#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="/home/ubuntu/lms_prod-compose.yml"
IMAGE_NAME="frappe-lms"

TARGET_VERSION="${1:-}"

if [ -z "${TARGET_VERSION}" ]; then
  TARGET_VERSION=$(cat "${SCRIPT_DIR}/VERSION" | tr -d '[:space:]')
  echo "No version specified, deploying current VERSION: v${TARGET_VERSION}"
fi

TAG_VERSIONED="${IMAGE_NAME}:arm64-v${TARGET_VERSION}"
TAG_LATEST="${IMAGE_NAME}:arm64"

echo "============================================"
echo "  Deploying frappe-lms v${TARGET_VERSION}"
echo "============================================"
echo ""

# Verify the target image exists
if ! docker image inspect "${TAG_VERSIONED}" &>/dev/null; then
  echo "ERROR: Image ${TAG_VERSIONED} not found."
  echo ""
  echo "Available versions:"
  docker images "${IMAGE_NAME}" --format "  {{.Tag}}\t{{.ID}}\t{{.CreatedAt}}" | sort
  exit 1
fi

echo "Promoting ${TAG_VERSIONED} → ${TAG_LATEST}"
docker tag "${TAG_VERSIONED}" "${TAG_LATEST}"

echo "Recreating all containers with new image..."
docker compose -f "${COMPOSE_FILE}" up -d --force-recreate \
  backend frontend websocket queue-long queue-short scheduler

echo ""
echo "Running database migration..."
docker compose -f "${COMPOSE_FILE}" exec -T backend \
  bench --site all migrate 2>&1 | tail -5

echo ""
echo "Clearing cache..."
docker compose -f "${COMPOSE_FILE}" exec -T backend \
  bench --site all clear-cache 2>&1

echo ""
echo "============================================"
echo "  Deployed v${TARGET_VERSION} successfully"
echo "============================================"
echo ""
docker ps --filter name=lms_prod --format "  {{.Names}}\t{{.Status}}"
