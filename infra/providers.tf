terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.11.1"
    }
    google = {
      source  = "hashicorp/google"
      version = "7.20.0"
    }
  }
}


provider "google" {
  project = var.project_id
  region  = var.region
}

provider "github" {

}