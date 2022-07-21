-- B. Data Exploration
-- 1. What day of the week is used for each week_date value?
SELECT DISTINCT to_char(week_date, 'Day')
FROM data_mart.weekly_sales;

-- 2. What range of week numbers are missing from the dataset?
WITH available_week_number
AS (
	SELECT DISTINCT week_number
	FROM data_mart.weekly_sales
	)
SELECT *
FROM generate_series(1, 53) AS missing_week_number
WHERE missing_week_number NOT IN (
		SELECT week_number
		FROM available_week_number
		);

-- 3. How many total transactions were there for each year in the dataset?
SELECT calendar_year
	,COUNT(1) AS transaction_count
FROM data_mart.weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;

-- 4. What is the total sales for each region for each month?
SELECT region
	,cast(SUM(sales) AS MONEY) AS total_sales
FROM data_mart.weekly_sales
GROUP BY region
ORDER BY total_sales DESC;

-- 5. What is the total count of transactions for each platform
SELECT platform
	,SUM(transactions) AS transaction_count
FROM data_mart.weekly_sales
GROUP BY platform
ORDER BY transaction_count DESC;

-- 6. What is the percentage of sales for Retail vs Shopify for each month?
SELECT DATE_TRUNC('month', week_date) AS start_of_month
	,(
		SUM(CASE 
				WHEN platform = 'Retail'
					THEN sales
				END) * 100::FLOAT / SUM(sales)::FLOAT
		)::DECIMAL(4, 2) AS retail_sales_percent
	,(
		SUM(CASE 
				WHEN platform = 'Shopify'
					THEN sales
				END) * 100::FLOAT / SUM(sales)::FLOAT
		)::DECIMAL(4, 2) AS shopify_sales_percent
FROM data_mart.weekly_sales
GROUP BY start_of_month
ORDER BY start_of_month;

-- 7. What is the percentage of sales by demographic for each year in the dataset?
SELECT demographic
	,calendar_year
	,ROUND(100 * SUM(sales) / SUM(SUM(sales)) OVER (PARTITION BY calendar_year), 2) AS percentage_sales
FROM data_mart.weekly_sales
GROUP BY demographic
	,calendar_year
ORDER BY calendar_year
	,demographic;
	
-- 8. Which age_band and demographic values contribute the most to Retail sales?
SELECT demographic
	,age_band
	,ROUND(100 * SUM(sales) / SUM(SUM(sales)) OVER (), 2) AS percentage_sales
FROM data_mart.weekly_sales
WHERE platform = 'Retail'
GROUP BY demographic
	,age_band
ORDER BY percentage_sales DESC;

-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT platform
	,calendar_year
	,SUM(sales)/SUM(transactions) AS avg_transaction
FROM data_mart.weekly_sales
GROUP BY platform
	,calendar_year
ORDER BY avg_transaction DESC;
	



