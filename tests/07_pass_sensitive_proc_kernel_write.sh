#!/usr/bin/env bash
set -euo pipefail
printf 'Performing the same harmless hostname write from the allowlisted bpfallow process.\n'
/opt/falco-lab/trusted/bpfallow proc-kernel-write
