import io, os
import pandas as pd
from airflow.sdk import DAG
from dotenv import load_dotenv
from google.cloud import storage
from sqlalchemy import create_engine
from airflow.providers.standard.operators.python import PythonOperator
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator

def ingest_tables() -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    """
    Retrieve raw data tables from a Google Cloud Storage (GCS) bucket and load them into pandas DataFrames.

    This function authenticates using a local service account key file, connects to the
    specified GCS bucket, downloads four CSV files as bytes, and reads them into
    pandas DataFrames.

    Files retrieved from the bucket:
        - customers_raw.csv → customers_df
        - furniture_raw.csv → furniture_df
        - orders_raw.csv → orders_df
        - sales_raw.csv → sales_df

    Returns:
        tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame]:
            A tuple containing four pandas DataFrames in the following order:
            (customers_df, furniture_df, orders_df, sales_df)

    Raises:
        google.cloud.exceptions.NotFound:
            If the bucket or any of the specified blobs do not exist.
        FileNotFoundError:
            If the service account key file is not found at the specified path.
        pandas.errors.ParserError:
            If any of the downloaded CSV files cannot be parsed.
    """
    service_account_key = "./dags/keys/gcs.json"
    bucket_name = "raw-furniture-data"
    client = storage.Client.from_service_account_json(service_account_key)
    bucket = client.bucket(bucket_name)

    customers_blob = bucket.blob("customers_raw.csv")
    customers_bytes = customers_blob.download_as_bytes()
    customers_df = pd.read_csv(io.BytesIO(customers_bytes))

    furniture_blob = bucket.blob("furniture_raw.csv")
    furniture_bytes = furniture_blob.download_as_bytes()
    furniture_df = pd.read_csv(io.BytesIO(furniture_bytes))

    orders_blob = bucket.blob("orders_raw.csv")
    orders_bytes = orders_blob.download_as_bytes()
    orders_df = pd.read_csv(io.BytesIO(orders_bytes))

    sales_blob = bucket.blob("sales_raw.csv")
    sales_bytes = sales_blob.download_as_bytes()
    sales_df = pd.read_csv(io.BytesIO(sales_bytes))

    return customers_df, furniture_df, orders_df, sales_df

def insert_tables():
    """
    Load raw data tables into a PostgreSQL database schema.

    This function retrieves raw DataFrames by calling `ingest_tables()`, loads
    database credentials from environment variables, establishes a SQLAlchemy
    engine connection to a PostgreSQL database, and appends the data to
    predefined tables within the `raw_data` schema.

    Environment Variables Required:
        - POSTGRES_USER: Database username
        - POSTGRES_PASSWORD: Database password
        - POSTGRES_DB: Target database name

    Target Tables (schema: raw_data):
        - raw_customers   ← customers_df
        - raw_furniture   ← furniture_df
        - raw_orders      ← orders_df
        - raw_sales       ← sales_df

    Behavior:
        - Data is appended to existing tables (`if_exists="append"`).
        - Table indexes are not written to the database (`index=False`).

    Raises:
        sqlalchemy.exc.SQLAlchemyError:
            If a database connection or insert operation fails.
        ValueError:
            If required environment variables are missing.
        Exception:
            Propagates any exception raised by `ingest_tables()`.
    """
    customers_df, furniture_df, orders_df, sales_df = ingest_tables()

    load_dotenv()
    db_user = os.getenv("POSTGRES_USER")
    db_password = os.getenv("POSTGRES_PASSWORD")
    db_name = os.getenv("POSTGRES_DB")

    engine = create_engine(f"postgresql://{db_user}:{db_password}@postgres:5432/{db_name}")

    customers_df.to_sql("raw_customers", engine, schema="raw_data", if_exists="append", index=False)
    furniture_df.to_sql("raw_furniture", engine, schema="raw_data", if_exists="append", index=False)
    orders_df.to_sql("raw_orders", engine, schema="raw_data", if_exists="append", index=False)
    sales_df.to_sql("raw_sales", engine, schema="raw_data", if_exists="append", index=False)

with DAG(
    dag_id="furniture_pipeline",
    schedule="@daily",
):
    prep_raw_schema = SQLExecuteQueryOperator(
        task_id="prep_raw_schema",
        conn_id="main_db",
        sql="./sql/ddl/raw_ddl.sql"
    )

    prep_clean_schema = SQLExecuteQueryOperator(
        task_id="prep_clean_schema",
        conn_id="main_db",
        sql="./sql/ddl/clean_ddl.sql"
    )

    insert_tables_task = PythonOperator(
        task_id="insert_tables",
        python_callable=insert_tables
    )

    insert_clean = SQLExecuteQueryOperator(
        task_id="insert_clean",
        conn_id="main_db",
        sql="./sql/insert_clean.sql"
    )

    prep_raw_schema >> prep_clean_schema >> insert_tables_task >> insert_clean