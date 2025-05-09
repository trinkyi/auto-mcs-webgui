#── 0. Build-time args ─────────────────────────
ARG DEBIAN_FRONTEND=noninteractive

FROM debian:bookworm-slim

ARG AUTO_MCS_URL

#── 1. Install dependencies ────────────────────
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      xvfb fluxbox x11vnc wget unzip ca-certificates tini \
 && rm -rf /var/lib/apt/lists/*

#── 2. Fetch & install auto-mcs ─────────────────
# create install dir and unzip as root
RUN mkdir -p /opt/auto-mcs \
 && wget -O /tmp/auto-mcs.zip "${AUTO_MCS_URL}" \
 && unzip /tmp/auto-mcs.zip -d /opt/auto-mcs \
 && rm /tmp/auto-mcs.zip \
 && chmod +x /opt/auto-mcs/auto-mcs

# make auto-mcs binary available on PATH
ENV PATH="/opt/auto-mcs:${PATH}"

#── 3. Copy & prepare startup script ───────────

COPY start.sh /start.sh
RUN chmod +x /start.sh

#── 4. Expose & healthcheck ────────────────────
# VNC_PORT (default 5900) is pulled from your .env at runtime
EXPOSE 5900
HEALTHCHECK --interval=30s --timeout=3s \
  CMD bash -c "echo >/dev/tcp/localhost/5900" || exit 1

#── 5. Entrypoint ───────────────────────────────
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/start.sh"]
