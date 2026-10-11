#define _XOPEN_SOURCE 700
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>
#include "TestTerminalSupport.h"

static int master = -1;
static struct termios original;

INT32 VOCTest_open_terminal(void)
{
    int slave = -1;
    char *name;
    master = posix_openpt(O_RDWR | O_NOCTTY);
    if (master < 0) return -1;
    if (grantpt(master) == 0 && unlockpt(master) == 0 && (name = ptsname(master)))
        slave = open(name, O_RDWR | O_NOCTTY);
    if (slave < 0 || tcgetattr(slave, &original) < 0) {
        if (slave >= 0) close(slave);
        close(master);
        master = -1;
        return -1;
    }
    return slave;
}

void VOCTest_close_terminal(INT32 fd)
{
    close(fd);
    close(master);
    master = -1;
}

INT32 VOCTest_terminal_settings(INT32 fd, INT32 raw, INT32 timed)
{
    struct termios actual, expected = original;
    if (raw) {
        expected.c_lflag &= ~(tcflag_t)(ICANON | ECHO | ISIG | IEXTEN);
        expected.c_iflag &= ~(tcflag_t)(ICRNL | IXON);
        expected.c_cc[VMIN] = timed ? 0 : 1;
        expected.c_cc[VTIME] = timed ? 1 : 0;
    }
    return tcgetattr(fd, &actual) == 0 &&
        actual.c_iflag == expected.c_iflag && actual.c_oflag == expected.c_oflag &&
        actual.c_cflag == expected.c_cflag && actual.c_lflag == expected.c_lflag &&
        !memcmp(actual.c_cc, expected.c_cc, sizeof actual.c_cc) &&
        cfgetispeed(&actual) == cfgetispeed(&expected) &&
        cfgetospeed(&actual) == cfgetospeed(&expected);
}

INT32 VOCTest_terminal_dimensions(INT32 fd)
{
    struct winsize size = {0};
    size.ws_row = 40000;
    size.ws_col = 65535;
    return ioctl(fd, TIOCSWINSZ, &size);
}
