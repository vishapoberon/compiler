/* voc 4.0.0 [2026/10/15]. Bootstrapping compiler for address size 8, alignment 8. xrtspaSF */

#ifndef Platform__h
#define Platform__h

#include "SYSTEM.h"

typedef
	void (*Platform_Command)(void);

typedef
	struct Platform_FileIdentity {
		INT32 _prvt0;
		char _prvt1[16];
	} Platform_FileIdentity;

typedef
	void (*Platform_SignalHandler)(INT32);


import BOOLEAN Platform_LittleEndian;
import INT16 Platform_PID;
import CHAR Platform_CWD[4096];
import INT16 Platform_SeekSet, Platform_SeekCur, Platform_SeekEnd;
import INT64 Platform_StdIn, Platform_StdOut, Platform_StdErr;
import CHAR Platform_NL[3];

import ADDRESS *Platform_FileIdentity__typ;

import BOOLEAN Platform_Absent (INT16 e);
import INT16 Platform_Chdir (CHAR *n, ADDRESS n__len);
import INT16 Platform_Close (INT64 h);
import INT16 Platform_CloseDirectory (INT64 *handle);
import void Platform_CommandCritical (BOOLEAN enter);
import BOOLEAN Platform_ConnectionFailed (INT16 e);
import void Platform_Delay (INT32 ms);
import BOOLEAN Platform_DifferentFilesystems (INT16 e);
import INT16 Platform_Error (void);
import void Platform_Exit (INT32 code);
import void Platform_GetClock (INT32 *t, INT32 *d);
import void Platform_GetEnv (CHAR *var, ADDRESS var__len, CHAR *val, ADDRESS val__len);
import void Platform_GetTimeOfDay (INT32 *sec, INT32 *usec);
import INT16 Platform_Identify (INT64 h, Platform_FileIdentity *identity, ADDRESS *identity__typ);
import INT16 Platform_IdentifyByName (CHAR *n, ADDRESS n__len, Platform_FileIdentity *identity, ADDRESS *identity__typ);
import BOOLEAN Platform_Inaccessible (INT16 e);
import BOOLEAN Platform_Interrupted (INT16 e);
import BOOLEAN Platform_IsConsole (INT64 h);
import BOOLEAN Platform_IsDirectory (CHAR *path, ADDRESS path__len);
import void Platform_MTimeAsClock (Platform_FileIdentity i, INT32 *t, INT32 *d);
import INT16 Platform_MaxNameLength (void);
import INT16 Platform_MaxPathLength (void);
import INT16 Platform_New (CHAR *n, ADDRESS n__len, INT64 *h);
import BOOLEAN Platform_NoSuchDirectory (INT16 e);
import INT64 Platform_OSAllocate (INT64 size);
import void Platform_OSFree (INT64 address);
import INT16 Platform_OldRO (CHAR *n, ADDRESS n__len, INT64 *h);
import INT16 Platform_OldRW (CHAR *n, ADDRESS n__len, INT64 *h);
import INT16 Platform_OpenDirectory (CHAR *path, ADDRESS path__len, INT64 *handle);
import INT16 Platform_Read (INT64 h, INT64 p, INT32 l, INT32 *n);
import INT16 Platform_ReadBuf (INT64 h, SYSTEM_BYTE *b, ADDRESS b__len, INT32 *n);
import INT16 Platform_ReadDirectory (INT64 handle, CHAR *name, ADDRESS name__len, BOOLEAN *done);
import INT16 Platform_Rename (CHAR *o, ADDRESS o__len, CHAR *n, ADDRESS n__len);
import INT32 Platform_RunCommand (Platform_Command command);
import BOOLEAN Platform_SameFile (Platform_FileIdentity i1, Platform_FileIdentity i2);
import BOOLEAN Platform_SameFileTime (Platform_FileIdentity i1, Platform_FileIdentity i2);
import INT16 Platform_Seek (INT64 h, INT32 o, INT16 r);
import void Platform_SetBadInstructionHandler (Platform_SignalHandler handler);
import INT16 Platform_SetFileMTime (CHAR *n, ADDRESS n__len, INT32 year, INT32 month, INT32 day, INT32 hour, INT32 minute, INT32 second);
import void Platform_SetMTime (Platform_FileIdentity *target, ADDRESS *target__typ, Platform_FileIdentity source);
import INT16 Platform_Size (INT64 h, INT32 *l);
import INT16 Platform_Sync (INT64 h);
import INT16 Platform_System (CHAR *cmd, ADDRESS cmd__len);
import INT16 Platform_Tell (INT64 h, INT32 *offset);
import INT32 Platform_Time (void);
import BOOLEAN Platform_TimedOut (INT16 e);
import BOOLEAN Platform_TooManyFiles (INT16 e);
import INT16 Platform_Truncate (INT64 h, INT32 limit);
import INT16 Platform_Unlink (CHAR *n, ADDRESS n__len);
import INT16 Platform_Write (INT64 h, INT64 p, INT32 l);
import INT16 Platform_WriteCount (INT64 h, INT64 p, INT32 l, INT32 *n);
import BOOLEAN Platform_getEnv (CHAR *var, ADDRESS var__len, CHAR *val, ADDRESS val__len);
import void *Platform__init(void);

#define Platform_SetInterruptHandler(h)	SystemSetInterruptHandler((ADDRESS)h)
#define Platform_SetQuitHandler(h)	SystemSetQuitHandler((ADDRESS)h)

#endif // Platform
