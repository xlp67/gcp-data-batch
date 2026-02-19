project_id = "project-abdcb642-e2ac-47c0-b1d"
region = "us-east1"
location = "US"
env="dev"

# GCS
bucket_name = "xlp67-interprise-bucket"
bucket_versioning = true
uniform_bucket_level_access = true

# KMS
kms_key = "key_churn_dev"
kms_key_ring = "key_ring_churn_dev"

# COMPOSER
composer_name="composer-dev"
composer_image_version = "composer-3-airflow-2"

# CLOUDBUILD
cloudbuild_trigger_name="data-batch-trigger"
github_branch="develop"
github_owner="thiiagowilliam"
github_repo = "gcp-data-batch"
cloudbuild_trigger_path="cloudbuild.yaml"
app_installation_id="111001074" 
oauth_token_secret = "projects/327909419888/secrets/gcp-data-batch-github-oauthtoken-7e8c1d/versions/1"

# BIGQUERY
dataset_id = "churn_dev"
friendly = "Dados de Churn [DEV]"
expiration_ms = 3600000
tables = {
    "tabela_vendas" = {
      partition_field = "data_venda"
      schema = [
        { name = "id",             type = "INTEGER",    mode = "REQUIRED", description = "ID único da venda" },
        { name = "cliente_id",    type = "INTEGER",    mode = "REQUIRED", description = "FK para tabela de clientes" },
        { name = "produto_id",    type = "INTEGER",    mode = "NULLABLE", description = "ID do produto vendido" },
        { name = "data_venda",    type = "DATE",      mode = "REQUIRED", description = "Data da transação" },
        { name = "valor_total",   type = "FLOAT",   mode = "NULLABLE", description = "Valor total da venda" },
        { name = "quantidade",    type = "INTEGER",   mode = "NULLABLE", description = "Quantidade de itens" },
        { name = "metodo_pagto",  type = "STRING",    mode = "NULLABLE", description = "Cartão, Boleto, PIX, etc" }
      ]
    },
    
    "tabela_clientes" = {
      partition_field = "data_cadastro"
      schema = [
        { name = "id",             type = "INTEGER",    mode = "REQUIRED", description = "ID único do cliente" },
        { name = "nome",           type = "STRING",    mode = "NULLABLE", description = "Nome completo" },
        { name = "email",          type = "STRING",    mode = "NULLABLE", description = "E-mail de contato" },
        { name = "telefone",       type = "STRING",    mode = "NULLABLE", description = "Telefone com DDD" },
        { name = "cidade",         type = "STRING",    mode = "NULLABLE", description = "Cidade de residência" },
        { name = "estado",         type = "STRING",    mode = "NULLABLE", description = "UF" },
        { name = "data_cadastro",  type = "DATE",      mode = "REQUIRED", description = "Data em que o cliente se registrou" },
        { name = "status",         type = "STRING",    mode = "NULLABLE", description = "Ativo, Inativo, Suspenso" }
      ]
    },
  }