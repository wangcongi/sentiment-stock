"""
简易情感分析 — 基于关键词规则
"""
import re
import logging

logger = logging.getLogger(__name__)

POSITIVE_WORDS = [
    "bullish", "great", "excellent", "breakthrough", "growth", "surge",
    "支持", "看好", "突破", "利好", "增长", "暴涨", "合作", "成功",
    "launch", "partnership", "AI", "innovation", "record",
]

NEGATIVE_WORDS = [
    "crash", "fear", "ban", "risk", "concern", "collapse",
    "下跌", "崩盘", "风险", "制裁", "禁止", "调查", "暴跌",
    "tariff", "sanction", "investigation", "lawsuit",
]


def analyze(text: str) -> str:
    """
    返回: 'positive' / 'negative' / 'neutral'
    """
    text_lower = text.lower()
    pos_score = sum(1 for w in POSITIVE_WORDS if w.lower() in text_lower)
    neg_score = sum(1 for w in NEGATIVE_WORDS if w.lower() in text_lower)

    if pos_score > neg_score + 1:
        return "positive"
    elif neg_score > pos_score + 1:
        return "negative"
    return "neutral"
