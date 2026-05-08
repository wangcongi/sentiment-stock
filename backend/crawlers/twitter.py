"""
X平台爬虫 — 通过Nitter RSS获取公开推文
"""
import logging
import httpx
from bs4 import BeautifulSoup
from datetime import datetime, timezone
from config import TRACKED_ACCOUNTS_X, NITTER_INSTANCES

logger = logging.getLogger(__name__)


def fetch_tweets_nitter(handle: str, limit: int = 10) -> list[dict]:
    """
    通过Nitter RSS获取用户最新推文
    Nitter是Twitter的隐私友好前端，提供RSS feed
    """
    tweets = []
    for instance in NITTER_INSTANCES:
        try:
            resp = httpx.get(
                f"{instance}/{handle}/rss",
                timeout=15,
                follow_redirects=True,
            )
            if resp.status_code != 200:
                continue

            soup = BeautifulSoup(resp.text, "xml")
            for item in soup.find_all("item")[:limit]:
                tweets.append({
                    "handle": handle,
                    "content": item.find("title").get_text(strip=True) if item.find("title") else "",
                    "original_url": item.find("link").get_text(strip=True) if item.find("link") else "",
                    "posted_at": item.find("pubDate").get_text(strip=True) if item.find("pubDate") else None,
                    "platform": "x",
                })
            break  # 成功则跳出实例轮询
        except Exception as e:
            logger.warning(f"Nitter {instance} failed for {handle}: {e}")
            continue

    return tweets


def parse_twitter_date(date_str: str) -> datetime:
    """解析Twitter日期格式 → UTC datetime"""
    from email.utils import parsedate_to_datetime
    return parsedate_to_datetime(date_str).astimezone(timezone.utc)


def crawl_all():
    """爬取所有关注账号的最新推文"""
    all_tweets = []
    for handle in TRACKED_ACCOUNTS_X:
        try:
            tweets = fetch_tweets_nitter(handle)
            all_tweets.extend(tweets)
            logger.info(f"Fetched {len(tweets)} tweets from @{handle}")
        except Exception as e:
            logger.error(f"Failed to crawl @{handle}: {e}")
    return all_tweets
