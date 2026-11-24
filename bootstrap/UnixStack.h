#ifndef VOC_UNIX_STACK_H
#define VOC_UNIX_STACK_H

#include <sys/resource.h>
#include <stdint.h>
#include <stddef.h>

static INT64 voc_stack_limit(void)
{
    struct rlimit limit;
    if (getrlimit(RLIMIT_STACK, &limit) < 0 || limit.rlim_cur == RLIM_INFINITY ||
        limit.rlim_cur == 0 || limit.rlim_cur > (rlim_t)INT64_MAX)
        return 0;
    return (INT64)limit.rlim_cur;
}

#if defined(__FreeBSD__) || defined(__NetBSD__) || defined(__OpenBSD__)
#include <sys/types.h>
#include <sys/sysctl.h>
#include <unistd.h>
#include <errno.h>
#if defined(__FreeBSD__)
#include <sys/user.h>
#endif

/* Native VM records stay private; unavailable or oversized maps disable classification. */
static INT64 voc_native_stack_top(ADDRESS marker)
{
    (void)marker;
#if defined(__FreeBSD__) && defined(KERN_PROC_VMMAP) && defined(KVME_FLAG_GROWS_DOWN)
    static union {
        struct kinfo_vmentry alignment;
        unsigned char bytes[1024 * 1024];
    } buffer;
    int mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_VMMAP, 0};
    size_t size = sizeof(buffer.bytes), offset = 0;
    mib[3] = getpid();
    if (sysctl(mib, 4, buffer.bytes, &size, NULL, 0) < 0 || size > sizeof(buffer.bytes)) return 0;
    while (size - offset >= offsetof(struct kinfo_vmentry, kve_path)) {
        struct kinfo_vmentry *entry = (void *)(buffer.bytes + offset);
        size_t step = entry->kve_structsize;
        if (step < offsetof(struct kinfo_vmentry, kve_path) || step > size - offset ||
            step % sizeof(uint64_t) != 0) return 0;
        if ((entry->kve_flags & KVME_FLAG_GROWS_DOWN) &&
            (entry->kve_protection & KVME_PROT_WRITE) &&
            (uintptr_t)marker >= entry->kve_start && (uintptr_t)marker < entry->kve_end &&
            entry->kve_end <= INT64_MAX)
            return (INT64)entry->kve_end;
        offset += step;
    }
#elif defined(__NetBSD__) && defined(VM_PROC_MAP) && defined(KVME_FLAG_GROWS_DOWN)
    static struct kinfo_vmentry entries[256];
    int mib[] = {CTL_VM, VM_PROC, VM_PROC_MAP, -1, sizeof(struct kinfo_vmentry)};
    size_t size = sizeof(entries), i;
    if (sysctl(mib, 5, entries, &size, NULL, 0) < 0 || size > sizeof(entries) ||
        size % sizeof(entries[0]) != 0) return 0;
    for (i = 0; i < size / sizeof(entries[0]); ++i) {
        struct kinfo_vmentry *entry = &entries[i];
        if ((entry->kve_flags & KVME_FLAG_GROWS_DOWN) &&
            (entry->kve_protection & KVME_PROT_WRITE) &&
            (uintptr_t)marker >= entry->kve_start && (uintptr_t)marker < entry->kve_end &&
            entry->kve_end <= INT64_MAX)
            return (INT64)entry->kve_end;
    }
#elif defined(__OpenBSD__) && defined(KERN_PROC_VMMAP) && defined(KVE_ET_STACK)
    struct kinfo_vmentry entries[32];
    int mib[] = {CTL_KERN, KERN_PROC_VMMAP, 0};
    size_t size, i;
    uintptr_t cursor = 0;
    unsigned int batch;
    mib[2] = getpid();
    for (batch = 0; batch < 1024; ++batch) {
        entries[0].kve_start = cursor;
        size = sizeof(entries);
        if (sysctl(mib, 3, entries, &size, NULL, 0) < 0 || size > sizeof(entries) ||
            size == 0 || size % sizeof(entries[0]) != 0) return 0;
        for (i = 0; i < size / sizeof(entries[0]); ++i) {
            struct kinfo_vmentry *entry = &entries[i];
            if ((entry->kve_etype & KVE_ET_STACK) && (entry->kve_protection & KVE_PROT_WRITE) &&
                (uintptr_t)marker >= entry->kve_start && (uintptr_t)marker < entry->kve_end &&
                entry->kve_end <= INT64_MAX)
                return (INT64)entry->kve_end;
        }
        if (entries[i - 1].kve_end <= cursor) return 0;
        cursor = entries[i - 1].kve_end;
    }
#endif
    return 0;
}
#else
static INT64 voc_native_stack_top(ADDRESS marker)
{
    (void)marker;
#if defined(__linux__)
    return -1;
#else
    return 0;
#endif
}
#endif

#endif
