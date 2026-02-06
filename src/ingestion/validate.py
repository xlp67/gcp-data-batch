import json
import logging
from io import StringIO
from typing import Dict, Any, List
import pandas as pd
from pydantic import ValidationError
from google.cloud import storage
from pandas.errors import EmptyDataError, ParserError
from contracts import SensorTelemetry
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
def validate_batch_data(file_content: str, file_name: str) -> bool:
    logging.info(f"Iniciando validação para o arquivo: {file_name}")
    try:
        df = pd.read_csv(StringIO(file_content))
        records: List[Dict[str, Any]] = df.to_dict(orient='records')
        for index, record in enumerate(records):
            SensorTelemetry.model_validate(record)
        logging.info(f"Validação bem-sucedida para todos os {len(records)} registros no arquivo: {file_name}.")
        return True
    except ValidationError as e:
        logging.warning(f"Falha na validação do Data Contract para o arquivo {file_name}!")
        logging.warning(json.dumps(e.errors(), indent=2))
        return False
    except EmptyDataError:
        logging.error(f"Erro: O arquivo {file_name} está vazio ou contém apenas cabeçalho.")
        return False
    except ParserError as e:
        logging.error(f"Erro de Parser no arquivo CSV {file_name}: {e}")
        return False
    except Exception as e:
        logging.error(f"Ocorreu um erro inesperado durante a validação do arquivo {file_name}: {e}")
        return False
def move_blob_to_quarantine(source_bucket_name: str, blob_name: str, project_id: str):
    storage_client = storage.Client(project=project_id)
    source_bucket = storage_client.bucket(source_bucket_name)
    quarantine_bucket = storage_client.bucket(f"{project_id}-data-quarantine")
    source_blob = source_bucket.blob(blob_name)
    logging.info(f"Simulando movimento do blob '{blob_name}' do Bucket '{source_bucket_name}' para quarentena no Bucket '{quarantine_bucket.name}'.")
    pass
if __name__ == '__main__':
    valid_data_content = """device_id,timestamp,temperature,humidity,operator_name,operator_email,status_code
device-001,2026-02-06T10:00:00Z,25.5,60.1,Thiago William,thiago.w@example.com,200
device-002,2026-02-06T10:01:00Z,26.1,62.3,Maria Silva,maria.s@example.com,200
"""
    valid_file_name = "valid_data.csv"
    invalid_data_content = """device_id,timestamp,temperature,humidity,operator_name,operator_email,status_code
device-003,2026-02-06T10:02:00Z,22.0,105.0,John Doe,john.d@example.com,500
device-004,2026-02-06T10:03:00Z,23.1,70.3,Jane Doe,jane.doe@,200
"""
    invalid_file_name = "invalid_data.csv"
    empty_data_content = """device_id,timestamp,temperature,humidity,operator_name,operator_email,status_code
"""
    empty_file_name = "empty_data.csv"
    print("\n" + "="*40 + "\n")
    print("--- Testando com Dados VÁLIDOS ---")
    if validate_batch_data(valid_data_content, valid_file_name):
        logging.info("Ação: O arquivo deve ser movido para a 'staging-zone' para processamento dbt.")
    else:
        logging.info("Ação: O arquivo deve ser movido para o Bucket de 'quarentena'.")
    print("\n" + "="*40 + "\n")
    print("--- Testando com Dados INVÁLIDOS ---")
    if validate_batch_data(invalid_data_content, invalid_file_name):
        logging.info("Ação: O arquivo deve ser movido para a 'staging-zone' para processamento dbt.")
    else:
        logging.info("Ação: O arquivo deve ser movido para o Bucket de 'quarentena'.")
    print("\n" + "="*40 + "\n")
    print("--- Testando com Dados VAZIOS ---")
    if validate_batch_data(empty_data_content, empty_file_name):
        logging.info("Ação: O arquivo deve ser movido para a 'staging-zone' para processamento dbt.")
    else:
        logging.info("Ação: O arquivo deve ser movido para o Bucket de 'quarentena'.")
