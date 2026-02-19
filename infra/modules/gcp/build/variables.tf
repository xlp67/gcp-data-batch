variable "cloudbuild_trigger_name" {}
variable "cloudbuild_trigger_path" {}
variable "github_branch" {}
variable "github_owner" {}
variable "github_repo" {}
variable "oauth_token_secret" {}
variable "app_installation_id" {}
variable "region" {}
variable "project_id" {}

variable "trigger_substitutions" {
  description = "Mapa de variáveis de substituição (substitutions) para o trigger do Cloud Build"
  type        = map(string)
  default     = {}
}