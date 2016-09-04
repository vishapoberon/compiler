/* voc 1.95 [2016/09/04] for gcc LP64 on cygwin xtspkaSfF */

#ifndef vt100__h
#define vt100__h

#define LARGE
#include "SYSTEM.h"


import CHAR vt100_CSI[5];


import void vt100_CHA (int32 n);
import void vt100_CNL (int32 n);
import void vt100_CPL (int32 n);
import void vt100_CUB (int32 n);
import void vt100_CUD (int32 n);
import void vt100_CUF (int32 n);
import void vt100_CUP (int32 n, int32 m);
import void vt100_CUU (int32 n);
import void vt100_DECTCEMh (void);
import void vt100_DECTCEMl (void);
import void vt100_DSR (int32 n);
import void vt100_ED (int32 n);
import void vt100_EL (int32 n);
import void vt100_HVP (int32 n, int32 m);
import void vt100_IntToStr (int64 int_, CHAR *str, LONGINT str__len);
import void vt100_RCP (void);
import void vt100_SCP (void);
import void vt100_SD (int32 n);
import void vt100_SGR (int32 n);
import void vt100_SGR2 (int32 n, int32 m);
import void vt100_SU (int32 n);
import void vt100_SetAttr (CHAR *attr, LONGINT attr__len);
import void *vt100__init(void);


#endif
