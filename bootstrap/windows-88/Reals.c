/* voc 1.95 [2016/09/01] for gcc LP64 on cygwin xtspkaSfF */
#define LARGE
#include "SYSTEM.h"




static void Reals_BytesToHex (SYSTEM_BYTE *b, LONGINT b__len, SYSTEM_BYTE *d, LONGINT d__len);
export void Reals_Convert (REAL x, int32 n, CHAR *d, LONGINT d__len);
export void Reals_ConvertH (REAL y, CHAR *d, LONGINT d__len);
export void Reals_ConvertHL (LONGREAL x, CHAR *d, LONGINT d__len);
export void Reals_ConvertL (LONGREAL x, int32 n, CHAR *d, LONGINT d__len);
export int32 Reals_Expo (REAL x);
export int32 Reals_ExpoL (LONGREAL x);
export void Reals_SetExpo (REAL *x, int32 ex);
export REAL Reals_Ten (int32 e);
export LONGREAL Reals_TenL (int32 e);
static CHAR Reals_ToHex (int32 i);


REAL Reals_Ten (int32 e)
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

LONGREAL Reals_TenL (int32 e)
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

int32 Reals_Expo (REAL x)
{
	int32 _o_result;
	int32 i;
	__GET((SYSTEM_ADRINT)&x + 2, i, int32);
	_o_result = __MASK(__ASHR(i, 7), -256);
	return _o_result;
}

void Reals_SetExpo (REAL *x, int32 ex)
{
	CHAR c;
	__GET((SYSTEM_ADRINT)x + 3, c, CHAR);
	__PUT((SYSTEM_ADRINT)x + 3, (CHAR)(__ASHL(__ASHR(c, 7), 7) + __MASK(__ASHR(ex, 1), -128)), CHAR);
	__GET((SYSTEM_ADRINT)x + 2, c, CHAR);
	__PUT((SYSTEM_ADRINT)x + 2, (CHAR)(__MASK(c, -128) + __ASHL(__MASK(ex, -2), 7)), CHAR);
}

int32 Reals_ExpoL (LONGREAL x)
{
	int32 _o_result;
	int32 i;
	__GET((SYSTEM_ADRINT)&x + 6, i, int32);
	_o_result = __MASK(__ASHR(i, 4), -2048);
	return _o_result;
}

void Reals_ConvertL (LONGREAL x, int32 n, CHAR *d, LONGINT d__len)
{
	int64 i, j, k;
	if (x < (LONGREAL)0) {
		x = -x;
	}
	k = 0;
	i = __ENTIER(x);
	while (k < (int64)n) {
		d[__X(k, d__len)] = (CHAR)(__MOD(i, 10) + 48);
		i = __DIV(i, 10);
		k += 1;
	}
}

void Reals_Convert (REAL x, int32 n, CHAR *d, LONGINT d__len)
{
	Reals_ConvertL(x, n, (void*)d, d__len);
}

static CHAR Reals_ToHex (int32 i)
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
	int32 i;
	int64 l;
	CHAR by;
	i = 0;
	l = b__len;
	while ((int64)i < l) {
		by = __VAL(CHAR, b[__X(i, b__len)]);
		d[__X(__ASHL(i, 1), d__len)] = Reals_ToHex(__ASHR(by, 4));
		d[__X(__ASHL(i, 1) + 1, d__len)] = Reals_ToHex(__MASK(by, -16));
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
