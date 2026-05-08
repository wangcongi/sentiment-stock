-- ============================================================
-- 舆论→A股 情报推送系统 — 数据库Schema
-- 部署到Supabase: supabase db push 或在SQL Editor直接执行
-- ============================================================

-- 1. 名人/影响者
CREATE TABLE celebrities (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,                        -- 显示名称
    handle      TEXT NOT NULL UNIQUE,                 -- 账号唯一标识
    platform    TEXT NOT NULL CHECK (platform IN ('x', 'truth_social', 'weibo')),
    avatar_url  TEXT,
    category    TEXT CHECK (category IN ('politics', 'tech', 'finance', 'crypto')),
    is_active   BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

-- 2. 帖子
CREATE TABLE posts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    celebrity_id    UUID NOT NULL REFERENCES celebrities(id) ON DELETE CASCADE,
    platform        TEXT NOT NULL,
    content         TEXT NOT NULL,
    original_url    TEXT,                              -- 原始链接
    posted_at       TIMESTAMPTZ NOT NULL,              -- 发帖时间
    likes           INTEGER DEFAULT 0,
    shares          INTEGER DEFAULT 0,                 -- 转发/分享数
    comments        INTEGER DEFAULT 0,
    heat_score      REAL DEFAULT 0,                    -- 热度分(综合计算)
    sentiment       TEXT CHECK (sentiment IN ('positive','negative','neutral')),
    fetched_at      TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_posts_posted_at ON posts(posted_at DESC);
CREATE INDEX idx_posts_celebrity ON posts(celebrity_id);
CREATE INDEX idx_posts_heat ON posts(heat_score DESC);

-- 3. A股公司
CREATE TABLE companies (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code        TEXT NOT NULL UNIQUE,                  -- 股票代码 如"300750"
    name        TEXT NOT NULL,                         -- 公司简称
    full_name   TEXT,                                  -- 全称
    sector      TEXT,                                  -- 行业
    sub_sector  TEXT,                                  -- 细分行业
    market_cap  REAL,                                  -- 市值(亿元)
    keywords    TEXT[] NOT NULL DEFAULT '{}',          -- 匹配关键词数组
    created_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_companies_code ON companies(code);
CREATE INDEX idx_companies_keywords ON companies USING GIN(keywords);

-- 4. 帖子↔公司关联
CREATE TABLE post_companies (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id         UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    company_id      UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    relevance_score REAL DEFAULT 0,                    -- 0-1 相关度
    keywords_matched TEXT[] DEFAULT '{}',              -- 匹配到的关键词
    UNIQUE(post_id, company_id)
);
CREATE INDEX idx_pc_post ON post_companies(post_id);
CREATE INDEX idx_pc_company ON post_companies(company_id);

-- 5. 原材料
CREATE TABLE materials (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL UNIQUE,                  -- 名称 如"天然气"
    unit        TEXT NOT NULL,                         -- 单位
    category    TEXT CHECK (category IN ('energy','chemical','metal','fiber','other')),
    source_url  TEXT                                   -- 数据源URL
);

-- 6. 原材料价格时间序列
CREATE TABLE material_prices (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    material_id UUID NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
    price       REAL NOT NULL,
    change_pct  REAL DEFAULT 0,                        -- 日涨跌幅%
    change_7d   REAL DEFAULT 0,                        -- 7日涨跌幅%
    recorded_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_mp_material_time ON material_prices(material_id, recorded_at DESC);
-- 启用Supabase Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE material_prices;

-- 7. 原材料↔公司关联
CREATE TABLE material_companies (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    material_id  UUID NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
    company_id   UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    impact_type  TEXT CHECK (impact_type IN ('cost','revenue','supply_chain')),
    impact_score REAL DEFAULT 0,                       -- 影响程度
    UNIQUE(material_id, company_id)
);

-- 8. 预警规则
CREATE TABLE alerts (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_token TEXT,                                  -- FCM token
    keyword     TEXT,                                   -- 监控关键词(模糊匹配)
    celebrity_id UUID REFERENCES celebrities(id),
    material_id  UUID REFERENCES materials(id),
    min_heat    REAL DEFAULT 100,                       -- 最低热度触发推送
    enabled     BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 初始数据: 名人
-- ============================================================
INSERT INTO celebrities (name, handle, platform, category) VALUES
('Donald Trump',    'realDonaldTrump',  'truth_social', 'politics'),
('Elon Musk',       'elonmusk',         'x',            'tech'),
('Jensen Huang',    'nvidia',           'x',            'tech'),
('Justin Sun',      'justinsuntron',    'x',            'crypto'),
('CZ Binance',      'cz_binance',       'x',            'crypto'),
('Vitalik Buterin', 'VitalikButerin',   'x',            'crypto'),
('Sam Altman',      'sama',             'x',            'tech'),
('Satya Nadella',   'satyanadella',     'x',            'tech');

-- ============================================================
-- 初始数据: 原材料
-- ============================================================
INSERT INTO materials (name, unit, category) VALUES
('天然气',       '元/千立方米', 'energy'),
('WTI原油',      '美元/桶',     'energy'),
('碳酸锂',       '元/吨',       'metal'),
('硅料',         '元/吨',       'metal'),
('MDI',          '元/吨',       'chemical'),
('TDI',          '元/吨',       'chemical'),
('光纤预制棒',   '元/吨',       'fiber'),
('稀土氧化镨钕', '元/吨',       'metal'),
('铜',           '元/吨',       'metal'),
('PTA',          '元/吨',       'chemical');

-- ============================================================
-- 初始数据: A股公司 (示例30家)
-- ============================================================
INSERT INTO companies (code, name, sector, sub_sector, keywords) VALUES
('300750', '宁德时代',   '电力设备', '电池',   ARRAY['电池','锂电池','储能','宁德','CATL']),
('002594', '比亚迪',     '汽车',     '整车',   ARRAY['电动车','新能源车','BYD','比亚迪']),
('600519', '贵州茅台',   '食品饮料', '白酒',   ARRAY['白酒','茅台','消费']),
('000858', '五粮液',     '食品饮料', '白酒',   ARRAY['白酒','五粮液','消费']),
('601012', '隆基绿能',   '电力设备', '光伏',   ARRAY['光伏','硅片','隆基','太阳能']),
('600309', '万华化学',   '化工',     'MDI',    ARRAY['MDI','化工','聚氨酯','万华']),
('600230', '沧州大化',   '化工',     'TDI',    ARRAY['TDI','化工','沧州大化']),
('002460', '赣锋锂业',   '有色金属', '锂',     ARRAY['锂','碳酸锂','赣锋']),
('601899', '紫金矿业',   '有色金属', '铜金',   ARRAY['铜','黄金','矿业','紫金']),
('000831', '中国稀土',   '有色金属', '稀土',   ARRAY['稀土','永磁']),
('688981', '中芯国际',   '电子',     '半导体', ARRAY['芯片','半导体','中芯','SMIC']),
('002049', '紫光国微',   '电子',     '半导体', ARRAY['芯片','FPGA','紫光']),
('000063', '中兴通讯',   '通信',     '设备',   ARRAY['5G','通信','中兴']),
('600585', '海螺水泥',   '建材',     '水泥',   ARRAY['水泥','建材','海螺']),
('601857', '中国石油',   '石油石化', '油气',   ARRAY['石油','天然气','中石油']),
('600028', '中国石化',   '石油石化', '油气',   ARRAY['石油','石化','中石化']),
('300124', '汇川技术',   '机械设备', '工控',   ARRAY['工控','自动化','机器人']),
('002415', '海康威视',   '计算机',   '安防',   ARRAY['安防','AI','海康']),
('688111', '金山办公',   '计算机',   '软件',   ARRAY['AI','办公','金山','WPS']),
('300274', '阳光电源',   '电力设备', '逆变器', ARRAY['光伏','逆变器','储能','阳光']);

-- ============================================================
-- 初始数据: 原材料↔公司关联
-- ============================================================
INSERT INTO material_companies (material_id, company_id, impact_type, impact_score)
SELECT m.id, c.id, 'cost', 0.8
FROM materials m, companies c
WHERE m.name = 'MDI'     AND c.code = '600309';

INSERT INTO material_companies (material_id, company_id, impact_type, impact_score)
SELECT m.id, c.id, 'cost', 0.7
FROM materials m, companies c
WHERE m.name = 'TDI'     AND c.code = '600230';

INSERT INTO material_companies (material_id, company_id, impact_type, impact_score)
SELECT m.id, c.id, 'cost', 0.8
FROM materials m, companies c
WHERE m.name = '碳酸锂'  AND c.code = '002460';

INSERT INTO material_companies (material_id, company_id, impact_type, impact_score)
SELECT m.id, c.id, 'cost', 0.7
FROM materials m, companies c
WHERE m.name = '碳酸锂'  AND c.code = '300750';

INSERT INTO material_companies (material_id, company_id, impact_type, impact_score)
SELECT m.id, c.id, 'supply_chain', 0.6
FROM materials m, companies c
WHERE m.name = '硅料'    AND c.code = '601012';

INSERT INTO material_companies (material_id, company_id, impact_type, impact_score)
SELECT m.id, c.id, 'supply_chain', 0.6
FROM materials m, companies c
WHERE m.name = '天然气'  AND c.code = '601857';

INSERT INTO material_companies (material_id, company_id, impact_type, impact_score)
SELECT m.id, c.id, 'supply_chain', 0.6
FROM materials m, companies c
WHERE m.name = '铜'      AND c.code = '601899';

-- ============================================================
-- 启用Realtime (实时订阅)
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE posts;
ALTER PUBLICATION supabase_realtime ADD TABLE post_companies;
