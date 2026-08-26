#!/usr/bin/env bash
set -euo pipefail

spoofed_path=/tmp/bpfallow
trap 'rm -f "$spoofed_path"' EXIT

printf 'Executing an untrusted binary through a symlink named bpfallow.\n'
ln -sfn /usr/local/bin/falco-trigger "$spoofed_path"
"$spoofed_path" bpf-prog-load
