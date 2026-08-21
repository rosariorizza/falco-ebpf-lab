#!/usr/bin/env bash
set -euo pipefail
printf 'Writing the current hostname back to the container UTS namespace from a non-allowlisted process.\n'
/usr/local/bin/falco-trigger proc-kernel-write
