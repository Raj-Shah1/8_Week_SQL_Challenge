-- 1. What is the total sales for the 4 weeks before and after 2020-06-15? 
-- What is the growth or reduction rate in actual values and percentage of sales?
WITH fixed_week_value
AS (
	SELECT DISTINCT week_number AS fixed_week_number
	FROM data_mart.clean_weekly_sales
	WHERE week_date = '2020-06-15'
	)
	,sales_data
AS (
	SELECT CASE 
			WHEN week_number < fixed_week_number
				THEN 'Before'
			ELSE 'After'
			END AS period
		,CONCAT (
			MIN(week_date)::VARCHAR
			,' to '
			,MAX(week_date)::VARCHAR
			) AS date_range
		,SUM(sales) AS total_sales
	FROM data_mart.clean_weekly_sales
	CROSS JOIN fixed_week_value
	WHERE week_number >= fixed_week_number - 4
		AND week_number < fixed_week_number + 4
		AND calendar_year = 2020
	GROUP BY period
	)
SELECT period
	,date_range
	,total_sales
	,total_sales - LAG(total_sales, 1) OVER (
		ORDER BY date_range
		) AS sales_growth
	,ROUND(100 * (
			(
				total_sales::NUMERIC / LAG(total_sales, 1) OVER (
					ORDER BY date_range
					)
				) - 1
			), 2) AS sales_growth_in_percent
FROM sales_data;

-- 2. What about the entire 12 weeks before and after?
WITH fixed_week_value
AS (
	SELECT DISTINCT week_number AS fixed_week_number
	FROM data_mart.clean_weekly_sales
	WHERE week_date = '2020-06-15'
	)
	,sales_data
AS (
	SELECT CASE 
			WHEN week_number < fixed_week_number
				THEN 'Before'
			ELSE 'After'
			END AS period
		,CONCAT (
			MIN(week_date)::VARCHAR
			,' to '
			,MAX(week_date)::VARCHAR
			) AS date_range
		,SUM(sales) AS total_sales
	FROM data_mart.clean_weekly_sales
	CROSS JOIN fixed_week_value
	WHERE week_number >= fixed_week_number - 12
		AND week_number < fixed_week_number + 12
		AND calendar_year = 2020
	GROUP BY period
	)
SELECT period
	,date_range
	,total_sales
	,total_sales - LAG(total_sales, 1) OVER (
		ORDER BY date_range
		) AS sales_growth
	,ROUND(100 * (
			(
				total_sales::NUMERIC / LAG(total_sales, 1) OVER (
					ORDER BY date_range
					)
				) - 1
			), 2) AS sales_growth_in_percent
FROM sales_data;

-- 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
-- Considering 12 weeks before and after
WITH fixed_week_value
AS (
	SELECT DISTINCT week_number AS fixed_week_number
	FROM data_mart.clean_weekly_sales
	WHERE week_date = '2020-06-15'
	)
	,sales_data
AS (
	SELECT calendar_year
		,CASE 
			WHEN week_number < fixed_week_number
				THEN 'Before'
			ELSE 'After'
			END AS period
		,CONCAT (
			MIN(week_date)::VARCHAR
			,' to '
			,MAX(week_date)::VARCHAR
			) AS date_range
		,SUM(sales) AS total_sales
	FROM data_mart.clean_weekly_sales
	CROSS JOIN fixed_week_value
	WHERE week_number >= fixed_week_number - 12
		AND week_number < fixed_week_number + 12
	GROUP BY calendar_year
		,period
	)
SELECT calendar_year
	,period
	,date_range
	,total_sales
	,total_sales - LAG(total_sales, 1) OVER (
		PARTITION BY calendar_year ORDER BY date_range
		) AS sales_growth
	,ROUND(100 * (
			(
				total_sales::NUMERIC / LAG(total_sales, 1) OVER (
					PARTITION BY calendar_year ORDER BY date_range
					)
				) - 1
			), 2) AS sales_growth_in_percent
FROM sales_data
ORDER BY calendar_year
	,date_range;