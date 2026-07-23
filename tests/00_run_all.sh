#!/usr/bin/env bash
set -euo pipefail

for test_file in /tests/[0-9][0-9]_*.sh; do
  case "$(basename "$test_file")" in
    00_run_all.sh) continue ;;
  esac
  printf '\n===== %s =====\n' "$(basename "$test_file")"
  bash "$test_file"
done
