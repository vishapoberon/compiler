#define _POSIX_C_SOURCE 200809L
#define _XOPEN_SOURCE 700
#include "SYSTEM.h"
#include <signal.h>
#include <stddef.h>
#include <unistd.h>

static union {
    long double alignment;
    unsigned char bytes[128 * 1024];
} hostStack;
static stack_t expected;

static void onFault(INT32 signal)
{
    volatile unsigned char marker;
    ADDRESS address = (ADDRESS)&marker;
    static const char message[] = "alternate signal stack used\n";
    if (signal != SIGSEGV || address < (ADDRESS)expected.ss_sp ||
        address - (ADDRESS)expected.ss_sp >= expected.ss_size)
        _exit(90);
    _exit(write(STDOUT_FILENO, message, sizeof(message) - 1) == sizeof(message) - 1 ? 0 : 91);
}

int main(int argc, char **argv)
{
    stack_t supplied = {0}, repeated;
    struct sigaction action;
    volatile unsigned char *invalid = (void *)(ADDRESS)1;
    int host = argc > 1 && argv[1][0] == 'h';
    if (host) {
        supplied.ss_sp = hostStack.bytes;
        supplied.ss_size = sizeof(hostStack.bytes);
        if (sigaltstack(&supplied, NULL) < 0) return 1;
    }
    setupAutomaticSegfaultHandler();
    if (sigaltstack(NULL, &expected) < 0 || (expected.ss_flags & SS_DISABLE)) return 2;
    if (host && (expected.ss_sp != supplied.ss_sp || expected.ss_size != supplied.ss_size)) return 3;
    if (!host && expected.ss_size < 128 * 1024) return 4;
    setupAutomaticSegfaultHandler();
    if (sigaltstack(NULL, &repeated) < 0 || repeated.ss_sp != expected.ss_sp ||
        repeated.ss_size != expected.ss_size) return 5;
    if (sigaction(SIGSEGV, NULL, &action) < 0 || !(action.sa_flags & SA_ONSTACK)) return 6;
    SystemSetHandler(SIGINT, (ADDRESS)onFault);
    if (sigaction(SIGINT, NULL, &action) < 0 || (action.sa_flags & SA_ONSTACK)) return 7;
    SystemSetHandler(SIGSEGV, (ADDRESS)onFault);
    *invalid = 0;
    return 8;
}
