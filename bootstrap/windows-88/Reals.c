/* voc 5.4.1 [2026/11/24] for gcc LP64 on gentoo xnrtspaSF */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32

#include "SYSTEM.h"
#include "Platform.h"

typedef
	struct Reals_Big {
		INT16 len;
		INT32 digit[512];
	} Reals_Big;


static INT16 Reals_realExpHi, Reals_realExpLo, Reals_lrealExpHi, Reals_lrealExpLo;

export ADDRESS *Reals_Big__typ;

static void Reals_AddDigit (Reals_Big *a, ADDRESS *a__typ, INT32 value);
static INT16 Reals_BitLength (Reals_Big *a, ADDRESS *a__typ);
static void Reals_BytesToHex (SYSTEM_BYTE *b, ADDRESS b__len, SYSTEM_BYTE *d, ADDRESS d__len);
static INT16 Reals_Compare (Reals_Big *a, ADDRESS *a__typ, Reals_Big *b, ADDRESS *b__typ);
export void Reals_Convert (REAL x, INT16 n, CHAR *d, ADDRESS d__len);
export void Reals_ConvertH (REAL y, CHAR *d, ADDRESS d__len);
export void Reals_ConvertHL (LONGREAL x, CHAR *d, ADDRESS d__len);
export void Reals_ConvertL (LONGREAL x, INT16 n, CHAR *d, ADDRESS d__len);
static CHAR Reals_DivideTen (Reals_Big *a, ADDRESS *a__typ);
export INT16 Reals_Expo (REAL x);
export INT16 Reals_ExpoL (LONGREAL x);
export void Reals_FormatLongReal (LONGREAL value, CHAR *text, ADDRESS text__len);
static void Reals_FromInt (INT64 value, Reals_Big *a, ADDRESS *a__typ);
static void Reals_Half (Reals_Big *a, ADDRESS *a__typ);
static void Reals_InitEndian (void);
static void Reals_Multiply (Reals_Big *a, ADDRESS *a__typ, INT32 factor);
static INT64 Reals_ParseBits (CHAR *text, ADDRESS text__len, BOOLEAN single);
export LONGREAL Reals_ParseLongReal (CHAR *text, ADDRESS text__len);
export REAL Reals_ParseReal (CHAR *text, ADDRESS text__len);
export void Reals_SetExpo (REAL *x, INT16 ex);
export void Reals_SetExpoL (LONGREAL *x, INT16 ex);
static void Reals_Shift (Reals_Big *a, ADDRESS *a__typ, INT16 bits, Reals_Big *b, ADDRESS *b__typ);
static INT64 Reals_SignedBits (INT64 bits, BOOLEAN negative, BOOLEAN single);
static void Reals_Subtract (Reals_Big *a, ADDRESS *a__typ, Reals_Big *b, ADDRESS *b__typ);
export REAL Reals_Ten (INT16 e);
export LONGREAL Reals_TenL (INT16 e);
static CHAR Reals_ToHex (INT16 i);
static void Reals_Trim (Reals_Big *a, ADDRESS *a__typ);


static void Reals_FromInt (INT64 value, Reals_Big *a, ADDRESS *a__typ)
{
	(*a).len = 0;
	while (value > 0) {
		(*a).digit[__X_AT((*a).len, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 36, 15, 1356)] = __SHORT(__MASK(value, (-32767-1)), 2147483648LL);
		(*a).len += 1;
		value = __ASHR(value, 15);
	}
}

static void Reals_Trim (Reals_Big *a, ADDRESS *a__typ)
{
	while (((*a).len > 0 && (*a).digit[__X_AT((*a).len - 1, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 42, 38, 1530)] == 0)) {
		(*a).len -= 1;
	}
}

static void Reals_Multiply (Reals_Big *a, ADDRESS *a__typ, INT32 factor)
{
	INT16 i;
	INT32 value, carry;
	INT16 _for__19;
	carry = 0;
	_for__19 = (*a).len - 1;
	i = 0;
	while (i <= _for__19) {
		value = (*a).digit[__X_AT(i, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 49, 24, 1753)] * factor + carry;
		(*a).digit[__X_AT(i, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 50, 15, 1786)] = __MASK(value, (-32767-1));
		carry = __ASHR(value, 15);
		i += 1;
	}
	if (carry > 0) {
		__ASSERT((*a).len < 512, 0);
		(*a).digit[__X_AT((*a).len, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 53, 42, 1912)] = carry;
		(*a).len += 1;
	}
}

static void Reals_AddDigit (Reals_Big *a, ADDRESS *a__typ, INT32 value)
{
	INT16 i;
	i = 0;
	while (value > 0) {
		if (i == (*a).len) {
			__ASSERT(i < 512, 0);
			(*a).digit[__X_AT(i, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 62, 56, 2138)] = 0;
			(*a).len += 1;
		}
		value += (*a).digit[__X_AT(i, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 63, 26, 2188)];
		(*a).digit[__X_AT(i, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 63, 39, 2201)] = __MASK(value, (-32767-1));
		value = __ASHR(value, 15);
		i += 1;
	}
}

static void Reals_Shift (Reals_Big *a, ADDRESS *a__typ, INT16 bits, Reals_Big *b, ADDRESS *b__typ)
{
	INT16 i, words;
	INT32 factor, value, carry;
	INT16 _for__27, _for__26;
	if ((*a).len == 0) {
		(*b).len = 0;
		return;
	}
	words = __DIV(bits, 15);
	factor = 1;
	factor = __LSH(factor, (int)__MOD(bits, 15), 32);
	__ASSERT(((*a).len + words) + 1 <= 512, 0);
	_for__27 = words - 1;
	i = 0;
	while (i <= _for__27) {
		(*b).digit[__X_AT(i, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 74, 38, 2644)] = 0;
		i += 1;
	}
	carry = 0;
	_for__26 = (*a).len - 1;
	i = 0;
	while (i <= _for__26) {
		value = (*a).digit[__X_AT(i, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 77, 24, 2725)] * factor + carry;
		(*b).digit[__X_AT(i + words, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 78, 15, 2758)] = __MASK(value, (-32767-1));
		carry = __ASHR(value, 15);
		i += 1;
	}
	(*b).len = (*a).len + words;
	if (carry > 0) {
		(*b).digit[__X_AT((*b).len, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 81, 31, 2885)] = carry;
		(*b).len += 1;
	}
}

static void Reals_Half (Reals_Big *a, ADDRESS *a__typ)
{
	INT16 i;
	INT32 value, carry;
	carry = 0;
	i = (*a).len - 1;
	while (i >= 0) {
		value = __ASHL(carry, 15) + (*a).digit[__X_AT(i, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 89, 41, 3108)];
		(*a).digit[__X_AT(i, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 90, 15, 3126)] = __ASHR(value, 1);
		carry = __MASK(value, -2);
		i += -1;
	}
	Reals_Trim(&*a, a__typ);
}

static INT16 Reals_Compare (Reals_Big *a, ADDRESS *a__typ, Reals_Big *b, ADDRESS *b__typ)
{
	INT16 i;
	if ((*a).len < (*b).len) {
		return -1;
	} else if ((*a).len > (*b).len) {
		return 1;
	}
	i = (*a).len;
	while (i > 0) {
		i -= 1;
		if ((*a).digit[__X_AT(i, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 102, 18, 3414)] < (*b).digit[__X_AT(i, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 102, 31, 3427)]) {
			return -1;
		} else if ((*a).digit[__X_AT(i, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 103, 21, 3465)] > (*b).digit[__X_AT(i, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 103, 34, 3478)]) {
			return 1;
		}
	}
	return 0;
}

static void Reals_Subtract (Reals_Big *a, ADDRESS *a__typ, Reals_Big *b, ADDRESS *b__typ)
{
	INT16 i;
	INT32 value, borrow;
	INT16 _for__30;
	borrow = 0;
	_for__30 = (*a).len - 1;
	i = 0;
	while (i <= _for__30) {
		value = (*a).digit[__X_AT(i, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 113, 24, 3700)] - borrow;
		if (i < (*b).len) {
			value -= (*b).digit[__X_AT(i, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 114, 44, 3756)];
		}
		if (value < 0) {
			value += 32768;
			borrow = 1;
		} else {
			borrow = 0;
		}
		(*a).digit[__X_AT(i, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 116, 15, 3859)] = value;
		i += 1;
	}
	__ASSERT(borrow == 0, 0);
	Reals_Trim(&*a, a__typ);
}

static INT16 Reals_BitLength (Reals_Big *a, ADDRESS *a__typ)
{
	INT16 n;
	INT32 value;
	if ((*a).len == 0) {
		return 0;
	}
	n = ((*a).len - 1) * 15;
	value = (*a).digit[__X_AT((*a).len - 1, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 125, 47, 4104)];
	while (value > 0) {
		n += 1;
		value = __ASHR(value, 1);
	}
	return n;
}

static INT64 Reals_SignedBits (INT64 bits, BOOLEAN negative, BOOLEAN single)
{
	if (negative) {
		if (single) {
			bits -= 2147483648LL;
		} else {
			bits += (-9223372036854775807LL-1);
		}
	}
	return bits;
}

static INT64 Reals_ParseBits (CHAR *text, ADDRESS text__len, BOOLEAN single)
{
	Reals_Big numerator, denominator, temporary;
	INT64 position;
	INT16 count, precision, minimum, maximum, exponent, shift, j, comparison;
	INT32 digit;
	INT64 scale, explicit, magnitude, unit, quotient, bits;
	BOOLEAN negative, point, sticky, negExp;
	CHAR ch;
	__DUP(text, text__len, CHAR);
	position = 0;
	count = 0;
	scale = 0;
	point = 0;
	sticky = 0;
	negative = 0;
	numerator.len = 0;
	if (text__len == 0) {
		__DEL(text);
		return 0;
	}
	if (text[0] == '-') {
		negative = 1;
		position += 1;
	} else if (text[0] == '+') {
		position += 1;
	}
	for (;;) {
		if (position >= (INT64)text__len) {
			break;
		}
		ch = text[__X_AT(position, text__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 152, 18, 5173)];
		if ((ch >= '0' && ch <= '9')) {
			digit = (INT16)ch - 48;
			if (count > 0 || digit != 0) {
				if (count < 1100) {
					Reals_Multiply(&numerator, Reals_Big__typ, 10);
					Reals_AddDigit(&numerator, Reals_Big__typ, digit);
					count += 1;
					if (point) {
						scale -= 1;
					}
				} else {
					sticky = sticky || digit != 0;
					if (!point) {
						scale += 1;
					}
				}
			} else if (point) {
				scale -= 1;
			}
		} else if ((ch == '.' && !point)) {
			point = 1;
		} else {
			break;
		}
		position += 1;
	}
	explicit = 0;
	negExp = 0;
	if ((position < (INT64)text__len && ((text[__X_AT(position, text__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 171, 40, 5806)] == 'E' || text[__X_AT(position, text__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 171, 66, 5832)] == 'e') || text[__X_AT(position, text__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 171, 92, 5858)] == 'D'))) {
		position += 1;
		if ((position < (INT64)text__len && text[__X_AT(position, text__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 173, 41, 5942)] == '-')) {
			negExp = 1;
			position += 1;
		} else if ((position < (INT64)text__len && text[__X_AT(position, text__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 174, 44, 6037)] == '+')) {
			position += 1;
		}
		for (;;) {
			if (position >= (INT64)text__len) {
				break;
			}
			ch = text[__X_AT(position, text__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 177, 20, 6156)];
			if (ch < '0' || ch > '9') {
				break;
			}
			digit = (INT16)ch - 48;
			if (explicit <= __DIV(9223372036854775807LL - (INT64)digit, 10)) {
				explicit = explicit * 10 + (INT64)digit;
			} else {
				explicit = 9223372036854775807LL;
			}
			position += 1;
		}
	}
	if (negExp) {
		explicit = -explicit;
	}
	if ((explicit > 0 && scale > 9223372036854775807LL - explicit)) {
		scale = 9223372036854775807LL;
	} else if ((explicit < 0 && scale < (-9223372036854775807LL-1) - explicit)) {
		scale = (-9223372036854775807LL-1);
	} else {
		scale += explicit;
	}
	if (single) {
		precision = 24;
		minimum = -126;
		maximum = 127;
	} else {
		precision = 53;
		minimum = -1022;
		maximum = 1023;
	}
	unit = __LSH(1, precision - 1, 64);
	if (numerator.len == 0) {
		__DEL(text);
		return Reals_SignedBits(0, negative, single);
	}
	if (scale > 400) {
		__DEL(text);
		return Reals_SignedBits((INT64)(__ASHL(maximum, 1) + 1) * unit, negative, single);
	} else if (scale < -1501) {
		__DEL(text);
		return Reals_SignedBits(0, negative, single);
	}
	if (sticky) {
		Reals_Multiply(&numerator, Reals_Big__typ, 10);
		Reals_AddDigit(&numerator, Reals_Big__typ, 1);
		count += 1;
		scale -= 1;
	}
	magnitude = (scale + (INT64)count) - 1;
	if (magnitude > 400) {
		__DEL(text);
		return Reals_SignedBits((INT64)(__ASHL(maximum, 1) + 1) * unit, negative, single);
	} else if (magnitude < -400) {
		__DEL(text);
		return Reals_SignedBits(0, negative, single);
	}
	Reals_FromInt(1, &denominator, Reals_Big__typ);
	if (scale >= 0) {
		while (scale > 0) {
			Reals_Multiply(&numerator, Reals_Big__typ, 10);
			scale -= 1;
		}
	} else {
		while (scale < 0) {
			Reals_Multiply(&denominator, Reals_Big__typ, 10);
			scale += 1;
		}
	}
	exponent = Reals_BitLength(&numerator, Reals_Big__typ) - Reals_BitLength(&denominator, Reals_Big__typ);
	if (exponent >= 0) {
		Reals_Shift(&denominator, Reals_Big__typ, exponent, &temporary, Reals_Big__typ);
		if (Reals_Compare(&numerator, Reals_Big__typ, &temporary, Reals_Big__typ) < 0) {
			exponent -= 1;
		}
	} else {
		Reals_Shift(&numerator, Reals_Big__typ, -exponent, &temporary, Reals_Big__typ);
		if (Reals_Compare(&temporary, Reals_Big__typ, &denominator, Reals_Big__typ) < 0) {
			exponent -= 1;
		}
	}
	if (exponent > maximum) {
		__DEL(text);
		return Reals_SignedBits((INT64)(__ASHL(maximum, 1) + 1) * unit, negative, single);
	}
	if (exponent >= minimum) {
		shift = (precision - 1) - exponent;
	} else {
		shift = (precision - 1) - minimum;
	}
	if (shift >= 0) {
		Reals_Shift(&numerator, Reals_Big__typ, shift, &temporary, Reals_Big__typ);
		numerator = temporary;
	} else {
		Reals_Shift(&denominator, Reals_Big__typ, -shift, &temporary, Reals_Big__typ);
		denominator = temporary;
	}
	quotient = 0;
	j = Reals_BitLength(&numerator, Reals_Big__typ) - Reals_BitLength(&denominator, Reals_Big__typ);
	if (j >= 0) {
		__ASSERT(j <= precision, 0);
		Reals_Shift(&denominator, Reals_Big__typ, j, &temporary, Reals_Big__typ);
		while (j >= 0) {
			quotient = __ASHL(quotient, 1);
			if (Reals_Compare(&numerator, Reals_Big__typ, &temporary, Reals_Big__typ) >= 0) {
				Reals_Subtract(&numerator, Reals_Big__typ, &temporary, Reals_Big__typ);
				quotient += 1;
			}
			Reals_Half(&temporary, Reals_Big__typ);
			j -= 1;
		}
	}
	Reals_Shift(&numerator, Reals_Big__typ, 1, &temporary, Reals_Big__typ);
	comparison = Reals_Compare(&temporary, Reals_Big__typ, &denominator, Reals_Big__typ);
	if (comparison > 0 || (comparison == 0 && __ODD(quotient))) {
		quotient += 1;
	}
	if (exponent < minimum) {
		bits = quotient;
	} else {
		if (quotient == __ASHL(unit, 1)) {
			quotient = __ASHR(quotient, 1);
			exponent += 1;
		}
		if (exponent > maximum) {
			bits = (INT64)(__ASHL(maximum, 1) + 1) * unit;
		} else {
			bits = ((INT64)(exponent + maximum) * unit + quotient) - unit;
		}
	}
	__DEL(text);
	return Reals_SignedBits(bits, negative, single);
}

REAL Reals_ParseReal (CHAR *text, ADDRESS text__len)
{
	INT32 bits;
	__DUP(text, text__len, CHAR);
	bits = __SHORTF(Reals_ParseBits(text, text__len, 1), 2147483648LL);
	__DEL(text);
	return __VAL(REAL, bits);
}

LONGREAL Reals_ParseLongReal (CHAR *text, ADDRESS text__len)
{
	INT64 bits;
	__DUP(text, text__len, CHAR);
	bits = Reals_ParseBits(text, text__len, 0);
	__DEL(text);
	return __VAL(LONGREAL, bits);
}

static CHAR Reals_DivideTen (Reals_Big *a, ADDRESS *a__typ)
{
	INT16 i;
	INT32 value, remainder;
	remainder = 0;
	i = (*a).len - 1;
	while (i >= 0) {
		value = __ASHL(remainder, 15) + (*a).digit[__X_AT(i, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 252, 45, 9884)];
		(*a).digit[__X_AT(i, 512, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 253, 15, 9902)] = __DIV(value, 10);
		remainder = (int)__MOD(value, 10);
		i += -1;
	}
	Reals_Trim(&*a, a__typ);
	return __CHR(remainder + 48);
}

void Reals_FormatLongReal (LONGREAL value, CHAR *text, ADDRESS text__len)
{
	Reals_Big a, temporary;
	CHAR reverse[1100];
	CHAR digits[17];
	CHAR exp[8];
	INT64 bits, mantissa;
	INT16 binary, scale, exponent, count, kept, i, j, position, n;
	BOOLEAN negative, round;
	INT16 _for__14, _for__13;
	__ASSERT(text__len >= 32, 0);
	bits = __VAL(INT64, value);
	negative = bits < 0;
	binary = __SHORT(__SHORT(__MASK(__LSHR(bits, 52, 64), -2048), 2147483648LL), 32768);
	__ASSERT(binary != 2047, 0);
	mantissa = __MASK(bits, -4503599627370496LL);
	if (binary != 0) {
		mantissa += 4503599627370496LL;
		binary = (binary - 1023) - 52;
	} else {
		binary = -1074;
	}
	Reals_FromInt(mantissa, &a, Reals_Big__typ);
	scale = 0;
	if (binary >= 0) {
		Reals_Shift(&a, Reals_Big__typ, binary, &temporary, Reals_Big__typ);
		a = temporary;
	} else {
		scale = -binary;
		while (binary < 0) {
			Reals_Multiply(&a, Reals_Big__typ, 5);
			binary += 1;
		}
	}
	count = 0;
	while (a.len > 0) {
		reverse[__X_AT(count, 1100, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 280, 32, 11149)] = Reals_DivideTen(&a, Reals_Big__typ);
		count += 1;
	}
	if (count == 0) {
		reverse[0] = '0';
		count = 1;
		scale = 0;
	}
	exponent = (count - scale) - 1;
	if (count > 17) {
		kept = 17;
	} else {
		kept = count;
	}
	_for__14 = kept - 1;
	i = 0;
	while (i <= _for__14) {
		digits[__X_AT(i, 17, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 284, 36, 11382)] = reverse[__X_AT((count - 1) - i, 1100, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 284, 50, 11396)];
		i += 1;
	}
	if (count > kept) {
		i = (count - kept) - 1;
		round = reverse[__X_AT(i, 1100, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 286, 43, 11479)] > '5';
		if (reverse[__X_AT(i, 1100, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 287, 18, 11506)] == '5') {
			round = __ODD((INT16)digits[__X_AT(kept - 1, 17, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 288, 33, 11552)] - 48);
			while (i > 0) {
				i -= 1;
				round = round || reverse[__X_AT(i, 1100, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 289, 59, 11630)] != '0';
			}
		}
		if (round) {
			i = kept - 1;
			while ((i > 0 && digits[__X_AT(i, 17, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 293, 33, 11728)] == '9')) {
				digits[__X_AT(i, 17, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 293, 53, 11748)] = '0';
				i -= 1;
			}
			if (digits[__X_AT(i, 17, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 294, 19, 11789)] == '9') {
				digits[__X_AT(i, 17, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 294, 40, 11810)] = '1';
				exponent += 1;
			} else {
				digits[__X_AT(i, 17, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 295, 21, 11855)] = __CHR((INT16)digits[__X_AT(i, 17, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 295, 42, 11876)] + 1);
			}
		}
	}
	while ((kept > 1 && digits[__X_AT(kept - 1, 17, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 298, 32, 11937)] == '0')) {
		kept -= 1;
	}
	position = 0;
	if (negative) {
		text[__X_AT(position, text__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 300, 27, 12015)] = '-';
		position += 1;
	}
	text[__X_AT(position, text__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 301, 10, 12061)] = digits[0];
	position += 1;
	text[__X_AT(position, text__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 301, 54, 12105)] = '.';
	position += 1;
	if (kept == 1) {
		text[__X_AT(position, text__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 302, 27, 12164)] = '0';
		position += 1;
	} else {
		_for__13 = kept - 1;
		i = 1;
		while (i <= _for__13) {
			text[__X_AT(position, text__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 303, 39, 12234)] = digits[__X_AT(i, 17, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 303, 59, 12254)];
			position += 1;
			i += 1;
		}
	}
	text[__X_AT(position, text__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 304, 10, 12290)] = 'e';
	position += 1;
	if (exponent < 0) {
		text[__X_AT(position, text__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 305, 31, 12353)] = '-';
		position += 1;
		exponent = -exponent;
	}
	n = 0;
	do {
		exp[__X_AT(n, 8, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 307, 16, 12440)] = __CHR((int)__MOD(exponent, 10) + 48);
		n += 1;
		exponent = __DIV(exponent, 10);
	} while (!(exponent == 0));
	j = n - 1;
	while (j >= 0) {
		text[__X_AT(position, text__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 308, 37, 12571)] = exp[__X_AT(j, 8, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 308, 54, 12588)];
		position += 1;
		j += -1;
	}
	text[__X_AT(position, text__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 309, 10, 12620)] = 0x00;
}

REAL Reals_Ten (INT16 e)
{
	LONGREAL r, power;
	r = (LONGREAL)1.0e0;
	power = (LONGREAL)1.0e1;
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
	r = (LONGREAL)1.0e0;
	power = (LONGREAL)1.0e1;
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
	if (x < (LONGREAL)0.0e0) {
		x = -x;
	}
	k = 0;
	if (n > 9) {
		i = __SHORT(__ENTIER(x / (LONGREAL)(LONGREAL)1.0e9), 2147483648LL);
		j = __SHORT(__ENTIER(x - i * (LONGREAL)1.0e9), 2147483648LL);
		if (j < 0) {
			j = 0;
		}
		while (k < 9) {
			d[__X_AT(k, d__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 401, 11, 15616)] = __CHR((int)__MOD(j, 10) + 48);
			j = __DIV(j, 10);
			k += 1;
		}
	} else {
		i = __SHORT(__ENTIER(x), 2147483648LL);
	}
	while (k < n) {
		d[__X_AT(k, d__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 410, 9, 15851)] = __CHR((int)__MOD(i, 10) + 48);
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
		by = __VAL(CHAR, b[__X_AT(i, b__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 432, 32, 16436)]);
		d[__X_AT(__ASHL(j, 1), d__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 433, 9, 16449)] = Reals_ToHex(__ASHR((INT16)by, 4));
		d[__X_AT(__ASHL(j, 1) + 1, d__len, (CHAR*)"../../src/library/Reals.Mod", 28, (CHAR*)"Reals", 6, 434, 9, 16490)] = Reals_ToHex(__MASK((INT16)by, -16));
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

__TDESC(Reals_Big, 1, 0) = {__TDFLDS("Big", 2052), {-8}};

export void *Reals__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(Platform);
	__REGMOD("Reals", 0);
	__INITYP(Reals_Big, Reals_Big, 0);
/* BEGIN */
	Reals_InitEndian();
	__ENDMOD;
}
