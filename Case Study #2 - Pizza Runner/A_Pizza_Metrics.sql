-- 1. How many pizzas were ordered?
SELECT COUNT(1) AS pizzas_ordered
FROM pizza_runner.customer_orders;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT customer_id) AS unique_customer_orders
FROM pizza_runner.customer_orders;

-- 3. How many successful orders were delivered by each runner?
SELECT runner_id
	,COUNT(order_id) AS orders_delivered
FROM pizza_runner.runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id
ORDER BY runner_id;

-- 4. How many of each type of pizza was delivered?
SELECT pn.pizza_name
	,COUNT(1) AS pizza_delivered
FROM pizza_runner.customer_orders co
INNER JOIN pizza_runner.runner_orders ro ON co.order_id = ro.order_id
INNER JOIN pizza_runner.pizza_names pn ON pn.pizza_id = co.pizza_id
WHERE ro.cancellation IS NULL
GROUP BY pn.pizza_name
ORDER BY pn.pizza_name;

-- 5. How many Vegetarian and Meat Lovers were ordered by each customer?
SELECT pn.pizza_name
	,COUNT(1) AS pizza_delivered
FROM pizza_runner.customer_orders co
INNER JOIN pizza_runner.pizza_names pn ON pn.pizza_id = co.pizza_id
GROUP BY pn.pizza_name
ORDER BY pn.pizza_name;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT COUNT(1) AS max_no_of_pizzas_delivered
FROM pizza_runner.customer_orders co
INNER JOIN pizza_runner.runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY co.order_id
ORDER BY max_no_of_pizzas_delivered DESC LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT co.customer_id
	,COUNT(CASE 
			WHEN co.extras IS NULL
				AND co.exclusions IS NULL
				THEN 1
			END) AS no_change_orders
	,COUNT(CASE 
			WHEN co.extras IS NOT NULL
				OR co.exclusions IS NOT NULL
				THEN 1
			END) AS at_least_one_change_orders
FROM pizza_runner.customer_orders co
INNER JOIN pizza_runner.runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY co.customer_id
ORDER BY co.customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras
SELECT COUNT(1) AS pizzas_with_exclusions_and_extras
FROM pizza_runner.customer_orders co
INNER JOIN pizza_runner.runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
	AND co.exclusions IS NOT NULL
	AND co.extras IS NOT NULL;

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT EXTRACT(hour FROM order_time) AS order_hour
	,COUNT(1) AS pizza_ordered
FROM pizza_runner.customer_orders
GROUP BY order_hour
ORDER BY order_hour;

-- 10. What was the volume of orders for each day of the week?
SELECT TO_CHAR(order_time, 'Day') AS week_day
	,COUNT(1) AS pizza_ordered
FROM pizza_runner.customer_orders
GROUP BY week_day