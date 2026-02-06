variable "gcp_project_id" {
  description = "The GCP project ID."
  type        = string
}
variable "gcp_region" {
  description = "The GCP region for resources."
  type        = string
  default     = "us-central1"
}
variable "service_account_id" {
  description = "The ID for the main service account."
  type        = string
  default     = "sa-data-pipeline"
}
variable "key_ring_name" {
  description = "The name of the KMS KeyRing."
  type        = string
  default     = "kr-data-services"
}
variable "cmek_key_name" {
  description = "The name of the Customer-Managed Encryption Key (CMEK)."
  type        = string
  default     = "key-bq-gcs-encryption"
}
variable "pii_salt_secret_id" {
  description = "The ID of the Secret Manager secret for PII salt."
  type        = string
  default     = "pii-hashing-salt"
}
variable "pii_salt_secret_value" {
  description = "The actual salt value for PII hashing. WARNING: Do not commit real secrets."
  type        = string
  sensitive   = true
  default     = "a-very-secret-salt-value-for-demo"
}