output "kms_key" {
  value = google_kms_crypto_key.this
}

output "kms_key_ring" {
  value = google_kms_key_ring.this
}