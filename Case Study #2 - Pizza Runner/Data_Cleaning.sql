-- Fix customer_orders and runner_orders data

-- 1. Handle null strings and empty strings
UPDATE pizza_runner.customer_orders
SET exclusions = NULL
WHERE exclusions IN ('null', '');

UPDATE pizza_runner.customer_orders
SET extras = NULL
WHERE extras IN ('null', '');

UPDATE pizza_runner.runner_orders
SET pickup_time = NULL
WHERE pickup_time IN ('null', '');

UPDATE pizza_runner.runner_orders
SET distance = NULL
WHERE distance IN ('null', '');

UPDATE pizza_runner.runner_orders
SET duration = NULL
WHERE duration IN ('null', '');

UPDATE pizza_runner.runner_orders
SET cancellation = NULL
WHERE cancellation IN ('null', '');

-- 2. Fix duration, distance and pickup_time values and update there data types
-- In below REGEXP_REPLACE, [[:alpha:]] checks for alphabets and 'g' is a function which tells to remove all alphabets not just the first one
WITH cte_runner_orders_updated
AS (
	SELECT order_id
		,REGEXP_REPLACE(distance, '[[:alpha:]]', '', 'g') AS distance_in_km
		,REGEXP_REPLACE(duration, '[[:alpha:]]', '', 'g') AS duration_in_minutes
	FROM pizza_runner.runner_orders
	)
UPDATE pizza_runner.runner_orders ro
SET duration = rou.duration_in_minutes
	,distance = rou.distance_in_km
FROM cte_runner_orders_updated rou
WHERE ro.order_id = rou.order_id;

ALTER TABLE pizza_runner.runner_orders RENAME COLUMN duration TO duration_in_minutes;

ALTER TABLE pizza_runner.runner_orders RENAME COLUMN distance TO distance_in_kms;

ALTER TABLE pizza_runner.runner_orders 
ALTER COLUMN duration_in_minutes TYPE INTEGER USING duration_in_minutes::INTEGER,
ALTER COLUMN distance_in_kms TYPE DECIMAL(4, 1) USING distance_in_kms::DECIMAL(4, 1),
ALTER COLUMN pickup_time TYPE TIMESTAMP USING pickup_time::TIMESTAMP;
