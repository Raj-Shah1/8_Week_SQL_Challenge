-- A. Customer Nodes Exploration
-- 1. How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM data_bank.customer_nodes;

-- 2. What is the number of nodes per region?
SELECT n.region_id
	,r.region_name
	,COUNT(DISTINCT n.node_id) AS unique_nodes
	,COUNT(n.node_id) AS total_nodes
FROM data_bank.customer_nodes n
LEFT JOIN data_bank.regions r ON r.region_id = n.region_id
GROUP BY n.region_id
	,r.region_name
ORDER BY n.region_id;

-- 3. How many customers are allocated to each region?
SELECT n.region_id
	,r.region_name
	,COUNT(DISTINCT n.customer_id) AS customer_count
FROM data_bank.customer_nodes n
LEFT JOIN data_bank.regions r ON r.region_id = n.region_id
GROUP BY n.region_id
	,r.region_name
ORDER BY n.region_id;

-- 4. How many days on average are customers reallocated to a different node?
SELECT ROUND(AVG(DATE_PART('day', end_date::TIMESTAMP - start_date::TIMESTAMP))) AS avg_rellocation_days
FROM data_bank.customer_nodes
WHERE end_date != (
		SELECT MAX(end_date)
		FROM data_bank.customer_nodes
		);

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
SELECT n.region_id
	,r.region_name
	,PERCENTILE_CONT(0.5) WITHIN
GROUP (
		ORDER BY DATE_PART('day', end_date::TIMESTAMP - start_date::TIMESTAMP)
		) AS median
	,PERCENTILE_CONT(0.8) WITHIN
GROUP (
		ORDER BY DATE_PART('day', end_date::TIMESTAMP - start_date::TIMESTAMP)
		) AS median_80th_percentile
	,PERCENTILE_CONT(0.95) WITHIN
GROUP (
		ORDER BY DATE_PART('day', end_date::TIMESTAMP - start_date::TIMESTAMP)
		) AS median_95th_percentile
FROM data_bank.customer_nodes n
LEFT JOIN data_bank.regions r ON r.region_id = n.region_id
WHERE n.end_date != (
		SELECT MAX(end_date)
		FROM data_bank.customer_nodes
		)
GROUP BY n.region_id
	,r.region_name
ORDER BY n.region_id;