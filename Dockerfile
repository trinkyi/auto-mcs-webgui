# Use a minimal Debian Bookworm Slim base image
FROM debian:bookworm-slim

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Install X server, lightweight window manager, VNC server, and utilities
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      xorg        # X11 server for graphical applications\
      fluxbox     # Lightweight window manager\
      x11vnc      # VNC server to share the X session\
      wget        # Tool to download files\
      unzip       # Unzip archives\
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*  # Clean up APT cache

# Download and install auto-mcs
ARG AUTO_MCS_VERSION=2.3
ENV AUTO_MCS_ASSET=auto-mcs-linux-${AUTO_MCS_VERSION}.zip
RUN wget -O /tmp/${AUTO_MCS_ASSET} \
      https://github.com/macarooni-man/auto-mcs/releases/download/v${AUTO_MCS_VERSION}/${AUTO_MCS_ASSET} && \
    unzip /tmp/${AUTO_MCS_ASSET} -d /opt/auto-mcs && \
    rm /tmp/${AUTO_MCS_ASSET} && \
    chmod +x /opt/auto-mcs/auto-mcs  # Make the binary executable

# Add auto-mcs to PATH
ENV PATH="/opt/auto-mcs:${PATH}"

# Store VNC password from environment variable or default to 'changeme'
# VNC_PASSWORD should be passed via 'docker run -e VNC_PASSWORD=yourpass'
RUN x11vnc -storepasswd ${VNC_PASSWORD:-changeme} /etc/x11vnc.pass

# Create entrypoint script to launch desktop, VNC server, and auto-mcs GUI
RUN printf '#!/bin/bash\n'                  > /start.sh && \
    printf 'fluxbox &\n'                   >> /start.sh && \
    printf 'x11vnc -forever -shared -rfbauth /etc/x11vnc.pass -display :0 &\n' >> /start.sh && \
    printf 'exec auto-mcs\n'              >> /start.sh && \
    chmod +x /start.sh

# Expose VNC port for Guacamole to connect
EXPOSE 5900

# Launch the startup script when container starts
CMD ["/start.sh"]
