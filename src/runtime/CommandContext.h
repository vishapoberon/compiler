#ifndef VOC_COMMAND_CONTEXT_H
#define VOC_COMMAND_CONTEXT_H

static SYSTEM_ModuleFrame *module_frames;

void SYSTEM_EnterModule(SYSTEM_ModuleFrame *frame, void *owner)
{
    frame->previous = module_frames;
    frame->owner = owner;
    module_frames = frame;
}

void SYSTEM_LeaveModule(SYSTEM_ModuleFrame *frame)
{
    module_frames = frame->previous;
}

BOOLEAN SYSTEM_ModuleActive(void *owner)
{
    SYSTEM_ModuleFrame *frame;
    for (frame = module_frames; frame; frame = frame->previous)
        if (frame->owner == owner) return 1;
    return 0;
}

/* Included only by SYSTEM.c. The jump buffer and native signal structures
   remain entirely in C; cleanup callbacks run after this frame returns. */
#ifndef _WIN32
#include <errno.h>
#include <setjmp.h>
#include <signal.h>
#include <stddef.h>

static sigjmp_buf command_context;
static volatile sig_atomic_t command_running;
static volatile sig_atomic_t command_pending;
static volatile sig_atomic_t command_critical;

static void command_interrupt(int signal)
{
    command_pending = signal;
    /* Only record the request here. Neither cleanup nor a non-local jump is
       safe while libc or an Oberon runtime operation may be halfway through. */
}

void SYSTEM_CommandCritical(BOOLEAN enter)
{
    if (enter) ++command_critical;
    else --command_critical;
}

void SYSTEM_CheckCommandInterrupt(void)
{
    /* Called at generated Oberon statement/loop boundaries, not from the
       signal handler. Critical regions include initializers, the heap and
       native calls that may invoke Oberon callbacks. */
    if (command_running && command_pending && !command_critical)
        siglongjmp(command_context, command_pending);
}

void SYSTEM_StopCommandRecovery(void)
{
    command_running = 0;
}

INT32 SYSTEM_RunCommand(void (*command)(void))
{
    SYSTEM_ModuleFrame *saved_frames = module_frames;
    struct sigaction action = {0}, previous_action;
    sigset_t interrupt, previous_mask, pending;
    int result, signal, error;

    if (!command) return -EINVAL;
    if (command_running || command_critical) return -EBUSY;
    sigemptyset(&interrupt);
    sigaddset(&interrupt, SIGINT);
    if (sigprocmask(SIG_BLOCK, &interrupt, &previous_mask) < 0) return -errno;
    action.sa_handler = command_interrupt;
    sigemptyset(&action.sa_mask);
    /* No SA_RESTART: blocking native calls must be able to return on SIGINT. */
    if (sigaction(SIGINT, &action, &previous_action) < 0) {
        error = errno;
        sigprocmask(SIG_SETMASK, &previous_mask, NULL);
        return -error;
    }
    command_pending = 0;
    result = sigsetjmp(command_context, 1);
    if (!result) {
        command_running = 1;
        sigprocmask(SIG_SETMASK, &previous_mask, NULL);
        command();
    }
    sigprocmask(SIG_BLOCK, &interrupt, NULL);
    command_running = 0;
    /* A cancelled command's C frames no longer exist. Keep its caller's frames. */
    module_frames = saved_frames;
    if (!result) result = command_pending;
    /* Account for an interrupt arriving at the command's return boundary.
       Do not consume a signal that the caller deliberately kept blocked. */
    if (!sigismember(&previous_mask, SIGINT) && sigpending(&pending) == 0 &&
        sigismember(&pending, SIGINT) && sigwait(&interrupt, &signal) == 0)
        result = signal;
    command_pending = 0;
    sigaction(SIGINT, &previous_action, NULL);
    sigprocmask(SIG_SETMASK, &previous_mask, NULL);
    return result;
}
#else
void SYSTEM_CommandCritical(BOOLEAN enter) { (void)enter; }
void SYSTEM_CheckCommandInterrupt(void) {}
void SYSTEM_StopCommandRecovery(void) {}
INT32 SYSTEM_RunCommand(void (*command)(void)) { command(); return 0; }
#endif

#endif
