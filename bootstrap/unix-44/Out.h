/* voc 1.95 [2016/10/04]. Bootstrapping compiler for address size 8, alignment 8. tsSfF */

#ifndef Out__h
#define Out__h

#include "SYSTEM.h"




import void Out_Char (CHAR ch);
import void Out_Int (int64 x, int64 n);
import void Out_Ln (void);
import void Out_LongReal (LONGREAL x, int16 n);
import void Out_Open (void);
import void Out_Real (REAL x, int16 n);
import void Out_String (CHAR *str, LONGINT str__len);
import void *Out__init(void);


#endif // Out
