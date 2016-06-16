/* voc  1.2 [2016/06/15] for gcc LP64 on cygwin xtspkaSfF */

#ifndef extTools__h
#define extTools__h

#define LARGE
#include "SYSTEM.h"




import void extTools_Assemble (CHAR *moduleName, LONGINT moduleName__len);
import void extTools_LinkMain (CHAR *moduleName, LONGINT moduleName__len, BOOLEAN statically, CHAR *additionalopts, LONGINT additionalopts__len);
import void *extTools__init(void);


#endif
