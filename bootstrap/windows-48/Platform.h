/* voc 1.95 [2016/09/04] for gcc LP64 on cygwin xtspkaSfF */

#ifndef Platform__h
#define Platform__h

#include "SYSTEM.h"

typedef
	struct Platform_FileIdentity {
		LONGINT _prvt0;
		char _prvt1[16];
	} Platform_FileIdentity;

typedef
	void (*Platform_HaltProcedure)(int32);

typedef
	void (*Platform_SignalHandler)(int16);


import BOOLEAN Platform_LittleEndian;
import address Platform_MainStackFrame;
import int32 Platform_HaltCode;
import int16 Platform_PID;
import CHAR Platform_CWD[4096];
import int16 Platform_ArgCount;
import address Platform_ArgVector;
import int16 Platform_SeekSet, Platform_SeekCur, Platform_SeekEnd;
import int32 Platform_StdIn, Platform_StdOut, Platform_StdErr;
import CHAR Platform_nl[3];

import LONGINT *Platform_FileIdentity__typ;

import BOOLEAN Platform_Absent (int16 e);
import int16 Platform_ArgPos (CHAR *s, LONGINT s__len);
import void Platform_AssertFail (int32 code);
import int16 Platform_Chdir (CHAR *n, LONGINT n__len);
import int16 Platform_Close (int32 h);
import BOOLEAN Platform_ConnectionFailed (int16 e);
import void Platform_Delay (int32 ms);
import BOOLEAN Platform_DifferentFilesystems (int16 e);
import int16 Platform_Error (void);
import void Platform_Exit (int16 code);
import void Platform_GetArg (int16 n, CHAR *val, LONGINT val__len);
import void Platform_GetClock (int32 *t, int32 *d);
import void Platform_GetEnv (CHAR *var, LONGINT var__len, CHAR *val, LONGINT val__len);
import void Platform_GetIntArg (int16 n, int32 *val);
import void Platform_GetTimeOfDay (int32 *sec, int32 *usec);
import void Platform_Halt (int32 code);
import int16 Platform_Identify (int32 h, Platform_FileIdentity *identity, LONGINT *identity__typ);
import int16 Platform_IdentifyByName (CHAR *n, LONGINT n__len, Platform_FileIdentity *identity, LONGINT *identity__typ);
import BOOLEAN Platform_Inaccessible (int16 e);
import void Platform_Init (int16 argc, address argvadr);
import void Platform_MTimeAsClock (Platform_FileIdentity i, int32 *t, int32 *d);
import int16 Platform_New (CHAR *n, LONGINT n__len, int32 *h);
import BOOLEAN Platform_NoSuchDirectory (int16 e);
import address Platform_OSAllocate (address size);
import void Platform_OSFree (address address);
import int16 Platform_OldRO (CHAR *n, LONGINT n__len, int32 *h);
import int16 Platform_OldRW (CHAR *n, LONGINT n__len, int32 *h);
import int16 Platform_Read (int32 h, address p, address l, address *n);
import int16 Platform_ReadBuf (int32 h, SYSTEM_BYTE *b, LONGINT b__len, address *n);
import int16 Platform_Rename (CHAR *o, LONGINT o__len, CHAR *n, LONGINT n__len);
import BOOLEAN Platform_SameFile (Platform_FileIdentity i1, Platform_FileIdentity i2);
import BOOLEAN Platform_SameFileTime (Platform_FileIdentity i1, Platform_FileIdentity i2);
import int16 Platform_Seek (int32 h, int32 o, int16 r);
import void Platform_SetBadInstructionHandler (Platform_SignalHandler handler);
import void Platform_SetHalt (Platform_HaltProcedure p);
import void Platform_SetMTime (Platform_FileIdentity *target, LONGINT *target__typ, Platform_FileIdentity source);
import int16 Platform_Size (int32 h, int32 *l);
import int16 Platform_Sync (int32 h);
import int16 Platform_System (CHAR *cmd, LONGINT cmd__len);
import int32 Platform_Time (void);
import BOOLEAN Platform_TimedOut (int16 e);
import BOOLEAN Platform_TooManyFiles (int16 e);
import int16 Platform_Truncate (int32 h, int32 limit);
import int16 Platform_Unlink (CHAR *n, LONGINT n__len);
import int16 Platform_Write (int32 h, int32 p, int32 l);
import BOOLEAN Platform_getEnv (CHAR *var, LONGINT var__len, CHAR *val, LONGINT val__len);
import void *Platform__init(void);

#define Platform_SetInterruptHandler(h)	SystemSetInterruptHandler((address)h)
#define Platform_SetQuitHandler(h)	SystemSetQuitHandler((address)h)

#endif
