/* Interpose only the synthetic descriptor, never compiler or test output. */
#include <sys/types.h>
#include <unistd.h>
#include <dlfcn.h>
#include <errno.h>
#include <stdlib.h>
#include <stdint.h>

static intptr_t calls, completed;

intptr_t VocWriteCalls(void) { return calls; }
intptr_t VocWriteCompleted(void) { return completed; }

ssize_t write(int fd, const void *buffer, size_t count)
{
    if (fd != 12345) {
        static ssize_t (*real_write)(int, const void *, size_t);
        if (!real_write) *(void **)&real_write = dlsym(RTLD_NEXT, "write");
        return real_write(fd, buffer, count);
    }
    int mode = atoi(getenv("VOC_WRITE_FAULT"));
    ++calls;
    if (mode == 1 && calls == 1) { errno = EINTR; return -1; }
    if (mode == 2 && calls == 2) { errno = EIO; return -1; }
    if (mode == 3) return 0;
    if (mode == 4) { errno = EAGAIN; return -1; }
    if (count != (size_t)(37 - completed)) { errno = EINVAL; return -1; }
    const unsigned char *bytes = buffer;
    size_t n = count < 3 ? count : 3;
    for (size_t i = 0; i < n; ++i) {
        if (bytes[i] != (unsigned char)((completed + i) % 251)) {
            errno = EINVAL;
            return -1;
        }
    }
    completed += n;
    return (ssize_t)n;
}
