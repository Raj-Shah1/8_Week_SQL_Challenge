-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT ((registration_date - '2021-01-01') / 7) + 1 AS week_number
	,COUNT(1)
FROM pizza_runner.runners
GROUP BY week_number
ORDER BY week_number;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH cte_customer_orders_distinct
AS (
	SELECT DISTINCT order_id
		,order_time
	FROM customer_orders
	)
SELECT ro.runner_id
	,DATE_PART('minute', AVG(ro.pickup_time - co.order_time)) AS average_time_in_minutes
FROM pizza_runner.runner_orders ro
INNER JOIN cte_customer_orders_distinct co ON ro.order_id = co.order_id
WHERE ro.pickup_time IS NOT NULL
GROUP BY ro.runner_id
ORDER BY ro.runner_id;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- Answer is NO, as per below query output. Only 34% of correlation is found
WITH cte_orders
AS (
	SELECT co.order_id
		,COUNT(1) AS number_of_pizzas_ordered
		,ro.duration_in_minutes
	FROM pizza_runner.runner_orders ro
	INNER JOIN pizza_runner.customer_orders co ON ro.order_id = co.order_id
	WHERE ro.cancellation IS NULL
	GROUP BY co.order_id
		,ro.duration_in_minutes
	ORDER BY number_of_pizzas_ordered DESC
	)
SELECT corr("number_of_pizzas_ordered", "duration_in_minutes") AS correlation_number
FROM cte_orders;

-- 4. What was the average distance travelled for each customer?
WITH cte_customer_orders_distinct
AS (
	SELECT DISTINCT order_id
		,customer_id
	FROM customer_orders
	)
SELECT co.customer_id
	,AVG(ro.distance_in_kms)::INT AS average_distance_in_kms
FROM pizza_runner.runner_orders ro
INNER JOIN cte_customer_orders_distinct co ON ro.order_id = co.order_id
GROUP BY co.customer_id
ORDER BY co.customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(ro.duration_in_minutes) - MIN(ro.duration_in_minutes) AS max_min_difference_in_minutes
FROM pizza_runner.runner_orders ro;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- As per the below 2 queries, it can be said that
-- Runner 2 has the highest speed but it decreases to the least for delivery to customer 103.
-- Where as Runner 1 and Runner 3 have average speed for customer 101, 102, 104
WITH cte_customer_orders_distinct
AS (
	SELECT DISTINCT order_id
		,customer_id
	FROM customer_orders
	)
SELECT ro.order_id
	,ro.runner_id
	,co.customer_id
	,(ro.distance_in_kms * 60 / ro.duration_in_minutes)::DECIMAL(4, 2) AS average_speed_in_km_per_hour
FROM pizza_runner.runner_orders ro
INNER JOIN cte_customer_orders_distinct co ON ro.order_id = co.order_id
WHERE ro.cancellation IS NULL
ORDER BY average_speed_in_km_per_hour;

WITH cte_customer_orders_distinct
AS (
	SELECT DISTINCT order_id
		,customer_id
	FROM customer_orders
	)
SELECT ro.runner_id
	,co.customer_id
	,AVG((ro.distance_in_kms * 60 / ro.duration_in_minutes))::DECIMAL(4, 2) AS average_speed_in_km_per_hour
FROM pizza_runner.runner_orders ro
INNER JOIN cte_customer_orders_distinct co ON ro.order_id = co.order_id
WHERE ro.cancellation IS NULL
GROUP BY ro.runner_id
	,co.customer_id
ORDER BY average_speed_in_km_per_hour;

-- 7. What is the successful delivery percentage for each runner?
SELECT runner_id
	,(
		COUNT(CASE 
				WHEN cancellation IS NULL
					THEN 1
				END) * 100 / COUNT(1)::FLOAT
		)::DECIMAL(6, 2) AS successful_delivery_percent
FROM runner_orders
GROUP BY runner_id
ORDER BY runner_id;