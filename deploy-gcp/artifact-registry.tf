// ABOUTME: Creates and configures the Artifact Registry repository for container images.
// ABOUTME: Includes cleanup policies to delete images older than 30 days.

resource "google_artifact_registry_repository" "services" {
  provider = google

  location      = local.region
  repository_id = local.artifact_repo
  description   = "Container images for ${var.app_name} services"
  format        = "DOCKER"

  cleanup_policies {
    id     = "delete-older-than-30d"
    action = "DELETE"
    condition {
      older_than = "2592000s"
    }
  }

  depends_on = [google_project_service.required["artifactregistry.googleapis.com"]]
}
