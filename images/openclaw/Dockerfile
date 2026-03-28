FROM ghcr.io/openclaw/openclaw:latest

LABEL org.opencontainers.image.source="https://github.com/carlosgit2016/homelab"
LABEL org.opencontainers.image.description="Openclaw homelab cluster admin agent"

USER root

# ── 1. System & network packages (apt) ───────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    dnsutils \
    file \
    git \
    gnupg \
    iproute2 \
    iputils-ping \
    jq \
    mtr-tiny \
    netcat-traditional \
    net-tools \
    nmap \
    openssl \
    procps \
    python3 \
    python3-pip \
    tcpdump \
    telnet \
    traceroute \
    vim \
    wget \
    whois \
    && rm -rf /var/lib/apt/lists/*

# ── 2. calicoctl (not in Homebrew — direct binary download) ──────────────────
ARG CALICOCTL_VERSION=v3.29.0
RUN curl -fsSL \
    "https://github.com/projectcalico/calico/releases/download/${CALICOCTL_VERSION}/calicoctl-linux-amd64" \
    -o /usr/local/bin/calicoctl \
    && chmod +x /usr/local/bin/calicoctl

# ── 3. Python tools (ansible, ansible-lint, pre-commit) ──────────────────────
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --break-system-packages --no-cache-dir -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

# ── 4. GitHub SSH known_hosts ─────────────────────────────────────────────────
RUN ssh-keyscan github.com >> /etc/ssh/ssh_known_hosts

# ── 5. Prepare Homebrew directory owned by UID 1000 ──────────────────────────
# Homebrew refuses to run as root — all root ops must be done above this line
RUN mkdir -p /home/linuxbrew && chown -R 1000:1000 /home/linuxbrew

ENV HOME=/home/linuxbrew
USER 1000

# ── 6. Homebrew (Linuxbrew) ───────────────────────────────────────────────────
RUN NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"

# ── 7. Tool binaries via Homebrew (kubectl, helm, argocd, kubeseal, terraform) ─
RUN brew install \
    argocd \
    helm \
    kubeseal \
    kubectl \
    terraform \
    && brew cleanup
