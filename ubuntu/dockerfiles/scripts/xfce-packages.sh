#!/bin/sh
set -eu

apt-get update
apt-get install -y --no-install-recommends \
  adwaita-icon-theme-full \
  elementary-xfce-icon-theme \
  greybird-gtk-theme \
  xfce4 \
  xfce4-goodies \
  xfce4-terminal \
  xubuntu-icon-theme
rm -rf /var/lib/apt/lists/*
