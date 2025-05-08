#!/usr/bin/env bash
set -euo pipefail

# Load your config variables
if [[ ! -f configuration.conf ]]; then
  echo "Error: configuration.conf not found!" >&2
  exit 1
fi
source configuration.conf

# Directories to populate
mkdir -p extensions mysql-init

########################################
# 1) Download the Guacamole JDBC .jar
########################################
JDBC_JAR=guacamole-auth-jdbc-mysql-${GUACAMOLE_VERSION}.jar
JDBC_URL="https://apache.org/dyn/closer.cgi/guacamole/${GUACAMOLE_VERSION}/binary/guacamole-auth-jdbc-mysql-${GUACAMOLE_VERSION}.tar.gz"

echo "Fetching JDBC extension from ${JDBC_URL}..."
curl -sL "${JDBC_URL}" \
  | tar xz --wildcards --strip-components=2 -C extensions '*/mysql/schema/*.jar'
mv extensions/*.jar extensions/${JDBC_JAR}
echo "  → Saved ${JDBC_JAR}"

########################################
# 2) Fetch the SQL schema
########################################
SCHEMA_URL="https://raw.githubusercontent.com/apache/guacamole-server/${GUACAMOLE_VERSION}/guacamole-auth-jdbc/modules/mysql/schema/001-create-schema.sql"
echo "Downloading schema DDL..."
curl -sL "${SCHEMA_URL}" > mysql-init/001-create-schema.sql
echo "  → Wrote mysql-init/001-create-schema.sql"

########################################
# 3) Generate admin user SQL
########################################
echo "Generating guacamole user SQL..."
# Use ADMIN_USERNAME and ADMIN_PASSWORD now
SALT=$(openssl rand -hex 16)
HASH=$(printf '%s%s' "${SALT}" "${ADMIN_PASSWORD}" \
       | sha256sum | awk '{print $1}')

cat > mysql-init/002-create-admin-user.sql <<EOF
USE \`${MYSQL_DB_NAME}\`;

INSERT INTO guacamole_user
  (username, password_salt, password_hash, password_date, disabled)
VALUES
  ('${ADMIN_USERNAME}', '${SALT}', UNHEX('${HASH}'), NOW(), FALSE);

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
echo "  → Wrote mysql-init/002-create-admin-user.sql"

echo "Pre-installation complete. You can now run: docker-compose up -d --build"
