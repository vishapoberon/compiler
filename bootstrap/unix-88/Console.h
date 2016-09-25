/* voc 1.95 [2016/09/24]. Bootstrapping compiler for address size 8, alignment 8. xtspaSfF */

#ifndef Console__h
#define Console__h

#include "SYSTEM.h"




import void Console_Bool (BOOLEAN b);
import void Console_Char (CHAR ch);
import void Console_Flush (void);
import void Console_Hex (int32 i);
import void Console_Int (int64 i, int64 n);
import void Console_Ln (void);
import void Console_Read (CHAR *ch);
import void Console_ReadLine (CHAR *line, LONGINT line__len);
import void Console_String (CHAR *s, LONGINT s__len);
import void *Console__init(void);


#endif // Console
