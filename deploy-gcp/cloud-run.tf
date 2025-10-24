// ABOUTME: Provisions the Cloud Run service for hosting the application.
// ABOUTME: Configures container specs, scaling, and public access permissions.

resource "google_cloud_run_service" "app" {
  name     = var.app_name
  location = local.region

  template {
    spec {
      service_account_name = google_service_account.run.email

      containers {
        image = local.cloud_run_placeholder_image

        env {
          name  = "ENVIRONMENT"
          value = "prod :)"
        }

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
