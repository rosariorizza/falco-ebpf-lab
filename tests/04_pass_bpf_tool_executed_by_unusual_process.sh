#!/usr/bin/env bash
set -euo pipefail
printf 'Executing the same lab bpftool stub from the allowlisted bpfallow parent.\n'
/opt/falco-lab/trusted/bpfallow run-bpftool
