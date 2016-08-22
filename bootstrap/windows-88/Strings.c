/* voc 1.95 [2016/08/22] for gcc LP64 on cygwin xtspkaSfF */
#define LARGE
#include "SYSTEM.h"




export void Strings_Append (CHAR *extra, LONGINT extra__len, CHAR *dest, LONGINT dest__len);
export void Strings_Cap (CHAR *s, LONGINT s__len);
export void Strings_Delete (CHAR *s, LONGINT s__len, INTEGER pos, INTEGER n);
export void Strings_Extract (CHAR *source, LONGINT source__len, INTEGER pos, INTEGER n, CHAR *dest, LONGINT dest__len);
export void Strings_Insert (CHAR *source, LONGINT source__len, INTEGER pos, CHAR *dest, LONGINT dest__len);
export INTEGER Strings_Length (CHAR *s, LONGINT s__len);
export BOOLEAN Strings_Match (CHAR *string, LONGINT string__len, CHAR *pattern, LONGINT pattern__len);
export INTEGER Strings_Pos (CHAR *pattern, LONGINT pattern__len, CHAR *s, LONGINT s__len, INTEGER pos);
export void Strings_Replace (CHAR *source, LONGINT source__len, INTEGER pos, CHAR *dest, LONGINT dest__len);


INTEGER Strings_Length (CHAR *s, LONGINT s__len)
{
	INTEGER _o_result;
	INTEGER i;
	__DUP(s, s__len, CHAR);
	i = 0;
	while (((SYSTEM_INT64)i < s__len && s[__X(i, s__len)] != 0x00)) {
		i += 1;
	}
	_o_result = i;
	__DEL(s);
	return _o_result;
}

void Strings_Append (CHAR *extra, LONGINT extra__len, CHAR *dest, LONGINT dest__len)
{
	INTEGER n1, n2, i;
	__DUP(extra, extra__len, CHAR);
	n1 = Strings_Length(dest, dest__len);
	n2 = Strings_Length(extra, extra__len);
	i = 0;
	while ((i < n2 && (SYSTEM_INT64)(i + n1) < dest__len)) {
		dest[__X(i + n1, dest__len)] = extra[__X(i, extra__len)];
		i += 1;
	}
	if ((SYSTEM_INT64)(i + n1) < dest__len) {
		dest[__X(i + n1, dest__len)] = 0x00;
	}
	__DEL(extra);
}

void Strings_Insert (CHAR *source, LONGINT source__len, INTEGER pos, CHAR *dest, LONGINT dest__len)
{
	INTEGER n1, n2, i;
	__DUP(source, source__len, CHAR);
	n1 = Strings_Length(dest, dest__len);
	n2 = Strings_Length(source, source__len);
	if (pos < 0) {
		pos = 0;
	}
	if (pos > n1) {
		Strings_Append(dest, dest__len, (void*)source, source__len);
		return;
	}
	if ((SYSTEM_INT64)(pos + n2) < dest__len) {
		i = n1;
		while (i >= pos) {
			if ((SYSTEM_INT64)(i + n2) < dest__len) {
				dest[__X(i + n2, dest__len)] = dest[__X(i, dest__len)];
			}
			i -= 1;
		}
	}
	i = 0;
	while (i < n2) {
		dest[__X(pos + i, dest__len)] = source[__X(i, source__len)];
		i += 1;
	}
	__DEL(source);
}

void Strings_Delete (CHAR *s, LONGINT s__len, INTEGER pos, INTEGER n)
{
	INTEGER len, i;
	len = Strings_Length(s, s__len);
	if (pos < 0) {
		pos = 0;
	} else if (pos >= len) {
		return;
	}
	if (pos + n < len) {
		i = pos + n;
		while (i < len) {
			s[__X(i - n, s__len)] = s[__X(i, s__len)];
			i += 1;
		}
		if ((SYSTEM_INT64)(i - n) < s__len) {
			s[__X(i - n, s__len)] = 0x00;
		}
	} else {
		s[__X(pos, s__len)] = 0x00;
	}
}

void Strings_Replace (CHAR *source, LONGINT source__len, INTEGER pos, CHAR *dest, LONGINT dest__len)
{
	__DUP(source, source__len, CHAR);
	Strings_Delete((void*)dest, dest__len, pos, pos + Strings_Length(source, source__len));
	Strings_Insert(source, source__len, pos, (void*)dest, dest__len);
	__DEL(source);
}

void Strings_Extract (CHAR *source, LONGINT source__len, INTEGER pos, INTEGER n, CHAR *dest, LONGINT dest__len)
{
	INTEGER len, destLen, i;
	__DUP(source, source__len, CHAR);
	len = Strings_Length(source, source__len);
	destLen = (int)dest__len - 1;
	if (pos < 0) {
		pos = 0;
	}
	if (pos >= len) {
		dest[0] = 0x00;
		return;
	}
	i = 0;
	while (((((SYSTEM_INT64)(pos + i) <= source__len && source[__X(pos + i, source__len)] != 0x00)) && i < n)) {
		if (i < destLen) {
			dest[__X(i, dest__len)] = source[__X(pos + i, source__len)];
		}
		i += 1;
	}
	dest[__X(i, dest__len)] = 0x00;
	__DEL(source);
}

INTEGER Strings_Pos (CHAR *pattern, LONGINT pattern__len, CHAR *s, LONGINT s__len, INTEGER pos)
{
	INTEGER _o_result;
	INTEGER n1, n2, i, j;
	__DUP(pattern, pattern__len, CHAR);
	__DUP(s, s__len, CHAR);
	n1 = Strings_Length(s, s__len);
	n2 = Strings_Length(pattern, pattern__len);
	if (n2 == 0) {
		_o_result = 0;
		__DEL(pattern);
		__DEL(s);
		return _o_result;
	}
	i = pos;
	while (i <= n1 - n2) {
		if (s[__X(i, s__len)] == pattern[0]) {
			j = 1;
			while ((j < n2 && s[__X(i + j, s__len)] == pattern[__X(j, pattern__len)])) {
				j += 1;
			}
			if (j == n2) {
				_o_result = i;
				__DEL(pattern);
				__DEL(s);
				return _o_result;
			}
		}
		i += 1;
	}
	_o_result = -1;
	__DEL(pattern);
	__DEL(s);
	return _o_result;
}

void Strings_Cap (CHAR *s, LONGINT s__len)
{
	INTEGER i;
	i = 0;
	while (s[__X(i, s__len)] != 0x00) {
		if (('a' <= s[__X(i, s__len)] && s[__X(i, s__len)] <= 'z')) {
			s[__X(i, s__len)] = __CAP(s[__X(i, s__len)]);
		}
		i += 1;
	}
}

static struct Match__7 {
	struct Match__7 *lnk;
} *Match__7_s;

static BOOLEAN M__8 (CHAR *name, LONGINT name__len, CHAR *mask, LONGINT mask__len, INTEGER n, INTEGER m);

static BOOLEAN M__8 (CHAR *name, LONGINT name__len, CHAR *mask, LONGINT mask__len, INTEGER n, INTEGER m)
{
	BOOLEAN _o_result;
	while ((((n >= 0 && m >= 0)) && mask[__X(m, mask__len)] != '*')) {
		if (name[__X(n, name__len)] != mask[__X(m, mask__len)]) {
			_o_result = 0;
			return _o_result;
		}
		n -= 1;
		m -= 1;
	}
	if (m < 0) {
		_o_result = n < 0;
		return _o_result;
	}
	while ((m >= 0 && mask[__X(m, mask__len)] == '*')) {
		m -= 1;
	}
	if (m < 0) {
		_o_result = 1;
		return _o_result;
	}
	while (n >= 0) {
		if (M__8(name, name__len, mask, mask__len, n, m)) {
			_o_result = 1;
			return _o_result;
		}
		n -= 1;
	}
	_o_result = 0;
	return _o_result;
}

BOOLEAN Strings_Match (CHAR *string, LONGINT string__len, CHAR *pattern, LONGINT pattern__len)
{
	BOOLEAN _o_result;
	struct Match__7 _s;
	__DUP(string, string__len, CHAR);
	__DUP(pattern, pattern__len, CHAR);
	_s.lnk = Match__7_s;
	Match__7_s = &_s;
	_o_result = M__8((void*)string, string__len, (void*)pattern, pattern__len, Strings_Length(string, string__len) - 1, Strings_Length(pattern, pattern__len) - 1);
	Match__7_s = _s.lnk;
	__DEL(string);
	__DEL(pattern);
	return _o_result;
}


export void *Strings__init(void)
{
	__DEFMOD;
	__REGMOD("Strings", 0);
/* BEGIN */
	__ENDMOD;
}
