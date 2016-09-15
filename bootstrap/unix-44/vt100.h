/* voc 1.95 [2016/09/15] for gcc LP64 on cygwin xtspkaSfF */

#ifndef vt100__h
#define vt100__h

#include "SYSTEM.h"


import CHAR vt100_CSI[5];


import void vt100_CHA (int16 n);
import void vt100_CNL (int16 n);
import void vt100_CPL (int16 n);
import void vt100_CUB (int16 n);
import void vt100_CUD (int16 n);
import void vt100_CUF (int16 n);
import void vt100_CUP (int16 n, int16 m);
import void vt100_CUU (int16 n);
import void vt100_DECTCEMh (void);
import void vt100_DECTCEMl (void);
import void vt100_DSR (int16 n);
import void vt100_ED (int16 n);
import void vt100_EL (int16 n);
import void vt100_HVP (int16 n, int16 m);
import void vt100_IntToStr (int32 int_, CHAR *str, LONGINT str__len);
import void vt100_RCP (void);
import void vt100_SCP (void);
import void vt100_SD (int16 n);
import void vt100_SGR (int16 n);
import void vt100_SGR2 (int16 n, int16 m);
import void vt100_SU (int16 n);
import void vt100_SetAttr (CHAR *attr, LONGINT attr__len);
import void *vt100__init(void);


#endif // vt100
