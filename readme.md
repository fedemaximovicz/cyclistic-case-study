![Cyclistic logo](/images/cyclistic-logo.png) 
# Cyclistic bike-share Analysis Project
This project is the first case study from the two options offered as a capstone project for the Google Data Analytics program. The project is about a fictitious bike-sharing company based in Chicago called Cyclistic. 
While the company is fictitious, the data provided for the project isn't. The data is real trip data from the City of Chicago's Divvy bicycle-sharing service. Taken from the case study instructions: "*The datasets have a different name because Cyclist is a fictional company. For the purposes of this case study, the datasets are appropriate and will enable you to answer the business questions. The data has been made available by Motivate International Inc. under this [license](https://divvybikes.com/data-license-agreement)*". For the scenario given for this Case Study the data will be interpreted as collected by Cyclistic, simulating a real-world scenario.

## Cyclistic
From the Case Study instructions provided: "*Cyclistic is a bike-share program that features more than 5,800 bicycles and 600
docking stations. Cyclistic sets itself apart by also offering reclining bikes, hand
tricycles, and cargo bikes, making bike-share more inclusive to people with disabilities
and riders who can't use a standard two-wheeled bike.*"

## Table of Contents:
The project structure is based on the six phases of Data Analysis learned in the Google Data Analytics program: Ask, Prepare, Process, Analyze, Share, and Act.
1. [Ask Phase](#ask-phase)
2. [Prepare Phase](#prepare)
3. [Processing Data](#processing)
4. [Analysis](#analysis)
5. [Dashboard](https://public.tableau.com/views/CyclisticBikeSharing_17366089123860/TripsbyClientType?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)
5. [Recommendations](#recommendations)


# Ask Phase
The aim of this project is to gain insight on how casual members and annual members use Cyclistic bikes differently, by analyzing ride data of the past 12 months. The director of marketing believes the company's future success depends on maximizing the number of annual memberships, so these insights will be used to design a new marketing strategy to increase the number of annual members.

**Three questions will guide the future marketing program:**
1. How do annual members and casual riders use Cyclistic bikes differently?
2. Why would casual riders buy Cyclistic annual memberships?
3. How can Cyclistic use digital media to influence casual riders to become members?


# Prepare
The data used for the project is Cyclistic's historical trip data (https://divvy-tripdata.s3.amazonaws.com/index.html). The last 12 months of data available will be used, starting from November 2023 up to October 2024. It's organized in 12 CSV files, since Cyclistic uploads the trip data monthly. The 12 files were decompressed and extracted into a folder named "data".

### Quality of the data
The data used in the project can be considered to be **good data**, since it meets the conditions of being **R**eliable, **O**riginal, **C**omprehensive, **C**urrent, and **C**ited. 
- **Reliable**: It's reliable since it is trip data collected by Cyclistic, it shows to be both accurate and complete
- **Original** and **Cited**: It's original and cited, the data is internal and from a first-party source since it's collected and stored by Cyclistic
- **Comprehensive**: The data is also comprehensive, since it contains the information needed to help find the answer to the questions made for this project.
- **Current**: And finally, it is current because the data is from the last 12 months of data starting from the latest data uploaded which was October 2024.

### Loading the data
The tool of choice for this project was SQL with Postgres as the RDBMS, all the csv's share the same columns

| ride_id | rideable_type | started_at | ended_at | start_station_name | start_station_id | end_station_name | end_station_id | start_lat | start_lng | end_lat | end_lng | member_casual |
|---------|----------------|------------|----------|--------------------|------------------|------------------|----------------|-----------|-----------|---------|---------|----------------|

So it was decided to put all of them on a single table called trip_data. This was achieved by using a Python script to "automate" the process of loading the 12 CSV files to the database.


The first step of this process was to create the table with the appropiate columns and data types:
```SQL
CREATE TABLE trip_data (
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
	member_casual VARCHAR(15)
)

```
No constraints were added, such as defining ride_id as a primary key, because this would have caused errors when loading the data if rows containing a duplicated ride_id were loaded.

The following Python script connects to the Postgres database using the **psycopg2** library. The credentials of the database are stored in a dictionary called DB_CONFIG, which retrieves each credential value from an .env file with the use of the **dotenv** library. The script goes through each csv file located in the indicated directory and loads them using the **COPY** method of Postgres, using the function *copy_expert*.
```python
import os
import psycopg2
from dotenv import dotenv_values

config = dotenv_values(".env")


DB_CONFIG = {
  "dbname": config["DB_NAME"],
  "user": config["USER_NAME"],
  "password": config["PASSWORD"], 
  "host": config["HOST"],
  "port": config["PORT"]
}

CSV_DIR = './data'

TABLE_NAME = 'trip_data'

#creates connection with postgres db
def connect_to_db():
  try:
    conn = psycopg2.connect(**DB_CONFIG)
    print('Connection successful...')
    return conn
  except Exception as ex:
    print(f"An error occurred when connecting to the db: {ex}")
    exit()


def load_csv(conn, csv_file):
  try:
    cur = conn.cursor()

    with open(csv_file, 'r') as f:
      cur.copy_expert(f"""
        COPY {TABLE_NAME} FROM STDIN WITH (FORMAT CSV, HEADER TRUE)
      """, f)
    
    conn.commit()
    print(f"{csv_file} successfuly loaded into {TABLE_NAME}")
  except Exception as ex:
    print(f"An error occurred while loading the data: {ex}")
  finally:
    if conn:
      cur.close()

def import_csv():
  conn = connect_to_db()
  try:
    for file_name in os.listdir(CSV_DIR):
      if file_name.endswith('.csv'):
        file_path = os.path.join(CSV_DIR, file_name)

        print(f"Processing {file_name}...")
        #this is to replace backslash for forward slash, since I'm using Windows
        file_path = file_path.replace('\\', '/')
        load_csv(conn, file_path)
  except Exception as ex:
    print(f"Error during import: {ex}")
  finally:
    conn.close()
    print('Db connection closed')

if __name__ == "__main__":
  import_csv()
```

# Processing
The first step taken to begin the data cleaning process was checking for duplicates. 
The following SQL query uses a CTE with ROW_NUMBER() and PARTITION BY, it checks for exact duplicates containing the same values in all of the columns. 
```SQL
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
```
No duplicates were found
![image shwowing the query returning no duplicates](/images/no-duplicates.png)

So knowing that each trip has a unique identifier "trip_id", which means that there should only exist one record containing a given trip_id, the next step was to check for duplicates just using that column. This is to check for duplicates rows that share the same trip_id but have different values.
```SQL
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
```
After running the query we can see that duplicates were found:
![Images showing the results of the query, duplicated values were found](/images/duplicates-found.png)

Checking a couple of duplicates, randomly selected, we can observe that they have the same values in all the columns except for the started_at and ended_at columns.
```SQL
SELECT * FROM trip_data WHERE ride_id = '0354FD0756337B59'
```
| ride_id          | rideable_type  | started_at                | ended_at                  | start_station_name | start_station_id | end_station_name | end_station_id | start_lat | start_lng | end_lat | end_lng | member_casual |
|------------------|----------------|---------------------------|---------------------------|--------------------|------------------|------------------|----------------|-----------|-----------|---------|---------|----------------|
| 0354FD0756337B59 | electric_bike  | 2024-05-31 23:34:36.273   | 2024-06-01 00:14:29.238   |                    |                  |                  |                | 41.97     | -87.66    | 41.96   | -87.66  | casual         |
| 0354FD0756337B59 | electric_bike  | 2024-05-31 23:34:36       | 2024-06-01 00:14:29       |                    |                  |                  |                | 41.97     | -87.66    | 41.96   | -87.66  | casual         |

**Another example**:
```SQL
SELECT * FROM trip_data WHERE ride_id = '0354FD0756337B59'
```
| ride_id          | rideable_type | started_at              | ended_at                | start_station_name    | start_station_id | end_station_name         | end_station_id | start_lat       | start_lng      | end_lat      | end_lng      | member_casual |
|------------------|---------------|-------------------------|-------------------------|-----------------------|------------------|--------------------------|----------------|-----------------|----------------|--------------|--------------|---------------|
| 0625A51D397A68F9 | classic_bike  | 2024-05-31 23:51:12.862 | 2024-06-01 00:01:17.815 | Shedd Aquarium        | 15544            | Dearborn St & Van Buren St | 624            | 41.86722595682  | -87.6153553902 | 41.876268    | -87.629155   | casual        |
| 0625A51D397A68F9 | classic_bike  | 2024-05-31 23:51:12     | 2024-06-01 00:01:17     | Shedd Aquarium        | 15544            | Dearborn St & Van Buren St | 624            | 41.86722595682  | -87.6153553902 | 41.876268    | -87.629155   | casual        |

One of the rows contains a started_at and ended_at timestamp with more precision. This explains why when running the query to find duplicates containing the same columns did not return any rows.

Counting the number of duplicates we can confirm that there are 211 duplicates.
```SQL
SELECT COUNT(*)
FROM (
	SELECT
	ROW_NUMBER() OVER (
		PARTITION BY ride_id
	) AS row_number
	FROM trip_data
)subquery
WHERE row_number > 1;
```

The next step is to remove the duplicated values. Since the table was going to updated, it was decided to create a new table to perform this operation safely, trip_data_staging
```SQL
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
```

Then inserting the values of the trip_data table to the new one, and using row_number to then identify and eliminate the duplicates:
```SQL
INSERT INTO trip_data_staging
SELECT *,
ROW_NUMBER() OVER (
	PARTITION BY ride_id
) AS row_number
FROM trip_data
```

```SQL
DELETE FROM trip_data_staging
WHERE row_number > 1
```

After deleting the duplicates, the row_number column was no longer needed, so the column was dropped.
```SQL
ALTER TABLE trip_data_staging DROP COLUMN row_number
```

### Standardizing the data
The process of standarization began by checking the values of the columns, to spot if there were two different versions of entries like, for example, the ones containing "classic_bike" and "classic_bike."
```SQL
SELECT DISTINCT(rideable_type) FROM trip_data_staging
```
![checking rideable_type values](/images/check-rideable-type.png)

**Checking the member_casual column**

![checking member_casual values](/images/check-member-casual.png)

```SQL
SELECT DISTINCT(start_station_name)
FROM trip_data_staging 
ORDER BY start_station_name
```
There are many different station names to check visually, so it was proceeded to check for the ones containing extra spacaces using the TRIM function:
```SQL
SELECT start_station_name, TRIM(start_station_name) AS trimmed_station_name
FROM trip_data_staging
WHERE start_station_name <> TRIM(start_station_name)
ORDER BY start_station_name
```

There were in fact some stations containing an extra space
![Start station names with white spaces](/images/start-station-name-whitespaces.png)

```SQL
SELECT end_station_name, TRIM(end_station_name) AS trimmed_station_name
FROM trip_data_staging
WHERE end_station_name <> TRIM(end_station_name)
ORDER BY end_station_name
```
![End station names with white spaces](/images/end-station-name-whitespaces.png)

So the next step was to update this values replacing them with their trimmed version.
```SQL
UPDATE trip_data_staging
SET start_station_name = TRIM(start_station_name);

UPDATE trip_data_staging
SET end_station_name = TRIM(end_station_name)
```

### Checking for nulls
The first step taken was to check the rideable_type, started_at, and ended_at columns
```SQL
SELECT 
	* 
FROM 
	trip_data_staging
WHERE 
	rideable_type IS NULL OR started_at IS NULL OR ended_at IS NULL
```
No null values were found.

The member_casual column didn't return nulls either
```SQL
SELECT * FROM trip_data_staging
WHERE member_casual IS NULL
```

The start_station_name and end_station_name return many null values.
```SQL
SELECT 
	* 
FROM 
	trip_data_staging
WHERE 
	start_station_name IS NULL OR end_station_name is NULL
```
![records containing null values](/images/nulls-found.png)

As we can observe, 1,660,073 rows contain null values on the start_station_name or end_station_name columns.

**Checking for rows containing nulls on both start_station_name and end_station_name**:
```SQL
SELECT 
	* 
FROM 
	trip_data_staging
WHERE 
	start_station_name IS NULL AND end_station_name IS NULL
```
531,150 rows were returned from this query, this number represents around the 9% of all the data. So after knowing this some questions were rised:
- Are this rows going to be useful for the analysis?
- Should these rows be deleted?
- Deleting this rows would cause the analysis to be skewed in some way?

Taking a look at the rows with nulls, all the rows that have a null in start_station_name or end_station_name have in common that the start_lat, start_lng, or end_lat and end_lng with is value containing just two decimal places. Since this are coorditanes, this information is incomplete since they are not precise.
![incomplete coordinates](/images/lat-lng-precision.png)

**Checking for rows where start_lat and start_lng are null**:
```SQL
SELECT
	*
FROM
	trip_data_staging
WHERE
	start_lat IS NULL OR start_lng IS NULL 
```
``` bash
 No rows were returned
```

**Checking for rows where end_lat and end_lng are null**:
```SQL
SELECT
	*
FROM
	trip_data_staging
WHERE
	end_lat IS NULL OR end_lng IS NULL 
```
This query returned 7377 rows.
![null end_lat and end_lng](/images/null-cooridnates.png)

This showed that only the end_lat and end_lng columns contained null values, and the rows are trips that were started but without data of the ending location of the trip. This might be an indicator of bikes that were stolen.
It was also found something that all rows with null end station coordinates had in common.

![start times and end times of trips with null values of end station coordinates](/images/trip-durations.png)

The trips lasted more than 24 hours.

The rows with null end_station coordinates were distributed in the following way for rideable types and user types:
```SQL
SELECT
	member_casual,
	COUNT(*) FILTER (WHERE end_lat IS NULL OR end_lng IS NULL) AS null_destinations
FROM
	trip_data_staging
GROUP BY
	member_casual

```
| member_casual | null_destinations |
|----------|-------|
| casual   | 5939  |
| member   | 1438  |


```SQL
SELECT
	rideable_type,
	COUNT(*) FILTER (WHERE end_lat IS NULL OR end_lng IS NULL) AS null_destinations
FROM
	trip_data_staging
GROUP BY
	rideable_type
```
| rideable_type     | null_destinations |
|-------------------|-------------------|
| classic_bike      | 7377              |
| electric_bike     | 0                 |
| electric_scooter  | 0                 |

This only occured to classic bikes.


This rows were not going to be useful for the analysis, since they don't represent a big part of the data, they don't have any end station data and trips of more than 24 hours can be considered outliers.

#### Trying to fill out missing values:
The first attempt to fill the null values found, was to see if there were rows with a null start_station_name that had a start_station_id that wasn't null, and the same with end_station_name and end_station_id
```SQL
SELECT
	*
FROM
	trip_data_staging
WHERE
	start_station_name IS NULL AND start_station_id IS NOT NULL
```
```bash
no rows were returned
```


```SQL
SELECT
	*
FROM
	trip_data_staging
WHERE
	end_station_name IS NULL AND end_station_id IS NOT NULL
```
```bash
again, 0 rows were returned
```

This meant that it is not possible to fill the name of the start or end station with their correspondent id. This is because, when the latitude and longitude data is incomplete, everything related to that station, the name and the id, is null.

The second attempt was trying to obtain the station data by querying trips within a certain range of coordinates. For example, if there is a row with a start_lat of 41.93, the trips with a start_lat between 41.93 and 41.94 will be retrieved. At first hand this seems difficult because coordinates need to be precise.
```SQL
SELECT DISTINCT 
	(start_station_name) 
FROM 
	trip_data_staging
WHERE 
	start_lat >= 41.93 AND start_lat < 41.94 
```
![trips in the given coordinate interval](/images/stations-coord.png)

159 rows were returned, so there is no posibility of estimating the start station.


Another attempt was trying by, within that interval, finding the station with the most trips started.
```SQL
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
```
![number of trips startead on each station in the given coordinate interval](/images/n-stations-coord.png)

The number of trips for each station were quite evenly distributed, so this approach was not possible.

#### Deciding wether to delete the rows with nulls or not
To measure the impact the deletion of these records will have on the data, the first thing was to find the type of bikes containing this null values to see if this affects a specific type of bike.
```SQL
SELECT
	rideable_type,
	COUNT (*) FILTER (WHERE start_station_name IS NULL AND end_station_name IS NULL) AS null_stations
FROM
	trip_data_staging
GROUP BY
	rideable_type
```
![number trips with null values of each type of bike](/images/rideable-type-nulls.png)

This shows that most trips that have nulls in start station and end station information are the ones made with electric bikes, with 489,656 rows. So deleting these records will have an impact on the trip data of electric bikes.
```SQL
SELECT
	COUNT (*) AS electric_bike_trips
FROM
	trip_data_staging
WHERE
	rideable_type = 'electric_bike'
```
This query returns the amount of trips made with electric bikes, 2,991,565 trips. So 489,656 represent around the 16.36% of trips made with electric bikes.

Since the main of objective of the analysis is how casual and member clients use the bikes, it was important to see how the deletion of these records impact each type of client.
```SQL
SELECT
	member_casual,
	COUNT (*) FILTER (WHERE start_station_name IS NULL AND end_station_name IS NULL) AS null_stations
FROM
	trip_data_staging
GROUP BY
	member_casual
```
![number of trips with null station data by client type](/images/user-type-nulls.png)

Each client type has a similar number of rows with null station data.

It was decided to keep this rows, since the deletion of them would represent a loss of around the 16.36% of electric bike trips and this will have an inpact on the analysis of trips by rideable type. This rows will be excluded from the queries when working on geographic analysis of the trips.

### Checking for outliers in trip durations
**Checking for the maximum trip duration in minutes**:
```SQL
SELECT
	MAX(EXTRACT(EPOCH FROM (ended_at - started_at)) / 60)
FROM trip_data_staging
```
The maximum trip duratioon returned was of 1559.93 minutes, so an extreme value was already spotted.

**To make queries simpler, a trip_duration column was added to the table**:
```SQL
ALTER TABLE trip_data_staging ADD COLUMN trip_duration_minutes NUMERIC;


UPDATE
    trip_data_staging
SET
	trip_duration_minutes = EXTRACT(EPOCH FROM (ended_at - started_at)) / 60
```

The method chosen to identify outliers was the Z-Score method, which calculates how far a trip's duration is from the mean, in standard deviations.

**Z = (Trip Duration - Mean) / Standard Deviation**

If a trip duration has the absolute value of a Z_Score more than 3 it will be considered an outlier, which means that this trip duration is more than three standard deviations away from the mean.

```SQL
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
```
![trips with a Z-Score bigger than 3](/images/outliers_found.png)
33,213 outliers were found

To make querying easier, a z_score column was created:
```SQL
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
```

**Checking minimum and maximum trip durations of outliers**
To explore these trip duration outliers deeper, the next step was to check their minimum and maximum values
```SQL
SELECT
	MIN(trip_duration_minutes),
	MAX(trip_duration_minutes)
FROM
	trip_data_staging
WHERE
	ABS(z_score) > 3
```
![minimum and maximum outlier trip durations](/images/minmax-outliers.png)

A negative value was found as a minimum, which means there exist negative trip durations in the dataset.

**Trips with a negative trip duration**:
```SQL
SELECT 
	* 
FROM 
	trip_data_staging 
WHERE 
	trip_duration_minutes < 0
```
![trips with negative trip durations](/images/negative_trip_durations.png)

258 trips with negative trip duration were found.

**Checking minimum and maximum trip durations of non-outliers**:
```SQL
SELECT
	MIN(trip_duration_minutes),
	MAX(trip_duration_minutes)
FROM
	trip_data_staging
WHERE
	ABS(z_score) <= 3
```
![minimum and maximum non-outlier trip durations](/images/minmax_non_outliers.png)

The minimum trip duration was of 0 minutes, this means that there are trips with very short trip durations which may indicate test rides or users making a mistake when starting the trip and finishing it right away. These short trips do not make sense for the scope of this project, so the minimum trip duration considered will be of 2 minutes.
```SQL
SELECT
	*
FROM
	trip_data_staging
WHERE
	trip_duration_minutes < 2
```
![trips with a duration of less than 2 minutes](/images/lessthantwominutes_trips.png)

There are 246,857 trips with a duration of less than two minutes.

#### Removing outliers
```SQL
DELETE FROM 
	trip_data_staging 
WHERE 
	trip_duration_minutes < 2

DELETE FROM
	trip_data_staging
WHERE
	ABS(z_score) > 3
```


# Analysis
### Trips by Client Type
The first step of the analysis was to check how the trips were distributed between member and casual clients.
```SQL
SELECT
	member_casual,
	count (*) AS number_of_trips
FROM
	trip_data_staging
GROUP BY
	member_casual
```
| member_casual | number_of_trips |
|---------------|-----------------|
| casual        | 2042971         |
| member        | 3602825         |

There are more trips taken by Member clients than Casual clients. Around 63% of the trips were taken by member clients, Casual clients represent around 37% of the trips.

### Trips by Rideable Type
```SQL
SELECT
	rideable_type,
	count(*) FILTER (WHERE member_casual = 'casual') AS trips_casual,
	count (*) FILTER (WHERE member_casual = 'member') AS trips_member
FROM
	trip_data_staging
GROUP BY 
	rideable_type
```
| rideable_type    | trips_casual | trips_member |
|------------------|--------------|--------------|
| classic_bike     | 941136       | 1756425      |
| electric_bike    | 1022780      | 1792286      |
| electric_scooter | 79055        | 54114        |

#### Member Clients:
![trips by rideable type, member clients](/images/trips_rideable_member.png)
#### Casual Clients:
![trips by rideable type, casual clients](/images/trips_rideable_casual.png)

The insight obtained from this, is that the preference of bikes of each type of client is very simillar, the most popular bike for both client types is the electric bike, followed by the classic bike. A small number of trips were taken with electric scooters. 


### Number of trips by month.
```SQL
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
```
![number of trips by month](/images/number_trips_month.png)
The usage of bikes by month by both type of users is very similar, both having a peak in the Summer months, specially in late August. The number of trips of both client types go down in the Winter months reaching its lower point in January.
Member clients take more trips than casual during all months of the year.    


### Average number of trips by day of the week.
```SQL
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
```
![average number of trips by day of the week](/images/avg_trips_week.png)

Casual clients take more trips on weekends, peaking on Saturdays. This can mean that most casual riders prefer to use the bikes in their free time for leisure activities on the weekend.
Member clients, on the other hand, take more trips on working days. This can imply that member clients are using the bikes to commute to work.


### Average number of trips by hour.
```SQL
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
```
![average number of trips by hour](/images/avg_trips_hour.png)

This chart shows something interesting, member clients have two peaks of average trips taken per hour, at 8am and 5pm which matches with the time of the day that people use to commute to work and back home. This confirms that member clients use the bikes to commute to work and return to their homes from work.

Casual clients tend to take more trips in the afternoon, peaking at 5pm. The usage of bikes at these hours may indicate again, leisure activities, since people tend to practice these type of activities in the afternoon. Also, the fact that the peak is at 5pm may indicate that some casual riders could be using the bikes to return home from work.


### Number of trips by station
```SQL
SELECT
	start_station_name,
	AVG(start_lat) AS avg_latitude,
	AVG(start_lng) AS avg_longitude,
	count(*) FILTER (WHERE member_casual = 'member') AS number_trips_member,
	count(*) FILTER (WHERE member_casual = 'casual') AS number_trips_casual
FROM 
	trip_data_staging
WHERE
	start_station_name IS NOT NULL
GROUP BY
	start_station_name
```
**Member Clients**:
![number of trips by station, member clients](/images/trips_stations_members.png)

The most popular stations for Member clients are in areas where the businesses are located like "The Loop", and high density residential buildings such as "Near North Side". Popular stations are also well distributed to the North of Chicago up to residential neighborhoods like "Lake View". Also, there are popular stations in university areas, like Hyde Park where the University of Chicago is located.

The fact that there are many station with a high volume of trips started in these mentioned areas, of businesses, residential, and universities, show that most Member clients use the bikes as a mean of transport to go to work or to the university.


**Casual Clients**:
![number of trips by station, casual clients](/images/trips_stations_casual.png)
The most popular stations to start a trip for Casual clients are in areas with parks or attractions, like the one located in Adler Planetarium, the Shed Aquarium, Millenium Park and Maggie Daley Park, the one in Lake Shore & North Boulevard by the Lincoln Monument Gardens and the Chicago History Museum.
The most popular station, with 48286 trips started, is the station in Streeter Dr & Grand Ave where the Addams (Jane) Memorial Park is, and the Navy Pier.

The insights obtained from this is that casual clients prefer to start their trips from stations located in parks and near touristic attractions, this also can indicate that there might be a percentage of casual clients who are tourists.


### Average trip duration by Client Type (in minutes):
```SQL
SELECT 
	member_casual,
	AVG (trip_duration_minutes) AS avg_trip_duration_minutes
FROM
	trip_data_staging
GROUP BY
	member_casual
```
| member_casual | avg_trip_duration_minutes  |
|---------------|----------------------------|
| casual        | 18.7873701557274512        |
| member        | 12.0712984698303877        |

Casual clients take longer trips than Member clients, the average duration of a Casual client's trip is around 18.79 minutes, while the average trip duration of a Member client is around 12.07 minutes.

### Average trip duration by day of the week (in minutes)
```SQL
SELECT 
    TO_CHAR(started_at, 'Day') AS day_of_week,
    AVG (trip_duration_minutes) 
		FILTER (WHERE member_casual = 'member') AS avg_trip_duration_member,
	AVG (trip_duration_minutes) 
		FILTER (WHERE member_casual = 'casual') AS avg_trip_duration_casual
FROM
	trip_data_staging
GROUP BY
	day_of_week
```
![average trip duration by day of the week](/images/avg_duration_day.png)
Casual clients take longer trips than Member clients during all days of the week, both take longer trips on weekends.


### Average trip duration by hour of day (minutes).
```SQL
SELECT 
    EXTRACT(HOUR FROM started_at) AS hour_of_day,
    AVG (trip_duration_minutes) 
		FILTER (WHERE member_casual = 'member') AS avg_trip_duration_member,
	AVG (trip_duration_minutes) 
		FILTER (WHERE member_casual = 'casual') AS avg_trip_duration_casual
FROM
	trip_data_staging
GROUP BY
	hour_of_day
```
![average trip duration by hour](/images/avg_duration_hour.png)
Casual clients take longer trips than Member clients during all hours of the day. The longest trip durations of Casual clients are registered from 10am to 5pm, with the maximum average trip duration being reached at 11am with 22.48 minutes. The lowest average trip duration of Casual clients was registerd at 6am, 11.88 minutes.

The trip durations of Member clients are quite similar during the day, they start increasing at 10am and reach their maximum at 5pm with 12.86 minutes of average duration. The lowest average trip duration, just like Casual clients, are registered at 6am being 10.24 minutes.

### Average trip duration by station (minutes).
```SQL
SELECT
	start_station_name,
	AVG(start_lat) AS avg_latitude,
	AVG(start_lng) AS avg_longitude,
	AVG (trip_duration_minutes) 
		FILTER (WHERE member_casual = 'member') AS avg_trip_duration_member,
	AVG (trip_duration_minutes) 
		FILTER (WHERE member_casual = 'casual') AS avg_trip_duration_casual
FROM 
	trip_data_staging
WHERE
	start_station_name IS NOT NULL
GROUP BY
	start_station_name
```

Trip durations among station were distributed quite evenly for both Member and Casual clients.
![average trip duration by stations, members](/images/duration_station_member.png)

![average trip duration by stations, casual clients](/images/duration_station_casual.png)

### Average trip duration by rideable type (minutes).
```SQL
SELECT
	rideable_type,
	AVG(trip_duration_minutes) FILTER(WHERE member_casual = 'member') AS avg_duration_member,
	AVG(trip_duration_minutes) FILTER(WHERE member_casual = 'casual') AS avg_duration_casual
FROM
	trip_data_staging
GROUP BY
	rideable_type
```
**Member Clients**:
![average trip duration by rideable type, members](/images/avg_duration_rideable_members.png)

Trip durations for each type of bike are similar for Member clients, classic bikes have the longest average trip duration for Member clients, with 12.9 minutes followed by electric bikes with 11.3. 

![average trip duration by rideable type, members](/images/avg_duration_rideable_casual.png)

Casual clients, on the other hand, have significantly longer trips with classic bikes with an average of 23.3 minutes, followed by electric bikes with trips lasting an average of 15.1 minutes.

# Recommendations

1. **Highlight the benefits of commuting to work using Cyclistic's annual membership**: Since Member clients mainly use bikes for commuting, a good marketing strategy can be focused on highlighting the benefits of how Cyclistic Bikes annual membership can be cheaper than commuting by car and more comfortable than public transport, plus the known benefits of bikes like avoiding traffic jams.

2. **Ad placing**: Knowing that Casual clients' popular stations are located in parks and landmarks, placing ads in those locations, highlighting the benefits of Cyclistic's annual subscription plans, can reach many casual riders. Also, placing ads on streets known for traffic jams can attract new users, put a QR code for people to scan that takes them to download the Cyclistic app and emphasize the benefits of the annual subscription.

3. **Special benefits for Member clients**: Add special benefits for frequent riders with an annual membership. For example, members who take more than a certain number of trips per week get a free trip for the next week. These types of benefits and promotions can convince a Casual rider who uses the bikes frequently to switch to an annual subscription to enjoy these benefits.


# Conclusion
From the insights obtained from the analysis, the main differences discovered between Casual and Member clients are that Casual clients tend to use the bikes for recreational activities, and Member clients use them mainly for commuting, this resulted from analysing the most popular stations of each client type which showed that most Member clients start their trips in business and high-density residential areas of the city. In contrast, the most popular stations for Casual clients were the ones located in parks and landmarks. Analysis of the average number of trips per hour and day of the week also showed this pattern, with Member clients taking more trips during commuting hours and on working days, and Casual clients taking more trips in the afternoon and weekends. 

Implementing the recommendations above can help convert Casual clients to Members with an annual subscription as well as bring new customers signing up directly for an annual membership.