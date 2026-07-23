#!/usr/bin/env bash
set -euo pipefail
printf 'Requesting a deliberately nonexistent pinned BPF object.\n'
/usr/local/bin/falco-trigger bpf-obj-get
