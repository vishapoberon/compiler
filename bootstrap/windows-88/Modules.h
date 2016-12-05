/* voc 2.00 [2016/12/05]. Bootstrapping compiler for address size 8, alignment 8. xtspaSF */

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
		INT32 refcnt;
		Modules_Cmd cmds;
		INT32 types;
		void (*enumPtrs)(void(*)(INT32));
		char _prvt0[8];
	} Modules_ModuleDesc;


import INT16 Modules_res;
import CHAR Modules_resMsg[256];
import Modules_ModuleName Modules_imported, Modules_importing;
import INT64 Modules_MainStackFrame;
import INT16 Modules_ArgCount;
import INT64 Modules_ArgVector;
import CHAR Modules_BinaryDir[1024];

import ADDRESS *Modules_ModuleDesc__typ;
import ADDRESS *Modules_CmdDesc__typ;

import INT16 Modules_ArgPos (CHAR *s, ADDRESS s__len);
import void Modules_AssertFail (INT32 code);
import void Modules_Free (CHAR *name, ADDRESS name__len, BOOLEAN all);
import void Modules_GetArg (INT16 n, CHAR *val, ADDRESS val__len);
import void Modules_GetIntArg (INT16 n, INT32 *val);
import void Modules_Halt (INT32 code);
import void Modules_Init (INT32 argc, INT64 argvadr);
import Modules_Command Modules_ThisCommand (Modules_Module mod, CHAR *name, ADDRESS name__len);
import Modules_Module Modules_ThisMod (CHAR *name, ADDRESS name__len);
import void *Modules__init(void);


#endif // Modules
