#!/bin/sh
set -eux

if getent passwd 1000 >/dev/null; then
  existing_user="$(getent passwd 1000 | cut -d: -f1)"
  if [ "$existing_user" != "coder" ]; then
    usermod -l coder "$existing_user"
  fi
  usermod -d /home/coder -s /bin/bash coder
else
  if getent group 1000 >/dev/null; then
    existing_group="$(getent group 1000 | cut -d: -f1)"
  else
    groupadd -g 1000 coder
    existing_group="coder"
  fi
  useradd -u 1000 -g "$existing_group" -d /home/coder -s /bin/bash coder
fi

mkdir -p /home/coder
chown 1000:1000 /home/coder
echo "coder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/coder
chmod 440 /etc/sudoers.d/coder
