data "google_project" "project" {}

# 
resource "google_service_account" "cloudbuild" {
  project      = data.google_project.project.project_id
  account_id   = "${var.cloudbuild_trigger_name}-sa"
  display_name = "Cloud Build SA - ${var.cloudbuild_trigger_name}"
  description  = "Service Account usado pelos triggers do Cloud Build v2"
}

resource "google_service_account_iam_member" "cloudbuild_impersonate" {
  service_account_id = google_service_account.cloudbuild.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"

  depends_on = [google_service_account.cloudbuild]
}

resource "google_project_iam_member" "cloudbuild_builder" {
  project = data.google_project.project.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}

resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  secret_id = split("/versions/", var.oauth_token_secret)[0]
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# 
resource "google_cloudbuildv2_connection" "this" {
  location = var.region
  name     = var.cloudbuild_trigger_name
  github_config {
    app_installation_id = var.app_installation_id
    authorizer_credential {
      oauth_token_secret_version = var.oauth_token_secret
    }
  }
  depends_on = [google_secret_manager_secret_iam_member.secret_accessor]
}

resource "google_cloudbuildv2_repository" "this" {
  name              = var.github_repo
  parent_connection = google_cloudbuildv2_connection.this.id
  remote_uri        = "https://github.com/${var.github_owner}/${var.github_repo}.git"

  depends_on = [google_cloudbuildv2_connection.this]
}

resource "google_cloudbuild_trigger" "repo-trigger" {
  name     = "${var.cloudbuild_trigger_name}-repo"
  location = var.region
  filename = var.cloudbuild_trigger_path
  service_account = google_service_account.cloudbuild.id

  repository_event_config {
    repository = google_cloudbuildv2_repository.this.id
    push {
      branch = "^${var.github_branch}$"
    }
  }
  depends_on = [
    google_service_account_iam_member.cloudbuild_impersonate,
    google_project_iam_member.cloudbuild_builder
  ]
}