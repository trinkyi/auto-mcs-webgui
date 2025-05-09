# Dockerfile zur Bereitstellung einer leichten Desktop-Umgebung mit VNC
# "Linux Lite" wird hier annähernd durch Ubuntu + XFCE ersetzt, da kein offizielles Linux Lite Base-Image verfügbar ist.

FROM ubuntu:22.04

# Non-interactive und Schweizer Zeitzone
ENV DEBIAN_FRONTEND=noninteractive TZ=Europe/Zurich

# Desktop-Umgebung (XFCE) und VNC-Server installieren
RUN apt-get update && \
    apt-get install -y xfce4 xfce4-goodies tightvncserver dbus-x11 x11-xserver-utils && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Benutzer für VNC-Zugriff anlegen
RUN useradd -m -s /bin/bash vncuser && \
    echo "vncuser:password" | chpasswd

USER vncuser
WORKDIR /home/vncuser

# VNC-Passwort konfigurieren (Standard: "password")
RUN mkdir -p /home/vncuser/.vnc && \
    echo "password" | vncpasswd -f > /home/vncuser/.vnc/passwd && \
    chmod 600 /home/vncuser/.vnc/passwd

# Startup-Skript für XFCE einrichten
RUN printf "#!/bin/bash\nxrdb $HOME/.Xresources\nstartxfce4 &\n" > /home/vncuser/.vnc/xstartup && \
    chmod +x /home/vncuser/.vnc/xstartup

# VNC-Port freigeben
EXPOSE 5900

# VNC-Server beim Containerstart auf Display :0 starten
CMD ["vncserver", ":0", "-geometry", "1280x800", "-depth", "24", "-fg"]
