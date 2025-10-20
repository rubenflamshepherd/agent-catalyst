#!/bin/bash
# ABOUTME: Creates unique GCP projects for dev and prod environments.
# ABOUTME: Prompts for app name and generates project IDs with random suffixes.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../.setup-config"

# Check for existing configuration
OLD_APP_NAME=""
OLD_PROD_PROJECT=""
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    OLD_APP_NAME="$APP_NAME"
    OLD_PROD_PROJECT="$PROD_PROJECT"
fi

echo "=== Create Project ==="
echo ""

# Prompt for app name with detection of existing configuration
if [[ -n "$OLD_APP_NAME" ]]; then
    echo "Existing app name detected: $OLD_APP_NAME"
    read -p "Press 'y' to continue with this app name, or any other key to enter a new one: " CONTINUE

    if [[ "$CONTINUE" == "y" ]]; then
        APP_NAME="$OLD_APP_NAME"
    else
        read -p "Enter new app name (leave blank for default: agent-catalyst): " APP_NAME

        # Use default if empty
        if [[ -z "$APP_NAME" ]]; then
            APP_NAME="agent-catalyst"
        fi
    fi
else
    read -p "Enter app name (leave blank for default: agent-catalyst): " APP_NAME

    # Use default if empty
    if [[ -z "$APP_NAME" ]]; then
        APP_NAME="agent-catalyst"
    fi
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

# Validate app name length
# Project ID format: {app-name}-{8-char-suffix} = app-name + 8 chars
# GCP requires project IDs to be 6-30 characters
# So app name must be at least 1 char and at most 15 chars (30 - 8 - 1)
APP_NAME_LENGTH=${#APP_NAME}
if [[ $APP_NAME_LENGTH -lt 1 ]] || [[ $APP_NAME_LENGTH -gt 21 ]]; then
    echo -e "${RED}Error: App name length ($APP_NAME_LENGTH) must be between 1-15 characters${NC}"
    echo -e "${RED}(Project ID will be: ${APP_NAME}xxxxxxxx, which must be 6-30 characters)${NC}"
    exit 1
fi

# Check if app name changed - if so, generate new suffix and warn about old project
if [[ -n "$OLD_APP_NAME" ]] && [[ "$APP_NAME" != "$OLD_APP_NAME" ]]; then
    echo ""
    echo -e "${YELLOW}Warning: App name changed from '$OLD_APP_NAME' to '$APP_NAME'${NC}"

    # Check if old project exists in GCP
    if [[ -n "$OLD_PROD_PROJECT" ]] && gcloud projects describe "$OLD_PROD_PROJECT" &> /dev/null; then
        echo -e "${YELLOW}Warning: Previous project '$OLD_PROD_PROJECT' still exists in GCP${NC}"
        echo -e "${YELLOW}You may want to delete it to avoid confusion and billing charges:${NC}"
        echo -e "  gcloud projects delete $OLD_PROD_PROJECT"
    fi

    echo ""
    # Generate new suffix for new app name
    SUFFIX=$(openssl rand -hex 4)
else
    # Generate or reuse random 8-character hex suffix
    if [[ -z "$SUFFIX" ]]; then
        SUFFIX=$(openssl rand -hex 4)
    fi
fi

# Create project IDs
PROD_PROJECT="${APP_NAME}-${SUFFIX}"

# Validate project ID lengths

if [[ ${#PROD_PROJECT} -lt 6 ]] || [[ ${#PROD_PROJECT} -gt 30 ]]; then
    echo -e "${RED}Error: Generated prod project ID length (${#PROD_PROJECT}) is not between 6-30 characters${NC}"
    exit 1
fi

echo ""
echo -e "Generated project ID: ${GREEN}$PROD_PROJECT${NC}"
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

# Check if project already exists (idempotency)
echo "Checking if project exists in GCP..."
if gcloud projects describe "$PROD_PROJECT" &> /dev/null; then
    echo -e "${GREEN}✓ Project already exists${NC}"
else
    echo "Project does not exist"
    echo ""

    # Confirm before creating
    read -p "Create this project now? (y/n): " CREATE

    if [[ "$CREATE" != "y" ]]; then
        echo ""
        echo "Project creation cancelled."
        echo ""
        echo "To create this project later, run:"
        echo "  gcloud projects create $PROD_PROJECT --name=\"$APP_NAME\""
        exit 0
    fi

    echo ""
    echo "Creating project in GCP..."
    echo ""

    # Create prod project
    if gcloud projects create "$PROD_PROJECT" --name="$APP_NAME" --quiet; then
        echo ""
        echo -e "${GREEN}✓ Project created successfully${NC}"
    else
        echo ""
        echo -e "${RED}✗ Failed to create project${NC}"
        exit 1
    fi
fi

echo ""

# Save configuration for other scripts
cat > "$CONFIG_FILE" << EOF
# Auto-generated configuration from setup process
export APP_NAME="$APP_NAME"
export SUFFIX="$SUFFIX"
export PROD_PROJECT="$PROD_PROJECT"
EOF

echo -e "${GREEN}✓ Configuration saved${NC}"
