variable "gcp_project_id" {
  description = "The GCP project ID."
  type        = string
}
variable "secret_id" {
  description = "The ID of the secret to create."
  type        = string
}
variable "secret_value" {
  description = "The value to store in the secret."
  type        = string
  sensitive   = true
}