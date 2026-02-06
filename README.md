# Secure Batch Data Lakehouse on GCP: Um Projeto de Portfólio "Flagship"

Este projeto "Secure Batch Data Lakehouse on GCP" foi desenvolvido como um **projeto de portfólio "Flagship"**, demonstrando proficiência avançada em **Engenharia de Dados e Arquitetura Cloud**. Ele reflete uma abordagem **estado da arte** na construção de pipelines de dados batch, com foco intransigente em **Segurança (LGPD/GDPR), Governança de Dados, FinOps (Otimização de Custos e Performance) e Qualidade de Código**.

A arquitetura implementa o padrão **Medallion (Bronze, Silver, Gold)**, garantindo que os dados sejam progressivamente refinados: desde a ingestão bruta até camadas prontas para consumo analítico, passando por etapas críticas de validação e anonimização.

## Arquitetura e Fluxo de Dados Detalhado

![Diagrama de Arquitetura Medalhão](https://i.imgur.com/example.png)  <!-- Placeholder para um diagrama de arquitetura real -->

O pipeline opera da seguinte forma:

1.  **Ingestão na Raw Zone (GCS):**
    *   Arquivos batch (CSV/Parquet) contendo telemetria de sensores (ex: indústria 4.0, supply chain) são enviados para um Bucket **GCS (`raw-zone`)**. Este Bucket é configurado com **Criptografia Gerenciada pelo Cliente (CMEK)** via Cloud KMS para garantir a segurança dos dados em repouso. Além disso, uma **política de ciclo de vida** (ex: exclusão de dados brutos após 30 dias) é aplicada para otimização de custos (FinOps), garantindo que apenas dados necessários permaneçam armazenados na camada mais cara.

2.  **Orquestração e Detecção (Cloud Composer/Airflow):**
    *   Um DAG do **Cloud Composer (Apache Airflow)** é acionado por um `GCSObjectExistenceSensor`, que monitora a chegada de novos arquivos na `raw-zone`. Esta orquestração garante o processamento pontual e automático dos lotes de dados.

3.  **Validação de Data Contract (Python/Pydantic):**
    *   A DAG executa um componente de validação (implementado em Python no `src/ingestion/validate.py` e `src/ingestion/contracts.py`). Utiliza-se **Pydantic** para validar o schema e a integridade de cada registro contra um Data Contract pré-definido.
    *   **"Fail Fast":** Se o contrato de dados for violado (e.g., tipo de dado incorreto, valor fora do range esperado, formato PII inválido), o arquivo é movido para um Bucket de **Quarentena (`quarantine-zone`)** para investigação. Isso previne a contaminação do Lakehouse e o processamento de dados inválidos, otimizando recursos (FinOps) e mantendo a qualidade dos dados.
    *   **Sucesso:** Se o arquivo for válido, ele é movido para a **Staging Zone (`staging-zone`)**, pronto para ser transformado.

4.  **Transformação com dbt (Bronze -> Silver -> Gold):**
    *   A DAG dispara um `dbt run` (executado via `KubernetesPodOperator` para isolamento e escalabilidade), que processa os dados através das camadas do Lakehouse:
        *   **Camada Bronze:** Uma `VIEW` no BigQuery é criada sobre a tabela externa que aponta para os dados na **Staging Zone**. Este `VIEW` define o Schema-on-Read, aplicando os tipos corretos e garantindo a consistência dos dados brutos processáveis.
        *   **Camada Silver:** Os dados são limpos, deduplicados e, crucialmente, campos sensíveis (PII como `operator_name`, `operator_email`) são **anonimizados**. Utiliza-se **Hashing (SHA-256) com um "Salt"** injetado de forma segura via Secret Manager (para conformidade LGPD/GDPR), tornando os dados irreversivelmente anonimizados, mas mantendo a capacidade de análise em dados hashados.
        *   **Camada Gold:** Os dados são agregados e transformados em tabelas de fatos e dimensões otimizadas para consumo analítico e Business Intelligence. As tabelas são intencionalmente **Particionadas por Data (`summary_date`) e Clusterizadas por ID de Entidade (`device_id`)**. Esta otimização é uma medida de **FinOps**, reduzindo drasticamente os custos de query e melhorando a performance ao escanear apenas os dados relevantes.

5.  **Armazenamento Final (BigQuery):**
    *   Todos os dados transformados residem em Datasets do BigQuery, organizados por camada (`bronze_layer`, `silver_layer`, `gold_layer`). Todos os Datasets são também criptografados com **CMEK** via Cloud KMS para garantir a segurança dos dados em repouso.

6.  **Pilar de Segurança e Governança:**
    *   **Criptografia End-to-End (CMEK):** Todos os Buckets GCS e Datasets BigQuery são criptografados com chaves gerenciadas pelo cliente via **Cloud KMS**, fornecendo controle total sobre as chaves de criptografia e aderência a requisitos de segurança empresarial e LGPD/GDPR.
    *   **Princípio do Menor Privilégio (IAM):** **Service Accounts** dedicadas são provisionadas com permissões IAM **granulares e estritamente necessárias** para cada componente do pipeline, minimizando a superfície de ataque.
    *   **Gerenciamento Seguro de Segredos:** Valores sensíveis como o "salt" para hashing de PII são armazenados e acessados de forma segura via **Secret Manager**, impedindo a exposição em código-fonte ou logs.

## Stack Tecnológica Detalhada

*   **Linguagem:** Python 3.10+ (com **Type Hinting** rigoroso e validação **Pydantic** para Data Contracts).
*   **IaC (Infrastructure as Code):** **Terraform** (código modular e reutilizável para provisionar toda a infraestrutura GCP de forma idempotente).
*   **Cloud:** Google Cloud Platform (GCP) - Utilização de serviços Managed/Serverless (GCS, BigQuery, Cloud Composer, Cloud KMS, Secret Manager).
*   **Armazenamento:** **GCS** (Buckets) e **BigQuery** (Datasets e Tabelas).
*   **Transformação:** **dbt Core** (Data Build Tool), com testes de qualidade de dados via `schema.yml` e `dbt-expectations`.
*   **Orquestração:** **Cloud Composer** (Apache Airflow) – Para scheduling, monitoramento e gestão de dependências.
*   **Processamento:** **Cloud Functions** (para triggers leves - *simulado no validate.py*), **BigQuery SQL** (para transformações em larga escala).
*   **Qualidade de Dados:** **Pydantic** (Data Contracts na ingestão), **dbt Tests** (`not_null`, `unique`, `expect_column_values_to_be_between`).

## Decisões Chave de Arquitetura e Justificativas de Alto Nível

### 1. Terraform Modular: Governança, Reutilização e Escalabilidade
A infraestrutura é definida em **módulos Terraform reutilizáveis** (`gcs`, `bigquery`, `kms`, `iam`, `secret_manager`). Esta abordagem garante:
*   **Consistência:** Recriação idêntica de ambientes (desenvolvimento, homologação, produção).
*   **Manutenibilidade:** Separação clara de responsabilidades, facilitando a compreensão e o isolamento de mudanças.
*   **Reutilização:** Módulos podem ser facilmente adaptados e reutilizados em outros projetos.
*   **Segurança e Governança:** Aplicação consistente de padrões de segurança (ex: CMEK, IAM com menor privilégio) em todos os recursos.

### 2. Conformidade LGPD/GDPR via Hashing Criptográfico com "Salt"
Em vez de simplesmente remover ou mascarar dados PII, implementamos uma estratégia de **Hashing SHA-256 com um "Salt" criptográfico** (gerenciado via Secret Manager). Este método oferece uma solução robusta para LGPD/GDPR:
*   **Anonimização Irreversível:** O valor original de PII não pode ser recuperado a partir do hash, protegendo a privacidade dos indivíduos.
*   **Integridade Analítica:** O mesmo PII, com o mesmo salt, sempre produz o mesmo hash. Isso permite realizar `JOINs` e agregações sobre dados anonimizados para análises de tendências e padrões, sem expor informações sensíveis.

### 3. FinOps na Camada Gold: Particionamento e Clustering no BigQuery
A tabela da camada Gold (`fct_daily_device_summary`) é otimizada para eficiência de custos e performance:
*   **Particionamento por Data (`summary_date`):** O BigQuery escaneia **apenas as partições relevantes** para a consulta. Isso resulta em **redução drástica nos custos de query e aumento da velocidade de execução**, uma medida fundamental de **FinOps** para Data Warehouses em nuvem.
*   **Clustering por ID de Entidade (`device_id`):** Dentro de cada partição de data, os dados são fisicamente organizados (`clustered`) por `device_id`. Isso otimiza ainda mais consultas que filtram ou agrupam por dispositivo, acelerando a recuperação de dados e, consequentemente, reduzindo o tempo de resposta e o custo.

### 4. Data Contracts na Entrada: "Fail Fast" para Qualidade e FinOps
A validação rigorosa dos dados de entrada usando **Pydantic Data Contracts** (`src/ingestion/contracts.py`) na fase de ingestão (`src/ingestion/validate.py`) é uma primeira linha de defesa crucial. Este princípio de **"Fail Fast"** garante que:
*   Dados malformados ou incompletos são identificados e rejeitados **antes** de consumir recursos de processamento caros.
*   A integridade do Data Lakehouse é mantida, evitando a propagação de "lixo" que poderia comprometer análises downstream.
*   Redução de **Overhead** na depuração e reprocessamento, impactando diretamente o FinOps.

### 5. Orquestração Robusta com KubernetesPodOperator (Airflow)
A execução de cargas de trabalho críticas (e.g., `dbt run`) via `KubernetesPodOperator` no Cloud Composer (`dags/gcp_secure_batch_pipeline_dag.py`) oferece:
*   **Isolamento de Dependências:** Cada tarefa roda em um ambiente de container limpo e dedicado, evitando conflitos de versão.
*   **Escalabilidade e Eficiência de Recursos:** Delega a execução para o GKE, utilizando recursos de forma elástica e otimizada (FinOps), ajustando-se à demanda da carga de trabalho.
*   **Observabilidade e Resiliência:** Facilita o monitoramento, o gerenciamento de logs e a recuperação de falhas em ambientes distribuídos.

## Como Iniciar o Projeto (Passo a Passo)

Para replicar e explorar este projeto, siga os passos abaixo. Certifique-se de que todas as credenciais necessárias e permissões no GCP estejam configuradas para sua Service Account.

1.  **Pré-requisitos:**
    *   CLI `gcloud` autenticada e configurada com o projeto GCP correto.
    *   Terraform CLI instalada (versão 1.x ou superior).
    *   Python 3.10+ e `pip` instalados.
    *   Docker Desktop ou um ambiente de execução Docker (para construir imagens dbt para KubernetesPodOperator).
    *   Acesso e permissões no GCP para criar recursos (BigQuery, GCS, KMS, Secret Manager, IAM).

2.  **Configurar o Ambiente GCP (via Terraform):**
    *   Navegue até o diretório `infra/`.
    *   Crie um arquivo `terraform.tfvars` (ou utilize variáveis de ambiente) com as seguintes configurações. **ATENÇÃO: NUNCA commite valores de segredos reais em repositórios públicos.**
        ```hcl
        gcp_project_id      = "seu-projeto-gcp-id"              # Substitua pelo ID do seu projeto GCP
        gcp_region          = "us-central1"                     # Ou sua região GCP preferida
        pii_salt_secret_value = "um-valor-secreto-para-seu-salt" # Valor do salt para hashing PII (ex: um UUIDv4)
        ```
    *   Execute os comandos para provisionar a infraestrutura:
        ```bash
        cd infra/
        terraform init                  # Inicializa o Terraform e baixa os providers
        terraform plan                  # Visualiza o plano de execução (verifique antes de aplicar!)
        terraform apply                 # Aplica as mudanças para provisionar os recursos no GCP
        ```
    *   Anote o email da `Service Account` principal do pipeline (`output "service_account_email"` do módulo IAM), pois será necessário para configurações no Airflow e dbt.

3.  **Configurar e Executar o dbt (Localmente):**
    *   **Instalação de Dependências:** Instale o dbt-bigquery e dbt-expectations:
        ```bash
        pip install dbt-bigquery dbt-expectations
        ```
    *   **Configuração de Perfil:** Crie ou atualize seu `~/.dbt/profiles.yml` para conectar ao BigQuery utilizando a Service Account criada (via `keyfile` ou autenticação de workload identity se for rodar de dentro do GCP).
        ```yaml
        gcp_secure_batch_dwh:
          target: dev
          outputs:
            dev:
              type: bigquery
              method: service-account
              project: "seu-projeto-gcp-id"                   # Substitua pelo ID do seu projeto GCP
              dataset: dbt_dev_dataset                       # Um Dataset dedicado para o desenvolvimento local do dbt
              threads: 4
              keyfile: "/caminho/para/sua/service-account-key.json" # Caminho para a chave JSON da Service Account
        ```
    *   **Variável PII Salt:** Para execução local do dbt, você precisará expor a variável de ambiente `DBT_PII_SALT` com o mesmo valor usado no `terraform.tfvars` ou passá-la via CLI. **NUNCA exponha segredos diretamente em scripts ou no histórico do shell.**
        ```bash
        export DBT_PII_SALT="um-valor-secreto-para-seu-salt" # O mesmo valor usado em terraform.tfvars
        ```
    *   **Execução dos Modelos:** Navegue até o diretório `dbt_project/` e execute os comandos:
        ```bash
        cd dbt_project/
        dbt debug                           # Verifica a conectividade e configuração do dbt
        dbt run --profile gcp_secure_batch_dwh   # Executa os modelos Bronze, Silver e Gold
        dbt test --profile gcp_secure_batch_dwh  # Roda os testes de qualidade de dados definidos
        ```

4.  **Simular a Ingestão e Validação (Python Localmente):**
    *   Navegue até o diretório `src/ingestion/`.
    *   O script `validate.py` contém um bloco `if __name__ == '__main__':` que simula a ingestão e validação com dados válidos, inválidos e vazios.
    *   Para rodar a simulação:
        ```bash
        cd src/ingestion/
        pip install pandas pydantic google-cloud-storage # Instala dependências do script
        python validate.py
        ```
    *   (Opcional) Para uma execução completa, um arquivo CSV de exemplo (`valid_data.csv`) será gerado localmente pelo script de simulação. Você pode fazer o upload deste arquivo para o Bucket `raw-zone` que o Terraform criou para simular um trigger do Airflow.

5.  **Configurar e Implantar o Orquestrador (Cloud Composer/Airflow):**
    *   **Crie um Ambiente Cloud Composer:** Certifique-se de que o ambiente Composer esteja configurado na mesma região que seus Buckets GCS e Datasets BigQuery.
    *   **Permissões da Service Account do Composer:** A Service Account padrão do seu ambiente Composer deve ter permissões para interagir com GCS, BigQuery, KMS e Secret Manager. Adicione, no mínimo, `roles/composer.worker`, `roles/storage.objectViewer`, `roles/bigquery.dataViewer`, e permissões para acessar os secrets e chaves KMS criados.
    *   **Upload da DAG:** Faça o upload do arquivo `dags/gcp_secure_batch_pipeline_dag.py` para o Bucket do DAGs do seu ambiente Composer (geralmente `gs://<nome-do-ambiente-composer>-bucket/dags/`).
    *   **Configurações do Airflow (Segredos e Variáveis):**
        *   Crie uma conexão do tipo `Google Cloud` com `ID: google_cloud_default` no Airflow UI.
        *   **Crie um Secret (GCP Secret Manager):** Armazene o valor do `pii_salt_secret_value` no Secret Manager.
        *   **Configure Variáveis de Ambiente no Airflow:** Utilize um mecanismo seguro (e.g., Airflow Connections ou Macros com Secret Manager) para injetar o `DBT_PII_SALT` como variável de ambiente para a execução do `KubernetesPodOperator` do dbt. No exemplo da DAG, `{{ macros.airflow.get_secret('pii-hashing-salt', 'ssm-parameter-name') }}` é um placeholder que você precisará adaptar para o seu método de recuperação de secret.
    *   **Construir Imagem Docker para dbt:** Crie e faça o push de uma imagem Docker (`gcr.io/your-gcp-project-id/dbt-runner:latest`) que contenha o dbt-bigquery e quaisquer outras dependências. Esta imagem será usada pelo `KubernetesPodOperator` na DAG.
    *   **Monitoramento:** Acompanhe a execução da DAG no Airflow UI.

## CI/CD com GitHub Actions

Este projeto inclui um pipeline de CI/CD configurado com GitHub Actions no arquivo `.github/workflows/ci.yml`. Este pipeline garante a qualidade do código e a validação contínua da infraestrutura e lógica de transformação.

**Etapas do Pipeline:**
*   **Linting e Type Checking (Python):** `flake8`, `black --check`, `mypy` para garantir a conformidade com padrões de código e tipagem.
*   **Testes Unitários (Python):** `pytest` para verificar a lógica dos scripts Python.
*   **Validação Terraform:** `terraform init -backend=false`, `terraform validate`, `terraform fmt -check` para garantir a sintaxe e as boas práticas de IaC.
*   **Validação e Testes dbt:** `dbt debug`, `dbt parse`, `dbt test` para verificar a configuração, sintaxe dos modelos e a qualidade dos dados. Requer credenciais GCP configuradas via GitHub Secrets para execução completa.
*   **Validação de DAGs Airflow:** `airflow dags lint` para verificar a sintaxe e a estrutura das DAGs.

**Configuração de Credenciais para CI/CD (GitHub Secrets):**
Para que os jobs de dbt e Terraform possam interagir com o GCP, você precisará configurar os seguintes GitHub Secrets em seu repositório:
*   `GCP_PROJECT_ID`: O ID do seu projeto GCP.
*   `GCP_SERVICE_ACCOUNT_KEY`: A chave JSON de uma Service Account com as permissões mínimas necessárias para:
    *   BigQuery (ex: `roles/bigquery.dataEditor`)
    *   Cloud KMS (`roles/cloudkms.viewer` e `roles/cloudkms.cryptoKeyEncrypterDecrypter`)
    *   Secret Manager (`roles/secretmanager.secretAccessor`)
    *   GCS (ex: `roles/storage.objectViewer`, `roles/storage.objectCreator`)

---
