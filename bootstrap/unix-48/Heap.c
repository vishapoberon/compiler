/* voc 5.4.2 [2026/11/24] for gcc LP64 on gentoo nrtsSF */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32

#include "SYSTEM.h"

struct Heap__1 {
	CHAR ch;
	SYSTEM_PTR p;
};

typedef
	struct Heap_CmdDesc *Heap_Cmd;

typedef
	CHAR Heap_CmdName[24];

typedef
	void (*Heap_Command)(void);

typedef
	struct Heap_CmdDesc {
		Heap_Cmd next;
		Heap_CmdName name;
		Heap_Command cmd;
	} Heap_CmdDesc;

typedef
	void (*Heap_EnumProc)(void(*)(SYSTEM_PTR));

typedef
	struct Heap_FinDesc *Heap_FinNode;

typedef
	void (*Heap_Finalizer)(SYSTEM_PTR);

typedef
	struct Heap_FinDesc {
		Heap_FinNode next;
		INT32 obj;
		BOOLEAN marked;
		Heap_Finalizer finalize;
	} Heap_FinDesc;

typedef
	struct Heap_ImportDesc *Heap_Import;

typedef
	struct Heap_ModuleDesc *Heap_Module;

typedef
	struct Heap_ImportDesc {
		Heap_Import next;
		Heap_Module imported;
	} Heap_ImportDesc;

typedef
	struct Heap_LifetimeDesc *Heap_Lifetime;

typedef
	struct Heap_LifetimeDesc {
		Heap_Lifetime next;
		Heap_Module owner;
		Heap_Import imports;
		INT16 state;
		INT32 retained;
		INT32 initializer;
	} Heap_LifetimeDesc;

typedef
	CHAR Heap_ModuleName[20];

typedef
	struct Heap_ModuleDesc {
		Heap_Module next;
		Heap_ModuleName name;
		INT32 refcnt;
		Heap_Cmd cmds;
		INT32 types;
		Heap_EnumProc enumPtrs;
		INT32 reserved1, reserved2;
	} Heap_ModuleDesc;

typedef
	void (*Heap_ModuleNotifier)(Heap_Module, INT32);

typedef
	struct Heap_ProcedureDesc *Heap_Procedure;

typedef
	struct Heap_ProcedureDesc {
		Heap_Procedure next;
		Heap_Module owner;
		INT32 address;
	} Heap_ProcedureDesc;

typedef
	struct Heap_RetentionDesc *Heap_Retention;

typedef
	struct Heap_RetentionDesc {
		Heap_Retention next;
		Heap_Module owner;
	} Heap_RetentionDesc;

typedef
	struct Heap_TerminationDesc *Heap_Termination;

typedef
	struct Heap_TerminationDesc {
		Heap_Termination next;
		Heap_Module owner;
		Heap_Command handler;
	} Heap_TerminationDesc;

typedef
	void (*Heap_UnloadHandler)(Heap_Module);

typedef
	struct Heap_UnloadHookDesc *Heap_UnloadHook;

typedef
	struct Heap_UnloadHookDesc {
		Heap_UnloadHook next;
		Heap_Module owner;
		Heap_UnloadHandler handler;
	} Heap_UnloadHookDesc;


export SYSTEM_PTR Heap_modules;
static INT32 Heap_freeList[10];
static INT32 Heap_bigBlocks;
export INT32 Heap_allocated;
static BOOLEAN Heap_firstTry;
static INT16 Heap_ldUnit;
export INT32 Heap_heap;
static INT32 Heap_heapMin, Heap_heapMax;
export INT32 Heap_heapsize, Heap_heapMinExpand;
static Heap_FinNode Heap_fin;
static Heap_Procedure Heap_procedures;
static Heap_Termination Heap_terminations;
static Heap_Lifetime Heap_lifetimes;
static Heap_Retention Heap_retentions;
static Heap_ModuleNotifier Heap_notifier;
static Heap_Retention Heap_notifierRetention;
static Heap_UnloadHook Heap_unloadHooks;
static INT16 Heap_lockdepth;
static BOOLEAN Heap_interrupted;
export INT16 Heap_FileCount;

export ADDRESS *Heap_ModuleDesc__typ;
export ADDRESS *Heap_ImportDesc__typ;
export ADDRESS *Heap_LifetimeDesc__typ;
export ADDRESS *Heap_RetentionDesc__typ;
export ADDRESS *Heap_UnloadHookDesc__typ;
export ADDRESS *Heap_ProcedureDesc__typ;
export ADDRESS *Heap_TerminationDesc__typ;
export ADDRESS *Heap_CmdDesc__typ;
export ADDRESS *Heap_FinDesc__typ;
export ADDRESS *Heap__1__typ;

export void Heap_BeginFree (Heap_Module owner);
static void Heap_CheckFin (void);
export INT16 Heap_CheckModule (Heap_Module owner);
static void Heap_Collect (Heap_Module excluded, BOOLEAN markStack);
export BOOLEAN Heap_CollectModule (Heap_Module owner);
export void Heap_CommitFree (Heap_Module owner);
export void Heap_DetachCallbacks (Heap_Module owner);
export void Heap_DisableModule (Heap_Module owner);
static void Heap_ExtendHeap (INT32 blksz);
export void Heap_FINALL (void);
export void Heap_FINALMOD (Heap_Module owner);
static void Heap_Finalize (void);
export BOOLEAN Heap_Finishable (Heap_Module owner);
export INT32 Heap_FreeModule (CHAR *name, ADDRESS name__len);
export void Heap_GC (BOOLEAN markStack);
export BOOLEAN Heap_HasFinalizers (Heap_Module owner);
static void Heap_HeapSort (INT32 n, INT32 *a, ADDRESS a__len);
export void Heap_INCREF (Heap_Module m);
export Heap_Module Heap_Imported (Heap_Module owner, INT16 index);
export void Heap_InitHeap (void);
export BOOLEAN Heap_InstallTermHandler (Heap_Command handler);
static Heap_Lifetime Heap_Life (Heap_Module owner, BOOLEAN create);
export BOOLEAN Heap_LiveTypes (Heap_Module owner);
export void Heap_Lock (void);
export void Heap_MODREADY (Heap_Module owner, INT32 initializer);
static void Heap_Mark (INT32 q);
static void Heap_MarkCandidates (INT32 n, INT32 *cand, ADDRESS cand__len);
static void Heap_MarkP (SYSTEM_PTR p);
static void Heap_MarkRoots (Heap_Module excluded, BOOLEAN markStack);
static void Heap_MarkStack (INT32 n, INT32 *cand, ADDRESS cand__len);
export INT16 Heap_ModuleState (Heap_Module owner);
export SYSTEM_PTR Heap_NEWBLK (INT32 size);
export SYSTEM_PTR Heap_NEWREC (INT32 tag);
static BOOLEAN Heap_NativeCallbacks (Heap_Module owner);
static INT32 Heap_NewChunk (INT32 blksz);
static BOOLEAN Heap_OwnedType (Heap_Module owner, INT32 tag);
export Heap_Module Heap_ProcedureModule (INT32 address);
export void Heap_REGCMD (Heap_Module m, CHAR *name, Heap_Command cmd);
export void Heap_REGIMPORT (Heap_Module owner, Heap_Module imported);
export SYSTEM_PTR Heap_REGMOD (CHAR *name, Heap_EnumProc enumPtrs);
export void Heap_REGPROC (Heap_Module m, INT32 address);
export void Heap_REGTYP (Heap_Module m, INT32 typ);
export void Heap_RegisterFinalizer (SYSTEM_PTR obj, Heap_Finalizer finalize);
export BOOLEAN Heap_RegisterUnloadHook (Heap_UnloadHandler handler);
export BOOLEAN Heap_ReleaseModule (Heap_Retention r);
export Heap_Retention Heap_RetainModule (Heap_Module owner);
export Heap_Retention Heap_RetainProcedure (INT32 address);
export INT32 Heap_Retained (Heap_Module owner);
static void Heap_Scan (void);
export void Heap_SetModuleNotifier (Heap_ModuleNotifier handler);
static void Heap_Sift (INT32 l, INT32 r, INT32 *a, ADDRESS a__len);
static void Heap_Terminate (Heap_Module owner);
static BOOLEAN Heap_TypeReferences (Heap_Module owner, BOOLEAN markedOnly);
export void Heap_Unlock (void);
export BOOLEAN Heap_UnregisterUnloadHook (Heap_UnloadHandler handler);

#define Heap_Active(owner)	SYSTEM_ModuleActive(owner)
#define Heap_CommandAddress(handler)	(ADDRESS)handler
#define Heap_CommandCritical(enter)	SYSTEM_CommandCritical(enter)
extern void *Heap__init();
extern ADDRESS Modules_MainStackFrame;
extern ADDRESS Platform_OSAllocate(ADDRESS size);
#define Heap_FinalizerAddress(handler)	(ADDRESS)handler
#define Heap_HeapModuleInit()	Heap__init()
#define Heap_HookAddress(handler)	(ADDRESS)handler
#define Heap_ModulesHalt(code)	Modules_Halt(code)
#define Heap_ModulesMainStackFrame()	Modules_MainStackFrame
#define Heap_NativeCallback(index)	SYSTEM_ModuleCallback(index)
#define Heap_NotifierAddress(handler)	(ADDRESS)handler
#define Heap_OSAllocate(size)	Platform_OSAllocate(size)
#define Heap_SaveRegisters()	__SAVE_REGISTERS()
#define Heap_TypeTag(link)	link + (__MAXEXT + 24/sizeof(ADDRESS) + 4)*sizeof(ADDRESS)
#define Heap_uLE(x, y)	((size_t)x <= (size_t)y)
#define Heap_uLT(x, y)	((size_t)x <  (size_t)y)

void Heap_Lock (void)
{
	Heap_CommandCritical(1);
	Heap_lockdepth += 1;
}

void Heap_Unlock (void)
{
	Heap_lockdepth -= 1;
	if ((Heap_interrupted && Heap_lockdepth == 0)) {
		Heap_ModulesHalt(-9);
	}
	Heap_CommandCritical(0);
}

SYSTEM_PTR Heap_REGMOD (CHAR *name, Heap_EnumProc enumPtrs)
{
	Heap_Module m;
	if (__STRCMP(name, "Heap") == 0) {
		__SYSNEW(m, 48);
	} else {
		__NEW(m, Heap_ModuleDesc);
	}
	((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 183, 6, 5698))->types = 0;
	((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 183, 20, 5712))->cmds = NIL;
	__COPY(name, ((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 184, 17, 5742))->name, 20);
	((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 185, 44, 5793))->refcnt = 0;
	((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 186, 6, 5816))->enumPtrs = enumPtrs;
	((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 186, 30, 5840))->next = (Heap_Module)(ADDRESS)Heap_modules;
	Heap_modules = (SYSTEM_PTR)m;
	return (void*)m;
}

INT32 Heap_FreeModule (CHAR *name, ADDRESS name__len)
{
	Heap_Module m, p;
	__DUP(name, name__len, CHAR);
	m = (Heap_Module)(ADDRESS)Heap_modules;
	while ((m != NIL && __STRCMP(((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 195, 25, 6138))->name, name) != 0)) {
		p = m;
		m = ((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 195, 56, 6169))->next;
	}
	if ((m != NIL && ((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 196, 22, 6201))->refcnt == 0)) {
		if (m == (Heap_Module)(ADDRESS)Heap_modules) {
			Heap_modules = (SYSTEM_PTR)((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 197, 54, 6272))->next;
		} else {
			((Heap_Module)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 198, 13, 6290))->next = ((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 198, 23, 6300))->next;
		}
		__DEL(name);
		return 0;
	} else {
		if (m == NIL) {
			__DEL(name);
			return -1;
		} else {
			__DEL(name);
			return ((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 202, 46, 6386))->refcnt;
		}
	}
	__RETCHK;
}

void Heap_REGCMD (Heap_Module m, CHAR *name, Heap_Command cmd)
{
	Heap_Cmd c;
	if (__STRCMP(((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 214, 9, 6822))->name, "Heap") == 0) {
		__SYSNEW(c, 32);
	} else {
		__NEW(c, Heap_CmdDesc);
	}
	__COPY(name, ((Heap_Cmd)__NIL_AT((ADDRESS)(c), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 219, 17, 6919))->name, 24);
	((Heap_Cmd)__NIL_AT((ADDRESS)(c), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 219, 26, 6928))->cmd = cmd;
	((Heap_Cmd)__NIL_AT((ADDRESS)(c), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 219, 40, 6942))->next = ((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 219, 50, 6952))->cmds;
	((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 219, 58, 6960))->cmds = c;
}

void Heap_REGTYP (Heap_Module m, INT32 typ)
{
	__PUT(typ, ((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 223, 21, 7054))->types, INT32);
	((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 223, 31, 7064))->types = typ;
}

void Heap_INCREF (Heap_Module m)
{
	((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 231, 10, 7262))->refcnt += 1;
}

static Heap_Lifetime Heap_Life (Heap_Module owner, BOOLEAN create)
{
	Heap_Lifetime l;
	l = Heap_lifetimes;
	while ((l != NIL && ((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 238, 25, 7419))->owner != owner)) {
		l = ((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 238, 50, 7444))->next;
	}
	if ((l == NIL && create)) {
		__NEW(l, Heap_LifetimeDesc);
		((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 240, 16, 7501))->owner = owner;
		((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 240, 34, 7519))->state = 1;
		((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 241, 8, 7539))->next = Heap_lifetimes;
		Heap_lifetimes = l;
	}
	return l;
}

INT16 Heap_ModuleState (Heap_Module owner)
{
	Heap_Lifetime l;
	l = Heap_Life(owner, 0);
	if (l == NIL) {
		return 0;
	} else {
		return ((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 250, 43, 7759))->state;
	}
	__RETCHK;
}

void Heap_REGIMPORT (Heap_Module owner, Heap_Module imported)
{
	Heap_Lifetime l;
	Heap_Import i;
	l = Heap_Life(owner, 1);
	__NEW(i, Heap_ImportDesc);
	((Heap_Import)__NIL_AT((ADDRESS)(i), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 257, 14, 7920))->imported = imported;
	((Heap_Import)__NIL_AT((ADDRESS)(i), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 257, 38, 7944))->next = ((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 257, 48, 7954))->imports;
	((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 257, 59, 7965))->imports = i;
}

void Heap_MODREADY (Heap_Module owner, INT32 initializer)
{
	Heap_Lifetime l;
	l = Heap_Life(owner, 1);
	((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 263, 30, 8117))->state = 2;
	((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 263, 44, 8131))->initializer = initializer;
	if (Heap_notifier != NIL) {
		((Heap_ModuleNotifier)__NIL_AT((ADDRESS)(Heap_notifier), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 264, 28, 8187))(owner, initializer);
	}
}

void Heap_SetModuleNotifier (Heap_ModuleNotifier handler)
{
	Heap_Lifetime l;
		Heap_notifier = handler;
	Heap_notifierRetention = Heap_RetainProcedure(Heap_NotifierAddress(handler));
		l = Heap_lifetimes;
	while (l != NIL) {
		if ((((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 280, 12, 8837))->state == 2 && ((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 280, 28, 8853))->initializer != 0)) {
			((Heap_ModuleNotifier)__NIL_AT((ADDRESS)(Heap_notifier), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 280, 51, 8876))(((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 280, 61, 8886))->owner, ((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 280, 70, 8895))->initializer);
		}
		l = ((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 281, 13, 8926))->next;
	}
}

Heap_Retention Heap_RetainModule (Heap_Module owner)
{
	Heap_Lifetime l;
	Heap_Retention r;
	if (owner == NIL) {
		return NIL;
	}
	l = Heap_Life(owner, 0);
	if (l == NIL || ((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 290, 23, 9153))->state != 2) {
		return NIL;
	}
	__NEW(r, Heap_RetentionDesc);
	((Heap_Retention)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 291, 14, 9199))->owner = owner;
	((Heap_Retention)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 291, 32, 9217))->next = Heap_retentions;
	Heap_retentions = r;
	((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 292, 10, 9264))->retained += 1;
	return r;
}

BOOLEAN Heap_ReleaseModule (Heap_Retention r)
{
	Heap_Retention p, previous;
	Heap_Lifetime l;
	p = Heap_retentions;
	previous = NIL;
	while ((p != NIL && p != r)) {
		previous = p;
		p = ((Heap_Retention)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 300, 55, 9506))->next;
	}
	if (p == NIL) {
		return 0;
	}
	l = Heap_Life(((Heap_Retention)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 302, 16, 9570))->owner, 0);
			((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 303, 10, 9636))->retained -= 1;
	if (previous == NIL) {
		Heap_retentions = ((Heap_Retention)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 304, 43, 9690))->next;
	} else {
		((Heap_Retention)__NIL_AT((ADDRESS)(previous), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 304, 62, 9709))->next = ((Heap_Retention)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 304, 72, 9719))->next;
	}
	((Heap_Retention)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 305, 6, 9735))->owner = NIL;
	((Heap_Retention)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 305, 22, 9751))->next = NIL;
	return 1;
}

INT32 Heap_Retained (Heap_Module owner)
{
	Heap_Lifetime l;
	l = Heap_Life(owner, 0);
	if (l == NIL) {
		return 0;
	} else {
		return ((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 313, 43, 9950))->retained;
	}
	__RETCHK;
}

Heap_Module Heap_Imported (Heap_Module owner, INT16 index)
{
	Heap_Lifetime l;
	Heap_Import i;
	l = Heap_Life(owner, 0);
	if (l == NIL) {
		return NIL;
	}
	i = ((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 321, 11, 10158))->imports;
	while ((i != NIL && index > 0)) {
		i = ((Heap_Import)__NIL_AT((ADDRESS)(i), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 322, 44, 10211))->next;
		index -= 1;
	}
	if (i == NIL) {
		return NIL;
	} else {
		return ((Heap_Import)__NIL_AT((ADDRESS)(i), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 323, 45, 10278))->imported;
	}
	__RETCHK;
}

void Heap_REGPROC (Heap_Module m, INT32 address)
{
	Heap_Procedure p;
	__NEW(p, Heap_ProcedureDesc);
	((Heap_Procedure)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 331, 14, 10559))->owner = m;
	((Heap_Procedure)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 331, 28, 10573))->address = address;
	((Heap_Procedure)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 332, 6, 10599))->next = Heap_procedures;
	Heap_procedures = p;
}

Heap_Module Heap_ProcedureModule (INT32 address)
{
	Heap_Procedure p;
	p = Heap_procedures;
	while ((p != NIL && ((Heap_Procedure)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 339, 25, 10785))->address != address)) {
		p = ((Heap_Procedure)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 339, 54, 10814))->next;
	}
	if (p == NIL) {
		return NIL;
	} else {
		return ((Heap_Procedure)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 340, 45, 10869))->owner;
	}
	__RETCHK;
}

Heap_Retention Heap_RetainProcedure (INT32 address)
{
	Heap_Module owner;
	Heap_Lifetime l;
	Heap_Retention r;
	owner = Heap_ProcedureModule(address);
	if (owner == NIL) {
		return NIL;
	}
	l = Heap_Life(owner, 1);
	if (((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 351, 9, 11297))->state > 2) {
		return NIL;
	}
	__NEW(r, Heap_RetentionDesc);
	((Heap_Retention)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 352, 14, 11342))->owner = owner;
	((Heap_Retention)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 352, 32, 11360))->next = Heap_retentions;
	Heap_retentions = r;
	((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 353, 10, 11407))->retained += 1;
	return r;
}

BOOLEAN Heap_RegisterUnloadHook (Heap_UnloadHandler handler)
{
	Heap_UnloadHook h;
	Heap_Module owner;
	Heap_Lifetime l;
	if (handler == NIL) {
		return 0;
	}
	h = Heap_unloadHooks;
	while ((h != NIL && ((Heap_UnloadHook)__NIL_AT((ADDRESS)(h), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 366, 25, 11910))->handler != handler)) {
		h = ((Heap_UnloadHook)__NIL_AT((ADDRESS)(h), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 366, 54, 11939))->next;
	}
	if (h != NIL) {
		return 1;
	}
	owner = Heap_ProcedureModule(Heap_HookAddress(handler));
	if (owner == NIL) {
		return 0;
	}
	l = Heap_Life(owner, 1);
	if (((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 371, 9, 12117))->state > 2) {
		return 0;
	}
	__NEW(h, Heap_UnloadHookDesc);
	((Heap_UnloadHook)__NIL_AT((ADDRESS)(h), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 372, 14, 12164))->owner = owner;
	((Heap_UnloadHook)__NIL_AT((ADDRESS)(h), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 372, 32, 12182))->handler = handler;
	((Heap_UnloadHook)__NIL_AT((ADDRESS)(h), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 373, 6, 12208))->next = Heap_unloadHooks;
	Heap_unloadHooks = h;
	((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 373, 51, 12253))->retained += 1;
	return 1;
}

BOOLEAN Heap_UnregisterUnloadHook (Heap_UnloadHandler handler)
{
	Heap_UnloadHook h, previous;
	Heap_Lifetime l;
	h = Heap_unloadHooks;
	previous = NIL;
	while ((h != NIL && ((Heap_UnloadHook)__NIL_AT((ADDRESS)(h), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 381, 25, 12493))->handler != handler)) {
		previous = h;
		h = ((Heap_UnloadHook)__NIL_AT((ADDRESS)(h), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 381, 69, 12537))->next;
	}
	if (h == NIL) {
		return 0;
	}
	l = Heap_Life(((Heap_UnloadHook)__NIL_AT((ADDRESS)(h), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 383, 16, 12601))->owner, 0);
	((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 383, 37, 12622))->retained -= 1;
	if (previous == NIL) {
		Heap_unloadHooks = ((Heap_UnloadHook)__NIL_AT((ADDRESS)(h), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 384, 44, 12677))->next;
	} else {
		((Heap_UnloadHook)__NIL_AT((ADDRESS)(previous), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 384, 63, 12696))->next = ((Heap_UnloadHook)__NIL_AT((ADDRESS)(h), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 384, 73, 12706))->next;
	}
	return 1;
}

void Heap_DetachCallbacks (Heap_Module owner)
{
	Heap_UnloadHook h;
	h = Heap_unloadHooks;
	while (h != NIL) {
		((Heap_UnloadHandler)__NIL_AT((ADDRESS)(((Heap_UnloadHook)__NIL_AT((ADDRESS)(h), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 392, 23, 12882))->handler), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 392, 23, 12882))(owner);
		h = ((Heap_UnloadHook)__NIL_AT((ADDRESS)(h), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 392, 46, 12905))->next;
	}
}

static BOOLEAN Heap_NativeCallbacks (Heap_Module owner)
{
	INT16 i;
	INT32 address;
	i = 0;
	while (i < 10) {
		address = Heap_NativeCallback(i);
		if ((address != 0 && Heap_ProcedureModule(address) == owner)) {
			return 1;
		}
		i += 1;
	}
	return 0;
}

INT16 Heap_CheckModule (Heap_Module owner)
{
	Heap_Lifetime l;
	l = Heap_Life(owner, 0);
	if (l == NIL) {
		return 1;
	}
	if (((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 415, 9, 13607))->state != 2) {
		return 2;
	}
	if (((Heap_Module)__NIL_AT((ADDRESS)(owner), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 416, 13, 13649))->refcnt != 1) {
		return 3;
	}
	if (Heap_Active(owner)) {
		return 4;
	}
	if (((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 418, 10, 13729))->retained != 0 || Heap_NativeCallbacks(owner)) {
		return 5;
	}
	if (Heap_lockdepth != 0) {
		return 6;
	}
	return 0;
}

void Heap_BeginFree (Heap_Module owner)
{
	Heap_Lifetime l;
	l = Heap_Life(owner, 0);
		((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 425, 52, 13973))->state = 3;
}

BOOLEAN Heap_Finishable (Heap_Module owner)
{
	Heap_Lifetime l;
	l = Heap_Life(owner, 0);
	return (((((((((l != NIL && ((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 432, 26, 14135))->state == 3)) && ((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 432, 42, 14151))->retained == 0)) && ((Heap_Module)__NIL_AT((ADDRESS)(owner), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 432, 65, 14174))->refcnt == 1)) && !Heap_Active(owner))) && !Heap_NativeCallbacks(owner));
}

BOOLEAN Heap_HasFinalizers (Heap_Module owner)
{
	Heap_FinNode f;
	f = Heap_fin;
	while (f != NIL) {
		if (Heap_ProcedureModule(Heap_FinalizerAddress(((Heap_FinNode)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 441, 44, 14413))->finalize)) == owner) {
			return 1;
		}
		f = ((Heap_FinNode)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 442, 13, 14467))->next;
	}
	return 0;
}

void Heap_DisableModule (Heap_Module owner)
{
	Heap_Lifetime l;
	l = Heap_Life(owner, 0);
		((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 450, 48, 14640))->state = 4;
	((Heap_Module)__NIL_AT((ADDRESS)(owner), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 451, 10, 14662))->cmds = NIL;
	((Heap_Module)__NIL_AT((ADDRESS)(owner), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 451, 29, 14681))->enumPtrs = NIL;
}

void Heap_CommitFree (Heap_Module owner)
{
	Heap_Module m, previous;
	Heap_Lifetime l, lp;
	Heap_Import i;
	Heap_Procedure p, pp, pn;
	Heap_Termination t, tp;
	l = Heap_lifetimes;
	lp = NIL;
	while ((l != NIL && ((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 459, 25, 14928))->owner != owner)) {
		lp = l;
		l = ((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 459, 59, 14962))->next;
	}
			i = ((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 461, 11, 15028))->imports;
	while (i != NIL) {
				((Heap_Module)__NIL_AT((ADDRESS)(((Heap_Import)__NIL_AT((ADDRESS)(i), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 462, 58, 15095))->imported), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 462, 67, 15104))->refcnt -= 1;
		i = ((Heap_Import)__NIL_AT((ADDRESS)(i), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 462, 83, 15120))->next;
	}
	if (lp == NIL) {
		Heap_lifetimes = ((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 463, 36, 15166))->next;
	} else {
		((Heap_Lifetime)__NIL_AT((ADDRESS)(lp), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 463, 49, 15179))->next = ((Heap_Lifetime)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 463, 59, 15189))->next;
	}
	p = Heap_procedures;
	pp = NIL;
	while (p != NIL) {
		pn = ((Heap_Procedure)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 466, 14, 15266))->next;
		if (((Heap_Procedure)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 467, 11, 15283))->owner == owner) {
			if (pp == NIL) {
				Heap_procedures = pn;
			} else {
				((Heap_Procedure)__NIL_AT((ADDRESS)(pp), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 468, 50, 15352))->next = pn;
			}
		} else {
			pp = p;
		}
		p = pn;
	}
	t = Heap_terminations;
	tp = NIL;
	while ((t != NIL && ((Heap_Termination)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 473, 25, 15473))->owner != owner)) {
		tp = t;
		t = ((Heap_Termination)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 473, 59, 15507))->next;
	}
	if (t != NIL) {
		if (tp == NIL) {
			Heap_terminations = ((Heap_Termination)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 475, 41, 15578))->next;
		} else {
			((Heap_Termination)__NIL_AT((ADDRESS)(tp), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 475, 54, 15591))->next = ((Heap_Termination)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 475, 64, 15601))->next;
		}
	}
	m = (Heap_Module)(ADDRESS)Heap_modules;
	previous = NIL;
	while ((m != NIL && m != owner)) {
		previous = m;
		m = ((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 478, 59, 15728))->next;
	}
		if (previous == NIL) {
		Heap_modules = (SYSTEM_PTR)((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 480, 40, 15799))->next;
	} else {
		((Heap_Module)__NIL_AT((ADDRESS)(previous), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 480, 59, 15818))->next = ((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 480, 69, 15828))->next;
	}
	((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 481, 6, 15844))->cmds = NIL;
	((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 481, 21, 15859))->enumPtrs = NIL;
	((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 481, 40, 15878))->types = 0;
	((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 481, 54, 15892))->next = NIL;
	((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 481, 69, 15907))->refcnt = 0;
}

BOOLEAN Heap_InstallTermHandler (Heap_Command handler)
{
	Heap_Module owner;
	Heap_Termination t;
	if (handler == NIL) {
		return 0;
	}
	owner = Heap_ProcedureModule(Heap_CommandAddress(handler));
	if (owner == NIL) {
		return 0;
	}
	if (Heap_ModuleState(owner) > 2) {
		return 0;
	}
	t = Heap_terminations;
	while ((t != NIL && ((Heap_Termination)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 492, 25, 16287))->owner != owner)) {
		t = ((Heap_Termination)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 492, 50, 16312))->next;
	}
	if (t == NIL) {
		__NEW(t, Heap_TerminationDesc);
		((Heap_Termination)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 494, 16, 16358))->owner = owner;
		((Heap_Termination)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 494, 34, 16376))->next = Heap_terminations;
		Heap_terminations = t;
	}
	((Heap_Termination)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 496, 6, 16431))->handler = handler;
	return 1;
}

static void Heap_Terminate (Heap_Module owner)
{
	Heap_Termination t;
	Heap_Command handler;
	t = Heap_terminations;
	while ((t != NIL && ((Heap_Termination)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 504, 25, 16630))->owner != owner)) {
		t = ((Heap_Termination)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 504, 50, 16655))->next;
	}
	if ((t != NIL && ((Heap_Termination)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 505, 22, 16687))->handler != NIL)) {
		handler = ((Heap_Termination)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 506, 19, 16726))->handler;
		((Heap_Termination)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 506, 30, 16737))->handler = NIL;
		((Heap_Command)__NIL_AT((ADDRESS)(handler), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 507, 7, 16818))();
	}
}

static INT32 Heap_NewChunk (INT32 blksz)
{
	INT32 chnk, blk, end;
	chnk = Heap_OSAllocate(blksz + 12);
	if (chnk != 0) {
		blk = chnk + 12;
		end = blk + blksz;
		__PUT(chnk + 4, end, INT32);
		__PUT(blk, blk + 4, INT32);
		__PUT(blk + 4, blksz, INT32);
		__PUT(blk + 8, -4, INT32);
		__PUT(blk + 12, Heap_bigBlocks, INT32);
		Heap_bigBlocks = blk;
		Heap_heapsize += blksz;
		if (Heap_uLT(blk + 4, Heap_heapMin)) {
			Heap_heapMin = blk + 4;
		}
		if (Heap_uLT(Heap_heapMax, end)) {
			Heap_heapMax = end;
		}
	}
	return chnk;
}

static void Heap_ExtendHeap (INT32 blksz)
{
	INT32 size, chnk, j, next;
		if (Heap_uLT(Heap_heapMinExpand, blksz)) {
		size = blksz;
	} else {
		size = Heap_heapMinExpand;
	}
	chnk = Heap_NewChunk(size);
	if (chnk != 0) {
		if (Heap_uLT(chnk, Heap_heap)) {
			__PUT(chnk, Heap_heap, INT32);
			Heap_heap = chnk;
		} else {
			j = Heap_heap;
			__GET(j, next, INT32);
			while ((next != 0 && Heap_uLT(next, chnk))) {
				j = next;
				__GET(j, next, INT32);
			}
			__PUT(chnk, next, INT32);
			__PUT(j, chnk, INT32);
		}
	} else if (!Heap_firstTry) {
		Heap_heapMinExpand = 16;
	}
}

SYSTEM_PTR Heap_NEWREC (INT32 tag)
{
	INT32 i, i0, di, blksz, restsize, t, adr, end, next, prev;
	SYSTEM_PTR new;
	Heap_Lock();
	__GET(tag, blksz, INT32);
		i0 = __LSH(blksz, -Heap_ldUnit, 32);
	i = i0;
	if (i < 9) {
		adr = Heap_freeList[i];
		while (adr == 0) {
			i += 1;
			adr = Heap_freeList[i];
		}
	}
	if (i < 9) {
		__GET(adr + 12, next, INT32);
		Heap_freeList[i] = next;
		if (i != i0) {
			di = i - i0;
			restsize = __ASHL(di, 4);
			end = adr + restsize;
			__PUT(end + 4, blksz, INT32);
			__PUT(end + 8, -4, INT32);
			__PUT(end, end + 4, INT32);
			__PUT(adr + 4, restsize, INT32);
			__PUT(adr + 12, Heap_freeList[di], INT32);
			Heap_freeList[di] = adr;
			adr += restsize;
		}
	} else {
		adr = Heap_bigBlocks;
		prev = 0;
		for (;;) {
			if (adr == 0) {
				if (Heap_firstTry) {
					Heap_GC(1);
					blksz += 16;
					t = __LSH(Heap_allocated + blksz, -(2 + Heap_ldUnit), 32) * 80;
					if (Heap_uLT(Heap_heapsize, t)) {
						Heap_ExtendHeap(t - Heap_heapsize);
					}
					Heap_firstTry = 0;
					new = Heap_NEWREC(tag);
					if (new == NIL) {
						Heap_ExtendHeap(blksz);
						new = Heap_NEWREC(tag);
					}
					Heap_firstTry = 1;
					Heap_Unlock();
					return new;
				} else {
					Heap_Unlock();
					return NIL;
				}
			}
			__GET(adr + 4, t, INT32);
			if (Heap_uLE(blksz, t)) {
				break;
			}
			prev = adr;
			__GET(adr + 12, adr, INT32);
		}
		restsize = t - blksz;
		end = adr + restsize;
		__PUT(end + 4, blksz, INT32);
		__PUT(end + 8, -4, INT32);
		__PUT(end, end + 4, INT32);
		if (Heap_uLT(144, restsize)) {
			__PUT(adr + 4, restsize, INT32);
		} else {
			__GET(adr + 12, next, INT32);
			if (prev == 0) {
				Heap_bigBlocks = next;
			} else {
				__PUT(prev + 12, next, INT32);
			}
			if (restsize != 0) {
				di = __ASHR(restsize, 4);
				__PUT(adr + 4, restsize, INT32);
				__PUT(adr + 12, Heap_freeList[di], INT32);
				Heap_freeList[di] = adr;
			}
		}
		adr += restsize;
	}
	i = adr + 16;
	end = adr + blksz;
	while (Heap_uLT(i, end)) {
		__PUT(i, 0, INT32);
		__PUT(i + 4, 0, INT32);
		__PUT(i + 8, 0, INT32);
		__PUT(i + 12, 0, INT32);
		i += 16;
	}
	__PUT(adr + 12, 0, INT32);
	__PUT(adr, tag, INT32);
	__PUT(adr + 4, 0, INT32);
	__PUT(adr + 8, 0, INT32);
	Heap_allocated += blksz;
	Heap_Unlock();
	return (SYSTEM_PTR)(ADDRESS)(adr + 4);
}

SYSTEM_PTR Heap_NEWBLK (INT32 size)
{
	INT32 blksz, tag;
	SYSTEM_PTR new;
	Heap_Lock();
	blksz = __ASHL(__ASHR(size + 31, 4), 4);
	new = Heap_NEWREC((ADDRESS)&blksz);
	tag = ((INT32)(ADDRESS)new + blksz) - 12;
	__PUT(tag - 4, 0, INT32);
	__PUT(tag, blksz, INT32);
	__PUT(tag + 4, -4, INT32);
	__PUT((INT32)(ADDRESS)new - 4, tag, INT32);
	Heap_Unlock();
	return new;
}

static void Heap_Mark (INT32 q)
{
	INT32 p, tag, offset, fld, n, tagbits;
	if (q != 0) {
		__GET(q - 4, tagbits, INT32);
		if (!__ODD(tagbits)) {
			__PUT(q - 4, tagbits + 1, INT32);
			p = 0;
			tag = tagbits + 4;
			for (;;) {
				__GET(tag, offset, INT32);
				if (offset < 0) {
					__PUT(q - 4, (tag + offset) + 1, INT32);
					if (p == 0) {
						break;
					}
					n = q;
					q = p;
					__GET(q - 4, tag, INT32);
					tag -= 1;
					__GET(tag, offset, INT32);
					fld = q + offset;
					__GET(fld, p, INT32);
					__PUT(fld, (SYSTEM_PTR)(ADDRESS)n, SYSTEM_PTR);
				} else {
					fld = q + offset;
					__GET(fld, n, INT32);
					if (n != 0) {
						__GET(n - 4, tagbits, INT32);
						if (!__ODD(tagbits)) {
							__PUT(n - 4, tagbits + 1, INT32);
							__PUT(q - 4, tag + 1, INT32);
							__PUT(fld, (SYSTEM_PTR)(ADDRESS)p, SYSTEM_PTR);
							p = q;
							q = n;
							tag = tagbits;
						}
					}
				}
				tag += 4;
			}
		}
	}
}

static void Heap_MarkP (SYSTEM_PTR p)
{
	Heap_Mark((INT32)(ADDRESS)p);
}

static void Heap_Scan (void)
{
	INT32 chnk, adr, end, start, tag, i, size, freesize;
	Heap_bigBlocks = 0;
	i = 1;
	while (i < 9) {
		Heap_freeList[i] = 0;
		i += 1;
	}
	freesize = 0;
	Heap_allocated = 0;
	chnk = Heap_heap;
	while (chnk != 0) {
		adr = chnk + 12;
		__GET(chnk + 4, end, INT32);
		while (Heap_uLT(adr, end)) {
			__GET(adr, tag, INT32);
			if (__ODD(tag)) {
				if (freesize != 0) {
					start = adr - freesize;
					__PUT(start, start + 4, INT32);
					__PUT(start + 4, freesize, INT32);
					__PUT(start + 8, -4, INT32);
					i = __LSH(freesize, -Heap_ldUnit, 32);
					freesize = 0;
					if (Heap_uLT(i, 9)) {
						__PUT(start + 12, Heap_freeList[i], INT32);
						Heap_freeList[i] = start;
					} else {
						__PUT(start + 12, Heap_bigBlocks, INT32);
						Heap_bigBlocks = start;
					}
				}
				tag -= 1;
				__PUT(adr, tag, INT32);
				__GET(tag, size, INT32);
				Heap_allocated += size;
				adr += size;
			} else {
				__GET(tag, size, INT32);
				freesize += size;
				adr += size;
			}
		}
		if (freesize != 0) {
			start = adr - freesize;
			__PUT(start, start + 4, INT32);
			__PUT(start + 4, freesize, INT32);
			__PUT(start + 8, -4, INT32);
			i = __LSH(freesize, -Heap_ldUnit, 32);
			freesize = 0;
			if (Heap_uLT(i, 9)) {
				__PUT(start + 12, Heap_freeList[i], INT32);
				Heap_freeList[i] = start;
			} else {
				__PUT(start + 12, Heap_bigBlocks, INT32);
				Heap_bigBlocks = start;
			}
		}
		__GET(chnk, chnk, INT32);
	}
}

static void Heap_Sift (INT32 l, INT32 r, INT32 *a, ADDRESS a__len)
{
	INT32 i, j;
	INT32 x;
	j = l;
	x = a[j];
	for (;;) {
		i = j;
		j = __ASHL(j, 1) + 1;
		if ((j < r && Heap_uLT(a[j], a[j + 1]))) {
			j += 1;
		}
		if (j > r || Heap_uLE(a[j], x)) {
			break;
		}
		a[i] = a[j];
	}
	a[i] = x;
}

static void Heap_HeapSort (INT32 n, INT32 *a, ADDRESS a__len)
{
	INT32 l, r;
	INT32 x;
	l = __ASHR(n, 1);
	r = n - 1;
	while (l > 0) {
		l -= 1;
		Heap_Sift(l, r, (void*)a, a__len);
	}
	while (r > 0) {
		x = a[0];
		a[0] = a[r];
		a[r] = x;
		r -= 1;
		Heap_Sift(l, r, (void*)a, a__len);
	}
}

static void Heap_MarkCandidates (INT32 n, INT32 *cand, ADDRESS cand__len)
{
	INT32 chnk, end, adr, tag, next, i, ptr, size;
		chnk = Heap_heap;
	i = 0;
	while (chnk != 0) {
		__GET(chnk + 4, end, INT32);
		adr = chnk + 12;
		while (Heap_uLT(adr, end)) {
			__GET(adr, tag, INT32);
			if (__ODD(tag)) {
				__GET(tag - 1, size, INT32);
				adr += size;
				ptr = adr + 4;
				while (Heap_uLT(cand[i], ptr)) {
					i += 1;
					if (i == n) {
						return;
					}
				}
			} else {
				__GET(tag, size, INT32);
				ptr = adr + 4;
				adr += size;
				while (Heap_uLT(cand[i], ptr)) {
					i += 1;
					if (i == n) {
						return;
					}
				}
				if (Heap_uLT(cand[i], adr)) {
					Heap_Mark(ptr);
				}
			}
			if (Heap_uLE(end, cand[i])) {
				adr = end;
			}
		}
		__GET(chnk, chnk, INT32);
	}
}

static void Heap_CheckFin (void)
{
	Heap_FinNode n;
	INT32 tag;
	n = Heap_fin;
	while (n != NIL) {
		__GET(((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 812, 14, 27780))->obj - 4, tag, INT32);
		if (!__ODD(tag)) {
			((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 813, 26, 27823))->marked = 0;
			Heap_Mark(((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 813, 50, 27847))->obj);
		} else {
			((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 814, 13, 27865))->marked = 1;
		}
		n = ((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 816, 13, 27904))->next;
	}
}

static void Heap_Finalize (void)
{
	Heap_FinNode n, prev;
	n = Heap_fin;
	prev = NIL;
	while (n != NIL) {
		if (!((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 824, 12, 28046))->marked) {
			if (n == Heap_fin) {
				Heap_fin = ((Heap_FinNode)__NIL_AT((ADDRESS)(Heap_fin), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 825, 35, 28093))->next;
			} else {
				((Heap_FinNode)__NIL_AT((ADDRESS)(prev), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 825, 50, 28108))->next = ((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 825, 60, 28118))->next;
			}
			((Heap_Finalizer)__NIL_AT((ADDRESS)(((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 826, 10, 28138))->finalize), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 826, 10, 28138))((SYSTEM_PTR)(ADDRESS)((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 826, 34, 28162))->obj);
			if (prev == NIL) {
				n = Heap_fin;
			} else {
				n = ((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 828, 48, 28288))->next;
			}
		} else {
			prev = n;
			n = ((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 830, 26, 28334))->next;
		}
	}
}

void Heap_FINALL (void)
{
	Heap_FinNode n;
	Heap_Module m;
	Heap_Lock();
	while (Heap_fin != NIL) {
		n = Heap_fin;
		Heap_fin = ((Heap_FinNode)__NIL_AT((ADDRESS)(Heap_fin), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 840, 27, 28494))->next;
		((Heap_Finalizer)__NIL_AT((ADDRESS)(((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 841, 8, 28508))->finalize), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 841, 8, 28508))((SYSTEM_PTR)(ADDRESS)((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 841, 32, 28532))->obj);
	}
	m = (Heap_Module)(ADDRESS)Heap_modules;
	while (m != NIL) {
		Heap_Terminate(m);
		m = ((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 845, 42, 28701))->next;
	}
	Heap_Unlock();
}

void Heap_FINALMOD (Heap_Module owner)
{
	Heap_FinNode n, previous, next;
	if (owner == NIL) {
		return;
	}
	Heap_Lock();
	n = Heap_fin;
	previous = NIL;
	while (n != NIL) {
		next = ((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 857, 16, 29015))->next;
		if (Heap_ProcedureModule(Heap_FinalizerAddress(((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 858, 44, 29065))->finalize)) == owner) {
			if (previous == NIL) {
				Heap_fin = next;
			} else {
				((Heap_FinNode)__NIL_AT((ADDRESS)(previous), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 859, 57, 29146))->next = next;
			}
			((Heap_Finalizer)__NIL_AT((ADDRESS)(((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 860, 10, 29174))->finalize), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 860, 10, 29174))((SYSTEM_PTR)(ADDRESS)((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 860, 34, 29198))->obj);
			n = Heap_fin;
			previous = NIL;
		} else {
			previous = n;
			n = next;
		}
	}
	Heap_Terminate(owner);
	Heap_Unlock();
}

static void Heap_MarkStack (INT32 n, INT32 *cand, ADDRESS cand__len)
{
	SYSTEM_PTR frame;
	INT32 nofcand;
	INT32 inc, sp, p, stack0;
	struct Heap__1 align;
	if (n > 0) {
		Heap_MarkStack(n - 1, cand, cand__len);
		if (n > 100) {
			return;
		}
	}
	if (n == 0) {
		nofcand = 0;
		sp = (ADDRESS)&frame;
		stack0 = Heap_ModulesMainStackFrame();
		inc = (ADDRESS)&align.p - (ADDRESS)&align;
		if (Heap_uLT(stack0, sp)) {
			inc = -inc;
		}
		while (sp != stack0) {
			__GET(sp, p, INT32);
			if ((Heap_uLE(Heap_heapMin, p) && Heap_uLT(p, Heap_heapMax))) {
				if (nofcand == cand__len) {
					Heap_HeapSort(nofcand, (void*)cand, cand__len);
					Heap_MarkCandidates(nofcand, (void*)cand, cand__len);
					nofcand = 0;
				}
				cand[nofcand] = p;
				nofcand += 1;
			}
			sp += inc;
		}
		if (nofcand > 0) {
			Heap_HeapSort(nofcand, (void*)cand, cand__len);
			Heap_MarkCandidates(nofcand, (void*)cand, cand__len);
		}
	}
}

static void Heap_MarkRoots (Heap_Module excluded, BOOLEAN markStack)
{
	Heap_Module m;
	INT32 i0, i1, i2, i3, i4, i5, i6, i7, i8, i9, i10, i11, i12, i13, i14, i15, i16, i17, i18, i19, i20, i21, i22, i23;
	INT32 cand[10000];
	m = (Heap_Module)(ADDRESS)Heap_modules;
	while (m != NIL) {
		if ((m != excluded && ((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 915, 29, 31090))->enumPtrs != NIL)) {
			((Heap_EnumProc)__NIL_AT((ADDRESS)(((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 915, 52, 31113))->enumPtrs), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 915, 52, 31113))(Heap_MarkP);
		}
		m = ((Heap_Module)__NIL_AT((ADDRESS)(m), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 916, 13, 31147))->next;
	}
	if (markStack) {
		Heap_SaveRegisters();
		i0 = -100;
		i1 = -101;
		i2 = -102;
		i3 = -103;
		i4 = -104;
		i5 = -105;
		i6 = -106;
		i7 = -107;
		i8 = 1;
		i9 = 2;
		i10 = 3;
		i11 = 4;
		i12 = 5;
		i13 = 6;
		i14 = 7;
		i15 = 8;
		i16 = 9;
		i17 = 10;
		i18 = 11;
		i19 = 12;
		i20 = 13;
		i21 = 14;
		i22 = 15;
		i23 = 16;
		for (;;) {
			i0 += 1;
			i1 += 2;
			i2 += 3;
			i3 += 4;
			i4 += 5;
			i5 += 6;
			i6 += 7;
			i7 += 8;
			i8 += 9;
			i9 += 10;
			i10 += 11;
			i11 += 12;
			i12 += 13;
			i13 += 14;
			i14 += 15;
			i15 += 16;
			i16 += 17;
			i17 += 18;
			i18 += 19;
			i19 += 20;
			i20 += 21;
			i21 += 22;
			i22 += 23;
			i23 += 24;
			if ((i0 == -99 && i15 == 24)) {
				Heap_MarkStack(32, (void*)cand, 10000);
				break;
			}
		}
		if (((((((((((((((((((((((i0 + i1) + i2) + i3) + i4) + i5) + i6) + i7) + i8) + i9) + i10) + i11) + i12) + i13) + i14) + i15) + i16) + i17) + i18) + i19) + i20) + i21) + i22) + i23 > 10000) {
			return;
		}
	}
}

static BOOLEAN Heap_OwnedType (Heap_Module owner, INT32 tag)
{
	INT32 t;
	t = ((Heap_Module)__NIL_AT((ADDRESS)(owner), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 948, 15, 32706))->types;
	while (t != 0) {
		if (Heap_TypeTag(t) == tag) {
			return 1;
		}
		__GET(t, t, INT32);
	}
	return 0;
}

static BOOLEAN Heap_TypeReferences (Heap_Module owner, BOOLEAN markedOnly)
{
	INT32 chnk, adr, end, tag, size;
	BOOLEAN found;
	chnk = Heap_heap;
	found = 0;
	while (chnk != 0) {
		adr = chnk + 12;
		__GET(chnk + 4, end, INT32);
		while (Heap_uLT(adr, end)) {
			__GET(adr, tag, INT32);
			if (__ODD(tag)) {
				tag -= 1;
				__PUT(adr, tag, INT32);
				if (Heap_OwnedType(owner, tag)) {
					found = 1;
				}
			} else if (!markedOnly) {
				if (Heap_OwnedType(owner, tag)) {
					found = 1;
				}
			}
			__GET(tag, size, INT32);
			adr += size;
		}
		__GET(chnk, chnk, INT32);
	}
	return found;
}

BOOLEAN Heap_LiveTypes (Heap_Module owner)
{
	Heap_FinNode n;
	BOOLEAN found;
	Heap_Lock();
	Heap_MarkRoots(owner, 1);
	n = Heap_fin;
	while (n != NIL) {
		if (Heap_ProcedureModule(Heap_FinalizerAddress(((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 987, 44, 33946))->finalize)) != owner) {
			Heap_Mark(((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 987, 75, 33977))->obj);
		}
		n = ((Heap_FinNode)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 988, 13, 34000))->next;
	}
	found = Heap_TypeReferences(owner, 1);
	Heap_Unlock();
	return found;
}

static void Heap_Collect (Heap_Module excluded, BOOLEAN markStack)
{
	Heap_Lock();
	Heap_MarkRoots(excluded, markStack);
	Heap_CheckFin();
	Heap_Scan();
	Heap_Finalize();
	Heap_Unlock();
}

void Heap_GC (BOOLEAN markStack)
{
	Heap_Collect(NIL, markStack);
}

BOOLEAN Heap_CollectModule (Heap_Module owner)
{
	BOOLEAN found;
	Heap_Collect(owner, 1);
	Heap_Lock();
	found = Heap_TypeReferences(owner, 0);
	Heap_Unlock();
	return !found;
}

void Heap_RegisterFinalizer (SYSTEM_PTR obj, Heap_Finalizer finalize)
{
	Heap_FinNode f;
	__NEW(f, Heap_FinDesc);
	((Heap_FinNode)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 1018, 6, 34671))->obj = (INT32)(ADDRESS)obj;
	((Heap_FinNode)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 1018, 38, 34703))->finalize = finalize;
	((Heap_FinNode)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 1018, 62, 34727))->marked = 1;
	((Heap_FinNode)__NIL_AT((ADDRESS)(f), (CHAR*)"../../src/runtime/Heap.Mod", 27, (CHAR*)"Heap", 5, 1019, 6, 34749))->next = Heap_fin;
	Heap_fin = f;
}

void Heap_InitHeap (void)
{
	Heap_heap = 0;
	Heap_heapsize = 0;
	Heap_allocated = 0;
	Heap_lockdepth = 0;
	Heap_heapMin = -1;
	Heap_heapMax = 0;
	Heap_bigBlocks = 0;
	Heap_heapMinExpand = 128000;
	Heap_ldUnit = 4;
	Heap_heap = Heap_NewChunk(128000);
	__PUT(Heap_heap, 0, INT32);
	Heap_firstTry = 1;
	Heap_freeList[9] = 1;
	Heap_FileCount = 0;
	Heap_modules = NIL;
	Heap_fin = NIL;
	Heap_procedures = NIL;
	Heap_terminations = NIL;
	Heap_lifetimes = NIL;
	Heap_retentions = NIL;
	Heap_notifier = NIL;
	Heap_notifierRetention = NIL;
	Heap_unloadHooks = NIL;
	Heap_interrupted = 0;
	Heap_HeapModuleInit();
}

static void EnumPtrs(void (*P)(void*))
{
	P(Heap_modules);
	P(Heap_fin);
	P(Heap_procedures);
	P(Heap_terminations);
	P(Heap_lifetimes);
	P(Heap_retentions);
	P(Heap_notifierRetention);
	P(Heap_unloadHooks);
}

__TDESC(Heap_ModuleDesc, 1, 2) = {__TDFLDS("ModuleDesc", 48), {0, 28, -12}};
__TDESC(Heap_ImportDesc, 1, 2) = {__TDFLDS("ImportDesc", 8), {0, 4, -12}};
__TDESC(Heap_LifetimeDesc, 1, 3) = {__TDFLDS("LifetimeDesc", 24), {0, 4, 8, -16}};
__TDESC(Heap_RetentionDesc, 1, 2) = {__TDFLDS("RetentionDesc", 8), {0, 4, -12}};
__TDESC(Heap_UnloadHookDesc, 1, 2) = {__TDFLDS("UnloadHookDesc", 12), {0, 4, -12}};
__TDESC(Heap_ProcedureDesc, 1, 2) = {__TDFLDS("ProcedureDesc", 12), {0, 4, -12}};
__TDESC(Heap_TerminationDesc, 1, 2) = {__TDFLDS("TerminationDesc", 12), {0, 4, -12}};
__TDESC(Heap_CmdDesc, 1, 1) = {__TDFLDS("CmdDesc", 32), {0, -8}};
__TDESC(Heap_FinDesc, 1, 1) = {__TDFLDS("FinDesc", 16), {0, -8}};
__TDESC(Heap__1, 1, 1) = {__TDFLDS("", 8), {4, -8}};

export void *Heap__init(void)
{
	__DEFMOD;
	__REGMOD("Heap", EnumPtrs);
	__REGCMD("FINALL", Heap_FINALL);
	__REGCMD("InitHeap", Heap_InitHeap);
	__REGCMD("Lock", Heap_Lock);
	__REGCMD("Unlock", Heap_Unlock);
	__INITYP(Heap_ModuleDesc, Heap_ModuleDesc, 0);
	__INITYP(Heap_ImportDesc, Heap_ImportDesc, 0);
	__INITYP(Heap_LifetimeDesc, Heap_LifetimeDesc, 0);
	__INITYP(Heap_RetentionDesc, Heap_RetentionDesc, 0);
	__INITYP(Heap_UnloadHookDesc, Heap_UnloadHookDesc, 0);
	__INITYP(Heap_ProcedureDesc, Heap_ProcedureDesc, 0);
	__INITYP(Heap_TerminationDesc, Heap_TerminationDesc, 0);
	__INITYP(Heap_CmdDesc, Heap_CmdDesc, 0);
	__INITYP(Heap_FinDesc, Heap_FinDesc, 0);
	__INITYP(Heap__1, Heap__1, 0);
/* BEGIN */
	__ENDMOD;
}
