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



SELECT * FROM trip_data_staging ORDER BY ride_id LIMIT 100



SELECT * FROM trip_data_staging
WHERE row_number > 1



DELETE FROM trip_data_staging
WHERE row_number > 1



--drop row_number column
ALTER TABLE trip_data_staging DROP COLUMN row_number



--standardizing data
SELECT DISTINCT(rideable_type) FROM trip_data_staging



SELECT DISTINCT(start_station_name)
FROM trip_data_staging 
ORDER BY start_station_name



--check if some rows of start_station_name have extra spaces
SELECT start_station_name, TRIM(start_station_name) AS trimmed_station_name
FROM trip_data_staging
WHERE start_station_name <> TRIM(start_station_name)
ORDER BY start_station_name



SELECT * FROM trip_data_staging
WHERE start_station_name = 'Public Rack - Forest Glen Station '



--trim the values of start_station_name columns
UPDATE trip_data_staging
SET start_station_name = TRIM(start_station_name)



--same process for end_station_name
SELECT end_station_name, TRIM(end_station_name) AS trimmed_station_name
FROM trip_data_staging
WHERE end_station_name <> TRIM(end_station_name)
ORDER BY end_station_name

UPDATE trip_data_staging
SET end_station_name = TRIM(end_station_name)



--check values of member_casual column
SELECT DISTINCT(member_casual) FROM trip_data_staging



-- Checking for nulls
SELECT 
	* 
FROM 
	trip_data_staging
WHERE 
	rideable_type IS NULL OR started_at IS NULL OR ended_at IS NULL



SELECT 
	* 
FROM 
	trip_data_staging
WHERE 
	start_station_name IS NULL OR end_station_name is NULL



SELECT DISTINCT 
	(start_station_name) 
FROM 
	trip_data_staging
WHERE 
	start_lat >= 41.93 AND start_lat < 41.94 
--159 rows, no posibilities of estimating what the start station is



SELECT
	start_station_name,
	COUNT(*) AS number_of_trips
FROM
	trip_data_staging
WHERE
	start_lat >= 41.93 AND start_lat < 41.94 
GROUP BY
	start_station_name
ORDER BY number_of_trips DESC



SELECT
	DISTINCT (start_lat)
FROM
	trip_data_staging
WHERE
	start_station_id IS NULL



SELECT COUNT(*) FROM trip_data_staging



SELECT 
	* 
FROM 
	trip_data_staging
WHERE 
	start_station_name IS NULL AND end_station_name IS NULL
--ORDER BY started_at



SELECT
	*
FROM
	trip_data_staging
WHERE
	start_lat IS NULL OR start_lng IS NULL 



SELECT
	*
FROM
	trip_data_staging
WHERE
	end_lat IS NULL OR end_lng IS NULL 



SELECT
	rideable_type,
	COUNT(*) FILTER (WHERE end_lat IS NULL OR end_lng IS NULL) AS null_destinations
FROM
	trip_data_staging
GROUP BY
	rideable_type
	


SELECT
	member_casual,
	COUNT(*) FILTER (WHERE end_lat IS NULL OR end_lng IS NULL) AS null_destinations
FROM
	trip_data_staging
GROUP BY
	member_casual



DELETE
FROM 
	trip_data_staging
WHERE
	end_lat IS NULL AND end_lng IS NULL



SELECT
	COUNT (*)
FROM
	trip_data_staging
WHERE
	rideable_type = 'classic_bike'



SELECT 
	DISTINCT(rideable_type) 
FROM 
	trip_data_staging
WHERE 
	start_station_name IS NULL AND end_station_name IS NULL



SELECT
	*
FROM
	trip_data_staging
WHERE
	start_station_name IS NULL AND start_station_id IS NOT NULL



SELECT
	*
FROM
	trip_data_staging
WHERE
	end_station_name IS NULL AND end_station_id IS NOT NULL



SELECT
	rideable_type,
	COUNT (*) FILTER (WHERE start_station_name IS NULL AND end_station_name IS NULL) AS null_stations
FROM
	trip_data_staging
GROUP BY
	rideable_type



SELECT
	member_casual,
	COUNT (*) FILTER (WHERE start_station_name IS NULL AND end_station_name IS NULL) AS null_stations
FROM
	trip_data_staging
GROUP BY
	member_casual



SELECT
	rideable_type,
	COUNT (*) FILTER (WHERE start_station_name IS NULL OR end_station_name IS NULL) AS null_stations
FROM
	trip_data_staging
GROUP BY
	rideable_type



SELECT
	member_casual,
	COUNT (*) FILTER (WHERE start_station_name IS NULL OR end_station_name IS NULL) AS null_stations
FROM
	trip_data_staging
GROUP BY
	member_casual



SELECT
	COUNT (*) AS electric_bike_trips
FROM
	trip_data_staging
WHERE
	rideable_type = 'electric_bike'
--trips made with electric bikes: 2991565



SELECT
	DATE_TRUNC('month', started_at) AS month,
	COUNT (*) FILTER (WHERE start_station_name IS NULL AND end_station_name IS NULL) AS null_stations
FROM
	trip_data_staging
GROUP BY
	month
ORDER BY 
	null_Stations DESC
	


SELECT * FROM trip_data_staging
WHERE member_casual IS NULL




SELECT
	MAX(EXTRACT(EPOCH FROM (ended_at - started_at)) / 60)
FROM trip_data_staging



SELECT
	member_casual,
	COUNT(*)
FROM
	trip_data_staging
WHERE
	(EXTRACT(EPOCH FROM (ended_at - started_at)) / 60) > 500
GROUP BY member_casual



SELECT
	member_casual,
	COUNT(*)
FROM
	trip_data_staging
WHERE
	(EXTRACT(EPOCH FROM (ended_at - started_at)) / 60) > 1000
GROUP BY member_casual



ALTER TABLE trip_data_staging ADD COLUMN trip_duration_minutes NUMERIC;


UPDATE
    trip_data_staging
SET
	trip_duration_minutes = EXTRACT(EPOCH FROM (ended_at - started_at)) / 60


SELECT * FROM trip_data_staging LIMIT 100



WITH stats AS (
    SELECT 
        AVG(trip_duration_minutes) AS mean_duration,
        STDDEV(trip_duration_minutes) AS stddev_duration
    FROM 
        trip_data_staging
)
SELECT 
    t.*,
    (trip_duration_minutes - s.mean_duration) 
		/ s.stddev_duration AS z_score
FROM 
    trip_data_staging t, stats s
WHERE 
    ABS(
		(trip_duration_minutes - s.mean_duration) 
		/ s.stddev_duration
	) > 3;




ALTER TABLE trip_data_staging ADD COLUMN z_score NUMERIC;


WITH stats AS (
    SELECT 
        AVG(trip_duration_minutes) AS mean_duration,
        STDDEV(trip_duration_minutes) AS stddev_duration
    FROM 
        trip_data_staging
)
UPDATE
    trip_data_staging
SET
	z_score = (trip_duration_minutes - (SELECT mean_duration FROM stats))
		/ (SELECT stddev_duration FROM stats)



SELECT
	*
FROM
	trip_data_staging
WHERE
	ABS(z_score) > 3


SELECT
	MIN(trip_duration_minutes),
	MAX(trip_duration_minutes)
FROM
	trip_data_staging
WHERE
	ABS(z_score) > 3


SELECT
	MIN(trip_duration_minutes),
	MAX(trip_duration_minutes)
FROM
	trip_data_staging
WHERE
	ABS(z_score) <= 3


	
--found records with negative trip durations
SELECT 
	* 
FROM 
	trip_data_staging 
WHERE 
	trip_duration_minutes < 0



SELECT
	*
FROM
	trip_data_staging
WHERE
	trip_duration_minutes < 2


SELECT AVG(trip_duration_minutes) FROM trip_data_staging
SELECT STDDEV(trip_duration_minutes) FROM trip_data_staging


--removing outliers
DELETE FROM 
	trip_data_staging 
WHERE 
	trip_duration_minutes < 2



DELETE FROM
	trip_data_staging
WHERE
	ABS(z_score) > 3
