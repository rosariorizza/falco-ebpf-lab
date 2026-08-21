#!/usr/bin/env bash
set -euo pipefail
printf 'Creating, reading, and removing a probe file in the test BPF filesystem from a non-allowlisted process.\n'
/usr/local/bin/falco-trigger bpf-filesystem-access
