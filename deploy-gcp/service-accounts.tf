// ABOUTME: Creates service accounts for Cloud Run runtime and Cloud Build execution.
// ABOUTME: Defines dedicated service accounts for secure service-to-service communication.

resource "google_service_account" "run" {
  project      = var.project_id
  account_id   = local.run_service_account
  display_name = "${var.app_name} Cloud Run runtime service account"
}

resource "google_service_account" "build" {
  project      = var.project_id
  account_id   = local.build_service_account
  display_name = "${var.app_name} Cloud Build execution service account"
}
