#ifndef VOC_UNIX_SIGNAL_H
#define VOC_UNIX_SIGNAL_H

#include <stdint.h>
#if !defined(__OpenBSD__)
#include <ucontext.h>
#endif

#define VOC_STACK_CONTEXT_SUPPORTED 1
static uintptr_t voc_interrupted_stack(void *context)
{
    if (!context) return 0;
#if defined(__linux__) && defined(__x86_64__) && defined(REG_RSP)
    return (uintptr_t)((ucontext_t *)context)->uc_mcontext.gregs[REG_RSP];
#elif defined(__linux__) && defined(__i386__) && defined(REG_ESP)
    return (uintptr_t)((ucontext_t *)context)->uc_mcontext.gregs[REG_ESP];
#elif defined(__linux__) && defined(__aarch64__)
    return (uintptr_t)((ucontext_t *)context)->uc_mcontext.sp;
#elif defined(__linux__) && defined(__arm__)
    return (uintptr_t)((ucontext_t *)context)->uc_mcontext.arm_sp;
#elif defined(__FreeBSD__) && defined(__x86_64__)
    return (uintptr_t)((ucontext_t *)context)->uc_mcontext.mc_rsp;
#elif defined(__FreeBSD__) && defined(__i386__)
    return (uintptr_t)((ucontext_t *)context)->uc_mcontext.mc_esp;
#elif defined(__FreeBSD__) && defined(__aarch64__)
    return (uintptr_t)((ucontext_t *)context)->uc_mcontext.mc_gpregs.gp_sp;
#elif defined(__NetBSD__) && defined(_UC_MACHINE_SP)
    return (uintptr_t)_UC_MACHINE_SP((ucontext_t *)context);
#elif defined(__OpenBSD__) && defined(__x86_64__)
    return (uintptr_t)((struct sigcontext *)context)->sc_rsp;
#elif defined(__OpenBSD__) && defined(__i386__)
    return (uintptr_t)((struct sigcontext *)context)->sc_esp;
#elif defined(__OpenBSD__) && defined(__aarch64__)
    return (uintptr_t)((struct sigcontext *)context)->sc_sp;
#else
#undef VOC_STACK_CONTEXT_SUPPORTED
#define VOC_STACK_CONTEXT_SUPPORTED 0
    return 0;
#endif
}

#endif
