# How to Deploy auto-mcs + Guacamole Stack

This guide covers everything you need to deploy the **auto-mcs** GUI inside Docker and expose it securely in your browser using **Apache Guacamole**. Follow the steps below to configure, customize, and launch your stack with ease.

---

## 📦 0. Prerequisites

* **Docker** (≥20.x) and **Docker Compose** (v2) installed, or **Portainer** with Stack support
* **Git** to clone the repository
* A Unix-like shell (Linux, macOS) or Windows WSL
* Optional but recommended: `envsubst` (part of `gettext`) for template rendering

---

## 🗂️ 1. Clone the Repository

```bash
git clone https://your.repo.url/auto-mcs-guacamole.git
cd auto-mcs-guacamole
```

Your project root contains:

```
├── Dockerfile                # Builds auto-mcs + Fluxbox + x11vnc container
├── docker-compose.yml        # Defines services: automcs, guacd, guacamole
├── guacamole/
│   └── user-mapping.xml.tpl  # Template for Guacamole users and VNC connection
├── Makefile                  # (Optional) helper commands for build and deploy
├── .env.example              # Sample environment variables
└── README.md                 # This deployment guide
```

---

## ⚙️ 2. Configure Environment Variables

Copy the sample file and edit values:

```bash
cp .env.example .env
nano .env
```

Set at minimum:

```dotenv
VNC_PASSWORD=YourSecureVncPass          # Password for x11vnc and Guacamole VNC
GUAC_ADMIN_USER=admin                   # Guacamole login username
GUAC_ADMIN_PASS=YourGuacLoginPass       # Guacamole login password
COMPOSE_PROJECT_NAME=automcs            # Prefix for Docker Compose resources
COMPOSE_HTTP_TIMEOUT=200                # Increase if building large images
```

> **Tip:** You can store `.env` outside version control for security.

---

## 📝 3. Render Guacamole User Mapping

We use a template (`user-mapping.xml.tpl`) with placeholders. At runtime, `envsubst` replaces variables:

```bash
envsubst < guacamole/user-mapping.xml.tpl > guacamole/user-mapping.xml
```

**Example template (`guacamole/user-mapping.xml.tpl`):**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<user-mapping>
  <authorize username="${GUAC_ADMIN_USER}" password="${GUAC_ADMIN_PASS}">
    <connection name="auto-mcs">
      <protocol>vnc</protocol>
      <param name="hostname">automcs</param>
      <param name="port">5900</param>
      <param name="password">${VNC_PASSWORD}</param>
    </connection>
  </authorize>
  <!--
  Add more users by copying the block above and changing USER/PASS.
  <authorize username="user2" password="SecondPass">
    ...
  </authorize>
  -->
</user-mapping>
```

> **Note:** This step can be automated in a Makefile or entrypoint script.

---

## 🔧 4. Review `docker-compose.yml`

Key sections you may want to adjust:

```yaml
version: '3.8'
services:
  automcs:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: ${COMPOSE_PROJECT_NAME}_automcs
    environment:
      - VNC_PASSWORD=${VNC_PASSWORD}
    volumes:
      - auto-mcs_data:/data
    expose:
      - "5900"
    restart: unless-stopped

  guacd:
    image: guacamole/guacd:latest
    container_name: ${COMPOSE_PROJECT_NAME}_guacd
    restart: unless-stopped

  guacamole:
    image: guacamole/guacamole:latest
    container_name: ${COMPOSE_PROJECT_NAME}_guacamole
    depends_on:
      - guacd
      - automcs
    environment:
      GUACD_HOSTNAME: guacd
      GUACD_PORT: 4822
    ports:
      - "9000:8080"
    volumes:
      - guacamole_config:/etc/guacamole
    restart: unless-stopped

volumes:
  auto-mcs_data:
  guacamole_config:

networks:
  default:
    name: ${COMPOSE_PROJECT_NAME}_network
```

* **Project Name**: Controls container and network names via `COMPOSE_PROJECT_NAME`.
* **Volumes**: Use named volumes for portability; switch to bind mounts if you need direct host access.
* **Ports**: Default Guacamole UI on `9000`; change if occupied.

---

## ▶️ 5. Launch the Stack

### A) Command-Line

1. Render user-mapping:

   ```bash
   envsubst < guacamole/user-mapping.xml.tpl > guacamole/user-mapping.xml
   ```
2. Start services:

   ```bash
   docker-compose up -d --build
   ```
3. Check status:

   ```bash
   docker-compose ps
   ```

### B) Portainer

1. **Stacks → Add stack** → **Upload**
2. Select the entire project folder (contains both `docker-compose.yml` and `Dockerfile`).
3. Fill in environment variables (`VNC_PASSWORD`, `GUAC_ADMIN_PASS`, etc.)
4. Deploy.

> **Pro Tip:** Use Git method in Portainer to auto-pull updates from your repo.

---

## 🌐 6. Access & Usage

* Open browser at `http://<HOST_IP>:9000`
* **Login**: `GUAC_ADMIN_USER` / `GUAC_ADMIN_PASS`
* Click on **auto-mcs** to launch the GUI inside your browser.

---

## 🔄 7. Updates & Maintenance

* **Upgrade auto-mcs**: Change `AUTO_MCS_VERSION` arg in Dockerfile, then rebuild:

  ```bash
  ```

docker-compose build automcs
docker-compose up -d

````
- **Add users**: Edit `guacamole/user-mapping.xml.tpl`, rerun `envsubst` and restart `guacamole`:
  ```bash
envsubst < guacamole/user-mapping.xml.tpl > guacamole/user-mapping.xml
docker-compose restart guacamole
````

* **SSL/TLS**: Place a reverse-proxy (e.g., Traefik, Nginx) in front of `guacamole` to secure HTTP to HTTPS.

---

## 🛠️ 8. Troubleshooting

* **Build errors**: Verify `docker-compose.yml` and `Dockerfile` are in the same directory.
* **Template not rendered**: Ensure `envsubst` is installed and `.env` is loaded.
* **Connection failed in Guacamole**: Check logs:

  ```bash
  ```

docker-compose logs guacd
docker-compose logs guacamole
docker-compose logs automcs

````

---

## 🚀 9. Quick Start with Makefile

If you have a `Makefile` in the repo, you can simplify commands:

```makefile
.PHONY: render up down logs

render:
	@envsubst < guacamole/user-mapping.xml.tpl > guacamole/user-mapping.xml

up: render
	docker-compose up -d --build

down:
	docker-compose down

logs:
	docker-compose logs -f
````

* `make up` → renders template, builds images, and starts services
* `make logs` → tails all logs

---

Congratulations! Your **auto-mcs + Guacamole** environment is now fully deployed and ready to use. 🎉
