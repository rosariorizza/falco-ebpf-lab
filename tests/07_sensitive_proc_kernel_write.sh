#!/usr/bin/env bash
set -euo pipefail

printf 'Writing the current hostname back to the container UTS namespace.\n'
current_hostname="$(cat /proc/sys/kernel/hostname)"
printf '%s\n' "$current_hostname" > /proc/sys/kernel/hostname
