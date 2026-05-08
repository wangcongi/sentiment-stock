"""
原材料价格爬虫 — 从公开数据源获取基础商品价格
初期用模拟数据占位，后续接入生意社/卓创资讯API
"""
import logging
import httpx
from datetime import datetime, timezone
from config import MATERIAL_SOURCES

logger = logging.getLogger(__name__)

# 占位数据: 后续替换为真实爬取
# 格式: {name: (price, change_pct, change_7d)}
MOCK_PRICES = {
    "天然气":       (4800, 2.3, 5.1),
    "WTI原油":      (78.5, -1.2, 3.8),
    "碳酸锂":       (112000, -0.5, -2.3),
    "硅料":         (65000, 1.8, 4.2),
    "MDI":          (16800, 0.3, 1.5),
    "TDI":          (18500, 2.1, 6.7),
    "光纤预制棒":   (32000, 0, 0.5),
    "稀土氧化镨钕": (485000, 1.5, 3.2),
    "铜":           (72000, 0.8, 2.1),
    "PTA":          (6100, -0.3, 1.1),
}


def fetch_prices() -> list[dict]:
    """
    获取原材料最新价格
    TODO: 接入真实数据源
    推荐: 生意社API (https://www.100ppi.com)、卓创资讯
    """
    results = []
    for name, (price, chg, chg7d) in MOCK_PRICES.items():
        results.append({
            "name": name,
            "price": price,
            "change_pct": round(chg, 2),
            "change_7d": round(chg7d, 2),
            "recorded_at": datetime.now(timezone.utc).isoformat(),
        })
    return results
