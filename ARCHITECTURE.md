# 舆股 — 舆论→A股 情报推送系统 架构文档

## 技术栈

| 层 | 选型 | 原因 |
|---|---|---|
| 移动端 | Flutter 3.x + Material 3 | 一套代码双端，UI表现力好 |
| 后端爬虫 | Python 3.12 + httpx + BeautifulSoup | 轻量，生态全 |
| 调度 | APScheduler | 单机够用，无需Celery |
| 数据库 | Supabase (PostgreSQL) | 免费档500MB，自带实时订阅 |
| 推送 | Firebase Cloud Messaging | 免费，Flutter原生支持 |
| NLP | 本地规则匹配 | 起步不依赖大模型API，省钱 |
| 部署 | Vultr东京 VPS $6/月 | 爬虫跑海外，直连Supabase |

## 架构图

```
Vultr东京 VPS ($6/mo)
┌─────────────────────────────────────┐
│  Python 后端                         │
│  ┌──────────┐  ┌──────────────────┐ │
│  │ APScheduler│  │  Crawlers       │ │
│  │ 每2min    │──│  ├ twitter.py    │ │
│  │ 每30min   │  │  ├ truthsoc.py   │ │
│  │           │  │  └ materials.py  │ │
│  └──────────┘  └───────┬──────────┘ │
│                        │             │
│  ┌─────────────────────▼──────────┐ │
│  │  NLP Pipeline                  │ │
│  │  ├ entity_extract.py           │ │
│  │  └ sentiment.py                │ │
│  └──────────────┬─────────────────┘ │
└─────────────────┼───────────────────┘
                  │ HTTPS
          ┌───────▼────────┐
          │   Supabase      │
          │  (PostgreSQL)   │
          └───────┬────────┘
                  │ Realtime
          ┌───────▼────────┐
          │  Flutter App    │
          │  (iOS/Android)  │
          └────────────────┘
                  │
          Firebase FCM
          (Push通知)
```

## 数据库(7张核心表)

| 表 | 说明 | 行数预估 |
|---|---|---|
| celebrities | 监控名人 | ~20 |
| posts | 采集帖子 | ~1万/月 |
| companies | A股公司 | ~200+ |
| post_companies | 帖子↔公司关联 | ~5万/月 |
| materials | 原材料 | ~15 |
| material_prices | 价格时序 | ~1万/月 |
| alerts | 预警规则 | ~100 |
| material_companies | 原材料↔公司 | ~100 |

## 推送流程

```
定时任务触发(2min)
  → 爬取X(Nitter RSS) + Truth Social API
  → NLP实体提取 + 情感分析
  → 匹配A股公司(关键词+产业链)
  → 写入Supabase
  → Supabase Realtime → Flutter实时更新
  → 热度超阈值 → Firebase FCM推送
```

## 页面结构

| 序号 | 页面 | 功能 |
|------|------|------|
| 1 | PostFeedPage | 名人帖子流，每帖关联A股标签 |
| 2 | MaterialPage | 原材料价格列表，涨跌幅排行 |
| 3 | AlertsPage | 关键词监控规则，推送管理 |
| 4 | ProfilePage | 关注管理，订阅状态，设置 |

## 开发状态

- [x] 数据库Schema (supabase/schema.sql)
- [x] Python后端 (backend/)
- [x] Flutter移动端骨架 (mobile/)
- [ ] 部署到Vultr VPS
- [ ] 创建Supabase项目
- [ ] 配置Firebase项目
- [ ] 真实数据源接入(替换Mock)
