resource "google_service_account" "service_account" {
  project      = var.gcp_project_id
  account_id   = var.service_account_id
  display_name = "Data Pipeline Service Account"
}
resource "google_kms_key_ring_iam_member" "iam_kms" {
  key_ring_id = var.kms_key_ring_id
  role        = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member      = "serviceAccount:${google_service_account.service_account.email}"
}
resource "google_secret_manager_secret_iam_member" "iam_secret" {
  project   = var.gcp_project_id
  secret_id = var.pii_salt_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.service_account.email}"
}