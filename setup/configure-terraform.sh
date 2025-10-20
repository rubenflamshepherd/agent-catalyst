#!/bin/bash
# ABOUTME: Configures Terraform backend and generates variable files.
# ABOUTME: Sets up terraform state management and project-specific variables.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../.setup-config"

echo "=== Terraform Configuration ==="
echo ""

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}Error: Configuration file not found${NC}"
    echo "Run ./setup.sh to generate configuration"
    exit 1
fi

source "$CONFIG_FILE"

# Verify prerequisites
echo "✓ Prerequisites verified"
echo ""

# Verify GCP project exists
echo "Verifying GCP project exists..."
if ! gcloud projects describe "$PROD_PROJECT" &> /dev/null; then
    echo -e "${RED}Error: Project '$PROD_PROJECT' does not exist${NC}"
    echo "Run ./setup.sh to create the project"
    exit 1
fi
echo "✓ GCP project verified: $PROD_PROJECT"
echo ""

# Check and link billing account
echo "Checking billing account..."
CURRENT_BILLING=$(gcloud billing projects describe "$PROD_PROJECT" --format="value(billingAccountName)" 2>/dev/null || true)

if [[ -n "$CURRENT_BILLING" ]]; then
    echo "✓ Billing already enabled: $CURRENT_BILLING"
else
    echo "Billing not enabled, linking billing account..."

    # Get list of open billing accounts
    BILLING_ACCOUNTS=$(gcloud billing accounts list --filter="open=true" --format="value(name)")

    if [[ -z "$BILLING_ACCOUNTS" ]]; then
        echo -e "${RED}Error: No active billing accounts found${NC}"
        echo ""
        echo "You need a billing account to enable GCP services."
        echo ""
        echo "To create a billing account:"
        echo "  1. Go to: https://console.cloud.google.com/billing"
        echo "  2. Create or activate a billing account"
        echo "  3. Run this script again"
        exit 1
    fi

    # Use the first open billing account
    BILLING_ACCOUNT_ID=$(echo "$BILLING_ACCOUNTS" | head -n 1)

    echo "Linking billing account: $BILLING_ACCOUNT_ID"
    if gcloud billing projects link "$PROD_PROJECT" --billing-account="$BILLING_ACCOUNT_ID" &> /dev/null; then
        echo "✓ Billing account linked"
    else
        echo -e "${RED}Error: Failed to link billing account${NC}"
        exit 1
    fi
fi
echo ""

# Enable required GCP APIs
echo "Enabling required GCP APIs..."
API_ERROR=$(mktemp)
if gcloud services enable \
    compute.googleapis.com \
    cloudresourcemanager.googleapis.com \
    storage-api.googleapis.com \
    --project="$PROD_PROJECT" 2>&1 | tee "$API_ERROR"; then
    echo "✓ GCP APIs enabled"
else
    echo -e "${RED}Error: Failed to enable GCP APIs${NC}"
    echo ""
    if grep -q "Billing account" "$API_ERROR" || grep -q "billing" "$API_ERROR"; then
        echo -e "${YELLOW}This project requires billing to be enabled.${NC}"
        echo ""
        echo "To enable billing:"
        echo "  1. Go to: https://console.cloud.google.com/billing/linkedaccount?project=$PROD_PROJECT"
        echo "  2. Link a billing account to this project"
        echo "  3. Run this script again"
    fi
    rm -f "$API_ERROR"
    exit 1
fi
rm -f "$API_ERROR"
echo ""

# Configure state bucket
BUCKET_NAME="${PROD_PROJECT}-terraform-state"
STATE_PREFIX="${APP_NAME}/terraform/state"

echo "Configuring Terraform state bucket..."
if gsutil ls -b "gs://${BUCKET_NAME}" &> /dev/null; then
    echo "✓ State bucket already exists: $BUCKET_NAME"
else
    echo "Creating state bucket..."
    if gsutil mb -p "$PROD_PROJECT" -l us-central1 "gs://${BUCKET_NAME}" &> /dev/null; then
        echo "✓ State bucket created: $BUCKET_NAME"

        # Enable versioning
        if gsutil versioning set on "gs://${BUCKET_NAME}" &> /dev/null; then
            echo "✓ Versioning enabled"
        else
            echo -e "${YELLOW}Warning: Failed to enable versioning${NC}"
        fi
    else
        echo -e "${RED}Error: Failed to create state bucket${NC}"
        exit 1
    fi
fi
echo ""

# Generate backend.tf
DEPLOY_DIR="$SCRIPT_DIR/../deploy-gcp"
BACKEND_FILE="$DEPLOY_DIR/backend.tf"

echo "Generating backend configuration..."
cat > "$BACKEND_FILE" << EOF
terraform {
  backend "gcs" {
    bucket = "${BUCKET_NAME}"
    prefix = "${STATE_PREFIX}"
  }
}
EOF
echo "✓ Backend configuration generated"
echo ""

# Generate terraform.tfvars
TFVARS_FILE="$DEPLOY_DIR/terraform.tfvars"

echo "Detecting GitHub repository..."
REPO_ROOT="$SCRIPT_DIR/.."
REMOTE_URL=$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || true)

if [[ -z "$REMOTE_URL" ]]; then
    echo -e "${RED}Error: Unable to determine git remote URL${NC}"
    echo "Ensure the repository has a configured remote named 'origin'."
    exit 1
fi

GITHUB_OWNER=""
GITHUB_REPO=""

if [[ "$REMOTE_URL" =~ ^git@github\.com:([^/]+)/([^/]+)(\.git)?$ ]]; then
    GITHUB_OWNER="${BASH_REMATCH[1]}"
    GITHUB_REPO="${BASH_REMATCH[2]}"
elif [[ "$REMOTE_URL" =~ ^https://github\.com/([^/]+)/([^/]+)(\.git)?$ ]]; then
    GITHUB_OWNER="${BASH_REMATCH[1]}"
    GITHUB_REPO="${BASH_REMATCH[2]}"
else
    echo -e "${RED}Error: Unsupported GitHub remote URL format${NC}"
    echo "Remote URL detected: $REMOTE_URL"
    echo "Expected formats:"
    echo "  git@github.com:owner/repo.git"
    echo "  https://github.com/owner/repo.git"
    exit 1
fi

GITHUB_REPO="${GITHUB_REPO%.git}"

if [[ -z "$GITHUB_OWNER" ]] || [[ -z "$GITHUB_REPO" ]]; then
    echo -e "${RED}Error: Failed to parse GitHub owner or repository${NC}"
    exit 1
fi

echo "✓ GitHub repository detected: $GITHUB_OWNER/$GITHUB_REPO"
echo ""

echo "Generating variables file..."
cat > "$TFVARS_FILE" << EOF
// ABOUTME: Stores Terraform variables for Cloud Run deployment pipeline.
// ABOUTME: Generated by setup scripts from local project configuration.
project_id = "$PROD_PROJECT"
app_name   = "$APP_NAME"
github_owner = "$GITHUB_OWNER"
github_repo  = "$GITHUB_REPO"
EOF
echo "✓ Variables file generated"
echo ""

# Update main.tf to add variables and use var.project_id
MAIN_TF="$DEPLOY_DIR/main.tf"

echo "Updating main.tf with variables..."

# Check if variables already exist
if grep -q "variable \"project_id\"" "$MAIN_TF"; then
    echo "✓ Variables already defined in main.tf"
else
    # Add variable declarations after the terraform block
    sed -i '/^provider "google" {/i\
variable "project_id" {\
  description = "GCP project ID"\
  type        = string\
}\
\
variable "app_name" {\
  description = "Application name"\
  type        = string\
}\
' "$MAIN_TF"
    echo "✓ Variable declarations added"
fi

# Replace <PROJECT_ID> with var.project_id
if grep -q "<PROJECT_ID>" "$MAIN_TF"; then
    sed -i 's/project = "<PROJECT_ID>"/project = var.project_id/' "$MAIN_TF"
    echo "✓ Updated provider to use var.project_id"
else
    echo "✓ Provider already using var.project_id"
fi
echo ""

# Run terraform init
echo "Initializing Terraform..."
cd "$DEPLOY_DIR"
if terraform init &> /dev/null; then
    echo "✓ Terraform initialized"
else
    echo -e "${RED}Error: Terraform init failed${NC}"
    exit 1
fi
echo ""

# Run terraform validate
echo "Validating configuration..."
if terraform validate &> /dev/null; then
    echo "✓ Configuration validated"
else
    echo -e "${RED}Error: Terraform validate failed${NC}"
    terraform validate
    exit 1
fi
echo ""

# Run terraform plan
echo "Running terraform plan..."
if terraform plan &> /dev/null; then
    echo "✓ Terraform plan succeeded"
else
    echo -e "${RED}Error: Terraform plan failed${NC}"
    terraform plan
    exit 1
fi
echo ""

echo -e "${GREEN}=== Terraform Configuration Complete ===${NC}"
echo ""
echo "Configuration summary:"
echo "  ✓ Billing account linked"
echo "  ✓ GCP APIs enabled"
echo "  ✓ State bucket: $BUCKET_NAME"
echo "  ✓ Backend configured"
echo "  ✓ Terraform initialized and validated"
echo ""
echo "Terraform is ready to use!"
echo ""
echo "Next steps:"
echo "  cd deploy-gcp"
echo "  terraform plan    # Review planned changes"
echo "  terraform apply   # Apply infrastructure changes"
