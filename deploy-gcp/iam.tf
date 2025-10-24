// ABOUTME: Manages IAM roles and permissions for all service accounts.
// ABOUTME: Configures permissions for Cloud Run, Cloud Build, and artifact registry access.

resource "google_project_iam_member" "run_service_account_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.run.email}"
}

resource "google_project_iam_member" "cloud_build_project_roles" {
  for_each = toset([
    "roles/artifactregistry.writer",
    "roles/run.admin",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${local.cloud_build_account}"

  depends_on = [google_project_service.required["cloudbuild.googleapis.com"]]
}

resource "google_service_account_iam_member" "cloud_build_impersonation" {
  service_account_id = google_service_account.run.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${local.cloud_build_account}"

  depends_on = [google_project_service.required["cloudbuild.googleapis.com"]]
}

resource "google_project_iam_member" "build_service_account_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/artifactregistry.writer",
    "roles/artifactregistry.admin",
    "roles/run.admin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/cloudbuild.builds.editor",
    "roles/compute.networkAdmin",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.build.email}"

  depends_on = [google_project_service.required["cloudbuild.googleapis.com"]]
}

resource "google_service_account_iam_member" "build_sa_impersonation" {
  service_account_id = google_service_account.build.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${local.cloud_build_account}"

  depends_on = [google_project_service.required["cloudbuild.googleapis.com"]]
}

resource "google_service_account_iam_member" "build_sa_run_service_account_user" {
  service_account_id = google_service_account.run.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.build.email}"
}

resource "google_storage_bucket_iam_member" "build_service_account_state_bucket_access" {
  bucket = "agent-catalyst-c405ad20-terraform-state"
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.build.email}"
}

resource "google_artifact_registry_repository_iam_member" "cloud_run_runtime_access" {
  project    = var.project_id
  location   = google_artifact_registry_repository.services.location
  repository = google_artifact_registry_repository.services.repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${local.serverless_robot_sa}"

  depends_on = [
    google_project_service.required["artifactregistry.googleapis.com"],
    google_project_service.required["run.googleapis.com"],
  ]
}

resource "google_artifact_registry_repository_iam_member" "build_service_account_repo_access" {
  project    = var.project_id
  location   = google_artifact_registry_repository.services.location
  repository = google_artifact_registry_repository.services.repository_id
  role       = "roles/artifactregistry.repoAdmin"
  member     = "serviceAccount:${google_service_account.build.email}"

  depends_on = [google_project_service.required["artifactregistry.googleapis.com"]]
}
