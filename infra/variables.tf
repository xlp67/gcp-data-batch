variable "region" {
  type = string
}

variable "dataset_id" {
  type = string
}

variable "friendly" {
  type = string
}

variable "location" {
  type = string
}

variable "expiration_ms" {
  type = number
}

variable "kms_key" {
  type = string
}

variable "kms_key_ring" {
  type = string
}

variable "project_id" {
  type = string
}

variable "tables" {}
variable "env" {}