"""
实体提取 + A股公司映射
基于关键词规则 + 简单NLP，起步阶段不依赖大模型API
"""
import re
import logging
from db.supabase_client import get_client

logger = logging.getLogger(__name__)

# 缓存公司关键词映射，避免每次都查库
_company_cache: list[dict] | None = None


def _load_companies() -> list[dict]:
    """从Supabase加载所有公司及其关键词"""
    global _company_cache
    if _company_cache is not None:
        return _company_cache
    result = get_client().table("companies").select("id,code,name,sector,keywords").execute()
    _company_cache = result.data
    return _company_cache


def extract_companies(text: str) -> list[tuple[dict, float, list[str]]]:
    """
    从文本中提取关联的A股公司
    返回: [(company_dict, relevance_score, matched_keywords), ...]
    """
    companies = _load_companies()
    results = []
    text_lower = text.lower()

    for comp in companies:
        matched = []
        score = 0
        for kw in comp.get("keywords", []):
            if kw.lower() in text_lower:
                matched.append(kw)
                # 短关键词权重低，长关键词权重高
                score += min(len(kw) / 4, 1.0)

        if matched:
            score = min(score / len(comp["keywords"]), 1.0) if comp["keywords"] else 0.5
            score = round(score, 2)
            results.append((comp, score, matched))

    results.sort(key=lambda x: x[1], reverse=True)
    return results


def compute_heat(likes: int, shares: int, comments: int) -> float:
    """综合计算热度分"""
    return likes * 1.0 + shares * 2.0 + comments * 0.5


def process_post(post_data: dict) -> dict:
    """
    处理单条帖子: 实体提取 + 热度计算
    返回处理后的数据
    """
    content = post_data.get("content", "")
    linked_companies = extract_companies(content)

    post_data["heat_score"] = compute_heat(
        post_data.get("likes", 0),
        post_data.get("shares", 0),
        post_data.get("comments", 0),
    )
    post_data["linked_companies"] = linked_companies
    return post_data
