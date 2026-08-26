#!/usr/bin/env bash
set -euo pipefail
printf 'Performing the same probe-file operations from the allowlisted bpfallow process.\n'
/opt/falco-lab/trusted/bpfallow bpf-filesystem-access
