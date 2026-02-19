variable "project_id" {}
variable "region" {}
variable "location" {}
variable "env" {}

# BIGQUERY
variable "dataset_id" {}
variable "tables" {}
variable "friendly" {}
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