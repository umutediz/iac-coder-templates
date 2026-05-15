#!/bin/sh
set -eu

. /tmp/configure-apt-cache.sh

apt_update
apt_install \
  dbus-x11 \
  libxkbcommon-x11-0 \
  nginx-light \
  novnc \
  tigervnc-standalone-server \
  websockify \
  xfonts-base \
  xrdp
apt_clean
