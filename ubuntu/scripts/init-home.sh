set -eu

# Populate home from skel on first run (no-clobber).
cp -rn /etc/skel/. /home/coder/ 2>/dev/null || true

# Remove stale X11/VNC state that may be owned by a different uid
# from a previous session, which would block writes as uid 1000.
rm -f /home/coder/.Xauthority
rm -f /home/coder/.vnc/xstartup
