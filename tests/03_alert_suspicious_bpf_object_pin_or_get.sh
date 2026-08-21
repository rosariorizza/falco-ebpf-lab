#!/usr/bin/env bash
set -euo pipefail
printf 'Requesting a deliberately nonexistent pinned BPF object from a non-allowlisted process.\n'
/usr/local/bin/falco-trigger bpf-obj-get
