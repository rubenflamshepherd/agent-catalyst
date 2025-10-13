# GitHub SSH Setup for Multiple Accounts

This guide walks through the one-time setup needed to use multiple GitHub accounts with SSH keys in the devcontainer.

## Prerequisites

- You have access to your host machine's terminal
- You have admin access to your GitHub accounts

## Step 1: Generate SSH Keys (on your host machine)

Open a terminal on your host machine and run:

```bash
# For your work account
ssh-keygen -t ed25519 -C "your-work-email@company.com" -f ~/.ssh/id_ed25519_work

# For your personal account
ssh-keygen -t ed25519 -C "your-personal-email@example.com" -f ~/.ssh/id_ed25519_personal
```

When prompted for a passphrase:
- You can press Enter for no passphrase (convenient but less secure)
- Or enter a passphrase (more secure, but you'll need to enter it when using the key)

## Step 2: Add Public Keys to GitHub

```bash
# Copy your work public key
cat ~/.ssh/id_ed25519_work.pub
```

1. Go to your **work** GitHub account
2. Navigate to Settings → SSH and GPG keys → New SSH key
3. Paste the public key content
4. Give it a descriptive title (e.g., "Work Laptop - Dev Container")

Repeat for your personal account:

```bash
# Copy your personal public key
cat ~/.ssh/id_ed25519_personal.pub
```

1. Go to your **personal** GitHub account
2. Navigate to Settings → SSH and GPG keys → New SSH key
3. Paste the public key content
4. Give it a descriptive title (e.g., "Personal Laptop - Dev Container")

## Step 3: Configure SSH (on your host machine)

Create or edit `~/.ssh/config`:

```bash
nano ~/.ssh/config
```

Add this configuration:

```
# Work GitHub account
Host github.com-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
  IdentitiesOnly yes

# Personal GitHub account
Host github.com-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_personal
  IdentitiesOnly yes
```

Save and exit (Ctrl+O, Enter, Ctrl+X if using nano).

Set proper permissions:

```bash
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_ed25519_work
chmod 600 ~/.ssh/id_ed25519_personal
chmod 644 ~/.ssh/id_ed25519_work.pub
chmod 644 ~/.ssh/id_ed25519_personal.pub
```

## Step 4: Test the Connection

Test each account:

```bash
# Test work account
ssh -T git@github.com-work

# Test personal account
ssh -T git@github.com-personal
```

You should see messages like: `Hi username! You've successfully authenticated...`

## Step 5: Rebuild the Dev Container

The Docker configuration has been updated to mount your SSH directory. You need to rebuild:

```bash
# Stop the current container if running
docker-compose down

# Rebuild and start
docker-compose up -d --build devcontainer
```

## Using Git Inside the Container

When cloning repositories or setting remotes, use the host aliases:

**For work repositories:**
```bash
git clone git@github.com-work:company/repo.git
```

**For personal repositories:**
```bash
git clone git@github.com-personal:youruser/repo.git
```

**For existing repositories, update the remote:**
```bash
# Check current remote
git remote -v

# Update to work account
git remote set-url origin git@github.com-work:company/repo.git

# Or update to personal account
git remote set-url origin git@github.com-personal:youruser/repo.git
```

## Troubleshooting

**"Permission denied (publickey)" error:**
- Verify the public key was added to the correct GitHub account
- Check that `~/.ssh/config` exists and has the correct configuration
- Ensure file permissions are correct (Step 3)
- Test connection from your host machine first

**"Too many authentication failures" error:**
- This means `IdentitiesOnly yes` is missing or not working
- Double-check your `~/.ssh/config` file

**Keys not available in container:**
- Ensure the container was rebuilt after updating `docker-compose.yml`
- Verify the volume mount: `docker-compose config` should show `~/.ssh:/root/.ssh:ro`

## Security Note

The SSH directory is mounted as read-only (`:ro`) into the container for security. Your private keys remain on your host machine and are only readable by the container, not writable.
