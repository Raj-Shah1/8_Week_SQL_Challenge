-- A. Customer Journey (1, 2, 11, 13, 15, 16, 18, 19)
SELECT *
FROM foodie_fi.subscriptions s
INNER JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
WHERE s.customer_id IN (1, 2, 11, 13, 15, 16, 18, 19)
ORDER BY s.customer_id
	,s.start_date;

-- Query to get general data explanation
WITH cte_data_explaination
AS (
	SELECT s.customer_id
		,CASE 
			WHEN s.plan_id = 0
				THEN CONCAT (
						'Customer '
						,s.customer_id
						,' started free trial plan on '
						,s.start_date
						)
			WHEN s.plan_id IN (1, 2, 3)
				THEN CONCAT (
						'switched to '
						,p.plan_name
						,' on '
						,s.start_date
						)
			WHEN s.plan_id = 4
				THEN CONCAT (
						'cancelled plan on '
						,s.start_date
						)
			END AS TEXT
	FROM foodie_fi.subscriptions s
	INNER JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
	WHERE s.customer_id IN (1, 2, 11, 13, 15, 16, 18, 19)
	)
SELECT customer_id
	,STRING_AGG(TEXT, ' and ')
FROM cte_data_explaination
GROUP BY customer_id
ORDER BY customer_id;
	-- Customer 1 started subscription with free trial on 2020-08-01 and then started with basic monthly plan right after it
	-- Customer 2 started subscription with free trial on 2020-09-20 and then started with pro annual plan right after it
	-- Customer 11 started subscription with free trial on 2020-11-19 and then cancelled plan on right after it
	-- Customer 13 started subscription with free trial on 2020-12-15 and then started with basic monthly plan right after it and switched to pro monthly on 2021-03-29
	-- Customer 15 started subscription with free trial on 2020-03-17 and then started with pro monthly plan right after it and cancelled plan on 2020-04-29
	-- Customer 16 started subscription with free trial on 2020-05-31 and then started with basic monthly plan right after it and switched to pro annual on 2020-10-21
	-- Customer 18 started subscription with free trial on 2020-07-06 and then started with pro monthly plan right after it
	-- Customer 19 started subscription with free trial on 2020-06-22 and then started with pro monthly plan right after it and switched to pro annual on 2020-08-29