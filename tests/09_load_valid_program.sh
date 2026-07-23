#!/usr/bin/env bash
set -euo pipefail
printf 'Loading an eBPF program from a valid process.\n'
/usr/local/bin/falco-trigger load-valid-program
