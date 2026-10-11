#ifndef VOC_PLATFORM_TERMIOS_H
#define VOC_PLATFORM_TERMIOS_H

/* TCC's -I search also applies to angle includes. Skip the module-header
   directory so the Oberon termios.h cannot shadow libc's termios.h. */
#ifdef __TINYC__
#include_next <termios.h>
#else
#include <termios.h>
#endif

#include <errno.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>

/* Keep native layouts and flag types here. Oberon owns these allocations
   through opaque ADDRESS handles; no struct layout crosses the interface. */
static int VOC_TerminalFD(LONGINT value, int *fd)
{
    if (value < 0 || (UINT64)value > INT_MAX) {
        errno = EBADF;
        return -1;
    }
    *fd = (int)value;
    return 0;
}

static int VOC_CaptureTerminalState(LONGINT handle, ADDRESS *state)
{
    struct termios *settings;
    int fd, error;
    *state = 0;
    if (VOC_TerminalFD(handle, &fd) < 0) return -1;
    settings = malloc(sizeof *settings);
    if (!settings) { errno = ENOMEM; return -1; }
    if (tcgetattr(fd, settings) < 0) {
        error = errno;
        free(settings);
        errno = error;
        return -1;
    }
    *state = (ADDRESS)settings;
    return 0;
}

static int VOC_RestoreTerminalState(LONGINT handle, ADDRESS state)
{
    int fd;
    if (VOC_TerminalFD(handle, &fd) < 0) return -1;
    return tcsetattr(fd, TCSANOW, (const struct termios *)state);
}

static int VOC_CopyTerminalState(ADDRESS source, ADDRESS *copy)
{
    struct termios *settings = malloc(sizeof *settings);
    *copy = 0;
    if (!settings) { errno = ENOMEM; return -1; }
    memcpy(settings, (const void *)source, sizeof *settings);
    *copy = (ADDRESS)settings;
    return 0;
}

static void VOC_MakeTerminalRaw(ADDRESS state)
{
    struct termios *settings = (struct termios *)state;
    settings->c_lflag &= ~(tcflag_t)(ICANON | ECHO | ISIG | IEXTEN);
    settings->c_iflag &= ~(tcflag_t)(ICRNL | IXON);
    settings->c_cc[VMIN] = 1;
    settings->c_cc[VTIME] = 0;
}

static void VOC_SetTerminalTimeout(ADDRESS state, int tenths)
{
    struct termios *settings = (struct termios *)state;
    settings->c_cc[VMIN] = 0;
    settings->c_cc[VTIME] = (cc_t)tenths;
}

static int VOC_GetTerminalDimensions(LONGINT handle, LONGINT *lines,
    LONGINT *columns, LONGINT limit)
{
    struct winsize size;
    int fd;
    if (VOC_TerminalFD(handle, &fd) < 0 || ioctl(fd, TIOCGWINSZ, &size) < 0)
        return -1;
    if ((UINT64)size.ws_row > (UINT64)limit ||
        (UINT64)size.ws_col > (UINT64)limit) {
        errno = EOVERFLOW;
        return -1;
    }
    *lines = (LONGINT)size.ws_row;
    *columns = (LONGINT)size.ws_col;
    return 0;
}

#endif
