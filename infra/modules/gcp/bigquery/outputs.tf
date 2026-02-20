# modules/gcp/bigquery/outputs.tf

output "dataset_id" {
  value       = google_bigquery_dataset.this.dataset_id
}

output "tables" {
  value       = google_bigquery_table.this
}