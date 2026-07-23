#!/usr/bin/env bash
set -euo pipefail
printf 'Requesting a deliberately nonexistent pinned BPF object from an authorized program.\n'
/usr/local/bin/bpfallow bpf-obj-get