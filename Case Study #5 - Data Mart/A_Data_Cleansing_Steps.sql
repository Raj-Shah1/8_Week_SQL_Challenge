-- A. Data Cleansing Steps
-- 1. Convert the week_date to a DATE format
ALTER TABLE data_mart.weekly_sales ALTER COLUMN week_date TYPE DATE USING TO_DATE (
	week_date
	,'DD/MM/YY'
	)::DATE;

-- 2. Add a week_number as the second column for each week_date value, 
-- for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
ALTER TABLE data_mart.weekly_sales ADD COLUMN week_number INTEGER;

UPDATE data_mart.weekly_sales
SET week_number = ((week_date - date_trunc('year', week_date::DATE)::DATE) / 7) + 1;

-- 3. Add a month_number with the calendar month for each week_date value as the 3rd column
ALTER TABLE data_mart.weekly_sales ADD COLUMN month_number INTEGER;

UPDATE data_mart.weekly_sales
SET month_number = EXTRACT(MONTH FROM week_date);

-- 4. Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
ALTER TABLE data_mart.weekly_sales ADD COLUMN calendar_year INTEGER;

UPDATE data_mart.weekly_sales
SET calendar_year = EXTRACT(YEAR FROM week_date);

-- 5. Add a new column called age_band after the original segment column 
-- using the following mapping on the number inside the segment value
-- segment	age_band
-- 1	Young Adults
-- 2	Middle Aged
-- 3 or 4	Retirees
ALTER TABLE data_mart.weekly_sales ADD COLUMN age_band VARCHAR(12);

UPDATE data_mart.weekly_sales
SET age_band = CASE 
		WHEN segment IS NULL
			OR segment = 'null'
			THEN NULL
		WHEN substring(segment, 2, 1)::INT = 1
			THEN 'Young Adults'
		WHEN substring(segment, 2, 1)::INT = 2
			THEN 'Middle Aged'
		WHEN substring(segment, 2, 1)::INT IN (3, 4)
			THEN 'Retirees'
		ELSE NULL
		END;

-- 6. Add a new demographic column using the following mapping 
-- for the first letter in the segment values:
-- segment	demographic
-- C	Couples
-- F	Families
ALTER TABLE data_mart.weekly_sales ADD COLUMN demographic VARCHAR(8);

UPDATE data_mart.weekly_sales
SET demographic = CASE 
		WHEN segment IS NULL
			OR segment = 'null'
			THEN NULL
		WHEN substring(segment, 1, 1) = 'C'
			THEN 'Couples'
		WHEN substring(segment, 1, 1) = 'F'
			THEN 'Families'
		ELSE NULL
		END;

-- 7. Ensure all null string values with an "unknown" string value 
-- in the original segment column as well as the new age_band and demographic columns
ALTER TABLE data_mart.weekly_sales ALTER COLUMN segment TYPE VARCHAR(7);

UPDATE data_mart.weekly_sales
SET segment = 'unknown'
WHERE segment IS NULL
	OR segment = 'null';

UPDATE data_mart.weekly_sales
SET age_band = 'unknown'
WHERE age_band IS NULL
	OR age_band = 'null';

UPDATE data_mart.weekly_sales
SET demographic = 'unknown'
WHERE demographic IS NULL
	OR demographic = 'null';

-- 8. Generate a new avg_transaction column as the sales value 
-- divided by transactions rounded to 2 decimal places for each record
ALTER TABLE data_mart.weekly_sales ADD COLUMN avg_transaction DECIMAL(10, 2);

UPDATE data_mart.weekly_sales
SET avg_transaction = round((sales::NUMERIC(12, 4) / transactions::NUMERIC(12, 4)), 2);
