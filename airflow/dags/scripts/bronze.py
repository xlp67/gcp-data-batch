from pyspark.sql import SparkSession
import pyspark.sql.functions as F

def ingest_raw_to_bronze(bucket: str, table_name: str):
    spark = SparkSession.builder \
        .appName(f"Bronze_Ingest_{table_name}") \
        .getOrCreate()

    raw_path = f"gs://{bucket}/datalake/raw/{table_name}/*.csv"
    bronze_path = f"gs://{bucket}/datalake/bronze/{table_name}/"

    try:
        df = spark.read.format("csv") \
            .option("header", "true") \
            .option("inferSchema", "false") \
            .load(raw_path)

        df_bronze = df \
            .withColumn("_source_file", F.input_file_name()) \
            .withColumn("_bronze_ingested_at", F.current_timestamp())

        df_bronze.write \
            .mode("overwrite") \
            .parquet(bronze_path)
            
        print(f"Sucesso: Camada Bronze atualizada. Destino: {bronze_path}")

    except Exception as e:
        print(f"Falha crítica na ingestão Bronze da tabela {table_name}: {str(e)}")
        raise e 

    finally:
        spark.stop()