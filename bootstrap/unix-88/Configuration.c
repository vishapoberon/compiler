/* voc 5.4.2 [2026/11/24] for gcc LP64 on gentoo xnrtspaSF */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32

#include "SYSTEM.h"


export CHAR Configuration_versionLong[76];





export void *Configuration__init(void)
{
	__DEFMOD;
	__REGMOD("Configuration", 0);
/* BEGIN */
	__MOVE("5.4.2 [2026/11/24]. Bootstrapping compiler for address size 8, alignment 8.", Configuration_versionLong, 76);
	__ENDMOD;
}
