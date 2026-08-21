#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'USAGE'
Usage: ./lab.sh <command> [argument]

Commands:
  doctor             Check host prerequisites.
  up                 Build and start Falco plus the tester.
  logs               Follow Falco alerts.
  shell              Open a Bash shell in the tester container.
  list               List available test scripts.
  run <script-name>  Run one test, for example 01_alert_unexpected_ebpf_program_load_or_attach.sh.
  test               Run all tests.
  verify             Run all tests and create evidence files.
  validate           Validate the Falco rules with --dry-run.
  down               Stop and remove the lab containers.
USAGE
}

require_docker() {
  command -v docker >/dev/null 2>&1 || {
    printf 'Docker is required.\n' >&2
    exit 1
  }
  docker compose version >/dev/null 2>&1 || {
    printf 'Docker Compose v2 is required.\n' >&2
    exit 1
  }
}

command_name="${1:-}"
case "$command_name" in
  doctor)
    exec ./scripts/doctor.sh
    ;;
  up)
    require_docker
    docker compose up -d --build
    ;;
  logs)
    require_docker
    docker compose logs -f falco
    ;;
  shell)
    require_docker
    docker compose exec tester bash
    ;;
  list)
    require_docker
    docker compose exec -T tester bash -lc 'find /tests -maxdepth 1 -type f -name "*.sh" -printf "%f\n" | sort'
    ;;
  run)
    require_docker
    test_name="${2:-}"
    if [[ -z "$test_name" || "$test_name" == */* ]]; then
      printf 'Pass a test filename from ./lab.sh list.\n' >&2
      exit 2
    fi
    docker compose exec -T tester bash "/tests/$test_name"
    ;;
  test)
    require_docker
    docker compose exec -T tester bash /tests/00_run_all.sh
    ;;
  validate)
    require_docker
    exec ./scripts/validate.sh
    ;;
  down)
    require_docker
    docker compose down --remove-orphans
    ;;
  *)
    usage
    exit 2
    ;;
esac
