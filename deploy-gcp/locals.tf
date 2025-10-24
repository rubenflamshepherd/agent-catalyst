// ABOUTME: Defines local values computed from variables and data sources.
// ABOUTME: Includes service account names, repository paths, and regional settings.

locals {
  region                          = "us-central1"
  app_slug_candidate              = trim(join("-", regexall("[a-z0-9]+", lower(var.app_name))), "-")
  app_slug                        = length(local.app_slug_candidate) > 0 ? local.app_slug_candidate : "app"
  artifact_repo                   = "${local.app_slug}-services"
  run_service_account_base        = "${local.app_slug}-run-sa"
  run_service_account_candidate   = trim(join("-", regexall("[a-z0-9]+", local.run_service_account_base)), "-")
  run_service_account_value       = length(local.run_service_account_candidate) > 0 ? local.run_service_account_candidate : "run-sa"
  run_service_account             = trim(substr(local.run_service_account_value, 0, 30), "-")
  build_service_account_base      = "${local.app_slug}-build-sa"
  build_service_account_candidate = trim(join("-", regexall("[a-z0-9]+", local.build_service_account_base)), "-")
  build_service_account_value     = length(local.build_service_account_candidate) > 0 ? local.build_service_account_candidate : "build-sa"
  build_service_account           = trim(substr(local.build_service_account_value, 0, 30), "-")
  cloud_build_account             = "${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
  serverless_robot_sa             = "service-${data.google_project.project.number}@serverless-robot-prod.iam.gserviceaccount.com"
  artifact_repo_path              = "us-central1-docker.pkg.dev/${var.project_id}/${local.artifact_repo}"
  cloud_run_placeholder_image     = "gcr.io/cloudrun/hello"
}
