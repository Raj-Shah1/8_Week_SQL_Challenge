-- C. Challenge Payment Question
-- The Foodie-Fi team wants you to create a new payments table for the year 2020 
-- that includes amounts paid by each customer in the subscriptions table with the following requirements:
	-- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
	-- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
	-- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
	-- once a customer churns they will no longer make payments

WITH leading_plan_date
AS (
	SELECT s.customer_id
		,s.plan_id
		,p.plan_name
		,s.start_date
		,p.price
		,LEAD(s.start_date, 1) OVER (
			PARTITION BY s.customer_id ORDER BY s.start_date
			) AS next_start_date
	FROM foodie_fi.subscriptions s
	INNER JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
	)
	,payment_dates_data
AS (
	SELECT customer_id
		,plan_id
		,plan_name
		,CAST(GENERATE_SERIES(start_date, CASE 
					WHEN plan_name IN ('basic monthly', 'pro monthly')
						THEN COALESCE(LEAST(next_start_date - INTERVAL '1 day', '2020-12-31'), '2020-12-31')
					ELSE start_date
					END, INTERVAL '1 month') AS DATE) AS payment_date
		,price AS total_amount
	FROM leading_plan_date
	WHERE plan_name IN ('basic monthly', 'pro monthly', 'pro annual')
	)
SELECT customer_id
	,plan_id
	,plan_name
	,payment_date
	,CASE 
		WHEN (
				LAG(plan_name, 1) OVER (
					PARTITION BY customer_id ORDER BY payment_date
					) != plan_name
				AND plan_name IN ('pro monthly', 'pro annual')
				)
			AND payment_date - LAG(payment_date) OVER (
				PARTITION BY customer_id ORDER BY payment_date
				) < 30
			THEN total_amount - LAG(total_amount, 1) OVER (
					PARTITION BY customer_id ORDER BY payment_date
					)
		ELSE total_amount
		END AS amount
	,ROW_NUMBER() OVER (
		PARTITION BY customer_id ORDER BY payment_date
		) AS payment_order
FROM payment_dates_data
-- WHERE customer_id IN (1, 2, 11, 13, 15, 16, 18, 19) 
-- The above condition is used to match this query's output for the gicen customer ids with the expected output on the page 