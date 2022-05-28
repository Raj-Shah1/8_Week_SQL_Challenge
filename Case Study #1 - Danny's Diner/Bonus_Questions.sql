-- Bonus Question 1 - Join All The Things
SELECT s.customer_id
	,s.order_date
	,m.product_name
	,m.price
	,CASE 
		WHEN mb.customer_id IS NOT NULL
			THEN 'Y'
		ELSE 'N'
		END AS member
FROM dannys_diner.menu m
INNER JOIN dannys_diner.sales s ON m.product_id = s.product_id
LEFT JOIN dannys_diner.members mb ON mb.customer_id = s.customer_id
	AND s.order_date >= mb.join_date
ORDER BY customer_id
	,order_date
	,product_name;

-- Bonus Question 2 - Rank All The Things
SELECT s.customer_id
	,s.order_date
	,m.product_name
	,m.price
	,CASE 
		WHEN mb.customer_id IS NOT NULL
			THEN 'Y'
		ELSE 'N'
		END AS member
	,CASE 
		WHEN mb.customer_id IS NOT NULL
			THEN rank() OVER (
					PARTITION BY mb.customer_id ORDER BY s.order_date
					)
		ELSE NULL
		END AS ranking
FROM dannys_diner.menu m
INNER JOIN dannys_diner.sales s ON m.product_id = s.product_id
LEFT JOIN dannys_diner.members mb ON mb.customer_id = s.customer_id
	AND s.order_date >= mb.join_date
ORDER BY s.customer_id
	,s.order_date
	,ranking;
