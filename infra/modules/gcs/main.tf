
resource "google_storage_bucket" "bucket_seguro" {
  name     = var.bucket_name
  location = var.bucket_location
  versioning {
    enabled = var.bucket_versioning
  }
  encryption {
    default_kms_key_name = var.kms_key_id
  }
  depends_on = [google_kms_crypto_key_iam_member.gcs_kms_user]
}