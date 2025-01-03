SELECT
	member_casual,
	count (*) AS number_of_trips
FROM
	trip_data_staging
GROUP BY
	member_casual



SELECT
	COUNT(*) AS total_trips
FROM
	trip_data_staging


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
    TO_CHAR(trip_date, 'Day') AS day_of_week,
    AVG(trip_count) FILTER(WHERE member_casual = 'member') AS avg_trips_member,
	AVG(trip_count) FILTER(WHERE member_casual = 'casual') AS avg_trips_casual
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
    day_of_week
ORDER BY
	avg_trips_member DESC



SELECT 
    EXTRACT(HOUR FROM trip_hour) AS hour_of_day,
    AVG(trip_count) FILTER(WHERE member_casual = 'member') AS avg_trips_member,
	AVG(trip_count) FILTER(WHERE member_casual = 'casual') AS avg_trips_casual
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
    hour_of_day
ORDER BY
	hour_of_day


	
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



--Average trip minutes by user type
SELECT 
	member_casual,
	AVG (EXTRACT(EPOCH FROM (ended_at - started_at)) / 60) AS avg_trip_duration_minutes
FROM
	trip_data_staging
WHERE
	z_score <= 3
GROUP BY
	member_casual


-- average trip duration by day of week
SELECT 
    TO_CHAR(started_at, 'Day') AS day_of_week,
    AVG (EXTRACT(EPOCH FROM (ended_at - started_at)) / 60) 
		FILTER (WHERE member_casual = 'member') AS avg_trip_duration_member,
	AVG (EXTRACT(EPOCH FROM (ended_at - started_at)) / 60) 
		FILTER (WHERE member_casual = 'casual') AS avg_trip_duration_casual
FROM
	trip_data_staging
WHERE
	z_score <= 3
GROUP BY
	day_of_week



--average trip duration by hour of day
SELECT 
    EXTRACT(HOUR FROM started_at) AS hour_of_day,
    AVG (EXTRACT(EPOCH FROM (ended_at - started_at)) / 60) 
		FILTER (WHERE member_casual = 'member') AS avg_trip_duration_member,
	AVG (EXTRACT(EPOCH FROM (ended_at - started_at)) / 60) 
		FILTER (WHERE member_casual = 'casual') AS avg_trip_duration_casual
FROM
	trip_data_staging
WHERE
	z_score <= 3
GROUP BY
	hour_of_day



-- average trip duration by month
SELECT 
    TO_CHAR(started_at, 'Month') AS month,
    AVG (EXTRACT(EPOCH FROM (ended_at - started_at)) / 60) 
		FILTER (WHERE member_casual = 'member') AS avg_trip_duration_member,
	AVG (EXTRACT(EPOCH FROM (ended_at - started_at)) / 60) 
		FILTER (WHERE member_casual = 'casual') AS avg_trip_duration_casual
FROM
	trip_data_staging
WHERE
	z_score <= 3
GROUP BY
	month




--total hours by user type
SELECT 
	member_casual,
	ROUND(SUM (EXTRACT(EPOCH FROM (ended_at - started_at)) / 3600),2) AS total_hours
FROM
	trip_data_staging
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
	start_station_name,
	AVG(start_lat) AS avg_latitude,
	AVG(start_lng) AS avg_longitude,
	AVG (EXTRACT(EPOCH FROM (ended_at - started_at)) / 60) 
		FILTER (WHERE member_casual = 'member') AS avg_trip_duration_member,
	AVG (EXTRACT(EPOCH FROM (ended_at - started_at)) / 60) 
		FILTER (WHERE member_casual = 'casual') AS avg_trip_duration_casual
FROM 
	trip_data_staging
WHERE
	start_station_name IS NOT NULL AND z_score <= 3
GROUP BY
	start_station_name



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
