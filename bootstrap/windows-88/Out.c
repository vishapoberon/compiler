/* voc 1.95 [2016/10/03]. Bootstrapping compiler for address size 8, alignment 8. tsSfF */

#define SHORTINT int8
#define INTEGER  int16
#define LONGINT  int32
#define SET      uint32

#include "SYSTEM.h"
#include "Platform.h"




export void Out_Char (CHAR ch);
export void Out_Int (int64 x, int64 n);
export void Out_Ln (void);
export void Out_LongReal (LONGREAL x, int16 n);
export void Out_Open (void);
export void Out_Real (REAL x, int16 n);
export void Out_String (CHAR *str, LONGINT str__len);


void Out_Open (void)
{
}

void Out_Char (CHAR ch)
{
	int16 error;
	error = Platform_Write(Platform_StdOut, (address)&ch, 1);
}

void Out_String (CHAR *str, LONGINT str__len)
{
	int32 l;
	int16 error;
	__DUP(str, str__len, CHAR);
	l = 0;
	while ((l < str__len && str[l] != 0x00)) {
		l += 1;
	}
	error = Platform_Write(Platform_StdOut, (address)str, l);
	__DEL(str);
}

void Out_Int (int64 x, int64 n)
{
	CHAR s[22];
	int16 i;
	BOOLEAN negative;
	negative = x < 0;
	if (x == (-9223372036854775807-1)) {
		__MOVE("8085774586302733229", s, 20);
		i = 19;
	} else {
		if (x < 0) {
			x = -x;
		}
		s[0] = (CHAR)(48 + __MOD(x, 10));
		x = __DIV(x, 10);
		i = 1;
		while (x != 0) {
			s[i] = (CHAR)(48 + __MOD(x, 10));
			x = __DIV(x, 10);
			i += 1;
		}
	}
	if (negative) {
		s[i] = '-';
		i += 1;
	}
	while (n > (int64)i) {
		Out_Char(' ');
		n -= 1;
	}
	while (i > 0) {
		i -= 1;
		Out_Char(s[i]);
	}
}

void Out_Real (REAL x, int16 n)
{
}

void Out_LongReal (LONGREAL x, int16 n)
{
}

void Out_Ln (void)
{
	Out_String(Platform_NL, 3);
}


export void *Out__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(Platform);
	__REGMOD("Out", 0);
	__REGCMD("Ln", Out_Ln);
	__REGCMD("Open", Out_Open);
/* BEGIN */
	__ENDMOD;
}
