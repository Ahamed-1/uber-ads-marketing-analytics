# 🚖 Uber Ads Analytics Dashboard

A end-to-end Marketing Analytics project simulating Uber's internal advertising analytics platform — built to demonstrate why brands should invest in Uber Ads.

![Dashboard Preview](page1_executive_overview.png)

---

## 📌 Project Overview

This project simulates Uber's ad analytics system covering:

- **10 advertisers** across QSR, Real Estate, Finance, Fashion, FMCG, Electronics, D2C
- **19 campaigns** across Uber Eats and Uber Rides
- **7 ad placements** across Pre, During and Post journey stages
- **4 months of data** — November 2024 to February 2025
- **₹22L+ in simulated ad spend**

### Business Question Answered
> *"Which platform, placement, and campaign type delivers the best return for advertisers on Uber?"*

---

## 🛠️ Tools Used

| Tool | Purpose |
|---|---|
| Python | Data simulation with realistic patterns |
| MySQL | Schema design, data loading, analytical views |
| Power BI | Dashboard design, DAX measures, storytelling |

---

## 📊 Dashboard Pages

### Page 1 — Executive Overview
- 5 KPI cards: Impressions, Clicks, Conversions, Spend, ROAS
- Monthly Performance Trend (Eats vs Rides)
- Top 5 Advertisers by Spend
- Spend by Platform (Donut)
- Ad Engagement Funnel
- Key Insight callout

### Page 2 — Platform Intelligence
- Eats vs Rides KPI comparison
- CTR % by Placement
- CVR % by Placement
- Category Performance by Platform
- Platform Verdict + Recommendations

---

## 🔑 Key Insights

- **Post Checkout** (Eats) has the highest CVR — decision moment after ordering
- **En Route Card** (Rides) has the highest CTR — captive audience with zero distraction
- **Real Estate brands** achieve the highest ROAS on Rides platform
- **December festive season** drove a 35% spike in Eats conversions
- **QSR brands** perform best on Eats — food intent context drives conversions

---

## 📐 Data Model

```
ad_placements ──── daily_performance ──── campaigns
                          │                    │
                     advertisers       campaign_placements
```

`daily_performance` is the central fact table with 4,560 rows of daily metrics.

---

## ⚙️ How to Run

### 1. Generate Data
```bash
pip install pandas numpy
python python/uber_ads_generator.py
```
This creates all 5 CSV files in the `data/` folder.

### 2. Load into MySQL
```sql
-- Open sql/uber_ads_sql.sql in MySQL Workbench
-- Update file paths in LOAD DATA INFILE sections
-- Run Section 1 (Schema) then Section 2 (Load Data)
```

### 3. Open Dashboard
- Open Power BI Desktop
- Get Data → Text/CSV → load all files from `data/`
- Build relationships as per data model above

---

## 📈 DAX Measures Used

```dax
CTR % = DIVIDE([Total Clicks], [Total Impressions]) * 100
CVR % = DIVIDE([Total Conversions], [Total Clicks]) * 100
CPA   = DIVIDE([Total Spend], [Total Conversions])
ROAS  = DIVIDE([Total Conversions] * 350, [Total Spend])
```

---
