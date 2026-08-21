#!/usr/bin/env bash
set -euo pipefail

failures=0
check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf 'PASS  %s\n' "$label"
  else
    printf 'FAIL  %s\n' "$label"
    failures=$((failures + 1))
  fi
}

check 'Linux host' test "$(uname -s)" = Linux
check 'Docker CLI' command -v docker
if command -v docker >/dev/null 2>&1; then
  check 'Docker daemon reachable' docker info
  check 'Docker Compose v2' docker compose version
else
  printf 'SKIP  Docker daemon reachable\n'
  printf 'SKIP  Docker Compose v2\n'
fi

if [[ -r /sys/kernel/btf/vmlinux ]]; then
  printf 'PASS  Kernel BTF available: /sys/kernel/btf/vmlinux\n'
else
  printf 'WARN  Kernel BTF not found at /sys/kernel/btf/vmlinux\n'
fi

if [[ -r /proc/sys/kernel/unprivileged_bpf_disabled ]]; then
  printf 'INFO  kernel.unprivileged_bpf_disabled=%s\n' "$(cat /proc/sys/kernel/unprivileged_bpf_disabled)"
fi

printf 'INFO  kernel=%s\n' "$(uname -r)"

if (( failures > 0 )); then
  exit 1
fi
