/* voc 1.95 [2016/08/12] for gcc LP64 on cygwin xtspkaSfF */

#ifndef OPV__h
#define OPV__h

#define LARGE
#include "SYSTEM.h"
#include "OPT.h"




import void OPV_AdrAndSize (OPT_Object topScope);
import void OPV_Init (void);
import void OPV_Module (OPT_Node prog);
import void OPV_TypSize (OPT_Struct typ);
import void *OPV__init(void);


#endif
