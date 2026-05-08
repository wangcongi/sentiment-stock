"""
Supabase客户端 — 单例模式
"""
import logging
from supabase import create_client, Client
from config import SUPABASE_URL, SUPABASE_KEY

logger = logging.getLogger(__name__)
_client: Client | None = None


def get_client() -> Client:
    global _client
    if _client is None:
        url = SUPABASE_URL.strip()
        key = SUPABASE_KEY.strip()
        logger.info(f"Supabase init: {url[:35]}...")
        _client = create_client(url, key)
    return _client


def insert_post(post_data: dict) -> str | None:
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
    get_client().table("post_companies").upsert({
        "post_id": post_id,
        "company_id": company_id,
        "relevance_score": score,
        "keywords_matched": keywords,
    }, on_conflict="post_id,company_id").execute()


def upsert_material_price(material_id: str, price: float, change_pct: float, change_7d: float = 0):
    get_client().table("material_prices").insert({
        "material_id": material_id,
        "price": price,
        "change_pct": change_pct,
        "change_7d": change_7d,
    }).execute()


def get_active_alerts() -> list[dict]:
    result = get_client().table("alerts").select("*").eq("enabled", True).execute()
    return result.data
