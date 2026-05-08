"""
GitHub Actions 单次运行脚本
由 .github/workflows/*.yml 触发，跑一次即退出
"""
import os
import sys
import logging

# 从 GitHub Secrets 注入环境变量
os.environ.setdefault("SUPABASE_URL", os.getenv("SUPABASE_URL", ""))
os.environ.setdefault("SUPABASE_KEY", os.getenv("SUPABASE_KEY", ""))
os.environ.setdefault("LLM_ENABLED", os.getenv("LLM_ENABLED", "true"))
os.environ.setdefault("DEEPSEEK_API_KEY", os.getenv("DEEPSEEK_API_KEY", ""))
os.environ.setdefault("DEEPSEEK_BASE_URL", "https://api.deepseek.com")
os.environ.setdefault("CRAWL_INTERVAL", "15")
os.environ.setdefault("LOG_LEVEL", os.getenv("LOG_LEVEL", "INFO"))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("github-action")


def run_post_crawl():
    """爬取帖子 → NLP → 入库"""
    import asyncio
    from crawlers import twitter, truthsoc
    from nlp.entity_extract import process_post
    from nlp.sentiment import analyze as sentiment_analyze
    from nlp.llm_analyzer import analyze_with_llm, merge_with_rules
    from db.supabase_client import insert_post, link_post_to_company, get_client

    logger.info("=== Post crawl started ===")
    raw_posts = []
    raw_posts.extend(twitter.crawl_all())
    raw_posts.extend(truthsoc.crawl_all())
    logger.info(f"Crawled {len(raw_posts)} raw posts")

    for raw in raw_posts:
        try:
            processed = process_post(raw)
            sentiment = sentiment_analyze(raw.get("content", ""))

            # LLM分析
            llm_result = None
            if os.getenv("LLM_ENABLED", "true").lower() == "true":
                try:
                    llm_result = asyncio.run(
                        analyze_with_llm(
                            raw.get("content", ""),
                            raw.get("handle", ""),
                            raw.get("platform", ""),
                        )
                    )
                except Exception as e:
                    logger.warning(f"LLM skipped: {e}")

            merged = merge_with_rules(llm_result, {
                "sentiment": sentiment,
                "linked_companies": processed.get("linked_companies", []),
            })

            handle = raw.get("handle", "")
            celeb_result = (
                get_client().table("celebrities")
                .select("id,name")
                .eq("handle", handle)
                .execute()
            )
            if not celeb_result.data:
                logger.warning(f"Unknown handle: {handle}")
                continue

            post_id = insert_post({
                "celebrity_id": celeb_result.data[0]["id"],
                "content": raw["content"],
                "platform": raw["platform"],
                "original_url": raw["original_url"],
                "posted_at": raw.get("posted_at"),
                "likes": raw.get("likes", 0),
                "shares": raw.get("shares", 0),
                "comments": raw.get("comments", 0),
                "heat_score": processed["heat_score"],
                "sentiment": merged.get("sentiment", sentiment),
            })

            if not post_id:
                continue

            # LLM关联
            for comp in merged.get("affected_companies", []):
                code = comp.get("code", "")
                company_result = (
                    get_client().table("companies")
                    .select("id")
                    .eq("code", code)
                    .execute()
                )
                if company_result.data:
                    link_post_to_company(
                        post_id, company_result.data[0]["id"],
                        comp.get("relevance", 0.5),
                        [comp.get("reason", "")],
                    )

            # 规则关联（兜底）
            for comp, score, keywords in processed.get("linked_companies", []):
                already = any(
                    comp.get("id") == c.get("code")
                    for c in merged.get("affected_companies", [])
                )
                if not already:
                    link_post_to_company(post_id, comp["id"], score, keywords)

        except Exception as e:
            logger.error(f"Error processing post: {e}")

    logger.info("=== Post crawl done ===")


def run_material_crawl():
    """爬取原材料价格"""
    from crawlers import materials
    from db.supabase_client import upsert_material_price, get_client

    logger.info("=== Material crawl started ===")
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
                    p["price"], p["change_pct"], p.get("change_7d", 0),
                )
        except Exception as e:
            logger.error(f"Material save failed: {e}")
    logger.info(f"=== Material crawl done. Updated {len(prices)} items ===")


if __name__ == "__main__":
    task = sys.argv[1] if len(sys.argv) > 1 else "posts"
    if task == "posts":
        run_post_crawl()
    elif task == "materials":
        run_material_crawl()
    else:
        print(f"Unknown task: {task}")
        sys.exit(1)
