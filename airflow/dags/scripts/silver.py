import os
import json
from pyspark.sql import SparkSession
import pyspark.sql.functions as F
from pyspark.sql.types import IntegerType, StringType, FloatType, DateType, TimestampType, BooleanType

class SilverProcessor:
    def __init__(self, bucket: str, table_name: str):
        self.bucket = bucket
        self.table_name = table_name
        self.dags_folder = os.environ.get('DAGS_FOLDER', 'dags/')
        self.contract_path = os.path.join(self.dags_folder, 'contracts', 'schemas.json')
        self.input_path = f"gs://{self.bucket}/datalake/bronze/{self.table_name}/"
        self.output_path = f"gs://{self.bucket}/datalake/silver/{self.table_name}/"

        self.type_map = {
            "INTEGER": IntegerType(),
            "STRING": StringType(),
            "FLOAT": FloatType(),
            "DATE": DateType(),
            "TIMESTAMP": TimestampType(),
            "BOOLEAN": BooleanType()
        }

    def _get_contract_config(self) -> dict:
        if not os.path.exists(self.contract_path):
            raise FileNotFoundError(f"Contract not found: {self.contract_path}")
            
        with open(self.contract_path, 'r') as f:
            full_contract = json.load(f)
        
        config = full_contract.get(f"silver_{self.table_name}")
        if not config:
            raise ValueError(f"Missing contract configuration for 'silver_{self.table_name}'")
        return config

    def _enforce_schema(self, df):
        config = self._get_contract_config()
        select_exprs = []
        
        for col_config in config['columns']:
            col_name = col_config['name']
            col_type = self.type_map.get(col_config['type'], StringType())
            
            expr = F.col(col_name).cast(col_type).alias(col_name)
            select_exprs.append(expr)
            
        df_casted = df.select(*select_exprs)
        
        for col_config in config['columns']:
            if col_config.get('mode') == 'REQUIRED':
                df_casted = df_casted.dropna(subset=[col_config['name']])
                
        return df_casted

    def _apply_transformations(self, df):
        for field in df.schema.fields:
            if isinstance(field.dataType, StringType):
                df = df.withColumn(field.name, F.trim(F.col(field.name)))
            
        return df.withColumn("dw_processed_at", F.current_timestamp())

    def execute(self):
        spark = SparkSession.builder \
            .appName(f"Silver_Processor_{self.table_name}") \
            .config("spark.sql.adaptive.enabled", "true") \
            .config("spark.sql.parquet.mergeSchema", "false") \
            .getOrCreate()

        try:
            df_bronze = spark.read.parquet(self.input_path)
            df_contracted = self._enforce_schema(df_bronze)
            df_final = self._apply_transformations(df_contracted)
            
            df_final.write.mode("overwrite").parquet(self.output_path)
            
        finally:
            spark.stop()

def run_silver_pipeline(bucket: str, table_name: str):
    processor = SilverProcessor(bucket, table_name)
    processor.execute()