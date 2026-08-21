#!/usr/bin/env bash
set -euo pipefail
printf 'Executing the lab bpftool stub from the non-allowlisted falco-trigger parent.\n'
/usr/local/bin/falco-trigger run-bpftool
