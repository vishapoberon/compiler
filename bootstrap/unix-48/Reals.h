/* voc 1.95 [2016/10/15]. Bootstrapping compiler for address size 8, alignment 8. xtspaSfF */

#ifndef Reals__h
#define Reals__h

#include "SYSTEM.h"




import void Reals_Convert (REAL x, int16 n, CHAR *d, LONGINT d__len);
import void Reals_ConvertH (REAL y, CHAR *d, LONGINT d__len);
import void Reals_ConvertHL (LONGREAL x, CHAR *d, LONGINT d__len);
import void Reals_ConvertL (LONGREAL x, int16 n, CHAR *d, LONGINT d__len);
import int16 Reals_Expo (REAL x);
import int16 Reals_ExpoL (LONGREAL x);
import void Reals_SetExpo (REAL *x, int16 ex);
import REAL Reals_Ten (int16 e);
import LONGREAL Reals_TenL (int16 e);
import void *Reals__init(void);


#endif // Reals
