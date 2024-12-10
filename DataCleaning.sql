SELECT * FROM trip_data LIMIT 100

--Check for duplicates
WITH duplicate_cte AS (
	SELECT *,
	ROW_NUMBER() OVER (
		PARTITION BY ride_id, rideable_type, started_at, ended_at, start_station_name,
			start_station_id, end_station_name, end_station_id, start_lat, start_lng,
			end_lat, end_lng, member_casual
	) AS row_number
	FROM trip_data
)
SELECT *
FROM duplicate_cte
WHERE
	row_number > 1


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


SELECT * FROM trip_data WHERE ride_id = '0625A51D397A68F9'

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

-- create TripDataStaging table to remove duplicates
CREATE TABLE trip_data_staging (
	ride_id VARCHAR(50),
	rideable_type VARCHAR(50),
	started_at TIMESTAMP,
	ended_at TIMESTAMP,
	start_station_name VARCHAR(100),
	start_station_id VARCHAR(50),
	end_station_name VARCHAR(100),
	end_station_id VARCHAR(50),
	start_lat DOUBLE PRECISION,
	start_lng DOUBLE PRECISION,
	end_lat DOUBLE PRECISION,
	end_lng DOUBLE PRECISION,
	member_casual VARCHAR(15),
	row_number INT
)


INSERT INTO trip_data_staging
SELECT *,
ROW_NUMBER() OVER (
	PARTITION BY ride_id
) AS row_number
FROM trip_data

SELECT * FROM trip_data_staging LIMIT 100

SELECT * FROM trip_data_staging
WHERE row_number > 1

DELETE FROM trip_data_staging
WHERE row_number > 1

--standardizing data
SELECT DISTINCT(rideable_type) FROM trip_data_staging

SELECT DISTINCT(start_station_name)
FROM trip_data_staging 
ORDER BY start_station_name

SELECT start_station_name, TRIM(start_station_name)
FROM trip_data_staging
ORDER BY start_station_name LIMIT 50




