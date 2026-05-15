#!/bin/sh
set -eu

apt-get update
apt-get install -y --no-install-recommends \
  dbus-x11 \
  libxkbcommon-x11-0 \
  nginx-light \
  novnc \
  tigervnc-standalone-server \
  websockify \
  x11-xserver-utils \
  xauth \
  xfonts-base
rm -rf /var/lib/apt/lists/*
