# Use a minimal Debian Bookworm Slim base image
FROM debian:bookworm-slim

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Install Xvfb, Fluxbox, x11vnc, wget, unzip, ca-certificates
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      xvfb \
      fluxbox \
      x11vnc \
      wget \
      unzip \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Download and install auto-mcs
ARG AUTO_MCS_VERSION=2.3
ENV AUTO_MCS_ASSET=auto-mcs-linux-${AUTO_MCS_VERSION}.zip
RUN wget -O /tmp/${AUTO_MCS_ASSET} \
      https://github.com/macarooni-man/auto-mcs/releases/download/v${AUTO_MCS_VERSION}/${AUTO_MCS_ASSET} && \
    unzip /tmp/${AUTO_MCS_ASSET} -d /opt/auto-mcs && \
    rm /tmp/${AUTO_MCS_ASSET} && \
    chmod +x /opt/auto-mcs/auto-mcs

# Add auto-mcs to PATH
ENV PATH="/opt/auto-mcs:${PATH}"

# Copy the new start.sh into the image
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose the VNC port
EXPOSE 5900

# Run our startup script
CMD ["/start.sh"]
