/* voc 1.95 [2016/08/12] for gcc LP64 on cygwin xtspkaSfF */
#define LARGE
#include "SYSTEM.h"




export void Reals_Convert (REAL x, INTEGER n, CHAR *d, LONGINT d__len);
export void Reals_ConvertH (REAL y, CHAR *d, LONGINT d__len);
export void Reals_ConvertHL (LONGREAL y, CHAR *d, LONGINT d__len);
export void Reals_ConvertL (LONGREAL x, INTEGER n, CHAR *d, LONGINT d__len);
export INTEGER Reals_Expo (REAL x);
export INTEGER Reals_ExpoL (LONGREAL x);
export REAL Reals_Ten (INTEGER e);
export LONGREAL Reals_TenL (INTEGER e);
static CHAR Reals_ToHex (INTEGER i);


REAL Reals_Ten (INTEGER e)
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

LONGREAL Reals_TenL (INTEGER e)
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

INTEGER Reals_Expo (REAL x)
{
	INTEGER _o_result;
	_o_result = (int)__MASK(__ASHR((LONGINT)(__VAL(INTEGER, x)), 23), -256);
	return _o_result;
}

INTEGER Reals_ExpoL (LONGREAL x)
{
	INTEGER _o_result;
	INTEGER i;
	LONGINT l;
	__GET((LONGINT)(uintptr_t)&x + 4, i, INTEGER);
	_o_result = (int)__MASK(__ASHR((LONGINT)i, 20), -2048);
	return _o_result;
}

void Reals_ConvertL (LONGREAL x, INTEGER n, CHAR *d, LONGINT d__len)
{
	LONGINT i, j, k;
	if (x < (LONGREAL)0) {
		x = -x;
	}
	k = 0;
	i = __ENTIER(x);
	while (k < (LONGINT)n) {
		d[__X(k, d__len)] = (CHAR)(__MOD(i, 10) + 48);
		i = __DIV(i, 10);
		k += 1;
	}
}

void Reals_Convert (REAL x, INTEGER n, CHAR *d, LONGINT d__len)
{
	Reals_ConvertL(x, n, (void*)d, d__len);
}

static CHAR Reals_ToHex (INTEGER i)
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

typedef
	CHAR (*pc4__3)[4];

void Reals_ConvertH (REAL y, CHAR *d, LONGINT d__len)
{
	pc4__3 p = NIL;
	INTEGER i;
	p = (pc4__3)(uintptr_t)((LONGINT)(uintptr_t)&y);
	i = 0;
	while (i < 4) {
		d[__X(__ASHL(i, 1), d__len)] = Reals_ToHex(__ASHR((int)(*p)[__X(i, ((LONGINT)(4)))], 4));
		d[__X(__ASHL(i, 1) + 1, d__len)] = Reals_ToHex(__MASK((int)(*p)[__X(i, ((LONGINT)(4)))], -16));
	}
}

typedef
	CHAR (*pc8__5)[8];

void Reals_ConvertHL (LONGREAL y, CHAR *d, LONGINT d__len)
{
	pc8__5 p = NIL;
	INTEGER i;
	p = (pc8__5)(uintptr_t)((LONGINT)(uintptr_t)&y);
	i = 0;
	while (i < 8) {
		d[__X(__ASHL(i, 1), d__len)] = Reals_ToHex(__ASHR((int)(*p)[__X(i, ((LONGINT)(8)))], 4));
		d[__X(__ASHL(i, 1) + 1, d__len)] = Reals_ToHex(__MASK((int)(*p)[__X(i, ((LONGINT)(8)))], -16));
	}
}


export void *Reals__init(void)
{
	__DEFMOD;
	__REGMOD("Reals", 0);
/* BEGIN */
	__ENDMOD;
}
