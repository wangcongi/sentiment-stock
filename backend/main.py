"""
舆情监控系统 — 入口
运行: python main.py
"""
import logging
import signal
import sys
from config import LOG_LEVEL
from scheduler import start as start_scheduler

logging.basicConfig(
    level=getattr(logging, LOG_LEVEL, logging.INFO),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("main")


def main():
    logger.info("=== 舆情监控系统启动 ===")

    scheduler = start_scheduler()

    # 优雅退出
    def shutdown(sig, frame):
        logger.info("Shutting down...")
        scheduler.shutdown(wait=False)
        sys.exit(0)

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    # 保持主线程存活
    signal.pause()


if __name__ == "__main__":
    main()
