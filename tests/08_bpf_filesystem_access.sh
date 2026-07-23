#!/usr/bin/env bash
set -euo pipefail
printf 'Reading and writing inside a tmpfs mounted over /sys/fs/bpf.\n'
printf 'falco-lab\n' > /sys/fs/bpf/falco_lab_probe
cat /sys/fs/bpf/falco_lab_probe >/dev/null
rm -f /sys/fs/bpf/falco_lab_probe
