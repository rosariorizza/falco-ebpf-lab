#!/usr/bin/env bash
set -euo pipefail
printf 'Loading an eBPF program from a valid process. Should not display any warning.\n'
/usr/local/bin/bpfallow load-valid-program
