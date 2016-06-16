/* voc  1.2 [2016/06/16] for gcc LP64 on cygwin xtpka */

#ifndef LSS__h
#define LSS__h

#define LARGE
#include "SYSTEM.h"
#include "Texts.h"

typedef
	CHAR LSS_Ident[32];


import LONGINT LSS_val;
import LSS_Ident LSS_id;
import BOOLEAN LSS_error;


import void LSS_Get (INTEGER *sym);
import void LSS_Init (Texts_Text T, LONGINT pos);
import void LSS_Mark (CHAR *msg, LONGINT msg__len);
import void *LSS__init(void);


#endif
