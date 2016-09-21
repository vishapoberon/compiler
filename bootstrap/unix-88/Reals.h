/* voc 1.95 [2016/09/21] for gcc LP64 on cygwin xtspkaSfF */

#ifndef Reals__h
#define Reals__h

#include "SYSTEM.h"




import void Reals_Convert (REAL x, int32 n, CHAR *d, LONGINT d__len);
import void Reals_ConvertH (REAL y, CHAR *d, LONGINT d__len);
import void Reals_ConvertHL (LONGREAL x, CHAR *d, LONGINT d__len);
import void Reals_ConvertL (LONGREAL x, int32 n, CHAR *d, LONGINT d__len);
import int32 Reals_Expo (REAL x);
import int32 Reals_ExpoL (LONGREAL x);
import void Reals_SetExpo (REAL *x, int32 ex);
import REAL Reals_Ten (int32 e);
import LONGREAL Reals_TenL (int32 e);
import void *Reals__init(void);


#endif // Reals
