#!/bin/bash
# ABOUTME: Creates unique GCP projects for dev and prod environments.
# ABOUTME: Prompts for app name and generates project IDs with random suffixes.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== GCP Project Creation ==="
echo ""

# Prompt for app name
read -p "Enter app name: " APP_NAME

# Validate input
if [[ -z "$APP_NAME" ]]; then
    echo -e "${RED}Error: App name cannot be empty${NC}"
    exit 1
fi

# Convert to lowercase and replace spaces/underscores with hyphens
APP_NAME=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr '_' '-' | tr -s '-')

# Remove leading/trailing hyphens
APP_NAME=$(echo "$APP_NAME" | sed 's/^-*//;s/-*$//')

# Validate app name format
if [[ ! "$APP_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
    echo -e "${RED}Error: App name must start with a letter and contain only lowercase letters, numbers, and hyphens${NC}"
    exit 1
fi

# Generate random 6-character hex suffix
SUFFIX=$(openssl rand -hex 3)

# Create project IDs
PROD_PROJECT="${APP_NAME}-prod-${SUFFIX}"

# Validate project ID lengths

if [[ ${#PROD_PROJECT} -lt 6 ]] || [[ ${#PROD_PROJECT} -gt 30 ]]; then
    echo -e "${RED}Error: Generated prod project ID length (${#PROD_PROJECT}) is not between 6-30 characters${NC}"
    exit 1
fi

echo ""
echo "Generated project IDs:"
echo -e "  ${GREEN}Prod:${NC} $PROD_PROJECT"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI is not installed${NC}"
    echo "Install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo -e "${YELLOW}Warning: Not authenticated with gcloud${NC}"
    echo "Run: gcloud auth login"
    exit 1
fi

# Confirm before creating
read -p "Create these projects now? (y/n): " CREATE

if [[ "$CREATE" != "y" ]]; then
    echo "Project creation cancelled."
    echo ""
    echo "To create these projects later, run:"
    echo "  gcloud projects create $PROD_PROJECT --name=\"$APP_NAME Production\""
    exit 0
fi

echo ""
echo "Creating projects..."

# Create prod project
echo -e "${YELLOW}Creating prod project...${NC}"
if gcloud projects create "$PROD_PROJECT" --name="$APP_NAME Production" --quiet; then
    echo -e "${GREEN}✓ Prod project created: $PROD_PROJECT${NC}"
else
    echo -e "${RED}✗ Failed to create prod project${NC}"
    echo -e "${YELLOW}Note: Dev project was created successfully${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=== Success ===${NC}"
echo ""
echo "Next steps:"
echo "  1. Set default project: gcloud config set project $DEV_PROJECT"
echo "  2. Enable billing: https://console.cloud.google.com/billing/linkedaccount?project=$DEV_PROJECT"
echo "  3. Enable required APIs for your projects"
echo ""
echo "Project IDs have been saved for reference:"
echo "  Prod: $PROD_PROJECT"
