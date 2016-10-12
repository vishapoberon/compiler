/* voc 1.95 [2016/10/11]. Bootstrapping compiler for address size 8, alignment 8. xtspaSfF */

#define SHORTINT int8
#define INTEGER  int16
#define LONGINT  int32
#define SET      uint32

#include "SYSTEM.h"
#include "Platform.h"


static CHAR Out_buf[128];
static int16 Out_in;


export void Out_Char (CHAR ch);
export void Out_Flush (void);
export void Out_Int (int64 x, int64 n);
static int32 Out_Length (CHAR *s, LONGINT s__len);
export void Out_Ln (void);
export void Out_LongReal (LONGREAL x, int16 n);
export void Out_Open (void);
export void Out_Real (REAL x, int16 n);
static void Out_RealP (LONGREAL x, int16 n, BOOLEAN long_);
export void Out_String (CHAR *str, LONGINT str__len);
export LONGREAL Out_Ten (int16 e);
static void Out_digit (int64 n, CHAR *s, LONGINT s__len, int16 *i);
static void Out_prepend (CHAR *t, LONGINT t__len, CHAR *s, LONGINT s__len, int16 *i);

#define Out_Entier64(x)	(int64)(x)

void Out_Flush (void)
{
	int16 error;
	if (Out_in > 0) {
		error = Platform_Write(1, (address)Out_buf, Out_in);
	}
	Out_in = 0;
}

void Out_Open (void)
{
}

void Out_Char (CHAR ch)
{
	if (Out_in >= 128) {
		Out_Flush();
	}
	Out_buf[__X(Out_in, 128)] = ch;
	Out_in += 1;
	if (ch == 0x0a) {
		Out_Flush();
	}
}

static int32 Out_Length (CHAR *s, LONGINT s__len)
{
	int32 _o_result;
	int32 l;
	l = 0;
	while ((l < s__len && s[__X(l, s__len)] != 0x00)) {
		l += 1;
	}
	_o_result = l;
	return _o_result;
}

void Out_String (CHAR *str, LONGINT str__len)
{
	int32 l;
	int16 error;
	__DUP(str, str__len, CHAR);
	l = Out_Length((void*)str, str__len);
	if (Out_in + l > 128) {
		Out_Flush();
	}
	if (l > 128) {
		error = Platform_Write(1, (address)str, l);
	} else {
		__MOVE((address)str, (address)&Out_buf[__X(Out_in, 128)], l);
		Out_in += (int16)l;
	}
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
	Out_Flush();
}

static void Out_digit (int64 n, CHAR *s, LONGINT s__len, int16 *i)
{
	*i -= 1;
	s[__X(*i, s__len)] = (CHAR)(__MOD(n, 10) + 48);
}

static void Out_prepend (CHAR *t, LONGINT t__len, CHAR *s, LONGINT s__len, int16 *i)
{
	int16 j;
	int32 l;
	__DUP(t, t__len, CHAR);
	l = Out_Length((void*)t, t__len);
	if (l > *i) {
		l = *i;
	}
	*i -= (int16)l;
	j = 0;
	while (j < l) {
		s[__X(*i + j, s__len)] = t[__X(j, t__len)];
		j += 1;
	}
	__DEL(t);
}

LONGREAL Out_Ten (int16 e)
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

static void Out_RealP (LONGREAL x, int16 n, BOOLEAN long_)
{
	int16 e;
	int64 f;
	CHAR s[30];
	int16 i, el;
	LONGREAL x0;
	BOOLEAN nn, en;
	int64 m;
	int16 d, dr;
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
		if (long_) {
			el = 3;
			dr = n - 6;
			if (dr > 17) {
				dr = 17;
			}
			d = dr;
			if (d < 16) {
				d = 16;
			}
		} else {
			el = 2;
			dr = n - 5;
			if (dr > 9) {
				dr = 9;
			}
			d = dr;
			if (d < 7) {
				d = 7;
			}
		}
		if (e == 0) {
			while (el > 0) {
				i -= 1;
				s[__X(i, 30)] = '0';
				el -= 1;
			}
			i -= 1;
			s[__X(i, 30)] = '+';
			m = 0;
		} else {
			if (nn) {
				x = -x;
			}
			e = (int16)__ASHR((e - 1023) * 77, 8);
			if (e >= 0) {
				x = x / (LONGREAL)Out_Ten(e);
			} else {
				x = Out_Ten(-e) * x;
			}
			if (x >= (LONGREAL)10) {
				x =   1.00000000000000e-001 * x;
				e += 1;
			}
			en = e < 0;
			if (en) {
				e = -e;
			}
			while (el > 0) {
				Out_digit(e, (void*)s, 30, &i);
				e = __DIV(e, 10);
				el -= 1;
			}
			i -= 1;
			if (en) {
				s[__X(i, 30)] = '-';
			} else {
				s[__X(i, 30)] = '+';
			}
			x0 = Out_Ten(d - 1);
			x = x0 * x +   5.00000000000000e-001;
			if (x >= (LONGREAL)10 * x0) {
				x =   1.00000000000000e-001 * x;
				e += 1;
			}
			m = Out_Entier64(x);
		}
		i -= 1;
		if (long_) {
			s[__X(i, 30)] = 'D';
		} else {
			s[__X(i, 30)] = 'E';
		}
		if (dr < 2) {
			dr = 2;
		}
		while ((d > dr && __MOD(m, 10) == 0)) {
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

void Out_Real (REAL x, int16 n)
{
	Out_RealP(x, n, 0);
}

void Out_LongReal (LONGREAL x, int16 n)
{
	Out_RealP(x, n, 1);
}


export void *Out__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(Platform);
	__REGMOD("Out", 0);
	__REGCMD("Flush", Out_Flush);
	__REGCMD("Ln", Out_Ln);
	__REGCMD("Open", Out_Open);
/* BEGIN */
	__ENDMOD;
}
