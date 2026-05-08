"""
Supabase客户端 — 单例模式，带调试
"""
import logging
from supabase import create_client, Client
from config import SUPABASE_URL, SUPABASE_KEY

logger = logging.getLogger(__name__)
_client: Client | None = None


def get_client() -> Client:
    global _client
    if _client is None:
        import httpx
        # 调试：先用httpx直接测试连通性
        try:
            test_resp = httpx.get(
                SUPABASE_URL + "/rest/v1/",
                headers={"apikey": SUPABASE_KEY},
                timeout=10,
            )
            logger.info(f"Supabase direct httpx test: HTTP {test_resp.status_code}")
        except Exception as e:
            logger.error(f"Supabase direct httpx FAILED: {e}")
            logger.error(f"URL used: '{SUPABASE_URL}'")

        logger.info(f"Initializing Supabase client: URL prefix={SUPABASE_URL[:35]}... len={len(SUPABASE_URL)}")
        _client = create_client(SUPABASE_URL, SUPABASE_KEY)
    return _client


def insert_post(post_data: dict) -> str | None:
    """插入帖子，去重检查后返回id"""
    client = get_client()
    existing = (
        client.table("posts")
        .select("id")
        .eq("original_url", post_data["original_url"])
        .execute()
    )
    if existing.data:
        return existing.data[0]["id"]

    result = client.table("posts").insert(post_data).execute()
    return result.data[0]["id"] if result.data else None


def link_post_to_company(post_id: str, company_id: str, score: float, keywords: list[str]):
    """建立帖子与A股公司的关联"""
    get_client().table("post_companies").upsert({
        "post_id": post_id,
        "company_id": company_id,
        "relevance_score": score,
        "keywords_matched": keywords,
    }, on_conflict="post_id,company_id").execute()


def upsert_material_price(material_id: str, price: float, change_pct: float, change_7d: float = 0):
    """写入原材料价格"""
    get_client().table("material_prices").insert({
        "material_id": material_id,
        "price": price,
        "change_pct": change_pct,
        "change_7d": change_7d,
    }).execute()


def get_active_alerts() -> list[dict]:
    """获取所有启用的预警规则"""
    result = get_client().table("alerts").select("*").eq("enabled", True).execute()
    return result.data
