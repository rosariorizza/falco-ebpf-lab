# Falco anomalous eBPF Lab

Docker Compose lab for running Falco with custom rules focused on anomalous use of eBPF, capabilities, kernel modules, and sensitive paths. A second container includes tests named after the actions they generate.

## Requirements

* Native Linux host. Docker Desktop on macOS or Windows does not expose the host Linux kernel in the way Falco requires.
* Docker Engine with Docker Compose v2.
* A recent kernel compatible with Falco's `modern_ebpf` driver.
* Sufficient privileges to start `privileged` containers.

The project uses the Falco `0.44.1` image and forces the `modern_ebpf` driver.

## Preliminary Checks

```bash
./lab.sh doctor
./lab.sh validate
```

## Running the Lab in Two Terminals

Terminal 1:

```bash
./lab.sh up
./lab.sh logs
```

Terminal 2:

```bash
./lab.sh shell
ls -1 /tests
/tests/01_unexpected_ebpf_program_load_or_attach.sh
/tests/03_suspicious_bpf_object_pin_or_get.sh
/tests/07_sensitive_proc_kernel_write.sh
/tests/00_run_all.sh
```

The first terminal will display alerts containing markers such as:

```text
[RULE=Unexpected eBPF Program Load Or Attach]
[RULE=eBPF Program Load From Container]
[RULE=Sensitive Proc Kernel Write]
```

## Automated Validation and Testing

```bash
./lab.sh validate
./lab.sh verify
```

`verify` starts the lab, runs all tests, and creates:

* `evidence/falco.log`
* `evidence/test-output.log`
* `evidence/verification-report.md`

The report marks each rule as `PASS` only when it finds the corresponding marker in the Falco log.

## Included Tests

| Script                                         | Generated event                               | Test safety                                                                    |
| ---------------------------------------------- | --------------------------------------------- | ------------------------------------------------------------------------------ |
| `01_unexpected_ebpf_program_load_or_attach.sh` | `BPF_PROG_LOAD`                               | Loads at most one minimal socket-filter program and closes it immediately.     |
| `02_ebpf_program_load_from_container.sh`       | `BPF_PROG_ATTACH`                             | Uses intentionally invalid file descriptors.                                   |
| `03_suspicious_bpf_object_pin_or_get.sh`       | `BPF_OBJ_GET`                                 | Requests a nonexistent object.                                                 |
| `04_bpf_tool_executed_by_unusual_process.sh`   | `bpftool` execution                           | Uses a local stub that only prints a message.                                  |
| `05_kernel_module_load_attempt.sh`             | `init_module`                                 | Passes an empty, invalid image; no module can be loaded.                       |
| `06_capability_set_modification.sh`            | `capset`                                      | Reapplies the current capabilities exactly as they are, without changing them. |
| `07_sensitive_proc_kernel_write.sh`            | write-open operation under `/proc/sys/kernel` | The path is overlaid with `tmpfs`, so it does not affect host sysctls.         |
| `08_bpf_filesystem_access.sh`                  | read/write operation under `/sys/fs/bpf`      | The path is overlaid with `tmpfs`, so it does not use the host bpffs.          |

## Quick Commands

```bash
./lab.sh list
./lab.sh run 04_bpf_tool_executed_by_unusual_process.sh
./lab.sh test
./lab.sh down
```

Equivalent targets are also available in the `Makefile`, including `make up`, `make logs`, `make verify`, and `make down`.

## Optional Tracefs Mount

Falco can operate without mounting tracefs, but the mount is recommended for certain TOCTOU mitigations. If your host exposes `/sys/kernel/tracing`:

```bash
./lab.sh up-tracefs
```

If the system uses `/sys/kernel/debug/tracing`, update the source path in `docker-compose.tracefs.yml`.

## Tuning Before Production

The `falco/ebpf-abuse-rules.yaml` file is intentionally sensitive. Update `known_bpf_loader_processes` with the legitimate agents used in your environment, such as Cilium, Tracee, Datadog, Sysdig, observability tools, or internal loaders.

The lab uses `privileged: true` to make the test syscalls reproducible. For a real deployment, apply the principle of least privilege and evaluate the capabilities specified in the Falco documentation.

## Official References

* https://falco.org/docs/setup/container/
* https://falco.org/docs/concepts/event-sources/kernel/
* https://falco.org/docs/reference/rules/supported-events/
* https://falco.org/docs/reference/rules/supported-fields/
