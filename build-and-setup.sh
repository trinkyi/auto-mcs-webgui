#!/usr/bin/env bash
set -euo pipefail

# 0) Clean up any old containers, networks, volumes
echo "🧹 Cleaning up previous stack…"
docker-compose down --volumes --remove-orphans || true

# 1) Load parameters
if [[ -f .env ]]; then
  export $(grep -v '^\s*#' .env | xargs)
else
  echo "❌ .env not found"; exit 1
fi

# 2) Build the Auto-MCS image
echo "🔨 Building image ${IMAGE_NAME}:${IMAGE_TAG}…"
docker build \
  --build-arg AUTO_MCS_VERSION="${AUTO_MCS_VERSION}" \
  --build-arg AUTO_MCS_ASSET="${AUTO_MCS_ASSET}" \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" .

# 3) Start only MySQL and guacd
echo "🚀 Starting guacamole-db & guacd…"
docker-compose up -d guacamole-db guacd

# 4) Wait for MySQL to be ready
echo -n "⏳ Waiting for MySQL (${MYSQL_DATABASE})…"
until docker exec guacamole-db \
       mysqladmin ping -h "localhost" \
         -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent &> /dev/null; do
  printf "."
  sleep 2
done
echo " ready!"

# 5) Generate the Guacamole schema SQL via plain docker run
#    (uses the official guacamole/guacamole image, so no compose magic)
PROJECT=$(basename "$PWD")
NET="${PROJECT}_guacnet"
echo "📄 Generating schema SQL with guacamole/guacamole:initdb…"
docker run --rm \
  --network "${NET}" \
  -e MYSQL_HOSTNAME=guacamole-db \
  -e MYSQL_PORT=3306 \
  -e MYSQL_DATABASE="${MYSQL_DATABASE}" \
  -e MYSQL_USER="${MYSQL_USER}" \
  -e MYSQL_PASSWORD="${MYSQL_PASSWORD}" \
  guacamole/guacamole:latest \
  /opt/guacamole/bin/initdb.sh mysql \
  > initdb.sql

echo "🐬 Importing schema into guacamole-db…"
docker exec -i guacamole-db \
  mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" \
  < initdb.sql

rm initdb.sql

# 6) Start the remaining services
echo "📦 Starting guacamole & automcs…"
docker-compose up -d guacamole automcs

echo "✅ All services are up!"
echo "   • Guacamole → http://localhost:9000 (default: guacadmin/guacadmin)"
echo "   • VNC       → localhost:5900 (password in VNC_PASSWORD)"
