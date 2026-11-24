#include <errno.h>
#include <sys/resource.h>

#ifndef TEST_UNLIMITED_STACK
#define TEST_UNLIMITED_STACK 0
#endif

int TestGetrlimit(int resource, struct rlimit *limit)
{
    (void)resource;
    if (TEST_UNLIMITED_STACK) {
        limit->rlim_cur = limit->rlim_max = RLIM_INFINITY;
        return 0;
    }
    errno = EIO;
    return -1;
}
