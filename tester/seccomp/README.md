# Lab seccomp profile

Docker requires a complete seccomp profile and cannot apply a small overlay to
its built-in default profile.

`default-moby.json` is an unchanged snapshot of the Moby default profile from
<https://raw.githubusercontent.com/moby/profiles/main/seccomp/default.json>,
retrieved on 2026-08-26. Its SHA-256 is
`b9aaf73b79aa9088c675399b494b358c579aa1221a722cf32da9aded5c4a40c1`.

`lab.patch` is the complete lab-specific change. It allows only the three BPF
commands exercised by the tests and `init_module` to reach the kernel without
granting their corresponding capabilities.

`../seccomp-profile.json` is the generated complete profile consumed by Docker
Compose. Generate it with:

```console
./scripts/render-seccomp-profile.sh
```

Use `./scripts/render-seccomp-profile.sh --check` to verify that the generated
file matches the original profile plus the patch.
