# Cyclistic bike-share
The aim of this project is to gain insight on how casual members and annual members use Cyclistic bikes differently, by analyzing ride data of the past 12 months. The director of marketing believes the company's future success
depends on maximizing the number of annual memberships, so these insights will be used to design a new marketing strategy to increase the number of annual members.

## Ask
**Three questions will guide the future marketing program:**
1. How do annual members and casual riders use Cyclistic bikes differently?
2. Why would casual riders buy Cyclistic annual memberships?
3. How can Cyclistic use digital media to influence casual riders to become members?


## Prepare
The data used for the project is Cyclistic's historical trip data (https://divvy-tripdata.s3.amazonaws.com/index.html). The last 12 months of data available will be used, starting from November 2023 up to October 2024. It's organized in 12 CSV, since Cyclistic uploads the trip data monthly. The 12 files were decompressed and extracted into a folder named "data".

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

so it was decided to put all of them on a single table called TripData. This was achieved by using a Python script to "automate" the process of loading the 12 CSV files to the database.


The first step of this process was to create the table with the appropiate columns and data types:
```SQL
CREATE TABLE TripData (
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

## Process
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

The next step is to remove the duplicated values. Since the table was going to updated, it was decided to create a new table to perform this operation safely, TripDataStaging