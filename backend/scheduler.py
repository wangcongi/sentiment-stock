"""
定时任务调度器
每N分钟执行一轮: 爬取 → NLP处理 → 入库
"""
import logging
import time
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.interval import IntervalTrigger

import asyncio
from config import CRAWL_INTERVAL_MIN, HEAT_THRESHOLD, LLM_ENABLED
from crawlers import twitter, truthsoc, materials
from nlp.entity_extract import process_post
from nlp.sentiment import analyze as sentiment_analyze
from nlp.llm_analyzer import analyze_with_llm, merge_with_rules
from db.supabase_client import insert_post, link_post_to_company, upsert_material_price, get_active_alerts
from db.supabase_client import get_client

logger = logging.getLogger(__name__)


async def _analyze_with_llm(content: str, celebrity: str, platform: str) -> dict | None:
    """异步调用LLM分析"""
    if not LLM_ENABLED:
        return None
    return await analyze_with_llm(content, celebrity, platform)


def job_crawl_posts():
    """爬取帖子 → 规则匹配 + LLM分析 → 入库"""
    logger.info("Starting post crawl job...")

    # 1. 爬取
    raw_posts = []
    raw_posts.extend(twitter.crawl_all())
    raw_posts.extend(truthsoc.crawl_all())

    # 2. 逐条处理
    for raw in raw_posts:
        try:
            # 规则匹配(必跑)
            processed = process_post(raw)
            sentiment = sentiment_analyze(raw.get("content", ""))

            # LLM分析(可选，异步)
            llm_result = None
            if LLM_ENABLED:
                try:
                    llm_result = asyncio.run(
                        _analyze_with_llm(
                            raw.get("content", ""),
                            raw.get("handle", ""),
                            raw.get("platform", ""),
                        )
                    )
                except Exception as e:
                    logger.warning(f"LLM analysis skipped: {e}")

            # 合并结果
            merged = merge_with_rules(llm_result, {
                "sentiment": sentiment,
                "linked_companies": processed.get("linked_companies", []),
            })

            # 准备入库数据
            insert_data = {
                "content": raw["content"],
                "platform": raw["platform"],
                "original_url": raw["original_url"],
                "posted_at": raw.get("posted_at"),
                "likes": raw.get("likes", 0),
                "shares": raw.get("shares", 0),
                "comments": raw.get("comments", 0),
                "heat_score": processed["heat_score"],
                "sentiment": merged.get("sentiment", sentiment),
            }

            # 根据handle找到celebrity_id
            handle = raw.get("handle", "")
            celeb_result = (
                get_client().table("celebrities")
                .select("id,name")
                .eq("handle", handle)
                .execute()
            )
            if not celeb_result.data:
                logger.warning(f"Unknown handle: {handle}, skipping")
                continue

            insert_data["celebrity_id"] = celeb_result.data[0]["id"]

            post_id = insert_post(insert_data)
            if not post_id:
                continue

            # LLM关联公司 (精度高)
            llm_companies = merged.get("affected_companies", [])
            if llm_companies:
                for comp in llm_companies:
                    # 按股票代码查company_id
                    code = comp.get("code", "")
                    company_result = (
                        get_client().table("companies")
                        .select("id")
                        .eq("code", code)
                        .execute()
                    )
                    if company_result.data:
                        link_post_to_company(
                            post_id,
                            company_result.data[0]["id"],
                            comp.get("relevance", 0.5),
                            [comp.get("reason", "")],
                        )
                    else:
                        logger.debug(f"Company code {code} not in DB, LLM may have hallucinated")

            # 规则匹配公司 (补充兜底)
            rule_companies = merged.get("rule_companies", [])
            for comp, score, keywords in rule_companies:
                # 跳过LLM已经关联过的
                already_linked = any(
                    comp.get("id") == c.get("code") for c in llm_companies
                )
                if not already_linked:
                    link_post_to_company(post_id, comp["id"], score, keywords)

        except Exception as e:
            logger.error(f"Error processing post: {e}")
            continue

    logger.info(f"Post crawl done. Processed {len(raw_posts)} posts.")


def job_crawl_materials():
    """爬取原材料价格 → 入库"""
    logger.info("Starting material price crawl...")
    prices = materials.fetch_prices()
    for p in prices:
        try:
            mat_result = (
                get_client().table("materials")
                .select("id")
                .eq("name", p["name"])
                .execute()
            )
            if mat_result.data:
                upsert_material_price(
                    mat_result.data[0]["id"],
                    p["price"],
                    p["change_pct"],
                    p.get("change_7d", 0),
                )
        except Exception as e:
            logger.error(f"Error saving material price for {p['name']}: {e}")
    logger.info(f"Material crawl done. Updated {len(prices)} items.")


def start():
    """启动定时任务"""
    scheduler = BackgroundScheduler(timezone="Asia/Shanghai")
    scheduler.add_job(
        job_crawl_posts,
        IntervalTrigger(minutes=CRAWL_INTERVAL_MIN),
        id="crawl_posts",
        name="Crawl posts every N minutes",
    )
    scheduler.add_job(
        job_crawl_materials,
        IntervalTrigger(minutes=30),  # 原材料每30分钟刷新
        id="crawl_materials",
        name="Crawl material prices every 30min",
    )
    scheduler.start()
    logger.info(f"Scheduler started. Post interval: {CRAWL_INTERVAL_MIN}min")
    return scheduler
