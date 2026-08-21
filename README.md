# Falco anomalous eBPF Lab

Docker Compose lab for running Falco with custom rules focused on anomalous use of eBPF, capabilities, kernel modules, and sensitive paths. A second container includes tests named after the actions they generate.

## Requirements

* Native Linux host. Docker Desktop on macOS or Windows does not expose the host Linux kernel in the way Falco requires.
* Docker Engine with Docker Compose v2.
* A recent kernel compatible with Falco's `modern_ebpf` driver.
* Sufficient privileges to start `privileged` containers.

The project uses the Falco `0.44.1` image.

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
/tests/01_alert_unexpected_ebpf_program_load_or_attach.sh
# should trigger Falco because the program is NOT in the allowlist
/tests/01_pass_unexpected_ebpf_program_load_or_attach.sh
# should print the tester result but NOT trigger Falco because the program is in the allowlist
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

Each numbered test is provided as an `_alert_` and `_pass_` pair. The table describes the alert case of each pair.

| Number | Test name                                  | Generated event                 | Description                                                                          | Expected observation                                                |
| ------ | ------------------------------------------ | ------------------------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------------------------- |
| 01     | `unexpected_ebpf_program_load_or_attach` | `BPF_PROG_LOAD`               | Loads an eBPF program from a non-allowlisted process.                                | Tester result and`[RULE=Unexpected eBPF Program Load Or Attach]`. |
| 02     | `ebpf_program_load_from_container`       | `BPF_PROG_ATTACH`             | Attempts to attach an eBPF program from a process not allowed by the container rule. | Tester result and`[RULE=eBPF Program Load From Container]`.       |
| 03     | `suspicious_bpf_object_pin_or_get`       | `BPF_OBJ_GET`                 | Attempts to retrieve a pinned eBPF object from a non-allowlisted process.            | Tester result and`[RULE=Suspicious BPF Object Pin Or Get]`.       |
| 04     | `bpf_tool_executed_by_unusual_process`   | `bpftool` execution           | Executes an eBPF-related tool from an unexpected process context.                    | Tool output and`[RULE=BPF Tool Executed By Unusual Process]`.     |
| 05     | `kernel_module_load_attempt`             | `init_module`                 | Attempts to load an invalid kernel module from a non-allowlisted process.            | Tester result and`[RULE=Kernel Module Load Attempt]`.             |
| 06     | `capability_set_modification`            | `capset`                      | Reapplies the current capability set from a non-allowlisted process.                 | Tester result and`[RULE=Capability Set Modification]`.            |
| 07     | `sensitive_proc_kernel_write`            | Write under`/proc/sys/kernel` | Writes the current hostname back to its kernel control path.                         | Tester result and`[RULE=Sensitive Proc Kernel Write]`.            |
| 08     | `bpf_filesystem_access`                  | Access under`/sys/fs/bpf`     | Creates, reads, and removes a probe file in the test BPF filesystem.                 | Tester result and`[RULE=BPF Filesystem Access]`.                  |

### Pass Cases

Every table entry has a matching pass script named `<number>_pass_<test-name>.sh`. It performs the same action and generates the same event as the alert script, but runs it from the allowlisted `bpfallow` process. The tester still prints the action result, confirming that it was attempted, while Falco should not generate the corresponding alert.

For example, test 01 consists of `01_alert_unexpected_ebpf_program_load_or_attach.sh` and `01_pass_unexpected_ebpf_program_load_or_attach.sh`.

## Official References

* https://falco.org/docs/setup/container/
* https://falco.org/docs/concepts/event-sources/kernel/
* https://falco.org/docs/reference/rules/supported-events/
* https://falco.org/docs/reference/rules/supported-fields/
