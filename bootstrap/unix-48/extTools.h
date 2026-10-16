/* voc 4.0.0 [2026/10/15]. Bootstrapping compiler for address size 8, alignment 8. xrtspaSF */

#ifndef extTools__h
#define extTools__h

#include "SYSTEM.h"


import BOOLEAN extTools_hosted;


import void extTools_Assemble (CHAR *moduleName, ADDRESS moduleName__len);
import void extTools_GenerateLauncher (CHAR *moduleName, ADDRESS moduleName__len);
import void extTools_LinkLauncher (CHAR *moduleName, ADDRESS moduleName__len, BOOLEAN embedded);
import void extTools_LinkMain (CHAR *moduleName, ADDRESS moduleName__len, BOOLEAN statically, CHAR *additionalopts, ADDRESS additionalopts__len);
import void extTools_LinkModule (CHAR *moduleName, ADDRESS moduleName__len);
import void *extTools__init(void);


#endif // extTools
