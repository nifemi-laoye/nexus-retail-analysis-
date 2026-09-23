-- SQL Capstone Project - Nexus Retail Group Analysis 

SELECT * FROM factors;
SELECT * FROM product; 
SELECT * FROM sales;  

--Aliases: sales, s  - product, p  - factors, f

-- P1: Inflation & GDP Impact Analysis
-- Q1. Which specific product categories suffer the biggest drop in sales volume when inflation rises?

-- FINDING INFLATION TIPPING POINT

SELECT MIN(inflationrate), MAX(inflationrate), AVG(inflationrate)
FROM factors; --- AVG is 3.03 approx. 3


WITH sales_with_level AS 
	(SELECT p.productcategory, s.inventoryquantity,
CASE
	WHEN f.inflationrate > 3 THEN 'High Inflation'
	ELSE 'Low Inflation'
END AS inflation_level
FROM sales s
JOIN product p
ON s.productid = p.productid 
JOIN factors f
ON s.salesdate = f.salesdate)
SELECT productcategory, 
	SUM(CASE WHEN inflation_level = 'Low Inflation' THEN inventoryquantity ELSE 0 END) AS low_inflation_volume,
	SUM(CASE WHEN inflation_level = 'High Inflation' THEN inventoryquantity ELSE 0 END) AS high_inflation_volume
FROM sales_with_level
GROUP BY productcategory
ORDER BY (SUM(CASE WHEN inflation_level = 'Low Inflation' THEN inventoryquantity ELSE 0 END)
	- SUM(CASE WHEN inflation_level = 'High Inflation' THEN inventoryquantity ELSE 0 END)) DESC;


-- Q2. How much company cash is tied up in unsold warehouse inventory during low-GDP months?

SELECT * FROM sales; 
SELECT * FROM factors; 

-- To find the GDP tipping point 

SELECT MIN(gdp), MAX(gdp), AVG(gdp)
FROM factors; -- AVG is 20042 approx. 20000

SELECT f.factors_year, f.factors_month,
	ROUND(SUM(s.inventoryquantity * s.productcost)) AS deadstock_capital 
FROM sales s
JOIN factors f
	ON s.salesdate = f.salesdate
WHERE f.gdp < 20000
GROUP BY f.factors_year, f.factors_month 
ORDER BY deadstock_capital DESC; 


-- P2: Promo & Demand Alignment Analysis
-- Q1. Do our promotional campaigns actually drive a clear lift in sales 
-- volume, or are they wasting budget?

SELECT * FROM sales; 
SELECT * FROM product;

SELECT DISTINCT promotions 
FROM product; -- YES/NO


SELECT p.promotions,
	ROUND(AVG(s.inventoryquantity)) AS avg_volume
FROM sales s
JOIN product p 
ON s.productid = p.productid
GROUP BY p.promotions;
 

-- Q2. Are we spending money on advertisements during slow 
-- seasons when customer demand is naturally low

SELECT * FROM factors;
SELECT * FROM product;
SELECT * FROM sales;

SELECT f.factors_year, f.factors_month, ROUND(AVG(f.seasonalfactor), 2) AS avg_seasonal_factor,
	COUNT(CASE WHEN p.promotions = 'Yes' THEN p.productid END) AS promo_count
FROM sales s
JOIN product p ON s.productid = p.productid
JOIN factors f ON s.salesdate = f.salesdate
GROUP BY f.factors_year, f.factors_month
ORDER BY avg_seasonal_factor ASC;


-- Q3. Which product categories bring in steady sales anyway, even
-- without any active marketing help?

SELECT * FROM product;
SELECT * FROM sales;

SELECT p.productcategory, SUM(s.inventoryquantity) AS total_volume
FROM sales s
JOIN product p
ON s.productid = p.productid
WHERE p.promotions = 'No'
GROUP BY p.productcategory
ORDER BY total_volume DESC;


-- P3: Inventory & Overstock Analysis 
-- Q1. Which products are sitting heavily in warehouse inventory
-- with little to no sales activity?

SELECT * FROM product;
SELECT * FROM sales;

SELECT ROUND(AVG(total_unsold), 2) AS avg_total_unsold
FROM (
SELECT productid, SUM(inventoryquantity) AS total_unsold
FROM sales
GROUP BY productid) AS price_totals;  -- 56.22 AS THE OVERSTOCK TIPPING POINT/THRESHOLD


SELECT s.productid, p.productcategory, 
	SUM(s.inventoryquantity) AS total_unsold
FROM sales s
JOIN product p
ON s.productid = p.productid
GROUP BY s.productid, p.productcategory
HAVING SUM(s.inventoryquantity) > (56.22) 
ORDER BY total_unsold DESC;

-- Q2. In which months of the year do we consistently get
-- stuck with the highest amount of unsold stock? 

SELECT * FROM factors;
SELECT * FROM sales;

SELECT f.factors_month, ROUND(AVG(s.inventoryquantity), 2) AS avg_unsold_across_years
FROM sales s
JOIN factors f
ON s.salesdate = f.salesdate
GROUP BY f.factors_month
ORDER BY avg_unsold_across_years DESC; 

-- Q3. Which specific product categories are taking up the
-- most warehouse space and draining our holding costs?

SELECT * FROM product;
SELECT * FROM sales;

SELECT p.productcategory,
	SUM(s.inventoryquantity) AS total_space_used,
	ROUND(SUM(s.inventoryquantity * s.productcost)) AS total_holding_value
FROM sales s
JOIN product p
ON s.productid = p.productid
GROUP BY p.productcategory
ORDER BY total_space_used DESC;


-- P4: Profit Margin & Cost Analysis
-- Q1. Which expensive product categories are draining the
-- most company cash when they sit unsold?

SELECT * FROM product;
SELECT * FROM sales;

SELECT p.productcategory,
	ROUND(AVG(s.productcost), 2) AS avg_unit_cost,
	ROUND(SUM(s.inventoryquantity * s.productcost)) AS total_tied_up_cash
FROM sales s
JOIN product p
ON s.productid = p.productid
GROUP BY p.productcategory
ORDER BY total_tied_up_cash DESC;






















 


















