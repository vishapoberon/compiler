/* voc 1.95 [2016/10/17]. Bootstrapping compiler for address size 8, alignment 8. xtspaSfF */

#ifndef VT100__h
#define VT100__h

#include "SYSTEM.h"


import CHAR VT100_CSI[5];


import void VT100_CHA (int16 n);
import void VT100_CNL (int16 n);
import void VT100_CPL (int16 n);
import void VT100_CUB (int16 n);
import void VT100_CUD (int16 n);
import void VT100_CUF (int16 n);
import void VT100_CUP (int16 n, int16 m);
import void VT100_CUU (int16 n);
import void VT100_DECTCEMh (void);
import void VT100_DECTCEMl (void);
import void VT100_DSR (int16 n);
import void VT100_ED (int16 n);
import void VT100_EL (int16 n);
import void VT100_HVP (int16 n, int16 m);
import void VT100_IntToStr (int32 int_, CHAR *str, LONGINT str__len);
import void VT100_RCP (void);
import void VT100_SCP (void);
import void VT100_SD (int16 n);
import void VT100_SGR (int16 n);
import void VT100_SGR2 (int16 n, int16 m);
import void VT100_SU (int16 n);
import void VT100_SetAttr (CHAR *attr, LONGINT attr__len);
import void *VT100__init(void);


#endif // VT100
