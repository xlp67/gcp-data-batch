resource "google_kms_key_ring" "keyring" {
  project  = var.gcp_project_id
  name     = var.key_ring_name
  location = "global"
}
resource "google_kms_crypto_key" "key" {
  name            = var.key_name
  key_ring        = google_kms_key_ring.keyring.id
  rotation_period = "100000s"
  lifecycle {
    prevent_destroy = true
  }
}