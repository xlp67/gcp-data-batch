from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.google.cloud.sensors.gcs import GCSObjectsWithPrefixExistenceSensor
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator

# 
PROJECT_ID = "seu-projeto-gcp"
BUCKET_NAME = "seu-bucket-datalake"
PREFIX = "datalake/" 
DATASET_NAME = "churn"
TABLE_NAME = "tabela_vendas"

default_args = {
    'owner': 'data_team',
    'depends_on_past': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    dag_id='datalake_csv_to_bigquery',
    default_args=default_args,
    start_date=datetime(2023, 1, 1),
    schedule_interval='@hourly', 
    catchup=False,
    tags=['gcs', 'bigquery', 'sensor'],
) as dag:

    espera_por_arquivo_csv = GCSObjectsWithPrefixExistenceSensor(
        task_id='espera_por_arquivo_csv',
        bucket=BUCKET_NAME,
        prefix=PREFIX,
        poke_interval=60, 
        timeout=60 * 60 * 2, 
        mode='poke'
    )

    carrega_csv_no_bq = GCSToBigQueryOperator(
        task_id='carrega_csv_no_bq',
        bucket=BUCKET_NAME,
        source_objects=[f'{PREFIX}*.csv'], 
        destination_project_dataset_table=f'{PROJECT_ID}.{DATASET_NAME}.{TABLE_NAME}',
        source_format='CSV',
        skip_leading_rows=1,
        write_disposition='WRITE_APPEND',
        autodetect=True, 
    )

    espera_por_arquivo_csv >> carrega_csv_no_bq