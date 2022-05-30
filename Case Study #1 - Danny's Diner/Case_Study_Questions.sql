/* --------------------
   Case Study Questions
   --------------------*/
-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id
	,SUM(m.price) AS amount_spent
FROM dannys_diner.menu m
INNER JOIN dannys_diner.sales s ON m.product_id = s.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT s.customer_id
	,COUNT(DISTINCT s.order_date) AS number_of_visits
FROM dannys_diner.sales s
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH cte_customer_rank
AS (
	SELECT DISTINCT customer_id
		,product_id
		,rank() OVER (
			PARTITION BY customer_id ORDER BY order_date
			) AS first_item_purchase_rank
	FROM dannys_diner.sales
	)
SELECT cr.customer_id
	,string_agg(m.product_name, ', ')
FROM dannys_diner.menu m
INNER JOIN cte_customer_rank cr ON m.product_id = cr.product_id
WHERE first_item_purchase_rank = 1
GROUP BY cr.customer_id
ORDER BY cr.customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name
	,COUNT(1) AS purchase_count
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY purchase_count DESC LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH cte_product_purchase_count AS (
    SELECT customer_id
        ,product_id
        ,COUNT(1)
        ,rank() OVER (
            PARTITION BY customer_id ORDER BY COUNT(1) DESC
            ) AS product_rank
    FROM dannys_diner.sales
    GROUP BY customer_id
        ,product_id
    ORDER BY customer_id
        ,product_id
    )
SELECT pp.customer_id
	,string_agg(m.product_name, ', ') AS popular_product_name
FROM cte_product_purchase_count pp
INNER JOIN dannys_diner.menu m ON pp.product_id = m.product_id
WHERE pp.product_rank = 1
GROUP BY pp.customer_id
ORDER BY pp.customer_id;

-- 6. Which item was purchased first by the customer after they became a member?
WITH cte_customer_rank
AS (
	SELECT s.customer_id
		,s.product_id
		,rank() OVER (
			PARTITION BY s.customer_id ORDER BY s.order_date
			) AS first_item_purchase_rank
	FROM dannys_diner.sales s
	INNER JOIN dannys_diner.members mb ON mb.customer_id = s.customer_id
		AND mb.join_date <= s.order_date
	)
SELECT cr.customer_id
	,string_agg(m.product_name, ', ')
FROM dannys_diner.menu m
INNER JOIN cte_customer_rank cr ON m.product_id = cr.product_id
WHERE first_item_purchase_rank = 1
GROUP BY cr.customer_id
ORDER BY cr.customer_id;

-- 7. Which item was purchased just before the customer became a member?
WITH cte_customer_rank
AS (
	SELECT s.customer_id
		,s.product_id
		,rank() OVER (
			PARTITION BY s.customer_id ORDER BY s.order_date DESC
			) AS first_item_purchase_rank
	FROM dannys_diner.sales s
	INNER JOIN dannys_diner.members mb ON mb.customer_id = s.customer_id
		AND mb.join_date > s.order_date
	)
SELECT cr.customer_id
	,string_agg(m.product_name, ', ')
FROM dannys_diner.menu m
INNER JOIN cte_customer_rank cr ON m.product_id = cr.product_id
WHERE first_item_purchase_rank = 1
GROUP BY cr.customer_id
ORDER BY cr.customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id
	,COUNT(m.product_id) AS items_purchased_before_joining
	,COALESCE(SUM(m.price), 0) AS amount_spent_before_joining
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.members mb ON mb.customer_id = s.customer_id
	AND mb.join_date > s.order_date
LEFT JOIN dannys_diner.menu m ON m.product_id = s.product_id
	AND mb.join_date > s.order_date
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id
	,SUM(CASE 
			WHEN m.product_name = 'sushi'
				THEN m.price * 20
			ELSE m.price * 10
			END) AS customer_points
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m ON m.product_id = s.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id
	,SUM(CASE 
			WHEN (
					m.product_name = 'sushi'
					OR (
						s.order_date >= mb.join_date
						AND s.order_date < mb.join_date + INTERVAL '1 WEEK'
						)
					)
				THEN m.price * 20
			ELSE m.price * 10
			END) AS customer_points
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m ON m.product_id = s.product_id
LEFT JOIN dannys_diner.members mb ON mb.customer_id = s.customer_id
GROUP BY s.customer_id
ORDER BY s.customer_id;
