// ABOUTME: Enables required GCP APIs for the project.
// ABOUTME: Includes Artifact Registry, Cloud Build, and Cloud Run APIs.

resource "google_project_service" "required" {
  for_each = {
    "artifactregistry.googleapis.com" = "artifactregistry.googleapis.com"
    "cloudbuild.googleapis.com"       = "cloudbuild.googleapis.com"
    "run.googleapis.com"              = "run.googleapis.com"
  }

  project                    = var.project_id
  service                    = each.value
  disable_dependent_services = false
  disable_on_destroy         = false
}
