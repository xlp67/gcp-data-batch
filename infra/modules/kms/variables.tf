variable "gcp_project_id" {
  description = "The GCP project ID."
  type        = string
}
variable "key_ring_name" {
  description = "Name for the KMS KeyRing."
  type        = string
}
variable "key_name" {
  description = "Name for the CMEK."
  type        = string
}