-- Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
    -- region
    -- platform
    -- age_band
    -- demographic
    -- customer_type
-- Below query can be used to find data for REGION
-- Replace region with platform, age_band, demographic or customer_type to get respective data
WITH fixed_week_value
AS (
	SELECT DISTINCT week_number AS fixed_week_number
	FROM data_mart.weekly_sales
	WHERE week_date = '2020-06-15'
	)
	,sales_data
AS (
	SELECT CASE 
			WHEN week_number < fixed_week_number
				THEN 'Before'
			ELSE 'After'
			END AS period
		,region
		,CONCAT (
			MIN(week_date)::VARCHAR
			,' to '
			,MAX(week_date)::VARCHAR
			) AS date_range
		,SUM(sales) AS total_sales
	FROM data_mart.weekly_sales
	CROSS JOIN fixed_week_value
	WHERE week_number >= fixed_week_number - 4
		AND week_number < fixed_week_number + 4
		AND calendar_year = 2020
	GROUP BY period
		,region
	)
	,growth_rate
AS (
SELECT period
	,region
	,date_range
	,total_sales
	,total_sales - LAG(total_sales, 1) OVER (
		PARTITION BY region ORDER BY date_range
		) AS sales_growth
	,ROUND(100 * (
			(
				total_sales::NUMERIC / LAG(total_sales, 1) OVER (
					PARTITION BY region ORDER BY date_range
					)
				) - 1
			), 2) AS sales_growth_in_percent
FROM sales_data
	)
SELECT region
	,sales_growth
	,sales_growth_in_percent
FROM growth_rate
WHERE sales_growth IS NOT NULL;
