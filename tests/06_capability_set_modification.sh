#!/usr/bin/env bash
set -euo pipefail
printf 'Calling capset with the process current capability set unchanged.\n'
/usr/local/bin/falco-trigger capset
