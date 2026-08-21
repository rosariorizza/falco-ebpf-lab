#!/usr/bin/env bash
set -euo pipefail
printf 'Triggering an intentionally invalid BPF_PROG_ATTACH syscall from a process not allowed by the container rule.\n'
/usr/local/bin/bpfcontainer bpf-prog-attach
