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
#include <unistd.h>
#include <sys/prctl.h>
#include <stdbool.h>


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

static int trigger_bpf_prog_load(bool valid)
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

    if (valid) {
        if (prctl(PR_SET_NAME, "cilium-agent", 0, 0, 0) == -1) {
            perror("prctl(PR_SET_NAME)");
            return -1;
        }
    }

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

static void usage(const char *program)
{
    fprintf(stderr,
            "Usage: %s <bpf-prog-load|bpf-prog-attach|bpf-obj-get|init-module|capset|tool|load-valid-program>\n",
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
        return trigger_bpf_prog_load(false);
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
    if (strcmp(argv[1], "tool") == 0) {
        puts("generic tool test");
        return 0;
    }
    if (strcmp(argv[1], "load-valid-program") == 0) {
        return trigger_bpf_prog_load(true);
    }

    usage(argv[0]);
    return 2;
}
