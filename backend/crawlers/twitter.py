"""
X平台爬虫 — 多源fallback
"""
import logging
import httpx
from bs4 import BeautifulSoup
from datetime import datetime, timezone
from config import TRACKED_ACCOUNTS_X

logger = logging.getLogger(__name__)

# 数据源列表 — 按优先级降序
RSS_SOURCES = [
    "https://xcancel.com",           # Nitter继任者
    "https://rsshub.app/twitter",    # RSSHub公共实例
    "https://nitter.poast.org",      # 替代实例
    "https://nitter.1d4.us",         # 替代实例
]


def _try_rss(instance: str, handle: str, limit: int) -> list[dict]:
    """尝试从单个RSS源获取推文"""
    url = f"{instance}/{handle}/rss"
    resp = httpx.get(url, timeout=20, follow_redirects=True,
                     headers={"User-Agent": "Mozilla/5.0 (compatible; SentimentBot/1.0)"})
    if resp.status_code != 200:
        return []

    soup = BeautifulSoup(resp.text, "xml")
    tweets = []
    for item in soup.find_all("item")[:limit]:
        title = item.find("title")
        link = item.find("link")
        pub_date = item.find("pubDate")
        tweets.append({
            "handle": handle,
            "content": title.get_text(strip=True) if title else "",
            "original_url": link.get_text(strip=True) if link else "",
            "posted_at": pub_date.get_text(strip=True) if pub_date else None,
            "platform": "x",
        })
    return tweets


def _try_rsshub(handle: str, limit: int) -> list[dict]:
    """RSSHub 特殊路径"""
    resp = httpx.get(f"https://rsshub.app/twitter/user/{handle}",
                     timeout=20, follow_redirects=True,
                     headers={"User-Agent": "Mozilla/5.0"})
    if resp.status_code != 200:
        return []

    soup = BeautifulSoup(resp.text, "xml")
    tweets = []
    for item in soup.find_all("item")[:limit]:
        title = item.find("title")
        link = item.find("link")
        pub_date = item.find("pubDate")
        tweets.append({
            "handle": handle,
            "content": title.get_text(strip=True) if title else "",
            "original_url": link.get_text(strip=True) if link else "",
            "posted_at": pub_date.get_text(strip=True) if pub_date else None,
            "platform": "x",
        })
    return tweets


def fetch_tweets(handle: str, limit: int = 10) -> list[dict]:
    """多源尝试获取推文"""
    # 先试RSSHub
    try:
        tweets = _try_rsshub(handle, limit)
        if tweets:
            logger.info(f"RSSHub OK for {handle}: {len(tweets)} tweets")
            return tweets
    except Exception as e:
        logger.debug(f"RSSHub failed: {e}")

    # 再试各RSS镜像
    for instance in RSS_SOURCES:
        try:
            tweets = _try_rss(instance, handle, limit)
            if tweets:
                logger.info(f"{instance} OK for {handle}: {len(tweets)} tweets")
                return tweets
        except Exception as e:
            logger.debug(f"{instance} failed for {handle}: {e}")
            continue

    logger.warning(f"All sources failed for @{handle}")
    return []


def crawl_all():
    """爬取所有关注账号"""
    all_tweets = []
    for handle in TRACKED_ACCOUNTS_X:
        try:
            tweets = fetch_tweets(handle)
            all_tweets.extend(tweets)
        except Exception as e:
            logger.error(f"Crawl failed for @{handle}: {e}")
    logger.info(f"X crawl done: {len(all_tweets)} tweets total")
    return all_tweets
