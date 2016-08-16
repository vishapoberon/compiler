/* voc 1.95 [2016/08/16] for gcc LP64 on cygwin tskSfF */

#ifndef Heap__h
#define Heap__h

#define LARGE
#include "SYSTEM.h"

typedef
	CHAR Heap_CmdName[24];

typedef
	void (*Heap_Command)(void);

typedef
	void (*Heap_EnumProc)(void(*)(SYSTEM_PTR));

typedef
	void (*Heap_Finalizer)(SYSTEM_PTR);

typedef
	struct Heap_ModuleDesc *Heap_Module;

typedef
	struct Heap_ModuleDesc {
		LONGINT _prvt0;
		char _prvt1[72];
	} Heap_ModuleDesc;

typedef
	CHAR Heap_ModuleName[20];


import SYSTEM_PTR Heap_modules;
import LONGINT Heap_allocated, Heap_heapsize;
import INTEGER Heap_FileCount;

import LONGINT *Heap_ModuleDesc__typ;

import void Heap_FINALL (void);
import void Heap_GC (BOOLEAN markStack);
import void Heap_INCREF (Heap_Module m);
import void Heap_InitHeap (void);
import void Heap_Lock (void);
import SYSTEM_PTR Heap_NEWBLK (LONGINT size);
import SYSTEM_PTR Heap_NEWREC (LONGINT tag);
import void Heap_REGCMD (Heap_Module m, Heap_CmdName name, Heap_Command cmd);
import SYSTEM_PTR Heap_REGMOD (Heap_ModuleName name, Heap_EnumProc enumPtrs);
import void Heap_REGTYP (Heap_Module m, LONGINT typ);
import void Heap_RegisterFinalizer (SYSTEM_PTR obj, Heap_Finalizer finalize);
import void Heap_Unlock (void);
import void *Heap__init(void);


#endif
