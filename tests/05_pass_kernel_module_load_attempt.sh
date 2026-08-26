#!/usr/bin/env bash
set -euo pipefail
printf 'Invoking the same harmless init_module attempt from the allowlisted bpfallow process.\n'
/opt/falco-lab/trusted/bpfallow init-module
