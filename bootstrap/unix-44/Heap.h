/* voc 4.0.0 [2026/10/15]. Bootstrapping compiler for address size 8, alignment 8. rtsSF */

#ifndef Heap__h
#define Heap__h

#include "SYSTEM.h"

typedef
	struct Heap_CmdDesc *Heap_Cmd;

typedef
	CHAR Heap_CmdName[24];

typedef
	void (*Heap_Command)(void);

typedef
	struct Heap_CmdDesc {
		Heap_Cmd next;
		Heap_CmdName name;
		Heap_Command cmd;
	} Heap_CmdDesc;

typedef
	void (*Heap_EnumProc)(void(*)(SYSTEM_PTR));

typedef
	void (*Heap_Finalizer)(SYSTEM_PTR);

typedef
	struct Heap_ModuleDesc *Heap_Module;

typedef
	CHAR Heap_ModuleName[20];

typedef
	struct Heap_ModuleDesc {
		Heap_Module next;
		Heap_ModuleName name;
		INT32 refcnt;
		Heap_Cmd cmds;
		INT32 types;
		Heap_EnumProc enumPtrs;
		char _prvt0[8];
	} Heap_ModuleDesc;

typedef
	void (*Heap_ModuleNotifier)(Heap_Module, INT32);

typedef
	struct Heap_RetentionDesc *Heap_Retention;

typedef
	struct Heap_RetentionDesc {
		INT32 _prvt0;
		char _prvt1[4];
	} Heap_RetentionDesc;

typedef
	void (*Heap_UnloadHandler)(Heap_Module);


import SYSTEM_PTR Heap_modules;
import INT32 Heap_allocated;
import INT32 Heap_heap;
import INT32 Heap_heapsize, Heap_heapMinExpand;
import INT16 Heap_FileCount;

import ADDRESS *Heap_ModuleDesc__typ;
import ADDRESS *Heap_RetentionDesc__typ;
import ADDRESS *Heap_CmdDesc__typ;

import void Heap_BeginFree (Heap_Module owner);
import INT16 Heap_CheckModule (Heap_Module owner);
import BOOLEAN Heap_CollectModule (Heap_Module owner);
import void Heap_CommitFree (Heap_Module owner);
import void Heap_DetachCallbacks (Heap_Module owner);
import void Heap_DisableModule (Heap_Module owner);
import void Heap_FINALL (void);
import void Heap_FINALMOD (Heap_Module owner);
import BOOLEAN Heap_Finishable (Heap_Module owner);
import INT32 Heap_FreeModule (CHAR *name, ADDRESS name__len);
import void Heap_GC (BOOLEAN markStack);
import BOOLEAN Heap_HasFinalizers (Heap_Module owner);
import void Heap_INCREF (Heap_Module m);
import Heap_Module Heap_Imported (Heap_Module owner, INT16 index);
import void Heap_InitHeap (void);
import BOOLEAN Heap_InstallTermHandler (Heap_Command handler);
import BOOLEAN Heap_LiveTypes (Heap_Module owner);
import void Heap_Lock (void);
import void Heap_MODREADY (Heap_Module owner, INT32 initializer);
import INT16 Heap_ModuleState (Heap_Module owner);
import SYSTEM_PTR Heap_NEWBLK (INT32 size);
import SYSTEM_PTR Heap_NEWREC (INT32 tag);
import Heap_Module Heap_ProcedureModule (INT32 address);
import void Heap_REGCMD (Heap_Module m, CHAR *name, Heap_Command cmd);
import void Heap_REGIMPORT (Heap_Module owner, Heap_Module imported);
import SYSTEM_PTR Heap_REGMOD (CHAR *name, Heap_EnumProc enumPtrs);
import void Heap_REGPROC (Heap_Module m, INT32 address);
import void Heap_REGTYP (Heap_Module m, INT32 typ);
import void Heap_RegisterFinalizer (SYSTEM_PTR obj, Heap_Finalizer finalize);
import BOOLEAN Heap_RegisterUnloadHook (Heap_UnloadHandler handler);
import BOOLEAN Heap_ReleaseModule (Heap_Retention r);
import Heap_Retention Heap_RetainModule (Heap_Module owner);
import Heap_Retention Heap_RetainProcedure (INT32 address);
import INT32 Heap_Retained (Heap_Module owner);
import void Heap_SetModuleNotifier (Heap_ModuleNotifier handler);
import void Heap_Unlock (void);
import BOOLEAN Heap_UnregisterUnloadHook (Heap_UnloadHandler handler);
import void *Heap__init(void);


#endif // Heap
