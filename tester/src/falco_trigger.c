#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <linux/bpf.h>
#include <linux/capability.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/syscall.h>
#include <sys/wait.h>
#include <unistd.h>


static void print_result(const char *action, long result)
{
    if (result >= 0) {
        printf("action=%s result=%ld status=success\n", action, result);
    } else {
        printf("action=%s result=%ld status=expected-failure errno=%d (%s)\n",
               action, result, errno, strerror(errno));
    }
}

static long do_bpf(enum bpf_cmd command, union bpf_attr *attr)
{
    errno = 0;
    return syscall(SYS_bpf, command, attr, sizeof(*attr));
}

static int trigger_bpf_prog_load()
{
    struct bpf_insn insns[] = {
        {
            .code = BPF_ALU64 | BPF_MOV | BPF_K,
            .dst_reg = BPF_REG_0,
            .src_reg = 0,
            .off = 0,
            .imm = 0,
        },
        {
            .code = BPF_JMP | BPF_EXIT,
            .dst_reg = 0,
            .src_reg = 0,
            .off = 0,
            .imm = 0,
        },
    };
    static const char license[] = "GPL";
    char log_buffer[4096] = {0};
    union bpf_attr attr;
    memset(&attr, 0, sizeof(attr));
    attr.prog_type = BPF_PROG_TYPE_SOCKET_FILTER;
    attr.insn_cnt = (uint32_t)(sizeof(insns) / sizeof(insns[0]));
    attr.insns = (uint64_t)(uintptr_t)insns;
    attr.license = (uint64_t)(uintptr_t)license;
    attr.log_buf = (uint64_t)(uintptr_t)log_buffer;
    attr.log_size = sizeof(log_buffer);
    attr.log_level = 1;


    long result = do_bpf(BPF_PROG_LOAD, &attr);
    print_result("BPF_PROG_LOAD", result);
    if (result >= 0) {
        close((int)result);
    }
    return 0;
}

static int trigger_bpf_prog_attach(void)
{
    union bpf_attr attr;
    memset(&attr, 0, sizeof(attr));
    attr.target_fd = (uint32_t)-1;
    attr.attach_bpf_fd = (uint32_t)-1;
    attr.attach_type = BPF_CGROUP_INET_INGRESS;

    long result = do_bpf(BPF_PROG_ATTACH, &attr);
    print_result("BPF_PROG_ATTACH", result);
    return 0;
}

static int trigger_bpf_obj_get(void)
{
    static const char path[] = "/sys/fs/bpf/falco-lab-object-that-does-not-exist";
    union bpf_attr attr;
    memset(&attr, 0, sizeof(attr));
    attr.pathname = (uint64_t)(uintptr_t)path;

    long result = do_bpf(BPF_OBJ_GET, &attr);
    print_result("BPF_OBJ_GET", result);
    if (result >= 0) {
        close((int)result);
    }
    return 0;
}

static int trigger_init_module(void)
{
#ifdef SYS_init_module
    errno = 0;
    long result = syscall(SYS_init_module, NULL, 0UL, "");
    print_result("init_module", result);
#else
    puts("action=init_module status=unsupported-on-this-architecture");
#endif
    return 0;
}

static int trigger_capset(void)
{
    struct __user_cap_header_struct header;
    struct __user_cap_data_struct data[2];
    memset(&header, 0, sizeof(header));
    memset(data, 0, sizeof(data));
    header.version = _LINUX_CAPABILITY_VERSION_3;
    header.pid = 0;

    errno = 0;
    long get_result = syscall(SYS_capget, &header, data);
    if (get_result < 0) {
        print_result("capget", get_result);
        return 0;
    }

    errno = 0;
    long set_result = syscall(SYS_capset, &header, data);
    print_result("capset-noop", set_result);
    return 0;
}

static int trigger_bpftool_execution(void)
{
    pid_t child = fork();
    if (child < 0) {
        print_result("BPFTOOL_EXECUTION", -1);
        return 0;
    }

    if (child == 0) {
        execl("/usr/local/bin/bpftool", "bpftool", "version", (char *)NULL);
        fprintf(stderr, "action=BPFTOOL_EXECUTION status=expected-failure errno=%d (%s)\n",
                errno, strerror(errno));
        _exit(127);
    }

    int status = 0;
    errno = 0;
    long result = waitpid(child, &status, 0);
    if (result < 0) {
        print_result("BPFTOOL_EXECUTION", result);
    } else if (WIFEXITED(status)) {
        printf("action=BPFTOOL_EXECUTION result=%d status=%s\n",
               WEXITSTATUS(status), WEXITSTATUS(status) == 0 ? "success" : "expected-failure");
    } else {
        puts("action=BPFTOOL_EXECUTION status=expected-failure reason=child-terminated");
    }
    return 0;
}

static int trigger_sensitive_proc_kernel_write(void)
{
    static const char path[] = "/proc/sys/kernel/hostname";
    char hostname[256];
    if (gethostname(hostname, sizeof(hostname) - 2) < 0) {
        print_result("SENSITIVE_PROC_KERNEL_WRITE", -1);
        return 0;
    }
    hostname[sizeof(hostname) - 2] = '\0';
    size_t length = strlen(hostname);
    hostname[length++] = '\n';

    errno = 0;
    int fd = open(path, O_WRONLY);
    if (fd < 0) {
        print_result("SENSITIVE_PROC_KERNEL_WRITE", fd);
        return 0;
    }

    errno = 0;
    long result = write(fd, hostname, length);
    int saved_errno = errno;
    close(fd);
    errno = saved_errno;
    print_result("SENSITIVE_PROC_KERNEL_WRITE", result);
    return 0;
}

static int trigger_bpf_filesystem_access(void)
{
    static const char path[] = "/run/cilium/bpffs/falco_lab_probe";
    static const char contents[] = "falco-lab\n";
    char buffer[sizeof(contents)];

    errno = 0;
    int fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0600);
    if (fd < 0) {
        print_result("BPF_FILESYSTEM_ACCESS", fd);
        return 0;
    }

    long result = write(fd, contents, sizeof(contents) - 1);
    int saved_errno = errno;
    close(fd);
    if (result < 0) {
        errno = saved_errno;
        print_result("BPF_FILESYSTEM_ACCESS", result);
        unlink(path);
        return 0;
    }

    errno = 0;
    fd = open(path, O_RDONLY);
    if (fd < 0) {
        print_result("BPF_FILESYSTEM_ACCESS", fd);
        unlink(path);
        return 0;
    }

    result = read(fd, buffer, sizeof(buffer));
    saved_errno = errno;
    close(fd);
    unlink(path);
    errno = saved_errno;
    print_result("BPF_FILESYSTEM_ACCESS", result);
    return 0;
}

static void usage(const char *program)
{
    fprintf(stderr,
            "Usage: %s <bpf-prog-load|bpf-prog-attach|bpf-obj-get|init-module|capset|run-bpftool|proc-kernel-write|bpf-filesystem-access>\n",
            program);
}

int main(int argc, char **argv)
{
    const char *base = strrchr(argv[0], '/');
    base = base ? base + 1 : argv[0];

    if (strcmp(base, "bpftool") == 0) {
        puts("bpftool lab stub: execution-only test; no kernel changes performed");
        return 0;
    }

    if (argc != 2) {
        usage(argv[0]);
        return 2;
    }

    if (strcmp(argv[1], "bpf-prog-load") == 0) {
        return trigger_bpf_prog_load();
    }
    if (strcmp(argv[1], "bpf-prog-attach") == 0) {
        return trigger_bpf_prog_attach();
    }
    if (strcmp(argv[1], "bpf-obj-get") == 0) {
        return trigger_bpf_obj_get();
    }
    if (strcmp(argv[1], "init-module") == 0) {
        return trigger_init_module();
    }
    if (strcmp(argv[1], "capset") == 0) {
        return trigger_capset();
    }
    if (strcmp(argv[1], "run-bpftool") == 0) {
        return trigger_bpftool_execution();
    }
    if (strcmp(argv[1], "proc-kernel-write") == 0) {
        return trigger_sensitive_proc_kernel_write();
    }
    if (strcmp(argv[1], "bpf-filesystem-access") == 0) {
        return trigger_bpf_filesystem_access();
    }

    usage(argv[0]);
    return 2;
}
