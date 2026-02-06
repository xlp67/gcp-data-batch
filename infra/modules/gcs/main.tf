locals {
  bucket_suffixes = ["raw-zone", "staging-zone", "curated-zone", "quarantine"]
}
resource "google_storage_bucket" "buckets" {
  for_each = toset(local.bucket_suffixes)
  project                     = var.gcp_project_id
  name                        = "${var.gcp_project_id}-data-${each.key}"
  location                    = var.location
  uniform_bucket_level_access = true
  force_destroy               = true
  encryption {
    default_kms_key_name = var.cmek_key_name
  }
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = (each.key == "raw-zone" ? 30 : null)
    }
  }
}
resource "google_storage_bucket_iam_member" "bucket_iam" {
  for_each = google_storage_bucket.buckets
  bucket = each.value.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.service_account_email}"
}