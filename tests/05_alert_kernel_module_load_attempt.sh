#!/usr/bin/env bash
set -euo pipefail
printf 'Invoking init_module with an empty, invalid image from a non-allowlisted process. No module can be loaded.\n'
/usr/local/bin/falco-trigger init-module
