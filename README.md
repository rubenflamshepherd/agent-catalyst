# agent-catalyst

Agent Catalyst is a batteries-included framework for you to stand up a basic app upon which you can then build out your app (agentically or otherwise)!

It includes a basic scaffold for:

- local development environment
- cloud production environment
- automatic deployment to prod
- CICD
- testing
- linting

With additional integrations for agentic workflows:
- git and gituhb
- gcloud CLI
- terraform

You can totally use this if you just want to standup development and production environments. But I think this framework really shines when combined with agentic workflows:

Agentic coding is good but non-deterministic. They can bootstrap an app's basic functionailty but this takes time, some back-and-forth with the agent, and the outcome is
not guarenteed. Instead, bootstrap this basic functionality with Agent Catalyst and have Agents build out the actual core functionality of the app.

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


## Quick Start

I'll be outlining how to do this on MacOS using `homebrew`. Mainly because that's my own setup and I believe that to be a pretty common among developers. However, this should be doable in Operating Systems with minimal adaptations/changes. I'd also highly recommend using VSCode with the Dev Container package to build the development environment (again my setup). A `.devcontainer/Dockerfiler` is provided for this.

### 1. Complete Prerequisites

Before starting, complete the setup steps in [PREREQUISITES.md](PREREQUISITES.md):

### 2. Start Development Environment

```bash
# Build and start the dev container
docker compose build
docker compose up
```

Navigate to http://localhost:8080 to verify the app is running.

The dev container automatically creates `.env` from `.env.example` if it doesn't exist. You can customize this file with your own values as needed.

### 3. Run Automated Setup

Inside the dev container, run the setup script:

```bash
./setup.sh
```

This single command will:
1. ✓ Verify prerequisites
2. ✓ Create GCP projects
3. ✓ Configure Terraform
4. ✓ Deploy infrastructure
5. ✓ Set up GitHub integration
6. ⚠ Verify deployment (not yet implemented)

Each step is idempotent - you can safely re-run if something fails.

## Development

Testing locally is run from inside the dev container. When running outside of the dev container, install dependencies manually:

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

The `make` command is a wrapper/alias. If you want to run the tests directly run the following commands from `/workspace/app`:

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

## Roadmap

- database integration
- basic user system (login, email validation, etc)

## Troubleshooting

See [PREREQUISITES.md](PREREQUISITES.md) for common issues and solutions.

**Common issues:**
- "Not authenticated with gcloud" - Run auth commands on host machine
- "Cannot list GCP projects" - Accept GCP Terms of Service
- Credentials not in container - Verify `~/.config/gcloud` exists on host
