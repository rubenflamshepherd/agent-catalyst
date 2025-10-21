# agent-catalyst
Bootstrap a basic project with prod and dev environments to enable agents to build out the differing functionality

## Basic Pieces

This template will setup:

- A local development and cloud-based production environment for all the below componenets.

- A database
- A server that will function as both our frontend and backend
  - Backend will be Python/Flask
  - Frontend will be node.js (or maybe vanilla JavaScript?)

Integrations for agents
- github authentications
  - commits, prs, pushs, cicd, etc
- mcp for database

## 

I'll be outlining how to do this on MacOS using homebrew. Mainly because I believe that to be a pretty common setup for developers. However, this should be doable in other setups with minimal adaptations/changes.

## Quick Start

### 1. Complete Prerequisites

Before starting, complete the setup steps in [PREREQUISITES.md](PREREQUISITES.md):

- Install Docker Desktop on your host machine
- Authenticate with Google Cloud (on host machine)
- Create a GCP account

### 2. Start Development Environment

```bash
# Build and start the dev container
docker compose build
docker compose up
```

Navigate to http://localhost:8080 to verify the app is running.

### 3. Run Automated Setup

Inside the dev container, run the setup script:

```bash
./setup.sh
```

This single command will:
1. ✓ Verify prerequisites
2. ✓ Create GCP projects (with generated unique IDs)
3. ⚠ Configure Terraform (not yet implemented)
4. ⚠ Deploy infrastructure (not yet implemented)
5. ⚠ Set up GitHub integration (not yet implemented)
6. ⚠ Verify deployment (not yet implemented)

Each step is idempotent - you can safely re-run if something fails.

## Development

Testing locally is run from inside the dev container. When running outside it, install dependencies manually:

```bash
pip install -r app/requirements.txt -r app/requirements-dev.txt
```

Run the full test suite:

```bash
make test
```

Run tests with coverage reporting:

```bash
make test-coverage
```

Run a specific test:

```bash
make test-target TARGET=tests/test_routes.py::test_homepage
```

If `make` is unavailable, run the underlying commands directly from `/workspace/app`:

```bash
cd app && PYTHONWARNINGS=error pytest
cd app && PYTHONWARNINGS=error pytest --cov=webapp --cov-report=term-missing
cd app && PYTHONWARNINGS=error pytest tests/test_routes.py::test_homepage
```

## What Gets Configured

This template sets up:

**Local Development:**
- Docker-based dev environment with all tools pre-installed
- Mounted GCP credentials from your host machine
- Hot-reloading Flask application on port 8080

**Cloud Production:**
- Unique GCP project with random suffix
- Infrastructure as code using Terraform
- (Coming soon) Cloud Run services, Cloud SQL database, networking

**Agent Integration:**
- GitHub authentication for commits, PRs, and CI/CD
- (Coming soon) MCP for database access

## Manual Setup (Alternative)

If you prefer to run individual setup steps:

```bash
# Verify prerequisites
./setup/verify-prerequisites.sh

# Create GCP projects
./setup/create-projects.sh

# Configure Terraform (not yet implemented)
./setup/configure-terraform.sh

# Deploy infrastructure (not yet implemented)
./setup/deploy-infrastructure.sh

# Set up GitHub integration (not yet implemented)
./setup/setup-github-integration.sh

# Verify deployment (not yet implemented)
./setup/verify-deployment.sh
```

## Troubleshooting

See [PREREQUISITES.md](PREREQUISITES.md) for common issues and solutions.

**Common issues:**
- "Not authenticated with gcloud" - Run auth commands on host machine
- "Cannot list GCP projects" - Accept GCP Terms of Service
- Credentials not in container - Verify `~/.config/gcloud` exists on host
