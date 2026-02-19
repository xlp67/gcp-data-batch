resource "google_composer_environment" "this" {
  project = var.project_id
  name    = var.composer_name
  region  = var.region

  config {
    node_config {
      service_account = var.composer_sa
    }
    software_config {
      image_version = var.composer_image_version
    }
  }
}