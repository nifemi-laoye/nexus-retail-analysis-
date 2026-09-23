# nexus-retail-sql-analysis-

# Nexus Retail Group — SQL Capstone Analysis

## Project Overview

**Nexus Retail Group** is a consumer electronics retailer facing volatile sales trends and inventory margin erosion during periods of high inflation, a problem affecting supply chain operations, warehouse holding costs, and overall profitability. Left unaddressed, it risks costly overstocking of premium tech items and missed revenue during economic downturns.

This project uses **PostgreSQL** to analyze five years (2018–2022) of sales, inventory, and macroeconomic data to answer 9 business questions across four themes:

1. **Inflation & GDP Impact** — which categories lose the most sales under inflation, and how much cash gets tied up during weak-GDP months
2. **Promo & Demand Alignment** — whether promotions actually lift sales, and whether they're timed against real seasonal demand
3. **Inventory & Overstock** — which products/months/categories generate the most unsold stock
4. **Profit Margin & Cost** — which categories are both expensive and prone to sitting unsold

Each query answers one specific, stated business question rather than producing a generic summary — the goal was actionable findings a retail operations team could act on directly.

## Data

The analysis draws on three related tables:

| Table | Description | Key Columns |
|---|---|---|
| `sales` | Individual sales transactions | `salesid` (PK), `productid` (FK), `salesdate` (FK), `inventoryquantity`, `productcost`, `sales_year`, `sales_month` |
| `product` | Product catalog | `productid` (PK), `productcategory`, `promotions` (Yes/No) |
| `factors` | Monthly macroeconomic and seasonal indicators | `salesdate` (PK), `gdp`, `inflationrate`, `seasonalfactor`, `factors_year`, `factors_month` |

**Relationships:** `sales.salesdate` → `factors.salesdate`, `sales.productid` → `product.productid`

## Key Queries

### 1. Product Performance under Inflation

Identifies which product categories lose the most sales volume when inflation is high, using a CTE to label months before aggregating.

```sql
WITH sales_with_level AS (
    SELECT p.productcategory, s.inventoryquantity,
    CASE
        WHEN f.inflationrate > 3 THEN 'High Inflation'
        ELSE 'Low Inflation'
    END AS inflation_level
    FROM sales s
    JOIN product p ON s.productid = p.productid
    JOIN factors f ON s.salesdate = f.salesdate)
SELECT productcategory,
    SUM(CASE WHEN inflation_level = 'Low Inflation' THEN inventoryquantity ELSE 0 END) AS low_inflation_volume,
    SUM(CASE WHEN inflation_level = 'High Inflation' THEN inventoryquantity ELSE 0 END) AS high_inflation_volume
FROM sales_with_level
GROUP BY productcategory
ORDER BY (SUM(CASE WHEN inflation_level = 'Low Inflation' THEN inventoryquantity ELSE 0 END)
        - SUM(CASE WHEN inflation_level = 'High Inflation' THEN inventoryquantity ELSE 0 END)) DESC;
```

**Insight:** Laptops drop from 10,316 to 8,707 units (-15.6%) under high inflation — the sharpest decline of any category. Electronics moves the opposite way, rising from 9,359 to 11,075 units (+18.3%).

### 2. Slow-Moving Stock

Flags individual products sitting well above the average unsold-stock level, using a subquery to set a data-driven threshold and `HAVING` to filter on the aggregated total.

```sql
SELECT s.productid, p.productcategory,
    SUM(s.inventoryquantity) AS total_unsold
FROM sales s
JOIN product p ON s.productid = p.productid
GROUP BY s.productid, p.productcategory
HAVING SUM(s.inventoryquantity) > (
    SELECT ROUND(AVG(total_unsold), 2)
    FROM (
        SELECT productid, SUM(inventoryquantity) AS total_unsold
        FROM sales
        GROUP BY productid
    ) AS price_totals
)
ORDER BY total_unsold DESC;
```

**Insight:** Product #9806 (Electronics) is the single worst offender at 210 unsold units, and Electronics fills 3 of the top 4 slow-moving spots — pointing to a category-level problem, not just one bad SKU.

## Key Findings

- **Laptops are the most inflation-sensitive category**, losing 15.6% of sales volume (10,316 → 8,707 units) during high-inflation months, while Electronics counterintuitively gains 18.3% (9,359 → 11,075 units).
- **Promotions deliver almost no measurable lift** — items with a promotion average 52 units sold versus 51 without, a difference too small to justify the spend.
- **October and February are consistently the worst months for deadstock**, averaging ~55.7 unsold units across all five years, including two of the largest single-month cash lock-ups on record: October 2021 ($115,956) and October 2018 ($113,645).
- **Electronics is the single biggest inventory problem** across every cost and space metric: 20,434 units of warehouse space, $2,224,964 in tied-up cash, and the highest average unit cost ($107.67) of any category.
- **SmartPhones is the strongest organic performer**, selling 10,912 units with zero promotional support, outperforming every other category with no marketing spend behind it.

## Recommendations

1. **Rebuild safety stock for Laptops ahead of inflation spikes** — order leaner during high-inflation months, and investigate why Electronics moves in the opposite direction to see if that resilience can be replicated.
2. **Reassess promotional spend, starting with the worst-timed months** — with only a 1-unit average lift overall, promotional budget needs a hard second look before it's renewed on autopilot.
3. **Fast-track markdowns for Electronics SKUs like Product #9806** — and re-run the Slow-Moving Stock query on a recurring basis to catch new problem items early.
4. **Plan clearance activity ahead of October and February every year** — these months are a predictable, recurring pattern, not a one-off risk.
5. **Treat Electronics as the top financial priority** — it is simultaneously the biggest space user, the biggest cash drain, and the most expensive category per unit, making it the highest-leverage area for cost recovery.

*Built with PostgreSQL as part of a data analytics capstone project with 10Alytics* 
