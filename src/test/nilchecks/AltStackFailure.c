#if defined(__linux__) && !defined(_GNU_SOURCE)
#define _GNU_SOURCE 1
#endif
#define _POSIX_C_SOURCE 200809L
#define _XOPEN_SOURCE 700
#include "SYSTEM.h"
#include <errno.h>
#include <signal.h>
#include <stddef.h>

static int failQuery;

int TestSigaltstack(const stack_t *alternate, stack_t *current)
{
    if (failQuery || alternate) {
        errno = ENOMEM;
        return -1;
    }
    return sigaltstack(NULL, current);
}

/* Preserve libc's symbol-version annotations before redirecting runtime calls. */
#define sigaltstack TestSigaltstack
#include "../../runtime/SYSTEM.c"

int main(int argc, char **argv)
{
    volatile unsigned char *invalid = (void *)(ADDRESS)1;
    failQuery = argc > 1 && argv[1][0] == 'q';
    setupAutomaticSegfaultHandler();
    *invalid = 0;
    return 1;
}
