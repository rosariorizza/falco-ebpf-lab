#!/usr/bin/env bash
set -euo pipefail
printf 'Triggering an intentionally invalid BPF_PROG_ATTACH syscall from this container.\n'
/usr/local/bin/bpfallow bpf-prog-attach
