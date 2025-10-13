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

## Setup your local development environment

1. Docker
   
Docker is what is going to allow us to setup the same local environment regardless of what base OS (MacOS, Windows, etc.) you are coming from. Install it for whatever Operating System you are on:
 - [Mac](https://docs.docker.com/desktop/setup/install/mac-install/)
 - [Windows](https://docs.docker.com/desktop/setup/install/windows-install/)
 - [Linux](https://docs.docker.com/desktop/setup/install/linux/)

Once it is installed make sure Docker Desktop is running.
   
2. Setup Google Cloud credentials for local development

You need to authenticate with Google Cloud on your host machine. Your entire gcloud configuration will be mounted into the dev container, allowing both infrastructure management (via `gcloud` CLI) and application code (via Application Default Credentials) to work seamlessly.

**Run both of these commands on your host machine (outside the container):**

```bash
# Authenticate the gcloud CLI (for infrastructure operations like creating projects)
gcloud auth login

# Authenticate for application code (for Python/Node code accessing GCP APIs)
gcloud auth application-default login
```

**Why both commands?**
- `gcloud auth login` - Needed for running infrastructure scripts inside the dev container (like `./deploy-gcp/create-projects.sh`)
- `gcloud auth application-default login` - Needed for your application code (Python, Node, etc.) to access GCP services

Your `~/.config/gcloud` directory gets automatically mounted into the dev container, so both the `gcloud` CLI, Terraform, and your application code will work inside the container with proper authentication.

**Note**: The dev container includes Terraform, gcloud CLI, and all necessary tools pre-installed. In production (Cloud Run, GKE, GCE), Workload Identity provides credentials automatically - no additional setup needed.

3. Standup your local environment

Build your local environment by running the following in the command line from the root of this project.

```bash
docker compose build
```
This will take a few minutes the first time. Once that is done run

```bash
docker compose up
```

Navigate to localhost:8080 and you should see our generic landing page!

## Setup your cloud production environment

1. Install [Terraform](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/install-cli)

2. Install [gcloud CLI](https://cloud.google.com/sdk/docs/install)

You'll need a [Google Cloud Platform](https://console.cloud.google.com/freetrial/) account if you don't already have one.

3. Authenticate with gcloud

```bash
gcloud auth login
```

4. Create GCP projects for dev and prod environments

Run the project creation script:

```bash
./deploy-gcp/create-projects.sh
```

This will:
- Prompt you for your app name
- Generate unique project IDs for dev and prod with random suffixes
- Create both projects in your GCP account

5. If you don't have SSH authentication setup for Github you need to do that via GITHUB_SSHE_SETUP.md

You'll need a Github account if you don't already have one.



2.


 [Terraform](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/install-cli). If you aren't familiar with Terraform it's probably helpful to walk through the tutorials in the link above so you have a working mental model of how the different pieces of this project work together