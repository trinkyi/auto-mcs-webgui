#!/usr/bin/env bash
set -euo pipefail

# Load all variables from configuration.conf
source configuration.conf

# Create directories for extension JAR, JDBC driver, and SQL init
mkdir -p extensions lib mysql-init                                  :contentReference[oaicite:0]{index=0}

########################################
# 1) Download Guacamole JDBC extension
########################################
JDBC_URL="https://downloads.apache.org/guacamole/${GUACAMOLE_VERSION}/binary/guacamole-auth-jdbc-${GUACAMOLE_VERSION}.tar.gz"
echo "Fetching JDBC auth extension from ${JDBC_URL}"
curl -sL "${JDBC_URL}" \
  | tar xz \
      --wildcards \
      --strip-components=2 \
      -C extensions \
      '*/mysql/guacamole-auth-jdbc-mysql-'"${GUACAMOLE_VERSION}"'.jar'  :contentReference[oaicite:1]{index=1}

########################################
# 2) Download MySQL Connector/J driver
########################################
CONNECTOR_URL="https://repo1.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar"
echo "Downloading MySQL Connector/J from ${CONNECTOR_URL}"
curl -sL "${CONNECTOR_URL}" \
  -o lib/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar        :contentReference[oaicite:2]{index=2}

########################################
# 3) Generate combined schema SQL
########################################
echo "Generating database initialization SQL via initdb.sh"
docker run --rm \
  guacamole/guacamole:"${GUACAMOLE_VERSION}" \
  /opt/guacamole/bin/initdb.sh --mysql > mysql-init/initdb.sql   :contentReference[oaicite:3]{index=3}

########################################
# 4) Create initial admin user SQL
########################################
echo "Generating initial Guacamole admin user SQL"
SALT=$(openssl rand -hex 16)                                      :contentReference[oaicite:4]{index=4}
HASH=$(printf '%s%s' "${SALT}" "${ADMIN_PASSWORD}" | sha256sum | awk '{print $1}')  :contentReference[oaicite:5]{index=5}

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
EOF                                                                 :contentReference[oaicite:6]{index=6}

echo "Pre-installation complete – SQL files in mysql-init/, JARs in extensions/ and lib/"
