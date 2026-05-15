mkdir -p "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
cat > "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Greybird"/>
    <property name="IconThemeName" type="string" value="elementary-xfce-dark"/>
  </property>
</channel>
EOF

if [ -d "$HOME/.config/xfce4/panel" ]; then
  for launcher in "$HOME"/.config/xfce4/panel/launcher-*/*.desktop; do
    [ -f "$launcher" ] || continue
    sed -i \
      -e 's/^Icon=org\.xfce\.terminalemulator$/Icon=utilities-terminal/' \
      -e 's/^Icon=org\.xfce\.filemanager$/Icon=system-file-manager/' \
      -e 's/^Icon=org\.xfce\.webbrowser$/Icon=web-browser/' \
      -e 's/^Icon=org\.xfce\.appfinder$/Icon=preferences-desktop-default-applications/' \
      "$launcher"
  done
fi
