/* voc 1.95 [2016/09/18] for gcc LP64 on cygwin xtspkaSfF */

#define INTEGER int16
#define LONGINT int32
#define SET     uint32

#include "SYSTEM.h"




static void Reals_BytesToHex (SYSTEM_BYTE *b, LONGINT b__len, SYSTEM_BYTE *d, LONGINT d__len);
export void Reals_Convert (REAL x, int16 n, CHAR *d, LONGINT d__len);
export void Reals_ConvertH (REAL y, CHAR *d, LONGINT d__len);
export void Reals_ConvertHL (LONGREAL x, CHAR *d, LONGINT d__len);
export void Reals_ConvertL (LONGREAL x, int16 n, CHAR *d, LONGINT d__len);
export int16 Reals_Expo (REAL x);
export int16 Reals_ExpoL (LONGREAL x);
export void Reals_SetExpo (REAL *x, int16 ex);
export REAL Reals_Ten (int16 e);
export LONGREAL Reals_TenL (int16 e);
static CHAR Reals_ToHex (int16 i);


REAL Reals_Ten (int16 e)
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

LONGREAL Reals_TenL (int16 e)
{
	LONGREAL _o_result;
	LONGREAL r, power;
	r = (LONGREAL)1;
	power = (LONGREAL)10;
	for (;;) {
		if (__ODD(e)) {
			r = r * power;
		}
		e = __ASHR(e, 1);
		if (e <= 0) {
			_o_result = r;
			return _o_result;
		}
		power = power * power;
	}
	__RETCHK;
}

int16 Reals_Expo (REAL x)
{
	int16 _o_result;
	int16 i;
	__GET((address)&x + 2, i, int16);
	_o_result = __MASK(__ASHR(i, 7), -256);
	return _o_result;
}

void Reals_SetExpo (REAL *x, int16 ex)
{
	CHAR c;
	__GET((address)x + 3, c, CHAR);
	__PUT((address)x + 3, (CHAR)(__ASHL(__ASHR((int16)c, 7), 7) + __MASK(__ASHR(ex, 1), -128)), CHAR);
	__GET((address)x + 2, c, CHAR);
	__PUT((address)x + 2, (CHAR)(__MASK((int16)c, -128) + __ASHL(__MASK(ex, -2), 7)), CHAR);
}

int16 Reals_ExpoL (LONGREAL x)
{
	int16 _o_result;
	int16 i;
	__GET((address)&x + 6, i, int16);
	_o_result = __MASK(__ASHR(i, 4), -2048);
	return _o_result;
}

void Reals_ConvertL (LONGREAL x, int16 n, CHAR *d, LONGINT d__len)
{
	int32 i, j, k;
	if (x < (LONGREAL)0) {
		x = -x;
	}
	k = 0;
	if (n > 9) {
		i = (int32)__ENTIER(x / (LONGREAL)(LONGREAL)1000000000);
		j = (int32)__ENTIER(x - i * (LONGREAL)1000000000);
		if (j < 0) {
			j = 0;
		}
		while (k < 9) {
			d[__X(k, d__len)] = (CHAR)((int)__MOD(j, 10) + 48);
			j = __DIV(j, 10);
			k += 1;
		}
	} else {
		i = (int32)__ENTIER(x);
	}
	while (k < n) {
		d[__X(k, d__len)] = (CHAR)((int)__MOD(i, 10) + 48);
		i = __DIV(i, 10);
		k += 1;
	}
}

void Reals_Convert (REAL x, int16 n, CHAR *d, LONGINT d__len)
{
	Reals_ConvertL(x, n, (void*)d, d__len);
}

static CHAR Reals_ToHex (int16 i)
{
	CHAR _o_result;
	if (i < 10) {
		_o_result = (CHAR)(i + 48);
		return _o_result;
	} else {
		_o_result = (CHAR)(i + 55);
		return _o_result;
	}
	__RETCHK;
}

static void Reals_BytesToHex (SYSTEM_BYTE *b, LONGINT b__len, SYSTEM_BYTE *d, LONGINT d__len)
{
	int16 i;
	int32 l;
	CHAR by;
	i = 0;
	l = b__len;
	while (i < l) {
		by = __VAL(CHAR, b[__X(i, b__len)]);
		d[__X(__ASHL(i, 1), d__len)] = Reals_ToHex(__ASHR((int16)by, 4));
		d[__X(__ASHL(i, 1) + 1, d__len)] = Reals_ToHex(__MASK((int16)by, -16));
		i += 1;
	}
}

void Reals_ConvertH (REAL y, CHAR *d, LONGINT d__len)
{
	Reals_BytesToHex((void*)&y, 4, (void*)d, d__len * 1);
}

void Reals_ConvertHL (LONGREAL x, CHAR *d, LONGINT d__len)
{
	Reals_BytesToHex((void*)&x, 8, (void*)d, d__len * 1);
}


export void *Reals__init(void)
{
	__DEFMOD;
	__REGMOD("Reals", 0);
/* BEGIN */
	__ENDMOD;
}
