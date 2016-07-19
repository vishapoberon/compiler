/* voc  1.95 [2016/07/19] for gcc LP64 on cygwin xtspkaSfF */
#include "SYSTEM.h"
#include "Console.h"
#include "Strings.h"


export CHAR vt100_CSI[5];
static CHAR vt100_tmpstr[32];


export void vt100_CHA (INTEGER n);
export void vt100_CNL (INTEGER n);
export void vt100_CPL (INTEGER n);
export void vt100_CUB (INTEGER n);
export void vt100_CUD (INTEGER n);
export void vt100_CUF (INTEGER n);
export void vt100_CUP (INTEGER n, INTEGER m);
export void vt100_CUU (INTEGER n);
export void vt100_DECTCEMh (void);
export void vt100_DECTCEMl (void);
export void vt100_DSR (INTEGER n);
export void vt100_ED (INTEGER n);
export void vt100_EL (INTEGER n);
static void vt100_EscSeq (INTEGER n, CHAR *letter, LONGINT letter__len);
static void vt100_EscSeq0 (CHAR *letter, LONGINT letter__len);
static void vt100_EscSeq2 (INTEGER n, INTEGER m, CHAR *letter, LONGINT letter__len);
static void vt100_EscSeqSwapped (INTEGER n, CHAR *letter, LONGINT letter__len);
export void vt100_HVP (INTEGER n, INTEGER m);
export void vt100_IntToStr (LONGINT int_, CHAR *str, LONGINT str__len);
export void vt100_RCP (void);
static void vt100_Reverse0 (CHAR *str, LONGINT str__len, INTEGER start, INTEGER end);
export void vt100_SCP (void);
export void vt100_SD (INTEGER n);
export void vt100_SGR (INTEGER n);
export void vt100_SGR2 (INTEGER n, INTEGER m);
export void vt100_SU (INTEGER n);
export void vt100_SetAttr (CHAR *attr, LONGINT attr__len);


static void vt100_Reverse0 (CHAR *str, LONGINT str__len, INTEGER start, INTEGER end)
{
	CHAR h;
	while (start < end) {
		h = str[__X(start, str__len)];
		str[__X(start, str__len)] = str[__X(end, str__len)];
		str[__X(end, str__len)] = h;
		start += 1;
		end -= 1;
	}
}

void vt100_IntToStr (LONGINT int_, CHAR *str, LONGINT str__len)
{
	CHAR b[21];
	INTEGER s, e;
	SHORTINT maxLength;
	maxLength = 11;
	if (int_ == (-2147483647-1)) {
		__MOVE("-2147483648", b, 12);
		e = 11;
	} else {
		if (int_ < 0) {
			b[0] = '-';
			int_ = -int_;
			s = 1;
		} else {
			s = 0;
		}
		e = s;
		do {
			b[__X(e, ((LONGINT)(21)))] = (CHAR)(__MOD(int_, 10) + 48);
			int_ = __DIV(int_, 10);
			e += 1;
		} while (!(int_ == 0));
		b[__X(e, ((LONGINT)(21)))] = 0x00;
		vt100_Reverse0((void*)b, ((LONGINT)(21)), s, e - 1);
	}
	__COPY(b, str, str__len);
}

static void vt100_EscSeq0 (CHAR *letter, LONGINT letter__len)
{
	CHAR cmd[9];
	__DUP(letter, letter__len, CHAR);
	__COPY(vt100_CSI, cmd, ((LONGINT)(9)));
	Strings_Append(letter, letter__len, (void*)cmd, ((LONGINT)(9)));
	Console_String(cmd, ((LONGINT)(9)));
	__DEL(letter);
}

static void vt100_EscSeq (INTEGER n, CHAR *letter, LONGINT letter__len)
{
	CHAR nstr[2];
	CHAR cmd[7];
	__DUP(letter, letter__len, CHAR);
	vt100_IntToStr(n, (void*)nstr, ((LONGINT)(2)));
	__COPY(vt100_CSI, cmd, ((LONGINT)(7)));
	Strings_Append(nstr, ((LONGINT)(2)), (void*)cmd, ((LONGINT)(7)));
	Strings_Append(letter, letter__len, (void*)cmd, ((LONGINT)(7)));
	Console_String(cmd, ((LONGINT)(7)));
	__DEL(letter);
}

static void vt100_EscSeqSwapped (INTEGER n, CHAR *letter, LONGINT letter__len)
{
	CHAR nstr[2];
	CHAR cmd[7];
	__DUP(letter, letter__len, CHAR);
	vt100_IntToStr(n, (void*)nstr, ((LONGINT)(2)));
	__COPY(vt100_CSI, cmd, ((LONGINT)(7)));
	Strings_Append(letter, letter__len, (void*)cmd, ((LONGINT)(7)));
	Strings_Append(nstr, ((LONGINT)(2)), (void*)cmd, ((LONGINT)(7)));
	Console_String(cmd, ((LONGINT)(7)));
	__DEL(letter);
}

static void vt100_EscSeq2 (INTEGER n, INTEGER m, CHAR *letter, LONGINT letter__len)
{
	CHAR nstr[5], mstr[5];
	CHAR cmd[12];
	__DUP(letter, letter__len, CHAR);
	vt100_IntToStr(n, (void*)nstr, ((LONGINT)(5)));
	vt100_IntToStr(m, (void*)mstr, ((LONGINT)(5)));
	__COPY(vt100_CSI, cmd, ((LONGINT)(12)));
	Strings_Append(nstr, ((LONGINT)(5)), (void*)cmd, ((LONGINT)(12)));
	Strings_Append((CHAR*)";", (LONGINT)2, (void*)cmd, ((LONGINT)(12)));
	Strings_Append(mstr, ((LONGINT)(5)), (void*)cmd, ((LONGINT)(12)));
	Strings_Append(letter, letter__len, (void*)cmd, ((LONGINT)(12)));
	Console_String(cmd, ((LONGINT)(12)));
	__DEL(letter);
}

void vt100_CUU (INTEGER n)
{
	vt100_EscSeq(n, (CHAR*)"A", (LONGINT)2);
}

void vt100_CUD (INTEGER n)
{
	vt100_EscSeq(n, (CHAR*)"B", (LONGINT)2);
}

void vt100_CUF (INTEGER n)
{
	vt100_EscSeq(n, (CHAR*)"C", (LONGINT)2);
}

void vt100_CUB (INTEGER n)
{
	vt100_EscSeq(n, (CHAR*)"D", (LONGINT)2);
}

void vt100_CNL (INTEGER n)
{
	vt100_EscSeq(n, (CHAR*)"E", (LONGINT)2);
}

void vt100_CPL (INTEGER n)
{
	vt100_EscSeq(n, (CHAR*)"F", (LONGINT)2);
}

void vt100_CHA (INTEGER n)
{
	vt100_EscSeq(n, (CHAR*)"G", (LONGINT)2);
}

void vt100_CUP (INTEGER n, INTEGER m)
{
	vt100_EscSeq2(n, m, (CHAR*)"H", (LONGINT)2);
}

void vt100_ED (INTEGER n)
{
	vt100_EscSeq(n, (CHAR*)"J", (LONGINT)2);
}

void vt100_EL (INTEGER n)
{
	vt100_EscSeq(n, (CHAR*)"K", (LONGINT)2);
}

void vt100_SU (INTEGER n)
{
	vt100_EscSeq(n, (CHAR*)"S", (LONGINT)2);
}

void vt100_SD (INTEGER n)
{
	vt100_EscSeq(n, (CHAR*)"T", (LONGINT)2);
}

void vt100_HVP (INTEGER n, INTEGER m)
{
	vt100_EscSeq2(n, m, (CHAR*)"f", (LONGINT)2);
}

void vt100_SGR (INTEGER n)
{
	vt100_EscSeq(n, (CHAR*)"m", (LONGINT)2);
}

void vt100_SGR2 (INTEGER n, INTEGER m)
{
	vt100_EscSeq2(n, m, (CHAR*)"m", (LONGINT)2);
}

void vt100_DSR (INTEGER n)
{
	vt100_EscSeq(6, (CHAR*)"n", (LONGINT)2);
}

void vt100_SCP (void)
{
	vt100_EscSeq0((CHAR*)"s", (LONGINT)2);
}

void vt100_RCP (void)
{
	vt100_EscSeq0((CHAR*)"u", (LONGINT)2);
}

void vt100_DECTCEMl (void)
{
	vt100_EscSeq0((CHAR*)"\?25l", (LONGINT)5);
}

void vt100_DECTCEMh (void)
{
	vt100_EscSeq0((CHAR*)"\?25h", (LONGINT)5);
}

void vt100_SetAttr (CHAR *attr, LONGINT attr__len)
{
	CHAR tmpstr[16];
	__DUP(attr, attr__len, CHAR);
	__COPY(vt100_CSI, tmpstr, ((LONGINT)(16)));
	Strings_Append(attr, attr__len, (void*)tmpstr, ((LONGINT)(16)));
	Console_String(tmpstr, ((LONGINT)(16)));
	__DEL(attr);
}


export void *vt100__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(Console);
	__MODULE_IMPORT(Strings);
	__REGMOD("vt100", 0);
	__REGCMD("DECTCEMh", vt100_DECTCEMh);
	__REGCMD("DECTCEMl", vt100_DECTCEMl);
	__REGCMD("RCP", vt100_RCP);
	__REGCMD("SCP", vt100_SCP);
/* BEGIN */
	__COPY("", vt100_CSI, ((LONGINT)(5)));
	Strings_Append((CHAR*)"[", (LONGINT)2, (void*)vt100_CSI, ((LONGINT)(5)));
	__ENDMOD;
}
