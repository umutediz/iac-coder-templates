#!/bin/sh
set -eu

apt-get update
apt-get install -y --no-install-recommends \
  greybird-gtk-theme \
  xfce4 \
  xfce4-terminal
rm -rf /var/lib/apt/lists/*
