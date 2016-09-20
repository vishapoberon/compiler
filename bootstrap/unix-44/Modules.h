/* voc 1.95 [2016/09/20] for gcc LP64 on cygwin xtspkaSfF */

#ifndef Modules__h
#define Modules__h

#include "SYSTEM.h"

typedef
	struct Modules_CmdDesc *Modules_Cmd;

typedef
	void (*Modules_Command)(void);

typedef
	struct Modules_CmdDesc {
		Modules_Cmd next;
		CHAR name[24];
		Modules_Command cmd;
	} Modules_CmdDesc;

typedef
	struct Modules_ModuleDesc *Modules_Module;

typedef
	CHAR Modules_ModuleName[20];

typedef
	struct Modules_ModuleDesc {
		Modules_Module next;
		Modules_ModuleName name;
		int32 refcnt;
		Modules_Cmd cmds;
		int32 types;
		void (*enumPtrs)(void(*)(int32));
		char _prvt0[8];
	} Modules_ModuleDesc;


import int16 Modules_res;
import CHAR Modules_resMsg[256];
import Modules_ModuleName Modules_imported, Modules_importing;

import LONGINT *Modules_ModuleDesc__typ;
import LONGINT *Modules_CmdDesc__typ;

import void Modules_Free (CHAR *name, LONGINT name__len, BOOLEAN all);
import Modules_Command Modules_ThisCommand (Modules_Module mod, CHAR *name, LONGINT name__len);
import Modules_Module Modules_ThisMod (CHAR *name, LONGINT name__len);
import void *Modules__init(void);

#define Modules_modules()	(Modules_Module)Heap_modules
#define Modules_setmodules(m)	Heap_modules = m

#endif // Modules
