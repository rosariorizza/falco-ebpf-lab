#!/usr/bin/env bash
set -euo pipefail
printf 'Reapplying the same capability set from the allowlisted bpfallow process.\n'
/opt/falco-lab/trusted/bpfallow capset
