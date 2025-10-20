// ABOUTME: Provisions infrastructure for deploying the Flask app to Cloud Run.
// ABOUTME: Manages registry, service accounts, IAM, Cloud Run, and Cloud Build triggers.

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "github_owner" {
  description = "GitHub organization or user that owns the repository"
  type        = string

  validation {
    condition     = length(trimspace(var.github_owner)) > 0
    error_message = "github_owner must be a non-empty string."
  }
}

variable "github_repo" {
  description = "GitHub repository name connected to Cloud Build"
  type        = string

  validation {
    condition     = length(trimspace(var.github_repo)) > 0
    error_message = "github_repo must be a non-empty string."
  }
}

locals {
  region                        = "us-central1"
  app_slug_candidate            = trim(join("-", regexall("[a-z0-9]+", lower(var.app_name))), "-")
  app_slug                      = length(local.app_slug_candidate) > 0 ? local.app_slug_candidate : "app"
  artifact_repo                 = "${local.app_slug}-services"
  run_service_account_base      = "${local.app_slug}-run-sa"
  run_service_account_candidate = trim(join("-", regexall("[a-z0-9]+", local.run_service_account_base)), "-")
  run_service_account_value     = length(local.run_service_account_candidate) > 0 ? local.run_service_account_candidate : "run-sa"
  run_service_account           = trim(substr(local.run_service_account_value, 0, 30), "-")
  cloud_build_account           = "${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
  serverless_robot_sa           = "service-${data.google_project.project.number}@serverless-robot-prod.iam.gserviceaccount.com"
  artifact_repo_path            = "us-central1-docker.pkg.dev/${var.project_id}/${local.artifact_repo}"
  cloud_run_placeholder_image   = "gcr.io/cloudrun/hello"
}

provider "google" {
  project = var.project_id
  region  = local.region
  zone    = "${local.region}-c"
}

data "google_project" "project" {
  project_id = var.project_id
}

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

resource "google_service_account" "run" {
  project      = var.project_id
  account_id   = local.run_service_account
  display_name = "${var.app_name} Cloud Run runtime service account"
}

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

resource "google_cloud_run_service" "app" {
  name     = var.app_name
  location = local.region

  template {
    spec {
      service_account_name = google_service_account.run.email

      containers {
        image = local.cloud_run_placeholder_image

        ports {
          container_port = 8080
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }
      }

      container_concurrency = 80
      timeout_seconds       = 300
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

  lifecycle {
    ignore_changes = [
      template[0].spec[0].containers[0].image,
    ]
  }

  depends_on = [
    google_project_service.required["run.googleapis.com"],
    google_project_service.required["artifactregistry.googleapis.com"],
  ]
}

resource "google_cloud_run_service_iam_member" "public_invoker" {
  location = google_cloud_run_service.app.location
  project  = var.project_id
  service  = google_cloud_run_service.app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloudbuild_trigger" "pr_validation" {
  name = "${local.app_slug}-pr-validate"

  description     = "Validate pull requests targeting main for ${var.app_name}"
  filename        = "deploy-gcp/cloudbuild-flask-build.yaml"
  location        = "global"
  service_account = "projects/${var.project_id}/serviceAccounts/${local.cloud_build_account}"

  github {
    owner = var.github_owner
    name  = var.github_repo

    pull_request {
      branch = "^main$"
    }
  }

  depends_on = [google_project_service.required["cloudbuild.googleapis.com"]]
}

resource "google_cloudbuild_trigger" "deploy_main" {
  name            = "${local.app_slug}-deploy"
  description     = "Build and deploy ${var.app_name} on pushes to main"
  filename        = "deploy-gcp/cloudbuild-flask.yaml"
  location        = "global"
  service_account = "projects/${var.project_id}/serviceAccounts/${local.cloud_build_account}"

  github {
    owner = var.github_owner
    name  = var.github_repo

    push {
      branch = "^main$"
    }
  }

  substitutions = {
    "_SERVICE_NAME"          = var.app_name
    "_REGION"                = local.region
    "_ARTIFACT_REPO"         = local.artifact_repo
    "_SERVICE_ACCOUNT_EMAIL" = google_service_account.run.email
  }

  depends_on = [google_project_service.required["cloudbuild.googleapis.com"]]
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
