/* voc 1.95 [2016/10/11]. Bootstrapping compiler for address size 8, alignment 8. xtspaSfF */

#ifndef extTools__h
#define extTools__h

#include "SYSTEM.h"




import void extTools_Assemble (CHAR *moduleName, LONGINT moduleName__len);
import void extTools_LinkMain (CHAR *moduleName, LONGINT moduleName__len, BOOLEAN statically, CHAR *additionalopts, LONGINT additionalopts__len);
import void *extTools__init(void);


#endif // extTools
