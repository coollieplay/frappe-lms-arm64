# frappe-lms-arm64

Native ARM64 Docker image for [Frappe LMS](https://github.com/frappe/lms), built on `frappe/build:version-16`.

## Why

The official `ghcr.io/frappe/lms` image is AMD64-only. Running it on ARM64 servers requires QEMU emulation, which causes high CPU load (~4.3 load avg on a 4-core machine). This build produces a native ARM64 image, dropping idle CPU to ~0.5.

## Build

```bash
# Clone frappe_docker
git clone https://github.com/frappe/frappe_docker
cd frappe_docker

# Build native ARM64 image
docker build \
  --platform linux/arm64 \
  --secret id=apps_json,src=apps.json \
  --build-arg FRAPPE_BRANCH=version-16 \
  -t frappe-lms:arm64 \
  -f images/layered/Containerfile \
  .
```

## apps.json

```json
[
  {
    "url": "https://github.com/frappe/payments",
    "branch": "develop"
  },
  {
    "url": "https://github.com/frappe/lms",
    "branch": "main"
  }
]
```

## Notes

- `payments` must use branch `develop` (no `main` branch exists)
- Built with Frappe `version-16` and Python 3.14
- Tested on Oracle Cloud ARM64 (aarch64) instance
