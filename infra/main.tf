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

# module "composer" {
#   source                 = "./modules/gcp/composer"
#   region                 = var.region
#   project_id             = var.project_id
#   composer_name          = var.composer_name
#   composer_image_version = var.composer_image_version
#   composer_sa            = module.iam.composer_worker.id
#   depends_on             = [module.kms, module.iam]
# }

module "bigquery_dataset_churn" {
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
  env                     = var.env
  region                  = var.region
  location                = var.region
  project_id              = var.project_id
  github_repo             = var.github_repo
  github_owner            = var.github_owner
  bucket_name             = module.gcs_bucket.bucket_name
  github_branch           = var.github_branch
  oauth_token_secret      = var.oauth_token_secret
  app_installation_id     = var.app_installation_id
  cloudbuild_trigger_name = var.cloudbuild_trigger_name
  cloudbuild_trigger_path = var.cloudbuild_trigger_path
  depends_on              = [module.gcs_bucket]
}




