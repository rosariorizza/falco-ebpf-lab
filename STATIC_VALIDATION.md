# Static validation performed before packaging

The following checks were executed successfully on the packaged source tree:

- YAML parsing for `docker-compose.yml`, `docker-compose.tracefs.yml`, and the Falco rules file.
- Presence of eight Falco rules and a unique `[RULE=...]` marker in every output.
- Bash syntax validation with `bash -n` for the launcher, validation scripts, verifier, and all tests.
- Native compilation of `tester/src/falco_trigger.c` with `gcc -O2 -Wall -Wextra -Werror` on x86_64.
- Local execution of the harmless BPF loader, attach attempt, object-get attempt, module-load attempt, capability no-op, and bpftool stub.

A full Falco runtime verification was not executed in the packaging environment because it does not provide Docker or the required host-kernel privileges. Run `./lab.sh verify` on a native Linux Docker host to generate real evidence under `evidence/`.
