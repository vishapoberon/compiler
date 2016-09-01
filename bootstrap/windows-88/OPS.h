/* voc 1.95 [2016/09/01] for gcc LP64 on cygwin tspkaSfF */

#ifndef OPS__h
#define OPS__h

#define LARGE
#include "SYSTEM.h"

typedef
	CHAR OPS_Name[256];

typedef
	CHAR OPS_String[256];


import OPS_Name OPS_name;
import OPS_String OPS_str;
import int32 OPS_numtyp;
import int64 OPS_intval;
import REAL OPS_realval;
import LONGREAL OPS_lrlval;


import void OPS_Get (int8 *sym);
import void OPS_Init (void);
import void *OPS__init(void);


#endif
