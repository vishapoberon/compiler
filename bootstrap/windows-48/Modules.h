/* voc 4.0.0 [2026/10/15]. Bootstrapping compiler for address size 8, alignment 8. xrtspaSF */

#ifndef Modules__h
#define Modules__h

#include "SYSTEM.h"
#include "Heap.h"

typedef
	void (*Modules_FreeHandler)(CHAR*, ADDRESS , BOOLEAN);


import INT16 Modules_res;
import CHAR Modules_resMsg[256];
import Heap_ModuleName Modules_imported, Modules_importing;
import INT32 Modules_MainStackFrame;
import INT16 Modules_ArgCount;
import INT32 Modules_ArgVector;
import CHAR Modules_BinaryDir[1024];


import INT16 Modules_ArgPos (CHAR *s, ADDRESS s__len);
import void Modules_AssertFail (INT32 code);
import void Modules_Free (CHAR *name, ADDRESS name__len, BOOLEAN all);
import void Modules_GetArg (INT16 n, CHAR *val, ADDRESS val__len);
import void Modules_GetIntArg (INT16 n, INT32 *val);
import void Modules_Halt (INT32 code);
import void Modules_Init (INT32 argc, INT32 argvadr);
import void Modules_InstallFreeHandler (Modules_FreeHandler handler);
import void Modules_InstallTermHandler (Heap_Command handler);
import void Modules_Release (Heap_Retention *retention);
import Heap_Retention Modules_Retain (Heap_Module owner);
import Heap_Command Modules_ThisCommand (Heap_Module mod, CHAR *name, ADDRESS name__len);
import Heap_Module Modules_ThisMod (CHAR *name, ADDRESS name__len);
import void *Modules__init(void);


#endif // Modules
