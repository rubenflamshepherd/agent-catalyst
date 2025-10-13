#!/bin/bash
# ABOUTME: Verifies that all prerequisites are met before running setup.
# ABOUTME: Checks for gcloud authentication and application default credentials.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Verifying prerequisites..."
echo ""

ERRORS=0

# Check if gcloud is installed
echo -n "Checking gcloud CLI... "
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}✗${NC}"
    echo -e "${RED}Error: gcloud CLI is not installed in this container${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓${NC}"
fi

# Check if user is authenticated with gcloud
echo -n "Checking gcloud authentication... "
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo -e "${RED}✗${NC}"
    echo -e "${RED}Error: Not authenticated with gcloud${NC}"
    echo "Please run on your HOST machine: gcloud auth login"
    ERRORS=$((ERRORS + 1))
else
    ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)
    echo -e "${GREEN}✓${NC} ($ACCOUNT)"
fi

# Check for Application Default Credentials
echo -n "Checking Application Default Credentials... "
ADC_PATH="$HOME/.config/gcloud/application_default_credentials.json"
if [[ ! -f "$ADC_PATH" ]]; then
    echo -e "${YELLOW}⚠${NC}"
    echo -e "${YELLOW}Warning: Application Default Credentials not found${NC}"
    echo "This is needed for application code to access GCP APIs."
    echo "Please run on your HOST machine: gcloud auth application-default login"
    echo ""
    echo -e "${YELLOW}You can continue setup without this, but application code won't work.${NC}"
else
    echo -e "${GREEN}✓${NC}"
fi

# Test that we can list projects (proves auth + permissions)
echo -n "Testing GCP API access... "
if gcloud projects list --limit=1 &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo -e "${RED}Error: Cannot list GCP projects${NC}"
    echo "This might be a permissions issue."
    ERRORS=$((ERRORS + 1))
fi

echo ""

if [[ $ERRORS -gt 0 ]]; then
    echo -e "${RED}Prerequisites check failed with $ERRORS error(s).${NC}"
    echo ""
    echo "Please see PREREQUISITES.md for setup instructions."
    exit 1
else
    echo -e "${GREEN}All prerequisites verified!${NC}"
    exit 0
fi
