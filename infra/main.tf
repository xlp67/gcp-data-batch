module "iam" {
  source     = "./modules/gcp/iam"
  project_id = var.project_id
}

module "kms" {
  source       = "./modules/gcp/kms"
  kms_key      = var.kms_key
  location     = var.location
  project_id   = var.project_id
  kms_key_ring = var.kms_key_ring
}

module "gcs_bucket" {
  source                      = "./modules/gcp/gcs"
  location                    = var.location
  project_id                  = var.project_id
  bucket_name                 = var.bucket_name
  kms_key                     = module.kms.kms_key.id
  bucket_versioning           = var.bucket_versioning
  uniform_bucket_level_access = var.uniform_bucket_level_access
  depends_on                  = [module.kms]
}

module "composer" {
  source                 = "./modules/gcp/composer"
  region                 = var.region
  project_id             = var.project_id
  composer_name          = var.composer_name
  composer_image_version = var.composer_image_version
  composer_sa            = module.iam.composer_worker.id
  depends_on             = [module.kms, module.iam]
  env_variables = {
    "AIRFLOW_VAR_GCP_PROJECT_ID"   = var.project_id
    "AIRFLOW_VAR_GCP_BUCKET_NAME"  = module.gcs_bucket.bucket_name
    "AIRFLOW_VAR_GCP_PREFIX_PATH"  = "datalake/"
    "AIRFLOW_VAR_GCP_DATASET_NAME" = module.bigquery_dataset.dataset_id
    "AIRFLOW_VAR_GCP_TABLE_NAME"   = module.bigquery_dataset.tables["tabela_vendas"].table_id
  }
}

module "bigquery_dataset" {
  source        = "./modules/gcp/bigquery"
  env           = var.env
  tables        = var.tables
  friendly      = var.friendly
  location      = var.location
  project_id    = var.project_id
  dataset_id    = var.dataset_id
  expiration_ms = var.expiration_ms
  kms_key       = module.kms.kms_key.id
  kms_key_ring  = module.kms.kms_key.id
  depends_on    = [module.kms]
}

module "cloudbuild" {
  source                  = "./modules/gcp/build"
  region                  = var.region
  project_id              = var.project_id
  github_repo             = var.github_repo
  github_owner            = var.github_owner
  github_branch           = var.github_branch
  included_files          = [var.included_files]
  oauth_token_secret      = var.oauth_token_secret
  app_installation_id     = var.app_installation_id
  cloudbuild_trigger_name = var.cloudbuild_trigger_name
  cloudbuild_trigger_path = var.cloudbuild_trigger_path
  trigger_substitutions = {
    "_BUCKET_NAME" = module.composer.composer_bucket_name
  }
  depends_on = [module.gcs_bucket]
}




