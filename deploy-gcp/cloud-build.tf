// ABOUTME: Configures Cloud Build triggers for CI/CD pipelines.
// ABOUTME: Includes triggers for PR validation and main branch deployments.

resource "google_cloudbuild_trigger" "pr_validation" {
  name = "${local.app_slug}-pr-validate"

  description     = "Validate pull requests targeting main for ${var.app_name}"
  filename        = "deploy-gcp/cloudbuild-flask-build.yaml"
  location        = "global"
  service_account = "projects/${var.project_id}/serviceAccounts/${google_service_account.build.email}"

  github {
    owner = var.github_owner
    name  = var.github_repo

    pull_request {
      branch = "^main$"
    }
  }

  substitutions = {
    "_APP_NAME"      = var.app_name
    "_GITHUB_OWNER"  = var.github_owner
    "_GITHUB_REPO"   = var.github_repo
  }

  depends_on = [google_project_service.required["cloudbuild.googleapis.com"]]
}

resource "google_cloudbuild_trigger" "deploy_main" {
  name            = "${local.app_slug}-deploy"
  description     = "Build and deploy ${var.app_name} on pushes to main"
  filename        = "deploy-gcp/cloudbuild-flask.yaml"
  location        = "global"
  service_account = "projects/${var.project_id}/serviceAccounts/${google_service_account.build.email}"

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
    "_APP_NAME"              = var.app_name
    "_GITHUB_OWNER"          = var.github_owner
    "_GITHUB_REPO"           = var.github_repo
  }

  depends_on = [google_project_service.required["cloudbuild.googleapis.com"]]
}
