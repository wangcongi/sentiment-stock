# 快速上手 — 免费部署，无需服务器

## 架构
```
GitHub Actions (美国, 免费)     Supabase (免费)
    │ 每15分钟                       │
    ├─ 爬取X/Truth Social ──────────┤
    ├─ DeepSeek分析 ────────────────┤
    └─ 写入 ───────────────────────→│
                                     │
    你的手机App ←── 实时读取 ────────┘
```
**月费: ¥0** (Supabase免费 + GitHub免费 + DeepSeek ¥2-5)

---

## 1. Supabase (数据库) — 5分钟
打开 https://supabase.com/dashboard → GitHub登录 → New Project
- Name: `sentiment-stock`
- Database Password: 自己设一个
- Region: Northeast Asia (Tokyo)
- 创建后 → Settings → Data API → 复制 `URL` + `service_role key`
- SQL Editor → 粘贴执行 `supabase/schema.sql`

## 2. DeepSeek (AI分析) — 3分钟
打开 https://platform.deepseek.com → 注册 → 充值¥10
- API Keys → 创建 → 复制 `sk-xxx`

## 3. GitHub (部署) — 3分钟
创建仓库后 → Settings → Secrets and variables → Actions → 添加4个Secret:

| Name | Value（填你自己的） |
|------|-------|
| `SUPABASE_URL` | `你的Supabase项目URL` |
| `SUPABASE_KEY` | `你的service_role key` |
| `LLM_ENABLED` | `true` |
| `DEEPSEEK_API_KEY` | `你的DeepSeek API Key` |

## 4. 推送代码
```bash
cd D:/项目/test/sentiment-stock
git remote add origin https://github.com/你的用户名/sentiment-stock.git
git branch -M main
git add -A
git commit -m "Initial: 舆情→A股情报推送系统"
git push -u origin main
```

推送后GitHub Actions自动开始运行，在Actions标签页可看日志。

## 5. Flutter (运行App)
```bash
cd mobile
flutter pub get
flutter run
```

## 可选: Firebase推送（需要翻墙）
略，App无推送也能用，Supabase Realtime实时更新。

## 验证
- GitHub → Actions → 看 `爬取名人帖子` 是否绿色
- Supabase → Table Editor → 看 `posts` 表是否有新数据
