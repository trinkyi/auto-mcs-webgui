#!/usr/bin/env bash
set -euo pipefail

# 1) Load config
if [[ ! -f .env ]]; then
  echo "ERROR: .env not found!" >&2
  exit 1
fi
source .env

# 2) Prepare dirs
mkdir -p extensions mysql-init

# 3) Download & extract the MySQL auth extension JAR
echo ">>> Fetching Guacamole JDBC auth extension (MySQL)..."
curl -fsSL "https://downloads.apache.org/guacamole/${GUACAMOLE_VERSION}/binary/guacamole-auth-jdbc-${GUACAMOLE_VERSION}.tar.gz" \
  | tar xz \
      --wildcards \
      --strip-components=2 \
      -C extensions \
      "*/mysql/guacamole-auth-jdbc-mysql-${GUACAMOLE_VERSION}.jar"

# 4) Generate full schema SQL via initdb.sh
echo ">>> Generating initdb.sql via Guacamole initdb.sh"
docker run --rm \
  guacamole/guacamole:"${GUACAMOLE_VERSION}" \
  /opt/guacamole/bin/initdb.sh --mysql \
  > mysql-init/initdb.sql

# 5) Append initial admin user
echo ">>> Appending initial admin user (${ADMIN_USERNAME})"
SALT=$(openssl rand -hex 16 | tr '[:lower:]' '[:upper:]')
HASH=$(printf '%s%s' "${ADMIN_PASSWORD}" "${SALT}" \
       | sha256sum | awk '{print $1}')

cat >> mysql-init/initdb.sql <<EOF
INSERT INTO guacamole_user
  (username, password_salt, password_hash, password_date, disabled)
VALUES
  ('${ADMIN_USERNAME}', UNHEX('${SALT}'), UNHEX('${HASH}'), NOW(), FALSE);

INSERT INTO guacamole_user_property
  (user_id, property_name, property_value)
VALUES
  (
    (SELECT user_id FROM guacamole_user WHERE username='${ADMIN_USERNAME}'),
    'password-encoding',
    'SHA-256'
  ),
  (
    (SELECT user_id FROM guacamole_user WHERE username='${ADMIN_USERNAME}'),
    'password-salt',
    '${SALT}'
  );
EOF

echo "✅ Pre-installation complete."
echo "  – extensions/guacamole-auth-jdbc-mysql-${GUACAMOLE_VERSION}.jar"
echo "  – mysql-init/initdb.sql (schema + admin user)"
