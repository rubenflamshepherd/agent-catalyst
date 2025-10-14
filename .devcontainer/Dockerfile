FROM python:3.11-slim

# Install Node.js and git
RUN apt-get update && \
    apt-get install -y curl git openssh-client sudo && \
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Install Google Cloud CLI
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates gnupg wget unzip && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get update && \
    apt-get install -y google-cloud-cli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo $VERSION_CODENAME) main" | tee /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && \
    apt-get install -y terraform && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && \
    apt-get install -y gh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash -u 1000 devuser && \
    echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /workspace

COPY app/requirements.txt ./app/
RUN pip install --no-cache-dir -r app/requirements.txt

# Create gcloud config directory for devuser
RUN mkdir -p /home/devuser/.config/gcloud && \
    chown -R devuser:devuser /home/devuser/.config

# Configure git aliases for devuser
RUN echo 'alias gs="git status"' >> /home/devuser/.bashrc && \
    echo 'alias gcam="git commit --all --message"' >> /home/devuser/.bashrc && \
    echo 'alias gd="git diff"' >> /home/devuser/.bashrc && \
    echo 'alias vamos="claude --dangerously-skip-permissions"' >> /home/devuser/.bashrc && \
    chown devuser:devuser /home/devuser/.bashrc

# Install Terraform autocomplete as devuser
USER devuser
RUN terraform -install-autocomplete
USER root

# Set ownership and switch to non-root user
RUN chown -R devuser:devuser /workspace
USER devuser
