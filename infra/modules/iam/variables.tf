variable "gcp_project_id" {
  description = "The GCP project ID."
  type        = string
}
variable "service_account_id" {
  description = "ID for the service account."
  type        = string
}
variable "kms_key_ring_id" {
  description = "The ID of the KMS KeyRing to grant permissions to."
  type        = string
}
variable "pii_salt_secret_id" {
  description = "The ID of the Secret Manager secret for PII salt access."
  type        = string
}