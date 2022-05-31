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
-- 1. What are the standard ingredients for each pizza?
SELECT pn.pizza_name
	,STRING_AGG(pt.topping_name, ', ')
FROM pizza_runner.pizza_names pn 
INNER JOIN tmp_pizza_recipes pr ON pn.pizza_id = pr.pizza_id
INNER JOIN pizza_runner.pizza_toppings pt ON pr.topping_id = pt.topping_id
GROUP BY pn.pizza_name

-- 2. What was the most commonly added extra?
SELECT pt.topping_name AS most_common_extra_topping
FROM tmp_pizza_extras pe 
INNER JOIN pizza_runner.pizza_toppings pt ON pe.topping_id = pt.topping_id
GROUP BY pt.topping_name
ORDER BY COUNT(pt.topping_name) DESC LIMIT 1

-- 3. What was the most common exclusion?
SELECT pt.topping_name AS most_common_excluded_topping
FROM tmp_pizza_exclusions pe 
INNER JOIN pizza_runner.pizza_toppings pt ON pe.topping_id = pt.topping_id
GROUP BY pt.topping_name
ORDER BY COUNT(pt.topping_name) DESC LIMIT 1

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
	-- 	Meat Lovers
	-- 	Meat Lovers - Exclude Beef
	-- 	Meat Lovers - Extra Bacon
	-- 	Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
	
WITH cte_topping_exclusions
AS (
	SELECT pe.record_id
		,' - Exclude ' || STRING_AGG(pt.topping_name, ', ') AS excluded_toppings
	FROM tmp_pizza_exclusions pe 
	INNER JOIN pizza_runner.pizza_toppings pt ON pe.topping_id = pt.topping_id
	GROUP BY record_id
), cte_topping_extras
AS (
	SELECT pe.record_id
		,' - Extra ' || STRING_AGG(pt.topping_name, ', ') AS extra_toppings
	FROM tmp_pizza_extras pe 
	INNER JOIN pizza_runner.pizza_toppings pt ON pe.topping_id = pt.topping_id
	GROUP BY record_id
)
SELECT order_id
	,customer_id
	,CASE WHEN pn.pizza_name = 'Meatlovers'
		THEN 'Meat Lovers' || COALESCE(exc.excluded_toppings, '') || COALESCE(ext.extra_toppings, '')
		WHEN pn.pizza_name = 'Vegetarian'
		THEN 'Vegetarian Lovers' || COALESCE(exc.excluded_toppings, '') || COALESCE(ext.extra_toppings, '')
		END AS order_data
FROM tmp_customer_orders co 
INNER JOIN pizza_runner.pizza_names pn ON co.pizza_id = pn.pizza_id
LEFT JOIN cte_topping_exclusions exc ON exc.record_id = co.record_id
LEFT JOIN cte_topping_extras ext ON ext.record_id = co.record_id
ORDER BY order_id,
	customer_id

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
	-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
	
WITH pizza_extras
AS (
	SELECT pe.record_id
		,co.order_id
		,co.customer_id
		,pn.pizza_name
		,pt.topping_name
		,pe.topping_id
	FROM tmp_pizza_extras pe
	INNER JOIN tmp_customer_orders co ON co.record_id = pe.record_id
	INNER JOIN pizza_runner.pizza_names pn ON pn.pizza_id = co.pizza_id
	INNER JOIN pizza_runner.pizza_toppings pt ON pt.topping_id = pe.topping_id
	)
	,order_topping_count
AS (
	SELECT COALESCE(co.record_id, ext.record_id) AS record_id1
		,COALESCE(co.order_id, ext.order_id) AS order_id1
		,COALESCE(co.customer_id, ext.customer_id) AS customer_id1
		,COALESCE(pn.pizza_name, ext.pizza_name) AS pizza_name1
		,COALESCE(pt.topping_name, ext.topping_name) AS topping_name1
		,COUNT(pr.topping_id) - COUNT(exc.topping_id) + COUNT(ext.topping_id) AS topping_count1
	FROM tmp_customer_orders co
	INNER JOIN tmp_pizza_recipes pr ON co.pizza_id = pr.pizza_id
	INNER JOIN pizza_runner.pizza_names pn ON pn.pizza_id = co.pizza_id
	INNER JOIN pizza_runner.pizza_toppings pt ON pt.topping_id = pr.topping_id
	LEFT JOIN tmp_pizza_exclusions exc ON exc.record_id = co.record_id
		AND exc.topping_id = pr.topping_id
	FULL OUTER JOIN pizza_extras ext ON ext.record_id = co.record_id
		AND ext.topping_id = pr.topping_id
	GROUP BY record_id1
		,order_id1
		,pizza_name1
		,customer_id1
		,topping_name1
	ORDER BY record_id1
		,lower(COALESCE(pt.topping_name, ext.topping_name))
	)
SELECT order_id1
	,customer_id1
	,CONCAT (
		pizza_name1
		,': '
		,STRING_AGG(CASE 
				WHEN topping_count1 = 1
					THEN topping_name1
				WHEN topping_count1 = 2
					THEN '2x' || topping_name1
				ELSE ''
				END, ', ')
		) AS topping_data
FROM order_topping_count
GROUP BY record_id1
	,order_id1
	,customer_id1
	,pizza_name1

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH cte_pizza_count AS 
(
	SELECT pr.topping_id
		,COUNT(pr.topping_id) AS topping_count
	FROM tmp_customer_orders co
	INNER JOIN tmp_pizza_recipes pr ON co.pizza_id = pr.pizza_id
	GROUP BY pr.topping_id
)
,topping_exclusion_count AS
(
	SELECT topping_id
		,COUNT(topping_id) AS topping_count
	FROM tmp_pizza_exclusions
	GROUP BY topping_id
)
,topping_extra_count AS
(
	SELECT topping_id
		,COUNT(topping_id) AS topping_count
	FROM tmp_pizza_extras
	GROUP BY topping_id
)
SELECT pt.topping_name
	,pc.topping_count - COALESCE(exc.topping_count,0) + COALESCE(ext.topping_count, 0) AS topping_count
FROM cte_pizza_count pc
LEFT JOIN topping_exclusion_count exc ON exc.topping_id = pc.topping_id
LEFT JOIN topping_extra_count ext ON ext.topping_id = pc.topping_id
INNER JOIN pizza_runner.pizza_toppings pt ON pt.topping_id = pc.topping_id 
ORDER BY topping_count DESC