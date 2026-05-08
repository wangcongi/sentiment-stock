"""
LLM分析模块 — 使用DeepSeek API进行深度分析
起步可选：不使用LLM时，fallback到规则匹配
"""
import json
import logging
import httpx
from config import DEEPSEEK_API_KEY, DEEPSEEK_BASE_URL, LLM_ENABLED

logger = logging.getLogger(__name__)

ANALYSIS_PROMPT = """你是一个A股产业链分析专家。分析以下名人帖子，输出JSON格式结果。

帖子内容：
{content}

发帖人：{celebrity}
平台：{platform}

请分析并返回严格JSON格式（不要markdown代码块）：
{{
  "summary": "一句话总结核心信息(中文，30字以内)",
  "sentiment": "positive/negative/neutral",
  "market_impact": 0-10的整数，表示对A股市场的影响程度,
  "affected_companies": [
    {{
      "code": "A股代码如300750",
      "name": "公司简称",
      "reason": "关联逻辑(一句话)",
      "relevance": 0.0-1.0的相关度
    }}
  ],
  "affected_sectors": ["行业1", "行业2"],
  "chain_logic": "产业链传导逻辑简述(50字内)"
}}

注意：
- 只返回真正相关的A股公司，不要编造
- 如果帖子不涉及中国股市/产业，affected_companies返回空数组
- reason要具体，不能是泛泛的"行业龙头"
"""


async def analyze_with_llm(content: str, celebrity: str, platform: str) -> dict | None:
    """调用DeepSeek API分析帖子"""
    if not LLM_ENABLED or not DEEPSEEK_API_KEY:
        return None

    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{DEEPSEEK_BASE_URL}/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {DEEPSEEK_API_KEY}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": "deepseek-chat",
                    "messages": [
                        {"role": "system", "content": "你是一个专业的A股产业链分析助手，输出严格JSON格式。"},
                        {"role": "user", "content": ANALYSIS_PROMPT.format(
                            content=content[:2000],  # 截断长文本
                            celebrity=celebrity,
                            platform=platform,
                        )},
                    ],
                    "temperature": 0.1,
                    "max_tokens": 800,
                },
                timeout=30,
            )

            if resp.status_code != 200:
                logger.error(f"LLM API error: {resp.status_code} {resp.text[:200]}")
                return None

            result = resp.json()
            raw = result["choices"][0]["message"]["content"]

            # 清洗可能的markdown代码块
            raw = raw.strip()
            if raw.startswith("```"):
                raw = raw.split("\n", 1)[-1]
                if raw.endswith("```"):
                    raw = raw[:-3]

            return json.loads(raw)

    except Exception as e:
        logger.error(f"LLM analysis failed: {e}")
        return None


def merge_with_rules(llm_result: dict | None, rule_result: dict) -> dict:
    """
    合并LLM结果和规则匹配结果
    LLM结果优先，规则结果补充
    """
    if llm_result is None:
        return rule_result

    return {
        "sentiment": llm_result.get("sentiment") or rule_result.get("sentiment", "neutral"),
        "market_impact": llm_result.get("market_impact", 0),
        "summary": llm_result.get("summary", ""),
        "chain_logic": llm_result.get("chain_logic", ""),
        "affected_companies": llm_result.get("affected_companies", []),
        "affected_sectors": llm_result.get("affected_sectors", []),
        "rule_companies": rule_result.get("linked_companies", []),  # 规则匹配的保留作参考
    }
