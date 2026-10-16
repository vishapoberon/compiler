/* voc 4.0.0 [2026/10/15]. Bootstrapping compiler for address size 8, alignment 8. rtsSF */

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
		INT64 obj;
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
		INT64 initializer;
	} Heap_LifetimeDesc;

typedef
	CHAR Heap_ModuleName[20];

typedef
	struct Heap_ModuleDesc {
		Heap_Module next;
		Heap_ModuleName name;
		INT32 refcnt;
		Heap_Cmd cmds;
		INT64 types;
		Heap_EnumProc enumPtrs;
		INT32 reserved1, reserved2;
	} Heap_ModuleDesc;

typedef
	void (*Heap_ModuleNotifier)(Heap_Module, INT64);

typedef
	struct Heap_ProcedureDesc *Heap_Procedure;

typedef
	struct Heap_ProcedureDesc {
		Heap_Procedure next;
		Heap_Module owner;
		INT64 address;
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
static INT64 Heap_freeList[10];
static INT64 Heap_bigBlocks;
export INT64 Heap_allocated;
static BOOLEAN Heap_firstTry;
static INT16 Heap_ldUnit;
export INT64 Heap_heap;
static INT64 Heap_heapMin, Heap_heapMax;
export INT64 Heap_heapsize, Heap_heapMinExpand;
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
static void Heap_ExtendHeap (INT64 blksz);
export void Heap_FINALL (void);
export void Heap_FINALMOD (Heap_Module owner);
static void Heap_Finalize (void);
export BOOLEAN Heap_Finishable (Heap_Module owner);
export INT32 Heap_FreeModule (CHAR *name, ADDRESS name__len);
export void Heap_GC (BOOLEAN markStack);
export BOOLEAN Heap_HasFinalizers (Heap_Module owner);
static void Heap_HeapSort (INT32 n, INT64 *a, ADDRESS a__len);
export void Heap_INCREF (Heap_Module m);
export Heap_Module Heap_Imported (Heap_Module owner, INT16 index);
export void Heap_InitHeap (void);
export BOOLEAN Heap_InstallTermHandler (Heap_Command handler);
static Heap_Lifetime Heap_Life (Heap_Module owner, BOOLEAN create);
export BOOLEAN Heap_LiveTypes (Heap_Module owner);
export void Heap_Lock (void);
export void Heap_MODREADY (Heap_Module owner, INT64 initializer);
static void Heap_Mark (INT64 q);
static void Heap_MarkCandidates (INT32 n, INT64 *cand, ADDRESS cand__len);
static void Heap_MarkP (SYSTEM_PTR p);
static void Heap_MarkRoots (Heap_Module excluded, BOOLEAN markStack);
static void Heap_MarkStack (INT64 n, INT64 *cand, ADDRESS cand__len);
export INT16 Heap_ModuleState (Heap_Module owner);
export SYSTEM_PTR Heap_NEWBLK (INT64 size);
export SYSTEM_PTR Heap_NEWREC (INT64 tag);
static BOOLEAN Heap_NativeCallbacks (Heap_Module owner);
static INT64 Heap_NewChunk (INT64 blksz);
static BOOLEAN Heap_OwnedType (Heap_Module owner, INT64 tag);
export Heap_Module Heap_ProcedureModule (INT64 address);
export void Heap_REGCMD (Heap_Module m, CHAR *name, Heap_Command cmd);
export void Heap_REGIMPORT (Heap_Module owner, Heap_Module imported);
export SYSTEM_PTR Heap_REGMOD (CHAR *name, Heap_EnumProc enumPtrs);
export void Heap_REGPROC (Heap_Module m, INT64 address);
export void Heap_REGTYP (Heap_Module m, INT64 typ);
export void Heap_RegisterFinalizer (SYSTEM_PTR obj, Heap_Finalizer finalize);
export BOOLEAN Heap_RegisterUnloadHook (Heap_UnloadHandler handler);
export BOOLEAN Heap_ReleaseModule (Heap_Retention r);
export Heap_Retention Heap_RetainModule (Heap_Module owner);
export Heap_Retention Heap_RetainProcedure (INT64 address);
export INT32 Heap_Retained (Heap_Module owner);
static void Heap_Scan (void);
export void Heap_SetModuleNotifier (Heap_ModuleNotifier handler);
static void Heap_Sift (INT32 l, INT32 r, INT64 *a, ADDRESS a__len);
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
		__SYSNEW(m, 64);
	} else {
		__NEW(m, Heap_ModuleDesc);
	}
	m->types = 0;
	m->cmds = NIL;
	__COPY(name, m->name, 20);
	m->refcnt = 0;
	m->enumPtrs = enumPtrs;
	m->next = (Heap_Module)(ADDRESS)Heap_modules;
	Heap_modules = (SYSTEM_PTR)m;
	return (void*)m;
}

INT32 Heap_FreeModule (CHAR *name, ADDRESS name__len)
{
	Heap_Module m, p;
	__DUP(name, name__len, CHAR);
	m = (Heap_Module)(ADDRESS)Heap_modules;
	while ((m != NIL && __STRCMP(m->name, name) != 0)) {
		p = m;
		m = m->next;
	}
	if ((m != NIL && m->refcnt == 0)) {
		if (m == (Heap_Module)(ADDRESS)Heap_modules) {
			Heap_modules = (SYSTEM_PTR)m->next;
		} else {
			p->next = m->next;
		}
		__DEL(name);
		return 0;
	} else {
		if (m == NIL) {
			__DEL(name);
			return -1;
		} else {
			__DEL(name);
			return m->refcnt;
		}
	}
	__RETCHK;
}

void Heap_REGCMD (Heap_Module m, CHAR *name, Heap_Command cmd)
{
	Heap_Cmd c;
	if (__STRCMP(m->name, "Heap") == 0) {
		__SYSNEW(c, 40);
	} else {
		__NEW(c, Heap_CmdDesc);
	}
	__COPY(name, c->name, 24);
	c->cmd = cmd;
	c->next = m->cmds;
	m->cmds = c;
}

void Heap_REGTYP (Heap_Module m, INT64 typ)
{
	__PUT(typ, m->types, INT64);
	m->types = typ;
}

void Heap_INCREF (Heap_Module m)
{
	m->refcnt += 1;
}

static Heap_Lifetime Heap_Life (Heap_Module owner, BOOLEAN create)
{
	Heap_Lifetime l;
	l = Heap_lifetimes;
	while ((l != NIL && l->owner != owner)) {
		l = l->next;
	}
	if ((l == NIL && create)) {
		__NEW(l, Heap_LifetimeDesc);
		l->owner = owner;
		l->state = 1;
		l->next = Heap_lifetimes;
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
		return l->state;
	}
	__RETCHK;
}

void Heap_REGIMPORT (Heap_Module owner, Heap_Module imported)
{
	Heap_Lifetime l;
	Heap_Import i;
	l = Heap_Life(owner, 1);
	__NEW(i, Heap_ImportDesc);
	i->imported = imported;
	i->next = l->imports;
	l->imports = i;
}

void Heap_MODREADY (Heap_Module owner, INT64 initializer)
{
	Heap_Lifetime l;
	l = Heap_Life(owner, 1);
	l->state = 2;
	l->initializer = initializer;
	if (Heap_notifier != NIL) {
		(*Heap_notifier)(owner, initializer);
	}
}

void Heap_SetModuleNotifier (Heap_ModuleNotifier handler)
{
	Heap_Lifetime l;
		Heap_notifier = handler;
	Heap_notifierRetention = Heap_RetainProcedure(Heap_NotifierAddress(handler));
		l = Heap_lifetimes;
	while (l != NIL) {
		if ((l->state == 2 && l->initializer != 0)) {
			(*Heap_notifier)(l->owner, l->initializer);
		}
		l = l->next;
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
	if (l == NIL || l->state != 2) {
		return NIL;
	}
	__NEW(r, Heap_RetentionDesc);
	r->owner = owner;
	r->next = Heap_retentions;
	Heap_retentions = r;
	l->retained += 1;
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
		p = p->next;
	}
	if (p == NIL) {
		return 0;
	}
	l = Heap_Life(p->owner, 0);
			l->retained -= 1;
	if (previous == NIL) {
		Heap_retentions = p->next;
	} else {
		previous->next = p->next;
	}
	p->owner = NIL;
	p->next = NIL;
	return 1;
}

INT32 Heap_Retained (Heap_Module owner)
{
	Heap_Lifetime l;
	l = Heap_Life(owner, 0);
	if (l == NIL) {
		return 0;
	} else {
		return l->retained;
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
	i = l->imports;
	while ((i != NIL && index > 0)) {
		i = i->next;
		index -= 1;
	}
	if (i == NIL) {
		return NIL;
	} else {
		return i->imported;
	}
	__RETCHK;
}

void Heap_REGPROC (Heap_Module m, INT64 address)
{
	Heap_Procedure p;
	__NEW(p, Heap_ProcedureDesc);
	p->owner = m;
	p->address = address;
	p->next = Heap_procedures;
	Heap_procedures = p;
}

Heap_Module Heap_ProcedureModule (INT64 address)
{
	Heap_Procedure p;
	p = Heap_procedures;
	while ((p != NIL && p->address != address)) {
		p = p->next;
	}
	if (p == NIL) {
		return NIL;
	} else {
		return p->owner;
	}
	__RETCHK;
}

Heap_Retention Heap_RetainProcedure (INT64 address)
{
	Heap_Module owner;
	Heap_Lifetime l;
	Heap_Retention r;
	owner = Heap_ProcedureModule(address);
	if (owner == NIL) {
		return NIL;
	}
	l = Heap_Life(owner, 1);
	if (l->state > 2) {
		return NIL;
	}
	__NEW(r, Heap_RetentionDesc);
	r->owner = owner;
	r->next = Heap_retentions;
	Heap_retentions = r;
	l->retained += 1;
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
	while ((h != NIL && h->handler != handler)) {
		h = h->next;
	}
	if (h != NIL) {
		return 1;
	}
	owner = Heap_ProcedureModule(Heap_HookAddress(handler));
	if (owner == NIL) {
		return 0;
	}
	l = Heap_Life(owner, 1);
	if (l->state > 2) {
		return 0;
	}
	__NEW(h, Heap_UnloadHookDesc);
	h->owner = owner;
	h->handler = handler;
	h->next = Heap_unloadHooks;
	Heap_unloadHooks = h;
	l->retained += 1;
	return 1;
}

BOOLEAN Heap_UnregisterUnloadHook (Heap_UnloadHandler handler)
{
	Heap_UnloadHook h, previous;
	Heap_Lifetime l;
	h = Heap_unloadHooks;
	previous = NIL;
	while ((h != NIL && h->handler != handler)) {
		previous = h;
		h = h->next;
	}
	if (h == NIL) {
		return 0;
	}
	l = Heap_Life(h->owner, 0);
	l->retained -= 1;
	if (previous == NIL) {
		Heap_unloadHooks = h->next;
	} else {
		previous->next = h->next;
	}
	return 1;
}

void Heap_DetachCallbacks (Heap_Module owner)
{
	Heap_UnloadHook h;
	h = Heap_unloadHooks;
	while (h != NIL) {
		(*h->handler)(owner);
		h = h->next;
	}
}

static BOOLEAN Heap_NativeCallbacks (Heap_Module owner)
{
	INT16 i;
	INT64 address;
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
	if (l->state != 2) {
		return 2;
	}
	if (owner->refcnt != 1) {
		return 3;
	}
	if (Heap_Active(owner)) {
		return 4;
	}
	if (l->retained != 0 || Heap_NativeCallbacks(owner)) {
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
		l->state = 3;
}

BOOLEAN Heap_Finishable (Heap_Module owner)
{
	Heap_Lifetime l;
	l = Heap_Life(owner, 0);
	return (((((((((l != NIL && l->state == 3)) && l->retained == 0)) && owner->refcnt == 1)) && !Heap_Active(owner))) && !Heap_NativeCallbacks(owner));
}

BOOLEAN Heap_HasFinalizers (Heap_Module owner)
{
	Heap_FinNode f;
	f = Heap_fin;
	while (f != NIL) {
		if (Heap_ProcedureModule(Heap_FinalizerAddress(f->finalize)) == owner) {
			return 1;
		}
		f = f->next;
	}
	return 0;
}

void Heap_DisableModule (Heap_Module owner)
{
	Heap_Lifetime l;
	l = Heap_Life(owner, 0);
		l->state = 4;
	owner->cmds = NIL;
	owner->enumPtrs = NIL;
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
	while ((l != NIL && l->owner != owner)) {
		lp = l;
		l = l->next;
	}
			i = l->imports;
	while (i != NIL) {
				i->imported->refcnt -= 1;
		i = i->next;
	}
	if (lp == NIL) {
		Heap_lifetimes = l->next;
	} else {
		lp->next = l->next;
	}
	p = Heap_procedures;
	pp = NIL;
	while (p != NIL) {
		pn = p->next;
		if (p->owner == owner) {
			if (pp == NIL) {
				Heap_procedures = pn;
			} else {
				pp->next = pn;
			}
		} else {
			pp = p;
		}
		p = pn;
	}
	t = Heap_terminations;
	tp = NIL;
	while ((t != NIL && t->owner != owner)) {
		tp = t;
		t = t->next;
	}
	if (t != NIL) {
		if (tp == NIL) {
			Heap_terminations = t->next;
		} else {
			tp->next = t->next;
		}
	}
	m = (Heap_Module)(ADDRESS)Heap_modules;
	previous = NIL;
	while ((m != NIL && m != owner)) {
		previous = m;
		m = m->next;
	}
		if (previous == NIL) {
		Heap_modules = (SYSTEM_PTR)m->next;
	} else {
		previous->next = m->next;
	}
	m->cmds = NIL;
	m->enumPtrs = NIL;
	m->types = 0;
	m->next = NIL;
	m->refcnt = 0;
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
	while ((t != NIL && t->owner != owner)) {
		t = t->next;
	}
	if (t == NIL) {
		__NEW(t, Heap_TerminationDesc);
		t->owner = owner;
		t->next = Heap_terminations;
		Heap_terminations = t;
	}
	t->handler = handler;
	return 1;
}

static void Heap_Terminate (Heap_Module owner)
{
	Heap_Termination t;
	Heap_Command handler;
	t = Heap_terminations;
	while ((t != NIL && t->owner != owner)) {
		t = t->next;
	}
	if ((t != NIL && t->handler != NIL)) {
		handler = t->handler;
		t->handler = NIL;
		(*handler)();
	}
}

static INT64 Heap_NewChunk (INT64 blksz)
{
	INT64 chnk, blk, end;
	chnk = Heap_OSAllocate(blksz + 24);
	if (chnk != 0) {
		blk = chnk + 24;
		end = blk + blksz;
		__PUT(chnk + 8, end, INT64);
		__PUT(blk, blk + 8, INT64);
		__PUT(blk + 8, blksz, INT64);
		__PUT(blk + 16, -8, INT64);
		__PUT(blk + 24, Heap_bigBlocks, INT64);
		Heap_bigBlocks = blk;
		Heap_heapsize += blksz;
		if (Heap_uLT(blk + 8, Heap_heapMin)) {
			Heap_heapMin = blk + 8;
		}
		if (Heap_uLT(Heap_heapMax, end)) {
			Heap_heapMax = end;
		}
	}
	return chnk;
}

static void Heap_ExtendHeap (INT64 blksz)
{
	INT64 size, chnk, j, next;
		if (Heap_uLT(Heap_heapMinExpand, blksz)) {
		size = blksz;
	} else {
		size = Heap_heapMinExpand;
	}
	chnk = Heap_NewChunk(size);
	if (chnk != 0) {
		if (Heap_uLT(chnk, Heap_heap)) {
			__PUT(chnk, Heap_heap, INT64);
			Heap_heap = chnk;
		} else {
			j = Heap_heap;
			__GET(j, next, INT64);
			while ((next != 0 && Heap_uLT(next, chnk))) {
				j = next;
				__GET(j, next, INT64);
			}
			__PUT(chnk, next, INT64);
			__PUT(j, chnk, INT64);
		}
	} else if (!Heap_firstTry) {
		Heap_heapMinExpand = 32;
	}
}

SYSTEM_PTR Heap_NEWREC (INT64 tag)
{
	INT64 i, i0, di, blksz, restsize, t, adr, end, next, prev;
	SYSTEM_PTR new;
	Heap_Lock();
	__GET(tag, blksz, INT64);
		i0 = __LSH(blksz, -Heap_ldUnit, 64);
	i = i0;
	if (i < 9) {
		adr = Heap_freeList[i];
		while (adr == 0) {
			i += 1;
			adr = Heap_freeList[i];
		}
	}
	if (i < 9) {
		__GET(adr + 24, next, INT64);
		Heap_freeList[i] = next;
		if (i != i0) {
			di = i - i0;
			restsize = __ASHL(di, 5);
			end = adr + restsize;
			__PUT(end + 8, blksz, INT64);
			__PUT(end + 16, -8, INT64);
			__PUT(end, end + 8, INT64);
			__PUT(adr + 8, restsize, INT64);
			__PUT(adr + 24, Heap_freeList[di], INT64);
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
					blksz += 32;
					t = __LSH(Heap_allocated + blksz, -(2 + Heap_ldUnit), 64) * 160;
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
			__GET(adr + 8, t, INT64);
			if (Heap_uLE(blksz, t)) {
				break;
			}
			prev = adr;
			__GET(adr + 24, adr, INT64);
		}
		restsize = t - blksz;
		end = adr + restsize;
		__PUT(end + 8, blksz, INT64);
		__PUT(end + 16, -8, INT64);
		__PUT(end, end + 8, INT64);
		if (Heap_uLT(288, restsize)) {
			__PUT(adr + 8, restsize, INT64);
		} else {
			__GET(adr + 24, next, INT64);
			if (prev == 0) {
				Heap_bigBlocks = next;
			} else {
				__PUT(prev + 24, next, INT64);
			}
			if (restsize != 0) {
				di = __ASHR(restsize, 5);
				__PUT(adr + 8, restsize, INT64);
				__PUT(adr + 24, Heap_freeList[di], INT64);
				Heap_freeList[di] = adr;
			}
		}
		adr += restsize;
	}
	i = adr + 32;
	end = adr + blksz;
	while (Heap_uLT(i, end)) {
		__PUT(i, 0, INT64);
		__PUT(i + 8, 0, INT64);
		__PUT(i + 16, 0, INT64);
		__PUT(i + 24, 0, INT64);
		i += 32;
	}
	__PUT(adr + 24, 0, INT64);
	__PUT(adr, tag, INT64);
	__PUT(adr + 8, 0, INT64);
	__PUT(adr + 16, 0, INT64);
	Heap_allocated += blksz;
	Heap_Unlock();
	return (SYSTEM_PTR)(ADDRESS)(adr + 8);
}

SYSTEM_PTR Heap_NEWBLK (INT64 size)
{
	INT64 blksz, tag;
	SYSTEM_PTR new;
	Heap_Lock();
	blksz = __ASHL(__ASHR(size + 63, 5), 5);
	new = Heap_NEWREC((ADDRESS)&blksz);
	tag = ((INT64)(ADDRESS)new + blksz) - 24;
	__PUT(tag - 8, 0, INT64);
	__PUT(tag, blksz, INT64);
	__PUT(tag + 8, -8, INT64);
	__PUT((INT64)(ADDRESS)new - 8, tag, INT64);
	Heap_Unlock();
	return new;
}

static void Heap_Mark (INT64 q)
{
	INT64 p, tag, offset, fld, n, tagbits;
	if (q != 0) {
		__GET(q - 8, tagbits, INT64);
		if (!__ODD(tagbits)) {
			__PUT(q - 8, tagbits + 1, INT64);
			p = 0;
			tag = tagbits + 8;
			for (;;) {
				__GET(tag, offset, INT64);
				if (offset < 0) {
					__PUT(q - 8, (tag + offset) + 1, INT64);
					if (p == 0) {
						break;
					}
					n = q;
					q = p;
					__GET(q - 8, tag, INT64);
					tag -= 1;
					__GET(tag, offset, INT64);
					fld = q + offset;
					__GET(fld, p, INT64);
					__PUT(fld, (SYSTEM_PTR)(ADDRESS)n, SYSTEM_PTR);
				} else {
					fld = q + offset;
					__GET(fld, n, INT64);
					if (n != 0) {
						__GET(n - 8, tagbits, INT64);
						if (!__ODD(tagbits)) {
							__PUT(n - 8, tagbits + 1, INT64);
							__PUT(q - 8, tag + 1, INT64);
							__PUT(fld, (SYSTEM_PTR)(ADDRESS)p, SYSTEM_PTR);
							p = q;
							q = n;
							tag = tagbits;
						}
					}
				}
				tag += 8;
			}
		}
	}
}

static void Heap_MarkP (SYSTEM_PTR p)
{
	Heap_Mark((INT64)(ADDRESS)p);
}

static void Heap_Scan (void)
{
	INT64 chnk, adr, end, start, tag, i, size, freesize;
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
		adr = chnk + 24;
		__GET(chnk + 8, end, INT64);
		while (Heap_uLT(adr, end)) {
			__GET(adr, tag, INT64);
			if (__ODD(tag)) {
				if (freesize != 0) {
					start = adr - freesize;
					__PUT(start, start + 8, INT64);
					__PUT(start + 8, freesize, INT64);
					__PUT(start + 16, -8, INT64);
					i = __LSH(freesize, -Heap_ldUnit, 64);
					freesize = 0;
					if (Heap_uLT(i, 9)) {
						__PUT(start + 24, Heap_freeList[i], INT64);
						Heap_freeList[i] = start;
					} else {
						__PUT(start + 24, Heap_bigBlocks, INT64);
						Heap_bigBlocks = start;
					}
				}
				tag -= 1;
				__PUT(adr, tag, INT64);
				__GET(tag, size, INT64);
				Heap_allocated += size;
				adr += size;
			} else {
				__GET(tag, size, INT64);
				freesize += size;
				adr += size;
			}
		}
		if (freesize != 0) {
			start = adr - freesize;
			__PUT(start, start + 8, INT64);
			__PUT(start + 8, freesize, INT64);
			__PUT(start + 16, -8, INT64);
			i = __LSH(freesize, -Heap_ldUnit, 64);
			freesize = 0;
			if (Heap_uLT(i, 9)) {
				__PUT(start + 24, Heap_freeList[i], INT64);
				Heap_freeList[i] = start;
			} else {
				__PUT(start + 24, Heap_bigBlocks, INT64);
				Heap_bigBlocks = start;
			}
		}
		__GET(chnk, chnk, INT64);
	}
}

static void Heap_Sift (INT32 l, INT32 r, INT64 *a, ADDRESS a__len)
{
	INT32 i, j;
	INT64 x;
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

static void Heap_HeapSort (INT32 n, INT64 *a, ADDRESS a__len)
{
	INT32 l, r;
	INT64 x;
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

static void Heap_MarkCandidates (INT32 n, INT64 *cand, ADDRESS cand__len)
{
	INT64 chnk, end, adr, tag, next, i, ptr, size;
		chnk = Heap_heap;
	i = 0;
	while (chnk != 0) {
		__GET(chnk + 8, end, INT64);
		adr = chnk + 24;
		while (Heap_uLT(adr, end)) {
			__GET(adr, tag, INT64);
			if (__ODD(tag)) {
				__GET(tag - 1, size, INT64);
				adr += size;
				ptr = adr + 8;
				while (Heap_uLT(cand[i], ptr)) {
					i += 1;
					if (i == (INT64)n) {
						return;
					}
				}
			} else {
				__GET(tag, size, INT64);
				ptr = adr + 8;
				adr += size;
				while (Heap_uLT(cand[i], ptr)) {
					i += 1;
					if (i == (INT64)n) {
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
		__GET(chnk, chnk, INT64);
	}
}

static void Heap_CheckFin (void)
{
	Heap_FinNode n;
	INT64 tag;
	n = Heap_fin;
	while (n != NIL) {
		__GET(n->obj - 8, tag, INT64);
		if (!__ODD(tag)) {
			n->marked = 0;
			Heap_Mark(n->obj);
		} else {
			n->marked = 1;
		}
		n = n->next;
	}
}

static void Heap_Finalize (void)
{
	Heap_FinNode n, prev;
	n = Heap_fin;
	prev = NIL;
	while (n != NIL) {
		if (!n->marked) {
			if (n == Heap_fin) {
				Heap_fin = Heap_fin->next;
			} else {
				prev->next = n->next;
			}
			(*n->finalize)((SYSTEM_PTR)(ADDRESS)n->obj);
			if (prev == NIL) {
				n = Heap_fin;
			} else {
				n = n->next;
			}
		} else {
			prev = n;
			n = n->next;
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
		Heap_fin = Heap_fin->next;
		(*n->finalize)((SYSTEM_PTR)(ADDRESS)n->obj);
	}
	m = (Heap_Module)(ADDRESS)Heap_modules;
	while (m != NIL) {
		Heap_Terminate(m);
		m = m->next;
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
		next = n->next;
		if (Heap_ProcedureModule(Heap_FinalizerAddress(n->finalize)) == owner) {
			if (previous == NIL) {
				Heap_fin = next;
			} else {
				previous->next = next;
			}
			(*n->finalize)((SYSTEM_PTR)(ADDRESS)n->obj);
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

static void Heap_MarkStack (INT64 n, INT64 *cand, ADDRESS cand__len)
{
	SYSTEM_PTR frame;
	INT32 nofcand;
	INT64 inc, sp, p, stack0;
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
			__GET(sp, p, INT64);
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
	INT64 i0, i1, i2, i3, i4, i5, i6, i7, i8, i9, i10, i11, i12, i13, i14, i15, i16, i17, i18, i19, i20, i21, i22, i23;
	INT64 cand[10000];
	m = (Heap_Module)(ADDRESS)Heap_modules;
	while (m != NIL) {
		if ((m != excluded && m->enumPtrs != NIL)) {
			(*m->enumPtrs)(Heap_MarkP);
		}
		m = m->next;
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

static BOOLEAN Heap_OwnedType (Heap_Module owner, INT64 tag)
{
	INT64 t;
	t = owner->types;
	while (t != 0) {
		if (Heap_TypeTag(t) == tag) {
			return 1;
		}
		__GET(t, t, INT64);
	}
	return 0;
}

static BOOLEAN Heap_TypeReferences (Heap_Module owner, BOOLEAN markedOnly)
{
	INT64 chnk, adr, end, tag, size;
	BOOLEAN found;
	chnk = Heap_heap;
	found = 0;
	while (chnk != 0) {
		adr = chnk + 24;
		__GET(chnk + 8, end, INT64);
		while (Heap_uLT(adr, end)) {
			__GET(adr, tag, INT64);
			if (__ODD(tag)) {
				tag -= 1;
				__PUT(adr, tag, INT64);
				if (Heap_OwnedType(owner, tag)) {
					found = 1;
				}
			} else if (!markedOnly) {
				if (Heap_OwnedType(owner, tag)) {
					found = 1;
				}
			}
			__GET(tag, size, INT64);
			adr += size;
		}
		__GET(chnk, chnk, INT64);
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
		if (Heap_ProcedureModule(Heap_FinalizerAddress(n->finalize)) != owner) {
			Heap_Mark(n->obj);
		}
		n = n->next;
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
	f->obj = (INT64)(ADDRESS)obj;
	f->finalize = finalize;
	f->marked = 1;
	f->next = Heap_fin;
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
	Heap_heapMinExpand = 256000;
	Heap_ldUnit = 5;
	Heap_heap = Heap_NewChunk(256000);
	__PUT(Heap_heap, 0, INT64);
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

__TDESC(Heap_ModuleDesc, 1, 2) = {__TDFLDS("ModuleDesc", 64), {0, 32, -24}};
__TDESC(Heap_ImportDesc, 1, 2) = {__TDFLDS("ImportDesc", 16), {0, 8, -24}};
__TDESC(Heap_LifetimeDesc, 1, 3) = {__TDFLDS("LifetimeDesc", 40), {0, 8, 16, -32}};
__TDESC(Heap_RetentionDesc, 1, 2) = {__TDFLDS("RetentionDesc", 16), {0, 8, -24}};
__TDESC(Heap_UnloadHookDesc, 1, 2) = {__TDFLDS("UnloadHookDesc", 24), {0, 8, -24}};
__TDESC(Heap_ProcedureDesc, 1, 2) = {__TDFLDS("ProcedureDesc", 24), {0, 8, -24}};
__TDESC(Heap_TerminationDesc, 1, 2) = {__TDFLDS("TerminationDesc", 24), {0, 8, -24}};
__TDESC(Heap_CmdDesc, 1, 1) = {__TDFLDS("CmdDesc", 40), {0, -16}};
__TDESC(Heap_FinDesc, 1, 1) = {__TDFLDS("FinDesc", 32), {0, -16}};
__TDESC(Heap__1, 1, 1) = {__TDFLDS("", 16), {8, -16}};

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
