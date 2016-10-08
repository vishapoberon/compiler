/* voc 1.95 [2016/10/08]. Bootstrapping compiler for address size 8, alignment 8. xtspaSfF */

#define SHORTINT int8
#define INTEGER  int16
#define LONGINT  int32
#define SET      uint32

#include "SYSTEM.h"
#include "Platform.h"
#include "Strings.h"




export void Out_Char (CHAR ch);
export void Out_Int (int64 x, int64 n);
export void Out_Ln (void);
export void Out_LongReal (LONGREAL x, int16 n);
export void Out_Open (void);
export void Out_Real (REAL x, int16 n);
export void Out_String (CHAR *str, LONGINT str__len);
export REAL Out_Ten (int16 e);
static LONGREAL Out_TenL (int16 e);
static void Out_digit (int64 n, CHAR *s, LONGINT s__len, int16 *i);
static void Out_prepend (CHAR *t, LONGINT t__len, CHAR *s, LONGINT s__len, int16 *i);

#define Out_Entier32(x)	(int32)(x)
#define Out_Entier64(x)	(int64)(x)

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
	while ((l < str__len && str[__X(l, str__len)] != 0x00)) {
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
			s[__X(i, 22)] = (CHAR)(48 + __MOD(x, 10));
			x = __DIV(x, 10);
			i += 1;
		}
	}
	if (negative) {
		s[__X(i, 22)] = '-';
		i += 1;
	}
	while (n > (int64)i) {
		Out_Char(' ');
		n -= 1;
	}
	while (i > 0) {
		i -= 1;
		Out_Char(s[__X(i, 22)]);
	}
}

void Out_Ln (void)
{
	Out_String(Platform_NL, 3);
}

static void Out_digit (int64 n, CHAR *s, LONGINT s__len, int16 *i)
{
	*i -= 1;
	s[__X(*i, s__len)] = (CHAR)(__MOD(n, 10) + 48);
}

static void Out_prepend (CHAR *t, LONGINT t__len, CHAR *s, LONGINT s__len, int16 *i)
{
	int16 j, l;
	__DUP(t, t__len, CHAR);
	l = Strings_Length(t, t__len);
	if (l > *i) {
		l = *i;
	}
	*i -= l;
	j = 0;
	while (j < l) {
		s[__X(*i + j, s__len)] = t[__X(j, t__len)];
		j += 1;
	}
	__DEL(t);
}

REAL Out_Ten (int16 e)
{
	REAL _o_result;
	LONGREAL r, power;
	r = (LONGREAL)1;
	power = (LONGREAL)10;
	while (e > 0) {
		if (__ODD(e)) {
			r = r * power;
		}
		power = power * power;
		e = __ASHR(e, 1);
	}
	_o_result = r;
	return _o_result;
}

void Out_Real (REAL x, int16 n)
{
	int16 e;
	int32 f;
	CHAR s[30];
	int16 i;
	REAL x0;
	BOOLEAN nn, en;
	int32 m;
	int16 d;
	nn = __VAL(int32, x) < 0;
	if (nn) {
		n -= 1;
	}
	e = (int16)__MASK(__ASHR(__VAL(int32, x), 23), -256);
	f = __MASK(__VAL(int32, x), -8388608);
	i = 30;
	if (e == 255) {
		if (f == 0) {
			Out_prepend((CHAR*)"Infinity", 9, (void*)s, 30, &i);
		} else {
			Out_prepend((CHAR*)"NaN", 4, (void*)s, 30, &i);
		}
	} else {
		if (e == 0) {
			Out_prepend((CHAR*)"E+00", 5, (void*)s, 30, &i);
			m = 0;
		} else {
			if (nn) {
				x = -x;
			}
			e = __ASHR((e - 127) * 77, 8);
			if (e >= 0) {
				x = x / (REAL)Out_Ten(e);
			} else {
				x = Out_Ten(-e) * x;
			}
			if (x >= (REAL)10) {
				x =   1.0000000e-001 * x;
				e += 1;
			}
			en = e < 0;
			if (en) {
				e = -e;
			}
			d = 2;
			while (d > 0) {
				Out_digit(e, (void*)s, 30, &i);
				e = __DIV(e, 10);
				d -= 1;
			}
			if (en) {
				Out_prepend((CHAR*)"E-", 3, (void*)s, 30, &i);
			} else {
				Out_prepend((CHAR*)"E+", 3, (void*)s, 30, &i);
			}
			x0 = Out_Ten(7);
			x = x0 * x +   5.0000000e-001;
			if (x >= (REAL)10 * x0) {
				x =   1.0000000e-001 * x;
				e += 1;
			}
			m = Out_Entier32(x);
		}
		d = 8;
		while ((((d > 2 && d > n - 5)) && (int)__MOD(m, 10) == 0)) {
			m = __DIV(m, 10);
			d -= 1;
		}
		while (d > 1) {
			Out_digit(m, (void*)s, 30, &i);
			m = __DIV(m, 10);
			d -= 1;
		}
		i -= 1;
		s[__X(i, 30)] = '.';
		Out_digit(m, (void*)s, 30, &i);
	}
	n -= 30 - i;
	while (n > 0) {
		Out_Char(' ');
		n -= 1;
	}
	if (nn) {
		Out_Char('-');
	}
	while (i < 30) {
		Out_Char(s[__X(i, 30)]);
		i += 1;
	}
}

static LONGREAL Out_TenL (int16 e)
{
	LONGREAL _o_result;
	LONGREAL r, power;
	r = (LONGREAL)1;
	power = (LONGREAL)10;
	while (e > 0) {
		if (__ODD(e)) {
			r = r * power;
		}
		power = power * power;
		e = __ASHR(e, 1);
	}
	_o_result = r;
	return _o_result;
}

void Out_LongReal (LONGREAL x, int16 n)
{
	int16 e;
	int64 f;
	CHAR s[30];
	int16 i;
	LONGREAL x0;
	BOOLEAN nn, en;
	int64 m;
	int16 d;
	nn = __VAL(int64, x) < 0;
	if (nn) {
		n -= 1;
	}
	e = (int16)__MASK(__ASHR((__VAL(int64, x)), 52), -2048);
	f = __MASK((__VAL(int64, x)), -4503599627370496);
	i = 30;
	if (e == 2047) {
		if (f == 0) {
			Out_prepend((CHAR*)"Infinity", 9, (void*)s, 30, &i);
		} else {
			Out_prepend((CHAR*)"NaN", 4, (void*)s, 30, &i);
		}
	} else {
		if (e == 0) {
			Out_prepend((CHAR*)"D+000", 6, (void*)s, 30, &i);
			m = 0;
		} else {
			if (nn) {
				x = -x;
			}
			e = (int16)__ASHR((e - 1023) * 77, 8);
			if (e >= 0) {
				x = x / (LONGREAL)Out_TenL(e);
			} else {
				x = Out_TenL(-e) * x;
			}
			if (x >= (LONGREAL)10) {
				x =   1.00000000000000e-001 * x;
				e += 1;
			}
			en = e < 0;
			if (en) {
				e = -e;
			}
			d = 3;
			while (d > 0) {
				Out_digit(e, (void*)s, 30, &i);
				e = __DIV(e, 10);
				d -= 1;
			}
			if (en) {
				Out_prepend((CHAR*)"D-", 3, (void*)s, 30, &i);
			} else {
				Out_prepend((CHAR*)"D+", 3, (void*)s, 30, &i);
			}
			x0 = Out_TenL(15);
			x = x0 * x +   5.00000000000000e-001;
			if (x >= (LONGREAL)10 * x0) {
				x =   1.00000000000000e-001 * x;
				e += 1;
			}
			m = Out_Entier64(x);
		}
		d = 16;
		while ((((d > 2 && d > n - 6)) && __MOD(m, 10) == 0)) {
			m = __DIV(m, 10);
			d -= 1;
		}
		while (d > 1) {
			Out_digit(m, (void*)s, 30, &i);
			m = __DIV(m, 10);
			d -= 1;
		}
		i -= 1;
		s[__X(i, 30)] = '.';
		Out_digit(m, (void*)s, 30, &i);
	}
	n -= 30 - i;
	while (n > 0) {
		Out_Char(' ');
		n -= 1;
	}
	if (nn) {
		Out_Char('-');
	}
	while (i < 30) {
		Out_Char(s[__X(i, 30)]);
		i += 1;
	}
}


export void *Out__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(Platform);
	__MODULE_IMPORT(Strings);
	__REGMOD("Out", 0);
	__REGCMD("Ln", Out_Ln);
	__REGCMD("Open", Out_Open);
/* BEGIN */
	__ENDMOD;
}
