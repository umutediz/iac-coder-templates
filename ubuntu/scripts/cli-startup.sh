set -eu

if [ ! -f "$HOME/.bashrc" ]; then
  cp -r /etc/skel/. "$HOME/" 2>/dev/null || true
fi
