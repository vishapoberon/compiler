/* voc 1.95 [2016/09/03] for gcc LP64 on cygwin xtspkaSfF */

#ifndef Console__h
#define Console__h

#define LARGE
#include "SYSTEM.h"




import void Console_Bool (BOOLEAN b);
import void Console_Char (CHAR ch);
import void Console_Flush (void);
import void Console_Hex (int64 i);
import void Console_Int (int64 i, int64 n);
import void Console_Ln (void);
import void Console_Read (CHAR *ch);
import void Console_ReadLine (CHAR *line, LONGINT line__len);
import void Console_String (CHAR *s, LONGINT s__len);
import void *Console__init(void);


#endif
