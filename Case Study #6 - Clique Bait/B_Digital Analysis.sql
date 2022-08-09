-- Using the available datasets - answer the following questions using a single query for each one:
--1. How many users are there?
SELECT COUNT(DISTINCT user_id) AS user_count
FROM clique_bait.users;

-- 2. How many cookies does each user have on average?
WITH cookie_count
AS (
	SELECT user_id
		,COUNT(1) AS cookie_count
	FROM clique_bait.users
	GROUP BY user_id
	ORDER BY user_id
	)
SELECT round(avg(cookie_count), 2) AS avg_cookies
FROM cookie_count;

-- 3. What is the unique number of visits by all users per month?
SELECT date_trunc('month', start_date)::DATE AS month
	,COUNT(DISTINCT user_id)
FROM clique_bait.users
GROUP BY month
ORDER BY month;

-- 4. What is the number of events for each event type?
SELECT event_type
	,COUNT(1)
FROM clique_bait.events
GROUP BY event_type
ORDER BY event_type;

-- 5. What is the percentage of visits which have a purchase event?
SELECT ROUND(COUNT(DISTINCT CASE 
				WHEN ei.event_name = 'Purchase'
					THEN visit_id
				END) * 100 / COUNT(DISTINCT visit_id)::NUMERIC, 2) AS percent_visits_for_purchase_event
FROM clique_bait.events e
LEFT JOIN clique_bait.event_identifier ei ON ei.event_type = e.event_type;

-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
WITH visit_count
AS (
	SELECT e.visit_id
		,MAX(CASE 
				WHEN ei.event_name = 'Purchase'
					THEN 1
				ELSE 0
				END) AS purchase_event
		,MAX(CASE 
				WHEN ph.page_name = 'Checkout'
					AND ei.event_name = 'Page View'
					THEN 1
				ELSE 0
				END) AS checkout_page
	FROM clique_bait.events e
	LEFT JOIN clique_bait.event_identifier ei ON ei.event_type = e.event_type
	LEFT JOIN clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
	GROUP BY e.visit_id
	)
SELECT ROUND((
			COUNT(CASE 
					WHEN purchase_event = 0
						AND checkout_page = 1
						THEN 1
					END) * 100 / COUNT(CASE 
					WHEN checkout_page = 1
						THEN 1
					END)::DECIMAL
			), 2)
FROM visit_count;

-- 7. What are the top 3 pages by number of views?
SELECT ph.page_name
	,COUNT(1) AS page_views
FROM clique_bait.events e
LEFT JOIN clique_bait.event_identifier ei ON ei.event_type = e.event_type
LEFT JOIN clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
WHERE ei.event_name = 'Page View'
GROUP BY ph.page_name
ORDER BY page_views DESC LIMIT 3;

-- 8. What is the number of views and cart adds for each product category?
SELECT ph.product_category
	,ei.event_name
	,COUNT(1) AS product_event_count
FROM clique_bait.events e
LEFT JOIN clique_bait.event_identifier ei ON ei.event_type = e.event_type
LEFT JOIN clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
WHERE ei.event_name IN ('Page View', 'Add to Cart')
GROUP BY ph.product_category
	,ei.event_name
ORDER BY ph.product_category
	,ei.event_name;

-- 9. What are the top 3 products by purchases?
WITH max_purchase
AS (
	SELECT u.user_id
		,MAX(e.event_time) AS max_purchase_event_time
	FROM clique_bait.events e
	INNER JOIN clique_bait.users u ON u.cookie_id = e.cookie_id
	INNER JOIN clique_bait.event_identifier ei ON ei.event_type = e.event_type
	WHERE ei.event_name = 'Purchase'
	GROUP BY u.user_id
	)
SELECT ph.page_name AS product_name
	,COUNT(1) AS purchase_count
FROM clique_bait.events e
INNER JOIN clique_bait.users u ON u.cookie_id = e.cookie_id
INNER JOIN clique_bait.event_identifier ei ON ei.event_type = e.event_type
INNER JOIN clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
INNER JOIN max_purchase mp ON mp.user_id = u.user_id
	AND e.event_time < mp.max_purchase_event_time
	AND ei.event_name = 'Add to Cart'
GROUP BY ph.page_name
ORDER BY purchase_count DESC LIMIT 3;
