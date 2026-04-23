#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAPPE_DOCKER_DIR="/home/ubuntu/lms/frappe_docker"
FRAPPE_BRANCH="version-16"
IMAGE_NAME="frappe-lms"

VERSION=$(cat "${SCRIPT_DIR}/VERSION" | tr -d '[:space:]')
BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
DATE_TAG=$(date -u +%Y.%m.%d)

TAG_LATEST="${IMAGE_NAME}:arm64"
TAG_VERSIONED="${IMAGE_NAME}:arm64-v${VERSION}"
TAG_DATED="${IMAGE_NAME}:arm64-${DATE_TAG}"

echo "============================================"
echo "  Building frappe-lms ARM64 image"
echo "  Version : v${VERSION}"
echo "  Date    : ${DATE_TAG}"
echo "  Branch  : ${FRAPPE_BRANCH}"
echo "============================================"
echo ""

# Validate build context exists
if [ ! -d "${FRAPPE_DOCKER_DIR}" ]; then
  echo "ERROR: frappe_docker not found at ${FRAPPE_DOCKER_DIR}"
  echo "Run: git clone https://github.com/frappe/frappe_docker ${FRAPPE_DOCKER_DIR}"
  exit 1
fi

# Warn if version tag already exists
if docker image inspect "${TAG_VERSIONED}" &>/dev/null; then
  echo "WARNING: ${TAG_VERSIONED} already exists. Overwriting."
  echo "Press Ctrl+C within 5 seconds to cancel..."
  sleep 5
fi

docker build \
  --platform linux/arm64 \
  --secret id=apps_json,src="${SCRIPT_DIR}/apps.json" \
  --build-arg FRAPPE_BRANCH="${FRAPPE_BRANCH}" \
  --build-arg VERSION="${VERSION}" \
  --build-arg BUILD_DATE="${BUILD_DATE}" \
  --tag "${TAG_LATEST}" \
  --tag "${TAG_VERSIONED}" \
  --tag "${TAG_DATED}" \
  --file "${SCRIPT_DIR}/Containerfile" \
  "${FRAPPE_DOCKER_DIR}"

echo ""
echo "Build complete:"
echo "  ${TAG_LATEST}"
echo "  ${TAG_VERSIONED}"
echo "  ${TAG_DATED}"
echo ""
echo "Next steps:"
echo "  Deploy now : ${SCRIPT_DIR}/deploy.sh ${VERSION}"
echo "  Or rollback: ${SCRIPT_DIR}/deploy.sh 1.0.0"
