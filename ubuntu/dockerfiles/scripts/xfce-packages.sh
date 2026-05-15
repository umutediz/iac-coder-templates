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

create_icon_alias() {
  source_name="$1"
  target_name="$2"

  for source_icon in /usr/share/icons/elementary-xfce*/apps/*/"${source_name}.png"; do
    [ -e "$source_icon" ] || continue
    ln -sf "${source_name}.png" "$(dirname "$source_icon")/${target_name}.png"
  done
}

create_icon_alias utilities-terminal org.xfce.terminalemulator
create_icon_alias system-file-manager org.xfce.filemanager
create_icon_alias web-browser org.xfce.webbrowser
create_icon_alias preferences-desktop-default-applications org.xfce.appfinder

for icon_theme in /usr/share/icons/elementary-xfce*; do
  [ -d "$icon_theme" ] || continue
  gtk-update-icon-cache -f -q "$icon_theme" || true
done
