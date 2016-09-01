/* voc 1.95 [2016/09/01] for gcc LP64 on cygwin xtspkaSfF */

#ifndef Platform__h
#define Platform__h

#define LARGE
#include "SYSTEM.h"

typedef
	struct Platform_FileIdentity {
		LONGINT _prvt0;
		char _prvt1[32];
	} Platform_FileIdentity;

typedef
	void (*Platform_HaltProcedure)(int64);

typedef
	void (*Platform_SignalHandler)(int32);


import BOOLEAN Platform_LittleEndian;
import int64 Platform_MainStackFrame, Platform_HaltCode;
import int32 Platform_PID;
import CHAR Platform_CWD[4096];
import int32 Platform_ArgCount;
import int64 Platform_ArgVector;
import int32 Platform_SeekSet, Platform_SeekCur, Platform_SeekEnd;
import int64 Platform_StdIn, Platform_StdOut, Platform_StdErr;
import CHAR Platform_nl[3];

import LONGINT *Platform_FileIdentity__typ;

import BOOLEAN Platform_Absent (int32 e);
import int32 Platform_ArgPos (CHAR *s, LONGINT s__len);
import void Platform_AssertFail (int64 code);
import int32 Platform_Chdir (CHAR *n, LONGINT n__len);
import int32 Platform_Close (int64 h);
import BOOLEAN Platform_ConnectionFailed (int32 e);
import void Platform_Delay (int64 ms);
import BOOLEAN Platform_DifferentFilesystems (int32 e);
import int32 Platform_Error (void);
import void Platform_Exit (int32 code);
import void Platform_GetArg (int32 n, CHAR *val, LONGINT val__len);
import void Platform_GetClock (int64 *t, int64 *d);
import void Platform_GetEnv (CHAR *var, LONGINT var__len, CHAR *val, LONGINT val__len);
import void Platform_GetIntArg (int32 n, int64 *val);
import void Platform_GetTimeOfDay (int64 *sec, int64 *usec);
import void Platform_Halt (int64 code);
import int32 Platform_Identify (int64 h, Platform_FileIdentity *identity, LONGINT *identity__typ);
import int32 Platform_IdentifyByName (CHAR *n, LONGINT n__len, Platform_FileIdentity *identity, LONGINT *identity__typ);
import BOOLEAN Platform_Inaccessible (int32 e);
import void Platform_Init (int32 argc, int64 argvadr);
import void Platform_MTimeAsClock (Platform_FileIdentity i, int64 *t, int64 *d);
import int32 Platform_New (CHAR *n, LONGINT n__len, int64 *h);
import BOOLEAN Platform_NoSuchDirectory (int32 e);
import int64 Platform_OSAllocate (int64 size);
import void Platform_OSFree (int64 address);
import int32 Platform_OldRO (CHAR *n, LONGINT n__len, int64 *h);
import int32 Platform_OldRW (CHAR *n, LONGINT n__len, int64 *h);
import int32 Platform_Read (int64 h, int64 p, int64 l, int64 *n);
import int32 Platform_ReadBuf (int64 h, SYSTEM_BYTE *b, LONGINT b__len, int64 *n);
import int32 Platform_Rename (CHAR *o, LONGINT o__len, CHAR *n, LONGINT n__len);
import BOOLEAN Platform_SameFile (Platform_FileIdentity i1, Platform_FileIdentity i2);
import BOOLEAN Platform_SameFileTime (Platform_FileIdentity i1, Platform_FileIdentity i2);
import int32 Platform_Seek (int64 h, int64 o, int32 r);
import void Platform_SetBadInstructionHandler (Platform_SignalHandler handler);
import void Platform_SetHalt (Platform_HaltProcedure p);
import void Platform_SetMTime (Platform_FileIdentity *target, LONGINT *target__typ, Platform_FileIdentity source);
import int32 Platform_Size (int64 h, int64 *l);
import int32 Platform_Sync (int64 h);
import int32 Platform_System (CHAR *cmd, LONGINT cmd__len);
import int64 Platform_Time (void);
import BOOLEAN Platform_TimedOut (int32 e);
import BOOLEAN Platform_TooManyFiles (int32 e);
import int32 Platform_Truncate (int64 h, int64 limit);
import int32 Platform_Unlink (CHAR *n, LONGINT n__len);
import int32 Platform_Write (int64 h, int64 p, int64 l);
import BOOLEAN Platform_getEnv (CHAR *var, LONGINT var__len, CHAR *val, LONGINT val__len);
import void *Platform__init(void);

#define Platform_SetInterruptHandler(h)	SystemSetInterruptHandler((SYSTEM_ADRINT)h)
#define Platform_SetQuitHandler(h)	SystemSetQuitHandler((SYSTEM_ADRINT)h)

#endif
