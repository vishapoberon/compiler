/* voc 1.95 [2016/08/30] for gcc LP64 on cygwin xtspkaSfF */

#ifndef vt100__h
#define vt100__h

#define LARGE
#include "SYSTEM.h"


import CHAR vt100_CSI[5];


import void vt100_CHA (INTEGER n);
import void vt100_CNL (INTEGER n);
import void vt100_CPL (INTEGER n);
import void vt100_CUB (INTEGER n);
import void vt100_CUD (INTEGER n);
import void vt100_CUF (INTEGER n);
import void vt100_CUP (INTEGER n, INTEGER m);
import void vt100_CUU (INTEGER n);
import void vt100_DECTCEMh (void);
import void vt100_DECTCEMl (void);
import void vt100_DSR (INTEGER n);
import void vt100_ED (INTEGER n);
import void vt100_EL (INTEGER n);
import void vt100_HVP (INTEGER n, INTEGER m);
import void vt100_IntToStr (LONGINT int_, CHAR *str, LONGINT str__len);
import void vt100_RCP (void);
import void vt100_SCP (void);
import void vt100_SD (INTEGER n);
import void vt100_SGR (INTEGER n);
import void vt100_SGR2 (INTEGER n, INTEGER m);
import void vt100_SU (INTEGER n);
import void vt100_SetAttr (CHAR *attr, LONGINT attr__len);
import void *vt100__init(void);


#endif
