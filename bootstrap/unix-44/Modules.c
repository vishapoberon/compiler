/* voc 1.95 [2016/11/24]. Bootstrapping compiler for address size 8, alignment 8. xtspaSF */

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

export ADDRESS *Modules_ModuleDesc__typ;
export ADDRESS *Modules_CmdDesc__typ;

static void Modules_Append (CHAR *a, LONGINT a__len, CHAR *b, LONGINT b__len);
export void Modules_AssertFail (INT32 code);
static void Modules_DisplayHaltCode (INT32 code);
export void Modules_Free (CHAR *name, LONGINT name__len, BOOLEAN all);
export void Modules_Halt (INT32 code);
export Modules_Command Modules_ThisCommand (Modules_Module mod, CHAR *name, LONGINT name__len);
export Modules_Module Modules_ThisMod (CHAR *name, LONGINT name__len);
static void Modules_errch (CHAR c);
static void Modules_errint (INT32 l);
static void Modules_errstring (CHAR *s, LONGINT s__len);

#define Modules_modules()	(Modules_Module)Heap_modules
#define Modules_setmodules(m)	Heap_modules = m

static void Modules_Append (CHAR *a, LONGINT a__len, CHAR *b, LONGINT b__len)
{
	INT16 i, j;
	__DUP(b, b__len, CHAR);
	i = 0;
	while (a[__X(i, a__len)] != 0x00) {
		i += 1;
	}
	j = 0;
	while (b[__X(j, b__len)] != 0x00) {
		a[__X(i, a__len)] = b[__X(j, b__len)];
		i += 1;
		j += 1;
	}
	a[__X(i, a__len)] = 0x00;
	__DEL(b);
}

Modules_Module Modules_ThisMod (CHAR *name, LONGINT name__len)
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
		Modules_Append((void*)Modules_resMsg, 256, name, name__len);
		Modules_Append((void*)Modules_resMsg, 256, (CHAR*)"\" not found", 12);
	}
	__DEL(name);
	return m;
}

Modules_Command Modules_ThisCommand (Modules_Module mod, CHAR *name, LONGINT name__len)
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
		Modules_Append((void*)Modules_resMsg, 256, mod->name, 20);
		Modules_Append((void*)Modules_resMsg, 256, (CHAR*)".", 2);
		Modules_Append((void*)Modules_resMsg, 256, name, name__len);
		Modules_Append((void*)Modules_resMsg, 256, (CHAR*)"\" not found", 12);
		__DEL(name);
		return NIL;
	}
	__RETCHK;
}

void Modules_Free (CHAR *name, LONGINT name__len, BOOLEAN all)
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
	e = Platform_Write(1, (ADDRESS)&c, 1);
}

static void Modules_errstring (CHAR *s, LONGINT s__len)
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
	Modules_errstring((CHAR*)"Assertion failure.", 19);
	if (code != 0) {
		Modules_errstring((CHAR*)" ASSERT code ", 14);
		Modules_errint(code);
		Modules_errstring((CHAR*)".", 2);
	}
	Modules_errstring(Platform_NL, 3);
	Platform_Exit(code);
}

__TDESC(Modules_ModuleDesc, 1, 2) = {__TDFLDS("ModuleDesc", 48), {0, 28, -12}};
__TDESC(Modules_CmdDesc, 1, 1) = {__TDFLDS("CmdDesc", 32), {0, -8}};

export void *Modules__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(Heap);
	__MODULE_IMPORT(Platform);
	__REGMOD("Modules", 0);
	__INITYP(Modules_ModuleDesc, Modules_ModuleDesc, 0);
	__INITYP(Modules_CmdDesc, Modules_CmdDesc, 0);
/* BEGIN */
	__ENDMOD;
}
