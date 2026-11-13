/* voc 5.0.0 [2026/11/13]. Bootstrapping compiler for address size 8, alignment 8. xrtspaSF */

#ifndef Reals__h
#define Reals__h

#include "SYSTEM.h"




import void Reals_Convert (REAL x, INT16 n, CHAR *d, ADDRESS d__len);
import void Reals_ConvertH (REAL y, CHAR *d, ADDRESS d__len);
import void Reals_ConvertHL (LONGREAL x, CHAR *d, ADDRESS d__len);
import void Reals_ConvertL (LONGREAL x, INT16 n, CHAR *d, ADDRESS d__len);
import INT16 Reals_Expo (REAL x);
import INT16 Reals_ExpoL (LONGREAL x);
import void Reals_FormatLongReal (LONGREAL value, CHAR *text, ADDRESS text__len);
import LONGREAL Reals_ParseLongReal (CHAR *text, ADDRESS text__len);
import REAL Reals_ParseReal (CHAR *text, ADDRESS text__len);
import void Reals_SetExpo (REAL *x, INT16 ex);
import void Reals_SetExpoL (LONGREAL *x, INT16 ex);
import REAL Reals_Ten (INT16 e);
import LONGREAL Reals_TenL (INT16 e);
import void *Reals__init(void);


#endif // Reals
