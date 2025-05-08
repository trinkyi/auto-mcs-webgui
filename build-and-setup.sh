#!/usr/bin/env bash
set -euo pipefail

# 1) Load parameters from .env
if [[ -f .env ]]; then
  export $(grep -v '^\s*#' .env | xargs)
else
  echo "ERROR: .env not found"; exit 1
fi

# 2) Build the Auto-MCS image
echo "Building image ${IMAGE_NAME}:${IMAGE_TAG}…"
docker build \
  --build-arg AUTO_MCS_VERSION="${AUTO_MCS_VERSION}" \
  --build-arg AUTO_MCS_ASSET="${AUTO_MCS_ASSET}" \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" .

# 3) Start only MySQL and guacd
echo "Starting MySQL and guacd…"
docker-compose up -d guacamole-db guacd

# 4) Wait for MySQL to be ready
echo -n "Waiting for MySQL (${MYSQL_DATABASE}) to become ready"
until docker exec guacamole-db \
       mysqladmin ping -h "localhost" \
         -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent &> /dev/null; do
  printf "."
  sleep 2
done
echo " OK"

# 5) Generate Guacamole schema and import
echo "Generating Guacamole schema SQL…"
docker-compose run --rm guacamole \
  /opt/guacamole/bin/initdb.sh mysql > initdb.sql

echo "Importing schema into guacamole-db…"
docker exec -i guacamole-db \
  mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" \
  < initdb.sql
rm initdb.sql

# 6) Bring up the rest of the stack
echo "Bringing up guacamole + automcs…"
docker-compose up -d guacamole automcs

echo "All services are up!"
echo " • Guacamole → http://localhost:9000 (default login: guacadmin/guacadmin)"
echo " • VNC → localhost:5900 (password from VNC_PASSWORD)"
