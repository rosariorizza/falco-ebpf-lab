#!/usr/bin/env bash
set -euo pipefail

trusted_link=/tmp/bpfallow
trap 'rm -f "$trusted_link"' EXIT

printf 'Executing the trusted binary through a symlink; its canonical executable path remains trusted.\n'
ln -sfn /opt/falco-lab/trusted/bpfallow "$trusted_link"
"$trusted_link" bpf-prog-load
