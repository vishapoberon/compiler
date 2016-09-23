/* voc 1.95 [2016/09/23]. Bootstrapping compiler for address size 8, alignment 8. tspaSfF */

#ifndef OPS__h
#define OPS__h

#include "SYSTEM.h"

typedef
	CHAR OPS_Name[256];

typedef
	CHAR OPS_String[256];


import OPS_Name OPS_name;
import OPS_String OPS_str;
import int16 OPS_numtyp;
import int64 OPS_intval;
import REAL OPS_realval;
import LONGREAL OPS_lrlval;


import void OPS_Get (int8 *sym);
import void OPS_Init (void);
import void *OPS__init(void);


#endif // OPS
