-- B. Data Analysis Questions
-- How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id)
FROM foodie_fi.subscriptions;

-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT date_trunc('month', s.start_date)::DATE AS start_month
	,COUNT(s.plan_id)
FROM foodie_fi.subscriptions s
INNER JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
WHERE p.plan_name = 'trial'
GROUP BY start_month
ORDER BY start_month;

-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT p.plan_name
	,COUNT(p.plan_id) AS plan_count_after_2020
FROM foodie_fi.subscriptions s
INNER JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
WHERE DATE_PART('YEAR', start_date) > 2020
GROUP BY p.plan_name;

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
WITH cte_churned_plan_customers_data
AS (
	SELECT COUNT(DISTINCT customer_id) AS total_customers
		,COUNT(DISTINCT CASE 
				WHEN p.plan_name = 'churn'
					THEN s.customer_id
				END) AS churned_plan_customers
	FROM foodie_fi.subscriptions s
	INNER JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
	)
SELECT churned_plan_customers AS churned_plan_customer_count
	,ROUND(churned_plan_customers::NUMERIC * 100 / total_customers::NUMERIC, 1) AS churned_plan_customer_percent
FROM cte_churned_plan_customers_data;

-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH cte_previous_plan
AS (
	SELECT s.customer_id
		,p.plan_name
		,LAG(p.plan_name, 1) OVER (
			PARTITION BY s.customer_id ORDER BY s.customer_id
				,s.start_date
			) AS previous_plan_name
	FROM foodie_fi.subscriptions s
	INNER JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
	)
SELECT COUNT(CASE 
			WHEN plan_name = 'churn'
				THEN customer_id
			END) AS churned_after_trial_customer_count
	,ROUND(COUNT(CASE 
				WHEN plan_name = 'churn'
					THEN customer_id
				END)::NUMERIC * 100 / COUNT(customer_id)::NUMERIC, 0) AS churned_after_trial_customer_percent
FROM cte_previous_plan
WHERE previous_plan_name = 'trial';

-- What is the number and percentage of customer plans after their initial free trial?
WITH cte_previous_plan
AS (
	SELECT s.customer_id
		,p.plan_name
		,LAG(p.plan_name, 1) OVER (
			PARTITION BY s.customer_id ORDER BY s.customer_id
				,s.start_date
			) AS previous_plan_name
	FROM foodie_fi.subscriptions s
	INNER JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
	)
	,cte_total_customers
AS (
	SELECT COUNT(DISTINCT customer_id) AS total_customers
	FROM foodie_fi.subscriptions
	)
SELECT pp.plan_name
	,COUNT(pp.customer_id) AS after_trial_plan_count
	,ROUND(COUNT(pp.customer_id)::NUMERIC * 100 / tc.total_customers::NUMERIC, 2) AS after_trial_plan_count_percent
FROM cte_previous_plan pp
CROSS JOIN cte_total_customers tc
WHERE previous_plan_name = 'trial'
GROUP BY pp.plan_name
	,tc.total_customers;

-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH cte_plan_rank
AS (
	SELECT s.customer_id
		,s.plan_id
		,RANK() OVER (
			PARTITION BY s.customer_id ORDER BY s.start_date DESC
			) AS plan_reverse_rank
	FROM foodie_fi.subscriptions s
	WHERE s.start_date <= '2020-12-31'
	)
	,cte_total_customers
AS (
	SELECT COUNT(DISTINCT customer_id) AS total_customers
	FROM foodie_fi.subscriptions
	)
SELECT p.plan_name
	,COUNT(pr.customer_id) AS after_trial_plan_count
	,ROUND(COUNT(pr.customer_id)::NUMERIC * 100 / tc.total_customers::NUMERIC, 2) AS after_trial_plan_count_percent
FROM cte_plan_rank pr
CROSS JOIN cte_total_customers tc
INNER JOIN foodie_fi.plans p ON pr.plan_id = p.plan_id
	AND pr.plan_reverse_rank = 1
GROUP BY p.plan_name
	,tc.total_customers;

-- How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(s.customer_id) AS customers_with_annual_plan_in_2020
FROM foodie_fi.subscriptions s
INNER JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
WHERE DATE_PART('YEAR', start_date) = 2020
	AND p.plan_name = 'pro annual';

-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH cte_trial_start_date
AS (
	SELECT s.customer_id
		,s.start_date AS trial_start_date
	FROM foodie_fi.subscriptions s
	INNER JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
		AND p.plan_name = 'trial'
	)
	,cte_pro_annual_start_date
AS (
	SELECT s.customer_id
		,s.start_date AS pro_annual_start_date
	FROM foodie_fi.subscriptions s
	INNER JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
		AND p.plan_name = 'pro annual'
	)
SELECT ROUND(AVG(pd.pro_annual_start_date - td.trial_start_date), 0)
FROM cte_pro_annual_start_date pd
INNER JOIN cte_trial_start_date td ON pd.customer_id = td.customer_id;

-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH cte_trial_start_date
AS (
	SELECT s.customer_id
		,s.start_date AS trial_start_date
	FROM foodie_fi.subscriptions s
	INNER JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
		AND p.plan_name = 'trial'
	)
	,cte_pro_annual_start_date
AS (
	SELECT s.customer_id
		,s.start_date AS pro_annual_start_date
	FROM foodie_fi.subscriptions s
	INNER JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
		AND p.plan_name = 'pro annual'
	)
	,cte_average_values_per_interval
AS (
	SELECT (((pd.pro_annual_start_date - td.trial_start_date) - 1) / 30) + 1 AS thirty_days_interval_rank
		,COUNT(pd.customer_id) AS customer_upgrade_count
		,AVG(pd.pro_annual_start_date - td.trial_start_date) AS avg_days_to_upgrade
	FROM cte_pro_annual_start_date pd
	INNER JOIN cte_trial_start_date td ON pd.customer_id = td.customer_id
	GROUP BY thirty_days_interval_rank
	ORDER BY thirty_days_interval_rank
	)
SELECT CASE 
		WHEN thirty_days_interval_rank = 1
			THEN '0-30 days'
		ELSE CONCAT (
				(thirty_days_interval_rank - 1) * 30 + 1
				,'-'
				,thirty_days_interval_rank * 30
				,' days'
				)
		END AS interval_days
	,customer_upgrade_count
	,ROUND(avg_days_to_upgrade, 0) AS avg_days_to_upgrade
FROM cte_average_values_per_interval;

-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH cte_previous_plans
AS (
	SELECT s.customer_id
		,s.start_date
		,p.plan_name
		,LAG(p.plan_name, 1) OVER (
			PARTITION BY s.customer_id ORDER BY s.customer_id
				,s.start_date
			) AS previous_plan_name
	FROM foodie_fi.subscriptions s
	INNER JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
	)
SELECT COUNT(customer_id) AS customers_downgraded_to_basic_monthly
FROM cte_previous_plans
WHERE previous_plan_name = 'pro monthly'
	AND plan_name = 'basic monthly'
	AND DATE_PART('YEAR', start_date) = 2020