#!/usr/bin/env bash
set -euo pipefail
printf 'Triggering a harmless BPF_PROG_LOAD syscall.\n'
/usr/local/bin/falco-trigger bpf-prog-load
