FROM debian:bookworm-slim@sha256:<digest>

#── Build-time args (mirroring config/app.conf)
ARG DEBIAN_FRONTEND=noninteractive
ARG GUI_USER
ARG GUI_GROUP
ARG GUI_UID
ARG GUI_GID
ARG AUTO_MCS_URL

#── Runtime env (from env_file)
# VNC_PASSWORD comes from your config; defaults to empty if not set
ENV VNC_PASSWORD="${VNC_PASSWORD}" \
    VNC_GEOMETRY=1920x1080 \
    VNC_DEPTH=24 \
    VNC_PORT=5900

#── 1. Install deps + tini
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      xvfb fluxbox x11vnc wget unzip ca-certificates tini \
 && rm -rf /var/lib/apt/lists/*

#── 2. Create non-root group & user
RUN groupadd --gid ${GUI_GID} ${GUI_GROUP} \
 && useradd --uid ${GUI_UID} \
            --gid ${GUI_GROUP} \
            --shell /bin/bash \
            --create-home \
            --home-dir /home/${GUI_USER} \
            ${GUI_USER}

USER ${GUI_USER}
WORKDIR /home/${GUI_USER}

#── 3. Fetch & install auto-mcs from CONFIGURED URL
RUN wget -O /tmp/auto-mcs.zip "${AUTO_MCS_URL}" \
 && unzip /tmp/auto-mcs.zip -d /opt/auto-mcs \
 && rm /tmp/auto-mcs.zip \
 && chmod +x /opt/auto-mcs/auto-mcs

ENV PATH="/opt/auto-mcs:${PATH}"

#── 4. Copy & mark your startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

#── 5. Expose, healthcheck & init
EXPOSE ${VNC_PORT}
HEALTHCHECK --interval=30s --timeout=3s \
  CMD nc -z localhost ${VNC_PORT} || exit 1

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/start.sh"]
