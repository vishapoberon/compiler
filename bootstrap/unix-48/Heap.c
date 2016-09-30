/* voc 1.95 [2016/09/30]. Bootstrapping compiler for address size 8, alignment 8. tsSfF */

#define SHORTINT int8
#define INTEGER  int16
#define LONGINT  int32
#define SET      uint32

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
		int32 obj;
		BOOLEAN marked;
		Heap_Finalizer finalize;
	} Heap_FinDesc;

typedef
	struct Heap_ModuleDesc *Heap_Module;

typedef
	CHAR Heap_ModuleName[20];

typedef
	struct Heap_ModuleDesc {
		Heap_Module next;
		Heap_ModuleName name;
		int32 refcnt;
		Heap_Cmd cmds;
		int32 types;
		Heap_EnumProc enumPtrs;
		int32 reserved1, reserved2;
	} Heap_ModuleDesc;


export SYSTEM_PTR Heap_modules;
static int32 Heap_freeList[10];
static int32 Heap_bigBlocks;
export int32 Heap_allocated;
static BOOLEAN Heap_firstTry;
static int32 Heap_heap, Heap_heapend;
export int32 Heap_heapsize;
static Heap_FinNode Heap_fin;
static int16 Heap_lockdepth;
static BOOLEAN Heap_interrupted;
export int16 Heap_FileCount;

export address *Heap_ModuleDesc__typ;
export address *Heap_CmdDesc__typ;
export address *Heap_FinDesc__typ;
export address *Heap__1__typ;

static void Heap_CheckFin (void);
static void Heap_ExtendHeap (int32 blksz);
export void Heap_FINALL (void);
static void Heap_Finalize (void);
export void Heap_GC (BOOLEAN markStack);
static void Heap_HeapSort (int32 n, int32 *a, LONGINT a__len);
export void Heap_INCREF (Heap_Module m);
export void Heap_InitHeap (void);
export void Heap_Lock (void);
static void Heap_Mark (int32 q);
static void Heap_MarkCandidates (int32 n, int32 *cand, LONGINT cand__len);
static void Heap_MarkP (SYSTEM_PTR p);
static void Heap_MarkStack (int32 n, int32 *cand, LONGINT cand__len);
export SYSTEM_PTR Heap_NEWBLK (int32 size);
export SYSTEM_PTR Heap_NEWREC (int32 tag);
static int32 Heap_NewChunk (int32 blksz);
export void Heap_REGCMD (Heap_Module m, Heap_CmdName name, Heap_Command cmd);
export SYSTEM_PTR Heap_REGMOD (Heap_ModuleName name, Heap_EnumProc enumPtrs);
export void Heap_REGTYP (Heap_Module m, int32 typ);
export void Heap_RegisterFinalizer (SYSTEM_PTR obj, Heap_Finalizer finalize);
static void Heap_Scan (void);
static void Heap_Sift (int32 l, int32 r, int32 *a, LONGINT a__len);
export void Heap_Unlock (void);

extern void *Heap__init();
extern address Platform_MainStackFrame;
extern address Platform_OSAllocate(address size);
#define Heap_HeapModuleInit()	Heap__init()
#define Heap_OSAllocate(size)	Platform_OSAllocate(size)
#define Heap_PlatformHalt(code)	Platform_Halt(code)
#define Heap_PlatformMainStackFrame()	Platform_MainStackFrame

void Heap_Lock (void)
{
	Heap_lockdepth += 1;
}

void Heap_Unlock (void)
{
	Heap_lockdepth -= 1;
	if ((Heap_interrupted && Heap_lockdepth == 0)) {
		Heap_PlatformHalt(-9);
	}
}

SYSTEM_PTR Heap_REGMOD (Heap_ModuleName name, Heap_EnumProc enumPtrs)
{
	SYSTEM_PTR _o_result;
	Heap_Module m;
	if (__STRCMP(name, "Heap") == 0) {
		__SYSNEW(m, 48);
	} else {
		__NEW(m, Heap_ModuleDesc);
	}
	m->types = 0;
	m->cmds = NIL;
	__COPY(name, m->name, 20);
	m->refcnt = 0;
	m->enumPtrs = enumPtrs;
	m->next = (Heap_Module)(address)Heap_modules;
	Heap_modules = (SYSTEM_PTR)m;
	_o_result = (void*)m;
	return _o_result;
}

void Heap_REGCMD (Heap_Module m, Heap_CmdName name, Heap_Command cmd)
{
	Heap_Cmd c;
	if (__STRCMP(m->name, "Heap") == 0) {
		__SYSNEW(c, 32);
	} else {
		__NEW(c, Heap_CmdDesc);
	}
	__COPY(name, c->name, 24);
	c->cmd = cmd;
	c->next = m->cmds;
	m->cmds = c;
}

void Heap_REGTYP (Heap_Module m, int32 typ)
{
	__PUT(typ, m->types, int32);
	m->types = typ;
}

void Heap_INCREF (Heap_Module m)
{
	m->refcnt += 1;
}

static int32 Heap_NewChunk (int32 blksz)
{
	int32 _o_result;
	int32 chnk;
	chnk = Heap_OSAllocate(blksz + 12);
	if (chnk != 0) {
		__PUT(chnk + 4, chnk + (12 + blksz), int32);
		__PUT(chnk + 12, chnk + 16, int32);
		__PUT(chnk + 16, blksz, int32);
		__PUT(chnk + 20, -4, int32);
		__PUT(chnk + 24, Heap_bigBlocks, int32);
		Heap_bigBlocks = chnk + 12;
		Heap_heapsize += blksz;
	}
	_o_result = chnk;
	return _o_result;
}

static void Heap_ExtendHeap (int32 blksz)
{
	int32 size, chnk, j, next;
	if (blksz > 160000) {
		size = blksz;
	} else {
		size = 160000;
	}
	chnk = Heap_NewChunk(size);
	if (chnk != 0) {
		if (chnk < Heap_heap) {
			__PUT(chnk, Heap_heap, int32);
			Heap_heap = chnk;
		} else {
			j = Heap_heap;
			__GET(j, next, int32);
			while ((next != 0 && chnk > next)) {
				j = next;
				__GET(j, next, int32);
			}
			__PUT(chnk, next, int32);
			__PUT(j, chnk, int32);
		}
		if (next == 0) {
			__GET(chnk + 4, Heap_heapend, int32);
		}
	}
}

SYSTEM_PTR Heap_NEWREC (int32 tag)
{
	SYSTEM_PTR _o_result;
	int32 i, i0, di, blksz, restsize, t, adr, end, next, prev;
	SYSTEM_PTR new;
	Heap_Lock();
	__GET(tag, blksz, int32);
		i0 = __ASHR(blksz, 4);
	i = i0;
	if (i < 9) {
		adr = Heap_freeList[i];
		while (adr == 0) {
			i += 1;
			adr = Heap_freeList[i];
		}
	}
	if (i < 9) {
		__GET(adr + 12, next, int32);
		Heap_freeList[i] = next;
		if (i != i0) {
			di = i - i0;
			restsize = __ASHL(di, 4);
			end = adr + restsize;
			__PUT(end + 4, blksz, int32);
			__PUT(end + 8, -4, int32);
			__PUT(end, end + 4, int32);
			__PUT(adr + 4, restsize, int32);
			__PUT(adr + 12, Heap_freeList[di], int32);
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
					if (__ASHL((Heap_heapsize - Heap_allocated) - blksz, 2) < Heap_heapsize) {
						Heap_ExtendHeap(__ASHL(__DIV(Heap_allocated + blksz, 48), 6) - Heap_heapsize);
					}
					Heap_firstTry = 0;
					new = Heap_NEWREC(tag);
					Heap_firstTry = 1;
					if (new == NIL) {
						Heap_ExtendHeap(__ASHL(__DIV(Heap_allocated + blksz, 48), 6) - Heap_heapsize);
						new = Heap_NEWREC(tag);
					}
					Heap_Unlock();
					_o_result = new;
					return _o_result;
				} else {
					Heap_Unlock();
					_o_result = NIL;
					return _o_result;
				}
			}
			__GET(adr + 4, t, int32);
			if (t >= blksz) {
				break;
			}
			prev = adr;
			__GET(adr + 12, adr, int32);
		}
		restsize = t - blksz;
		end = adr + restsize;
		__PUT(end + 4, blksz, int32);
		__PUT(end + 8, -4, int32);
		__PUT(end, end + 4, int32);
		if (restsize > 144) {
			__PUT(adr + 4, restsize, int32);
		} else {
			__GET(adr + 12, next, int32);
			if (prev == 0) {
				Heap_bigBlocks = next;
			} else {
				__PUT(prev + 12, next, int32);
			}
			if (restsize > 0) {
				di = __ASHR(restsize, 4);
				__PUT(adr + 4, restsize, int32);
				__PUT(adr + 12, Heap_freeList[di], int32);
				Heap_freeList[di] = adr;
			}
		}
		adr += restsize;
	}
	i = adr + 16;
	end = adr + blksz;
	while (i < end) {
		__PUT(i, 0, int32);
		__PUT(i + 4, 0, int32);
		__PUT(i + 8, 0, int32);
		__PUT(i + 12, 0, int32);
		i += 16;
	}
	__PUT(adr + 12, 0, int32);
	__PUT(adr, tag, int32);
	__PUT(adr + 4, 0, int32);
	__PUT(adr + 8, 0, int32);
	Heap_allocated += blksz;
	Heap_Unlock();
	_o_result = (SYSTEM_PTR)(address)(adr + 4);
	return _o_result;
}

SYSTEM_PTR Heap_NEWBLK (int32 size)
{
	SYSTEM_PTR _o_result;
	int32 blksz, tag;
	SYSTEM_PTR new;
	Heap_Lock();
	blksz = __ASHL(__ASHR(size + 31, 4), 4);
	new = Heap_NEWREC((address)&blksz);
	tag = ((int32)(address)new + blksz) - 12;
	__PUT(tag - 4, 0, int32);
	__PUT(tag, blksz, int32);
	__PUT(tag + 4, -4, int32);
	__PUT((int32)(address)new - 4, tag, int32);
	Heap_Unlock();
	_o_result = new;
	return _o_result;
}

static void Heap_Mark (int32 q)
{
	int32 p, tag, offset, fld, n, tagbits;
	if (q != 0) {
		__GET(q - 4, tagbits, int32);
		if (!__ODD(tagbits)) {
			__PUT(q - 4, tagbits + 1, int32);
			p = 0;
			tag = tagbits + 4;
			for (;;) {
				__GET(tag, offset, int32);
				if (offset < 0) {
					__PUT(q - 4, (tag + offset) + 1, int32);
					if (p == 0) {
						break;
					}
					n = q;
					q = p;
					__GET(q - 4, tag, int32);
					tag -= 1;
					__GET(tag, offset, int32);
					fld = q + offset;
					__GET(fld, p, int32);
					__PUT(fld, (SYSTEM_PTR)(address)n, SYSTEM_PTR);
				} else {
					fld = q + offset;
					__GET(fld, n, int32);
					if (n != 0) {
						__GET(n - 4, tagbits, int32);
						if (!__ODD(tagbits)) {
							__PUT(n - 4, tagbits + 1, int32);
							__PUT(q - 4, tag + 1, int32);
							__PUT(fld, (SYSTEM_PTR)(address)p, SYSTEM_PTR);
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
	Heap_Mark((int32)(address)p);
}

static void Heap_Scan (void)
{
	int32 chnk, adr, end, start, tag, i, size, freesize;
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
		__GET(chnk + 4, end, int32);
		while (adr < end) {
			__GET(adr, tag, int32);
			if (__ODD(tag)) {
				if (freesize > 0) {
					start = adr - freesize;
					__PUT(start, start + 4, int32);
					__PUT(start + 4, freesize, int32);
					__PUT(start + 8, -4, int32);
					i = __ASHR(freesize, 4);
					freesize = 0;
					if (i < 9) {
						__PUT(start + 12, Heap_freeList[i], int32);
						Heap_freeList[i] = start;
					} else {
						__PUT(start + 12, Heap_bigBlocks, int32);
						Heap_bigBlocks = start;
					}
				}
				tag -= 1;
				__PUT(adr, tag, int32);
				__GET(tag, size, int32);
				Heap_allocated += size;
				adr += size;
			} else {
				__GET(tag, size, int32);
				freesize += size;
				adr += size;
			}
		}
		if (freesize > 0) {
			start = adr - freesize;
			__PUT(start, start + 4, int32);
			__PUT(start + 4, freesize, int32);
			__PUT(start + 8, -4, int32);
			i = __ASHR(freesize, 4);
			freesize = 0;
			if (i < 9) {
				__PUT(start + 12, Heap_freeList[i], int32);
				Heap_freeList[i] = start;
			} else {
				__PUT(start + 12, Heap_bigBlocks, int32);
				Heap_bigBlocks = start;
			}
		}
		__GET(chnk, chnk, int32);
	}
}

static void Heap_Sift (int32 l, int32 r, int32 *a, LONGINT a__len)
{
	int32 i, j, x;
	j = l;
	x = a[j];
	for (;;) {
		i = j;
		j = __ASHL(j, 1) + 1;
		if ((j < r && a[j] < a[j + 1])) {
			j += 1;
		}
		if (j > r || a[j] <= x) {
			break;
		}
		a[i] = a[j];
	}
	a[i] = x;
}

static void Heap_HeapSort (int32 n, int32 *a, LONGINT a__len)
{
	int32 l, r, x;
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

static void Heap_MarkCandidates (int32 n, int32 *cand, LONGINT cand__len)
{
	int32 chnk, adr, tag, next, lim, lim1, i, ptr, size;
	chnk = Heap_heap;
	i = 0;
	lim = cand[n - 1];
	while ((chnk != 0 && chnk < lim)) {
		adr = chnk + 12;
		__GET(chnk + 4, lim1, int32);
		if (lim < lim1) {
			lim1 = lim;
		}
		while (adr < lim1) {
			__GET(adr, tag, int32);
			if (__ODD(tag)) {
				__GET(tag - 1, size, int32);
				adr += size;
			} else {
				__GET(tag, size, int32);
				ptr = adr + 4;
				while (cand[i] < ptr) {
					i += 1;
				}
				if (i == n) {
					return;
				}
				next = adr + size;
				if (cand[i] < next) {
					Heap_Mark(ptr);
				}
				adr = next;
			}
		}
		__GET(chnk, chnk, int32);
	}
}

static void Heap_CheckFin (void)
{
	Heap_FinNode n;
	int32 tag;
	n = Heap_fin;
	while (n != NIL) {
		__GET(n->obj - 4, tag, int32);
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
			(*n->finalize)((SYSTEM_PTR)(address)n->obj);
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
	while (Heap_fin != NIL) {
		n = Heap_fin;
		Heap_fin = Heap_fin->next;
		(*n->finalize)((SYSTEM_PTR)(address)n->obj);
	}
}

static void Heap_MarkStack (int32 n, int32 *cand, LONGINT cand__len)
{
	SYSTEM_PTR frame;
	int32 inc, nofcand, sp, p, stack0;
	struct Heap__1 align;
	if (n > 0) {
		Heap_MarkStack(n - 1, cand, cand__len);
		if (n > 100) {
			return;
		}
	}
	if (n == 0) {
		nofcand = 0;
		sp = (address)&frame;
		stack0 = Heap_PlatformMainStackFrame();
		inc = (address)&align.p - (address)&align;
		if (sp > stack0) {
			inc = -inc;
		}
		while (sp != stack0) {
			__GET(sp, p, int32);
			if ((p > Heap_heap && p < Heap_heapend)) {
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

void Heap_GC (BOOLEAN markStack)
{
	Heap_Module m;
	int32 i0, i1, i2, i3, i4, i5, i6, i7, i8, i9, i10, i11, i12, i13, i14, i15, i16, i17, i18, i19, i20, i21, i22, i23;
	int32 cand[10000];
	if (Heap_lockdepth == 0 || (Heap_lockdepth == 1 && !markStack)) {
		Heap_Lock();
		m = (Heap_Module)(address)Heap_modules;
		while (m != NIL) {
			if (m->enumPtrs != NIL) {
				(*m->enumPtrs)(Heap_MarkP);
			}
			m = m->next;
		}
		if (markStack) {
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
		Heap_CheckFin();
		Heap_Scan();
		Heap_Finalize();
		Heap_Unlock();
	}
}

void Heap_RegisterFinalizer (SYSTEM_PTR obj, Heap_Finalizer finalize)
{
	Heap_FinNode f;
	__NEW(f, Heap_FinDesc);
	f->obj = (int32)(address)obj;
	f->finalize = finalize;
	f->marked = 1;
	f->next = Heap_fin;
	Heap_fin = f;
}

void Heap_InitHeap (void)
{
	Heap_heap = Heap_NewChunk(128000);
	__GET(Heap_heap + 4, Heap_heapend, int32);
	__PUT(Heap_heap, 0, int32);
	Heap_allocated = 0;
	Heap_firstTry = 1;
	Heap_freeList[9] = 1;
	Heap_lockdepth = 0;
	Heap_FileCount = 0;
	Heap_modules = NIL;
	Heap_heapsize = 0;
	Heap_bigBlocks = 0;
	Heap_fin = NIL;
	Heap_interrupted = 0;
	Heap_HeapModuleInit();
}

static void EnumPtrs(void (*P)(void*))
{
	P(Heap_modules);
	P(Heap_fin);
}

__TDESC(Heap_ModuleDesc, 1, 2) = {__TDFLDS("ModuleDesc", 48), {0, 28, -12}};
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
	__INITYP(Heap_CmdDesc, Heap_CmdDesc, 0);
	__INITYP(Heap_FinDesc, Heap_FinDesc, 0);
	__INITYP(Heap__1, Heap__1, 0);
/* BEGIN */
	__ENDMOD;
}
