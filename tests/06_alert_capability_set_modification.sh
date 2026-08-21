#!/usr/bin/env bash
set -euo pipefail
printf 'Reapplying the current capability set from a non-allowlisted process.\n'
/usr/local/bin/falco-trigger capset
