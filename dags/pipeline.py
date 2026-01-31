import io, os
import pandas as pd
from airflow.sdk import DAG
from dotenv import load_dotenv
from google.cloud import storage
from sqlalchemy import create_engine
from airflow.providers.standard.operators.python import PythonOperator
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator

def ingest_and_insert():
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

    ingest_and_insert = PythonOperator(
        task_id="ingest_and_insert",
        python_callable=ingest_and_insert
    )

    insert_clean = SQLExecuteQueryOperator(
        task_id="insert_clean",
        conn_id="main_db",
        sql="./sql/insert_clean.sql"
    )

    prep_raw_schema >> prep_clean_schema >> ingest_and_insert >> insert_clean