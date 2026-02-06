locals {
  dataset_names = ["bronze_layer", "silver_layer", "gold_layer"]
}
resource "google_bigquery_dataset" "datasets" {
  for_each = toset(local.dataset_names)
  project    = var.gcp_project_id
  dataset_id = each.key
  location   = var.location
  default_encryption_configuration {
    kms_key_name = var.cmek_key_name
  }
}
resource "google_bigquery_dataset_iam_member" "dataset_iam" {
  for_each = google_bigquery_dataset.datasets
  project    = var.gcp_project_id
  dataset_id = each.value.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.service_account_email}"
}