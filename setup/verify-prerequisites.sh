#!/bin/bash
# ABOUTME: Verifies that all prerequisites are met before running setup.
# ABOUTME: Checks for CLI tools (gcloud, terraform, gh) and authentication.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Check if terraform is installed
echo -n "Checking Terraform CLI... "
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}✗${NC}"
    echo -e "${RED}Error: Terraform is not installed in this container${NC}"
    ERRORS=$((ERRORS + 1))
else
    TERRAFORM_VERSION=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    echo -e "${GREEN}✓${NC} ($TERRAFORM_VERSION)"
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

# Check if gh CLI is installed
echo -n "Checking GitHub CLI... "
if ! command -v gh &> /dev/null; then
    echo -e "${RED}✗${NC}"
    echo -e "${RED}Error: GitHub CLI (gh) is not installed in this container${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓${NC}"
fi

# Check if user is authenticated with gh
echo -n "Checking GitHub authentication... "
if ! gh auth status &> /dev/null; then
    echo -e "${RED}✗${NC}"
    echo -e "${RED}Error: Not authenticated with GitHub CLI${NC}"
    echo "Please run on your HOST machine: gh auth login"
    ERRORS=$((ERRORS + 1))
else
    GH_USER=$(gh api user -q .login 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✓${NC} ($GH_USER)"
fi

# Check push permissions to remote repo
echo -n "Checking GitHub push permissions... "
REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")
if [[ -z "$REMOTE_URL" ]]; then
    echo -e "${YELLOW}⚠${NC}"
    echo -e "${YELLOW}Warning: No git remote configured${NC}"
    echo "Skipping push permission check."
elif ! command -v gh &> /dev/null || ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠${NC}"
    echo -e "${YELLOW}Skipped (gh not available or not authenticated)${NC}"
else
    # Extract owner/repo from remote URL
    REPO_PATH=$(echo "$REMOTE_URL" | sed -E 's#^(https://github.com/|git@github.com:)##' | sed 's#\.git$##')
    if gh api "repos/$REPO_PATH" -q .permissions.push &> /dev/null; then
        HAS_PUSH=$(gh api "repos/$REPO_PATH" -q .permissions.push 2>/dev/null)
        if [[ "$HAS_PUSH" == "true" ]]; then
            echo -e "${GREEN}✓${NC} ($REPO_PATH)"
        else
            echo -e "${RED}✗${NC}"
            echo -e "${RED}Error: No push permission to repository $REPO_PATH${NC}"
            echo "You need push access to commit and create pull requests."
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo -e "${RED}✗${NC}"
        echo -e "${RED}Error: Cannot verify permissions for repository $REPO_PATH${NC}"
        echo "Check that the repository exists and you have access."
        ERRORS=$((ERRORS + 1))
    fi
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
