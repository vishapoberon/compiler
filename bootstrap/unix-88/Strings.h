/* voc 1.95 [2016/09/01] for gcc LP64 on cygwin xtspkaSfF */

#ifndef Strings__h
#define Strings__h

#define LARGE
#include "SYSTEM.h"




import void Strings_Append (CHAR *extra, LONGINT extra__len, CHAR *dest, LONGINT dest__len);
import void Strings_Cap (CHAR *s, LONGINT s__len);
import void Strings_Delete (CHAR *s, LONGINT s__len, int32 pos, int32 n);
import void Strings_Extract (CHAR *source, LONGINT source__len, int32 pos, int32 n, CHAR *dest, LONGINT dest__len);
import void Strings_Insert (CHAR *source, LONGINT source__len, int32 pos, CHAR *dest, LONGINT dest__len);
import int32 Strings_Length (CHAR *s, LONGINT s__len);
import BOOLEAN Strings_Match (CHAR *string, LONGINT string__len, CHAR *pattern, LONGINT pattern__len);
import int32 Strings_Pos (CHAR *pattern, LONGINT pattern__len, CHAR *s, LONGINT s__len, int32 pos);
import void Strings_Replace (CHAR *source, LONGINT source__len, int32 pos, CHAR *dest, LONGINT dest__len);
import void *Strings__init(void);


#endif
