#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

./scripts/render-seccomp-profile.sh --check

if ! id -nG | tr ' ' '\n' | grep -qx docker; then
  echo "ERROR: Your user is not in the docker group, so this lab cannot access Docker."
  echo "Run: sudo usermod -aG docker \$USER"
  echo "Then log out and back in, or run: newgrp docker"
  exit 1
fi

docker compose run --rm --no-deps falco \
  /usr/bin/falco --dry-run \
  -r /etc/falco/rules.d/ebpf-safety-rules.yaml
