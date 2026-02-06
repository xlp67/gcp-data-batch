provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
module "kms" {
  source           = "./modules/kms"
  gcp_project_id   = var.gcp_project_id
  key_ring_name    = var.key_ring_name
  key_name         = var.cmek_key_name
}
module "secret_manager" {
  source           = "./modules/secret_manager"
  gcp_project_id   = var.gcp_project_id
  secret_id        = var.pii_salt_secret_id
  secret_value     = var.pii_salt_secret_value
}
module "iam" {
  source                 = "./modules/iam"
  gcp_project_id         = var.gcp_project_id
  service_account_id     = var.service_account_id
  kms_key_ring_id        = module.kms.key_ring_id
  pii_salt_secret_id     = module.secret_manager.secret_id
}
module "gcs" {
  source                = "./modules/gcs"
  gcp_project_id        = var.gcp_project_id
  location              = var.gcp_region
  cmek_key_name         = module.kms.key_id
  service_account_email = module.iam.service_account_email
}
module "bigquery" {
  source                = "./modules/bigquery"
  gcp_project_id        = var.gcp_project_id
  location              = var.gcp_region
  cmek_key_name         = module.kms.key_id
  service_account_email = module.iam.service_account_email
}