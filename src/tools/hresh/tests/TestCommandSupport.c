#define _POSIX_C_SOURCE 200809L
#include <errno.h>
#include <signal.h>
#include <stddef.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <netinet/in.h>
#include <time.h>
#include <unistd.h>
#include "TestCommandSupport.h"

static volatile sig_atomic_t previous_signals;
static int native_returned;
static struct sigaction previous_action;
static pid_t interrupter = -1;
static struct sockaddr_in listener_address;
static sigset_t previous_mask;

static void previous_interrupt(int signal)
{
    (void)signal;
    ++previous_signals;
}

void VOC_TestInterrupt(void)
{
    raise(SIGINT);
}

void VOC_TestNativeCallback(void (*callback)(void))
{
    native_returned = 0;
    raise(SIGINT);
    callback();
    native_returned = 1;
}

int VOC_TestNativeReturned(void) { return native_returned; }

void VOC_TestSignalHandler(int install)
{
    if (install) {
        struct sigaction action = {0};
        previous_signals = 0;
        action.sa_handler = previous_interrupt;
        sigemptyset(&action.sa_mask);
        sigaction(SIGINT, &action, &previous_action);
    } else sigaction(SIGINT, &previous_action, NULL);
}

int VOC_TestPreviousSignals(void) { return previous_signals; }

int VOC_TestInterruptingCondition(void)
{
    raise(SIGINT);
    return 1;
}

int VOC_TestStartInterrupt(void)
{
    pid_t parent = getpid();
    interrupter = fork();
    if (!interrupter) {
        struct timespec delay = {0, 50000000};
        while (nanosleep(&delay, &delay) < 0 && errno == EINTR) {}
        _exit(kill(parent, SIGINT) < 0);
    }
    return interrupter > 0;
}

int VOC_TestWaitInterrupt(void)
{
    int status;
    pid_t result;
    do result = waitpid(interrupter, &status, 0); while (result < 0 && errno == EINTR);
    interrupter = -1;
    return result > 0 && WIFEXITED(status) && !WEXITSTATUS(status);
}

int VOC_TestListen(void)
{
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    socklen_t size = sizeof listener_address;
    listener_address = (struct sockaddr_in){0};
    listener_address.sin_family = AF_INET;
    listener_address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    if (fd < 0) return -1;
    if (bind(fd, (struct sockaddr *)&listener_address, size) < 0 ||
        getsockname(fd, (struct sockaddr *)&listener_address, &size) < 0 ||
        listen(fd, 1) < 0) {
        close(fd);
        return -1;
    }
    return fd;
}

int VOC_TestAccept(int fd) { return accept(fd, NULL, NULL); }
void VOC_TestClose(int fd) { close(fd); }

int VOC_TestListenerClosed(void)
{
    int fd = socket(AF_INET, SOCK_STREAM, 0), result;
    if (fd < 0) return 0;
    result = bind(fd, (struct sockaddr *)&listener_address, sizeof listener_address);
    close(fd);
    return result == 0;
}

void VOC_TestBlockInterrupt(int block)
{
    sigset_t interrupt;
    if (block) {
        sigemptyset(&interrupt);
        sigaddset(&interrupt, SIGINT);
        sigprocmask(SIG_BLOCK, &interrupt, &previous_mask);
    } else sigprocmask(SIG_SETMASK, &previous_mask, NULL);
}
