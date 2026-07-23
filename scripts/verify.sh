#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
mkdir -p evidence

printf 'Starting Falco and the tester container...\n'
docker compose up -d --build

printf 'Waiting for the Falco syscall source to open...\n'
ready=0
for _ in $(seq 1 60); do
  if ! docker compose ps --status running --services | grep -qx falco; then
    sleep 1
    continue
  fi
  if docker compose logs --no-color falco 2>/dev/null | grep -Eq "Opening 'syscall' source with modern BPF probe|Enabled event sources:.*syscall"; then
    ready=1
    break
  fi
  sleep 1
done

if (( ready == 0 )); then
  docker compose logs --no-color falco | tee evidence/falco.log
  printf 'Falco did not become ready. See evidence/falco.log.\n' >&2
  exit 1
fi
sleep 2

: > evidence/test-output.log
for test_file in tests/[0-9][0-9]_*.sh; do
  case "$(basename "$test_file")" in
    00_run_all.sh) continue ;;
  esac
  printf '\n===== %s =====\n' "$(basename "$test_file")" | tee -a evidence/test-output.log
  docker compose exec -T tester bash "/tests/$(basename "$test_file")" 2>&1 | tee -a evidence/test-output.log
done

sleep 2
docker compose logs --no-color falco > evidence/falco.log

expected_rules=(
  "Unexpected eBPF Program Load Or Attach"
  "eBPF Program Load From Container"
  "Suspicious BPF Object Pin Or Get"
  "BPF Tool Executed By Unusual Process"
  "Kernel Module Load Attempt"
  "Capability Set Modification"
  "Sensitive Proc Kernel Write"
  "BPF Filesystem Access"
)

report="evidence/verification-report.md"
{
  printf '# Falco rule verification report\n\n'
  printf '| Rule | Result |\n'
  printf '|---|---|\n'
} > "$report"

failures=0
for rule_name in "${expected_rules[@]}"; do
  marker="[RULE=${rule_name}]"
  if grep -Fq "$marker" evidence/falco.log; then
    printf '| `%s` | PASS |\n' "$rule_name" >> "$report"
    printf 'PASS: %s\n' "$rule_name"
  else
    printf '| `%s` | FAIL |\n' "$rule_name" >> "$report"
    printf 'FAIL: %s\n' "$rule_name" >&2
    failures=$((failures + 1))
  fi
done

{
  printf '\nArtifacts:\n\n'
  printf -- '- `falco.log`: complete Falco output.\n'
  printf -- '- `test-output.log`: output produced by every test script.\n'
} >> "$report"

printf '\nReport written to %s\n' "$report"
if (( failures > 0 )); then
  exit 1
fi
