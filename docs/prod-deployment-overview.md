# Production Deployment Overview

## Pipeline Summary
- `./setup.sh` orchestrates prerequisites, project creation, Terraform configuration, infrastructure deployment, and GitHub integration; each step script halts on missing prerequisites and describes manual follow-ups (`setup/configure-terraform.sh`, `setup/deploy-infrastructure.sh`, `setup/setup-github-integration.sh`).
- Terraform persists state in a dedicated GCS bucket with object versioning (`deploy-gcp/backend.tf`) and consumes `deploy-gcp/terraform.tfvars`, which the setup process generates from `.setup-config`.
- `deploy-gcp/main.tf` enables required services, provisions the Artifact Registry repository, Cloud Run service, dedicated runtime and build service accounts, and IAM bindings while ignoring container image drift so Cloud Build revisions stay authoritative.
- Cloud Build triggers wire GitHub pull requests and pushes to `main`; the deploy pipeline builds the Flask image, pushes `$SHORT_SHA` and `latest` tags, then deploys the SHA-tagged image to Cloud Run using trigger substitutions (`deploy-gcp/cloudbuild-flask.yaml`, `deploy-gcp/cloudbuild-flask-build.yaml`).
- The container image runs Gunicorn when `ENVIRONMENT=prod` (applied via Terraform on Cloud Run) and the Flask development server otherwise (`app/Dockerfile`, `app/entrypoint.sh`).
- Terraform outputs expose the Cloud Run URL and Artifact Registry repository path after `terraform apply`, and `google_cloud_run_service_iam_member` grants `roles/run.invoker` to `allUsers` for public access (`deploy-gcp/outputs.tf`, `deploy-gcp/main.tf`).

## Known Gaps
- The pull request trigger is a smoke build only; it does not run tests or linting before reporting success.
- `setup/verify-deployment.sh` remains a stub, so post-deploy smoke checks rely on manual validation.
- Terraform trigger creation fails until the Cloud Build GitHub App connection is established in the GCP console; rerunning the deployment script after connecting resolves it.
