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

#include "SYSTEM.h"
#include "stdarg.h"
#include <signal.h>


// Procedure verions of SYSTEM.H versions used when a multiply accessed
// parameter has side effects.

int64 SYSTEM_XCHK(uint64 i, uint64 ub) {return __X(i, ub);}
int64 SYSTEM_RCHK(uint64 i, uint64 ub) {return __R(i, ub);}
LONGINT SYSTEM_ASH (LONGINT i, LONGINT n)  {return __ASH(i, n);}
LONGINT SYSTEM_ABS (LONGINT i)             {return __ABS(i);}
double  SYSTEM_ABSD(double i)              {return __ABS(i);}

void SYSTEM_INHERIT(LONGINT *t, LONGINT *t0)
{
    t -= __TPROC0OFF;
    t0 -= __TPROC0OFF;
    while (*t0 != __EOM) {*t = *t0; t--; t0--;}
}


void SYSTEM_ENUMP(void *adr, LONGINT n, void (*P)())
{
    while (n > 0) {
        P((uintptr)(*((void**)(adr))));
        adr = ((void**)adr) + 1;
        n--;
    }
}

void SYSTEM_ENUMR(void *adr, LONGINT *typ, LONGINT size, LONGINT n, void (*P)())
{
    LONGINT *t, off;
    typ++;
    while (n > 0) {
        t = typ;
        off = *t;
        while (off >= 0) {P(*(uintptr*)((char*)adr+off)); t++; off = *t;}
        adr = ((char*)adr) + size;
        n--;
    }
}

LONGINT SYSTEM_DIV(uint64 x, uint64 y)
{   if ((int64) x >= 0) return (x / y);
    else return -((y - 1 - x) / y);
}

LONGINT SYSTEM_MOD(uint64 x, uint64 y)
{   uint64 m;
    if ((int64) x >= 0) return (x % y);
    else { m = (-x) % y;
        if (m != 0) return (y - m); else return 0;
    }
}

LONGINT SYSTEM_ENTIER(double x)
{
    LONGINT y;
    if (x >= 0)
        return (LONGINT)x;
    else {
        y = (LONGINT)x;
        if (y <= x) return y; else return y - 1;
    }
}

extern void Heap_Lock();
extern void Heap_Unlock();

SYSTEM_PTR SYSTEM_NEWARR(LONGINT *typ, LONGINT elemsz, int elemalgn, int nofdim, int nofdyn, ...)
{
    LONGINT nofelems, size, dataoff, n, nptr, *x, *p, nofptrs, i, *ptab, off;
    va_list ap;
    va_start(ap, nofdyn);
    nofelems = 1;
    while (nofdim > 0) {
        nofelems = nofelems * va_arg(ap, LONGINT); nofdim--;
        if (nofelems <= 0) __HALT(-20);
    }
    va_end(ap);
    dataoff = nofdyn * sizeof(LONGINT);
    if (elemalgn > sizeof(LONGINT)) {
        n = dataoff % elemalgn;
        if (n != 0) dataoff += elemalgn - n;
    }
    size = dataoff + nofelems * elemsz;
    Heap_Lock();
    if (typ == NIL) {
        /* element typ does not contain pointers */
        x = Heap_NEWBLK(size);
    }
    else if (typ == (LONGINT*)POINTER__typ) {
        /* element type is a pointer */
        x = Heap_NEWBLK(size + nofelems * sizeof(LONGINT));
        p = (LONGINT*)(uintptr)x[-1];
        p[-nofelems] = *p;  /* build new type desc in situ: 1. copy block size; 2. setup ptr tab; 3. set sentinel; 4. patch tag */
        p -= nofelems - 1; n = 1;   /* n =1 for skipping the size field */
        while (n <= nofelems) {*p = n*sizeof(LONGINT); p++; n++;}
        *p = - (nofelems + 1) * sizeof(LONGINT);    /* sentinel */
        x[-1] -= nofelems * sizeof(LONGINT);
    }
    else {
        /* element type is a record that contains pointers */
        ptab = typ + 1; nofptrs = 0;
        while (ptab[nofptrs] >= 0) {nofptrs++;} /* number of pointers per element */
        nptr = nofelems * nofptrs;  /* total number of pointers */
        x = Heap_NEWBLK(size + nptr * sizeof(LONGINT));
        p = (LONGINT*)(uintptr)x[- 1];
        p[-nptr] = *p;  /* build new type desc in situ; 1. copy block size; 2. setup ptr tab; 3. set sentinel; 4. patch tag */
        p -= nptr - 1; n = 0; off = dataoff;
        while (n < nofelems) {i = 0;
            while (i < nofptrs) {*p = off + ptab[i]; p++; i++;}
            off += elemsz; n++;
        }
        *p = - (nptr + 1) * sizeof(LONGINT);    /* sentinel */
        x[-1] -= nptr * sizeof(LONGINT);
    }
    if (nofdyn != 0) {
        /* setup len vector for index checks */
        va_start(ap, nofdyn);
        p = x;
        while (nofdyn > 0) {*p = va_arg(ap, LONGINT); p++, nofdyn--;}
        va_end(ap);
    }
    Heap_Unlock();
    return x;
}




typedef void (*SystemSignalHandler)(INTEGER); // = Platform_SignalHandler

#ifndef _WIN32

    SystemSignalHandler handler[3] = {0};

    // Provide signal handling for Unix based systems
    void signalHandler(int s) {
        if (s >= 2  &&  s <= 4) handler[s-2](s);
        // (Ignore other signals)
    }

    void SystemSetHandler(int s, uintptr h) {
        if (s >= 2 && s <= 4) {
            int needtosetsystemhandler = handler[s-2] == 0;
            handler[s-2] = (SystemSignalHandler)h;
            if (needtosetsystemhandler) {signal(s, signalHandler);}
        }
    }

#else

    // Provides Windows callback handlers for signal-like scenarios
    #include "WindowsWrapper.h"

    SystemSignalHandler SystemInterruptHandler = 0;
    SystemSignalHandler SystemQuitHandler      = 0;
    BOOL ConsoleCtrlHandlerSet = FALSE;

    BOOL WINAPI SystemConsoleCtrlHandler(DWORD ctrlType) {
        if ((ctrlType == CTRL_C_EVENT) || (ctrlType == CTRL_BREAK_EVENT)) {
            if (SystemInterruptHandler) {
                SystemInterruptHandler(2); // SIGINT
                return TRUE;
            }
        } else { // Close, logoff or shutdown
            if (SystemQuitHandler) {
                SystemQuitHandler(3); // SIGQUIT
                return TRUE;
            }
        }
        return FALSE;
    }

    void EnsureConsoleCtrlHandler() {
        if (!ConsoleCtrlHandlerSet) {
        SetConsoleCtrlHandler(SystemConsoleCtrlHandler, TRUE);
            ConsoleCtrlHandlerSet = TRUE;
        }
    }

    void SystemSetInterruptHandler(uintptr h) {
        EnsureConsoleCtrlHandler();
        SystemInterruptHandler = (SystemSignalHandler)h;
    }

    void SystemSetQuitHandler(uintptr h) {
        EnsureConsoleCtrlHandler();
        SystemQuitHandler = (SystemSignalHandler)h;
    }

#endif
