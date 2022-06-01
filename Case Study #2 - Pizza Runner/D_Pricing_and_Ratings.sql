-- First use Data Optimization Queries to get data in optimized format to make the queries simple.

-- Data Optimization Queries
-- a. Get comma separated toppings as rows in a new temp table 
CREATE TEMP TABLE tmp_pizza_recipes AS (
	SELECT pizza_id
		,(unnest(string_to_array(toppings, ', ')))::INT AS topping_id 
	FROM pizza_runner.pizza_recipes
	);

-- b. Create a temp customer_orders table and add a primary key identity column to it
CREATE TEMP TABLE tmp_customer_orders AS (
	SELECT * FROM pizza_runner.customer_orders
	);

ALTER TABLE tmp_customer_orders ADD COLUMN record_id SERIAL PRIMARY KEY;

-- c. Get comma separated exclusions as rows in a new temp table
CREATE TEMP TABLE tmp_pizza_exclusions AS (
	SELECT record_id
		,(unnest(string_to_array(exclusions, ', ')))::INT AS topping_id
	FROM tmp_customer_orders 
	WHERE exclusions IS NOT NULL
	);

-- d. Get comma separated extras as rows in a new temp table
CREATE TEMP TABLE tmp_pizza_extras AS (
	SELECT record_id
		,(unnest(string_to_array(extras, ', ')))::INT AS topping_id 
	FROM tmp_customer_orders 
	WHERE extras IS NOT NULL
	);

-- e. Drop extras, exclusions FROM temp table as we have them as tables
ALTER TABLE tmp_customer_orders
DROP COLUMN exclusions
,DROP COLUMN extras;





-- Case Study Queries
	-- Tables To Be Used For Querying
		-- tmp_customer_orders;
		-- pizza_runner.runner_orders;
		-- pizza_runner.pizza_names;
		-- tmp_pizza_recipes;
		-- tmp_pizza_extras;
		-- tmp_pizza_exclusions;
		-- pizza_runner.pizza_toppings;
		-- pizza_runner.runners;

-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - 
-- how much money has Pizza Runner made so far if there are no delivery fees?
SELECT SUM(CASE 
			WHEN pn.pizza_name = 'Meatlovers'
				THEN 12
			WHEN pn.pizza_name = 'Vegetarian'
				THEN 10
			END) AS earnings_in_dollars
FROM tmp_customer_orders co
INNER JOIN pizza_runner.pizza_names pn ON co.pizza_id = pn.pizza_id
INNER JOIN pizza_runner.runner_orders ro ON ro.order_id = co.order_id
	AND ro.cancellation IS NULL;

-- 2. What if there was an additional $1 charge for any pizza extras?
	-- Add cheese is $1 extra
WITH extras_count
AS (
	SELECT record_id
		,COUNT(1) AS extras_amount
	FROM tmp_pizza_extras
	GROUP BY record_id
	)
SELECT SUM(CASE 
			WHEN pn.pizza_name = 'Meatlovers'
				THEN 12 + COALESCE(extras_amount, 0)
			WHEN pn.pizza_name = 'Vegetarian'
				THEN 10 + COALESCE(extras_amount, 0)
			END) AS earnings_in_dollars
FROM tmp_customer_orders co
INNER JOIN pizza_runner.pizza_names pn ON co.pizza_id = pn.pizza_id
INNER JOIN pizza_runner.runner_orders ro ON ro.order_id = co.order_id
LEFT JOIN extras_count pe ON pe.record_id = co.record_id
WHERE ro.cancellation IS NULL;

-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
-- how would you design an additional table for this new dataset - 
-- generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
CREATE TABLE pizza_runner.ratings (
	order_id INT
	,rating INT
	);
INSERT INTO ratings (
	SELECT order_id
		,floor(random() * (5)) + 1 
	FROM pizza_runner.runner_orders 
	WHERE cancellation IS NULL
	);

-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
	-- 	customer_id
	-- 	order_id
	-- 	runner_id
	-- 	rating
	-- 	order_time
	-- 	pickup_time
	-- 	Time between order and pickup
	-- 	Delivery duration
	-- 	Average speed
	-- 	Total number of pizzas

SELECT co.customer_id 
	,co.order_id
	,ro.runner_id
	,r.rating
	,co.order_time
	,ro.pickup_time
	,(ro.pickup_time - co.order_time) AS pickup_to_order_duration
	,ro.duration_in_minutes AS delivery_duration_in_minutes
	,(ro.distance_in_kms * 60/ro.duration_in_minutes) AS speed_in_kms_per_hour
	,COUNT(co.pizza_id) AS no_of_pizzas_ordered
FROM tmp_customer_orders co
INNER JOIN pizza_runner.runner_orders ro ON co.order_id = ro.order_id
INNER JOIN pizza_runner.ratings r ON r.order_id = co.order_id
GROUP BY co.customer_id 
	,co.order_id
	,ro.runner_id
	,r.rating
	,co.order_time
	,ro.pickup_time
	,pickup_to_order_duration
	,delivery_duration_in_minutes
	,speed_in_kms_per_hour
ORDER BY customer_id
	,order_id

