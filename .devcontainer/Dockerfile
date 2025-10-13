FROM python:3.11-slim

# Install Node.js and git
RUN apt-get update && \
    apt-get install -y curl git openssh-client && \
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY app/requirements.txt ./app/
RUN pip install --no-cache-dir -r app/requirements.txt
