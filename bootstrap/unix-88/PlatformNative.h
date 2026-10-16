/* voc 4.0.0 [2026/10/15]. Bootstrapping compiler for address size 8, alignment 8. xrtspaSF */

#ifndef PlatformNative__h
#define PlatformNative__h

#include "SYSTEM.h"




import INT32 PlatformNative_BadFD (void);
import void PlatformNative_ClearError (void);
import INT32 PlatformNative_CloseDirectory (INT64 handle);
import INT64 PlatformNative_EntryName (INT64 entry);
import INT32 PlatformNative_Error (void);
import INT32 PlatformNative_GetTerminal (INT32 fd, INT64 state);
import UINT64 PlatformNative_InputFlags (INT64 state);
import UINT64 PlatformNative_InputRawMask (void);
import UINT64 PlatformNative_LocalFlags (INT64 state);
import UINT64 PlatformNative_LocalRawMask (void);
import INT32 PlatformNative_MakeDirectory (CHAR *path, ADDRESS path__len);
import INT32 PlatformNative_MinIndex (void);
import INT32 PlatformNative_NameTooLong (void);
import INT32 PlatformNative_NoMemory (void);
import INT64 PlatformNative_OpenDirectory (CHAR *path, ADDRESS path__len);
import INT32 PlatformNative_Overflow (void);
import INT32 PlatformNative_PathKind (CHAR *path, ADDRESS path__len, BOOLEAN follow, INT16 *kind);
import INT64 PlatformNative_ReadDirectory (INT64 handle);
import void PlatformNative_SetControl (INT64 state, INT32 index, INT32 value);
import void PlatformNative_SetInputFlags (INT64 state, UINT64 flags);
import void PlatformNative_SetLocalFlags (INT64 state, UINT64 flags);
import INT32 PlatformNative_SetTerminal (INT32 fd, INT64 state);
import INT64 PlatformNative_TerminalSize (void);
import INT32 PlatformNative_TimeIndex (void);
import INT32 PlatformNative_WindowSize (INT32 fd, INT32 *lines, INT32 *cols);
import void *PlatformNative__init(void);


#endif // PlatformNative
