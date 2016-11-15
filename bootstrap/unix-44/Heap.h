/* voc 1.95 [2016/11/15]. Bootstrapping compiler for address size 8, alignment 8. tsSF */

#ifndef Heap__h
#define Heap__h

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
		INT32 _prvt0;
		char _prvt1[44];
	} Heap_ModuleDesc;

typedef
	CHAR Heap_ModuleName[20];


import SYSTEM_PTR Heap_modules;
import INT32 Heap_allocated, Heap_heapsize;
import INT16 Heap_FileCount;

import ADDRESS *Heap_ModuleDesc__typ;

import void Heap_FINALL (void);
import void Heap_GC (BOOLEAN markStack);
import void Heap_INCREF (Heap_Module m);
import void Heap_InitHeap (void);
import void Heap_Lock (void);
import SYSTEM_PTR Heap_NEWBLK (INT32 size);
import SYSTEM_PTR Heap_NEWREC (INT32 tag);
import void Heap_REGCMD (Heap_Module m, Heap_CmdName name, Heap_Command cmd);
import SYSTEM_PTR Heap_REGMOD (Heap_ModuleName name, Heap_EnumProc enumPtrs);
import void Heap_REGTYP (Heap_Module m, INT32 typ);
import void Heap_RegisterFinalizer (SYSTEM_PTR obj, Heap_Finalizer finalize);
import void Heap_Unlock (void);
import void *Heap__init(void);


#endif // Heap
