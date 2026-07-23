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
# should trigger Falco because the program is NOT in the whitelist
/tests/03_suspicious_bpf_object_pin_or_get.sh
# should NOT trigger Falco because the program is in the whitelist
/tests/09_allowed_bpf_obj_pin.sh
```

The first terminal will display alerts containing markers such as:

```text
[RULE=Unexpected eBPF Program Load Or Attach]
[RULE=eBPF Program Load From Container]
[RULE=Sensitive Proc Kernel Write]
```

## Stop the lab

In order to stop the lab, run:

```bash
./lab.sh down
```

## Included Tests

| Script                                         | Generated event                | Description                                                       |
| ---------------------------------------------- | ------------------------------ | ----------------------------------------------------------------- |
| `01_unexpected_ebpf_program_load_or_attach.sh` | `BPF_PROG_LOAD`                | Loads an eBPF program from a non-allowlisted process.             |
| `02_ebpf_program_load_from_container.sh`       | `BPF_PROG_ATTACH`              | Attempts to attach an eBPF program from inside a container.       |
| `03_suspicious_bpf_object_pin_or_get.sh`       | `BPF_OBJ_GET`                  | Attempts to retrieve a pinned eBPF object.                        |
| `04_bpf_tool_executed_by_unusual_process.sh`   | `bpftool` execution            | Executes an eBPF-related tool from an unexpected process context. |
| `05_kernel_module_load_attempt.sh`             | `init_module`                  | Attempts to load a kernel module.                                 |
| `06_capability_set_modification.sh`            | `capset`                       | Invokes a process capability-set operation.                       |
| `07_sensitive_proc_kernel_write.sh`            | Write under `/proc/sys/kernel` | Attempts to write to a sensitive kernel configuration path.       |
| `08_bpf_filesystem_access.sh`                  | Access under `/sys/fs/bpf`     | Reads from or writes to the eBPF filesystem.                      |
| `09_allowed_bpf_obj_pin.sh`                    | `BPF_OBJ_GET`                  | Accesses an eBPF object from an allowlisted process. It should not trigger Falco.             |
|

## Official References

* https://falco.org/docs/setup/container/
* https://falco.org/docs/concepts/event-sources/kernel/
* https://falco.org/docs/reference/rules/supported-events/
* https://falco.org/docs/reference/rules/supported-fields/
