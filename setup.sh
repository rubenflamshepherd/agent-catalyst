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

# Available steps (in order)
declare -A STEPS
STEPS=(
    ["prerequisites"]="$SCRIPT_DIR/setup/verify-prerequisites.sh|Prerequisites Verification"
    ["create-projects"]="$SCRIPT_DIR/setup/create-projects.sh|GCP Project Creation"
    ["configure-terraform"]="$SCRIPT_DIR/setup/configure-terraform.sh|Terraform Configuration"
    ["deploy-infrastructure"]="$SCRIPT_DIR/setup/deploy-infrastructure.sh|Infrastructure Deployment"
    ["setup-github"]="$SCRIPT_DIR/setup/setup-github-integration.sh|GitHub Integration"
    ["verify-deployment"]="$SCRIPT_DIR/setup/verify-deployment.sh|Deployment Verification"
)

# Step execution order
STEP_ORDER=(
    "prerequisites"
    "create-projects"
    "configure-terraform"
    "deploy-infrastructure"
    "setup-github"
    "verify-deployment"
)

show_usage() {
    echo "Usage: ./setup.sh [STEP]"
    echo ""
    echo "Run all setup steps, or a specific step."
    echo ""
    echo "Available steps:"
    for step in "${STEP_ORDER[@]}"; do
        IFS='|' read -r script description <<< "${STEPS[$step]}"
        echo "  $step"
        echo "    $description"
    done
    echo ""
    echo "Examples:"
    echo "  ./setup.sh                    # Run all steps"
    echo "  ./setup.sh prerequisites      # Run only prerequisites check"
    echo "  ./setup.sh create-projects    # Run only project creation"
}

# Parse arguments
SPECIFIC_STEP=""
if [[ $# -gt 0 ]]; then
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        show_usage
        exit 0
    fi

    SPECIFIC_STEP="$1"

    if [[ ! -v "STEPS[$SPECIFIC_STEP]" ]]; then
        echo -e "${RED}Error: Unknown step '$SPECIFIC_STEP'${NC}"
        echo ""
        show_usage
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}===                           _      _____      _        _           _      _____      _                ==="
echo -e "${BLUE}===     /\                   | |    / ____|    | |      | |         | |    / ____|    | |               ==="
echo -e "${BLUE}===    /  \   __ _  ___ _ __ | |_  | |     __ _| |_ __ _| |_   _ ___| |_  | (___   ___| |_ _   _ _ __   ==="
echo -e "${BLUE}===   / /\ \ / _  |/ _ \ '_ \| __| | |    / _  | __/ _  | | | | / __| __|  \___ \ / _ \ __| | | | '_ \  ==="
echo -e "${BLUE}===  / ____ \ (_| |  __/ | | | |_  | |___| (_| | || (_| | | |_| \__ \ |_   ____) |  __/ |_| |_| | |_) | ==="
echo -e "${BLUE}=== /_/    \_\__, |\___|_| |_|\__|  \_____\__,_|\__\__,_|_|\__, |___/\__| |_____/ \___|\__|\__,_| .__/  ==="
echo -e "${BLUE}===           __/ |                                         __/ |                               | |     ==="
echo -e "${BLUE}===          |___/                                         |___/                                |_|     ==="
echo ""

# Function to run a setup step
run_step() {
    local script=$1
    local description=$2

    echo ""
    echo -e "${BLUE}=== $description ===${NC}"
    echo ""

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

# Run steps
if [[ -n "$SPECIFIC_STEP" ]]; then
    # Run only the specified step
    IFS='|' read -r script description <<< "${STEPS[$SPECIFIC_STEP]}"
    run_step "$script" "$description"
    echo ""
    echo -e "${GREEN}✓ Step '$SPECIFIC_STEP' complete${NC}"
    echo ""
else
    # Run all steps in order
    for step in "${STEP_ORDER[@]}"; do
        IFS='|' read -r script description <<< "${STEPS[$step]}"
        run_step "$script" "$description"
    done

    echo ""
    echo -e "${GREEN}=== Setup Complete ===${NC}"
    echo ""
    echo "Your development and production environments are ready!"
    echo ""
fi
