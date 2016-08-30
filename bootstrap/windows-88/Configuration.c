/* voc 1.95 [2016/08/30] for gcc LP64 on cygwin xtspkaSfF */
#define LARGE
#include "SYSTEM.h"


export CHAR Configuration_versionLong[41];





export void *Configuration__init(void)
{
	__DEFMOD;
	__REGMOD("Configuration", 0);
/* BEGIN */
	__MOVE("1.95 [2016/08/30] for gcc LP64 on cygwin", Configuration_versionLong, 41);
	__ENDMOD;
}
