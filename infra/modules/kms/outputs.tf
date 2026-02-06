output "key_id" {
  description = "The full ID of the KMS key."
  value       = google_kms_crypto_key.key.id
}
output "key_ring_id" {
    description = "The full ID of the KMS KeyRing."
    value = google_kms_key_ring.keyring.id
}