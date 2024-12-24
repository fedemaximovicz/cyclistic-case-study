SELECT
	member_casual,
	count (*) AS number_of_trips
FROM
	trip_data_staging
GROUP BY
	member_casual



SELECT
	rideable_type,
	count(*) FILTER (WHERE member_casual = 'casual') AS trips_casual,
	count (*) FILTER (WHERE member_casual = 'member') AS trips_member
FROM
	trip_data_staging
GROUP BY 
	rideable_type



SELECT
	DATE_TRUNC('month', started_at) AS month,
	COUNT (*) FILTER (WHERE member_casual = 'member') AS member_trips,
	COUNT (*) FILTER (WHERE member_casual = 'casual') AS casual_trips
FROM
	trip_data_staging
GROUP BY
	month
ORDER BY 
	month



SELECT
	DATE_TRUNC('month', started_at) AS month,
	COUNT (*) FILTER (WHERE member_casual = 'member') AS member_trips
FROM
	trip_data_staging
GROUP BY
	month
ORDER BY 
	member_trips DESC



SELECT
	DATE_TRUNC('month', started_at) AS month,
	COUNT (*) FILTER (WHERE member_casual = 'casual') AS casual_trips
FROM
	trip_data_staging
GROUP BY
	month
ORDER BY 
	casual_trips DESC



SELECT 
    member_casual,
    TO_CHAR(trip_date, 'Day') AS day_of_week,
    AVG(trip_count) AS avg_trips_per_day
FROM (
    SELECT 
        member_casual,
        DATE_TRUNC('day', started_at) AS trip_date,
        COUNT(*) AS trip_count
    FROM 
        trip_data_staging
    GROUP BY 
        member_casual,
        trip_date
) daily_trips
GROUP BY 
    member_casual, 
    day_of_week
ORDER BY 
    member_casual, 
    avg_trips_per_day DESC
-- Member clients tend to use the bikes on work days, while casual clients use them mostly on weekends



SELECT 
    member_casual,
    EXTRACT(HOUR FROM trip_hour) AS hour_of_day,
    AVG(trip_count) AS avg_trips_per_hour
FROM (
    SELECT 
        member_casual,
        DATE_TRUNC('hour', started_at) AS trip_hour,
        COUNT(*) AS trip_count
    FROM 
        trip_data_staging
    GROUP BY 
        member_casual,
        trip_hour
) hourly_trips
GROUP BY 
    member_casual, 
    hour_of_day
ORDER BY 
    member_casual, 
    avg_trips_per_hour DESC



SELECT 
	member_casual,
	AVG (EXTRACT(EPOCH FROM (ended_at - started_at)) / 60) AS avg_trip_duration_minutes
FROM
	trip_data_staging
GROUP BY
	member_casual



SELECT 
	member_casual,
	AVG (EXTRACT(EPOCH FROM (ended_at - started_at)) / 60) AS avg_trip_duration_minutes
FROM
	trip_data_staging
WHERE
	end_lat IS NOT NULL
GROUP BY
	member_casual



SELECT
	*,
	EXTRACT(EPOCH FROM (ended_at - started_at)) / 60 AS trip_duration_minutes
FROM
	trip_data_staging
LIMIT 1000



SELECT
	start_station_name,
	start_lat,
	start_lng,
	count(*) AS number_of_trips
FROM 
	trip_data_staging
WHERE
	start_station_name IS NOT NULL
GROUP BY
	start_station_name,
	start_lat,
	start_lng
ORDER BY 
	number_of_trips DESC

	

SELECT
	start_station_name,
	AVG(start_lat) AS avg_latitude,
	AVG(start_lng) AS avg_longitude,
	count(*) AS number_of_trips
FROM 
	trip_data_staging
WHERE
	start_station_name IS NOT NULL
GROUP BY
	start_station_name
ORDER BY 
	number_of_trips DESC



SELECT
	start_station_name,
	AVG(start_lat) AS avg_latitude,
	AVG(start_lng) AS avg_longitude,
	count(*) AS number_of_trips
FROM 
	trip_data_staging
WHERE
	start_station_name IS NOT NULL AND member_casual = 'member'
GROUP BY
	start_station_name
ORDER BY 
	number_of_trips DESC



SELECT
	start_station_name,
	AVG(start_lat) AS avg_latitude,
	AVG(start_lng) AS avg_longitude,
	count(*) AS number_of_trips
FROM 
	trip_data_staging
WHERE
	start_station_name IS NOT NULL AND member_casual = 'casual'
GROUP BY
	start_station_name
ORDER BY 
	number_of_trips DESC


SELECT
	member_casual,
	COUNT (*) FILTER (WHERE start_station_name IS NULL) AS null_count
FROM
	trip_data_staging
GROUP BY
	member_casual


	
SELECT DISTINCT (start_station_name)
FROM trip_data_staging



SELECT 
	*
FROM
	trip_data_staging
WHERE
	EXTRACT(MONTH FROM started_at) IN (9) AND member_casual = 'member' 
	AND (start_station_name IS NOT NULL AND end_station_name IS NOT NULL)



SELECT 
	*
FROM
	trip_data_staging
WHERE
	EXTRACT(MONTH FROM started_at) IN (9) AND member_casual = 'casual' 
	AND (start_station_name IS NOT NULL AND end_station_name IS NOT NULL)




SELECT
	DATE_TRUNC('day', started_at) AS day,
	COUNT (*) AS daily_trips
FROM
	trip_data_staging
GROUP BY
	day
ORDER BY 
	daily_trips DESC



SELECT
	*
FROM
	trip_data_staging
WHERE
	DATE_TRUNC('day', started_at) = '2024-09-21 00:00:00'
	AND (start_station_name IS NOT NULL AND end_station_name IS NOT NULL)
