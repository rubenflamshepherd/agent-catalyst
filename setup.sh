#!/bin/bash
# ABOUTME: Main orchestrator script that runs all setup tasks in sequence.
# ABOUTME: Each task script is idempotent and can be re-run safely.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/.setup-config"

echo ""
echo -e "${BLUE}=== Agent Catalyst Setup ===${NC}"
echo ""

# Function to run a setup step
run_step() {
    local script=$1
    local description=$2

    echo ""
    echo -e "${BLUE}=== $description ===${NC}"

    if "$script"; then
        echo -e "${GREEN}✓ $description complete${NC}"
        return 0
    else
        echo -e "${RED}✗ $description failed${NC}"
        echo ""
        echo "Fix the issue and re-run: ./setup.sh"
        echo "Each script is idempotent and will skip completed steps."
        exit 1
    fi
}

# Load existing config if it exists
if [[ -f "$CONFIG_FILE" ]]; then
    echo -e "${YELLOW}Loading existing configuration...${NC}"
    source "$CONFIG_FILE"
fi

# Run setup steps in order
run_step "$SCRIPT_DIR/setup/verify-prerequisites.sh" "Prerequisites Verification"
run_step "$SCRIPT_DIR/setup/create-projects.sh" "GCP Project Creation"
run_step "$SCRIPT_DIR/setup/configure-terraform.sh" "Terraform Configuration"
run_step "$SCRIPT_DIR/setup/deploy-infrastructure.sh" "Infrastructure Deployment"
run_step "$SCRIPT_DIR/setup/setup-github-integration.sh" "GitHub Integration"
run_step "$SCRIPT_DIR/setup/verify-deployment.sh" "Deployment Verification"

echo ""
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "Your development and production environments are ready!"
echo ""
