#!/usr/bin/env bash
set -euo pipefail
printf 'Triggering the same BPF_PROG_ATTACH syscall from the allowlisted bpfallow process.\n'
/usr/local/bin/bpfallow bpf-prog-attach
