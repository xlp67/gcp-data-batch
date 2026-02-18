variable "dataset_id" {}
variable "friendly" {}
variable "location" {}
variable "expiration_ms" {}
variable "kms_key" {}
variable "kms_key_ring" {}
variable "project_id" {}
variable "tables" {}
variable "env" {}
variable "deletion_protection" {
  type        = bool
  default     = false
}
