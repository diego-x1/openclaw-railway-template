FROM node:22-bookworm

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    gosu \
    procps \
    build-essential \
    # Python
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    # Browser & rendering
    chromium \
    # Audio/Video processing
    ffmpeg \
    # OCR
    tesseract-ocr \
    tesseract-ocr-pol \
    # Document processing
    imagemagick \
    poppler-utils \
    pandoc \
    # Search & navigation
    ripgrep \
    fd-find \
    # Data & DB
    jq \
    sqlite3 \
    # Network & SSH
    openssh-client \
    rsync \
    # Misc utilities
    zip \
    unzip \
    htop \
    tree \
  && rm -rf /var/lib/apt/lists/*

# Python packages (transcription, media tools)
RUN pip3 install --no-cache-dir --break-system-packages \
    faster-whisper \
    yt-dlp

RUN npm install -g openclaw@latest

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile --prod

COPY src ./src
COPY entrypoint.sh ./entrypoint.sh

RUN useradd -m -s /bin/bash openclaw \
  && chown -R openclaw:openclaw /app \
  && mkdir -p /data && chown openclaw:openclaw /data \
  && mkdir -p /home/linuxbrew/.linuxbrew && chown -R openclaw:openclaw /home/linuxbrew

USER openclaw
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
ENV HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
ENV HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
ENV HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"

ENV PORT=8080
ENV OPENCLAW_ENTRY=/usr/local/lib/node_modules/openclaw/dist/entry.js
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD curl -f http://localhost:8080/setup/healthz || exit 1

USER root
ENTRYPOINT ["./entrypoint.sh"]
