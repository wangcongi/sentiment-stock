"""
Truth Social爬虫 — 抓取特朗普等用户帖子
Truth Social基于Mastodon，提供公开API
"""
import logging
import httpx
from datetime import datetime, timezone
from config import TRACKED_ACCOUNTS_TRUTH_SOCIAL

logger = logging.getLogger(__name__)

TRUTH_API = "https://truthsocial.com/api/v1"


def fetch_user_posts(handle: str, limit: int = 10) -> list[dict]:
    """
    通过Truth Social公开API获取用户帖子
    不需要认证即可读取公开帖子
    """
    try:
        # 1. 先查找用户ID
        resp = httpx.get(
            f"{TRUTH_API}/accounts/lookup",
            params={"acct": handle},
            timeout=15,
        )
        if resp.status_code != 200:
            logger.warning(f"User lookup failed: {handle}")
            return []

        account_id = resp.json()["id"]

        # 2. 获取帖子列表
        resp = httpx.get(
            f"{TRUTH_API}/accounts/{account_id}/statuses",
            params={"limit": limit, "exclude_replies": True},
            timeout=15,
        )
        if resp.status_code != 200:
            return []

        posts = []
        for item in resp.json():
            posts.append({
                "handle": handle,
                "content": item.get("content", ""),
                "original_url": item.get("url") or item.get("uri", ""),
                "posted_at": item.get("created_at"),
                "likes": item.get("favourites_count", 0),
                "shares": item.get("reblogs_count", 0),
                "comments": item.get("replies_count", 0),
                "platform": "truth_social",
            })
        return posts

    except Exception as e:
        logger.error(f"Truth Social crawl failed for {handle}: {e}")
        return []


def parse_truth_date(date_str: str) -> datetime:
    """解析ISO格式日期"""
    return datetime.fromisoformat(date_str.replace("Z", "+00:00")).astimezone(timezone.utc)


def crawl_all():
    """爬取所有关注Truth Social账号"""
    all_posts = []
    for handle in TRACKED_ACCOUNTS_TRUTH_SOCIAL:
        try:
            posts = fetch_user_posts(handle)
            all_posts.extend(posts)
            logger.info(f"Fetched {len(posts)} posts from {handle}@truthsocial")
        except Exception as e:
            logger.error(f"Failed to crawl {handle}: {e}")
    return all_posts
