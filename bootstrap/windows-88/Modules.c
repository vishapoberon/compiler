/* voc 2.00 [2016/12/03]. Bootstrapping compiler for address size 8, alignment 8. xtspaSF */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32

#include "SYSTEM.h"
#include "Heap.h"
#include "Platform.h"

typedef
	struct Modules_CmdDesc *Modules_Cmd;

typedef
	void (*Modules_Command)(void);

typedef
	struct Modules_CmdDesc {
		Modules_Cmd next;
		CHAR name[24];
		Modules_Command cmd;
	} Modules_CmdDesc;

typedef
	struct Modules_ModuleDesc *Modules_Module;

typedef
	CHAR Modules_ModuleName[20];

typedef
	struct Modules_ModuleDesc {
		Modules_Module next;
		Modules_ModuleName name;
		INT32 refcnt;
		Modules_Cmd cmds;
		INT32 types;
		void (*enumPtrs)(void(*)(INT32));
		INT32 reserved1, reserved2;
	} Modules_ModuleDesc;


export INT16 Modules_res;
export CHAR Modules_resMsg[256];
export Modules_ModuleName Modules_imported, Modules_importing;
export INT64 Modules_MainStackFrame;
export INT16 Modules_ArgCount;
export INT64 Modules_ArgVector;
export CHAR Modules_BinaryDir[1024];

export ADDRESS *Modules_ModuleDesc__typ;
export ADDRESS *Modules_CmdDesc__typ;

static void Modules_Append (CHAR *s, ADDRESS s__len, CHAR *d, ADDRESS d__len);
static void Modules_AppendPart (CHAR c, CHAR *s, ADDRESS s__len, CHAR *d, ADDRESS d__len);
export INT16 Modules_ArgPos (CHAR *s, ADDRESS s__len);
export void Modules_AssertFail (INT32 code);
static void Modules_Canonify (CHAR *s, ADDRESS s__len, CHAR *d, ADDRESS d__len);
static INT16 Modules_CharCount (CHAR *s, ADDRESS s__len);
static void Modules_DisplayHaltCode (INT32 code);
static void Modules_ExtractPart (CHAR *s, ADDRESS s__len, INT16 *i, CHAR *p, ADDRESS p__len, CHAR *d, ADDRESS d__len);
static void Modules_FindBinaryDir (CHAR *d, ADDRESS d__len);
export void Modules_Free (CHAR *name, ADDRESS name__len, BOOLEAN all);
export void Modules_GetArg (INT16 n, CHAR *val, ADDRESS val__len);
export void Modules_GetIntArg (INT16 n, INT32 *val);
export void Modules_Halt (INT32 code);
export void Modules_Init (INT32 argc, INT64 argvadr);
static BOOLEAN Modules_IsAbsolute (CHAR *d, ADDRESS d__len);
static BOOLEAN Modules_IsFilePresent (CHAR *s, ADDRESS s__len);
static BOOLEAN Modules_IsOneOf (CHAR c, CHAR *s, ADDRESS s__len);
export Modules_Command Modules_ThisCommand (Modules_Module mod, CHAR *name, ADDRESS name__len);
export Modules_Module Modules_ThisMod (CHAR *name, ADDRESS name__len);
static void Modules_Trim (CHAR *s, ADDRESS s__len, CHAR *d, ADDRESS d__len);
static void Modules_errch (CHAR c);
static void Modules_errint (INT32 l);
static void Modules_errstring (CHAR *s, ADDRESS s__len);

extern void Heap_InitHeap();
extern void *Modules__init(void);
#define Modules_InitHeap()	Heap_InitHeap()
#define Modules_ModulesInit()	Modules__init()
#define Modules_modules()	(Modules_Module)Heap_modules
#define Modules_setmodules(m)	Heap_modules = m

void Modules_Init (INT32 argc, INT64 argvadr)
{
	Modules_MainStackFrame = argvadr;
	Modules_ArgCount = __VAL(INT16, argc);
	__GET(argvadr, Modules_ArgVector, INT64);
	Modules_InitHeap();
	Modules_ModulesInit();
}

typedef
	CHAR (*argptr__15)[1024];

void Modules_GetArg (INT16 n, CHAR *val, ADDRESS val__len)
{
	argptr__15 arg = NIL;
	if (n < Modules_ArgCount) {
		__GET(Modules_ArgVector + (INT64)__ASHL(n, 3), arg, argptr__15);
		__COPY(*arg, val, val__len);
	}
}

void Modules_GetIntArg (INT16 n, INT32 *val)
{
	CHAR s[64];
	INT32 k, d, i;
	s[0] = 0x00;
	Modules_GetArg(n, (void*)s, 64);
	i = 0;
	if (s[0] == '-') {
		i = 1;
	}
	k = 0;
	d = (INT16)s[__X(i, 64)] - 48;
	while ((d >= 0 && d <= 9)) {
		k = k * 10 + d;
		i += 1;
		d = (INT16)s[__X(i, 64)] - 48;
	}
	if (s[0] == '-') {
		k = -k;
		i -= 1;
	}
	if (i > 0) {
		*val = k;
	}
}

INT16 Modules_ArgPos (CHAR *s, ADDRESS s__len)
{
	INT16 i;
	CHAR arg[256];
	__DUP(s, s__len, CHAR);
	i = 0;
	Modules_GetArg(i, (void*)arg, 256);
	while ((i < Modules_ArgCount && __STRCMP(s, arg) != 0)) {
		i += 1;
		Modules_GetArg(i, (void*)arg, 256);
	}
	__DEL(s);
	return i;
}

static INT16 Modules_CharCount (CHAR *s, ADDRESS s__len)
{
	INT16 i;
	__DUP(s, s__len, CHAR);
	i = 0;
	while ((i < s__len && s[__X(i, s__len)] != 0x00)) {
		i += 1;
	}
	__DEL(s);
	return i;
}

static void Modules_Append (CHAR *s, ADDRESS s__len, CHAR *d, ADDRESS d__len)
{
	INT16 i, j;
	__DUP(s, s__len, CHAR);
	i = 0;
	j = Modules_CharCount(d, d__len);
	while (s[__X(i, s__len)] != 0x00) {
		d[__X(j, d__len)] = s[__X(i, s__len)];
		i += 1;
		j += 1;
	}
	d[__X(j, d__len)] = 0x00;
	__DEL(s);
}

static void Modules_AppendPart (CHAR c, CHAR *s, ADDRESS s__len, CHAR *d, ADDRESS d__len)
{
	INT16 i, j;
	__DUP(s, s__len, CHAR);
	i = 0;
	j = Modules_CharCount(d, d__len);
	if ((j > 0 && d[__X(j - 1, d__len)] != c)) {
		d[__X(j, d__len)] = c;
		j += 1;
	}
	while (s[__X(i, s__len)] != 0x00) {
		d[__X(j, d__len)] = s[__X(i, s__len)];
		i += 1;
		j += 1;
	}
	d[__X(j, d__len)] = 0x00;
	__DEL(s);
}

static BOOLEAN Modules_IsOneOf (CHAR c, CHAR *s, ADDRESS s__len)
{
	INT16 i;
	__DUP(s, s__len, CHAR);
	if (c == 0x00) {
		__DEL(s);
		return 0;
	}
	i = 0;
	while ((s[__X(i, s__len)] != c && s[__X(i, s__len)] != 0x00)) {
		i += 1;
	}
	__DEL(s);
	return s[__X(i, s__len)] == c;
}

static BOOLEAN Modules_IsAbsolute (CHAR *d, ADDRESS d__len)
{
	__DUP(d, d__len, CHAR);
	if (d[0] == 0x00) {
		__DEL(d);
		return 0;
	}
	if (Modules_IsOneOf(d[0], (CHAR*)"/\\", 3)) {
		__DEL(d);
		return 1;
	}
	if (d[__X(1, d__len)] == ':') {
		__DEL(d);
		return 1;
	}
	__DEL(d);
	return 0;
}

static void Modules_Canonify (CHAR *s, ADDRESS s__len, CHAR *d, ADDRESS d__len)
{
	__DUP(s, s__len, CHAR);
	if (Modules_IsAbsolute(s, s__len)) {
		__COPY(s, d, d__len);
	} else {
		__COPY(Platform_CWD, d, d__len);
		Modules_AppendPart('/', s, s__len, (void*)d, d__len);
	}
	__DEL(s);
}

static BOOLEAN Modules_IsFilePresent (CHAR *s, ADDRESS s__len)
{
	Platform_FileIdentity identity;
	__DUP(s, s__len, CHAR);
	__DEL(s);
	return Platform_IdentifyByName(s, s__len, &identity, Platform_FileIdentity__typ) == 0;
}

static void Modules_ExtractPart (CHAR *s, ADDRESS s__len, INT16 *i, CHAR *p, ADDRESS p__len, CHAR *d, ADDRESS d__len)
{
	INT16 j;
	__DUP(s, s__len, CHAR);
	__DUP(p, p__len, CHAR);
	j = 0;
	while ((s[__X(*i, s__len)] != 0x00 && !Modules_IsOneOf(s[__X(*i, s__len)], p, p__len))) {
		d[__X(j, d__len)] = s[__X(*i, s__len)];
		*i += 1;
		j += 1;
	}
	d[__X(j, d__len)] = 0x00;
	while (Modules_IsOneOf(s[__X(*i, s__len)], p, p__len)) {
		*i += 1;
	}
	__DEL(s);
	__DEL(p);
}

static void Modules_Trim (CHAR *s, ADDRESS s__len, CHAR *d, ADDRESS d__len)
{
	INT16 i, j;
	CHAR part[1024];
	__DUP(s, s__len, CHAR);
	i = 0;
	j = 0;
	while ((i < 2 && Modules_IsOneOf(s[__X(i, s__len)], (CHAR*)"/\\", 3))) {
		i += 1;
		d[__X(j, d__len)] = '/';
		j += 1;
	}
	d[__X(j, d__len)] = 0x00;
	while (s[__X(i, s__len)] != 0x00) {
		Modules_ExtractPart(s, s__len, &i, (CHAR*)"/\\", 3, (void*)part, 1024);
		if ((part[0] != 0x00 && __STRCMP(part, ".") != 0)) {
			Modules_AppendPart('/', part, 1024, (void*)d, d__len);
		}
	}
	__DEL(s);
}

typedef
	CHAR pathstring__12[4096];

static void Modules_FindBinaryDir (CHAR *d, ADDRESS d__len)
{
	pathstring__12 executable, dir, testpath, pathlist;
	INT16 i, j, k;
	BOOLEAN present;
	if (Modules_ArgCount < 1) {
		d[0] = 0x00;
		return;
	}
	Modules_GetArg(0, (void*)testpath, 4096);
	Modules_Trim(testpath, 4096, (void*)executable, 4096);
	Modules_Canonify(executable, 4096, (void*)d, d__len);
	present = Modules_IsFilePresent(d, d__len);
	if ((!present && !Modules_IsAbsolute(testpath, 4096))) {
		Platform_GetEnv((CHAR*)"PATH", 5, (void*)pathlist, 4096);
		i = 0;
		while ((!present && pathlist[__X(i, 4096)] != 0x00)) {
			Modules_ExtractPart(pathlist, 4096, &i, (CHAR*)":;", 3, (void*)dir, 4096);
			Modules_Trim(dir, 4096, (void*)testpath, 4096);
			Modules_AppendPart('/', executable, 4096, (void*)testpath, 4096);
			Modules_Canonify(testpath, 4096, (void*)d, d__len);
			present = Modules_IsFilePresent(d, d__len);
		}
	}
	if (present) {
		k = Modules_CharCount(d, d__len);
		while ((k > 0 && !Modules_IsOneOf(d[__X(k - 1, d__len)], (CHAR*)"/\\", 3))) {
			k -= 1;
		}
		if (k == 0) {
			d[__X(k, d__len)] = 0x00;
		} else {
			d[__X(k - 1, d__len)] = 0x00;
		}
	} else {
		d[0] = 0x00;
	}
}

Modules_Module Modules_ThisMod (CHAR *name, ADDRESS name__len)
{
	Modules_Module m = NIL;
	CHAR bodyname[64];
	Modules_Command body;
	__DUP(name, name__len, CHAR);
	m = Modules_modules();
	while ((m != NIL && __STRCMP(m->name, name) != 0)) {
		m = m->next;
	}
	if (m != NIL) {
		Modules_res = 0;
		Modules_resMsg[0] = 0x00;
	} else {
		Modules_res = 1;
		__COPY(name, Modules_importing, 20);
		__MOVE(" module \"", Modules_resMsg, 10);
		Modules_Append(name, name__len, (void*)Modules_resMsg, 256);
		Modules_Append((CHAR*)"\" not found", 12, (void*)Modules_resMsg, 256);
	}
	__DEL(name);
	return m;
}

Modules_Command Modules_ThisCommand (Modules_Module mod, CHAR *name, ADDRESS name__len)
{
	Modules_Cmd c = NIL;
	__DUP(name, name__len, CHAR);
	c = mod->cmds;
	while ((c != NIL && __STRCMP(c->name, name) != 0)) {
		c = c->next;
	}
	if (c != NIL) {
		Modules_res = 0;
		Modules_resMsg[0] = 0x00;
		__DEL(name);
		return c->cmd;
	} else {
		Modules_res = 2;
		__MOVE(" command \"", Modules_resMsg, 11);
		__COPY(name, Modules_importing, 20);
		Modules_Append(mod->name, 20, (void*)Modules_resMsg, 256);
		Modules_Append((CHAR*)".", 2, (void*)Modules_resMsg, 256);
		Modules_Append(name, name__len, (void*)Modules_resMsg, 256);
		Modules_Append((CHAR*)"\" not found", 12, (void*)Modules_resMsg, 256);
		__DEL(name);
		return NIL;
	}
	__RETCHK;
}

void Modules_Free (CHAR *name, ADDRESS name__len, BOOLEAN all)
{
	Modules_Module m = NIL, p = NIL;
	__DUP(name, name__len, CHAR);
	m = Modules_modules();
	if (all) {
		Modules_res = 1;
		__MOVE("unloading \"all\" not yet supported", Modules_resMsg, 34);
	} else {
		while ((m != NIL && __STRCMP(m->name, name) != 0)) {
			p = m;
			m = m->next;
		}
		if ((m != NIL && m->refcnt == 0)) {
			if (m == Modules_modules()) {
				Modules_setmodules(m->next);
			} else {
				p->next = m->next;
			}
			Modules_res = 0;
		} else {
			Modules_res = 1;
			if (m == NIL) {
				__MOVE("module not found", Modules_resMsg, 17);
			} else {
				__MOVE("clients of this module exist", Modules_resMsg, 29);
			}
		}
	}
	__DEL(name);
}

static void Modules_errch (CHAR c)
{
	INT16 e;
	e = Platform_Write(Platform_StdOut, (ADDRESS)&c, 1);
}

static void Modules_errstring (CHAR *s, ADDRESS s__len)
{
	INT32 i;
	__DUP(s, s__len, CHAR);
	i = 0;
	while ((i < s__len && s[__X(i, s__len)] != 0x00)) {
		Modules_errch(s[__X(i, s__len)]);
		i += 1;
	}
	__DEL(s);
}

static void Modules_errint (INT32 l)
{
	if (l < 0) {
		Modules_errch('-');
		l = -l;
	}
	if (l >= 10) {
		Modules_errint(__DIV(l, 10));
	}
	Modules_errch((CHAR)((int)__MOD(l, 10) + 48));
}

static void Modules_DisplayHaltCode (INT32 code)
{
	switch (code) {
		case -1: 
			Modules_errstring((CHAR*)"Assertion failure.", 19);
			break;
		case -2: 
			Modules_errstring((CHAR*)"Index out of range.", 20);
			break;
		case -3: 
			Modules_errstring((CHAR*)"Reached end of function without reaching RETURN.", 49);
			break;
		case -4: 
			Modules_errstring((CHAR*)"CASE statement: no matching label and no ELSE.", 47);
			break;
		case -5: 
			Modules_errstring((CHAR*)"Type guard failed.", 19);
			break;
		case -6: 
			Modules_errstring((CHAR*)"Implicit type guard in record assignment failed.", 49);
			break;
		case -7: 
			Modules_errstring((CHAR*)"Invalid case in WITH statement.", 32);
			break;
		case -8: 
			Modules_errstring((CHAR*)"Value out of range.", 20);
			break;
		case -9: 
			Modules_errstring((CHAR*)"Heap interrupted while locked, but lockdepth = 0 at unlock.", 60);
			break;
		case -10: 
			Modules_errstring((CHAR*)"NIL access.", 12);
			break;
		case -11: 
			Modules_errstring((CHAR*)"Alignment error.", 17);
			break;
		case -12: 
			Modules_errstring((CHAR*)"Divide by zero.", 16);
			break;
		case -13: 
			Modules_errstring((CHAR*)"Arithmetic overflow/underflow.", 31);
			break;
		case -14: 
			Modules_errstring((CHAR*)"Invalid function argument.", 27);
			break;
		case -15: 
			Modules_errstring((CHAR*)"Internal error, e.g. Type descriptor size mismatch.", 52);
			break;
		case -20: 
			Modules_errstring((CHAR*)"Too many, or negative number of, elements in dynamic array.", 60);
			break;
		default: 
			break;
	}
}

void Modules_Halt (INT32 code)
{
	Heap_FINALL();
	Modules_errstring((CHAR*)"Terminated by Halt(", 20);
	Modules_errint(code);
	Modules_errstring((CHAR*)"). ", 4);
	if (code < 0) {
		Modules_DisplayHaltCode(code);
	}
	Modules_errstring(Platform_NL, 3);
	Platform_Exit(code);
}

void Modules_AssertFail (INT32 code)
{
	Heap_FINALL();
	Modules_errstring((CHAR*)"Assertion failure.", 19);
	if (code != 0) {
		Modules_errstring((CHAR*)" ASSERT code ", 14);
		Modules_errint(code);
		Modules_errstring((CHAR*)".", 2);
	}
	Modules_errstring(Platform_NL, 3);
	if (code > 0) {
		Platform_Exit(code);
	} else {
		Platform_Exit(-1);
	}
}

__TDESC(Modules_ModuleDesc, 1, 2) = {__TDFLDS("ModuleDesc", 64), {0, 32, -24}};
__TDESC(Modules_CmdDesc, 1, 1) = {__TDFLDS("CmdDesc", 40), {0, -16}};

export void *Modules__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(Heap);
	__MODULE_IMPORT(Platform);
	__REGMOD("Modules", 0);
	__INITYP(Modules_ModuleDesc, Modules_ModuleDesc, 0);
	__INITYP(Modules_CmdDesc, Modules_CmdDesc, 0);
/* BEGIN */
	Modules_FindBinaryDir((void*)Modules_BinaryDir, 1024);
	__ENDMOD;
}
