/* voc 1.95 [2016/09/06] for gcc LP64 on cygwin xtspkaSfF */

#define INTEGER int32
#define LONGINT int64
#define SET     uint64

#include "SYSTEM.h"


export CHAR Configuration_versionLong[41];





export void *Configuration__init(void)
{
	__DEFMOD;
	__REGMOD("Configuration", 0);
/* BEGIN */
	__MOVE("1.95 [2016/09/06] for gcc LP64 on cygwin", Configuration_versionLong, 41);
	__ENDMOD;
}
