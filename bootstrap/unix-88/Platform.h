/* voc 4.0.0 [2026/10/15]. Bootstrapping compiler for address size 8, alignment 8. xrtspaSF */

#ifndef Platform__h
#define Platform__h

#include "SYSTEM.h"

typedef
	void (*Platform_Command)(void);

typedef
	struct Platform_FileIdentity {
		INT32 _prvt0;
		char _prvt1[8];
	} Platform_FileIdentity;

typedef
	void (*Platform_SignalHandler)(INT32);


import BOOLEAN Platform_LittleEndian;
import INT16 Platform_PID;
import CHAR Platform_CWD[256];
import INT16 Platform_SeekSet, Platform_SeekCur, Platform_SeekEnd;
import CHAR Platform_NL[3];

import ADDRESS *Platform_FileIdentity__typ;

import BOOLEAN Platform_Absent (INT16 e);
import INT16 Platform_CaptureTerminalState (INT32 h, INT64 *state);
import INT16 Platform_Chdir (CHAR *n, ADDRESS n__len);
import INT16 Platform_Close (INT32 h);
import INT16 Platform_CloseDirectory (INT64 *handle);
import void Platform_CommandCritical (BOOLEAN enter);
import BOOLEAN Platform_ConnectionFailed (INT16 e);
import INT16 Platform_CopyTerminalState (INT64 source, INT64 *copy);
import void Platform_Delay (INT32 ms);
import BOOLEAN Platform_DifferentFilesystems (INT16 e);
import INT16 Platform_Error (void);
import void Platform_Exit (INT32 code);
import void Platform_GetClock (INT32 *t, INT32 *d);
import void Platform_GetEnv (CHAR *var, ADDRESS var__len, CHAR *val, ADDRESS val__len);
import INT16 Platform_GetTerminalDimensions (INT32 h, INT32 *lines, INT32 *columns);
import INT16 Platform_GetTerminalSize (INT32 h, INT16 *lines, INT16 *columns);
import void Platform_GetTimeOfDay (INT32 *sec, INT32 *usec);
import INT16 Platform_Identify (INT32 h, Platform_FileIdentity *identity, ADDRESS *identity__typ);
import INT16 Platform_IdentifyByName (CHAR *n, ADDRESS n__len, Platform_FileIdentity *identity, ADDRESS *identity__typ);
import BOOLEAN Platform_Inaccessible (INT16 e);
import BOOLEAN Platform_Interrupted (INT16 e);
import BOOLEAN Platform_IsConsole (INT32 h);
import BOOLEAN Platform_IsDirectory (CHAR *path, ADDRESS path__len);
import void Platform_MTimeAsClock (Platform_FileIdentity i, INT32 *t, INT32 *d);
import void Platform_MakeTerminalRaw (INT64 state);
import INT16 Platform_MaxNameLength (void);
import INT16 Platform_MaxPathLength (void);
import INT16 Platform_New (CHAR *n, ADDRESS n__len, INT32 *h);
import BOOLEAN Platform_NoSuchDirectory (INT16 e);
import INT64 Platform_OSAllocate (INT64 size);
import void Platform_OSFree (INT64 address);
import INT16 Platform_OldRO (CHAR *n, ADDRESS n__len, INT32 *h);
import INT16 Platform_OldRW (CHAR *n, ADDRESS n__len, INT32 *h);
import INT16 Platform_OpenDirectory (CHAR *path, ADDRESS path__len, INT64 *handle);
import INT16 Platform_OpenFile (CHAR *n, ADDRESS n__len, INT16 access, INT16 creation, INT32 *h);
import INT16 Platform_Read (INT32 h, INT64 p, INT32 l, INT32 *n);
import INT16 Platform_ReadBuf (INT32 h, SYSTEM_BYTE *b, ADDRESS b__len, INT32 *n);
import INT16 Platform_ReadDirectory (INT64 handle, CHAR *name, ADDRESS name__len, BOOLEAN *done);
import void Platform_ReleaseTerminalState (INT64 *state);
import INT16 Platform_Rename (CHAR *o, ADDRESS o__len, CHAR *n, ADDRESS n__len);
import INT16 Platform_RestoreTerminalState (INT32 h, INT64 state);
import INT32 Platform_RunCommand (Platform_Command command);
import BOOLEAN Platform_SameFile (Platform_FileIdentity i1, Platform_FileIdentity i2);
import BOOLEAN Platform_SameFileTime (Platform_FileIdentity i1, Platform_FileIdentity i2);
import BOOLEAN Platform_SameTerminal (INT32 first, INT32 second);
import INT16 Platform_Seek (INT32 h, INT32 offset, INT16 whence);
import void Platform_SetBadInstructionHandler (Platform_SignalHandler handler);
import INT16 Platform_SetFileMTime (CHAR *n, ADDRESS n__len, INT32 year, INT32 month, INT32 day, INT32 hour, INT32 minute, INT32 second);
import void Platform_SetInterruptHandler (Platform_SignalHandler handler);
import void Platform_SetMTime (Platform_FileIdentity *target, ADDRESS *target__typ, Platform_FileIdentity source);
import void Platform_SetQuitHandler (Platform_SignalHandler handler);
import INT16 Platform_SetTerminalEcho (INT32 h, BOOLEAN enabled);
import INT16 Platform_SetTerminalInputMode (INT32 h, BOOLEAN raw);
import INT16 Platform_SetTerminalOutputMode (INT32 h, BOOLEAN raw);
import void Platform_SetTerminalTimeout (INT64 state, INT16 tenths);
import INT16 Platform_Size (INT32 h, INT32 *l);
import INT16 Platform_Sync (INT32 h);
import INT16 Platform_System (CHAR *cmd, ADDRESS cmd__len);
import INT16 Platform_Tell (INT32 h, INT32 *offset);
import INT32 Platform_Time (void);
import BOOLEAN Platform_TimedOut (INT16 e);
import BOOLEAN Platform_TooManyFiles (INT16 e);
import INT16 Platform_Truncate (INT32 h, INT32 l);
import INT16 Platform_Unlink (CHAR *n, ADDRESS n__len);
import INT16 Platform_Write (INT32 h, INT64 p, INT32 l);
import INT16 Platform_WriteCount (INT32 h, INT64 p, INT32 l, INT32 *n);
import BOOLEAN Platform_getEnv (CHAR *var, ADDRESS var__len, CHAR *val, ADDRESS val__len);
import void *Platform__init(void);


#endif // Platform
