/* voc 4.0.0 [2026/10/15]. Bootstrapping compiler for address size 8, alignment 8. xrtspaSF */

#ifndef PlatformNative__h
#define PlatformNative__h

#include "SYSTEM.h"




import INT32 PlatformNative_Attributes (CHAR *path, ADDRESS path__len);
import BOOLEAN PlatformNative_Close (INT32 search);
import BOOLEAN PlatformNative_Directory (INT32 value);
import INT32 PlatformNative_DirectoryError (void);
import INT32 PlatformNative_EntryName (INT32 entry);
import INT32 PlatformNative_EntrySize (void);
import INT32 PlatformNative_Error (void);
import INT32 PlatformNative_First (CHAR *pattern, ADDRESS pattern__len, INT32 entry);
import INT32 PlatformNative_Invalid (void);
import BOOLEAN PlatformNative_InvalidAttributes (INT32 value);
import INT32 PlatformNative_NameTooLong (void);
import BOOLEAN PlatformNative_Next (INT32 search, INT32 entry);
import BOOLEAN PlatformNative_NoFiles (INT32 error);
import INT32 PlatformNative_NoMemory (void);
import BOOLEAN PlatformNative_NoMoreFiles (INT32 error);
import void *PlatformNative__init(void);


#endif // PlatformNative
