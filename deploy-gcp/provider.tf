// ABOUTME: Configures the Terraform provider and required provider versions.
// ABOUTME: Sets up the Google Cloud provider with project and region configuration.

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = local.region
  zone    = "${local.region}-c"
}

data "google_project" "project" {
  project_id = var.project_id
}
