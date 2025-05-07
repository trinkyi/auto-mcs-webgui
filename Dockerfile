# Use a minimal Debian Bookworm Slim base image
FROM debian:bookworm-slim

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Install virtual X server, lightweight window manager, VNC server, envsubst, and utilities
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  xvfb            # Virtual X11 server              \
  fluxbox         # Lightweight window manager     \
  x11vnc          # VNC server to share the X session \
  wget            # Tool to download files         \
  unzip           # Unzip archives                 \
  gettext-base    # Provides envsubst for templating \
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

# Copy Guacamole template into the image
# (assumes you have a guacamole/ directory alongside this Dockerfile)
COPY guacamole/ /guacamole/

# Create entrypoint script to:
#  1) render the Guacamole XML from template,
#  2) start Xvfb,
#  3) set VNC password,
#  4) launch Fluxbox, VNC, and auto-mcs
RUN printf '#!/usr/bin/env bash\n'                                          > /start.sh && \
  # 1) Render Guacamole user-mapping.xml if template exists
  printf 'if [ -f "/guacamole/user-mapping.xml.tpl" ]; then\n'           >> /start.sh && \
  printf '  echo "Rendering Guacamole user-mapping.xml from template"\n' >> /start.sh && \
  printf '  envsubst < /guacamole/user-mapping.xml.tpl > /guacamole/user-mapping.xml\n' >> /start.sh && \
  printf '  if [ "${REMOVE_TEMPLATE:-false}" = "true" ]; then rm /guacamole/user-mapping.xml.tpl; fi\n' >> /start.sh && \
  printf 'fi\n\n'                                                      >> /start.sh && \
  # 2) Start virtual X server
  printf 'Xvfb :0 -screen 0 1024x768x16 &\n'                             >> /start.sh && \
  # 3) Set VNC password at runtime
  printf 'VNC_PASSWORD=${VNC_PASSWORD:-changeme}\n'                      >> /start.sh && \
  printf 'echo "$VNC_PASSWORD" | x11vnc -storepasswd /etc/x11vnc.pass\n' >> /start.sh && \
  # 4) Launch window manager and VNC server
  printf 'fluxbox &\n'                                                  >> /start.sh && \
  printf 'x11vnc -forever -shared -rfbauth /etc/x11vnc.pass -display :0 &\n' >> /start.sh && \
  # 5) Exec auto-mcs GUI
  printf 'exec auto-mcs\n'                                              >> /start.sh && \
  chmod +x /start.sh

# Expose VNC port for Guacamole (or direct VNC clients) to connect
EXPOSE 5900

# Launch the startup script when container starts
CMD ["/start.sh"]
