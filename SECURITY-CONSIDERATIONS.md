# Security Considerations

## Purpose

This lab tests whether Falco detects sensitive eBPF and kernel operations.
It is not a complete production security design.

Production allowlists must be designed for each application. The application,
its inputs, its deployment environment, and its required kernel operations must
be reviewed separately.

## Threat Model

The lab must be resistant to an unprivileged user who tries to bypass a Falco
allowlist by changing a process name or by running another executable.

The lab does not try to protect Falco from an attacker who already controls the
host as root. A host root user or a user with full access to the Docker daemon
can stop or modify Falco.

## Trusted Execution Identity

Trusted execution must use:

- `proc.exepath` for the full executable path;
- `proc.pexepath` when the parent executable is relevant;
- `user.uid` for the numeric UID that runs the process;
- the container or workload identity when the same path and UID can exist in
  more than one container.

The path, UID, and workload identity must be checked together. Separate lists
of trusted paths and trusted UIDs could allow an unintended combination.

An absolute path is evaluated inside a process mount namespace. Two containers
can contain the same path and use the same numeric UID. The workload identity
prevents one container from copying the trusted path and UID of another
container. The exact identity depends on the environment. This lab uses
`container.image.repository`; a production deployment may use an immutable
image identity or Kubernetes workload metadata.

Using `proc.name` or `proc.pname` as an allowlist identity would be unsafe. A
process name can be changed and is limited to 16 characters. These fields may
still be useful in alert messages.

## Trusted Executable Files

A trusted executable must be stored in a directory controlled by root. The
runtime user may execute the file, but it must not be able to modify, replace,
rename, or delete it.

An example layout is:

```text
/opt/trusted-ebpf/loader

directory owner: root:ebpf-runner
directory mode:  0750
file owner:      root:ebpf-runner
file mode:       0550
```

The runtime user belongs to the `ebpf-runner` group. Every parent directory of
the executable must also be protected from writes by that user.

Falco resolves `proc.exepath` to the executable path. Renaming a copy of a
program, changing `argv[0]`, or using a symlink to a different program must not
make that program trusted.

File permissions do not protect a path from mount replacement. The runtime
user must not receive `CAP_SYS_ADMIN` or other mount privileges. The container
must also prevent unprivileged mount-namespace tricks by using an appropriate
seccomp or LSM policy, a read-only root filesystem, and no unnecessary
capabilities.

## Tester Privileges

The tester must run with a dedicated non-root UID and GID. Its container must
use:

- `privileged: false`;
- `cap_drop: ALL`;
- `no-new-privileges`;
- a read-only root filesystem;
- only the writable temporary filesystems required by a test.

No Linux capability is required for the default tests. A narrow test seccomp
profile allows only the required `bpf` commands and `init_module` to reach the
kernel so Falco can observe them. The kernel can still reject the operations
because the tester has no capabilities, while unrelated dangerous syscalls
remain blocked.

This is different from a real eBPF application. A real application that must
successfully load or attach an eBPF program needs carefully selected
capabilities or a BPF token. That decision is outside this lab and must be made
for the specific application.

## Test Behaviour Without Capabilities

| Test | Expected behaviour as non-root with no capabilities |
| --- | --- |
| 01 - BPF program load | The `bpf` syscall may fail, but Falco detects the attempted `BPF_PROG_LOAD`. |
| 02 - BPF program attach | The `bpf` syscall may fail, but Falco detects the attempted attach command. |
| 03 - BPF object access | The `bpf` syscall may fail, but Falco detects the attempted object access. |
| 04 - BPF tool execution | Executing the harmless test tool needs no capability. |
| 05 - Kernel module load | `init_module` is expected to fail without `CAP_SYS_MODULE`, but Falco detects the attempt. |
| 06 - Capability change | The process can call `capset`; Falco detects the call even when it has no capabilities. |
| 07 - `/proc/sys/kernel` write | The open is expected to fail. The rule must detect failed write-open attempts, not only successful opens. |
| 08 - BPF filesystem access | The test uses an isolated tmpfs owned by the tester UID. It does not need access to the host BPF filesystem. |
| 09 - Spoofed process name | A symlink named `bpfallow` still alerts when it resolves to the untrusted executable path. |

The purpose of these tests is to verify detection. A successful sensitive
kernel operation is not required.

## References

- [Falco supported fields](https://falco.org/docs/reference/rules/supported-fields/)
- [Falco container deployment](https://falco.org/docs/setup/container/)
- [Docker Compose service configuration](https://docs.docker.com/reference/compose-file/services/)
- [Docker default seccomp profile](https://docs.docker.com/engine/security/seccomp/)
- [Linux kernel BPF syscall documentation](https://docs.kernel.org/userspace-api/ebpf/syscall.html)
