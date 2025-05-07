#!/usr/bin/env bash
set -euo pipefail

# 1) .env einlesen
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "ERROR: .env not found"
  exit 1
fi

# 2) Docker-Image bauen
docker build \
  --build-arg AUTO_MCS_VERSION="${AUTO_MCS_VERSION}" \
  --build-arg AUTO_MCS_ASSET="${AUTO_MCS_ASSET}" \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" .

# 3) XML aus Template generieren
if [ -f "${TEMPLATE_FILE}" ]; then
  echo "Rendering ${TEMPLATE_FILE} → ${OUTPUT_FILE}"
  envsubst < "${TEMPLATE_FILE}" > "${OUTPUT_FILE}"
  if [ "${REMOVE_TEMPLATE}" = "true" ]; then
    echo "Removing template ${TEMPLATE_FILE}"
    rm "${TEMPLATE_FILE}"
  fi
else
  echo "WARN: Template ${TEMPLATE_FILE} not found, skipping rendering"
fi

echo "Done. Du kannst jetzt mit docker-compose up -d starten."
