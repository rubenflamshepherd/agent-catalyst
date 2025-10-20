// ABOUTME: Exposes useful details about the deployed Cloud Run resources.
// ABOUTME: Shares Cloud Run URL and Artifact Registry repository path.
output "cloud_run_url" {
  description = "Public URL of the Cloud Run service"
  value       = google_cloud_run_service.app.status[0].url
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository path for application images"
  value       = local.artifact_repo_path
}
