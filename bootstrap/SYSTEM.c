/*
*   The body prefix file of the voc(jet backend) runtime system, Version 1.0
*
*   Copyright (c) Software Templ, 1994, 1995
*
*   Module SYSTEM is subject to change any time without prior notification.
*   Software Templ disclaims all warranties with regard to module SYSTEM,
*   in particular shall Software Templ not be liable for any damage resulting
*   from inappropriate use or modification of module SYSTEM.
*
*   Version 1.1  jt, 24.11.95  fixes for correct pointer arithmetic on Cray computers
*   jt 31.1.2007  ANSI prototypes for malloc and exit in order to avoid cc warnings
*
*/

#ifndef _WIN32
#ifndef _POSIX_C_SOURCE
#define _POSIX_C_SOURCE 200809L
#endif
#endif
#include "SYSTEM.h"
#include "stdarg.h"
#include <signal.h>

/* Compiler-maintained native stack frames and POSIX command recovery.
   The setjmp frame must remain live until the command returns; cleanup is
   performed by Oberon code after SYSTEM_RunCommand has returned. */
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

#ifndef _WIN32
#include <errno.h>
#include <setjmp.h>
#include <stddef.h>

static sigjmp_buf command_context;
static volatile sig_atomic_t command_running;
static volatile sig_atomic_t command_pending;
static volatile sig_atomic_t command_critical;

static void command_interrupt(int signal)
{
    /* A signal must not unwind libc or interrupt a runtime update. */
    command_pending = signal;
}

void SYSTEM_CommandCritical(BOOLEAN enter)
{
    if (enter) ++command_critical;
    else --command_critical;
}

void SYSTEM_CheckCommandInterrupt(void)
{
    /* Generated Oberon statement/loop boundaries are safe cancellation points. */
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
    /* No SA_RESTART: blocking native calls must return on SIGINT. */
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
    module_frames = saved_frames;
    if (!result) result = command_pending;
    /* Preserve signals deliberately blocked by the caller. */
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

/* Modular libraries resolve this symbol from their host. In particular they
   must not pull a second heap/core into an executable built with -mD. */
#ifdef VOC_CORE_RUNTIME
export const INT32 VOC_CoreABI = VOC_CORE_ABI_PROFILE;
#endif


// Procedure verions of SYSTEM.H versions used when a multiply accessed
// parameter has side effects.




INT64 SYSTEM_DIV(INT64 x, INT64 y)
{
  if (x == 0) return 0;
  if (x >= 0)
    if (y >= 0) {return x/y;}
    else        {return -((x-y-1)/(-y));}
  else
    if (y >= 0) {return -((y-x-1)/y);}
    else        {return (-x)/(-y);}
}

INT64 SYSTEM_MOD(INT64 x, INT64 y)
{
  if (x == 0) return 0;
  if (x >= 0)
    if (y >= 0) {return x % y;}
    else        {return (y+1) + ((x-1) % (-y));}
  else
    if (y >= 0) {return (y-1) - ((-x-1) % y);}
    else        {return -((-x) % (-y));}
}

INT64 SYSTEM_ENTIER(double x)
{
    INT64 y;
    if (x >= 0)
        return (INT64)x;
    else {
        y = (INT64)x;
        if (y <= x) return y; else return y - 1;
    }
}



void SYSTEM_INHERIT(ADDRESS *t, ADDRESS *t0)
{
    t -= __TPROC0OFF;
    t0 -= __TPROC0OFF;
    while (*t0 != __EOM) {*t = *t0; t--; t0--;}
}


void SYSTEM_ENUMP(void *adr, ADDRESS n, void (*P)(SYSTEM_PTR))
{
    while (n > 0) {
        P(*((SYSTEM_PTR*)adr));
        adr = ((void**)adr) + 1;
        n--;
    }
}

void SYSTEM_ENUMR(void *adr, ADDRESS *typ, ADDRESS size, ADDRESS n, void (*P)(SYSTEM_PTR))
{
    ADDRESS *t, off;
    typ++;
    while (n > 0) {
        t = typ;
        off = *t;
        while (off >= 0) {P(*(SYSTEM_PTR*)((char*)adr+off)); t++; off = *t;}
        adr = ((char*)adr) + size;
        n--;
    }
}

extern void Heap_Lock(void);
extern void Heap_Unlock(void);

SYSTEM_PTR SYSTEM_NEWARR(ADDRESS *typ, ADDRESS elemsz, int elemalgn, int nofdim, int nofdyn, ...)
{
    ADDRESS nofelems, size, dataoff, n, nptr, *x, *p, nofptrs, i, *ptab, off;
    va_list ap;
    va_start(ap, nofdyn);
    nofelems = 1;
    while (nofdim > 0) {
        nofelems = nofelems * va_arg(ap, ADDRESS); nofdim--;
        if (nofelems <= 0) __HALT(-20);
    }
    va_end(ap);
    dataoff = nofdyn * sizeof(ADDRESS);
    if (elemalgn > sizeof(ADDRESS)) {
        n = dataoff % elemalgn;
        if (n != 0) dataoff += elemalgn - n;
    }
    size = dataoff + nofelems * elemsz;
    Heap_Lock();
    if (typ == NIL) {
        /* element typ does not contain pointers */
        x = Heap_NEWBLK(size);
    }
    else if (typ == (ADDRESS*)POINTER__typ) {
        /* element type is a pointer */
        x = Heap_NEWBLK(size + nofelems * sizeof(ADDRESS));
        p = (ADDRESS*)(ADDRESS)x[-1];
        p[-nofelems] = *p;  /* build new type desc in situ: 1. copy block size; 2. setup ptr tab; 3. set sentinel; 4. patch tag */
        p -= nofelems - 1; n = 1;   /* n =1 for skipping the size field */
        while (n <= nofelems) {*p = n*sizeof(ADDRESS); p++; n++;}
        *p = - (nofelems + 1) * sizeof(ADDRESS);    /* sentinel */
        x[-1] -= nofelems * sizeof(ADDRESS);
    }
    else {
        /* element type is a record that contains pointers */
        ptab = typ + 1; nofptrs = 0;
        while (ptab[nofptrs] >= 0) {nofptrs++;} /* number of pointers per element */
        nptr = nofelems * nofptrs;  /* total number of pointers */
        x = Heap_NEWBLK(size + nptr * sizeof(ADDRESS));
        p = (ADDRESS*)(ADDRESS)x[- 1];
        p[-nptr] = *p;  /* build new type desc in situ; 1. copy block size; 2. setup ptr tab; 3. set sentinel; 4. patch tag */
        p -= nptr - 1; n = 0; off = dataoff;
        while (n < nofelems) {i = 0;
            while (i < nofptrs) {*p = off + ptab[i]; p++; i++;}
            off += elemsz; n++;
        }
        *p = - (nptr + 1) * sizeof(ADDRESS);    /* sentinel */
        x[-1] -= nptr * sizeof(ADDRESS);
    }
    if (nofdyn != 0) {
        /* setup len vector for index checks */
        va_start(ap, nofdyn);
        p = x;
        while (nofdyn > 0) {*p = va_arg(ap, ADDRESS); p++, nofdyn--;}
        va_end(ap);
    }
    Heap_Unlock();
    return x;
}

typedef void (*SystemSignalHandler)(INT32); // = Platform_SignalHandler

#ifndef _WIN32
    // Unix signal handling
    SystemSignalHandler handler[10] = {0};  // Adjust the array size to include signal 11

    ADDRESS SYSTEM_ModuleCallback(INT32 index) {
        return index >= 0 && index < 10 ? (ADDRESS)handler[index] : 0;
    }

    void segfaultHandler(int signal) {
      __HALT(-10);
    }
    // Revised signal handler to accommodate additional signals like SIGSEGV
    void signalHandler(int s) {
        if ((s >= 2 && s <= 4) || s == 11) {  // Include SIGSEGV (usually signal 11)
            if (handler[s-2]) {
                handler[s-2](s);
            }
        }
        // Ignore other signals
    }

    void SystemSetHandler(int s, ADDRESS h) {
        if ((s >= 2 && s <= 4) || s == 11) {
            int needtosetsystemhandler = handler[s-2] == 0;
            handler[s-2] = (SystemSignalHandler)h;
            if (needtosetsystemhandler) {
                struct sigaction action = {0};
                action.sa_handler = signalHandler;
                action.sa_flags = SA_RESTART;
                sigemptyset(&action.sa_mask);
                sigaction(s, &action, NULL);
            }
        }
    }

    void setupAutomaticSegfaultHandler(void) {
        SystemSetHandler(11, (ADDRESS)segfaultHandler);  // Register handler for SIGSEGV
    }

#else
    // Windows system remains as is since Windows does not use SIGSEGV in the same way
    #include "WindowsWrapper.h"

    SystemSignalHandler SystemInterruptHandler = 0;
    SystemSignalHandler SystemQuitHandler = 0;
    BOOL ConsoleCtrlHandlerSet = FALSE;

    ADDRESS SYSTEM_ModuleCallback(INT32 index) {
        if (index == 0) return (ADDRESS)SystemInterruptHandler;
        if (index == 1) return (ADDRESS)SystemQuitHandler;
        return 0;
    }

    BOOL WINAPI SystemConsoleCtrlHandler(DWORD ctrlType) {
        if ((ctrlType == CTRL_C_EVENT) || (ctrlType == CTRL_BREAK_EVENT)) {
            if (SystemInterruptHandler) {
                SystemInterruptHandler(2);  // SIGINT
                return TRUE;
            }
        } else {
            if (SystemQuitHandler) {
                SystemQuitHandler(3);  // SIGQUIT
                return TRUE;
            }
        }
        return FALSE;
    }
    void EnsureConsoleCtrlHandler(void) {
        if (!ConsoleCtrlHandlerSet) {
        SetConsoleCtrlHandler(SystemConsoleCtrlHandler, TRUE);
            ConsoleCtrlHandlerSet = TRUE;
        }
    }

    void SystemSetInterruptHandler(ADDRESS h) {
        EnsureConsoleCtrlHandler();
        SystemInterruptHandler = (SystemSignalHandler)h;
    }

    void SystemSetQuitHandler(ADDRESS h) {
        EnsureConsoleCtrlHandler();
        SystemQuitHandler = (SystemSignalHandler)h;
    }

#endif
