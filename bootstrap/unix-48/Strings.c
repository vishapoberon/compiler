/* voc 5.4.2 [2026/11/24] for gcc LP64 on gentoo xnrtspaSF */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32

#include "SYSTEM.h"
#include "Reals.h"




export void Strings_Append (CHAR *extra, ADDRESS extra__len, CHAR *dest, ADDRESS dest__len);
export void Strings_Cap (CHAR *s, ADDRESS s__len);
export void Strings_Delete (CHAR *s, ADDRESS s__len, INT16 pos, INT16 n);
export void Strings_Extract (CHAR *source, ADDRESS source__len, INT16 pos, INT16 n, CHAR *dest, ADDRESS dest__len);
export void Strings_Insert (CHAR *source, ADDRESS source__len, INT16 pos, CHAR *dest, ADDRESS dest__len);
export INT16 Strings_Length (CHAR *s, ADDRESS s__len);
export BOOLEAN Strings_Match (CHAR *string, ADDRESS string__len, CHAR *pattern, ADDRESS pattern__len);
export INT16 Strings_Pos (CHAR *pattern, ADDRESS pattern__len, CHAR *s, ADDRESS s__len, INT16 pos);
export void Strings_Replace (CHAR *source, ADDRESS source__len, INT16 pos, CHAR *dest, ADDRESS dest__len);
export void Strings_StrToLongReal (CHAR *s, ADDRESS s__len, LONGREAL *r);
export void Strings_StrToReal (CHAR *s, ADDRESS s__len, REAL *r);


INT16 Strings_Length (CHAR *s, ADDRESS s__len)
{
	INT32 i;
	__DUP(s, s__len, CHAR);
	i = 0;
	while ((i < s__len && s[__X_AT(i, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 37, 35, 1894)] != 0x00)) {
		i += 1;
	}
	if (i <= 32767) {
		__DEL(s);
		return __SHORT(i, 32768);
	} else {
		__DEL(s);
		return 32767;
	}
	__RETCHK;
}

void Strings_Append (CHAR *extra, ADDRESS extra__len, CHAR *dest, ADDRESS dest__len)
{
	INT16 n1, n2, i;
	__DUP(extra, extra__len, CHAR);
	n1 = Strings_Length(dest, dest__len);
	n2 = Strings_Length(extra, extra__len);
	i = 0;
	while ((i < n2 && (i + n1) < dest__len)) {
		dest[__X_AT(i + n1, dest__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 46, 49, 2203)] = extra[__X_AT(i, extra__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 46, 66, 2220)];
		i += 1;
	}
	if ((i + n1) < dest__len) {
		dest[__X_AT(i + n1, dest__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 47, 35, 2271)] = 0x00;
	}
	__DEL(extra);
}

void Strings_Insert (CHAR *source, ADDRESS source__len, INT16 pos, CHAR *dest, ADDRESS dest__len)
{
	INT16 n1, n2, i;
	__DUP(source, source__len, CHAR);
	n1 = Strings_Length(dest, dest__len);
	n2 = Strings_Length(source, source__len);
	if (pos < 0) {
		pos = 0;
	}
	if (pos > n1) {
		Strings_Append(dest, dest__len, (void*)source, source__len);
		__DEL(source);
		return;
	}
	if ((pos + n2) < dest__len) {
		i = n1;
		while (i >= pos) {
			if ((i + n2) < dest__len) {
				dest[__X_AT(i + n2, dest__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 60, 39, 2710)] = dest[__X_AT(i, dest__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 60, 55, 2726)];
			}
			i -= 1;
		}
	}
	i = 0;
	while (i < n2) {
		dest[__X_AT(pos + i, dest__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 64, 32, 2795)] = source[__X_AT(i, source__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 64, 51, 2814)];
		i += 1;
	}
	__DEL(source);
}

void Strings_Delete (CHAR *s, ADDRESS s__len, INT16 pos, INT16 n)
{
	INT16 len, i;
	len = Strings_Length(s, s__len);
	if (pos < 0) {
		pos = 0;
	} else if (pos >= len) {
		return;
	}
	if (pos + n < len) {
		i = pos + n;
		while (i < len) {
			s[__X_AT(i - n, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 74, 36, 3068)] = s[__X_AT(i, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 74, 46, 3078)];
			i += 1;
		}
		if ((i - n) < s__len) {
			s[__X_AT(i - n, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 75, 30, 3124)] = 0x00;
		}
	} else {
		s[__X_AT(pos, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 76, 10, 3148)] = 0x00;
	}
}

void Strings_Replace (CHAR *source, ADDRESS source__len, INT16 pos, CHAR *dest, ADDRESS dest__len)
{
	__DUP(source, source__len, CHAR);
	Strings_Delete((void*)dest, dest__len, pos, pos + Strings_Length(source, source__len));
	Strings_Insert(source, source__len, pos, (void*)dest, dest__len);
	__DEL(source);
}

void Strings_Extract (CHAR *source, ADDRESS source__len, INT16 pos, INT16 n, CHAR *dest, ADDRESS dest__len)
{
	INT16 len, destLen, i;
	__DUP(source, source__len, CHAR);
	len = Strings_Length(source, source__len);
	destLen = __SHORT(dest__len, 32768) - 1;
	if (pos < 0) {
		pos = 0;
	}
	if (pos >= len) {
		dest[0] = 0x00;
		__DEL(source);
		return;
	}
	i = 0;
	while (((((pos + i) <= source__len && source[__X_AT(pos + i, source__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 95, 44, 3669)] != 0x00)) && i < n)) {
		if (i < destLen) {
			dest[__X_AT(i, dest__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 96, 30, 3726)] = source[__X_AT(pos + i, source__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 96, 43, 3739)];
		}
		i += 1;
	}
	dest[__X_AT(i, dest__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 99, 8, 3780)] = 0x00;
	__DEL(source);
}

INT16 Strings_Pos (CHAR *pattern, ADDRESS pattern__len, CHAR *s, ADDRESS s__len, INT16 pos)
{
	INT16 n1, n2, i, j;
	__DUP(pattern, pattern__len, CHAR);
	__DUP(s, s__len, CHAR);
	n1 = Strings_Length(s, s__len);
	n2 = Strings_Length(pattern, pattern__len);
	if (n2 == 0) {
		__DEL(pattern);
		__DEL(s);
		return 0;
	}
	i = pos;
	while (i <= n1 - n2) {
		if (s[__X_AT(i, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 110, 10, 4025)] == pattern[0]) {
			j = 1;
			while ((j < n2 && s[__X_AT(i + j, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 111, 35, 4080)] == pattern[__X_AT(j, pattern__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 111, 52, 4097)])) {
				j += 1;
			}
			if (j == n2) {
				__DEL(pattern);
				__DEL(s);
				return i;
			}
		}
		i += 1;
	}
	__DEL(pattern);
	__DEL(s);
	return -1;
}

void Strings_Cap (CHAR *s, ADDRESS s__len)
{
	INT16 i;
	i = 0;
	while (s[__X_AT(i, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 124, 11, 4286)] != 0x00) {
		if (('a' <= s[__X_AT(i, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 125, 18, 4314)] && s[__X_AT(i, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 125, 27, 4323)] <= 'z')) {
			s[__X_AT(i, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 125, 45, 4341)] = __CAP(s[__X_AT(i, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 125, 57, 4353)]);
		}
		i += 1;
	}
}

static struct Match__7 {
	struct Match__7 *lnk;
} *Match__7_s;

static BOOLEAN M__8 (CHAR *name, ADDRESS name__len, CHAR *mask, ADDRESS mask__len, INT16 n, INT16 m);

static BOOLEAN M__8 (CHAR *name, ADDRESS name__len, CHAR *mask, ADDRESS mask__len, INT16 n, INT16 m)
{
	while ((((n >= 0 && m >= 0)) && mask[__X_AT(m, mask__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 135, 39, 4569)] != '*')) {
		if (name[__X_AT(n, name__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 136, 15, 4596)] != mask[__X_AT(m, mask__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 136, 25, 4606)]) {
			return 0;
		}
		n -= 1;
		m -= 1;
	}
	if (m < 0) {
		return n < 0;
	}
	while ((m >= 0 && mask[__X_AT(m, mask__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 142, 28, 4837)] == '*')) {
		m -= 1;
	}
	if (m < 0) {
		return 1;
	}
	while (n >= 0) {
		if (M__8(name, name__len, mask, mask__len, n, m)) {
			return 1;
		}
		n -= 1;
	}
	return 0;
}

BOOLEAN Strings_Match (CHAR *string, ADDRESS string__len, CHAR *pattern, ADDRESS pattern__len)
{
	struct Match__7 _s;
	BOOLEAN __retval;
	__DUP(string, string__len, CHAR);
	__DUP(pattern, pattern__len, CHAR);
	_s.lnk = Match__7_s;
	Match__7_s = &_s;
	__retval = M__8((void*)string, string__len, (void*)pattern, pattern__len, Strings_Length(string, string__len) - 1, Strings_Length(pattern, pattern__len) - 1);
	Match__7_s = _s.lnk;
	__DEL(string);
	__DEL(pattern);
	;
	return __retval;
}

void Strings_StrToReal (CHAR *s, ADDRESS s__len, REAL *r)
{
	INT16 p, e;
	REAL y, g;
	BOOLEAN neg, negE;
	__DUP(s, s__len, CHAR);
	p = 0;
	while (s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 160, 11, 5287)] == ' ' || s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 160, 27, 5303)] == '0') {
		p += 1;
	}
	if (s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 161, 7, 5334)] == '-') {
		neg = 1;
		p += 1;
	} else {
		neg = 0;
	}
	while (s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 162, 11, 5401)] == ' ' || s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 162, 27, 5417)] == '0') {
		p += 1;
	}
	y = (REAL)0.0e0;
	while (('0' <= s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 165, 18, 5469)] && s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 165, 27, 5478)] <= '9')) {
		y = y * (REAL)1.0e1 + ((INT16)s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 166, 24, 5515)] - 48);
		p += 1;
	}
	if (s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 169, 7, 5549)] == '.') {
		p += 1;
		g = (REAL)1.0e0;
		while (('0' <= s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 171, 19, 5599)] && s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 171, 28, 5608)] <= '9')) {
			g = g / (REAL)(REAL)1.0e1;
			y = y + g * ((INT16)s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 172, 37, 5658)] - 48);
			p += 1;
		}
	}
	if (s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 176, 8, 5701)] == 'D' || s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 176, 24, 5717)] == 'E') {
		p += 1;
		e = 0;
		if (s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 178, 8, 5757)] == '-') {
			negE = 1;
			p += 1;
		} else {
			negE = 0;
		}
		while (s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 179, 12, 5827)] == '0') {
			p += 1;
		}
		while (('0' <= s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 180, 19, 5870)] && s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 180, 28, 5879)] <= '9')) {
			e = e * 10 + ((INT16)s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 181, 25, 5917)] - 48);
			p += 1;
		}
		if (negE) {
			y = y / (REAL)Reals_Ten(e);
		} else {
			y = y * Reals_Ten(e);
		}
	}
	if (neg) {
		y = -y;
	}
	*r = y;
	__DEL(s);
}

void Strings_StrToLongReal (CHAR *s, ADDRESS s__len, LONGREAL *r)
{
	INT16 p, e;
	LONGREAL y, g;
	BOOLEAN neg, negE;
	__DUP(s, s__len, CHAR);
	p = 0;
	while (s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 195, 11, 6216)] == ' ' || s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 195, 27, 6232)] == '0') {
		p += 1;
	}
	if (s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 196, 7, 6263)] == '-') {
		neg = 1;
		p += 1;
	} else {
		neg = 0;
	}
	while (s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 197, 11, 6330)] == ' ' || s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 197, 27, 6346)] == '0') {
		p += 1;
	}
	y = (LONGREAL)0.0e0;
	while (('0' <= s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 200, 18, 6398)] && s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 200, 27, 6407)] <= '9')) {
		y = y * (LONGREAL)1.0e1 + ((INT16)s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 201, 24, 6444)] - 48);
		p += 1;
	}
	if (s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 204, 7, 6478)] == '.') {
		p += 1;
		g = (LONGREAL)1.0e0;
		while (('0' <= s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 206, 19, 6528)] && s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 206, 28, 6537)] <= '9')) {
			g = g / (LONGREAL)(LONGREAL)1.0e1;
			y = y + g * ((INT16)s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 207, 37, 6587)] - 48);
			p += 1;
		}
	}
	if (s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 211, 8, 6630)] == 'D' || s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 211, 24, 6646)] == 'E') {
		p += 1;
		e = 0;
		if (s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 213, 8, 6686)] == '-') {
			negE = 1;
			p += 1;
		} else {
			negE = 0;
		}
		while (s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 214, 12, 6756)] == '0') {
			p += 1;
		}
		while (('0' <= s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 215, 19, 6799)] && s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 215, 28, 6808)] <= '9')) {
			e = e * 10 + ((INT16)s[__X_AT(p, s__len, (CHAR*)"../../src/library/Strings.Mod", 30, (CHAR*)"Strings", 8, 216, 25, 6846)] - 48);
			p += 1;
		}
		if (negE) {
			y = y / (LONGREAL)Reals_Ten(e);
		} else {
			y = y * Reals_Ten(e);
		}
	}
	if (neg) {
		y = -y;
	}
	*r = y;
	__DEL(s);
}


export void *Strings__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(Reals);
	__REGMOD("Strings", 0);
/* BEGIN */
	__ENDMOD;
}
