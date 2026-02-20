from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.sensors.gcs import GCSObjectsWithPrefixExistenceSensor
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
import os
import subprocess

PROJECT_ID   = os.getenv("AIRFLOW_VAR_GCP_PROJECT_ID")
BUCKET_NAME  = os.getenv("AIRFLOW_VAR_GCP_BUCKET_NAME")
PREFIX_PATH  = os.getenv("AIRFLOW_VAR_GCP_PREFIX_PATH")
DATASET_NAME = os.getenv("AIRFLOW_VAR_GCP_DATASET_NAME")
TABLE_NAME   = os.getenv("AIRFLOW_VAR_GCP_TABLE_NAME")

default_args = {
    'owner': 'data_team',
    'depends_on_past': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

def print_env_vars():
    print("=" * 75)
    print(f"Projeto GCP: {PROJECT_ID}")
    print(f"Bucket GCS:  {BUCKET_NAME}")
    print(f"Dataset BQ:  {DATASET_NAME}")
    print(f"Tabela BQ:   {TABLE_NAME}")
    print(f"Caminho:     {PREFIX_PATH}")
    print(subprocess.run(["env"]).stdout)
with DAG(
    dag_id='datalake_csv_to_bigquery',
    default_args=default_args,
    start_date=datetime(2023, 1, 1),
    schedule_interval='@daily',
    catchup=False,
    tags=['gcs', 'bigquery', 'sensor'],
) as dag:
    
    debug_vars = PythonOperator(
        task_id='debug_vars',
        python_callable=print_env_vars
    # )
    # espera_por_arquivo_csv = GCSObjectsWithPrefixExistenceSensor(
    #     task_id='espera_por_arquivo_csv',
    #     bucket=BUCKET_NAME,
    #     prefix=PREFIX_PATH,
    #     poke_interval=60,
    #     timeout=7200,
    #     mode='reschedule'
    # )

    # carrega_csv_no_bq = GCSToBigQueryOperator(
    #     task_id='carrega_csv_no_bq',
    #     bucket=BUCKET_NAME,
    #     source_objects=[f'{PREFIX_PATH}*.csv'],
    #     destination_project_dataset_table=f'{PROJECT_ID}.{DATASET_NAME}.{TABLE_NAME}',
    #     source_format='CSV',
    #     skip_leading_rows=1,
    #     write_disposition='WRITE_APPEND',
    #     autodetect=True,
    )
    debug_vars
    # espera_por_arquivo_csv >> carrega_csv_no_bq