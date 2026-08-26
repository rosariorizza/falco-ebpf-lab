#!/usr/bin/env bash
set -euo pipefail
printf 'Requesting the same nonexistent pinned BPF object from the allowlisted bpfallow process.\n'
/opt/falco-lab/trusted/bpfallow bpf-obj-get
