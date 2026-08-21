#!/usr/bin/env bash
set -euo pipefail
printf 'Performing the same probe-file operations from the allowlisted bpfallow process.\n'
/usr/local/bin/bpfallow bpf-filesystem-access
