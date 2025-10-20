#!/bin/bash
# ABOUTME: Configures GitHub integration for the project.
# ABOUTME: Sets up repository, actions, and deploy keys.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../.setup-config"
TFVARS_FILE="$SCRIPT_DIR/../deploy-gcp/terraform.tfvars"
REPO_ROOT="$SCRIPT_DIR/.."

fail() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

warn() {
    echo -e "${YELLOW}$1${NC}"
}

success() {
    echo -e "${GREEN}$1${NC}"
}

if [[ ! -f "$CONFIG_FILE" ]]; then
    fail "Configuration file not found. Run ./setup.sh to generate configuration."
fi

if [[ ! -f "$TFVARS_FILE" ]]; then
    fail "deploy-gcp/terraform.tfvars not found. Run ./setup.sh to configure Terraform inputs."
fi

source "$CONFIG_FILE"

if [[ -z "${APP_NAME:-}" || -z "${PROD_PROJECT:-}" ]]; then
    fail "APP_NAME or PROD_PROJECT missing in ./.setup-config. Re-run earlier setup steps."
fi

if ! command -v gh >/dev/null 2>&1; then
    fail "GitHub CLI (gh) is not installed. Install it and rerun this step."
fi

if ! gh auth status >/dev/null 2>&1; then
    echo -e "${RED}Error: GitHub CLI is not authenticated.${NC}"
    echo "Run: gh auth login"
    exit 1
fi

if ! command -v gcloud >/dev/null 2>&1; then
    fail "gcloud CLI is not installed. Install it to continue."
fi

parse_tfvars() {
    local key="$1"
    python - "$TFVARS_FILE" "$key" <<'PY'
import re
import sys

tfvars_path, requested_key = sys.argv[1], sys.argv[2]
pattern = re.compile(rf'^{requested_key}\s*=\s*"(.*)"\s*$')
with open(tfvars_path, "r", encoding="utf-8") as handle:
    for line in handle:
        match = pattern.match(line.strip())
        if match:
            print(match.group(1))
            sys.exit(0)
print("")
PY
}

GITHUB_OWNER="$(parse_tfvars "github_owner")"
GITHUB_REPO="$(parse_tfvars "github_repo")"

if [[ -z "$GITHUB_OWNER" || -z "$GITHUB_REPO" ]]; then
    fail "Unable to read github_owner or github_repo from deploy-gcp/terraform.tfvars."
fi

REMOTE_URL="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || true)"
if [[ -z "$REMOTE_URL" ]]; then
    fail "Cannot determine git remote URL. Ensure 'origin' is configured."
fi

REMOTE_PATH=""
if [[ "$REMOTE_URL" =~ ^git@github\.com:(.+?)(\.git)?$ ]]; then
    REMOTE_PATH="${BASH_REMATCH[1]}"
elif [[ "$REMOTE_URL" =~ ^https://github\.com/(.+?)(\.git)?$ ]]; then
    REMOTE_PATH="${BASH_REMATCH[1]}"
else
    fail "Origin remote ($REMOTE_URL) is not a GitHub repository."
fi
REMOTE_PATH="${REMOTE_PATH%.git}"

REMOTE_OWNER="${REMOTE_PATH%%/*}"
REMOTE_REPO="${REMOTE_PATH##*/}"

if [[ "$REMOTE_OWNER" != "$GITHUB_OWNER" || "$REMOTE_REPO" != "$GITHUB_REPO" ]]; then
    echo -e "${RED}Error: Repository mismatch detected.${NC}"
    echo "Terraform expects $GITHUB_OWNER/$GITHUB_REPO but git remote is $REMOTE_OWNER/$REMOTE_REPO."
    echo "Update deploy-gcp/terraform.tfvars or the git remote so they match."
    exit 1
fi

REPO_SLUG="$GITHUB_OWNER/$GITHUB_REPO"

DEFAULT_BRANCH_FILE="$(mktemp)"
if ! DEFAULT_BRANCH="$(gh repo view "$REPO_SLUG" --json defaultBranchRef --jq '.defaultBranchRef.name' 2>"$DEFAULT_BRANCH_FILE")"; then
    echo -e "${RED}Error: Unable to detect default branch via GitHub API.${NC}"
    cat "$DEFAULT_BRANCH_FILE"
    rm -f "$DEFAULT_BRANCH_FILE"
    echo ""
    echo "Inspect the repository default branch manually and rerun after resolving the issue."
    exit 1
fi
rm -f "$DEFAULT_BRANCH_FILE"

if [[ -z "$DEFAULT_BRANCH" ]]; then
    fail "GitHub returned an empty default branch. Verify repository settings and retry."
fi

APP_SLUG="$(APP_NAME="$APP_NAME" python <<'PY'
import os
import re

name = os.environ["APP_NAME"]
parts = re.findall(r"[a-z0-9]+", name.lower())
print("-".join(parts) if parts else "app")
PY
)"

echo "Repository: $REPO_SLUG"
echo "Default branch: $DEFAULT_BRANCH"
echo ""

echo "Verifying Cloud Build triggers..."
TRIGGERS_JSON_FILE="$(mktemp)"
TRIGGERS_ERR_FILE="$(mktemp)"
if ! gcloud builds triggers list --project "$PROD_PROJECT" --format=json >"$TRIGGERS_JSON_FILE" 2>"$TRIGGERS_ERR_FILE"; then
    echo -e "${RED}Error: Failed to list Cloud Build triggers for project $PROD_PROJECT.${NC}"
    cat "$TRIGGERS_ERR_FILE"
    rm -f "$TRIGGERS_JSON_FILE" "$TRIGGERS_ERR_FILE"
    echo ""
    echo "Ensure deploy-infrastructure.sh completed successfully and that the Cloud Build GitHub App is connected."
    exit 1
fi

if [[ -s "$TRIGGERS_ERR_FILE" ]]; then
    warn "$(cat "$TRIGGERS_ERR_FILE")"
fi
rm -f "$TRIGGERS_ERR_FILE"

TRIGGER_CHECK_OUTPUT="$(TARGET_OWNER="$GITHUB_OWNER" TARGET_REPO="$GITHUB_REPO" \
    EXPECTED_PR_TRIGGER="${APP_SLUG}-pr-validate" EXPECTED_DEPLOY_TRIGGER="${APP_SLUG}-deploy" \
    python - "$TRIGGERS_JSON_FILE" <<'PY'
import json
import os
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    payload = handle.read().strip()
data = json.loads(payload or "[]")

owner = os.environ["TARGET_OWNER"]
repo = os.environ["TARGET_REPO"]
expected = [os.environ["EXPECTED_PR_TRIGGER"], os.environ["EXPECTED_DEPLOY_TRIGGER"]]

matching = [trigger for trigger in data if trigger.get("github", {}).get("owner") == owner and trigger.get("github", {}).get("name") == repo]
names = [trigger.get("name", "") for trigger in matching]
missing = [trigger_name for trigger_name in expected if trigger_name not in names]
disabled = [trigger.get("name", "") for trigger in matching if trigger.get("disabled", False)]

if missing:
    print("Missing triggers: " + ", ".join(sorted(missing)))
    sys.exit(1)

if disabled:
    print("Disabled triggers: " + ", ".join(sorted(disabled)))
    sys.exit(2)

print("Cloud Build triggers verified: " + ", ".join(sorted(names)))
PY
)"
TRIGGER_CHECK_STATUS=$?
rm -f "$TRIGGERS_JSON_FILE"

if [[ $TRIGGER_CHECK_STATUS -ne 0 ]]; then
    echo -e "${RED}${TRIGGER_CHECK_OUTPUT}${NC}"
    echo "Re-run deploy-infrastructure.sh or reconnect the Cloud Build GitHub App, then retry."
    exit 1
fi

success "$TRIGGER_CHECK_OUTPUT"
echo ""

PR_STATUS_CONTEXT="${APP_SLUG}-pr-validate (${PROD_PROJECT})"

echo "Enforcing branch protection on '$DEFAULT_BRANCH'..."
PROTECTION_JSON_FILE="$(mktemp)"
PROTECTION_ERR_FILE="$(mktemp)"
if gh api "repos/$REPO_SLUG/branches/$DEFAULT_BRANCH/protection" \
    -H "Accept: application/vnd.github+json" >"$PROTECTION_JSON_FILE" 2>"$PROTECTION_ERR_FILE"; then
    BRANCH_PROTECTED=true
else
    if grep -q "404" "$PROTECTION_ERR_FILE"; then
        BRANCH_PROTECTED=false
        echo "Branch is not currently protected; applying baseline settings."
    else
        echo -e "${RED}Error: Failed to read existing branch protection.${NC}"
        cat "$PROTECTION_ERR_FILE"
        rm -f "$PROTECTION_JSON_FILE" "$PROTECTION_ERR_FILE"
        exit 1
    fi
fi

NEEDS_PROTECTION_UPDATE=true
if [[ "$BRANCH_PROTECTED" == true ]]; then
    if PROTECTION_CHECK_OUTPUT="$(PR_STATUS_CONTEXT="$PR_STATUS_CONTEXT" python - "$PROTECTION_JSON_FILE" <<'PY'
import json
import sys
import os

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    current = json.load(handle)

desired_contexts = [os.environ["PR_STATUS_CONTEXT"]]
reasons = []

status_checks = current.get("required_status_checks")
if not status_checks:
    reasons.append("Status checks not configured.")
else:
    contexts = status_checks.get("contexts") or []
    if sorted(contexts) != desired_contexts:
        reasons.append("Status check contexts do not match Cloud Build.")
    if bool(status_checks.get("strict")):
        reasons.append("Strict status checks enabled; expected relaxed merge rule.")

enforce_admins = current.get("enforce_admins", {}).get("enabled", False)
if not enforce_admins:
    reasons.append("Admins can bypass protections.")

reviews = current.get("required_pull_request_reviews")
if reviews and reviews.get("required_approving_review_count", 0) > 0:
    reasons.append("Pull request review requirement present.")

allow_force_pushes = current.get("allow_force_pushes", {}).get("enabled", False)
if allow_force_pushes:
    reasons.append("Force pushes allowed.")

allow_deletions = current.get("allow_deletions", {}).get("enabled", False)
if allow_deletions:
    reasons.append("Branch deletions allowed.")

if reasons:
    print("\n".join(reasons))
    sys.exit(1)
else:
    sys.exit(0)
PY
)"; then
        NEEDS_PROTECTION_UPDATE=false
    else
        echo "Branch protection drift detected:"
        echo "$PROTECTION_CHECK_OUTPUT"
    fi
fi
rm -f "$PROTECTION_ERR_FILE" "$PROTECTION_JSON_FILE"

if [[ "$NEEDS_PROTECTION_UPDATE" == true ]]; then
    echo "Updating branch protection..."
    PROTECTION_PAYLOAD="$(cat <<EOF
{
  "required_status_checks": {
    "strict": false,
    "contexts": ["$PR_STATUS_CONTEXT"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
)"

    if ! echo "$PROTECTION_PAYLOAD" | gh api --method PUT "repos/$REPO_SLUG/branches/$DEFAULT_BRANCH/protection" \
        -H "Accept: application/vnd.github+json" \
        -H "Content-Type: application/json" \
        --input - >/dev/null; then
        fail "Failed to apply branch protection. Check your GitHub permissions."
    fi
    success "Branch protection updated."
else
    success "Branch protection already matches desired settings."
fi

echo ""
echo "Configuring GitHub repository variables..."
declare -A GH_VARIABLES=(
    ["GCP_PROJECT_ID"]="$PROD_PROJECT"
    ["CLOUD_RUN_REGION"]="us-central1"
    ["CLOUD_RUN_SERVICE"]="$APP_NAME"
)
VARIABLE_ORDER=("GCP_PROJECT_ID" "CLOUD_RUN_REGION" "CLOUD_RUN_SERVICE")

for VAR_NAME in "${VARIABLE_ORDER[@]}"; do
    VAR_VALUE="${GH_VARIABLES[$VAR_NAME]}"
    VAR_ENDPOINT="repos/$REPO_SLUG/actions/variables/$VAR_NAME"
    if gh api "$VAR_ENDPOINT" -H "Accept: application/vnd.github+json" >/dev/null 2>&1; then
        VAR_PAYLOAD="$(cat <<EOF
{
  "name": "$VAR_NAME",
  "value": "$VAR_VALUE"
}
EOF
)"
        if ! echo "$VAR_PAYLOAD" | gh api --method PATCH "$VAR_ENDPOINT" \
            -H "Accept: application/vnd.github+json" \
            -H "Content-Type: application/json" \
            --input - >/dev/null; then
            fail "Failed to update repository variable $VAR_NAME."
        fi
    else
        VAR_CREATE_PAYLOAD="$(cat <<EOF
{
  "name": "$VAR_NAME",
  "value": "$VAR_VALUE"
}
EOF
)"
        if ! echo "$VAR_CREATE_PAYLOAD" | gh api --method POST "repos/$REPO_SLUG/actions/variables" \
            -H "Accept: application/vnd.github+json" \
            -H "Content-Type: application/json" \
            --input - >/dev/null; then
            fail "Failed to create repository variable $VAR_NAME."
        fi
    fi
    echo "  - $VAR_NAME = $VAR_VALUE"
done

echo ""
success "GitHub integration configured successfully."
echo ""
echo "Summary:"
echo "  - Verified Cloud Build triggers for $REPO_SLUG"
echo "  - Enforced branch protection on $DEFAULT_BRANCH"
echo "  - Published repository variables: ${VARIABLE_ORDER[*]}"
echo ""
echo "Next steps:"
echo "  - Create a test pull request to confirm Cloud Build reports status in GitHub."
