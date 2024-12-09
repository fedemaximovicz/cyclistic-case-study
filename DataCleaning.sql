SELECT * FROM trip_data LIMIT 100

--Check for duplicates
WITH duplicate_cte AS (
	SELECT *,
	ROW_NUMBER() OVER (
		PARTITION BY ride_id
	) AS row_number
	FROM trip_data
)
SELECT *
FROM duplicate_cte
WHERE
	row_number > 1


SELECT * FROM trip_data WHERE ride_id = '0354FD0756337B59'

--count number of duplicates

-- SELECT ride_id, COUNT(*) AS duplicate_count
-- FROM trip_data
-- GROUP BY ride_id
-- HAVING COUNT(*) > 1

SELECT COUNT(*)
FROM (
	SELECT
	ROW_NUMBER() OVER (
		PARTITION BY ride_id
	) AS row_number
	FROM trip_data
)subquery
WHERE row_number > 1;
-- 211 duplicates found