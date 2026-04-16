import pandas as pd
import numpy as np
from datetime import date, timedelta
import random
import os

random.seed(42)
np.random.seed(42)

OUTPUT_DIR = "uber_ads_data"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ─────────────────────────────────────────────
# 1. ADVERTISERS
# ─────────────────────────────────────────────
advertisers = pd.DataFrame([
    {"advertiser_id": "ADV01", "brand": "KFC",               "category": "QSR",         "primary_platform": "Eats"},
    {"advertiser_id": "ADV02", "brand": "McDonald's",         "category": "QSR",         "primary_platform": "Eats"},
    {"advertiser_id": "ADV03", "brand": "Domino's",           "category": "QSR",         "primary_platform": "Eats"},
    {"advertiser_id": "ADV04", "brand": "NoBroker",           "category": "Real Estate", "primary_platform": "Rides"},
    {"advertiser_id": "ADV05", "brand": "Godrej Properties",  "category": "Real Estate", "primary_platform": "Rides"},
    {"advertiser_id": "ADV06", "brand": "Myntra",             "category": "Fashion",     "primary_platform": "Both"},
    {"advertiser_id": "ADV07", "brand": "Pepsi",              "category": "FMCG",        "primary_platform": "Both"},
    {"advertiser_id": "ADV08", "brand": "HDFC Bank",          "category": "Finance",     "primary_platform": "Rides"},
    {"advertiser_id": "ADV09", "brand": "boAt",               "category": "Electronics", "primary_platform": "Both"},
    {"advertiser_id": "ADV10", "brand": "Mamaearth",          "category": "D2C",         "primary_platform": "Eats"},
])

# ─────────────────────────────────────────────
# 2. AD PLACEMENTS
# ─────────────────────────────────────────────
placements = pd.DataFrame([
    # Uber Eats
    {"placement_id": "PL01", "platform": "Eats",  "stage": "Pre-Order",  "placement_name": "Sponsored Listing", "format": "Feed Card"},
    {"placement_id": "PL02", "platform": "Eats",  "stage": "Pre-Order",  "placement_name": "Offer Banner",      "format": "Banner"},
    {"placement_id": "PL03", "platform": "Eats",  "stage": "Pre-Order",  "placement_name": "Store Ad Front",    "format": "Hero Banner"},
    {"placement_id": "PL04", "platform": "Eats",  "stage": "Post-Order", "placement_name": "Post Checkout",     "format": "Interstitial"},
    # Uber Rides
    {"placement_id": "PL05", "platform": "Rides", "stage": "Pre-Trip",   "placement_name": "Pre-Trip Screen",   "format": "Banner"},
    {"placement_id": "PL06", "platform": "Rides", "stage": "En Route",   "placement_name": "En Route Card",     "format": "Card"},
    {"placement_id": "PL07", "platform": "Rides", "stage": "Post-Trip",  "placement_name": "Post-Trip Screen",  "format": "Interstitial"},
])

# ─────────────────────────────────────────────
# 3. CAMPAIGNS
# ─────────────────────────────────────────────
START_DATE = date(2024, 11, 1)
END_DATE   = date(2025, 2, 28)

# (advertiser_id, campaign_name, platform, budget_inr, objective, placements_used)
campaign_definitions = [
    # QSR – Eats focused
    ("ADV01", "KFC Bucket Offer",         "Eats",  150000, "Conversions", ["PL01","PL02","PL04"]),
    ("ADV01", "KFC Brand Awareness",      "Eats",   80000, "Awareness",   ["PL03"]),
    ("ADV02", "McD Happy Meal Push",      "Eats",  120000, "Conversions", ["PL01","PL02"]),
    ("ADV02", "McD Store Visibility",     "Eats",   70000, "Traffic",     ["PL03","PL04"]),
    ("ADV03", "Dominos 30-Min Deals",     "Eats",  100000, "Conversions", ["PL01","PL04"]),
    ("ADV03", "Dominos Weekend Blast",    "Eats",   60000, "Awareness",   ["PL02","PL03"]),
    # Real Estate – Rides focused
    ("ADV04", "NoBroker Zero Brokerage",  "Rides", 200000, "Leads",       ["PL05","PL06","PL07"]),
    ("ADV04", "NoBroker Rentals",         "Rides",  90000, "Traffic",     ["PL06"]),
    ("ADV05", "Godrej New Launch",        "Rides", 250000, "Leads",       ["PL05","PL06","PL07"]),
    # Fashion – Both
    ("ADV06", "Myntra End of Reason Sale","Eats",  130000, "Traffic",     ["PL01","PL02"]),
    ("ADV06", "Myntra Fashion Forward",   "Rides", 110000, "Awareness",   ["PL05","PL06"]),
    # FMCG – Both
    ("ADV07", "Pepsi Summer Push",        "Eats",   95000, "Awareness",   ["PL02","PL03"]),
    ("ADV07", "Pepsi Ride Refresh",       "Rides",  85000, "Awareness",   ["PL05","PL06"]),
    # Finance – Rides
    ("ADV08", "HDFC Credit Card Offer",   "Rides", 180000, "Conversions", ["PL05","PL06","PL07"]),
    ("ADV08", "HDFC SmartPay",            "Rides",  75000, "Traffic",     ["PL07"]),
    # Electronics – Both
    ("ADV09", "boAt Airdopes Launch",     "Eats",  140000, "Traffic",     ["PL01","PL04"]),
    ("ADV09", "boAt Rockerz Rides",       "Rides", 120000, "Awareness",   ["PL05","PL06"]),
    # D2C – Eats
    ("ADV10", "Mamaearth Vitamin C",      "Eats",   90000, "Conversions", ["PL02","PL04"]),
    ("ADV10", "Mamaearth Store Front",    "Eats",   55000, "Awareness",   ["PL03"]),
]

campaigns = []
brand_counter = {}  # track per-brand count for unique identifier

for adv_id, name, platform, budget, objective, pl_ids in campaign_definitions:
    brand_name = advertisers.loc[advertisers["advertiser_id"] == adv_id, "brand"].values[0]
    # Clean brand name: remove spaces, apostrophes, dots → uppercase
    brand_slug = brand_name.replace("'", "").replace(".", "").replace(" ", "").upper()
    start_str  = START_DATE.strftime("%Y%m%d")
    end_str    = END_DATE.strftime("%Y%m%d")
    brand_counter[brand_slug] = brand_counter.get(brand_slug, 0) + 1
    uid = f"{brand_counter[brand_slug]:03d}"
    campaign_id = f"{brand_slug}_{start_str}_{end_str}_{uid}"

    campaigns.append({
        "campaign_id":   campaign_id,
        "advertiser_id": adv_id,
        "campaign_name": name,
        "platform":      platform,
        "objective":     objective,
        "total_budget":  budget,
        "start_date":    START_DATE,
        "end_date":      END_DATE,
        "placements":    ",".join(pl_ids),
    })

campaigns_df = pd.DataFrame(campaigns)

# ─────────────────────────────────────────────
# 4. DAILY PERFORMANCE (Fact Table)
# ─────────────────────────────────────────────

# Base CTR by placement (realistic mobile ad benchmarks)
BASE_CTR = {
    "PL01": 0.030,  # Sponsored Listing   – moderate
    "PL02": 0.045,  # Offer Banner        – higher (discount-driven)
    "PL03": 0.025,  # Store Ad Front      – lower (awareness)
    "PL04": 0.060,  # Post Checkout       – highest on Eats (decision moment)
    "PL05": 0.035,  # Pre-Trip Screen     – moderate
    "PL06": 0.055,  # En Route Card       – high (captive audience)
    "PL07": 0.050,  # Post-Trip Screen    – high (receipt moment)
}

# CVR (click to conversion) by placement
BASE_CVR = {
    "PL01": 0.08,
    "PL02": 0.14,
    "PL03": 0.05,
    "PL04": 0.20,
    "PL05": 0.07,
    "PL06": 0.10,
    "PL07": 0.18,
}

# Category affinity multiplier: how well a category fits a platform
AFFINITY = {
    ("QSR",         "Eats"):  1.40,
    ("QSR",         "Rides"): 0.70,
    ("Real Estate", "Rides"): 1.45,
    ("Real Estate", "Eats"):  0.65,
    ("Fashion",     "Eats"):  1.10,
    ("Fashion",     "Rides"): 1.05,
    ("FMCG",        "Eats"):  1.20,
    ("FMCG",        "Rides"): 1.10,
    ("Finance",     "Rides"): 1.35,
    ("Finance",     "Eats"):  0.80,
    ("Electronics", "Eats"):  1.10,
    ("Electronics", "Rides"): 1.10,
    ("D2C",         "Eats"):  1.25,
    ("D2C",         "Rides"): 0.85,
}

# Cost per 1000 impressions (CPM) by placement in INR
CPM = {
    "PL01": 55,
    "PL02": 70,
    "PL03": 60,
    "PL04": 90,
    "PL05": 65,
    "PL06": 80,
    "PL07": 85,
}

date_range = [START_DATE + timedelta(days=d) for d in range((END_DATE - START_DATE).days + 1)]

daily_rows = []

# build a lookup: advertiser_id -> category
adv_cat = dict(zip(advertisers["advertiser_id"], advertisers["category"]))

for _, camp in campaigns_df.iterrows():
    pl_ids    = camp["placements"].split(",")
    platform  = camp["platform"]
    budget    = camp["total_budget"]
    daily_bgt = budget / len(date_range)   # evenly spread budget
    adv_id    = camp["advertiser_id"]
    category  = adv_cat[adv_id]
    affinity  = AFFINITY.get((category, platform), 1.0)

    for dt in date_range:
        dow     = dt.weekday()          # 0=Mon, 6=Sun
        is_weekend = dow >= 5

        # Traffic multiplier by platform and day type
        if platform == "Eats":
            day_mult = 1.30 if is_weekend else 1.0
        else:
            day_mult = 0.85 if is_weekend else 1.0

        # Month-level trend: Dec is festive peak
        month_mult = {11: 1.0, 12: 1.35, 1: 0.95, 2: 1.05}.get(dt.month, 1.0)

        for pl_id in pl_ids:
            cpm_val  = CPM[pl_id]
            spend    = (daily_bgt / len(pl_ids)) * np.random.uniform(0.85, 1.15)
            impressions = int((spend / cpm_val) * 1000 * day_mult * month_mult)
            impressions = max(impressions, 50)

            ctr = BASE_CTR[pl_id] * affinity * day_mult * np.random.uniform(0.80, 1.20)
            ctr = min(ctr, 0.15)

            clicks = int(impressions * ctr)
            clicks = min(clicks, impressions)

            cvr  = BASE_CVR[pl_id] * affinity * np.random.uniform(0.75, 1.25)
            cvr  = min(cvr, 0.50)
            conversions = int(clicks * cvr)

            daily_rows.append({
                "date":          dt,
                "campaign_id":   camp["campaign_id"],
                "advertiser_id": adv_id,
                "placement_id":  pl_id,
                "platform":      platform,
                "impressions":   impressions,
                "clicks":        clicks,
                "conversions":   conversions,
                "spend_inr":     round(spend, 2),
            })

daily_perf = pd.DataFrame(daily_rows)

# ─────────────────────────────────────────────
# 5. SAVE CSVs
# ─────────────────────────────────────────────
advertisers.to_csv(f"{OUTPUT_DIR}/advertisers.csv", index=False)
placements.to_csv(f"{OUTPUT_DIR}/ad_placements.csv", index=False)
campaigns_df.drop(columns=["placements"]).to_csv(f"{OUTPUT_DIR}/campaigns.csv", index=False)
daily_perf.to_csv(f"{OUTPUT_DIR}/daily_performance.csv", index=False)

# Campaign-placement mapping (separate table for SQL joins)
camp_pl_rows = []
for _, camp in campaigns_df.iterrows():
    for pl in camp["placements"].split(","):
        camp_pl_rows.append({"campaign_id": camp["campaign_id"], "placement_id": pl})
pd.DataFrame(camp_pl_rows).to_csv(f"{OUTPUT_DIR}/campaign_placements.csv", index=False)

# ─────────────────────────────────────────────
# 6. QUICK VALIDATION
# ─────────────────────────────────────────────
print("=== DATA GENERATION COMPLETE ===\n")
print(f"Advertisers   : {len(advertisers)}")
print(f"Campaigns     : {len(campaigns_df)}")
print(f"Placements    : {len(placements)}")
print(f"Daily rows    : {len(daily_perf):,}")
print(f"Date range    : {START_DATE} → {END_DATE}")
print(f"\nTotal spend   : ₹{daily_perf['spend_inr'].sum():,.0f}")
print(f"Total impr.   : {daily_perf['impressions'].sum():,}")
print(f"Total clicks  : {daily_perf['clicks'].sum():,}")
print(f"Total conv.   : {daily_perf['conversions'].sum():,}")
print(f"\nOverall CTR   : {daily_perf['clicks'].sum()/daily_perf['impressions'].sum()*100:.2f}%")
print(f"Overall CVR   : {daily_perf['conversions'].sum()/daily_perf['clicks'].sum()*100:.2f}%")
print(f"\nFiles saved to: ./{OUTPUT_DIR}/")