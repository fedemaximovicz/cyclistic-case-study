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


