-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? 
-- Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

-- Solution: Any number of pizzas can be added, just the database needs to be updated with pizza name, id and topping details
INSERT INTO pizza_runner.pizza_names VALUES (3, 'Supreme');

WITH supreme_pizza
AS (
	SELECT 0 AS id
		,pizza_id
	FROM pizza_runner.pizza_names
	WHERE pizza_name = 'Supreme'
	)
	,toppings
AS (
	SELECT 0 AS id
		,STRING_AGG(topping_id::VARCHAR, ', ') AS toppings
	FROM pizza_runner.pizza_toppings
	)
INSERT INTO pizza_runner.pizza_recipes (
	SELECT pizza_id
	,toppings FROM supreme_pizza sp INNER JOIN toppings t ON sp.id = t.id
	);