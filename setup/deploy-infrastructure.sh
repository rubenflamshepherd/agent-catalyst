#!/bin/bash
# ABOUTME: Deploys infrastructure using Terraform.
# ABOUTME: Provisions all GCP resources needed for the application.

set -e
set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../.setup-config"

echo "=== Infrastructure Deployment ==="
echo ""

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}Error: Configuration file not found${NC}"
    echo "Run ./setup.sh to generate configuration"
    exit 1
fi

source "$CONFIG_FILE"

# Validate required variables
if [[ -z "$PROD_PROJECT" ]] || [[ -z "$APP_NAME" ]]; then
    echo -e "${RED}Error: Missing configuration values in .setup-config${NC}"
    echo "Ensure create-projects and configure-terraform steps completed successfully."
    exit 1
fi

# Ensure terraform CLI is available
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: terraform CLI not found${NC}"
    echo "Run ./setup/verify-prerequisites.sh to install required tools."
    exit 1
fi

DEPLOY_DIR="$SCRIPT_DIR/../deploy-gcp"
TFVARS_FILE="$DEPLOY_DIR/terraform.tfvars"

# Confirm terraform directory exists
if [[ ! -d "$DEPLOY_DIR" ]]; then
    echo -e "${RED}Error: Terraform configuration directory not found: $DEPLOY_DIR${NC}"
    echo "Run ./setup/configure-terraform.sh and retry."
    exit 1
fi

# Confirm terraform.tfvars exists and matches expected project
if [[ ! -f "$TFVARS_FILE" ]]; then
    echo -e "${RED}Error: terraform.tfvars not found at $TFVARS_FILE${NC}"
    echo "Run ./setup/configure-terraform.sh to generate required files."
    exit 1
fi

if ! grep -q "project_id = \"$PROD_PROJECT\"" "$TFVARS_FILE"; then
    echo -e "${RED}Error: terraform.tfvars project_id does not match configured project${NC}"
    echo "Expected project_id \"$PROD_PROJECT\"."
    echo "Run ./setup/configure-terraform.sh to regenerate Terraform configuration."
    exit 1
fi

echo "✓ Configuration verified"
echo ""

export TF_IN_AUTOMATION=1

run_terraform() {
    local action=$1
    shift

    terraform -chdir="$DEPLOY_DIR" "$action" "$@"
}

echo "Running terraform init..."
INIT_LOG=$(mktemp)
if run_terraform init -input=false &> "$INIT_LOG"; then
    echo "✓ Terraform initialized"
else
    echo -e "${RED}Error: terraform init failed${NC}"
    cat "$INIT_LOG"
    rm -f "$INIT_LOG"
    exit 1
fi
rm -f "$INIT_LOG"
echo ""

echo "Running terraform plan..."
PLAN_LOG=$(mktemp)
if run_terraform plan -input=false -var-file=terraform.tfvars | tee "$PLAN_LOG"; then
    echo "✓ Plan completed"
else
    echo -e "${RED}Error: terraform plan failed${NC}"
    echo ""
    cat "$PLAN_LOG"
    rm -f "$PLAN_LOG"
    exit 1
fi
rm -f "$PLAN_LOG"
echo ""

echo "Applying infrastructure changes..."
APPLY_LOG=$(mktemp)
if run_terraform apply -input=false -auto-approve -var-file=terraform.tfvars | tee "$APPLY_LOG"; then
    echo "✓ Infrastructure deployed"
else
    echo -e "${RED}Error: terraform apply failed${NC}"
    echo ""
    cat "$APPLY_LOG"
    echo ""
    echo "Investigate the issue above. Partial resources may exist."
    rm -f "$APPLY_LOG"
    exit 1
fi
rm -f "$APPLY_LOG"
echo ""

echo "Retrieving terraform outputs (if any)..."
if ! run_terraform output; then
    echo -e "${YELLOW}Warning: Unable to retrieve terraform outputs (none defined or command failed)${NC}"
fi
echo ""

echo -e "${GREEN}✓ Infrastructure deployment complete${NC}"
echo ""
echo "Next steps:"
echo "  - Inspect deployed resources in project: $PROD_PROJECT"
echo "  - Re-run ./setup.sh deploy-infrastructure to reconcile future changes"
