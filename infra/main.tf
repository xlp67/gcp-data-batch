module "kms" {
  source       = "./modules/kms"
  project_id   = var.project_id
  kms_key      = var.kms_key
  kms_key_ring = var.kms_key_ring
  location     = var.location
}

module "bigquery_dataset_churn" {
  source        = "./modules/bigquery"
  project_id    = var.project_id
  dataset_id    = var.dataset_id
  friendly      = var.friendly
  location      = var.location
  expiration_ms = var.expiration_ms
  kms_key       = module.kms.kms_key.id
  kms_key_ring  = module.kms.kms_key.id
  env           = var.env
  tables        = var.tables
}


