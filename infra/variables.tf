variable "env" {}
variable "region" {}
variable "location" {}
variable "project_id" {}

# BIGQUERY
variable "tables" {}
variable "friendly" {}
variable "dataset_id" {}
variable "expiration_ms" {}

# KMS
variable "kms_key" {}
variable "kms_key_ring" {}

# GCS
variable "bucket_name" {}
variable "bucket_versioning" {}
variable "uniform_bucket_level_access" {}

# COMPOSER
variable "composer_name" {}
variable "composer_image_version" {}

# CLOUDBUILD
variable "github_repo" {}
variable "github_owner" {}
variable "github_branch" {}
variable "oauth_token_secret" {}
variable "app_installation_id" {}
variable "cloudbuild_trigger_name" {}
variable "cloudbuild_trigger_path" {}

variable "trigger_substitutions" {}