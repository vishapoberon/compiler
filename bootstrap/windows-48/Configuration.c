/* voc 4.0.6 [2026/11/06] for clang LP64 on gentoo xrtspaSF */

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
	__MOVE("4.0.6 [2026/11/06]. Bootstrapping compiler for address size 8, alignment 8.", Configuration_versionLong, 76);
	__ENDMOD;
}
