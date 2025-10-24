# ABOUTME: Creates terraform.tfvars inside the Cloud Build workspace.
# ABOUTME: Derives missing values from build metadata to support templated forks.
#!/usr/bin/env bash

set -euo pipefail

PROJECT_ID="${1:-}"
APP_NAME="${2:-}"
GITHUB_OWNER="${3:-}"
GITHUB_REPO="${4:-}"
REGION="${5:-}"
REPO_FULL_NAME="${6:-}"
HEAD_REPO_URL="${7:-}"
REPO_NAME="${8:-}"

if [[ -z "${PROJECT_ID}" ]]; then
  echo "PROJECT_ID is required to write terraform.tfvars" >&2
  exit 1
fi

if [[ -z "${APP_NAME}" ]]; then
  if [[ -n "${REGION}" ]]; then
    search_region="${REGION}"
  else
    search_region="us-central1"
  fi

  APP_NAME="$(gcloud run services list --platform=managed --region="${search_region}" --format='value(metadata.name)' --limit=1)"
fi

if [[ -z "${APP_NAME}" ]]; then
  echo "Unable to determine app_name for terraform.tfvars" >&2
  exit 1
fi

default_owner=""
default_repo=""

if [[ -n "${REPO_FULL_NAME}" ]]; then
  default_owner="${REPO_FULL_NAME%%/*}"
  default_repo="${REPO_FULL_NAME##*/}"
fi

if [[ -z "${default_owner}" || -z "${default_repo}" ]]; then
  if [[ -n "${HEAD_REPO_URL}" ]]; then
    head_path="${HEAD_REPO_URL#https://github.com/}"
    if [[ -z "${default_owner}" ]]; then
      default_owner="${head_path%%/*}"
    fi
    if [[ -z "${default_repo}" ]]; then
      default_repo="${head_path##*/}"
    fi
  fi
fi

if [[ -z "${default_repo}" && -n "${REPO_NAME}" ]]; then
  default_repo="${REPO_NAME}"
fi

if [[ -z "${GITHUB_OWNER}" ]]; then
  GITHUB_OWNER="${default_owner}"
fi

if [[ -z "${GITHUB_REPO}" ]]; then
  GITHUB_REPO="${default_repo}"
fi

if [[ -z "${GITHUB_OWNER}" || -z "${GITHUB_REPO}" ]]; then
  echo "Unable to determine GitHub owner/repo for terraform.tfvars" >&2
  exit 1
fi

cat <<EOF > deploy-gcp/terraform.tfvars
project_id   = "${PROJECT_ID}"
app_name     = "${APP_NAME}"
github_owner = "${GITHUB_OWNER}"
github_repo  = "${GITHUB_REPO}"
EOF
