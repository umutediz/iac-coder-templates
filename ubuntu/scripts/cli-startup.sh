set -eu

if [ ! -f "$HOME/.bashrc" ]; then
  cp -r /etc/skel/. "$HOME/" 2>/dev/null || true
fi

settings_dir="$HOME/.local/share/code-server/User"
settings_file="$settings_dir/settings.json"
mkdir -p "$settings_dir"

if ! grep -q '"workbench.colorTheme"' "$settings_file" 2>/dev/null; then
  if [ ! -s "$settings_file" ] || [ "$(tr -d '[:space:]' < "$settings_file" 2>/dev/null)" = "{}" ]; then
    cat > "$settings_file" <<'EOF'
{
  "workbench.colorTheme": "Default Dark Modern"
}
EOF
  else
    tmp_settings="$(mktemp)"
    awk '
      {
        lines[NR] = $0
      }
      END {
        end = 0
        for (i = NR; i >= 1; i--) {
          if (lines[i] ~ /^[[:space:]]*}[[:space:]]*$/) {
            end = i
            break
          }
        }
        if (end == 0) {
          print "{"
          print "  \"workbench.colorTheme\": \"Default Dark Modern\""
          print "}"
          exit
        }
        last = 0
        for (i = end - 1; i >= 1; i--) {
          if (lines[i] !~ /^[[:space:]]*$/) {
            last = i
            break
          }
        }
        for (i = 1; i <= NR; i++) {
          if (i == last && lines[i] !~ /,[[:space:]]*$/) {
            print lines[i] ","
          } else if (i == end) {
            print "  \"workbench.colorTheme\": \"Default Dark Modern\""
            print lines[i]
          } else {
            print lines[i]
          }
        }
      }
    ' "$settings_file" > "$tmp_settings" && mv "$tmp_settings" "$settings_file"
  fi
fi

if command -v code-server >/dev/null 2>&1 && ! pgrep -u "$(id -u)" -f 'code-server.*--port 13337' >/dev/null 2>&1; then
  code-server \
    --auth none \
    --host 127.0.0.1 \
    --port 13337 \
    "$HOME" \
    >/tmp/code-server.log 2>&1 &
fi
