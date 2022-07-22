-- A. Data Cleansing Steps
-- 1. Convert the week_date to a DATE format

-- 2. Add a week_number as the second column for each week_date value, 
-- for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc

-- 3. Add a month_number with the calendar month for each week_date value as the 3rd column

-- 4. Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values

-- 5. Add a new column called age_band after the original segment column 
-- using the following mapping on the number inside the segment value
-- segment	age_band
-- 1	Young Adults
-- 2	Middle Aged
-- 3 or 4	Retirees

-- 6. Add a new demographic column using the following mapping 
-- for the first letter in the segment values:
-- segment	demographic
-- C	Couples
-- F	Families

-- 8. Generate a new avg_transaction column as the sales value 
-- divided by transactions rounded to 2 decimal places for each record

DROP TABLE IF EXISTS data_mart.clean_weekly_sales;
CREATE TABLE data_mart.clean_weekly_sales AS 
SELECT TO_DATE(week_date, 'DD/MM/YY') AS week_date
	,DATE_PART('week', TO_DATE(week_date, 'DD/MM/YY')) AS week_number
	,DATE_PART('month', TO_DATE(week_date, 'DD/MM/YY')) AS month_number
	,DATE_PART('year', TO_DATE(week_date, 'DD/MM/YY')) AS calendar_year
	,region
	,platform
	,CASE 
		WHEN segment = 'null'
			THEN 'unknown'
		ELSE segment
		END AS segment
	,CASE 
		WHEN segment = 'null'
			THEN 'unknown'
		WHEN substring(segment, 2, 1)::INT = 1
			THEN 'Young Adults'
		WHEN substring(segment, 2, 1)::INT = 2
			THEN 'Middle Aged'
		WHEN substring(segment, 2, 1)::INT IN (3, 4)
			THEN 'Retirees'
		ELSE NULL
		END AS age_band
	,CASE 
		WHEN segment = 'null'
			THEN 'unknown'
		WHEN substring(segment, 1, 1) = 'C'
			THEN 'Couples'
		WHEN substring(segment, 1, 1) = 'F'
			THEN 'Families'
		ELSE 'unknown'
		END AS demographic
	,customer_type
	,transactions
	,sales
	,round(sales::NUMERIC / transactions::NUMERIC, 2) AS avg_transaction
FROM data_mart.weekly_sales;
