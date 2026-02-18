variable "dataset_id" {}
variable "friendly" {}
variable "location" {}
variable "expiration_ms" {}
variable "kms_key" {}
variable "kms_key_ring" {}
variable "project_id" {}

variable "tables" {
  type = map(object({
    partition_field = optional(string)
    schema          = list(object({
      name        = string
      type        = string
      mode        = optional(string)
      description = optional(string)
    }))
  }))
}
variable "env" {}


