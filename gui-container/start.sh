#!/bin/bash
# start.sh

# launch a headless X server
Xvfb :0 -screen 0 1920x1080x24 &

# simple window manager
fluxbox &

# VNC server reading password from $VNC_PASSWORD
x11vnc -display :0 \
       -rfbport 5900 \
       -passwd "${VNC_PASSWORD}" \
       -forever -shared

# keep container alive
wait
