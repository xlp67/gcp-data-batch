resource "google_bigquery_dataset" "this" {
  project                     = var.project_id
  dataset_id                  = var.dataset_id
  friendly_name             = var.friendly
  description                 = "${var.dataset_id} Dataset"
  location                    = var.location
  default_table_expiration_ms = var.expiration_ms

  default_encryption_configuration {
    kms_key_name = var.kms_key
  }
}

resource "google_bigquery_dataset" "default" {
    project = var.project_id
    dataset_id                  = "foo"
    friendly_name               = "test"
    description                 = "This is a test description"
    location                    = "EU"
    default_table_expiration_ms = 3600000

    labels = {
    env = "default"
    }
    }

resource "google_bigquery_table" "this" {
    project = var.project_id
    for_each            = var.tables
    dataset_id          = google_bigquery_dataset.this.dataset_id
    table_id            = each.key
    schema              = each.value.schema
    deletion_protection = var.env == "prod" ? true : false
    dynamic "time_partitioning" {
    for_each = each.value.partition_field != null ? [1] : []
    content {
        type  = "DAY"
        field = each.value.partition_field
    }
    }
}