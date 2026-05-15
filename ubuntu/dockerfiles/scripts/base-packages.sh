#!/bin/sh
set -eu

apt-get update
apt-get install -y --no-install-recommends \
  bash \
  build-essential \
  curl \
  dnsutils \
  file \
  git \
  htop \
  jq \
  less \
  man-db \
  nano \
  openssh-client \
  procps \
  python3 \
  python3-pip \
  python3-venv \
  rsync \
  sudo \
  tmux \
  unzip \
  vim \
  wget \
  zip
rm -rf /var/lib/apt/lists/*
