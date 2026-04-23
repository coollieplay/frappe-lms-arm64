ARG FRAPPE_BRANCH=version-16

FROM frappe/build:${FRAPPE_BRANCH} AS builder

ARG FRAPPE_BRANCH=version-16
ARG FRAPPE_PATH=https://github.com/frappe/frappe

USER frappe

RUN --mount=type=secret,id=apps_json,target=/opt/frappe/apps.json,uid=1000,gid=1000 \
  export APP_INSTALL_ARGS="" && \
  if [ -f /opt/frappe/apps.json ] && [ -s /opt/frappe/apps.json ]; then \
    export APP_INSTALL_ARGS="--apps_path=/opt/frappe/apps.json"; \
  fi && \
  bench init ${APP_INSTALL_ARGS}\
    --frappe-branch=${FRAPPE_BRANCH} \
    --frappe-path=${FRAPPE_PATH} \
    --no-procfile \
    --no-backups \
    --skip-redis-config-generation \
    --verbose \
    /home/frappe/frappe-bench && \
  cd /home/frappe/frappe-bench && \
  echo "{}" > sites/common_site_config.json && \
  find apps -mindepth 1 -path "*/.git" | xargs rm -fr

# Patch LMS frontend source: rename "Questions" → "Discussions" in the lesson panel,
# then recompile the Vue frontend with yarn (bench build calls `yarn run production`
# which LMS does not support — the app uses Vite directly via `yarn build`).
RUN cd /home/frappe/frappe-bench && \
  LESSON_VUE="apps/lms/frontend/src/pages/Lesson.vue" && \
  if [ -f "$LESSON_VUE" ]; then \
    sed -i "s|:title=\"'Questions'\"|:title=\"'Discussions'\"|g" "$LESSON_VUE" && \
    sed -i "s|__('Ask a question to get help from the community\.')|__('Start a discussion to get help from the community.')|g" "$LESSON_VUE" && \
    sed -i "s|MessageCircleQuestion|MessageCircle|g" "$LESSON_VUE" && \
    echo "Patched Lesson.vue: Questions → Discussions"; \
  else \
    echo "WARNING: Lesson.vue not found at $LESSON_VUE"; \
  fi && \
  echo '{"socketio_port":9000}' > sites/common_site_config.json && \
  cd apps/lms/frontend && \
  yarn build && \
  cd /home/frappe/frappe-bench && \
  echo "{}" > sites/common_site_config.json && \
  cp -r apps/lms/lms/public/frontend/. sites/assets/lms/frontend/

# Sync _lms.html with the actual built frontend hash.
# bench init runs bench build which compiles the Vue frontend to sites/assets/lms/,
# generating a new content-hashed index.html. The www template must match or the
# browser will request a JS file that no longer exists (404).
RUN cd /home/frappe/frappe-bench && \
  FRONTEND_INDEX="sites/assets/lms/frontend/index.html" && \
  LMS_TEMPLATE="apps/lms/lms/www/_lms.html" && \
  if [ -f "$FRONTEND_INDEX" ] && [ -f "$LMS_TEMPLATE" ]; then \
    JS=$(grep -o 'src="/assets/lms/frontend/assets/index-[^"]*\.js"' "$FRONTEND_INDEX" | grep -o 'index-[^"]*\.js' | head -1) && \
    CSS=$(grep -o 'href="/assets/lms/frontend/assets/index-[^"]*\.css"' "$FRONTEND_INDEX" | grep -o 'index-[^"]*\.css' | head -1) && \
    sed -i "s|index-[A-Za-z0-9_-]*\.js|${JS}|g" "$LMS_TEMPLATE" && \
    sed -i "s|index-[A-Za-z0-9_-]*\.css|${CSS}|g" "$LMS_TEMPLATE" && \
    echo "Synced _lms.html: JS=${JS} CSS=${CSS}"; \
  else \
    echo "WARNING: Could not sync _lms.html (frontend index or template not found)"; \
  fi

FROM frappe/base:${FRAPPE_BRANCH} AS backend

ARG VERSION=dev
ARG BUILD_DATE

LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.title="frappe-lms-arm64"
LABEL org.opencontainers.image.description="Frappe LMS native ARM64 image"

USER frappe

COPY --from=builder --chown=frappe:frappe /home/frappe/frappe-bench /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

VOLUME [ \
  "/home/frappe/frappe-bench/sites", \
  "/home/frappe/frappe-bench/logs" \
]

CMD [ \
  "/home/frappe/frappe-bench/env/bin/gunicorn", \
  "--chdir=/home/frappe/frappe-bench/sites", \
  "--bind=0.0.0.0:8000", \
  "--threads=4", \
  "--workers=4", \
  "--worker-class=gthread", \
  "--worker-tmp-dir=/dev/shm", \
  "--timeout=120", \
  "--preload", \
  "frappe.app:application" \
]
