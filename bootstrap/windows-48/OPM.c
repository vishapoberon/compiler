/* voc 1.95 [2016/08/21] for gcc LP64 on cygwin xtspkaSfF */
#include "SYSTEM.h"
#include "Configuration.h"
#include "Console.h"
#include "Files.h"
#include "Platform.h"
#include "Strings.h"
#include "Texts.h"
#include "errors.h"
#include "vt100.h"

typedef
	CHAR OPM_FileName[32];


static CHAR OPM_SourceFileName[256];
export INTEGER OPM_Alignment, OPM_ByteSize, OPM_CharSize, OPM_BoolSize, OPM_SIntSize, OPM_IntSize, OPM_LIntSize, OPM_SetSize, OPM_RealSize, OPM_LRealSize, OPM_PointerSize, OPM_ProcSize, OPM_RecSize, OPM_MaxSet;
export LONGINT OPM_MaxIndex;
export LONGREAL OPM_MinReal, OPM_MaxReal, OPM_MinLReal, OPM_MaxLReal;
export BOOLEAN OPM_noerr;
export LONGINT OPM_curpos, OPM_errpos, OPM_breakpc;
export INTEGER OPM_currFile, OPM_level, OPM_pc, OPM_entno;
export CHAR OPM_modName[32];
export CHAR OPM_objname[64];
export SET OPM_opt, OPM_glbopt;
static LONGINT OPM_ErrorLineStartPos, OPM_ErrorLineLimitPos, OPM_ErrorLineNumber, OPM_lasterrpos;
static Texts_Reader OPM_inR;
static Texts_Text OPM_Log;
static Texts_Writer OPM_W;
static Files_Rider OPM_oldSF, OPM_newSF;
static Files_Rider OPM_R[3];
static Files_File OPM_oldSFile, OPM_newSFile, OPM_HFile, OPM_BFile, OPM_HIFile;
static INTEGER OPM_S;
export BOOLEAN OPM_dontAsm, OPM_dontLink, OPM_mainProg, OPM_mainLinkStat, OPM_notColorOutput, OPM_forceNewSym, OPM_Verbose;
static CHAR OPM_OBERON[1024];
static CHAR OPM_MODULES[1024];


static void OPM_Append (Files_Rider *R, LONGINT *R__typ, Files_File F);
export void OPM_CloseFiles (void);
export void OPM_CloseOldSym (void);
export void OPM_DeleteNewSym (void);
export void OPM_FPrint (LONGINT *fp, LONGINT val);
export void OPM_FPrintLReal (LONGINT *fp, LONGREAL lr);
export void OPM_FPrintReal (LONGINT *fp, REAL real);
export void OPM_FPrintSet (LONGINT *fp, SET set);
static void OPM_FindLine (Files_File f, Files_Rider *r, LONGINT *r__typ, LONGINT pos);
export void OPM_Get (CHAR *ch);
static void OPM_GetProperties (void);
static void OPM_GetProperty (Texts_Scanner *S, LONGINT *S__typ, CHAR *name, LONGINT name__len, INTEGER *size, INTEGER *align);
export void OPM_Init (BOOLEAN *done, CHAR *mname, LONGINT mname__len);
export void OPM_InitOptions (void);
static void OPM_LogErrMsg (INTEGER n);
export void OPM_LogW (CHAR ch);
export void OPM_LogWLn (void);
export void OPM_LogWNum (LONGINT i, LONGINT len);
export void OPM_LogWStr (CHAR *s, LONGINT s__len);
static void OPM_MakeFileName (CHAR *name, LONGINT name__len, CHAR *FName, LONGINT FName__len, CHAR *ext, LONGINT ext__len);
export void OPM_Mark (INTEGER n, LONGINT pos);
export void OPM_NewSym (CHAR *modName, LONGINT modName__len);
export void OPM_OldSym (CHAR *modName, LONGINT modName__len, BOOLEAN *done);
export void OPM_OpenFiles (CHAR *moduleName, LONGINT moduleName__len);
export BOOLEAN OPM_OpenPar (void);
export void OPM_RegisterNewSym (void);
static void OPM_ScanOptions (CHAR *s, LONGINT s__len, SET *opt);
static void OPM_ShowLine (LONGINT pos);
export LONGINT OPM_SignedMaximum (LONGINT bytecount);
export LONGINT OPM_SignedMinimum (LONGINT bytecount);
export void OPM_SymRCh (CHAR *ch);
export LONGINT OPM_SymRInt (void);
export void OPM_SymRLReal (LONGREAL *lr);
export void OPM_SymRReal (REAL *r);
export void OPM_SymRSet (SET *s);
export void OPM_SymWCh (CHAR ch);
export void OPM_SymWInt (LONGINT i);
export void OPM_SymWLReal (LONGREAL lr);
export void OPM_SymWReal (REAL r);
export void OPM_SymWSet (SET s);
static void OPM_VerboseListSizes (void);
export void OPM_Write (CHAR ch);
export void OPM_WriteHex (LONGINT i);
export void OPM_WriteInt (LONGINT i);
export void OPM_WriteLn (void);
export void OPM_WriteReal (LONGREAL r, CHAR suffx);
export void OPM_WriteString (CHAR *s, LONGINT s__len);
export void OPM_WriteStringVar (CHAR *s, LONGINT s__len);
export BOOLEAN OPM_eofSF (void);
export void OPM_err (INTEGER n);
static LONGINT OPM_minusop (LONGINT i);
static LONGINT OPM_power0 (LONGINT i, LONGINT j);


void OPM_LogW (CHAR ch)
{
	Console_Char(ch);
}

void OPM_LogWStr (CHAR *s, LONGINT s__len)
{
	__DUP(s, s__len, CHAR);
	Console_String(s, s__len);
	__DEL(s);
}

void OPM_LogWNum (LONGINT i, LONGINT len)
{
	Console_Int(i, len);
}

void OPM_LogWLn (void)
{
	Console_Ln();
}

static void OPM_ScanOptions (CHAR *s, LONGINT s__len, SET *opt)
{
	INTEGER i;
	i = 1;
	while (s[__X(i, s__len)] != 0x00) {
		switch (s[__X(i, s__len)]) {
			case 'a': 
				*opt = *opt ^ 0x80;
				break;
			case 'c': 
				*opt = *opt ^ 0x4000;
				break;
			case 'e': 
				*opt = *opt ^ 0x0200;
				break;
			case 'f': 
				*opt = *opt ^ 0x010000;
				break;
			case 'k': 
				*opt = *opt ^ 0x40;
				break;
			case 'm': 
				*opt = *opt ^ 0x0400;
				break;
			case 'p': 
				*opt = *opt ^ 0x20;
				break;
			case 'r': 
				*opt = *opt ^ 0x04;
				break;
			case 's': 
				*opt = *opt ^ 0x10;
				break;
			case 't': 
				*opt = *opt ^ 0x08;
				break;
			case 'x': 
				*opt = *opt ^ 0x01;
				break;
			case 'B': 
				if (s[__X(i + 1, s__len)] != 0x00) {
					i += 1;
					OPM_IntSize = (int)s[__X(i, s__len)] - 48;
				}
				if (s[__X(i + 1, s__len)] != 0x00) {
					i += 1;
					OPM_PointerSize = (int)s[__X(i, s__len)] - 48;
				}
				if (s[__X(i + 1, s__len)] != 0x00) {
					i += 1;
					OPM_Alignment = (int)s[__X(i, s__len)] - 48;
				}
				__ASSERT(OPM_IntSize == 2 || OPM_IntSize == 4, 0);
				__ASSERT(OPM_PointerSize == 4 || OPM_PointerSize == 8, 0);
				__ASSERT(OPM_Alignment == 4 || OPM_Alignment == 8, 0);
				Files_SetSearchPath((CHAR*)"", (LONGINT)1);
				break;
			case 'F': 
				*opt = *opt ^ 0x020000;
				break;
			case 'M': 
				*opt = *opt ^ 0x8000;
				break;
			case 'S': 
				*opt = *opt ^ 0x2000;
				break;
			case 'V': 
				*opt = *opt ^ 0x040000;
				break;
			default: 
				OPM_LogWStr((CHAR*)"  warning: option ", (LONGINT)19);
				OPM_LogW('-');
				OPM_LogW(s[__X(i, s__len)]);
				OPM_LogWStr((CHAR*)" ignored", (LONGINT)9);
				OPM_LogWLn();
				break;
		}
		i += 1;
	}
}

BOOLEAN OPM_OpenPar (void)
{
	BOOLEAN _o_result;
	CHAR s[256];
	if (Platform_ArgCount == 1) {
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"Vishap Oberon-2 compiler v", (LONGINT)27);
		OPM_LogWStr(Configuration_versionLong, ((LONGINT)(41)));
		OPM_LogW('.');
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"Based on Ofront by Software Templ OEG, continued by Norayr Chilingarian and others.", (LONGINT)84);
		OPM_LogWLn();
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"Usage:", (LONGINT)7);
		OPM_LogWLn();
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"  ", (LONGINT)3);
		OPM_LogWStr((CHAR*)"voc", (LONGINT)4);
		OPM_LogWStr((CHAR*)" options {files {options}}.", (LONGINT)28);
		OPM_LogWLn();
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"Where options = [\"-\" {option} ].", (LONGINT)33);
		OPM_LogWLn();
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"  m - generate code for main module", (LONGINT)36);
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"  M - generate code for main module and link object statically", (LONGINT)63);
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"  s - generate new symbol file", (LONGINT)31);
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"  e - allow extending the module interface", (LONGINT)43);
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"  r - check value ranges", (LONGINT)25);
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"  x - turn off array indices check", (LONGINT)35);
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"  a - don't check ASSERTs at runtime, use this option in tested production code", (LONGINT)80);
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"  p - turn off automatic pointer initialization", (LONGINT)48);
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"  t - don't check type guards (use in rare cases such as low-level modules where every cycle counts)", (LONGINT)101);
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"  S - don't call external assembler/compiler, only generate C code", (LONGINT)67);
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"  c - don't call linker", (LONGINT)24);
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"  f - don't use color output", (LONGINT)29);
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"  F - force writing new symbol file in current directory", (LONGINT)57);
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"  V - verbose output", (LONGINT)21);
		OPM_LogWLn();
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"Initial options specify defaults for all files.", (LONGINT)48);
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"Options following a filename are specific to that file.", (LONGINT)56);
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"Repeating an option toggles its value.", (LONGINT)39);
		OPM_LogWLn();
		_o_result = 0;
		return _o_result;
	} else {
		OPM_S = 1;
		s[0] = 0x00;
		Platform_GetArg(OPM_S, (void*)s, ((LONGINT)(256)));
		OPM_glbopt = 0xe9;
		while (s[0] == '-') {
			OPM_ScanOptions((void*)s, ((LONGINT)(256)), &OPM_glbopt);
			OPM_S += 1;
			s[0] = 0x00;
			Platform_GetArg(OPM_S, (void*)s, ((LONGINT)(256)));
		}
		_o_result = 1;
		return _o_result;
	}
	__RETCHK;
}

void OPM_InitOptions (void)
{
	CHAR s[256];
	OPM_opt = OPM_glbopt;
	s[0] = 0x00;
	Platform_GetArg(OPM_S, (void*)s, ((LONGINT)(256)));
	while (s[0] == '-') {
		OPM_ScanOptions((void*)s, ((LONGINT)(256)), &OPM_opt);
		OPM_S += 1;
		s[0] = 0x00;
		Platform_GetArg(OPM_S, (void*)s, ((LONGINT)(256)));
	}
	OPM_dontAsm = __IN(13, OPM_opt);
	OPM_dontLink = __IN(14, OPM_opt);
	OPM_mainProg = __IN(10, OPM_opt);
	OPM_mainLinkStat = __IN(15, OPM_opt);
	OPM_notColorOutput = __IN(16, OPM_opt);
	OPM_forceNewSym = __IN(17, OPM_opt);
	OPM_Verbose = __IN(18, OPM_opt);
	if (OPM_mainLinkStat) {
		OPM_glbopt |= __SETOF(10);
	}
	OPM_GetProperties();
}

void OPM_Init (BOOLEAN *done, CHAR *mname, LONGINT mname__len)
{
	Texts_Text T = NIL;
	LONGINT beg, end, time;
	CHAR s[256];
	*done = 0;
	OPM_curpos = 0;
	if (OPM_S >= Platform_ArgCount) {
		return;
	}
	s[0] = 0x00;
	Platform_GetArg(OPM_S, (void*)s, ((LONGINT)(256)));
	__NEW(T, Texts_TextDesc);
	Texts_Open(T, s, ((LONGINT)(256)));
	OPM_LogWStr(s, ((LONGINT)(256)));
	OPM_LogWStr((CHAR*)"  ", (LONGINT)3);
	__COPY(s, mname, mname__len);
	__COPY(s, OPM_SourceFileName, ((LONGINT)(256)));
	if (T->len == 0) {
		OPM_LogWStr(s, ((LONGINT)(256)));
		OPM_LogWStr((CHAR*)" not found.", (LONGINT)12);
		OPM_LogWLn();
	} else {
		Texts_OpenReader(&OPM_inR, Texts_Reader__typ, T, ((LONGINT)(0)));
		*done = 1;
	}
	OPM_S += 1;
	OPM_level = 0;
	OPM_noerr = 1;
	OPM_errpos = OPM_curpos;
	OPM_lasterrpos = OPM_curpos - 10;
	OPM_ErrorLineStartPos = 0;
	OPM_ErrorLineLimitPos = 0;
	OPM_ErrorLineNumber = 0;
}

void OPM_Get (CHAR *ch)
{
	Texts_Read(&OPM_inR, Texts_Reader__typ, &*ch);
	if (*ch == 0x0d) {
		OPM_curpos = Texts_Pos(&OPM_inR, Texts_Reader__typ);
	} else {
		OPM_curpos += 1;
	}
	if ((*ch < 0x09 && !OPM_inR.eot)) {
		*ch = ' ';
	}
}

static void OPM_MakeFileName (CHAR *name, LONGINT name__len, CHAR *FName, LONGINT FName__len, CHAR *ext, LONGINT ext__len)
{
	INTEGER i, j;
	CHAR ch;
	__DUP(ext, ext__len, CHAR);
	i = 0;
	for (;;) {
		ch = name[__X(i, name__len)];
		if (ch == 0x00) {
			break;
		}
		FName[__X(i, FName__len)] = ch;
		i += 1;
	}
	j = 0;
	do {
		ch = ext[__X(j, ext__len)];
		FName[__X(i, FName__len)] = ch;
		i += 1;
		j += 1;
	} while (!(ch == 0x00));
	__DEL(ext);
}

static void OPM_LogErrMsg (INTEGER n)
{
	Texts_Scanner S;
	Texts_Text T = NIL;
	CHAR ch;
	INTEGER i;
	CHAR buf[1024];
	if (n >= 0) {
		if (!OPM_notColorOutput) {
			vt100_SetAttr((CHAR*)"31m", (LONGINT)4);
		}
		OPM_LogWStr((CHAR*)"  err ", (LONGINT)7);
		if (!OPM_notColorOutput) {
			vt100_SetAttr((CHAR*)"0m", (LONGINT)3);
		}
	} else {
		if (!OPM_notColorOutput) {
			vt100_SetAttr((CHAR*)"35m", (LONGINT)4);
		}
		OPM_LogWStr((CHAR*)"  warning ", (LONGINT)11);
		n = -n;
		if (!OPM_notColorOutput) {
			vt100_SetAttr((CHAR*)"0m", (LONGINT)3);
		}
	}
	OPM_LogWNum(n, ((LONGINT)(1)));
	OPM_LogWStr((CHAR*)"  ", (LONGINT)3);
	OPM_LogWStr(errors_errors[__X(n, ((LONGINT)(350)))], ((LONGINT)(128)));
}

static void OPM_FindLine (Files_File f, Files_Rider *r, LONGINT *r__typ, LONGINT pos)
{
	CHAR ch, cheol;
	if (pos < OPM_ErrorLineStartPos) {
		OPM_ErrorLineStartPos = 0;
		OPM_ErrorLineLimitPos = 0;
		OPM_ErrorLineNumber = 0;
	}
	if (pos < OPM_ErrorLineLimitPos) {
		Files_Set(&*r, r__typ, f, OPM_ErrorLineStartPos);
		return;
	}
	Files_Set(&*r, r__typ, f, OPM_ErrorLineLimitPos);
	Files_Read(&*r, r__typ, (void*)&ch);
	while ((OPM_ErrorLineLimitPos < pos && !(*r).eof)) {
		OPM_ErrorLineStartPos = OPM_ErrorLineLimitPos;
		OPM_ErrorLineNumber += 1;
		while ((((ch != 0x00 && ch != 0x0d)) && ch != 0x0a)) {
			Files_Read(&*r, r__typ, (void*)&ch);
			OPM_ErrorLineLimitPos += 1;
		}
		cheol = ch;
		Files_Read(&*r, r__typ, (void*)&ch);
		OPM_ErrorLineLimitPos += 1;
		if ((cheol == 0x0d && ch == 0x0a)) {
			OPM_ErrorLineLimitPos += 1;
			Files_Read(&*r, r__typ, (void*)&ch);
		}
	}
	Files_Set(&*r, r__typ, f, OPM_ErrorLineStartPos);
}

static void OPM_ShowLine (LONGINT pos)
{
	Files_File f = NIL;
	Files_Rider r;
	CHAR line[1023];
	INTEGER i;
	CHAR ch;
	f = Files_Old(OPM_SourceFileName, ((LONGINT)(256)));
	OPM_FindLine(f, &r, Files_Rider__typ, pos);
	i = 0;
	Files_Read(&r, Files_Rider__typ, (void*)&ch);
	while ((((((ch != 0x00 && ch != 0x0d)) && ch != 0x0a)) && i < 1022)) {
		line[__X(i, ((LONGINT)(1023)))] = ch;
		i += 1;
		Files_Read(&r, Files_Rider__typ, (void*)&ch);
	}
	line[__X(i, ((LONGINT)(1023)))] = 0x00;
	OPM_LogWLn();
	OPM_LogWLn();
	OPM_LogWNum(OPM_ErrorLineNumber, ((LONGINT)(4)));
	OPM_LogWStr((CHAR*)": ", (LONGINT)3);
	OPM_LogWStr(line, ((LONGINT)(1023)));
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"      ", (LONGINT)7);
	if (pos >= OPM_ErrorLineLimitPos) {
		pos = OPM_ErrorLineLimitPos - 1;
	}
	i = (int)(pos - OPM_ErrorLineStartPos);
	while (i > 0) {
		OPM_LogW(' ');
		i -= 1;
	}
	if (!OPM_notColorOutput) {
		vt100_SetAttr((CHAR*)"32m", (LONGINT)4);
	}
	OPM_LogW('^');
	if (!OPM_notColorOutput) {
		vt100_SetAttr((CHAR*)"0m", (LONGINT)3);
	}
	Files_Close(f);
}

void OPM_Mark (INTEGER n, LONGINT pos)
{
	if (pos == -1) {
		pos = 0;
	}
	if (n >= 0) {
		OPM_noerr = 0;
		if (pos < OPM_lasterrpos || OPM_lasterrpos + 9 < pos) {
			OPM_lasterrpos = pos;
			OPM_ShowLine(pos);
			OPM_LogWLn();
			OPM_LogWStr((CHAR*)"  ", (LONGINT)3);
			if (n < 249) {
				OPM_LogWStr((CHAR*)"  pos", (LONGINT)6);
				OPM_LogWNum(pos, ((LONGINT)(6)));
				OPM_LogErrMsg(n);
			} else if (n == 255) {
				OPM_LogWStr((CHAR*)"pos", (LONGINT)4);
				OPM_LogWNum(pos, ((LONGINT)(6)));
				OPM_LogWStr((CHAR*)"  pc ", (LONGINT)6);
				OPM_LogWNum(OPM_breakpc, ((LONGINT)(1)));
			} else if (n == 254) {
				OPM_LogWStr((CHAR*)"pc not found", (LONGINT)13);
			} else {
				OPM_LogWStr(OPM_objname, ((LONGINT)(64)));
				if (n == 253) {
					OPM_LogWStr((CHAR*)" is new, compile with option e", (LONGINT)31);
				} else if (n == 252) {
					OPM_LogWStr((CHAR*)" is redefined, compile with option s", (LONGINT)37);
				} else if (n == 251) {
					OPM_LogWStr((CHAR*)" is redefined (private part only), compile with option s", (LONGINT)57);
				} else if (n == 250) {
					OPM_LogWStr((CHAR*)" is no longer visible, compile with option s", (LONGINT)45);
				} else if (n == 249) {
					OPM_LogWStr((CHAR*)" is not consistently imported, recompile imports", (LONGINT)49);
				}
			}
		}
	} else {
		if (pos >= 0) {
			OPM_ShowLine(pos);
			OPM_LogWLn();
			OPM_LogWStr((CHAR*)"  pos", (LONGINT)6);
			OPM_LogWNum(pos, ((LONGINT)(6)));
		}
		OPM_LogErrMsg(n);
		if (pos < 0) {
			OPM_LogWLn();
		}
	}
}

void OPM_err (INTEGER n)
{
	OPM_Mark(n, OPM_errpos);
}

void OPM_FPrint (LONGINT *fp, LONGINT val)
{
	*fp = __ROTL((LONGINT)((SET)*fp ^ (SET)val), 1, LONGINT);
}

void OPM_FPrintSet (LONGINT *fp, SET set)
{
	OPM_FPrint(&*fp, (LONGINT)set);
}

void OPM_FPrintReal (LONGINT *fp, REAL real)
{
	INTEGER i;
	LONGINT l;
	__GET((LONGINT)(uintptr_t)&real, l, LONGINT);
	OPM_FPrint(&*fp, l);
}

void OPM_FPrintLReal (LONGINT *fp, LONGREAL lr)
{
	LONGINT l, h;
	__GET((LONGINT)(uintptr_t)&lr, l, LONGINT);
	__GET((LONGINT)(uintptr_t)&lr + 4, h, LONGINT);
	OPM_FPrint(&*fp, l);
	OPM_FPrint(&*fp, h);
}

static void OPM_GetProperty (Texts_Scanner *S, LONGINT *S__typ, CHAR *name, LONGINT name__len, INTEGER *size, INTEGER *align)
{
	__DUP(name, name__len, CHAR);
	if (((*S).class == 1 && __STRCMP((*S).s, name) == 0)) {
		Texts_Scan(&*S, S__typ);
		if ((*S).class == 3) {
			*size = (int)(*S).i;
			Texts_Scan(&*S, S__typ);
		} else {
			OPM_Mark(-157, ((LONGINT)(-1)));
		}
		if ((*S).class == 3) {
			*align = (int)(*S).i;
			Texts_Scan(&*S, S__typ);
		} else {
			OPM_Mark(-157, ((LONGINT)(-1)));
		}
	} else {
		OPM_Mark(-157, ((LONGINT)(-1)));
	}
	__DEL(name);
}

static LONGINT OPM_minusop (LONGINT i)
{
	LONGINT _o_result;
	_o_result = -i;
	return _o_result;
}

static LONGINT OPM_power0 (LONGINT i, LONGINT j)
{
	LONGINT _o_result;
	LONGINT k, p;
	k = 1;
	p = i;
	do {
		p = p * i;
		k += 1;
	} while (!(k == j));
	_o_result = p;
	return _o_result;
}

static void OPM_VerboseListSizes (void)
{
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"Type        Size  Alignement", (LONGINT)29);
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"CHAR         ", (LONGINT)14);
	OPM_LogWNum(OPM_CharSize, ((LONGINT)(4)));
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"BOOLEAN      ", (LONGINT)14);
	OPM_LogWNum(OPM_BoolSize, ((LONGINT)(4)));
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"SHORTINT     ", (LONGINT)14);
	OPM_LogWNum(OPM_SIntSize, ((LONGINT)(4)));
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"INTEGER      ", (LONGINT)14);
	OPM_LogWNum(OPM_IntSize, ((LONGINT)(4)));
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"LONGINT      ", (LONGINT)14);
	OPM_LogWNum(OPM_LIntSize, ((LONGINT)(4)));
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"SET          ", (LONGINT)14);
	OPM_LogWNum(OPM_SetSize, ((LONGINT)(4)));
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"REAL         ", (LONGINT)14);
	OPM_LogWNum(OPM_RealSize, ((LONGINT)(4)));
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"LONGREAL     ", (LONGINT)14);
	OPM_LogWNum(OPM_LRealSize, ((LONGINT)(4)));
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"PTR          ", (LONGINT)14);
	OPM_LogWNum(OPM_PointerSize, ((LONGINT)(4)));
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"PROC         ", (LONGINT)14);
	OPM_LogWNum(OPM_ProcSize, ((LONGINT)(4)));
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"RECORD       ", (LONGINT)14);
	OPM_LogWNum(OPM_RecSize, ((LONGINT)(4)));
	OPM_LogWLn();
	OPM_LogWLn();
}

LONGINT OPM_SignedMaximum (LONGINT bytecount)
{
	LONGINT _o_result;
	LONGINT result;
	result = 1;
	result = __LSH(result, __ASHL(bytecount, 3) - 1, LONGINT);
	_o_result = result - 1;
	return _o_result;
}

LONGINT OPM_SignedMinimum (LONGINT bytecount)
{
	LONGINT _o_result;
	_o_result = -OPM_SignedMaximum(bytecount) - 1;
	return _o_result;
}

static void OPM_GetProperties (void)
{
	OPM_ProcSize = OPM_PointerSize;
	OPM_LIntSize = __ASHL(OPM_IntSize, 1);
	OPM_SetSize = OPM_LIntSize;
	if (OPM_RealSize == 4) {
		OPM_MaxReal =   3.40282346000000e+038;
	} else if (OPM_RealSize == 8) {
		OPM_MaxReal =   1.79769296342094e+308;
	}
	if (OPM_LRealSize == 4) {
		OPM_MaxLReal =   3.40282346000000e+038;
	} else if (OPM_LRealSize == 8) {
		OPM_MaxLReal =   1.79769296342094e+308;
	}
	OPM_MinReal = -OPM_MaxReal;
	OPM_MinLReal = -OPM_MaxLReal;
	OPM_MaxSet = __ASHL(OPM_SetSize, 3) - 1;
	OPM_MaxIndex = OPM_SignedMaximum(OPM_PointerSize);
	if (OPM_Verbose) {
		OPM_VerboseListSizes();
	}
}

void OPM_SymRCh (CHAR *ch)
{
	Files_Read(&OPM_oldSF, Files_Rider__typ, (void*)&*ch);
}

LONGINT OPM_SymRInt (void)
{
	LONGINT _o_result;
	LONGINT k;
	Files_ReadNum(&OPM_oldSF, Files_Rider__typ, &k);
	_o_result = k;
	return _o_result;
}

void OPM_SymRSet (SET *s)
{
	Files_ReadNum(&OPM_oldSF, Files_Rider__typ, (LONGINT*)&*s);
}

void OPM_SymRReal (REAL *r)
{
	Files_ReadReal(&OPM_oldSF, Files_Rider__typ, &*r);
}

void OPM_SymRLReal (LONGREAL *lr)
{
	Files_ReadLReal(&OPM_oldSF, Files_Rider__typ, &*lr);
}

void OPM_CloseOldSym (void)
{
}

void OPM_OldSym (CHAR *modName, LONGINT modName__len, BOOLEAN *done)
{
	CHAR ch;
	OPM_FileName fileName;
	OPM_MakeFileName((void*)modName, modName__len, (void*)fileName, ((LONGINT)(32)), (CHAR*)".sym", (LONGINT)5);
	OPM_oldSFile = Files_Old(fileName, ((LONGINT)(32)));
	*done = OPM_oldSFile != NIL;
	if (*done) {
		Files_Set(&OPM_oldSF, Files_Rider__typ, OPM_oldSFile, ((LONGINT)(0)));
		Files_Read(&OPM_oldSF, Files_Rider__typ, (void*)&ch);
		if (ch != 0xf7) {
			OPM_err(-306);
			OPM_CloseOldSym();
			*done = 0;
		}
	}
}

BOOLEAN OPM_eofSF (void)
{
	BOOLEAN _o_result;
	_o_result = OPM_oldSF.eof;
	return _o_result;
}

void OPM_SymWCh (CHAR ch)
{
	Files_Write(&OPM_newSF, Files_Rider__typ, ch);
}

void OPM_SymWInt (LONGINT i)
{
	Files_WriteNum(&OPM_newSF, Files_Rider__typ, i);
}

void OPM_SymWSet (SET s)
{
	Files_WriteNum(&OPM_newSF, Files_Rider__typ, (LONGINT)s);
}

void OPM_SymWReal (REAL r)
{
	Files_WriteReal(&OPM_newSF, Files_Rider__typ, r);
}

void OPM_SymWLReal (LONGREAL lr)
{
	Files_WriteLReal(&OPM_newSF, Files_Rider__typ, lr);
}

void OPM_RegisterNewSym (void)
{
	if (__STRCMP(OPM_modName, "SYSTEM") != 0 || __IN(10, OPM_opt)) {
		Files_Register(OPM_newSFile);
	}
}

void OPM_DeleteNewSym (void)
{
}

void OPM_NewSym (CHAR *modName, LONGINT modName__len)
{
	OPM_FileName fileName;
	OPM_MakeFileName((void*)modName, modName__len, (void*)fileName, ((LONGINT)(32)), (CHAR*)".sym", (LONGINT)5);
	OPM_newSFile = Files_New(fileName, ((LONGINT)(32)));
	if (OPM_newSFile != NIL) {
		Files_Set(&OPM_newSF, Files_Rider__typ, OPM_newSFile, ((LONGINT)(0)));
		Files_Write(&OPM_newSF, Files_Rider__typ, 0xf7);
	} else {
		OPM_err(153);
	}
}

void OPM_Write (CHAR ch)
{
	Files_Write(&OPM_R[__X(OPM_currFile, ((LONGINT)(3)))], Files_Rider__typ, ch);
}

void OPM_WriteString (CHAR *s, LONGINT s__len)
{
	INTEGER i;
	i = 0;
	while (s[__X(i, s__len)] != 0x00) {
		i += 1;
	}
	Files_WriteBytes(&OPM_R[__X(OPM_currFile, ((LONGINT)(3)))], Files_Rider__typ, (void*)s, s__len * ((LONGINT)(1)), i);
}

void OPM_WriteStringVar (CHAR *s, LONGINT s__len)
{
	INTEGER i;
	i = 0;
	while (s[__X(i, s__len)] != 0x00) {
		i += 1;
	}
	Files_WriteBytes(&OPM_R[__X(OPM_currFile, ((LONGINT)(3)))], Files_Rider__typ, (void*)s, s__len * ((LONGINT)(1)), i);
}

void OPM_WriteHex (LONGINT i)
{
	CHAR s[3];
	INTEGER digit;
	digit = __ASHR((int)i, 4);
	if (digit < 10) {
		s[0] = (CHAR)(48 + digit);
	} else {
		s[0] = (CHAR)(87 + digit);
	}
	digit = __MASK((int)i, -16);
	if (digit < 10) {
		s[1] = (CHAR)(48 + digit);
	} else {
		s[1] = (CHAR)(87 + digit);
	}
	s[2] = 0x00;
	OPM_WriteString(s, ((LONGINT)(3)));
}

void OPM_WriteInt (LONGINT i)
{
	CHAR s[20];
	LONGINT i1, k;
	if (i == OPM_SignedMinimum(OPM_IntSize) || i == OPM_SignedMinimum(OPM_LIntSize)) {
		OPM_Write('(');
		OPM_WriteInt(i + 1);
		OPM_WriteString((CHAR*)"-1)", (LONGINT)4);
	} else {
		i1 = __ABS(i);
		s[0] = (CHAR)(__MOD(i1, 10) + 48);
		i1 = __DIV(i1, 10);
		k = 1;
		while (i1 > 0) {
			s[__X(k, ((LONGINT)(20)))] = (CHAR)(__MOD(i1, 10) + 48);
			i1 = __DIV(i1, 10);
			k += 1;
		}
		if (i < 0) {
			s[__X(k, ((LONGINT)(20)))] = '-';
			k += 1;
		}
		while (k > 0) {
			k -= 1;
			OPM_Write(s[__X(k, ((LONGINT)(20)))]);
		}
	}
}

void OPM_WriteReal (LONGREAL r, CHAR suffx)
{
	Texts_Writer W;
	Texts_Text T = NIL;
	Texts_Reader R;
	CHAR s[32];
	CHAR ch;
	INTEGER i;
	if ((((r < OPM_SignedMaximum(OPM_LIntSize) && r > OPM_SignedMinimum(OPM_LIntSize))) && r == (__ENTIER(r)))) {
		if (suffx == 'f') {
			OPM_WriteString((CHAR*)"(REAL)", (LONGINT)7);
		} else {
			OPM_WriteString((CHAR*)"(LONGREAL)", (LONGINT)11);
		}
		OPM_WriteInt(__ENTIER(r));
	} else {
		Texts_OpenWriter(&W, Texts_Writer__typ);
		if (suffx == 'f') {
			Texts_WriteLongReal(&W, Texts_Writer__typ, r, 16);
		} else {
			Texts_WriteLongReal(&W, Texts_Writer__typ, r, 23);
		}
		__NEW(T, Texts_TextDesc);
		Texts_Open(T, (CHAR*)"", (LONGINT)1);
		Texts_Append(T, W.buf);
		Texts_OpenReader(&R, Texts_Reader__typ, T, ((LONGINT)(0)));
		i = 0;
		Texts_Read(&R, Texts_Reader__typ, &ch);
		while (ch != 0x00) {
			s[__X(i, ((LONGINT)(32)))] = ch;
			i += 1;
			Texts_Read(&R, Texts_Reader__typ, &ch);
		}
		s[__X(i, ((LONGINT)(32)))] = 0x00;
		i = 0;
		ch = s[0];
		while ((ch != 'D' && ch != 0x00)) {
			i += 1;
			ch = s[__X(i, ((LONGINT)(32)))];
		}
		if (ch == 'D') {
			s[__X(i, ((LONGINT)(32)))] = 'e';
		}
		OPM_WriteString(s, ((LONGINT)(32)));
	}
}

void OPM_WriteLn (void)
{
	Files_Write(&OPM_R[__X(OPM_currFile, ((LONGINT)(3)))], Files_Rider__typ, 0x0a);
}

static void OPM_Append (Files_Rider *R, LONGINT *R__typ, Files_File F)
{
	Files_Rider R1;
	CHAR buffer[4096];
	if (F != NIL) {
		Files_Set(&R1, Files_Rider__typ, F, ((LONGINT)(0)));
		Files_ReadBytes(&R1, Files_Rider__typ, (void*)buffer, ((LONGINT)(4096)), ((LONGINT)(4096)));
		while (4096 - R1.res > 0) {
			Files_WriteBytes(&*R, R__typ, (void*)buffer, ((LONGINT)(4096)), 4096 - R1.res);
			Files_ReadBytes(&R1, Files_Rider__typ, (void*)buffer, ((LONGINT)(4096)), ((LONGINT)(4096)));
		}
	}
}

void OPM_OpenFiles (CHAR *moduleName, LONGINT moduleName__len)
{
	CHAR FName[32];
	__COPY(moduleName, OPM_modName, ((LONGINT)(32)));
	OPM_HFile = Files_New((CHAR*)"", (LONGINT)1);
	if (OPM_HFile != NIL) {
		Files_Set(&OPM_R[0], Files_Rider__typ, OPM_HFile, ((LONGINT)(0)));
	} else {
		OPM_err(153);
	}
	OPM_MakeFileName((void*)moduleName, moduleName__len, (void*)FName, ((LONGINT)(32)), (CHAR*)".c", (LONGINT)3);
	OPM_BFile = Files_New(FName, ((LONGINT)(32)));
	if (OPM_BFile != NIL) {
		Files_Set(&OPM_R[1], Files_Rider__typ, OPM_BFile, ((LONGINT)(0)));
	} else {
		OPM_err(153);
	}
	OPM_MakeFileName((void*)moduleName, moduleName__len, (void*)FName, ((LONGINT)(32)), (CHAR*)".h", (LONGINT)3);
	OPM_HIFile = Files_New(FName, ((LONGINT)(32)));
	if (OPM_HIFile != NIL) {
		Files_Set(&OPM_R[2], Files_Rider__typ, OPM_HIFile, ((LONGINT)(0)));
	} else {
		OPM_err(153);
	}
}

void OPM_CloseFiles (void)
{
	CHAR FName[32];
	INTEGER res;
	if (OPM_noerr) {
		OPM_LogWStr((CHAR*)"  ", (LONGINT)3);
		OPM_LogWNum(Files_Pos(&OPM_R[1], Files_Rider__typ), ((LONGINT)(0)));
		OPM_LogWStr((CHAR*)" chars.", (LONGINT)8);
	}
	if (OPM_noerr) {
		if (__STRCMP(OPM_modName, "SYSTEM") == 0) {
			if (!__IN(10, OPM_opt)) {
				Files_Register(OPM_BFile);
			}
		} else if (!__IN(10, OPM_opt)) {
			OPM_Append(&OPM_R[2], Files_Rider__typ, OPM_HFile);
			Files_Register(OPM_HIFile);
			Files_Register(OPM_BFile);
		} else {
			OPM_MakeFileName((void*)OPM_modName, ((LONGINT)(32)), (void*)FName, ((LONGINT)(32)), (CHAR*)".h", (LONGINT)3);
			Files_Delete(FName, ((LONGINT)(32)), &res);
			OPM_MakeFileName((void*)OPM_modName, ((LONGINT)(32)), (void*)FName, ((LONGINT)(32)), (CHAR*)".sym", (LONGINT)5);
			Files_Delete(FName, ((LONGINT)(32)), &res);
			Files_Register(OPM_BFile);
		}
	}
	OPM_HFile = NIL;
	OPM_BFile = NIL;
	OPM_HIFile = NIL;
	OPM_newSFile = NIL;
	OPM_oldSFile = NIL;
	Files_Set(&OPM_R[0], Files_Rider__typ, NIL, ((LONGINT)(0)));
	Files_Set(&OPM_R[1], Files_Rider__typ, NIL, ((LONGINT)(0)));
	Files_Set(&OPM_R[2], Files_Rider__typ, NIL, ((LONGINT)(0)));
	Files_Set(&OPM_newSF, Files_Rider__typ, NIL, ((LONGINT)(0)));
	Files_Set(&OPM_oldSF, Files_Rider__typ, NIL, ((LONGINT)(0)));
}

static void EnumPtrs(void (*P)(void*))
{
	__ENUMR(&OPM_inR, Texts_Reader__typ, 48, 1, P);
	P(OPM_Log);
	__ENUMR(&OPM_W, Texts_Writer__typ, 36, 1, P);
	__ENUMR(&OPM_oldSF, Files_Rider__typ, 20, 1, P);
	__ENUMR(&OPM_newSF, Files_Rider__typ, 20, 1, P);
	__ENUMR(OPM_R, Files_Rider__typ, 20, 3, P);
	P(OPM_oldSFile);
	P(OPM_newSFile);
	P(OPM_HFile);
	P(OPM_BFile);
	P(OPM_HIFile);
}


export void *OPM__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(Configuration);
	__MODULE_IMPORT(Console);
	__MODULE_IMPORT(Files);
	__MODULE_IMPORT(Platform);
	__MODULE_IMPORT(Strings);
	__MODULE_IMPORT(Texts);
	__MODULE_IMPORT(errors);
	__MODULE_IMPORT(vt100);
	__REGMOD("OPM", EnumPtrs);
	__REGCMD("CloseFiles", OPM_CloseFiles);
	__REGCMD("CloseOldSym", OPM_CloseOldSym);
	__REGCMD("DeleteNewSym", OPM_DeleteNewSym);
	__REGCMD("InitOptions", OPM_InitOptions);
	__REGCMD("LogWLn", OPM_LogWLn);
	__REGCMD("RegisterNewSym", OPM_RegisterNewSym);
	__REGCMD("WriteLn", OPM_WriteLn);
/* BEGIN */
	Texts_OpenWriter(&OPM_W, Texts_Writer__typ);
	OPM_MODULES[0] = 0x00;
	Platform_GetEnv((CHAR*)"MODULES", (LONGINT)8, (void*)OPM_MODULES, ((LONGINT)(1024)));
	__MOVE(".", OPM_OBERON, 2);
	Platform_GetEnv((CHAR*)"OBERON", (LONGINT)7, (void*)OPM_OBERON, ((LONGINT)(1024)));
	Strings_Append((CHAR*)";.;", (LONGINT)4, (void*)OPM_OBERON, ((LONGINT)(1024)));
	Strings_Append(OPM_MODULES, ((LONGINT)(1024)), (void*)OPM_OBERON, ((LONGINT)(1024)));
	Strings_Append((CHAR*)";", (LONGINT)2, (void*)OPM_OBERON, ((LONGINT)(1024)));
	Strings_Append((CHAR*)"/opt/voc", (LONGINT)9, (void*)OPM_OBERON, ((LONGINT)(1024)));
	Strings_Append((CHAR*)"/sym;", (LONGINT)6, (void*)OPM_OBERON, ((LONGINT)(1024)));
	Files_SetSearchPath(OPM_OBERON, ((LONGINT)(1024)));
	OPM_CharSize = 1;
	OPM_BoolSize = 1;
	OPM_SIntSize = 1;
	OPM_RecSize = 1;
	OPM_ByteSize = 1;
	OPM_RealSize = 4;
	OPM_LRealSize = 8;
	OPM_PointerSize = 8;
	OPM_Alignment = 8;
	OPM_IntSize = 4;
	__ENDMOD;
}
