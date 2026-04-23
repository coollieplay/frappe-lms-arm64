# Changelog

All image builds are tagged as `frappe-lms:arm64-vX.Y.Z`.

Format: **MAJOR** = Frappe version bump · **MINOR** = app version bump · **PATCH** = config/bug fix

---

## [1.0.4] - 2026-04-23

### Fixed
- Vite build failed because `common_site_config.json` was empty (`{}`), causing Rollup
  to reject the `socketio_port` named import in `src/socket.js`. Now temporarily writes
  `{"socketio_port":9000}` before `yarn build` and restores `{}` afterwards.

---

## [1.0.3] - 2026-04-23

### Fixed
- `bench build --app lms` calls `yarn run production` which LMS does not have (it uses
  Vite directly). Replaced with `yarn build` in `apps/lms/frontend/` followed by an
  explicit `cp` to `sites/assets/lms/frontend/`. The Discussions rename is now correctly
  compiled into the image-baked JS bundle.

---

## [1.0.2] - 2026-04-23

### Changed
- Renamed "Questions" to "Discussions" in the course lesson panel (`Lesson.vue`).
  Updated tab title, empty-state text, and icon (`MessageCircleQuestion` →
  `MessageCircle`) to be consistent with the Discussions label used in Batch pages.

---

## [1.0.1] - 2026-04-23

### Fixed
- `_lms.html` www template now auto-synced with the actual Vite build hash at image
  build time. Previously the template hardcoded an old hash (`CaTvf8pX`) while the
  built assets used a different hash (`DK_FSy-J`), causing a 404 on the frontend JS
  bundle for every visitor.
- Configurator command now uses absolute paths (`/home/frappe/frappe-bench/apps/`)
  so `apps.txt` is always written correctly on container restart.
- Added `Cache-Control: no-store` headers for `index.html` and `registerSW.js` via
  nginx to prevent stale cached pages after future deployments.

### Added
- This CHANGELOG and versioning system.
- `build.sh` for reproducible versioned builds.
- `deploy.sh` for deploying or rolling back to any tagged version.

---

## [1.0.0] - 2026-04-22

### Initial
- Native ARM64 image built from `frappe/build:version-16`.
- Apps: `frappe` (v16), `lms` (main), `payments` (develop).
- Deployed with Traefik TLS at `lms.coollie.top`.
