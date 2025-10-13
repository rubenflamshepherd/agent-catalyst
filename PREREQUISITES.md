# Prerequisites Checklist

Complete these steps **before** running `./setup.sh` inside the dev container.

## 1. Install Docker Desktop

Docker Desktop must be installed and running on your host machine.

**Installation links:**
- [macOS](https://docs.docker.com/desktop/setup/install/mac-install/)
- [Windows](https://docs.docker.com/desktop/setup/install/windows-install/)
- [Linux](https://docs.docker.com/desktop/setup/install/linux/)

**Verify:** Open Docker Desktop and confirm it's running.

## 2. Google Cloud Authentication

You need to authenticate with Google Cloud **on your host machine** (not inside the container). These credentials will be mounted into the dev container automatically.

### 2.1 Install gcloud CLI (Host Machine)

**macOS (Homebrew):**
```bash
brew install --cask google-cloud-sdk
```

**Other platforms:** See [official installation guide](https://cloud.google.com/sdk/docs/install)

### 2.2 Authenticate (Host Machine)

Run **both** of these commands on your host machine:

```bash
# Authenticate gcloud CLI (for infrastructure operations)
gcloud auth login

# Authenticate for application code (for Python/Node code accessing GCP)
gcloud auth application-default login
```

**Why both?**
- `gcloud auth login` - Required for running infrastructure scripts (creating projects, deploying resources)
- `gcloud auth application-default login` - Required for application code to access GCP APIs

**Verify:**
```bash
# Check that you're authenticated
gcloud auth list

# Verify you can list projects (proves auth + permissions)
gcloud projects list
```

Your `~/.config/gcloud` directory will be automatically mounted into the dev container.

## 3. Google Cloud Platform Account

You'll need a [Google Cloud Platform account](https://console.cloud.google.com/freetrial/).

The free tier includes $300 in credits for new users.

## 4. Start Dev Container

Once prerequisites are complete:

```bash
# Build the dev container
docker compose build

# Start the container
docker compose up
```

Navigate to http://localhost:8080 to verify the app is running.

## 5. Run Setup

Inside the dev container (or using `docker exec`):

```bash
./setup.sh
```

The setup script will:
1. Verify all prerequisites are met
2. Create GCP projects
3. Configure Terraform
4. Deploy infrastructure
5. Set up GitHub integration
6. Verify deployment

Each step is idempotent - you can safely re-run if something fails.

## Troubleshooting

### "Not authenticated with gcloud"

Make sure you ran both auth commands **on your host machine**:
```bash
gcloud auth login
gcloud auth application-default login
```

### "Cannot list GCP projects"

This usually means:
1. You haven't authenticated yet
2. Your account doesn't have proper permissions
3. You need to accept Google Cloud's Terms of Service

Visit https://console.cloud.google.com to accept ToS if needed.

### Credentials not appearing in container

Verify your `~/.config/gcloud` directory exists on the host machine. The dev container mounts this directory automatically via docker-compose.yml.
