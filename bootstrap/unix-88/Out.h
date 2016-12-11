/* voc 2.00 [2016/12/11]. Bootstrapping compiler for address size 8, alignment 8. xtspaSF */

#ifndef Out__h
#define Out__h

#include "SYSTEM.h"


import BOOLEAN Out_IsConsole;


import void Out_Char (CHAR ch);
import void Out_Flush (void);
import void Out_Hex (INT64 x, INT64 n);
import void Out_HexDump (SYSTEM_BYTE *m, ADDRESS m__len);
import void Out_HexDumpAdr (INT64 a, INT64 o, INT64 l);
import void Out_Int (INT64 x, INT64 n);
import void Out_Ln (void);
import void Out_LongReal (LONGREAL x, INT16 n);
import void Out_Open (void);
import void Out_Real (REAL x, INT16 n);
import void Out_String (CHAR *str, ADDRESS str__len);
import LONGREAL Out_Ten (INT16 e);
import void *Out__init(void);


#endif // Out
