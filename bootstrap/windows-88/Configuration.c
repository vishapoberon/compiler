/* voc 1.95 [2016/10/03]. Bootstrapping compiler for address size 8, alignment 8. xtspaSfF */

#define SHORTINT int8
#define INTEGER  int16
#define LONGINT  int32
#define SET      uint32

#include "SYSTEM.h"


export CHAR Configuration_versionLong[75];





export void *Configuration__init(void)
{
	__DEFMOD;
	__REGMOD("Configuration", 0);
/* BEGIN */
	__MOVE("1.95 [2016/10/03]. Bootstrapping compiler for address size 8, alignment 8.", Configuration_versionLong, 75);
	__ENDMOD;
}
