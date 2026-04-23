# Changelog

All image builds are tagged as `frappe-lms:arm64-vX.Y.Z`.

Format: **MAJOR** = Frappe version bump · **MINOR** = app version bump · **PATCH** = config/bug fix

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
