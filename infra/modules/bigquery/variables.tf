variable "gcp_project_id" {
  description = "The GCP project ID."
  type        = string
}
variable "location" {
  description = "The location for the BigQuery datasets."
  type        = string
}
variable "cmek_key_name" {
  description = "The CMEK to use for encrypting the datasets."
  type        = string
}
variable "service_account_email" {
  description = "The service account to grant permissions."
  type        = string
}