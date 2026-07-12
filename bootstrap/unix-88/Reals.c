/* voc 2.1.0 [2026/07/12]. Bootstrapping compiler for address size 8, alignment 8. xrtspaSF */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32

#include "SYSTEM.h"
#include "Platform.h"


static INT16 Reals_realExpHi, Reals_realExpLo, Reals_lrealExpHi, Reals_lrealExpLo;


static void Reals_BytesToHex (SYSTEM_BYTE *b, ADDRESS b__len, SYSTEM_BYTE *d, ADDRESS d__len);
export void Reals_Convert (REAL x, INT16 n, CHAR *d, ADDRESS d__len);
export void Reals_ConvertH (REAL y, CHAR *d, ADDRESS d__len);
export void Reals_ConvertHL (LONGREAL x, CHAR *d, ADDRESS d__len);
export void Reals_ConvertL (LONGREAL x, INT16 n, CHAR *d, ADDRESS d__len);
export INT16 Reals_Expo (REAL x);
export INT16 Reals_ExpoL (LONGREAL x);
static void Reals_InitEndian (void);
export void Reals_SetExpo (REAL *x, INT16 ex);
export void Reals_SetExpoL (LONGREAL *x, INT16 ex);
export REAL Reals_Ten (INT16 e);
export LONGREAL Reals_TenL (INT16 e);
static CHAR Reals_ToHex (INT16 i);


REAL Reals_Ten (INT16 e)
{
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
	return r;
}

LONGREAL Reals_TenL (INT16 e)
{
	LONGREAL r, power;
	r = (LONGREAL)1;
	power = (LONGREAL)10;
	for (;;) {
		if (__ODD(e)) {
			r = r * power;
		}
		e = __ASHR(e, 1);
		if (e <= 0) {
			return r;
		}
		power = power * power;
	}
	__RETCHK;
}

INT16 Reals_Expo (REAL x)
{
	CHAR hi, lo;
	__GET((ADDRESS)&x + (INT64)Reals_realExpHi, hi, CHAR);
	__GET((ADDRESS)&x + (INT64)Reals_realExpLo, lo, CHAR);
	return __MASK(__ASHL((INT16)hi, 1) + __ASHR((INT16)lo, 7), -256);
}

void Reals_SetExpo (REAL *x, INT16 ex)
{
	CHAR c;
	__GET((ADDRESS)x + (INT64)Reals_realExpHi, c, CHAR);
	__PUT((ADDRESS)x + (INT64)Reals_realExpHi, __CHR(__ASHL(__ASHR((INT16)c, 7), 7) + __MASK(__ASHR(ex, 1), -128)), CHAR);
	__GET((ADDRESS)x + (INT64)Reals_realExpLo, c, CHAR);
	__PUT((ADDRESS)x + (INT64)Reals_realExpLo, __CHR(__MASK((INT16)c, -128) + __ASHL(__MASK(ex, -2), 7)), CHAR);
}

INT16 Reals_ExpoL (LONGREAL x)
{
	CHAR hi, lo;
	__GET((ADDRESS)&x + (INT64)Reals_lrealExpHi, hi, CHAR);
	__GET((ADDRESS)&x + (INT64)Reals_lrealExpLo, lo, CHAR);
	return __MASK(__ASHL((INT16)hi, 4) + __ASHR((INT16)lo, 4), -2048);
}

void Reals_SetExpoL (LONGREAL *x, INT16 ex)
{
	CHAR c;
	__GET((ADDRESS)x + (INT64)Reals_lrealExpHi, c, CHAR);
	__PUT((ADDRESS)x + (INT64)Reals_lrealExpHi, __CHR(__ASHL(__ASHR((INT16)c, 7), 7) + __MASK(__ASHR(ex, 4), -128)), CHAR);
	__GET((ADDRESS)x + (INT64)Reals_lrealExpLo, c, CHAR);
	__PUT((ADDRESS)x + (INT64)Reals_lrealExpLo, __CHR(__ASHL(__MASK(ex, -16), 4) + __MASK((INT16)c, -16)), CHAR);
}

void Reals_ConvertL (LONGREAL x, INT16 n, CHAR *d, ADDRESS d__len)
{
	INT32 i, j, k;
	if (x < (LONGREAL)0) {
		x = -x;
	}
	k = 0;
	if (n > 9) {
		i = __SHORT(__ENTIER(x / (LONGREAL)(LONGREAL)1000000000), 2147483648LL);
		j = __SHORT(__ENTIER(x - i * (LONGREAL)1000000000), 2147483648LL);
		if (j < 0) {
			j = 0;
		}
		while (k < 9) {
			d[__X(k, d__len)] = __CHR((int)__MOD(j, 10) + 48);
			j = __DIV(j, 10);
			k += 1;
		}
	} else {
		i = __SHORT(__ENTIER(x), 2147483648LL);
	}
	while (k < n) {
		d[__X(k, d__len)] = __CHR((int)__MOD(i, 10) + 48);
		i = __DIV(i, 10);
		k += 1;
	}
}

void Reals_Convert (REAL x, INT16 n, CHAR *d, ADDRESS d__len)
{
	Reals_ConvertL(x, n, (void*)d, d__len);
}

static CHAR Reals_ToHex (INT16 i)
{
	if (i < 10) {
		return __CHR(i + 48);
	} else {
		return __CHR(i + 55);
	}
	__RETCHK;
}

static void Reals_BytesToHex (SYSTEM_BYTE *b, ADDRESS b__len, SYSTEM_BYTE *d, ADDRESS d__len)
{
	INT16 i, j, len;
	CHAR by;
	len = __SHORT(b__len, 32768);
	if (Platform_LittleEndian) {
		i = 0;
	} else {
		i = len - 1;
	}
	j = 0;
	while ((i >= 0 && i < len)) {
		by = __VAL(CHAR, b[__X(i, b__len)]);
		d[__X(__ASHL(j, 1), d__len)] = Reals_ToHex(__ASHR((INT16)by, 4));
		d[__X(__ASHL(j, 1) + 1, d__len)] = Reals_ToHex(__MASK((INT16)by, -16));
		j += 1;
		if (Platform_LittleEndian) {
			i += 1;
		} else {
			i -= 1;
		}
	}
}

void Reals_ConvertH (REAL y, CHAR *d, ADDRESS d__len)
{
	Reals_BytesToHex((void*)&y, 4, (void*)d, d__len * 1);
}

void Reals_ConvertHL (LONGREAL x, CHAR *d, ADDRESS d__len)
{
	Reals_BytesToHex((void*)&x, 8, (void*)d, d__len * 1);
}

static void Reals_InitEndian (void)
{
	if (Platform_LittleEndian) {
		Reals_realExpHi = 3;
		Reals_realExpLo = 2;
		Reals_lrealExpHi = 7;
		Reals_lrealExpLo = 6;
	} else {
		Reals_realExpHi = 0;
		Reals_realExpLo = 1;
		Reals_lrealExpHi = 0;
		Reals_lrealExpLo = 1;
	}
}


export void *Reals__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(Platform);
	__REGMOD("Reals", 0);
/* BEGIN */
	Reals_InitEndian();
	__ENDMOD;
}
