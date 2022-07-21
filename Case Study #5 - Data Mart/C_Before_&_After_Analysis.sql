-- 1. What is the total sales for the 4 weeks before and after 2020-06-15? 
-- What is the growth or reduction rate in actual values and percentage of sales?
WITH period_interval AS 
(
	SELECT DISTINCT week_date
		,CASE WHEN week_date < '2020-06-15'
	THEN 'Before'
	ELSE 'After'
	END AS period
	FROM data_mart.weekly_sales
	WHERE week_date >= date '2020-06-15' - interval '4 week'
AND week_date < date '2020-06-15' + interval '4 week'
)
,sales AS 
(
SELECT pi.period
	,CONCAT(MIN(pi.week_date)::VARCHAR, ' to ', MAX(pi.week_date)::VARCHAR) AS date_range
	,SUM(ws.sales) AS total_sales
FROM data_mart.weekly_sales ws
INNER JOIN period_interval pi ON pi.week_date = ws.week_date
GROUP BY pi.period
	)
SELECT period
	,date_range
	,total_sales
	,total_sales - LAG(total_sales, 1) OVER (ORDER BY date_range) AS sales_growth
	,ROUND(100 * (total_sales - LAG(total_sales, 1) OVER (ORDER BY date_range)):: NUMERIC/LAG(total_sales, 1) OVER (ORDER BY date_range), 2) AS sales_growth_in_percent
FROM sales;

-- 2. What about the entire 12 weeks before and after?
-- 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?