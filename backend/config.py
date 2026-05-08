"""
舆情监控系统 — 后端配置
在Vultr VPS上运行时，环境变量通过.env文件注入
"""
import os
from dotenv import load_dotenv

load_dotenv()

# Supabase
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "")  # service_role key for backend

# 爬虫配置
CRAWL_INTERVAL_MIN = int(os.getenv("CRAWL_INTERVAL", "2"))  # 每N分钟轮询
HEAT_THRESHOLD = float(os.getenv("HEAT_THRESHOLD", "100"))  # 热度阈值

# 监控账号列表 (handle → 优先级)
TRACKED_ACCOUNTS_X = [
    "elonmusk",
    "nvidia",           # Jensen Huang
    "justinsuntron",
    "cz_binance",
    "VitalikButerin",
    "sama",
    "satyanadella",
]

TRACKED_ACCOUNTS_TRUTH_SOCIAL = [
    "realDonaldTrump",
]

# Nitter实例 (公开RSS桥接，无需API Key)
# 可自建或使用公共实例
NITTER_INSTANCES = [
    "https://nitter.net",
    "https://nitter.privacydev.net",
]

# 原材料数据源
MATERIAL_SOURCES = {
    "天然气": "https://www.xxx.com/natural-gas",     # TODO: 接入生意社/卓创API
    "WTI原油": "https://www.xxx.com/wti",
    "碳酸锂": "https://www.xxx.com/lithium",
}

# LLM分析 (DeepSeek API)
LLM_ENABLED = os.getenv("LLM_ENABLED", "false").lower() == "true"
DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY", "")
DEEPSEEK_BASE_URL = os.getenv("DEEPSEEK_BASE_URL", "https://api.deepseek.com")

# 日志
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
