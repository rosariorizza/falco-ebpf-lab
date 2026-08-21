#!/usr/bin/env bash
set -euo pipefail
printf 'Requesting the same nonexistent pinned BPF object from the allowlisted bpfallow process.\n'
/usr/local/bin/bpfallow bpf-obj-get
