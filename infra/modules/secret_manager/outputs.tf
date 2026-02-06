output "secret_id" {
  description = "The full ID of the secret."
  value       = google_secret_manager_secret.secret.id
}