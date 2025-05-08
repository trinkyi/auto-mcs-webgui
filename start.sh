#!/usr/bin/env bash
set -euo pipefail

# 1) Ensure VNC password is stored
VNC_PASSWORD=${VNC_PASSWORD:-changeme}
echo "$VNC_PASSWORD" | x11vnc -storepasswd /etc/x11vnc.pass

# 2) Launch Xvfb + Fluxbox + x11vnc + auto-mcs in one go
exec xvfb-run -n 0 -s "-screen 0 1024x768x24" \
  bash -lc "\
    fluxbox & \
    x11vnc -forever -shared -rfbauth /etc/x11vnc.pass -display :0 & \
    exec auto-mcs"
