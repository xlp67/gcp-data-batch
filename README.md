Este é um projeto de pipeline de dados construído na Google Cloud Platform (GCP). O projeto demonstra uma arquitetura medalhão (Bronze, Silver) para processamento de dados, com um forte foco em qualidade de dados e infraestrutura como código.

## Arquitetura

A infraestrutura do projeto é totalmente gerenciada pelo Terraform e é composta pelos seguintes serviços da GCP:

*   **Google Cloud Storage (GCS)**: Armazena os dados brutos, bronze e silver em um data lake.
*   **Google Cloud Composer (Airflow)**: Orquestra os pipelines de dados.
*   **Google BigQuery**: Atua como o data warehouse.
*   **Google Cloud KMS**: Utilizado para criptografia.
*   **Google Cloud IAM**: Gerencia as contas de serviço e permissões.
*   **Google Cloud Build**: Usado para CI/CD.

## Pipeline de Dados

O pipeline de dados é orquestrado pelo Airflow e segue uma arquitetura medalhão com duas camadas:

### 1. Camada Bronze

*   **DAG**: `01_bronze_ingestion_layer`
*   **Objetivo**: Ingerir dados brutos (CSV) da camada raw do data lake, convertê-los para o formato Parquet e armazená-los na camada bronze do data lake.
*   **Processo**:
    1.  Um job PySpark lê os arquivos CSV de `gs://<bucket>/datalake/raw/<table_name>`.
    2.  Os dados são gravados em formato Parquet em `gs://<bucket>/datalake/bronze/<table_name>`.
    3.  Os dados da camada bronze são carregados em uma tabela do BigQuery no dataset `bronze`.

### 2. Camada Silver

*   **DAG**: `02_silver_trusted_layer`
*   **Objetivo**: Transformar os dados da camada bronze, aplicar verificações de qualidade e armazená-los na camada silver.
*   **Processo**:
    1.  Os dados são lidos da camada bronze no GCS.
    2.  **Validação da Qualidade dos Dados**: Os dados são validados contra um contrato de dados definido no arquivo `contracts/schemas.json` usando a biblioteca Pandera. Isso garante que os dados estejam em conformidade com o esquema e os tipos de dados esperados.
    3.  **Transformação**: São aplicadas transformações básicas, como a remoção de espaços em branco de colunas de string. Uma coluna `dw_processed_at` é adicionada para rastrear quando os dados foram processados.
    4.  Os dados transformados são gravados em formato Parquet na camada silver no GCS em `gs://<bucket>/datalake/silver/<table_name>`.
    5.  Os dados da camada silver são carregados em uma tabela do BigQuery no dataset `silver`.

## Contratos de Dados

A qualidade dos dados é um aspecto central deste projeto. O arquivo `contracts/schemas.json` define o esquema esperado para cada tabela nas camadas bronze e silver. Isso inclui nomes de colunas, tipos de dados e se uma coluna pode ser nula. Esses contratos são aplicados pelo pipeline da camada silver usando a biblioteca Pandera.

## Infraestrutura como Código

Toda a infraestrutura deste projeto é gerenciada com o Terraform. O código do Terraform é organizado em módulos para cada serviço da GCP, tornando-o reutilizável e de fácil manutenção.

## CI/CD

O projeto utiliza o GitHub Actions e o Google Cloud Build para CI/CD. O arquivo `.github/workflows/cloudbuild.yaml` define um fluxo de trabalho que aciona um pipeline do Cloud Build quando as alterações são enviadas para a branch Develop. Esse pipeline pode ser usado para aplicar as alterações do Terraform e implantar as DAGs do Airflow.

