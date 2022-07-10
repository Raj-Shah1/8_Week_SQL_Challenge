-- B. Customer Transactions
-- 1. What is the unique count and total amount for each transaction type?
SELECT txn_type
	,COUNT(1) AS txn_count
	,SUM(txn_amount) AS txn_amount
FROM data_bank.customer_transactions
GROUP BY txn_type;

-- 2. What is the average total historical deposit counts and amounts for all customers?
WITH historial_deposits
AS (
	SELECT customer_id
		,COUNT(1) AS txn_count
		,AVG(txn_amount) AS txn_amount
	FROM data_bank.customer_transactions
	WHERE txn_type = 'deposit'
	GROUP BY customer_id
	)
SELECT ROUND(AVG(txn_count)) AS avg_txn_count
	,ROUND(AVG(txn_amount)) AS avg_txn_amount
FROM historial_deposits;

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH customer_data
AS (
	SELECT DATE_TRUNC('month', txn_date) AS month
		,customer_id
		,COUNT(CASE 
				WHEN txn_type = 'deposit'
					THEN 1
				END) AS deposit_count
		,COUNT(CASE 
				WHEN txn_type = 'purchase'
					OR txn_type = 'withdrawal'
					THEN 1
				END) AS purchase_withdrawal_count
	FROM data_bank.customer_transactions
	GROUP BY month
		,customer_id
	)
SELECT month::DATE
    ,COUNT(customer_id) AS customer_count
FROM customer_data
WHERE deposit_count > 1
	AND purchase_withdrawal_count >= 1
GROUP BY month;

-- 4. What is the closing balance for each customer at the end of the month?
WITH monthly_balance
AS (
	SELECT DATE_TRUNC('month', txn_date) AS month
		,customer_id
		,SUM(CASE 
				WHEN txn_type = 'deposit'
					THEN txn_amount
				WHEN txn_type IN ('withdrawal', 'purchase')
					THEN (- txn_amount)
				END) AS monthly_balance
	FROM data_bank.customer_transactions
	GROUP BY customer_id
		,month
	ORDER BY customer_id
		,month
	)
SELECT customer_id
	,month
	,sum(monthly_balance) OVER (
		PARTITION BY customer_id ORDER BY month
		) AS closing_balance
FROM monthly_balance;

-- 5. What is the percentage of customers who increase their closing balance by more than 5%?
WITH monthly_balance
AS (
	SELECT DATE_TRUNC('month', txn_date) AS month
		,customer_id
		,SUM(CASE 
				WHEN txn_type = 'deposit'
					THEN txn_amount
				WHEN txn_type IN ('withdrawal', 'purchase')
					THEN (- txn_amount)
				END) AS monthly_balance
	FROM data_bank.customer_transactions
	GROUP BY customer_id
		,month
	ORDER BY customer_id
		,month
	)
	,closing_balance
AS (
	SELECT customer_id
		,month
		,sum(monthly_balance) OVER (
			PARTITION BY customer_id ORDER BY month
			) AS closing_balance
	FROM monthly_balance
	)
	,total_customers
AS (
	SELECT count(DISTINCT customer_id) AS customer_count
	FROM data_bank.customer_transactions
	)
	,monthly_increment
AS (
	SELECT customer_id
		,month
		,(
			(
				(
					closing_balance::FLOAT / NULLIF(lag(closing_balance, 1) OVER (
							PARTITION BY customer_id ORDER BY month
							), 0)::FLOAT
					) - 1
				) * 100
			)::FLOAT AS increase_percent
	FROM closing_balance
	)
SELECT month
	,100 * COUNT(CASE 
			WHEN increase_percent >= 5
				THEN 1
			END) / customer_count AS percentage_of_customers_with_more_than_5_percent_increase
FROM monthly_increment
CROSS JOIN total_customers
GROUP BY month
	,customer_count
ORDER BY month OFFSET 1