--

CREATE DATABASE IF NOT EXISTS uber_ads;
USE uber_ads;
DROP TABLE IF EXISTS daily_performance;
DROP TABLE IF EXISTS campaign_placements;
DROP TABLE IF EXISTS campaigns;
DROP TABLE IF EXISTS ad_placements;
DROP TABLE IF EXISTS advertisers;
CREATE TABLE advertisers (
    advertiser_id     VARCHAR(10)  NOT NULL PRIMARY KEY,
    brand        VARCHAR(100) NOT NULL,
    category          VARCHAR(50)  NOT NULL,   
);

CREATE TABLE ad_placements (
    placement_id    VARCHAR(10)  NOT NULL PRIMARY KEY,
    platform    VARCHAR(20)  NOT NULL,   
    stage        VARCHAR(20)  NOT NULL,   
    placement_name  VARCHAR(100) NOT NULL,
    format          VARCHAR(50)  NOT NULL   
);

CREATE TABLE campaigns (
    campaign_id    VARCHAR(80)  NOT NULL PRIMARY KEY,  
    advertiser_id  VARCHAR(10)  NOT NULL,
    campaign_name  VARCHAR(150) NOT NULL,
    platform       VARCHAR(20)  NOT NULL,
    objective      VARCHAR(50)  NOT NULL,              -- Awareness | Traffic | Conversions | Leads
    total_budget   DECIMAL(12,2) NOT NULL,
    start_date     DATE         NOT NULL,
    end_date       DATE         NOT NULL,
    FOREIGN KEY (advertiser_id) REFERENCES advertisers(advertiser_id)
);

-- 1.4 Campaign ↔ Placement bridge
CREATE TABLE campaign_placements (
    campaign_id   VARCHAR(80) NOT NULL,
    placement_id  VARCHAR(10) NOT NULL,
    PRIMARY KEY (campaign_id, placement_id),
    FOREIGN KEY (campaign_id)  REFERENCES campaigns(campaign_id),
    FOREIGN KEY (placement_id) REFERENCES ad_placements(placement_id)
);

-- 1.5 Daily Performance (Fact Table)
CREATE TABLE daily_performance (
    perf_id        BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    date           DATE         NOT NULL,
    campaign_id    VARCHAR(80)  NOT NULL,
    advertiser_id  VARCHAR(10)  NOT NULL,
    placement_id   VARCHAR(10)  NOT NULL,
    platform       VARCHAR(20)  NOT NULL,
    impressions    INT          NOT NULL DEFAULT 0,
    clicks         INT          NOT NULL DEFAULT 0,
    conversions    INT          NOT NULL DEFAULT 0,
    spend_inr      DECIMAL(12,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (campaign_id)   REFERENCES campaigns(campaign_id),
    FOREIGN KEY (advertiser_id) REFERENCES advertisers(advertiser_id),
    FOREIGN KEY (placement_id)  REFERENCES ad_placements(placement_id)
);


-- ============================================================

LOAD DATA INFILE '/path/to/advertisers.csv'
INTO TABLE advertisers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE '/path/to/ad_placements.csv'
INTO TABLE ad_placements
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE '/path/to/campaigns.csv'
INTO TABLE campaigns
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(campaign_id, advertiser_id, campaign_name, platform, objective, total_budget, start_date, end_date);

LOAD DATA INFILE '/path/to/campaign_placements.csv'
INTO TABLE campaign_placements
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE '/path/to/daily_performance.csv'
INTO TABLE daily_performance
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(date, campaign_id, advertiser_id, placement_id, platform, impressions, clicks, conversions, spend_inr);



-- ────────────────────────────────────────────
-- Q1: PLATFORM SUMMARY
-- Answers: Eats vs Rides — which drives more value?
-- ────────────────────────────────────────────
CREATE OR REPLACE VIEW v_platform_summary AS
SELECT
    dp.platform,
    COUNT(DISTINCT dp.campaign_id)                              AS total_campaigns,
    SUM(dp.impressions)                                         AS total_impressions,
    SUM(dp.clicks)                                             AS total_clicks,
    SUM(dp.conversions)                                        AS total_conversions,
    ROUND(SUM(dp.spend_inr), 2)                                AS total_spend_inr,
    ROUND(SUM(dp.clicks) / NULLIF(SUM(dp.impressions),0) * 100, 2) AS ctr_pct,
    ROUND(SUM(dp.conversions) / NULLIF(SUM(dp.clicks),0) * 100, 2) AS cvr_pct,
    ROUND(SUM(dp.spend_inr) / NULLIF(SUM(dp.clicks),0), 2)    AS cpc_inr,
    ROUND(SUM(dp.spend_inr) / NULLIF(SUM(dp.conversions),0), 2) AS cpa_inr
FROM daily_performance dp
GROUP BY dp.platform;


-- ────────────────────────────────────────────
-- Q2: PLACEMENT FUNNEL ANALYSIS
-- Answers: Which stage of the journey converts best?
-- ────────────────────────────────────────────
CREATE OR REPLACE VIEW v_placement_funnel AS
SELECT
    pl.platform,
    pl.stage,
    pl.placement_name,
    pl.format,
    SUM(dp.impressions)                                              AS impressions,
    SUM(dp.clicks)                                                   AS clicks,
    SUM(dp.conversions)                                              AS conversions,
    ROUND(SUM(dp.spend_inr), 2)                                      AS spend_inr,
    ROUND(SUM(dp.clicks) / NULLIF(SUM(dp.impressions),0) * 100, 2)  AS ctr_pct,
    ROUND(SUM(dp.conversions) / NULLIF(SUM(dp.clicks),0) * 100, 2)  AS cvr_pct,
    ROUND(SUM(dp.spend_inr) / NULLIF(SUM(dp.conversions),0), 2)     AS cpa_inr,
    -- Funnel drop-off: % of impressions that did NOT click
    ROUND((1 - SUM(dp.clicks) / NULLIF(SUM(dp.impressions),0)) * 100, 2) AS impression_dropoff_pct,
    -- Funnel drop-off: % of clicks that did NOT convert
    ROUND((1 - SUM(dp.conversions) / NULLIF(SUM(dp.clicks),0)) * 100, 2) AS click_dropoff_pct
FROM daily_performance dp
JOIN ad_placements pl ON dp.placement_id = pl.placement_id
GROUP BY pl.platform, pl.stage, pl.placement_name, pl.format
ORDER BY pl.platform, cvr_pct DESC;


-- ────────────────────────────────────────────
-- Q3: CAMPAIGN PERFORMANCE WITH ROAS
-- Answers: Which campaigns are profitable vs wasteful?
-- ────────────────────────────────────────────
CREATE OR REPLACE VIEW v_campaign_performance AS
SELECT
    c.campaign_id,
    c.campaign_name,
    a.brand,
    a.category,
    c.platform,
    c.objective,
    c.total_budget                                                    AS planned_budget_inr,
    ROUND(SUM(dp.spend_inr), 2)                                       AS actual_spend_inr,
    ROUND(SUM(dp.spend_inr) / c.total_budget * 100, 1)               AS budget_utilization_pct,
    SUM(dp.impressions)                                               AS impressions,
    SUM(dp.clicks)                                                    AS clicks,
    SUM(dp.conversions)                                               AS conversions,
    ROUND(SUM(dp.clicks) / NULLIF(SUM(dp.impressions),0) * 100, 2)   AS ctr_pct,
    ROUND(SUM(dp.conversions) / NULLIF(SUM(dp.clicks),0) * 100, 2)   AS cvr_pct,
    ROUND(SUM(dp.spend_inr) / NULLIF(SUM(dp.conversions),0), 2)      AS cpa_inr,
    -- Conversion value by category (INR)
    CASE a.category
        WHEN 'QSR'          THEN 350
        WHEN 'Real Estate'  THEN 50000
        WHEN 'Fashion'      THEN 800
        WHEN 'FMCG'         THEN 200
        WHEN 'Finance'      THEN 2000
        WHEN 'Electronics'  THEN 1500
        WHEN 'D2C'          THEN 600
        ELSE 500
    END                                                               AS avg_conversion_value_inr,
    -- ROAS = Total Conversion Value / Total Spend
    ROUND(
        (SUM(dp.conversions) * CASE a.category
            WHEN 'QSR'         THEN 350
            WHEN 'Real Estate' THEN 50000
            WHEN 'Fashion'     THEN 800
            WHEN 'FMCG'        THEN 200
            WHEN 'Finance'     THEN 2000
            WHEN 'Electronics' THEN 1500
            WHEN 'D2C'         THEN 600
            ELSE 500
        END) / NULLIF(SUM(dp.spend_inr), 0)
    , 2)                                                              AS roas,
    -- Performance label for easy filtering in Power BI
    CASE
        WHEN ROUND(
            (SUM(dp.conversions) * CASE a.category
                WHEN 'QSR'         THEN 350
                WHEN 'Real Estate' THEN 50000
                WHEN 'Fashion'     THEN 800
                WHEN 'FMCG'        THEN 200
                WHEN 'Finance'     THEN 2000
                WHEN 'Electronics' THEN 1500
                WHEN 'D2C'         THEN 600
                ELSE 500
            END) / NULLIF(SUM(dp.spend_inr), 0), 2) >= 3 THEN 'High Performer'
        WHEN ROUND(
            (SUM(dp.conversions) * CASE a.category
                WHEN 'QSR'         THEN 350
                WHEN 'Real Estate' THEN 50000
                WHEN 'Fashion'     THEN 800
                WHEN 'FMCG'        THEN 200
                WHEN 'Finance'     THEN 2000
                WHEN 'Electronics' THEN 1500
                WHEN 'D2C'         THEN 600
                ELSE 500
            END) / NULLIF(SUM(dp.spend_inr), 0), 2) >= 1 THEN 'Moderate'
        ELSE 'Underperforming'
    END                                                               AS performance_label
FROM daily_performance dp
JOIN campaigns c    ON dp.campaign_id   = c.campaign_id
JOIN advertisers a  ON dp.advertiser_id = a.advertiser_id
GROUP BY
    c.campaign_id, c.campaign_name, a.brand, a.category,
    c.platform, c.objective, c.total_budget
ORDER BY roas DESC;


-- ────────────────────────────────────────────
-- Q4: MONTHLY TREND
-- Answers: How do metrics move over 4 months?
-- ────────────────────────────────────────────
CREATE OR REPLACE VIEW v_monthly_trend AS
SELECT
    DATE_FORMAT(dp.date, '%Y-%m')                                     AS month,
    dp.platform,
    SUM(dp.impressions)                                               AS impressions,
    SUM(dp.clicks)                                                    AS clicks,
    SUM(dp.conversions)                                               AS conversions,
    ROUND(SUM(dp.spend_inr), 2)                                       AS spend_inr,
    ROUND(SUM(dp.clicks) / NULLIF(SUM(dp.impressions),0) * 100, 2)   AS ctr_pct,
    ROUND(SUM(dp.conversions) / NULLIF(SUM(dp.clicks),0) * 100, 2)   AS cvr_pct,
    ROUND(SUM(dp.spend_inr) / NULLIF(SUM(dp.conversions),0), 2)      AS cpa_inr
FROM daily_performance dp
GROUP BY DATE_FORMAT(dp.date, '%Y-%m'), dp.platform
ORDER BY month, dp.platform;


-- ────────────────────────────────────────────
-- Q5: CATEGORY PERFORMANCE
-- Answers: Which advertiser category gets the most from Uber Ads?
-- ────────────────────────────────────────────
CREATE OR REPLACE VIEW v_category_performance AS
SELECT
    a.category,
    dp.platform,
    COUNT(DISTINCT dp.campaign_id)                                    AS campaigns_run,
    SUM(dp.impressions)                                               AS impressions,
    SUM(dp.clicks)                                                    AS clicks,
    SUM(dp.conversions)                                               AS conversions,
    ROUND(SUM(dp.spend_inr), 2)                                       AS spend_inr,
    ROUND(SUM(dp.clicks) / NULLIF(SUM(dp.impressions),0) * 100, 2)   AS ctr_pct,
    ROUND(SUM(dp.conversions) / NULLIF(SUM(dp.clicks),0) * 100, 2)   AS cvr_pct,
    ROUND(SUM(dp.spend_inr) / NULLIF(SUM(dp.conversions),0), 2)      AS cpa_inr
FROM daily_performance dp
JOIN advertisers a ON dp.advertiser_id = a.advertiser_id
GROUP BY a.category, dp.platform
ORDER BY ctr_pct DESC;


-- ────────────────────────────────────────────
-- Q6: WEEKEND vs WEEKDAY PERFORMANCE
-- Answers: When should advertisers increase budget?
-- ────────────────────────────────────────────
CREATE OR REPLACE VIEW v_day_type_performance AS
SELECT
    dp.platform,
    CASE WHEN DAYOFWEEK(dp.date) IN (1,7) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    ROUND(AVG(dp.impressions), 0)                                     AS avg_daily_impressions,
    ROUND(AVG(dp.clicks), 0)                                          AS avg_daily_clicks,
    ROUND(AVG(dp.conversions), 0)                                     AS avg_daily_conversions,
    ROUND(AVG(dp.spend_inr), 2)                                       AS avg_daily_spend_inr,
    ROUND(SUM(dp.clicks) / NULLIF(SUM(dp.impressions),0) * 100, 2)   AS ctr_pct,
    ROUND(SUM(dp.conversions) / NULLIF(SUM(dp.clicks),0) * 100, 2)   AS cvr_pct
FROM daily_performance dp
GROUP BY dp.platform, day_type
ORDER BY dp.platform, day_type;


-- ────────────────────────────────────────────
-- Q7: TOP 5 AND BOTTOM 5 CAMPAIGNS BY ROAS
-- Answers: Where is ad spend working and where is it wasted?
-- Useful for Power BI conditional formatting tables
-- ────────────────────────────────────────────

-- Top 5
SELECT campaign_id, campaign_name, brand, category, platform, roas, performance_label
FROM v_campaign_performance
ORDER BY roas DESC
LIMIT 5;

-- Bottom 5
SELECT campaign_id, campaign_name, brand, category, platform, roas, performance_label
FROM v_campaign_performance
ORDER BY roas ASC
LIMIT 5;


-- ────────────────────────────────────────────
-- Q8: SPEND PACING — Budget Utilization Check
-- Answers: Are campaigns burning budget as planned?
-- ────────────────────────────────────────────
CREATE OR REPLACE VIEW v_spend_pacing AS
SELECT
    c.campaign_id,
    c.campaign_name,
    a.brand,
    c.platform,
    c.total_budget                                                    AS planned_budget_inr,
    ROUND(SUM(dp.spend_inr), 2)                                       AS actual_spend_inr,
    ROUND(c.total_budget - SUM(dp.spend_inr), 2)                     AS remaining_budget_inr,
    ROUND(SUM(dp.spend_inr) / c.total_budget * 100, 1)               AS pacing_pct,
    CASE
        WHEN SUM(dp.spend_inr) / c.total_budget >= 0.95 THEN 'On Track'
        WHEN SUM(dp.spend_inr) / c.total_budget >= 0.75 THEN 'Slightly Under'
        ELSE 'Underpacing'
    END                                                               AS pacing_status
FROM daily_performance dp
JOIN campaigns c   ON dp.campaign_id   = c.campaign_id
JOIN advertisers a ON dp.advertiser_id = a.advertiser_id
GROUP BY c.campaign_id, c.campaign_name, a.brand, c.platform, c.total_budget
ORDER BY pacing_pct DESC;


-- ────────────────────────────────────────────
-- Q9: DAILY TREND (for time-series line chart in Power BI)
-- ────────────────────────────────────────────
CREATE OR REPLACE VIEW v_daily_trend AS
SELECT
    dp.date,
    dp.platform,
    SUM(dp.impressions)                                               AS impressions,
    SUM(dp.clicks)                                                    AS clicks,
    SUM(dp.conversions)                                               AS conversions,
    ROUND(SUM(dp.spend_inr), 2)                                       AS spend_inr,
    ROUND(SUM(dp.clicks) / NULLIF(SUM(dp.impressions),0) * 100, 2)   AS ctr_pct,
    ROUND(SUM(dp.conversions) / NULLIF(SUM(dp.clicks),0) * 100, 2)   AS cvr_pct
FROM daily_performance dp
GROUP BY dp.date, dp.platform
ORDER BY dp.date;


-- ============================================================
-- SECTION 5: QUICK VALIDATION QUERIES
-- Run these after loading data to confirm everything is correct
-- ============================================================

-- Row counts
SELECT 'advertisers'      AS tbl, COUNT(*) AS rows FROM advertisers    UNION ALL
SELECT 'ad_placements'    AS tbl, COUNT(*) AS rows FROM ad_placements  UNION ALL
SELECT 'campaigns'        AS tbl, COUNT(*) AS rows FROM campaigns      UNION ALL
SELECT 'campaign_placements', COUNT(*) FROM campaign_placements        UNION ALL
SELECT 'daily_performance',   COUNT(*) FROM daily_performance;

-- Sanity check: no nulls in key columns
SELECT COUNT(*) AS null_campaign_ids   FROM daily_performance WHERE campaign_id  IS NULL;
SELECT COUNT(*) AS null_placement_ids  FROM daily_performance WHERE placement_id IS NULL;
SELECT COUNT(*) AS negative_spend      FROM daily_performance WHERE spend_inr    < 0;

-- Overall KPIs (should match Python output)
SELECT
    SUM(impressions)                                           AS total_impressions,
    SUM(clicks)                                                AS total_clicks,
    SUM(conversions)                                           AS total_conversions,
    ROUND(SUM(spend_inr),0)                                    AS total_spend_inr,
    ROUND(SUM(clicks)/SUM(impressions)*100, 2)                 AS overall_ctr_pct,
    ROUND(SUM(conversions)/SUM(clicks)*100, 2)                 AS overall_cvr_pct
FROM daily_performance;
