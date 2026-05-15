#!/bin/sh
set -eu

. /tmp/configure-apt-cache.sh

apt_update
apt_install \
  adwaita-icon-theme-full \
  elementary-xfce-icon-theme \
  greybird-gtk-theme \
  xfce4 \
  xfce4-goodies \
  xfce4-terminal \
  xubuntu-icon-theme
apt_clean
