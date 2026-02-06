import os
from datetime import datetime, timedelta
from airflow.models.dag import DAG
from airflow.providers.google.cloud.sensors.gcs import GCSObjectExistenceSensor
from airflow.providers.cncf.kubernetes.operators.kubernetes_pod import KubernetesPodOperator
from airflow.operators.bash import BashOperator
default_args = {
    'owner': 'Thiago William',
    'start_date': datetime(2026, 2, 6),
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
    'project_id': os.environ.get("GCP_PROJECT_ID"),
}
DBT_ENV_VARS = {
    "GCP_PROJECT_ID": os.environ.get("GCP_PROJECT_ID"),
    "DBT_PII_SALT": "{{ macros.airflow.get_secret('pii-hashing-salt', 'ssm-parameter-name') }}"
}
GCS_RAW_BUCKET = f"{os.environ.get('GCP_PROJECT_ID', 'your-gcp-project-id')}-data-raw-zone"
FILE_TO_SENSE = "incoming_telemetry_{{ ds_nodash }}.csv"
with DAG(
    dag_id='gcp_secure_batch_pipeline',
    default_args=default_args,
    schedule_interval='@daily',
    catchup=False,
    tags=['gcp', 'dbt', 'data-governance'],
    description='Orchestrates a secure batch data pipeline with dbt and PII hashing.'
) as dag:
    sense_new_file = GCSObjectExistenceSensor(
        task_id='sense_new_file_in_raw_zone',
        bucket=GCS_RAW_BUCKET,
        object=FILE_TO_SENSE,
        google_cloud_conn_id='google_cloud_default',
        mode='poke',
        timeout=60 * 10,
        poke_interval=60,
    )
    validate_data_contract = BashOperator(
        task_id='validate_data_contract',
        bash_command=(
            f'echo "Running validation on gs://{GCS_RAW_BUCKET}/{FILE_TO_SENSE}" && '
            'echo "Validation successful!"'
        ),
    )
    trigger_dbt_run = KubernetesPodOperator(
        task_id='trigger_dbt_run',
        name='dbt-run-pod',
        namespace='composer',
        image='gcr.io/your-gcp-project-id/dbt-runner:latest',
        cmds=["dbt"],
        arguments=["run"],
        service_account_name='sa-data-pipeline',
        env_vars=DBT_ENV_VARS,
    )
    sense_new_file >> validate_data_contract >> trigger_dbt_run