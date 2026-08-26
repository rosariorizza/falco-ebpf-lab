#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_PROFILE="$ROOT_DIR/tester/seccomp/default-moby.json"
LAB_PATCH="$ROOT_DIR/tester/seccomp/lab.patch"
OUTPUT_PROFILE="$ROOT_DIR/tester/seccomp-profile.json"

command -v patch >/dev/null 2>&1 || {
  printf 'ERROR: patch is required to render the seccomp profile.\n' >&2
  exit 1
}

temporary_profile="$(mktemp)"
trap 'rm -f "$temporary_profile"' EXIT

patch --quiet --output="$temporary_profile" "$BASE_PROFILE" "$LAB_PATCH"

case "${1:---write}" in
  --write)
    install -m 0644 "$temporary_profile" "$OUTPUT_PROFILE"
    ;;
  --check)
    if ! cmp --silent "$temporary_profile" "$OUTPUT_PROFILE"; then
      printf 'ERROR: %s is not generated from the Moby profile and lab patch.\n' \
        "$OUTPUT_PROFILE" >&2
      printf 'Run ./scripts/render-seccomp-profile.sh to regenerate it.\n' >&2
      exit 1
    fi
    ;;
  *)
    printf 'Usage: %s [--write|--check]\n' "${0##*/}" >&2
    exit 2
    ;;
esac
