# Secure Batch Data Lakehouse on GCP: A Flagship Portfolio Project

Este projeto demonstra a construção de um pipeline de dados batch de ponta a ponta na Google Cloud Platform (GCP). Ele foi projetado para refletir os desafios do mundo real em engenharia de dados, com um foco rigoroso em **segurança, governança de dados (LGPD/GDPR), infraestrutura como código (IaC) e otimização de custos (FinOps)**.

A arquitetura segue o padrão **Medallion (Bronze, Silver, Gold)**, garantindo que os dados sejam progressivamente limpos, enriquecidos e agregados para análise.

## Arquitetura e Fluxo de Dados

![Arquitetura Medalhão](https://i.imgur.com/example.png)  

1.  **Ingestão:** Arquivos batch (CSV/Parquet) contendo telemetria de sensores são enviados para um bucket **GCS (Raw Zone)**.
2.  **Orquestração:** Um **Cloud Composer (Airflow)** DAG detecta o novo arquivo.
3.  **Validação (Data Contract):** Uma **Cloud Function** (simulada por um script Python) é acionada. Ela usa **Pydantic** para validar o schema do arquivo contra um "Data Contract" pré-definido.
    *   **Sucesso:** O arquivo é movido para a **Staging Zone**.
    *   **Falha:** O arquivo é movido para a **Quarantine Zone** para análise de falha, prevenindo a contaminação do Lakehouse.
4.  **Transformação (dbt):** O DAG do Airflow dispara um `dbt run`.
    *   **Camada Bronze:** Uma `VIEW` é criada sobre a tabela externa que aponta para os arquivos na **Staging Zone**.
    *   **Camada Silver:** Os dados são limpos, deduplicados e, crucialmente, campos sensíveis (PII) são **anonimizados usando Hashing (SHA-256) com Salt**, garantindo a conformidade com a LGPD.
    *   **Camada Gold:** Tabela agregada focada em performance (Use **Partitioning** por Data e **Clustering** por ID de entidade) para demonstrar conhecimentos de FinOps.
5.  **Armazenamento:** Todos os dados processados residem em datasets do **BigQuery**, separados por camada (Bronze, Silver, Gold).
6.  **Segurança e Governança:**
    *   **Criptografia:** Todos os Buckets GCS e Datasets BigQuery são criptografados com **chaves de criptografia gerenciadas pelo cliente (CMEK)**, controladas via **Cloud KMS**.
    *   **Menor Privilégio:** **Service Accounts** dedicadas com permissões IAM estritamente necessárias são usadas em todo o pipeline.
    *   **Gerenciamento de Segredos:** O "salt" para o hashing de PII é armazenado de forma segura no **Secret Manager**.

## Stack Tecnológica

*   **Linguagem:** Python 3.10+ (com Type Hinting, Pydantic)
*   **IaC:** Terraform (Modularizado)
*   **Cloud:** Google Cloud Platform (GCP)
*   **Armazenamento:** GCS (Buckets) e BigQuery
*   **Transformação:** dbt Core (com dbt-expectations)
*   **Orquestração:** Cloud Composer (Airflow)
*   **Processamento:** Cloud Functions e BigQuery Jobs
*   **Qualidade:** Pydantic (Data Contracts) e dbt Tests

## Decisões Chave de Arquitetura

### Por que Terraform Modular?
A infraestrutura é definida em módulos reutilizáveis (`gcs`, `bigquery`, `kms`). Isso não apenas segue as melhores práticas de IaC, mas também permite que a infraestrutura seja escalada e mantida de forma mais eficiente e com menor risco.

### Conformidade LGPD via Hashing com Salt
Em vez de simplesmente remover ou mascarar dados PII, implementamos uma estratégia de hashing SHA-256 com "salt". Isso anonimiza os dados de forma irreversível, mas mantém a capacidade de realizar joins e análises sobre os identificadores hash, preservando o valor analítico dos dados sem expor informações sensíveis. O "salt" é gerenciado pelo Secret Manager para máxima segurança.

### FinOps na Camada Gold: Particionamento e Clustering
A tabela da camada Gold não é apenas uma agregação. Ela é intencionalmente `particionada` por data e `clusterizada` por `device_id`.
*   **Particionamento:** Quando os analistas consultam um intervalo de datas específico (ex: `WHERE summary_date > '2026-01-01'`), o BigQuery lê apenas as partições relevantes, resultando em uma **redução drástica de custos** e um **aumento significativo de performance**.
*   **Clustering:** Dentro de cada partição, os dados são fisicamente ordenados pelo `device_id`. Isso acelera ainda mais as consultas que filtram ou agregam por dispositivo.

### Data Contracts na Entrada
A validação com Pydantic na ingestão é uma primeira linha de defesa crucial. Ela garante a "sanidade" dos dados *antes* que eles consumam recursos de processamento caros, aderindo a um princípio de "fail fast" (falhe rápido) e mantendo a integridade do Data Lakehouse.

## Como Executar o Projeto

1.  **Configurar o Ambiente GCP:**
    *   Autentique sua CLI `gcloud`.
    *   Crie um arquivo `terraform.tfvars` na pasta `infra/` com seu `gcp_project_id`.

2.  **Provisionar a Infraestrutura:**
    ```bash
    cd infra/
    terraform init
    terraform apply
    ```

3.  **Configurar o dbt:**
    *   Crie seu perfil em `~/.dbt/profiles.yml` para conectar ao BigQuery.
    *   Exponha a variável de ambiente para o "salt" (ou passe via CLI).

4.  **Executar a Transformação:**
    ```bash
    cd dbt_project/
    # Injetando o salt via variável de ambiente
    export DBT_PII_SALT=$(gcloud secrets versions access latest --secret="pii-hashing-salt")
    dbt run
    dbt test
    ```

5.  **Implantar o Orquestrador:**
    *   Configure o ambiente do Cloud Composer.
    *   Faça o upload do arquivo da DAG para o bucket do Composer.
    *   Configure as variáveis de ambiente e conexões no Airflow UI.

Este projeto representa uma base sólida e profissional para demonstrar competências avançadas em engenharia de dados em um ambiente de nuvem moderno.
