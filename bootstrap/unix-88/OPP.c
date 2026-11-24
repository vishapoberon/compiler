/* voc 5.4.1 [2026/11/24] for gcc LP64 on gentoo xnrtspaSF */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32

#include "SYSTEM.h"
#include "OPB.h"
#include "OPM.h"
#include "OPS.h"
#include "OPT.h"

struct OPP__1 {
	INT32 low, high;
};

typedef
	struct OPP__1 OPP_CaseTable[128];


static INT8 OPP_sym, OPP_level;
static INT16 OPP_LoopLevel, OPP_AllCounter, OPP_ReductionDepth;
static OPT_Node OPP_TDinit, OPP_lastTDinit;
static INT16 OPP_nofFwdPtr;
static OPT_Struct OPP_FwdPtr[64];

export ADDRESS *OPP__1__typ;

static void OPP_ActualParameters (OPT_Node *aparlist, OPT_Object fpar);
static INT16 OPP_AllAccessProof (OPT_Node a, OPT_Node b, OPT_Node ranges);
static BOOLEAN OPP_AllAffine (OPT_Node n, OPT_Object range);
static BOOLEAN OPP_AllDestination (OPT_Node n, OPT_Object range);
static BOOLEAN OPP_AllIndexBounds (OPT_Node n, OPT_Node ranges, INT64 *low, INT64 *high);
static BOOLEAN OPP_AllInjective (OPT_Node n, OPT_Object range);
static BOOLEAN OPP_AllInvariant (OPT_Node n);
static void OPP_AllLocals (OPT_Object range);
static BOOLEAN OPP_AllMultiple (OPT_Node range);
static BOOLEAN OPP_AllOwned (OPT_Object obj, BOOLEAN heap);
static INT16 OPP_AllPathLength (OPT_Node n);
static OPT_Node OPP_AllPathPart (OPT_Node n, INT16 length, INT16 position);
static OPT_Object OPP_AllRoot (OPT_Node n, BOOLEAN *heap);
static BOOLEAN OPP_AllSeparate (OPT_Object a, OPT_Object b, BOOLEAN ah, BOOLEAN bh);
static void OPP_AllStatement (OPT_Node *x);
static void OPP_ArrayType (OPT_Struct *typ, OPT_Struct *banned);
static void OPP_Block (OPT_Node *procdec, OPT_Node *statseq);
static void OPP_CaseLabelList (OPT_Node *lab, OPT_Struct LabelTyp, INT16 *n, struct OPP__1 *tab);
static void OPP_CheckAllAccess (OPT_Node n, OPT_Node target, OPT_Node ranges);
static void OPP_CheckAllAddress (OPT_Node n, OPT_Node target, OPT_Node ranges);
static void OPP_CheckAllAssignments (OPT_Node body, OPT_Node ranges);
static void OPP_CheckAllExpression (OPT_Node n);
static void OPP_CheckMark (INT8 *vis);
static void OPP_CheckSym (INT16 s);
static void OPP_CheckSysFlag (INT16 *sysflag, INT16 default_);
static void OPP_ConstExpression (OPT_Node *x);
static void OPP_Designator (OPT_Node *x);
static void OPP_Element (OPT_Node *x);
static void OPP_Expression (OPT_Node *x);
static BOOLEAN OPP_Extends (OPT_Struct x, OPT_Struct b);
static void OPP_Factor (OPT_Node *x);
static void OPP_FormalParameters (OPT_Object *firstPar, OPT_Struct *resTyp);
export void OPP_Module (OPT_Node *prog, UINT32 opt);
static void OPP_PointerType (OPT_Struct *typ);
static void OPP_ProcedureDeclaration (OPT_Node *x);
static void OPP_Receiver (INT8 *mode, CHAR *name, OPT_Struct *typ, OPT_Struct *rec);
static void OPP_RecordType (OPT_Struct *typ, OPT_Struct *banned);
static void OPP_ReductionCall (OPT_Node *x, INT8 operation);
static void OPP_ReductionExpression (OPT_Node n);
static BOOLEAN OPP_SameAllIndex (OPT_Node a, OPT_Node b);
static void OPP_Sets (OPT_Node *x);
static void OPP_SimpleExpression (OPT_Node *x);
static void OPP_SkipAllTail (void);
static void OPP_StandProcCall (OPT_Node *x);
static void OPP_StatSeq (OPT_Node *stat);
static void OPP_Term (OPT_Node *x);
static void OPP_Type (OPT_Struct *typ, OPT_Struct *banned);
static void OPP_TypeDecl (OPT_Struct *typ, OPT_Struct *banned);
static BOOLEAN OPP_UnitIndex (OPT_Node n, OPT_Object range, INT64 *offset);
static BOOLEAN OPP_UsesRange (OPT_Node n, OPT_Object range);
static void OPP_err (INT16 n);
static void OPP_qualident (OPT_Object *id);
static void OPP_selector (OPT_Node *x);


static void OPP_err (INT16 n)
{
	OPM_err(n);
}

static void OPP_CheckSym (INT16 s)
{
	if ((INT16)OPP_sym == s) {
		OPS_Get(&OPP_sym);
	} else {
		OPM_err(s);
	}
}

static void OPP_qualident (OPT_Object *id)
{
	OPT_Object obj = NIL;
	INT8 lev;
	OPT_Find(&obj);
	if ((((((obj != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 40, 26, 1000))->mode == 8)) && (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 41, 14, 1035))->adr == 33 || ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 41, 40, 1061))->adr == 34))) && !__IN(23, OPM_Options, 32))) {
		obj = NIL;
	}
	OPS_Get(&OPP_sym);
	if ((((OPP_sym == 18 && obj != NIL)) && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 44, 47, 1207))->mode == 11)) {
		OPS_Get(&OPP_sym);
		if (OPP_sym == 38) {
			OPT_FindImport(obj, &obj);
			OPS_Get(&OPP_sym);
		} else {
			OPP_err(38);
			obj = NIL;
		}
	}
	if (obj == NIL) {
		OPP_err(0);
		obj = OPT_NewObj();
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 52, 31, 1445))->mode = 1;
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 52, 53, 1467))->typ = OPT_undftyp;
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 52, 78, 1492))->adr = 0;
	} else {
		lev = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 53, 20, 1522))->mnolev;
		if ((__IN(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 54, 14, 1545))->mode, 0x06, 32) && lev != OPP_level)) {
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 55, 12, 1610))->leaf = 0;
			if (lev > 0) {
				OPB_StaticLink(OPP_level - lev);
			}
		}
	}
	*id = obj;
}

static void OPP_ConstExpression (OPT_Node *x)
{
	OPP_Expression(&*x);
	if (((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 64, 9, 1810))->class != 7) {
		OPP_err(50);
		*x = OPB_NewIntConst(1);
	}
}

static void OPP_CheckMark (INT8 *vis)
{
	OPS_Get(&OPP_sym);
	if (OPP_sym == 1 || OPP_sym == 7) {
		if (OPP_level > 0) {
			OPP_err(47);
		}
		if (OPP_sym == 1) {
			*vis = 1;
		} else {
			*vis = 2;
		}
		OPS_Get(&OPP_sym);
	} else {
		*vis = 0;
	}
}

static void OPP_CheckSysFlag (INT16 *sysflag, INT16 default_)
{
	OPT_Node x = NIL;
	INT64 sf;
	if (OPP_sym == 31) {
		OPS_Get(&OPP_sym);
		if (!OPT_SYSimported) {
			OPP_err(135);
		}
		OPP_ConstExpression(&x);
		if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 85, 11, 2448))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 85, 16, 2453))->form == 4) {
			sf = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 85, 45, 2482))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 85, 53, 2490))->intval;
			if (sf < 0 || sf > 1) {
				OPP_err(220);
				sf = 0;
			}
		} else {
			OPP_err(51);
			sf = 0;
		}
		*sysflag = OPM_Integer(sf);
		OPP_CheckSym(23);
	} else {
		*sysflag = default_;
	}
}

static void OPP_RecordType (OPT_Struct *typ, OPT_Struct *banned)
{
	OPT_Object fld = NIL, first = NIL, last = NIL, base = NIL;
	OPT_Struct ftyp = NIL;
	INT16 sysflag;
	*typ = OPT_NewStr(13, 4);
	((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 97, 53, 2914))->BaseTyp = NIL;
	OPP_CheckSysFlag(&sysflag, -1);
	if (OPP_sym == 30) {
		OPS_Get(&OPP_sym);
		if (OPP_sym == 38) {
			OPP_qualident(&base);
			if ((((OPT_Object)__NIL_AT((ADDRESS)(base), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 103, 17, 3104))->mode == 5 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(base), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 103, 42, 3129))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 103, 47, 3134))->comp == 4)) {
				if (((OPT_Object)__NIL_AT((ADDRESS)(base), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 104, 18, 3177))->typ == *banned) {
					OPP_err(58);
				} else {
					((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(base), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 105, 20, 3224))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 105, 25, 3229))->pvused = 1;
					((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 106, 16, 3262))->BaseTyp = ((OPT_Object)__NIL_AT((ADDRESS)(base), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 106, 33, 3279))->typ;
					((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 106, 43, 3289))->extlev = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(base), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 106, 59, 3305))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 106, 64, 3310))->extlev + 1;
					((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 106, 81, 3327))->sysflag = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(base), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 106, 98, 3344))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 106, 103, 3349))->sysflag;
				}
			} else {
				OPP_err(52);
			}
		} else {
			OPP_err(38);
		}
		OPP_CheckSym(22);
	}
	if (sysflag >= 0) {
		((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 114, 29, 3509))->sysflag = sysflag;
	}
	OPT_OpenScope(0, NIL);
	first = NIL;
	last = NIL;
	for (;;) {
		if (OPP_sym == 38) {
			for (;;) {
				if (OPP_sym == 38) {
					if (((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 120, 19, 3694))->BaseTyp != NIL) {
						OPT_FindField(OPS_name, ((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 121, 42, 3756))->BaseTyp, &fld);
						if (fld != NIL) {
							OPP_err(1);
						}
					}
					OPT_Insert(OPS_name, &fld);
					OPP_CheckMark(&((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 124, 53, 3886))->vis);
					((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 125, 16, 3909))->mode = 4;
					((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 125, 38, 3931))->link = NIL;
					((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 125, 56, 3949))->typ = OPT_undftyp;
					if (first == NIL) {
						first = fld;
					}
					if (last == NIL) {
						((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 127, 35, 4056))->link = fld;
					} else {
						((OPT_Object)__NIL_AT((ADDRESS)(last), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 127, 58, 4079))->link = fld;
					}
					last = fld;
				} else {
					OPP_err(38);
				}
				if (OPP_sym == 19) {
					OPS_Get(&OPP_sym);
				} else if (OPP_sym == 38) {
					OPP_err(19);
				} else {
					break;
				}
			}
			OPP_CheckSym(20);
			OPP_Type(&ftyp, &*banned);
			((OPT_Struct)__NIL_AT((ADDRESS)(ftyp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 137, 13, 4377))->pvused = 1;
			if (((OPT_Struct)__NIL_AT((ADDRESS)(ftyp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 138, 16, 4410))->comp == 3) {
				ftyp = OPT_undftyp;
				OPP_err(88);
			}
			while (first != NIL) {
				((OPT_Object)__NIL_AT((ADDRESS)(first), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 140, 16, 4514))->typ = ftyp;
				first = ((OPT_Object)__NIL_AT((ADDRESS)(first), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 140, 45, 4543))->link;
			}
		}
		if (OPP_sym == 39) {
			OPS_Get(&OPP_sym);
		} else if (OPP_sym == 38) {
			OPP_err(39);
		} else {
			break;
		}
	}
	OPT_CloseScope();
}

static void OPP_ArrayType (OPT_Struct *typ, OPT_Struct *banned)
{
	OPT_Node x = NIL;
	INT64 n;
	INT16 sysflag;
	OPP_CheckSysFlag(&sysflag, 0);
	if (OPP_sym == 25) {
		*typ = OPT_NewStr(13, 3);
		((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 155, 51, 4983))->mno = 0;
		((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 155, 66, 4998))->sysflag = sysflag;
		OPS_Get(&OPP_sym);
		OPP_Type(&((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 156, 29, 5048))->BaseTyp, &*banned);
		((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 157, 10, 5077))->BaseTyp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 157, 19, 5086))->pvused = 1;
		if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 158, 13, 5116))->BaseTyp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 158, 22, 5125))->comp == 3) {
			((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 158, 50, 5153))->n = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 158, 60, 5163))->BaseTyp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 158, 69, 5172))->n + 1;
		} else {
			((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 159, 15, 5194))->n = 0;
		}
	} else {
		*typ = OPT_NewStr(13, 2);
		((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 162, 50, 5271))->sysflag = sysflag;
		OPP_ConstExpression(&x);
		if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 163, 11, 5323))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 163, 16, 5328))->form == 4) {
			n = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 163, 44, 5356))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 163, 52, 5364))->intval;
			if (n <= 0 || n > OPM_MaxIndex) {
				OPP_err(63);
				n = 1;
			}
		} else {
			OPP_err(51);
			n = 1;
		}
		((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 167, 10, 5489))->n = OPM_Longint(n);
		if (OPP_sym == 25) {
			OPS_Get(&OPP_sym);
			OPP_Type(&((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 169, 31, 5569))->BaseTyp, &*banned);
			((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 170, 12, 5600))->BaseTyp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 170, 21, 5609))->pvused = 1;
		} else if (OPP_sym == 19) {
			OPS_Get(&OPP_sym);
			if (OPP_sym != 25) {
				OPP_ArrayType(&((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 172, 57, 5715))->BaseTyp, &*banned);
			}
		} else {
			OPP_err(35);
		}
		if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 175, 13, 5781))->BaseTyp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 175, 22, 5790))->comp == 3) {
			((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 175, 50, 5818))->BaseTyp = OPT_undftyp;
			OPP_err(88);
		}
	}
}

static void OPP_PointerType (OPT_Struct *typ)
{
	OPT_Object id = NIL;
	*typ = OPT_NewStr(11, 1);
	OPP_CheckSysFlag(&((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 181, 68, 6019))->sysflag, 0);
	OPP_CheckSym(28);
	if (OPP_sym == 38) {
		OPT_Find(&id);
		if (id == NIL) {
			if (OPP_nofFwdPtr < 64) {
				OPP_FwdPtr[__X_AT(OPP_nofFwdPtr, 64, (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 185, 48, 6168)] = *typ;
				OPP_nofFwdPtr += 1;
			} else {
				OPP_err(224);
			}
			((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 188, 12, 6249))->link = OPT_NewObj();
			__COPY(OPS_name, ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 188, 54, 6291))->link), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 188, 60, 6297))->name, 256);
			((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 189, 12, 6317))->BaseTyp = OPT_undftyp;
			OPS_Get(&OPP_sym);
		} else {
			OPP_qualident(&id);
			if (((OPT_Object)__NIL_AT((ADDRESS)(id), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 191, 14, 6411))->mode == 5) {
				if (__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(id), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 192, 16, 6448))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 192, 21, 6453))->comp, 0x1c, 32)) {
					((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 193, 16, 6519))->BaseTyp = ((OPT_Object)__NIL_AT((ADDRESS)(id), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 193, 31, 6534))->typ;
				} else {
					((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 194, 19, 6558))->BaseTyp = OPT_undftyp;
					OPP_err(57);
				}
			} else {
				((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 196, 17, 6622))->BaseTyp = OPT_undftyp;
				OPP_err(52);
			}
		}
	} else {
		OPP_Type(&((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 199, 18, 6695))->BaseTyp, &OPT_notyp);
		if (!__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 200, 15, 6732))->BaseTyp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 200, 24, 6741))->comp, 0x1c, 32)) {
			((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 201, 12, 6804))->BaseTyp = OPT_undftyp;
			OPP_err(57);
		}
	}
}

static void OPP_FormalParameters (OPT_Object *firstPar, OPT_Struct *resTyp)
{
	INT8 mode;
	OPT_Object par = NIL, first = NIL, last = NIL, res = NIL;
	OPT_Struct typ = NIL;
	first = NIL;
	last = *firstPar;
	if (OPP_sym == 38 || OPP_sym == 60) {
		for (;;) {
			if (OPP_sym == 60) {
				OPS_Get(&OPP_sym);
				mode = 2;
			} else {
				mode = 1;
			}
			for (;;) {
				if (OPP_sym == 38) {
					OPT_Insert(OPS_name, &par);
					OPS_Get(&OPP_sym);
					if (OPP_sym == 7) {
						if (mode == 2) {
							OPP_err(246);
						}
						OPS_Get(&OPP_sym);
						((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 218, 32, 7451))->mode = 2;
						((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 218, 57, 7476))->vis = 3;
					} else {
						((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 220, 18, 7535))->mode = mode;
						((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 220, 37, 7554))->vis = 0;
					}
					((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 222, 16, 7608))->link = NIL;
					if (first == NIL) {
						first = par;
					}
					if (*firstPar == NIL) {
						*firstPar = par;
					} else {
						((OPT_Object)__NIL_AT((ADDRESS)(last), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 224, 61, 7734))->link = par;
					}
					last = par;
				} else {
					OPP_err(38);
				}
				if (OPP_sym == 19) {
					OPS_Get(&OPP_sym);
				} else if (OPP_sym == 38) {
					OPP_err(19);
				} else if (OPP_sym == 60) {
					OPP_err(19);
					OPS_Get(&OPP_sym);
				} else {
					break;
				}
			}
			OPP_CheckSym(20);
			OPP_Type(&typ, &OPT_notyp);
			if (((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 235, 17, 8102))->comp == 2 || ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 235, 43, 8128))->comp == 4) && ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 236, 16, 8164))->strobj == NIL)) {
				OPP_err(-309);
			}
			if (mode == 1) {
				((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 239, 35, 8251))->pvused = 1;
			}
			while (first != NIL) {
				((OPT_Object)__NIL_AT((ADDRESS)(first), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 241, 35, 8376))->typ = typ;
				first = ((OPT_Object)__NIL_AT((ADDRESS)(first), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 241, 63, 8404))->link;
			}
			if (OPP_sym == 39) {
				OPS_Get(&OPP_sym);
			} else if (OPP_sym == 38) {
				OPP_err(39);
			} else {
				break;
			}
		}
	}
	OPP_CheckSym(22);
	if (OPP_sym == 20) {
		OPS_Get(&OPP_sym);
		*resTyp = OPT_undftyp;
		if (OPP_sym == 38) {
			OPP_qualident(&res);
			if (((OPT_Object)__NIL_AT((ADDRESS)(res), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 252, 15, 8727))->mode == 5) {
				if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(res), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 253, 18, 8766))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 253, 23, 8771))->form < 13) {
					*resTyp = ((OPT_Object)__NIL_AT((ADDRESS)(res), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 253, 120, 8868))->typ;
				} else {
					OPP_err(54);
				}
			} else {
				OPP_err(52);
			}
		} else {
			OPP_err(38);
		}
	} else {
		*resTyp = OPT_notyp;
	}
}

static void OPP_TypeDecl (OPT_Struct *typ, OPT_Struct *banned)
{
	OPT_Object id = NIL;
	*typ = OPT_undftyp;
	if (OPP_sym < 30) {
		OPP_err(12);
		do {
			OPS_Get(&OPP_sym);
		} while (!(OPP_sym >= 30));
	}
	if (OPP_sym == 38) {
		OPP_qualident(&id);
		if (((OPT_Object)__NIL_AT((ADDRESS)(id), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 271, 12, 9298))->mode == 5) {
			if (((OPT_Object)__NIL_AT((ADDRESS)(id), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 272, 14, 9333))->typ == *banned) {
				OPP_err(58);
			} else {
				*typ = ((OPT_Object)__NIL_AT((ADDRESS)(id), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 273, 20, 9385))->typ;
			}
		} else {
			OPP_err(52);
		}
	} else if (OPP_sym == 54) {
		OPS_Get(&OPP_sym);
		OPP_ArrayType(&*typ, &*banned);
	} else if (OPP_sym == 55) {
		OPS_Get(&OPP_sym);
		OPP_RecordType(&*typ, &*banned);
		OPB_Inittd(&OPP_TDinit, &OPP_lastTDinit, *typ);
		OPP_CheckSym(41);
	} else if (OPP_sym == 56) {
		OPS_Get(&OPP_sym);
		OPP_PointerType(&*typ);
	} else if (OPP_sym == 61) {
		OPS_Get(&OPP_sym);
		*typ = OPT_NewStr(12, 1);
		OPP_CheckSysFlag(&((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 285, 80, 9827))->sysflag, 0);
		if (OPP_sym == 30) {
			OPS_Get(&OPP_sym);
			OPT_OpenScope(OPP_level, NIL);
			OPP_FormalParameters(&((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 288, 29, 9950))->link, &((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 288, 40, 9961))->BaseTyp);
			OPT_CloseScope();
		} else {
			((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 289, 15, 10002))->BaseTyp = OPT_notyp;
			((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 289, 42, 10029))->link = NIL;
		}
	} else {
		OPP_err(12);
	}
	for (;;) {
		if (((OPP_sym >= 39 && OPP_sym <= 42) || OPP_sym == 22) || OPP_sym == 64) {
			break;
		}
		OPP_err(15);
		if (OPP_sym == 38) {
			break;
		}
		OPS_Get(&OPP_sym);
	}
}

static void OPP_Type (OPT_Struct *typ, OPT_Struct *banned)
{
	OPP_TypeDecl(&*typ, &*banned);
	if ((((((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 302, 12, 10379))->form == 11 && ((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 302, 40, 10407))->BaseTyp == OPT_undftyp)) && ((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 302, 71, 10438))->strobj == NIL)) {
		OPP_err(0);
	}
}

static void OPP_selector (OPT_Node *x)
{
	OPT_Object obj = NIL, proc = NIL;
	OPT_Node y = NIL;
	OPT_Struct typ = NIL;
	OPS_Name name;
	INT32 pos, indexPos;
	for (;;) {
		pos = OPS_pos;
		if (OPP_sym == 31) {
			OPS_Get(&OPP_sym);
			for (;;) {
				if ((((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 312, 16, 10734))->typ != NIL && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 312, 33, 10751))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 312, 38, 10756))->form == 11)) {
					OPB_DeRef(&*x);
					((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 312, 80, 10798))->pos = pos;
				}
				indexPos = OPS_pos;
				OPP_Expression(&y);
				OPB_Index(&*x, y);
				((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 313, 65, 10881))->pos = indexPos;
				if (OPP_sym == 19) {
					OPS_Get(&OPP_sym);
				} else {
					break;
				}
			}
			OPP_CheckSym(23);
		} else if (OPP_sym == 18) {
			OPS_Get(&OPP_sym);
			if (OPP_sym == 38) {
				__MOVE(OPS_name, name, 256);
				OPS_Get(&OPP_sym);
				if (((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 319, 15, 11129))->typ != NIL) {
					if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 320, 17, 11162))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 320, 22, 11167))->form == 11) {
						OPB_DeRef(&*x);
						((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 320, 63, 11208))->pos = pos;
					}
					if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 321, 17, 11243))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 321, 22, 11248))->comp == 4) {
						OPT_FindField(name, ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 322, 36, 11308))->typ, &obj);
						OPB_Field(&*x, obj);
						((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 322, 69, 11341))->pos = pos;
						if ((obj != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 323, 36, 11390))->mode == 13)) {
							if (OPP_sym == 17) {
								OPS_Get(&OPP_sym);
								y = ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 325, 25, 11511))->left;
								if (((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 326, 23, 11541))->class == 3) {
									y = ((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 326, 55, 11573))->left;
								}
								if (((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 327, 23, 11635))->obj != NIL) {
									proc = OPT_topScope;
									while ((((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 329, 32, 11780))->link != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 329, 53, 11801))->link), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 329, 59, 11807))->mode != 13)) {
										proc = ((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 329, 94, 11842))->left;
									}
									if (((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 330, 29, 11883))->link == NIL || ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 330, 51, 11905))->link), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 330, 57, 11911))->link != ((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 330, 67, 11921))->obj) {
										OPP_err(75);
									}
									typ = ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 331, 29, 11975))->obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 331, 34, 11980))->typ;
									if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 332, 27, 12013))->form == 11) {
										typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 332, 63, 12049))->BaseTyp;
									}
									OPT_FindField(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 333, 36, 12100))->obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 333, 41, 12105))->name, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 333, 52, 12116))->BaseTyp, &proc);
									if (proc != NIL) {
										((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 334, 41, 12174))->subcl = 1;
									} else {
										OPP_err(74);
									}
								} else {
									OPP_err(75);
								}
							}
							if ((((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 338, 24, 12310))->typ != OPT_notyp && OPP_sym != 30)) {
								OPP_err(30);
							}
						}
					} else {
						OPP_err(53);
					}
				} else {
					OPP_err(52);
				}
			} else {
				OPP_err(38);
			}
		} else if (OPP_sym == 17) {
			OPS_Get(&OPP_sym);
			OPB_DeRef(&*x);
			((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 346, 63, 12573))->pos = pos;
		} else if ((((((OPP_sym == 30 && ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 347, 36, 12621))->class < 7)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 347, 62, 12647))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 347, 67, 12652))->form != 12)) && (((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 348, 14, 12689))->obj == NIL || ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 348, 32, 12707))->obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 348, 37, 12712))->mode != 13))) {
			OPS_Get(&OPP_sym);
			if (OPP_sym == 38) {
				OPP_qualident(&obj);
				if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 352, 17, 12834))->mode == 5) {
					OPB_TypTest(&*x, obj, 1);
					((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 352, 67, 12884))->pos = pos;
				} else {
					OPP_err(52);
				}
			} else {
				OPP_err(38);
			}
			OPP_CheckSym(22);
		} else {
			break;
		}
	}
}

static void OPP_Designator (OPT_Node *x)
{
	OPT_Object id = NIL;
	INT32 pos;
	pos = OPS_pos;
	OPP_qualident(&id);
	*x = OPB_NewLeaf(id);
	((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 366, 59, 13201))->pos = pos;
	OPP_selector(&*x);
}

static void OPP_ActualParameters (OPT_Node *aparlist, OPT_Object fpar)
{
	OPT_Node apar = NIL, last = NIL;
	*aparlist = NIL;
	last = NIL;
	if (OPP_sym != 22) {
		for (;;) {
			OPP_Expression(&apar);
			if (fpar != NIL) {
				OPB_Param(apar, fpar);
				OPB_Link(&*aparlist, &last, apar);
				fpar = ((OPT_Object)__NIL_AT((ADDRESS)(fpar), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 376, 23, 13558))->link;
			} else {
				OPP_err(64);
			}
			if (OPP_sym == 19) {
				OPS_Get(&OPP_sym);
			} else if ((30 <= OPP_sym && OPP_sym <= 38)) {
				OPP_err(19);
			} else {
				break;
			}
		}
	}
	if (fpar != NIL) {
		OPP_err(65);
	}
}

static void OPP_StandProcCall (OPT_Node *x)
{
	OPT_Node y = NIL;
	INT8 m;
	INT16 n;
	m = __SHORT(__SHORT(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 390, 27, 13947))->obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 390, 32, 13952))->adr, 32768), 128);
	n = 0;
	if (m == 33 || m == 34) {
		OPP_ReductionCall(&*x, m);
		return;
	}
	if (OPP_sym == 30) {
		OPS_Get(&OPP_sym);
		if (OPP_sym != 22) {
			for (;;) {
				if (n == 0) {
					OPP_Expression(&*x);
					OPB_StPar0(&*x, m);
					n = 1;
				} else if (n == 1) {
					OPP_Expression(&y);
					OPB_StPar1(&*x, y, m);
					n = 2;
				} else {
					OPP_Expression(&y);
					OPB_StParN(&*x, y, m, n);
					n += 1;
				}
				if (OPP_sym == 19) {
					OPS_Get(&OPP_sym);
				} else if ((30 <= OPP_sym && OPP_sym <= 38)) {
					OPP_err(19);
				} else {
					break;
				}
			}
			OPP_CheckSym(22);
		} else {
			OPS_Get(&OPP_sym);
		}
		OPB_StFct(&*x, m, n);
	} else {
		OPP_err(30);
	}
	if ((OPP_level > 0 && (m == 1 || m == 30))) {
		((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 410, 79, 14723))->link), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 410, 85, 14729))->leaf = 0;
	}
}

static void OPP_Element (OPT_Node *x)
{
	OPT_Node y = NIL;
	OPP_Expression(&*x);
	if (OPP_sym == 21) {
		OPS_Get(&OPP_sym);
		OPP_Expression(&y);
		OPB_SetRange(&*x, y);
	} else {
		OPB_SetElem(&*x);
	}
}

static void OPP_Sets (OPT_Node *x)
{
	OPT_Node y = NIL;
	if (OPP_sym != 24) {
		OPP_Element(&*x);
		for (;;) {
			if (OPP_sym == 19) {
				OPS_Get(&OPP_sym);
			} else if ((30 <= OPP_sym && OPP_sym <= 38)) {
				OPP_err(19);
			} else {
				break;
			}
			OPP_Element(&y);
			OPB_Op(6, &*x, y);
		}
	} else {
		*x = OPB_EmptySet();
	}
	OPP_CheckSym(24);
}

static void OPP_Factor (OPT_Node *x)
{
	OPT_Object fpar = NIL;
	OPT_Node apar = NIL;
	if (OPP_sym < 30) {
		OPP_err(13);
		do {
			OPS_Get(&OPP_sym);
		} while (!(OPP_sym >= 30));
	}
	if (OPP_sym == 38) {
		OPP_Designator(&*x);
		if ((((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 447, 12, 15631))->class == 9 && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 447, 37, 15656))->obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 447, 42, 15661))->mode == 8)) {
			OPP_StandProcCall(&*x);
		} else if (OPP_sym == 30) {
			OPS_Get(&OPP_sym);
			OPB_PrepCall(&*x, &fpar);
			OPP_ActualParameters(&apar, fpar);
			OPB_Call(&*x, apar, fpar);
			OPP_CheckSym(22);
			if (OPP_level > 0) {
				((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 453, 39, 15941))->link), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 453, 45, 15947))->leaf = 0;
			}
		}
	} else if (OPP_sym == 35) {
		switch (OPS_numtyp) {
			case 1: 
				*x = OPB_NewIntConst(OPS_intval);
				((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 457, 58, 16091))->typ = OPT_chartyp;
				break;
			case 2: 
				*x = OPB_NewIntConst(OPS_intval);
				break;
			case 3: 
				*x = OPB_NewRealConst(OPS_realval, OPT_realtyp);
				break;
			case 4: 
				*x = OPB_NewRealConst(OPS_lrlval, OPT_lrltyp);
				break;
			default: 
				OPM_LogWStr((CHAR*)"unhandled case in OPP.Factor, OPS.numtyp = ", 44);
				OPM_LogWNum(OPS_numtyp, 0);
				OPM_LogWLn();
				break;
		}
		OPS_Get(&OPP_sym);
	} else if (OPP_sym == 37) {
		*x = OPB_NewString(OPS_str, OPS_intval);
		OPS_Get(&OPP_sym);
	} else if (OPP_sym == 36) {
		*x = OPB_Nil();
		OPS_Get(&OPP_sym);
	} else if (OPP_sym == 30) {
		OPS_Get(&OPP_sym);
		OPP_Expression(&*x);
		OPP_CheckSym(22);
	} else if (OPP_sym == 31) {
		OPS_Get(&OPP_sym);
		OPP_err(30);
		OPP_Expression(&*x);
		OPP_CheckSym(22);
	} else if (OPP_sym == 32) {
		OPS_Get(&OPP_sym);
		OPP_Sets(&*x);
	} else if (OPP_sym == 33) {
		OPS_Get(&OPP_sym);
		OPP_Factor(&*x);
		OPB_MOp(33, &*x);
	} else {
		OPP_err(13);
		OPS_Get(&OPP_sym);
		*x = NIL;
	}
	if (*x == NIL) {
		*x = OPB_NewIntConst(1);
		((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 478, 47, 17035))->typ = OPT_undftyp;
	}
}

static void OPP_Term (OPT_Node *x)
{
	OPT_Node y = NIL;
	INT8 mulop;
	OPP_Factor(&*x);
	while ((1 <= OPP_sym && OPP_sym <= 5)) {
		mulop = OPP_sym;
		OPS_Get(&OPP_sym);
		OPP_Factor(&y);
		OPB_Op(mulop, &*x, y);
	}
}

static void OPP_SimpleExpression (OPT_Node *x)
{
	OPT_Node y = NIL;
	INT8 addop;
	if (OPP_sym == 7) {
		OPS_Get(&OPP_sym);
		OPP_Term(&*x);
		OPB_MOp(7, &*x);
	} else if (OPP_sym == 6) {
		OPS_Get(&OPP_sym);
		OPP_Term(&*x);
		OPB_MOp(6, &*x);
	} else {
		OPP_Term(&*x);
	}
	while ((6 <= OPP_sym && OPP_sym <= 8)) {
		addop = OPP_sym;
		OPS_Get(&OPP_sym);
		OPP_Term(&y);
		OPB_Op(addop, &*x, y);
	}
}

static void OPP_Expression (OPT_Node *x)
{
	OPT_Node y = NIL;
	OPT_Object obj = NIL;
	INT8 relation;
	OPP_SimpleExpression(&*x);
	if ((9 <= OPP_sym && OPP_sym <= 14)) {
		relation = OPP_sym;
		OPS_Get(&OPP_sym);
		OPP_SimpleExpression(&y);
		OPB_Op(relation, &*x, y);
	} else if (OPP_sym == 15) {
		OPS_Get(&OPP_sym);
		OPP_SimpleExpression(&y);
		OPB_In(&*x, y);
	} else if (OPP_sym == 16) {
		OPS_Get(&OPP_sym);
		if (OPP_sym == 38) {
			OPP_qualident(&obj);
			if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 515, 15, 18189))->mode == 5) {
				OPB_TypTest(&*x, obj, 0);
			} else {
				OPP_err(52);
			}
		} else {
			OPP_err(38);
		}
	}
}

static void OPP_Receiver (INT8 *mode, CHAR *name, OPT_Struct *typ, OPT_Struct *rec)
{
	OPT_Object obj = NIL;
	*typ = OPT_undftyp;
	*rec = NIL;
	if (OPP_sym == 60) {
		OPS_Get(&OPP_sym);
		*mode = 2;
	} else {
		*mode = 1;
	}
	__MOVE(OPS_name, name, 256);
	OPP_CheckSym(38);
	OPP_CheckSym(20);
	if (OPP_sym == 38) {
		OPT_Find(&obj);
		OPS_Get(&OPP_sym);
		if (obj == NIL) {
			OPP_err(0);
		} else if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 530, 16, 18740))->mode != 5) {
			OPP_err(72);
		} else {
			*typ = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 531, 22, 18791))->typ;
			*rec = *typ;
			if (((OPT_Struct)__NIL_AT((ADDRESS)(*rec), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 532, 15, 18824))->form == 11) {
				*rec = ((OPT_Struct)__NIL_AT((ADDRESS)(*rec), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 532, 51, 18860))->BaseTyp;
			}
			if (!((((*mode == 1 && ((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 533, 37, 18912))->form == 11)) && ((OPT_Struct)__NIL_AT((ADDRESS)(*rec), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 533, 65, 18940))->comp == 4) || (*mode == 2 && ((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 534, 37, 19000))->comp == 4))) {
				OPP_err(70);
				*rec = NIL;
			}
			if ((*rec != NIL && ((OPT_Struct)__NIL_AT((ADDRESS)(*rec), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 535, 30, 19082))->mno != OPP_level)) {
				OPP_err(72);
				*rec = NIL;
			}
		}
	} else {
		OPP_err(38);
	}
	OPP_CheckSym(22);
	if (*rec == NIL) {
		*rec = OPT_NewStr(13, 4);
		((OPT_Struct)__NIL_AT((ADDRESS)(*rec), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 540, 67, 19262))->BaseTyp = NIL;
	}
}

static BOOLEAN OPP_Extends (OPT_Struct x, OPT_Struct b)
{
	if ((((OPT_Struct)__NIL_AT((ADDRESS)(b), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 545, 10, 19365))->form == 11 && ((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 545, 36, 19391))->form == 11)) {
		b = ((OPT_Struct)__NIL_AT((ADDRESS)(b), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 545, 69, 19424))->BaseTyp;
		x = ((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 545, 86, 19441))->BaseTyp;
	}
	if ((((OPT_Struct)__NIL_AT((ADDRESS)(b), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 546, 10, 19466))->comp == 4 && ((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 546, 35, 19491))->comp == 4)) {
		do {
			x = ((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 547, 20, 19536))->BaseTyp;
		} while (!(x == NIL || x == b));
	}
	return x == b;
}

static struct ProcedureDeclaration__35 {
	OPT_Node *x;
	OPT_Object *proc, *fwd;
	OPS_Name *name;
	INT8 *mode, *vis;
	BOOLEAN *forward;
	struct ProcedureDeclaration__35 *lnk;
} *ProcedureDeclaration__35_s;

static void Body__36 (void);
static void GetCode__38 (void);
static void GetParams__40 (void);
static void TProcDecl__42 (void);

static void GetCode__38 (void)
{
	OPT_ConstExt ext = NIL;
	INT16 n;
	INT64 c;
	ext = OPT_NewExt();
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 561, 32, 19894))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 561, 40, 19902))->ext = ext;
	n = 0;
	if (OPP_sym == 37) {
		while (OPS_str[__X_AT(n, 1024, (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 563, 23, 19977)] != 0x00) {
			if (n < 255) {
				(*((OPT_ConstExt)__NIL_AT((ADDRESS)(ext), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 564, 30, 20017)))[__X_AT(n + 1, 1024, (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 564, 31, 20018)] = OPS_str[__X_AT(n, 1024, (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 564, 47, 20034)];
			}
			n += 1;
		}
		if (n > 255) {
			OPP_err(241);
			n = 255;
		}
		(*((OPT_ConstExt)__NIL_AT((ADDRESS)(ext), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 568, 12, 20131)))[0] = __CHR(n);
		OPS_Get(&OPP_sym);
	} else {
		for (;;) {
			if (OPP_sym == 35) {
				c = OPS_intval;
				n += 1;
				if (c < 0 || c > 255) {
					OPP_err(64);
					c = 1;
					n = 1;
				}
				if (n > 255) {
					OPP_err(241);
					n = 255;
				}
				OPS_Get(&OPP_sym);
				(*((OPT_ConstExt)__NIL_AT((ADDRESS)(ext), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 580, 30, 20616)))[__X_AT(n, 1024, (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 580, 32, 20618)] = __CHR(c);
			}
			if (OPP_sym == 19) {
				OPS_Get(&OPP_sym);
			} else if (OPP_sym == 35) {
				OPP_err(19);
			} else {
				(*((OPT_ConstExt)__NIL_AT((ADDRESS)(ext), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 584, 19, 20765)))[0] = __CHR(n);
				break;
			}
		}
	}
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 588, 16, 20839))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 588, 24, 20847))->setval |= __SETOF(1,64);
}

static void GetParams__40 (void)
{
	((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 593, 11, 20933))->vis = *ProcedureDeclaration__35_s->vis;
	((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 593, 29, 20951))->mode = *ProcedureDeclaration__35_s->mode;
	((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 593, 49, 20971))->typ = OPT_notyp;
	((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 594, 11, 21001))->conval = OPT_NewConst();
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 594, 43, 21033))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 594, 51, 21041))->setval = 0x0;
	if (OPP_sym == 30) {
		OPS_Get(&OPP_sym);
		OPP_FormalParameters(&((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 596, 44, 21131))->link, &((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 596, 56, 21143))->typ);
	}
	if (*ProcedureDeclaration__35_s->fwd != NIL) {
		OPB_CheckParameters(((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 599, 33, 21218))->link, ((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->fwd), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 599, 44, 21229))->link, 1);
		if (((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 600, 16, 21259))->typ != ((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->fwd), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 600, 27, 21270))->typ) {
			OPP_err(117);
		}
		*ProcedureDeclaration__35_s->proc = *ProcedureDeclaration__35_s->fwd;
		OPT_topScope = ((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 601, 42, 21337))->scope;
		if (*ProcedureDeclaration__35_s->mode == 10) {
			((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 602, 38, 21383))->mode = 10;
		}
	}
}

static void Body__36 (void)
{
	OPT_Node procdec = NIL, statseq = NIL;
	INT32 c;
	c = OPM_errpos;
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 610, 16, 21555))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 610, 24, 21563))->setval |= __SETOF(1,64);
	OPP_CheckSym(39);
	OPP_Block(&procdec, &statseq);
	OPB_Enter(&procdec, statseq, *ProcedureDeclaration__35_s->proc);
	*ProcedureDeclaration__35_s->x = procdec;
	((OPT_Node)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 613, 8, 21705))->conval = OPT_NewConst();
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 613, 37, 21734))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 613, 45, 21742))->intval = c;
	if (OPP_sym == 38) {
		if (__STRCMP(OPS_name, ((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 615, 27, 21813))->name) != 0) {
			OPP_err(4);
		}
		OPS_Get(&OPP_sym);
	} else {
		OPP_err(38);
	}
}

static void TProcDecl__42 (void)
{
	OPT_Object baseProc = NIL;
	OPT_Struct objTyp = NIL, recTyp = NIL;
	INT8 objMode;
	OPS_Name objName;
	OPS_Get(&OPP_sym);
	*ProcedureDeclaration__35_s->mode = 13;
	if (OPP_level > 0) {
		OPP_err(73);
	}
	OPP_Receiver(&objMode, objName, &objTyp, &recTyp);
	if (OPP_sym == 38) {
		__MOVE(OPS_name, *ProcedureDeclaration__35_s->name, 256);
		OPP_CheckMark(&*ProcedureDeclaration__35_s->vis);
		OPT_FindField(*ProcedureDeclaration__35_s->name, recTyp, &*ProcedureDeclaration__35_s->fwd);
		OPT_FindField(*ProcedureDeclaration__35_s->name, ((OPT_Struct)__NIL_AT((ADDRESS)(recTyp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 633, 35, 22342))->BaseTyp, &baseProc);
		if ((baseProc != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(baseProc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 634, 40, 22403))->mode != 13)) {
			baseProc = NIL;
		}
		if (*ProcedureDeclaration__35_s->fwd == baseProc) {
			*ProcedureDeclaration__35_s->fwd = NIL;
		}
		if ((*ProcedureDeclaration__35_s->fwd != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->fwd), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 636, 30, 22527))->mnolev != OPP_level)) {
			*ProcedureDeclaration__35_s->fwd = NIL;
		}
		if ((((*ProcedureDeclaration__35_s->fwd != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->fwd), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 637, 30, 22596))->mode == 13)) && !__IN(1, ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->fwd), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 637, 72, 22638))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 637, 80, 22646))->setval, 64))) {
			*ProcedureDeclaration__35_s->proc = OPT_NewObj();
			((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 639, 37, 22762))->leaf = 1;
			if (((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->fwd), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 640, 17, 22794))->vis != *ProcedureDeclaration__35_s->vis) {
				OPP_err(118);
			}
		} else {
			if (*ProcedureDeclaration__35_s->fwd != NIL) {
				OPP_err(1);
				*ProcedureDeclaration__35_s->fwd = NIL;
			}
			OPT_OpenScope(0, NIL);
			((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 643, 46, 22935))->right = ((OPT_Struct)__NIL_AT((ADDRESS)(recTyp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 643, 63, 22952))->link;
			OPT_Insert(*ProcedureDeclaration__35_s->name, &*ProcedureDeclaration__35_s->proc);
			((OPT_Struct)__NIL_AT((ADDRESS)(recTyp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 644, 17, 23000))->link = ((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 644, 39, 23022))->right;
			OPT_CloseScope();
		}
		OPP_level += 1;
		OPT_OpenScope(OPP_level, *ProcedureDeclaration__35_s->proc);
		OPT_Insert(objName, &((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 647, 33, 23141))->link);
		((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 647, 46, 23154))->link), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 647, 52, 23160))->mode = objMode;
		((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 647, 75, 23183))->link), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 647, 81, 23189))->typ = objTyp;
		GetParams__40();
		if (baseProc != NIL) {
			if (objMode != ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(baseProc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 650, 33, 23288))->link), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 650, 39, 23294))->mode || !OPP_Extends(objTyp, ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(baseProc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 650, 75, 23330))->link), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 650, 81, 23336))->typ)) {
				OPP_err(115);
			}
			OPB_CheckParameters(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 651, 35, 23397))->link), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 651, 41, 23403))->link, ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(baseProc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 651, 57, 23419))->link), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 651, 63, 23425))->link, 0);
			if (((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 652, 18, 23458))->typ != ((OPT_Object)__NIL_AT((ADDRESS)(baseProc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 652, 34, 23474))->typ) {
				OPP_err(117);
			}
			if ((((((((OPT_Object)__NIL_AT((ADDRESS)(baseProc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 653, 23, 23522))->vis == 1 && ((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 653, 52, 23551))->vis == 0)) && ((OPT_Struct)__NIL_AT((ADDRESS)(recTyp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 654, 20, 23594))->strobj != NIL)) && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(recTyp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 654, 45, 23619))->strobj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 654, 53, 23627))->vis == 1)) {
				OPP_err(109);
			}
			((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(*ProcedureDeclaration__35_s->proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 656, 20, 23698))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 656, 28, 23706))->setval |= __SETOF(2,64);
		}
		if (!*ProcedureDeclaration__35_s->forward) {
			Body__36();
		}
		OPP_level -= 1;
		OPT_CloseScope();
	} else {
		OPP_err(38);
	}
}

static void OPP_ProcedureDeclaration (OPT_Node *x)
{
	OPT_Object proc = NIL, fwd = NIL;
	OPS_Name name;
	INT8 mode, vis;
	BOOLEAN forward;
	struct ProcedureDeclaration__35 _s;
	_s.x = x;
	_s.proc = &proc;
	_s.fwd = &fwd;
	_s.name = (void*)name;
	_s.mode = &mode;
	_s.vis = &vis;
	_s.forward = &forward;
	_s.lnk = ProcedureDeclaration__35_s;
	ProcedureDeclaration__35_s = &_s;
	proc = NIL;
	forward = 0;
	*x = NIL;
	mode = 6;
	if ((OPP_sym != 38 && OPP_sym != 30)) {
		if (OPP_sym == 1) {
		} else if (OPP_sym == 17) {
			forward = 1;
		} else if (OPP_sym == 6) {
			mode = 10;
		} else if (OPP_sym == 7) {
			mode = 9;
		} else {
			OPP_err(38);
		}
		if ((__IN(mode, 0x0600, 32) && !OPT_SYSimported)) {
			OPP_err(135);
		}
		OPS_Get(&OPP_sym);
	}
	if (OPP_sym == 30) {
		TProcDecl__42();
	} else if (OPP_sym == 38) {
		OPT_Find(&fwd);
		__MOVE(OPS_name, name, 256);
		OPP_CheckMark(&vis);
		if ((vis != 0 && mode == 6)) {
			mode = 7;
		}
		if ((fwd != NIL && (((OPT_Object)__NIL_AT((ADDRESS)(fwd), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 679, 29, 24591))->mnolev != OPP_level || ((OPT_Object)__NIL_AT((ADDRESS)(fwd), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 679, 54, 24616))->mode == 8))) {
			fwd = NIL;
		}
		if ((((fwd != NIL && __IN(((OPT_Object)__NIL_AT((ADDRESS)(fwd), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 680, 28, 24686))->mode, 0xc0, 32))) && !__IN(1, ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(fwd), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 680, 84, 24742))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 680, 92, 24750))->setval, 64))) {
			proc = OPT_NewObj();
			((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 682, 35, 24862))->leaf = 1;
			if (((OPT_Object)__NIL_AT((ADDRESS)(fwd), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 683, 15, 24892))->vis != vis) {
				OPP_err(118);
			}
		} else {
			if (fwd != NIL) {
				OPP_err(1);
				fwd = NIL;
			}
			OPT_Insert(name, &proc);
		}
		if ((mode != 6 && OPP_level > 0)) {
			OPP_err(73);
		}
		OPP_level += 1;
		OPT_OpenScope(OPP_level, proc);
		((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 690, 11, 25144))->link = NIL;
		GetParams__40();
		if (mode == 9) {
			GetCode__38();
		} else if (!forward) {
			Body__36();
		}
		OPP_level -= 1;
		OPT_CloseScope();
	} else {
		OPP_err(38);
	}
	ProcedureDeclaration__35_s = _s.lnk;
}

static void OPP_CaseLabelList (OPT_Node *lab, OPT_Struct LabelTyp, INT16 *n, struct OPP__1 *tab)
{
	OPT_Node x = NIL, y = NIL, lastlab = NIL;
	INT16 i, f;
	INT32 xval, yval;
	*lab = NIL;
	lastlab = NIL;
	for (;;) {
		OPP_ConstExpression(&x);
		f = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 702, 36, 25590))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 702, 41, 25595))->form;
		if (__IN(f, 0x18, 32)) {
			xval = OPM_Longint(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 703, 62, 25664))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 703, 70, 25672))->intval);
		} else {
			OPP_err(61);
			xval = 1;
		}
		if (f == 4) {
			if (!(((OPT_Struct)__NIL_AT((ADDRESS)(LabelTyp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 707, 22, 25770))->form == 4) || ((OPT_Struct)__NIL_AT((ADDRESS)(LabelTyp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 707, 51, 25799))->size < ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 707, 60, 25808))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 707, 64, 25812))->size) {
				OPP_err(60);
			}
		} else if ((INT16)((OPT_Struct)__NIL_AT((ADDRESS)(LabelTyp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 708, 21, 25856))->form != f) {
			OPP_err(60);
		}
		if (OPP_sym == 21) {
			OPS_Get(&OPP_sym);
			OPP_ConstExpression(&y);
			yval = OPM_Longint(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 711, 64, 25983))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 711, 72, 25991))->intval);
			if (((INT16)((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 712, 14, 26015))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 712, 19, 26020))->form != f && !((f == 4 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 712, 53, 26054))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 712, 58, 26059))->form == 4)))) {
				OPP_err(60);
			}
			if (yval < xval) {
				OPP_err(63);
				yval = xval;
			}
		} else {
			yval = xval;
		}
		((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 716, 8, 26194))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 716, 16, 26202))->intval2 = yval;
		i = *n;
		if (i < 128) {
			for (;;) {
				if (i == 0) {
					break;
				}
				if (tab[__X_AT(i - 1, 128, (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 721, 18, 26373)].low <= yval) {
					if (tab[__X_AT(i - 1, 128, (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 722, 20, 26414)].high >= xval) {
						OPP_err(62);
					}
					break;
				}
				tab[__X_AT(i, 128, (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 725, 15, 26498)] = tab[__X_AT(i - 1, 128, (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 725, 25, 26508)];
				i -= 1;
			}
			tab[__X_AT(i, 128, (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 727, 13, 26547)].low = xval;
			tab[__X_AT(i, 128, (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 727, 33, 26567)].high = yval;
			*n += 1;
		} else {
			OPP_err(213);
		}
		OPB_Link(&*lab, &lastlab, x);
		if (OPP_sym == 19) {
			OPS_Get(&OPP_sym);
		} else if (OPP_sym == 35 || OPP_sym == 38) {
			OPP_err(19);
		} else {
			break;
		}
	}
}

static BOOLEAN OPP_UsesRange (OPT_Node n, OPT_Object range)
{
	if (n == NIL) {
		return 0;
	}
	return (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 741, 14, 26950))->obj == range || OPP_UsesRange(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 741, 43, 26979))->left, range)) || OPP_UsesRange(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 741, 72, 27008))->right, range);
}

static void OPP_CheckAllExpression (OPT_Node n)
{
	if (n != NIL) {
		if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 747, 11, 27125))->class == 13) {
			OPP_err(162);
		}
		if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 748, 11, 27174))->class == 31) {
			OPP_err(176);
		}
		if ((__IN(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 749, 12, 27226))->class, 0x1800, 32) && __IN(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 749, 49, 27263))->subcl, 0x06000000, 32))) {
			OPP_err(181);
		}
		if ((((((((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 750, 12, 27323))->class == 0 && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 750, 36, 27347))->obj != NIL)) && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 750, 53, 27364))->obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 750, 58, 27369))->mode == 15)) && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 751, 13, 27406))->obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 751, 18, 27411))->adr == 0)) {
			OPP_err(167);
		}
		OPP_CheckAllExpression(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 752, 27, 27467))->left);
		OPP_CheckAllExpression(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 752, 56, 27496))->right);
		OPP_CheckAllExpression(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 752, 86, 27526))->link);
	}
}

static void OPP_ReductionExpression (OPT_Node n)
{
	if (n != NIL) {
		if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 759, 11, 27653))->class == 13) {
			OPP_err(177);
		}
		if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 760, 11, 27702))->class == 31) {
			OPP_err(176);
		}
		OPP_ReductionExpression(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 761, 28, 27770))->left);
		OPP_ReductionExpression(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 761, 58, 27800))->right);
		OPP_ReductionExpression(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 761, 89, 27831))->link);
	}
}

static void OPP_ReductionCall (OPT_Node *x, INT8 operation)
{
	OPS_Name name;
	OPT_Object id = NIL, owner = NIL;
	OPT_Node low = NIL, high = NIL, range = NIL, value = NIL;
	OPT_Struct typ = NIL;
	INT32 pos;
	pos = OPM_errpos;
	if (OPP_ReductionDepth > 0) {
		OPP_err(176);
	}
	OPP_ReductionDepth += 1;
	OPP_CheckSym(30);
	OPP_CheckSym(31);
	__MOVE(OPS_name, name, 256);
	OPP_CheckSym(38);
	if (OPP_sym == 19) {
		OPP_err(173);
		while ((((((OPP_sym != 9 && OPP_sym != 20)) && OPP_sym != 23)) && OPP_sym != 64)) {
			OPS_Get(&OPP_sym);
		}
	}
	OPP_CheckSym(9);
	OPP_Expression(&low);
	OPP_CheckSym(21);
	OPP_Expression(&high);
	if (OPP_sym == 19) {
		OPP_err(173);
		while ((((OPP_sym != 20 && OPP_sym != 23)) && OPP_sym != 64)) {
			OPS_Get(&OPP_sym);
		}
	}
	OPP_ReductionExpression(low);
	OPP_ReductionExpression(high);
	typ = OPT_inttyp;
	if (((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(low), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 785, 12, 28719))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 785, 17, 28724))->form != 4 || ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(high), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 785, 43, 28750))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 785, 48, 28755))->form != 4) || __IN(((OPT_Node)__NIL_AT((ADDRESS)(low), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 786, 13, 28788))->class, 0x0300, 32)) || __IN(((OPT_Node)__NIL_AT((ADDRESS)(high), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 786, 56, 28831))->class, 0x0300, 32)) {
		OPP_err(179);
		low = OPB_NewIntConst(0);
		high = OPB_NewIntConst(-1);
	} else {
		if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(low), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 789, 13, 28963))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 789, 18, 28968))->size > ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 789, 30, 28980))->size) {
			typ = ((OPT_Node)__NIL_AT((ADDRESS)(low), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 789, 52, 29002))->typ;
		}
		if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(high), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 790, 14, 29026))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 790, 19, 29031))->size > ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 790, 31, 29043))->size) {
			typ = ((OPT_Node)__NIL_AT((ADDRESS)(high), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 790, 54, 29066))->typ;
		}
	}
	OPP_CheckSym(20);
	owner = ((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 793, 26, 29135))->link;
	OPT_OpenScope(OPP_level, NIL);
	((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 793, 73, 29182))->link = owner;
	OPT_Insert(name, &id);
	((OPT_Object)__NIL_AT((ADDRESS)(id), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 794, 29, 29227))->mode = 14;
	((OPT_Object)__NIL_AT((ADDRESS)(id), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 794, 52, 29250))->typ = typ;
	((OPT_Object)__NIL_AT((ADDRESS)(id), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 794, 68, 29266))->x = OPP_AllCounter;
	OPP_AllCounter += 1;
	range = OPT_NewNode(30);
	((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 795, 44, 29345))->obj = id;
	((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 795, 62, 29363))->typ = typ;
	((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 796, 10, 29386))->left = low;
	((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 796, 30, 29406))->right = high;
	OPP_Expression(&value);
	OPP_ReductionExpression(value);
	if (!__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 798, 15, 29488))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 798, 20, 29493))->form, 0x70, 32) || __IN(((OPT_Node)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 799, 15, 29552))->class, 0x0300, 32)) {
		OPP_err(174);
		value = OPB_NewIntConst(0);
	}
	OPT_CloseScope();
	OPP_CheckSym(23);
	OPP_CheckSym(22);
	OPP_ReductionDepth -= 1;
	*x = range;
	OPB_Construct(31, &*x, value);
	((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 802, 6, 29778))->typ = ((OPT_Node)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 802, 20, 29792))->typ;
	((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 802, 28, 29800))->subcl = operation;
	((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 802, 51, 29823))->obj = id;
	((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 803, 6, 29841))->conval = OPT_NewConst();
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 803, 35, 29870))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 803, 43, 29878))->intval = pos;
}

static BOOLEAN OPP_AllDestination (OPT_Node n, OPT_Object range)
{
	if (n == NIL) {
		return 0;
	}
	if ((((((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 809, 10, 30040))->class == 0 && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 809, 34, 30064))->obj != NIL)) && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 809, 51, 30081))->obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 809, 56, 30086))->mode == 15)) {
		return 1;
	} else if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 810, 12, 30137))->class == 4) {
		return OPP_UsesRange(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 811, 25, 30187))->right, range) || OPP_AllDestination(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 811, 60, 30222))->left, range);
	} else if (__IN(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 812, 12, 30248))->class, 0x2c, 32)) {
		return OPP_AllDestination(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 813, 30, 30330))->left, range);
	}
	return 0;
}

static BOOLEAN OPP_UnitIndex (OPT_Node n, OPT_Object range, INT64 *offset)
{
	INT64 c;
	if ((((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 821, 10, 30526))->class == 0 && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 821, 34, 30550))->obj == range)) {
		*offset = 0;
		return 1;
	}
	if ((((((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 822, 10, 30609))->class == 11 && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 822, 34, 30633))->subcl == 20)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 822, 58, 30657))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 822, 63, 30662))->size >= ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 822, 74, 30673))->left), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 822, 80, 30679))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 822, 85, 30684))->size)) {
		return OPP_UnitIndex(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 823, 25, 30721))->left, range, &*offset);
	}
	if ((((((((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 825, 10, 30762))->class == 12 && __IN(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 825, 34, 30786))->subcl, 0xc0, 32))) && ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 826, 11, 30832))->right), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 826, 18, 30839))->class == 7)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 826, 44, 30865))->right), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 826, 51, 30872))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 826, 56, 30877))->form == 4)) {
		c = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 827, 13, 30912))->right), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 827, 20, 30919))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 827, 28, 30927))->intval;
		if (OPP_UnitIndex(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 828, 21, 30957))->left, range, &*offset)) {
			if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 829, 13, 30997))->subcl == 7) {
				if (c == OPM_SignedMinimum(8)) {
					return 0;
				}
				c = -c;
			}
			if ((c > 0 && *offset > OPM_SignedMaximum(8) - c) || (c < 0 && *offset < OPM_SignedMinimum(8) - c)) {
				return 0;
			}
			*offset = *offset + c;
			return 1;
		}
	}
	return 0;
}

static BOOLEAN OPP_AllMultiple (OPT_Node range)
{
	return (((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 843, 18, 31431))->left), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 843, 24, 31437))->class != 7 || ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 843, 55, 31468))->right), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 843, 62, 31475))->class != 7) || ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 844, 13, 31512))->left), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 844, 19, 31518))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 844, 27, 31526))->intval < ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 844, 43, 31542))->right), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 844, 50, 31549))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 844, 58, 31557))->intval;
}

static BOOLEAN OPP_AllInvariant (OPT_Node n)
{
	if (n == NIL) {
		return 1;
	}
	if ((((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 850, 10, 31689))->obj != NIL && __IN(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 850, 27, 31706))->obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 850, 32, 31711))->mode, 0xc000, 32))) {
		return 0;
	}
	return (((OPP_AllInvariant(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 851, 26, 31796))->left) && OPP_AllInvariant(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 851, 50, 31820))->right))) && OPP_AllInvariant(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 851, 75, 31845))->link));
}

static BOOLEAN OPP_AllAffine (OPT_Node n, OPT_Object range)
{
	if ((n == NIL || ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 856, 23, 31968))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 856, 28, 31973))->form != 4) || ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 856, 51, 31996))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 856, 56, 32001))->size < ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 856, 70, 32015))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 856, 75, 32020))->size) {
		return 0;
	}
	if ((((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 857, 10, 32060))->class == 0 && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 857, 34, 32084))->obj == range)) {
		return 1;
	}
	if ((((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 858, 10, 32130))->class == 11 && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 858, 34, 32154))->subcl == 20)) {
		return (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 859, 16, 32194))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 859, 21, 32199))->size >= ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 859, 32, 32210))->left), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 859, 38, 32216))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 859, 43, 32221))->size && OPP_AllAffine(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 859, 64, 32242))->left, range));
	} else if ((((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 860, 13, 32269))->class == 11 && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 860, 37, 32293))->subcl == 7)) {
		return OPP_AllAffine(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 861, 25, 32343))->left, range);
	}
	if ((((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 863, 10, 32376))->class == 12 && __IN(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 863, 34, 32400))->subcl, 0xc0, 32))) {
		return (OPP_AllAffine(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 864, 26, 32464))->left, range) && OPP_AllInvariant(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 864, 57, 32495))->right)) || (OPP_AllInvariant(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 865, 24, 32531))->left) && OPP_AllAffine(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 865, 45, 32552))->right, range));
	}
	return 0;
}

static BOOLEAN OPP_AllInjective (OPT_Node n, OPT_Object range)
{
	while (n != NIL) {
		if ((((((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 873, 12, 32720))->class == 0 && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 873, 36, 32744))->obj != NIL)) && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 873, 53, 32761))->obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 873, 58, 32766))->mode == 15)) {
			return 1;
		}
		if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 874, 11, 32821))->class == 4) {
			if (OPP_AllAffine(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 875, 23, 32869))->right, range)) {
				return 1;
			}
		} else if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 876, 14, 32919))->class != 2) {
			return 0;
		}
		n = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 878, 13, 32981))->left;
	}
	return 0;
}

static OPT_Object OPP_AllRoot (OPT_Node n, BOOLEAN *heap)
{
	*heap = 0;
	while ((n != NIL && __IN(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 886, 25, 33151))->class, 0x14, 32))) {
		if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 887, 11, 33201))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 887, 16, 33206))->sysflag != 0) {
			return NIL;
		}
		n = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 888, 13, 33253))->left;
	}
	if ((n != NIL && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 890, 22, 33290))->class == 3)) {
		if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 891, 11, 33327))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 891, 16, 33332))->sysflag != 0) {
			return NIL;
		}
		*heap = 1;
		n = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 892, 27, 33393))->left;
	}
	if ((((n != NIL && __IN(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 894, 22, 33430))->class, 0x03, 32))) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 894, 62, 33470))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 894, 67, 33475))->sysflag == 0)) {
		return ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 894, 95, 33503))->obj;
	}
	return NIL;
}

static BOOLEAN OPP_AllOwned (OPT_Object obj, BOOLEAN heap)
{
	return (((!heap && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 899, 28, 33635))->mode == 1)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 899, 52, 33659))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 899, 57, 33664))->sysflag == 0);
}

static BOOLEAN OPP_AllSeparate (OPT_Object a, OPT_Object b, BOOLEAN ah, BOOLEAN bh)
{
	if (OPP_AllOwned(a, ah)) {
		if (OPP_AllOwned(b, bh)) {
			return a != b;
		}
		if (bh || (OPP_level > 0 && ((OPT_Object)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 907, 33, 34016))->mnolev == OPP_level)) {
			return 1;
		}
	}
	if (OPP_AllOwned(b, bh)) {
		if (ah || (OPP_level > 0 && ((OPT_Object)__NIL_AT((ADDRESS)(b), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 910, 33, 34125))->mnolev == OPP_level)) {
			return 1;
		}
	}
	return 0;
}

static INT16 OPP_AllPathLength (OPT_Node n)
{
	INT16 length;
	length = 0;
	while (__IN(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 919, 12, 34321))->class, 0x14, 32)) {
		length += 1;
		n = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 919, 70, 34379))->left;
	}
	return length;
}

static OPT_Node OPP_AllPathPart (OPT_Node n, INT16 length, INT16 position)
{
	while (length > position) {
		n = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 925, 38, 34551))->left;
		length -= 1;
	}
	return n;
}

static BOOLEAN OPP_SameAllIndex (OPT_Node a, OPT_Node b)
{
	if (a == NIL || b == NIL) {
		return a == b;
	}
	if ((((OPT_Node)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 932, 10, 34730))->class != ((OPT_Node)__NIL_AT((ADDRESS)(b), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 932, 21, 34741))->class || ((OPT_Node)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 932, 35, 34755))->typ != ((OPT_Node)__NIL_AT((ADDRESS)(b), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 932, 44, 34764))->typ) || ((OPT_Node)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 932, 56, 34776))->obj != ((OPT_Node)__NIL_AT((ADDRESS)(b), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 932, 65, 34785))->obj) {
		return 0;
	}
	if ((__IN(((OPT_Node)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 933, 10, 34824))->class, 0x1800, 32) && ((OPT_Node)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 933, 47, 34861))->subcl != ((OPT_Node)__NIL_AT((ADDRESS)(b), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 933, 58, 34872))->subcl)) {
		return 0;
	}
	if (((OPT_Node)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 934, 9, 34912))->class == 7) {
		if (__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 935, 11, 34948))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 935, 16, 34953))->form, 0x60, 32)) {
			return ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 935, 61, 34998))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 935, 69, 35006))->realval == ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(b), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 935, 82, 35019))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 935, 90, 35027))->realval;
		}
		if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 936, 11, 35052))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 936, 16, 35057))->form == 7) {
			return ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 936, 46, 35087))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 936, 54, 35095))->setval == ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(b), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 936, 66, 35107))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 936, 74, 35115))->setval;
		}
		if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 937, 11, 35139))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 937, 16, 35144))->form == 8) {
			return a == b;
		}
		return ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 938, 15, 35201))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 938, 23, 35209))->intval == ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(b), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 938, 35, 35221))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 938, 43, 35229))->intval;
	}
	return (((OPP_SameAllIndex(((OPT_Node)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 940, 26, 35272))->left, ((OPT_Node)__NIL_AT((ADDRESS)(b), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 940, 35, 35281))->left) && OPP_SameAllIndex(((OPT_Node)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 940, 59, 35305))->right, ((OPT_Node)__NIL_AT((ADDRESS)(b), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 940, 69, 35315))->right))) && OPP_SameAllIndex(((OPT_Node)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 940, 94, 35340))->link, ((OPT_Node)__NIL_AT((ADDRESS)(b), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 940, 103, 35349))->link));
}

static BOOLEAN OPP_AllIndexBounds (OPT_Node n, OPT_Node ranges, INT64 *low, INT64 *high)
{
	INT64 offset;
	if ((((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 946, 10, 35512))->class == 7 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 946, 36, 35538))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 946, 41, 35543))->form == 4)) {
		*low = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 947, 15, 35580))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 947, 23, 35588))->intval;
		*high = *low;
		return 1;
	}
	while (ranges != NIL) {
		if ((((((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(ranges), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 950, 17, 35674))->left), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 950, 23, 35680))->class == 7 && ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(ranges), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 950, 54, 35711))->right), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 950, 61, 35718))->class == 7)) && OPP_UnitIndex(n, ((OPT_Node)__NIL_AT((ADDRESS)(ranges), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 951, 30, 35771))->obj, &offset))) {
			*low = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(ranges), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 952, 22, 35812))->left), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 952, 28, 35818))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 952, 36, 35826))->intval;
			*high = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(ranges), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 952, 60, 35850))->right), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 952, 67, 35857))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 952, 75, 35865))->intval;
			if ((offset > 0 && *high > OPM_SignedMaximum(8) - offset) || (offset < 0 && *low < OPM_SignedMinimum(8) - offset)) {
				return 0;
			}
			*low = *low + offset;
			*high = *high + offset;
			return 1;
		}
		ranges = ((OPT_Node)__NIL_AT((ADDRESS)(ranges), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 957, 23, 36132))->link;
	}
	return 0;
}

static INT16 OPP_AllAccessProof (OPT_Node a, OPT_Node b, OPT_Node ranges)
{
	OPT_Object ar = NIL, br = NIL;
	BOOLEAN ah, bh, tied, shifted;
	INT16 al, bl, common, i;
	OPT_Node ap = NIL, bp = NIL, r = NIL;
	INT64 alo, ahi, blo, bhi, ao, bo;
	ar = OPP_AllRoot(a, &ah);
	br = OPP_AllRoot(b, &bh);
	if (ar == NIL || br == NIL) {
		return 181;
	}
	if (OPP_AllSeparate(ar, br, ah, bh)) {
		return 0;
	}
	if (ar != br || ah != bh) {
		return 181;
	}
	al = OPP_AllPathLength(a);
	bl = OPP_AllPathLength(b);
	common = al;
	if (bl < common) {
		common = bl;
	}
	i = 1;
	while (i <= common) {
		ap = OPP_AllPathPart(a, al, i);
		bp = OPP_AllPathPart(b, bl, i);
		if (((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 976, 12, 36846))->class != ((OPT_Node)__NIL_AT((ADDRESS)(bp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 976, 24, 36858))->class) {
			common = i - 1;
		} else if (((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 977, 15, 36899))->class == 2) {
			if (((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 978, 14, 36938))->obj != ((OPT_Node)__NIL_AT((ADDRESS)(bp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 978, 24, 36948))->obj) {
				return 0;
			}
		} else if ((((OPP_AllIndexBounds(((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 979, 30, 37001))->right, ranges, &alo, &ahi) && OPP_AllIndexBounds(((OPT_Node)__NIL_AT((ADDRESS)(bp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 979, 76, 37047))->right, ranges, &blo, &bhi))) && (ahi < blo || bhi < alo))) {
			return 0;
		}
		i += 1;
	}
	r = ranges;
	while (r != NIL) {
		if (OPP_AllMultiple(r)) {
			tied = 0;
			shifted = 0;
			i = 1;
			while (i <= common) {
				ap = OPP_AllPathPart(a, al, i);
				bp = OPP_AllPathPart(b, bl, i);
				if (((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 991, 16, 37470))->class == 4) {
					if ((OPP_SameAllIndex(((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 992, 31, 37526))->right, ((OPT_Node)__NIL_AT((ADDRESS)(bp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 992, 42, 37537))->right) && OPP_AllAffine(((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 992, 65, 37560))->right, ((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 992, 75, 37570))->obj))) {
						tied = 1;
					}
					if (OPP_UnitIndex(((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 993, 28, 37627))->right, ((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 993, 38, 37637))->obj, &ao)) {
						if (OPP_UnitIndex(((OPT_Node)__NIL_AT((ADDRESS)(bp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 994, 30, 37682))->right, ((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 994, 40, 37692))->obj, &bo)) {
							if (ao != bo) {
								shifted = 1;
							}
						} else if (((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(bp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 996, 23, 37782))->right), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 996, 30, 37789))->class == 7) {
							shifted = 1;
						}
					} else if ((((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 998, 22, 37870))->right), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 998, 29, 37877))->class == 7 && OPP_UnitIndex(((OPT_Node)__NIL_AT((ADDRESS)(bp), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 998, 65, 37913))->right, ((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 998, 75, 37923))->obj, &bo))) {
						shifted = 1;
					}
				}
				i += 1;
			}
			if (!tied) {
				if (shifted) {
					return 166;
				} else {
					return 181;
				}
			}
		}
		r = ((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1007, 13, 38130))->link;
	}
	return 0;
}

static void OPP_CheckAllAddress (OPT_Node n, OPT_Node target, OPT_Node ranges)
{
	if (n == NIL) {
		return;
	}
	if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1017, 9, 38347))->class == 4) {
		OPP_CheckAllAccess(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1018, 23, 38395))->right, target, ranges);
		OPP_CheckAllAddress(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1018, 66, 38438))->left, target, ranges);
	} else if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1019, 12, 38473))->class == 2) {
		OPP_CheckAllAddress(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1019, 55, 38516))->left, target, ranges);
	} else if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1020, 12, 38551))->class == 3) {
		OPP_CheckAllAccess(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1020, 54, 38593))->left, target, ranges);
	}
}

static void OPP_CheckAllAccess (OPT_Node n, OPT_Node target, OPT_Node ranges)
{
	INT16 proof;
	if (n == NIL) {
		return;
	}
	if (__IN(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1028, 9, 38778))->class, 0x7f, 32)) {
		if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1029, 12, 38890))->obj == NIL || !__IN(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1029, 31, 38909))->obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1029, 36, 38914))->mode, 0xc000, 32)) {
			proof = OPP_AllAccessProof(target, n, ranges);
			if (proof != 0) {
				OPP_err(proof);
			}
			OPP_CheckAllAddress(n, target, ranges);
		}
	} else if ((((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1033, 13, 39107))->class == 11 && __IN(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1033, 37, 39131))->subcl, 0x01080000, 32))) {
		OPP_CheckAllAddress(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1034, 24, 39190))->left, target, ranges);
		OPP_CheckAllAccess(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1034, 65, 39231))->right, target, ranges);
	} else {
		OPP_CheckAllAccess(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1036, 23, 39287))->left, target, ranges);
		OPP_CheckAllAccess(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1036, 64, 39328))->right, target, ranges);
	}
	OPP_CheckAllAccess(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1038, 21, 39382))->link, target, ranges);
}

static void OPP_CheckAllAssignments (OPT_Node body, OPT_Node ranges)
{
	OPT_Node s = NIL, other = NIL, range = NIL;
	BOOLEAN multiple, valid;
	range = ranges;
	multiple = 0;
	while (range != NIL) {
		if ((((((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1046, 16, 39635))->left), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1046, 22, 39641))->class == 7 && ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1046, 52, 39671))->right), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1046, 59, 39678))->class == 7)) && ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1047, 17, 39718))->left), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1047, 23, 39724))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1047, 31, 39732))->intval > ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1047, 47, 39748))->right), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1047, 54, 39755))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1047, 62, 39763))->intval)) {
			return;
		}
		multiple = multiple || OPP_AllMultiple(range);
		range = ((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1048, 65, 39854))->link;
	}
	if (!multiple) {
		return;
	}
	s = body;
	while (s != NIL) {
		OPM_errpos = OPM_Longint(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(s), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1053, 34, 39973))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1053, 42, 39981))->intval);
		range = ranges;
		valid = 1;
		while (range != NIL) {
			if (OPP_AllMultiple(range)) {
				if (!OPP_AllDestination(((OPT_Node)__NIL_AT((ADDRESS)(s), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1056, 31, 40116))->left, ((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1056, 44, 40129))->obj)) {
					OPP_err(163);
					valid = 0;
				} else if (!OPP_AllInjective(((OPT_Node)__NIL_AT((ADDRESS)(s), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1057, 32, 40197))->left, ((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1057, 45, 40210))->obj)) {
					OPP_err(180);
					valid = 0;
				}
			}
			range = ((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1060, 23, 40296))->link;
		}
		if ((valid && !((((((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(s), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1062, 22, 40335))->left), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1062, 28, 40341))->class == 0 && ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(s), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1062, 52, 40365))->left), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1062, 58, 40371))->obj != NIL)) && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(s), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1062, 75, 40388))->left), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1062, 81, 40394))->obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1062, 86, 40399))->mode == 15)))) {
			other = body;
			while (other != NIL) {
				OPP_CheckAllAccess(((OPT_Node)__NIL_AT((ADDRESS)(other), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1065, 31, 40510))->left, ((OPT_Node)__NIL_AT((ADDRESS)(s), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1065, 40, 40519))->left, ranges);
				OPP_CheckAllAccess(((OPT_Node)__NIL_AT((ADDRESS)(other), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1065, 77, 40556))->right, ((OPT_Node)__NIL_AT((ADDRESS)(s), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1065, 87, 40566))->left, ranges);
				other = ((OPT_Node)__NIL_AT((ADDRESS)(other), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1066, 25, 40607))->link;
			}
		}
		s = ((OPT_Node)__NIL_AT((ADDRESS)(s), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1069, 13, 40649))->link;
	}
}

static void OPP_SkipAllTail (void)
{
	INT16 depth;
	depth = 0;
	while (OPP_sym != 64) {
		if (OPP_sym == 41) {
			if (depth == 0) {
				return;
			}
			depth -= 1;
		} else if (((((((OPP_sym == 45 || OPP_sym == 46) || OPP_sym == 47) || OPP_sym == 49) || OPP_sym == 50) || OPP_sym == 51) || OPP_sym == 57) || OPP_sym == 65) {
			depth += 1;
		}
		OPS_Get(&OPP_sym);
	}
}

static void OPP_AllLocals (OPT_Object range)
{
	OPT_Object first = NIL, last = NIL, obj = NIL, group = NIL, typeObj = NIL;
	OPT_Struct typ = NIL;
	OPS_Get(&OPP_sym);
	first = NIL;
	last = NIL;
	for (;;) {
		group = NIL;
		for (;;) {
			if (OPP_sym != 38) {
				OPP_err(38);
				break;
			}
			OPT_Insert(OPS_name, &obj);
			OPS_Get(&OPP_sym);
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1097, 12, 41452))->mode = 15;
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1097, 39, 41479))->typ = OPT_undftyp;
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1098, 12, 41512))->x = OPP_AllCounter;
			OPP_AllCounter += 1;
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1098, 51, 41551))->adr = 0;
			if (first == NIL) {
				first = obj;
			} else {
				((OPT_Object)__NIL_AT((ADDRESS)(last), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1099, 51, 41613))->link = obj;
			}
			last = obj;
			if (group == NIL) {
				group = obj;
			}
			if (OPP_sym != 19) {
				break;
			}
			OPS_Get(&OPP_sym);
		}
		OPP_CheckSym(20);
		typ = OPT_inttyp;
		if (OPP_sym == 38) {
			OPP_qualident(&typeObj);
			if (((OPT_Object)__NIL_AT((ADDRESS)(typeObj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1108, 19, 41895))->mode == 5) {
				typ = ((OPT_Object)__NIL_AT((ADDRESS)(typeObj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1108, 55, 41931))->typ;
			} else {
				OPP_err(52);
			}
		} else {
			OPP_err(165);
			while ((((((OPP_sym != 27 && OPP_sym != 39)) && OPP_sym != 41)) && OPP_sym != 64)) {
				OPS_Get(&OPP_sym);
			}
		}
		if (!__IN(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1113, 15, 42117))->form, 0xfe, 32) || ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1113, 53, 42155))->comp != 1) {
			OPP_err(165);
			typ = OPT_inttyp;
		}
		while (group != NIL) {
			((OPT_Object)__NIL_AT((ADDRESS)(group), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1116, 33, 42259))->typ = typ;
			group = ((OPT_Object)__NIL_AT((ADDRESS)(group), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1116, 61, 42287))->link;
		}
		if (OPP_sym != 39) {
			break;
		}
		OPS_Get(&OPP_sym);
	}
	((OPT_Object)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1120, 10, 42380))->link = first;
}

static void OPP_AllStatement (OPT_Node *x)
{
	OPT_Object id = NIL, owner = NIL;
	OPT_Node low = NIL, high = NIL, range = NIL, ranges = NIL, tail = NIL, group = NIL, body = NIL, last = NIL, s = NIL, y = NIL;
	OPT_Struct typ = NIL;
	INT32 pos;
	OPS_Get(&OPP_sym);
	ranges = NIL;
	tail = NIL;
	for (;;) {
		group = NIL;
		for (;;) {
			range = OPT_NewNode(30);
			((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1131, 48, 42733))->obj = OPT_NewObj();
			__MOVE(OPS_name, ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1132, 14, 42769))->obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1132, 19, 42774))->name, 256);
			OPP_CheckSym(38);
			if (group == NIL) {
				group = range;
			} else {
				((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1133, 54, 42868))->subcl = 1;
			}
			OPB_Link(&ranges, &tail, range);
			if (OPP_sym != 19) {
				break;
			}
			OPS_Get(&OPP_sym);
		}
		OPP_CheckSym(9);
		OPP_Expression(&low);
		OPP_CheckSym(21);
		OPP_Expression(&high);
		typ = OPT_inttyp;
		if (((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(low), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1140, 14, 43117))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1140, 19, 43122))->form != 4 || ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(high), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1140, 45, 43148))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1140, 50, 43153))->form != 4) || __IN(((OPT_Node)__NIL_AT((ADDRESS)(low), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1141, 15, 43188))->class, 0x0300, 32)) || __IN(((OPT_Node)__NIL_AT((ADDRESS)(high), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1141, 58, 43231))->class, 0x0300, 32)) {
			OPP_err(164);
			low = OPB_NewIntConst(0);
			high = OPB_NewIntConst(-1);
		} else {
			if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(low), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1144, 15, 43369))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1144, 20, 43374))->size > ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1144, 32, 43386))->size) {
				typ = ((OPT_Node)__NIL_AT((ADDRESS)(low), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1144, 54, 43408))->typ;
			}
			if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(high), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1145, 16, 43434))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1145, 21, 43439))->size > ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1145, 33, 43451))->size) {
				typ = ((OPT_Node)__NIL_AT((ADDRESS)(high), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1145, 56, 43474))->typ;
			}
		}
		range = group;
		while (range != NIL) {
			((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1149, 14, 43557))->typ = typ;
			((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1149, 33, 43576))->left = low;
			((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1149, 53, 43596))->right = high;
			range = ((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1150, 23, 43635))->link;
		}
		if (OPP_sym != 19) {
			break;
		}
		OPS_Get(&OPP_sym);
	}
	owner = ((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1155, 26, 43746))->link;
	OPT_OpenScope(OPP_level, NIL);
	((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1156, 44, 43797))->link = owner;
	range = ranges;
	while (range != NIL) {
		OPT_Insert(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1159, 23, 43882))->obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1159, 28, 43887))->name, &id);
		((OPT_Object)__NIL_AT((ADDRESS)(id), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1159, 43, 43902))->mode = 14;
		((OPT_Object)__NIL_AT((ADDRESS)(id), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1159, 66, 43925))->typ = ((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1159, 80, 43939))->typ;
		((OPT_Object)__NIL_AT((ADDRESS)(id), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1160, 9, 43954))->x = OPP_AllCounter;
		OPP_AllCounter += 1;
		((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1160, 50, 43995))->obj = id;
		range = ((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1160, 77, 44022))->link;
	}
	if (OPP_sym == 51) {
		OPP_AllLocals(((OPT_Node)__NIL_AT((ADDRESS)(ranges), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1162, 44, 44081))->obj);
	}
	OPP_CheckSym(27);
	body = NIL;
	last = NIL;
	for (;;) {
		if (OPP_sym != 38) {
			break;
		}
		pos = OPM_errpos;
		OPP_Designator(&s);
		if (OPP_sym != 34) {
			OPP_err(161);
			OPP_SkipAllTail();
			break;
		}
		OPS_Get(&OPP_sym);
		OPP_Expression(&y);
		if (((OPT_Node)__NIL_AT((ADDRESS)(s), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1171, 11, 44350))->class != 0) {
			OPP_CheckAllExpression(s);
		}
		OPP_CheckAllExpression(y);
		if ((((((OPT_Node)__NIL_AT((ADDRESS)(s), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1173, 12, 44441))->class == 0 && ((OPT_Node)__NIL_AT((ADDRESS)(s), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1173, 36, 44465))->obj != NIL)) && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(s), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1173, 53, 44482))->obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1173, 58, 44487))->mode == 15)) {
			((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(s), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1173, 87, 44516))->obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1173, 92, 44521))->adr = 1;
		}
		OPB_Assign(&s, y);
		((OPT_Node)__NIL_AT((ADDRESS)(s), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1175, 8, 44568))->conval = OPT_NewConst();
		((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(s), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1175, 37, 44597))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1175, 45, 44605))->intval = pos;
		OPB_Link(&body, &last, s);
		if (OPP_sym != 39) {
			break;
		}
		OPS_Get(&OPP_sym);
		if (OPP_sym == 41) {
			OPP_err(161);
		}
	}
	if (OPP_sym != 41) {
		OPP_err(161);
		OPP_SkipAllTail();
	}
	OPP_CheckAllAssignments(body, ranges);
	OPT_CloseScope();
	OPP_CheckSym(41);
	*x = ranges;
	OPB_Construct(29, &*x, body);
}

static struct StatSeq__53 {
	INT32 *pos;
	struct StatSeq__53 *lnk;
} *StatSeq__53_s;

static void CasePart__54 (OPT_Node *x);
static void CheckBool__56 (OPT_Node *x);
static void SetPos__58 (OPT_Node x);

static void CasePart__54 (OPT_Node *x)
{
	INT16 n;
	INT32 low, high;
	BOOLEAN e;
	OPP_CaseTable tab;
	OPT_Node cases = NIL, lab = NIL, y = NIL, lastcase = NIL;
	OPP_Expression(&*x);
	*StatSeq__53_s->pos = OPM_errpos;
	if (((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1196, 12, 45377))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1196, 38, 45403))->class == 9) {
		OPP_err(126);
	} else if (!__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1197, 16, 45453))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1197, 21, 45458))->form, 0x18, 32)) {
		OPP_err(125);
	}
	OPP_CheckSym(25);
	cases = NIL;
	lastcase = NIL;
	n = 0;
	for (;;) {
		if (OPP_sym < 40) {
			OPP_CaseLabelList(&lab, ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1202, 31, 45649))->typ, &n, tab);
			OPP_CheckSym(20);
			OPP_StatSeq(&y);
			OPB_Construct(17, &lab, y);
			OPB_Link(&cases, &lastcase, lab);
		}
		if (OPP_sym == 40) {
			OPS_Get(&OPP_sym);
		} else {
			break;
		}
	}
	if (n > 0) {
		low = tab[0].low;
		high = tab[__X_AT(n - 1, 128, (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1208, 52, 45919)].high;
		if (high - low > 512) {
			OPP_err(209);
		}
	} else {
		low = 1;
		high = 0;
	}
	e = OPP_sym == 42;
	if (e) {
		OPS_Get(&OPP_sym);
		OPP_StatSeq(&y);
	} else {
		y = NIL;
		OPM_Mark(-307, OPM_curpos);
	}
	OPB_Construct(16, &cases, y);
	OPB_Construct(21, &*x, cases);
	((OPT_Node)__NIL_AT((ADDRESS)(cases), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1219, 12, 46312))->conval = OPT_NewConst();
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(cases), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1220, 12, 46351))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1220, 20, 46359))->intval = low;
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(cases), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1220, 42, 46381))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1220, 50, 46389))->intval2 = high;
	if (e) {
		((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(cases), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1221, 22, 46429))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1221, 30, 46437))->setval = 0x02;
	} else {
		((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(cases), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1221, 56, 46463))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1221, 64, 46471))->setval = 0x0;
	}
}

static void SetPos__58 (OPT_Node x)
{
	((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1226, 8, 46561))->conval = OPT_NewConst();
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1226, 37, 46590))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1226, 45, 46598))->intval = *StatSeq__53_s->pos;
}

static void CheckBool__56 (OPT_Node *x)
{
	if (((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1231, 12, 46694))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1231, 38, 46720))->class == 9) {
		OPP_err(126);
		*x = OPB_NewBoolConst(0);
	} else if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1232, 14, 46798))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1232, 19, 46803))->form != 2) {
		OPP_err(120);
		*x = OPB_NewBoolConst(0);
	}
	*StatSeq__53_s->pos = OPM_errpos;
}

static void OPP_StatSeq (OPT_Node *stat)
{
	OPT_Object fpar = NIL, id = NIL, t = NIL, obj = NIL;
	OPT_Struct idtyp = NIL;
	BOOLEAN e;
	OPT_Node s = NIL, x = NIL, y = NIL, z = NIL, apar = NIL, last = NIL, lastif = NIL;
	INT32 pos;
	OPS_Name name;
	struct StatSeq__53 _s;
	_s.pos = &pos;
	_s.lnk = StatSeq__53_s;
	StatSeq__53_s = &_s;
	*stat = NIL;
	last = NIL;
	for (;;) {
		x = NIL;
		if (OPP_sym < 38) {
			OPP_err(14);
			do {
				OPS_Get(&OPP_sym);
			} while (!(OPP_sym >= 38));
		}
		if (OPP_sym == 38) {
			OPP_Designator(&x);
			if (OPP_sym == 34) {
				OPS_Get(&OPP_sym);
				OPP_Expression(&y);
				OPB_Assign(&x, y);
			} else if (OPP_sym == 9) {
				OPP_err(34);
				OPS_Get(&OPP_sym);
				OPP_Expression(&y);
				OPB_Assign(&x, y);
			} else if ((((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1248, 17, 47342))->class == 9 && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1248, 42, 47367))->obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1248, 47, 47372))->mode == 8)) {
				OPP_StandProcCall(&x);
				if ((x != NIL && ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1250, 28, 47452))->typ != OPT_notyp)) {
					OPP_err(55);
				}
			} else {
				OPB_PrepCall(&x, &fpar);
				if (OPP_sym == 30) {
					OPS_Get(&OPP_sym);
					OPP_ActualParameters(&apar, fpar);
					OPP_CheckSym(22);
				} else {
					apar = NIL;
					if (fpar != NIL) {
						OPP_err(65);
					}
				}
				OPB_Call(&x, apar, fpar);
				if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1258, 15, 47772))->typ != OPT_notyp) {
					OPP_err(55);
				}
				if (OPP_level > 0) {
					((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1259, 41, 47849))->link), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1259, 47, 47855))->leaf = 0;
				}
			}
			pos = OPM_errpos;
		} else if (OPP_sym == 45) {
			OPS_Get(&OPP_sym);
			OPP_Expression(&x);
			CheckBool__56(&x);
			OPP_CheckSym(26);
			OPP_StatSeq(&y);
			OPB_Construct(15, &x, y);
			SetPos__58(x);
			lastif = x;
			while (OPP_sym == 43) {
				OPS_Get(&OPP_sym);
				OPP_Expression(&y);
				CheckBool__56(&y);
				OPP_CheckSym(26);
				OPP_StatSeq(&z);
				OPB_Construct(15, &y, z);
				SetPos__58(y);
				OPB_Link(&x, &lastif, y);
			}
			if (OPP_sym == 42) {
				OPS_Get(&OPP_sym);
				OPP_StatSeq(&y);
			} else {
				y = NIL;
			}
			OPB_Construct(20, &x, y);
			OPP_CheckSym(41);
			OPB_OptIf(&x);
			pos = OPM_errpos;
		} else if (OPP_sym == 46) {
			OPS_Get(&OPP_sym);
			CasePart__54(&x);
			OPP_CheckSym(41);
		} else if (OPP_sym == 47) {
			OPS_Get(&OPP_sym);
			OPP_Expression(&x);
			CheckBool__56(&x);
			OPP_CheckSym(27);
			OPP_StatSeq(&y);
			OPB_Construct(22, &x, y);
			OPP_CheckSym(41);
		} else if (OPP_sym == 48) {
			OPS_Get(&OPP_sym);
			OPP_StatSeq(&x);
			if (OPP_sym == 44) {
				OPS_Get(&OPP_sym);
				OPP_Expression(&y);
				CheckBool__56(&y);
			} else {
				OPP_err(44);
			}
			OPB_Construct(23, &x, y);
		} else if (OPP_sym == 65) {
			OPP_AllStatement(&x);
			pos = OPM_errpos;
		} else if (OPP_sym == 49) {
			OPS_Get(&OPP_sym);
			if (OPP_sym == 38) {
				OPP_qualident(&id);
				if (!(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(id), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1287, 18, 49139))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1287, 23, 49144))->form == 4)) {
					OPP_err(68);
				}
				OPP_CheckSym(34);
				OPP_Expression(&y);
				pos = OPM_errpos;
				x = OPB_NewLeaf(id);
				OPB_Assign(&x, y);
				SetPos__58(x);
				OPP_CheckSym(28);
				OPP_Expression(&y);
				pos = OPM_errpos;
				if (((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1291, 15, 49385))->class != 7) {
					__MOVE("@@", name, 3);
					OPT_Insert(name, &t);
					__MOVE("@for", ((OPT_Object)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1292, 49, 49459))->name, 5);
					((OPT_Object)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1293, 14, 49509))->mode = 1;
					((OPT_Object)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1293, 34, 49529))->typ = ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1293, 44, 49539))->left), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1293, 50, 49545))->typ;
					obj = ((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1294, 32, 49583))->scope;
					if (obj == NIL) {
						((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1295, 43, 49634))->scope = t;
					} else {
						while (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1297, 24, 49687))->link != NIL) {
							obj = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1297, 50, 49713))->link;
						}
						((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1298, 18, 49743))->link = t;
					}
					z = OPB_NewLeaf(t);
					OPB_Assign(&z, y);
					SetPos__58(z);
					OPB_Link(&*stat, &last, z);
					y = OPB_NewLeaf(t);
				} else if (!(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1302, 20, 49911))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1302, 25, 49916))->form == 4) || ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1302, 48, 49939))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1302, 52, 49943))->size > ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1302, 61, 49952))->left), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1302, 66, 49957))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1302, 70, 49961))->size) {
					OPP_err(113);
				}
				OPB_Link(&*stat, &last, x);
				if (OPP_sym == 29) {
					OPS_Get(&OPP_sym);
					OPP_ConstExpression(&z);
				} else {
					z = OPB_NewIntConst(1);
				}
				pos = OPM_errpos;
				x = OPB_NewLeaf(id);
				if (((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1307, 15, 50197))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1307, 23, 50205))->intval > 0) {
					OPB_Op(12, &x, y);
				} else if (((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1308, 18, 50262))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1308, 26, 50270))->intval < 0) {
					OPB_Op(14, &x, y);
				} else {
					OPP_err(63);
					OPB_Op(14, &x, y);
				}
				OPP_CheckSym(27);
				OPP_StatSeq(&s);
				y = OPB_NewLeaf(id);
				OPB_StPar1(&y, z, 13);
				SetPos__58(y);
				if (s == NIL) {
					s = y;
				} else {
					z = s;
					while (((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1315, 20, 50559))->link != NIL) {
						z = ((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1315, 42, 50581))->link;
					}
					((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1316, 14, 50607))->link = y;
				}
				OPP_CheckSym(41);
				OPB_Construct(22, &x, s);
			} else {
				OPP_err(38);
			}
		} else if (OPP_sym == 50) {
			OPS_Get(&OPP_sym);
			OPP_LoopLevel += 1;
			OPP_StatSeq(&x);
			OPP_LoopLevel -= 1;
			OPB_Construct(24, &x, NIL);
			OPP_CheckSym(41);
			pos = OPM_errpos;
		} else if (OPP_sym == 51) {
			OPS_Get(&OPP_sym);
			idtyp = NIL;
			x = NIL;
			for (;;) {
				if (OPP_sym == 38) {
					OPP_qualident(&id);
					y = OPB_NewLeaf(id);
					if ((((id != NIL && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(id), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1329, 32, 51118))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1329, 37, 51123))->form == 11)) && (((OPT_Object)__NIL_AT((ADDRESS)(id), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1329, 65, 51151))->mode == 2 || !((OPT_Object)__NIL_AT((ADDRESS)(id), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1329, 92, 51178))->leaf))) {
						OPP_err(245);
					}
					OPP_CheckSym(20);
					if (OPP_sym == 38) {
						OPP_qualident(&t);
						if (((OPT_Object)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1334, 19, 51384))->mode == 5) {
							if (id != NIL) {
								idtyp = ((OPT_Object)__NIL_AT((ADDRESS)(id), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1336, 30, 51468))->typ;
								OPB_TypTest(&y, t, 0);
								((OPT_Object)__NIL_AT((ADDRESS)(id), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1336, 65, 51503))->typ = ((OPT_Object)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1336, 75, 51513))->typ;
							} else {
								OPP_err(130);
							}
						} else {
							OPP_err(52);
						}
					} else {
						OPP_err(38);
					}
				} else {
					OPP_err(38);
				}
				pos = OPM_errpos;
				OPP_CheckSym(27);
				OPP_StatSeq(&s);
				OPB_Construct(15, &y, s);
				SetPos__58(y);
				if (idtyp != NIL) {
					((OPT_Object)__NIL_AT((ADDRESS)(id), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1346, 33, 51840))->typ = idtyp;
					idtyp = NIL;
				}
				if (x == NIL) {
					x = y;
					lastif = x;
				} else {
					OPB_Link(&x, &lastif, y);
				}
				if (OPP_sym == 40) {
					OPS_Get(&OPP_sym);
				} else {
					break;
				}
			}
			e = OPP_sym == 42;
			if (e) {
				OPS_Get(&OPP_sym);
				OPP_StatSeq(&s);
			} else {
				s = NIL;
			}
			OPB_Construct(27, &x, s);
			OPP_CheckSym(41);
			if (e) {
				((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1353, 20, 52197))->subcl = 1;
			}
		} else if (OPP_sym == 52) {
			OPS_Get(&OPP_sym);
			if (OPP_LoopLevel == 0) {
				OPP_err(46);
			}
			OPB_Construct(25, &x, NIL);
			pos = OPM_errpos;
		} else if (OPP_sym == 53) {
			OPS_Get(&OPP_sym);
			if (OPP_sym < 39) {
				OPP_Expression(&x);
			}
			if (OPP_level > 0) {
				OPB_Return(&x, ((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1361, 53, 52536))->link);
			} else {
				OPB_Return(&x, NIL);
			}
			pos = OPM_errpos;
		}
		if (x != NIL) {
			SetPos__58(x);
			OPB_Link(&*stat, &last, x);
		}
		if (OPP_sym == 39) {
			OPS_Get(&OPP_sym);
		} else if ((OPP_sym <= 38 || (45 <= OPP_sym && OPP_sym <= 53)) || OPP_sym == 65) {
			OPP_err(39);
		} else {
			break;
		}
	}
	StatSeq__53_s = _s.lnk;
}

static void OPP_Block (OPT_Node *procdec, OPT_Node *statseq)
{
	OPT_Struct typ = NIL;
	OPT_Object obj = NIL, first = NIL, last = NIL;
	OPT_Node x = NIL, lastdec = NIL;
	INT16 i;
	first = NIL;
	last = NIL;
	OPP_nofFwdPtr = 0;
	for (;;) {
		if (OPP_sym == 58) {
			OPS_Get(&OPP_sym);
			while (OPP_sym == 38) {
				OPT_Insert(OPS_name, &obj);
				OPP_CheckMark(&((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1385, 51, 53283))->vis);
				((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1386, 14, 53304))->typ = OPT_sinttyp;
				((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1386, 39, 53329))->mode = 1;
				if (OPP_sym == 9) {
					OPS_Get(&OPP_sym);
					OPP_ConstExpression(&x);
				} else if (OPP_sym == 34) {
					OPP_err(9);
					OPS_Get(&OPP_sym);
					OPP_ConstExpression(&x);
				} else {
					OPP_err(9);
					x = OPB_NewIntConst(1);
				}
				((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1393, 14, 53650))->mode = 3;
				((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1393, 36, 53672))->typ = ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1393, 46, 53682))->typ;
				((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1393, 56, 53692))->conval = ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1393, 69, 53705))->conval;
				OPP_CheckSym(39);
			}
		}
		if (OPP_sym == 59) {
			OPS_Get(&OPP_sym);
			while (OPP_sym == 38) {
				OPT_Insert(OPS_name, &obj);
				((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1400, 41, 53928))->mode = 5;
				((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1400, 63, 53950))->typ = OPT_undftyp;
				OPP_CheckMark(&((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1401, 24, 53995))->vis);
				if (OPP_sym == 9) {
					if (((((((((__STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1403, 20, 54054))->name, "SHORTINT") == 0 || __STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1404, 20, 54097))->name, "INTEGER") == 0) || __STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1405, 20, 54139))->name, "LONGINT") == 0) || __STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1406, 20, 54181))->name, "HUGEINT") == 0) || __STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1407, 20, 54223))->name, "REAL") == 0) || __STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1408, 20, 54262))->name, "LONGREAL") == 0) || __STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1409, 20, 54305))->name, "SET") == 0) || __STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1410, 20, 54343))->name, "CHAR") == 0) || __STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1411, 20, 54382))->name, "TRUE") == 0) || __STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1411, 44, 54406))->name, "FALSE") == 0) {
						OPM_Mark(-310, OPM_curpos);
					}
					OPS_Get(&OPP_sym);
					OPP_TypeDecl(&((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1414, 38, 54572))->typ, &((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1414, 48, 54582))->typ);
				} else if (OPP_sym == 34 || OPP_sym == 20) {
					OPP_err(9);
					OPS_Get(&OPP_sym);
					OPP_TypeDecl(&((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1416, 53, 54703))->typ, &((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1416, 63, 54713))->typ);
				} else {
					OPP_err(9);
				}
				if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1419, 17, 54780))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1419, 22, 54785))->strobj == NIL) {
					((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1419, 45, 54808))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1419, 50, 54813))->strobj = obj;
				}
				if (__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1420, 17, 54851))->typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1420, 22, 54856))->comp, 0x1c, 32)) {
					i = 0;
					while (i < OPP_nofFwdPtr) {
						typ = OPP_FwdPtr[__X_AT(i, 64, (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1422, 50, 54976)];
						i += 1;
						if (__STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1423, 21, 55008))->link), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1423, 27, 55014))->name, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1423, 39, 55026))->name) == 0) {
							((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1423, 54, 55041))->BaseTyp = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1423, 70, 55057))->typ;
							((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1423, 80, 55067))->link), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1423, 86, 55073))->name[0] = 0x00;
						}
					}
				}
				OPP_CheckSym(39);
			}
		}
		if (OPP_sym == 60) {
			OPS_Get(&OPP_sym);
			while (OPP_sym == 38) {
				for (;;) {
					if (OPP_sym == 38) {
						OPT_Insert(OPS_name, &obj);
						OPP_CheckMark(&((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1434, 55, 55368))->vis);
						((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1435, 18, 55393))->mode = 1;
						((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1435, 40, 55415))->link = NIL;
						((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1435, 58, 55433))->leaf = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1435, 71, 55446))->vis == 0;
						((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1435, 96, 55471))->typ = OPT_undftyp;
						if (first == NIL) {
							first = obj;
						}
						if (last == NIL) {
							((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1437, 46, 55591))->scope = obj;
						} else {
							((OPT_Object)__NIL_AT((ADDRESS)(last), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1437, 70, 55615))->link = obj;
						}
						last = obj;
					} else {
						OPP_err(38);
					}
					if (OPP_sym == 19) {
						OPS_Get(&OPP_sym);
					} else if (OPP_sym == 38) {
						OPP_err(19);
					} else {
						break;
					}
				}
				OPP_CheckSym(20);
				OPP_Type(&typ, &OPT_notyp);
				((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1447, 14, 55934))->pvused = 1;
				if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1448, 17, 55968))->comp == 3) {
					typ = OPT_undftyp;
					OPP_err(88);
				}
				while (first != NIL) {
					((OPT_Object)__NIL_AT((ADDRESS)(first), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1449, 37, 56063))->typ = typ;
					first = ((OPT_Object)__NIL_AT((ADDRESS)(first), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1449, 65, 56091))->link;
				}
				OPP_CheckSym(39);
			}
		}
		if (OPP_sym < 58 || OPP_sym > 60) {
			break;
		}
	}
	i = 0;
	while (i < OPP_nofFwdPtr) {
		if (((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(OPP_FwdPtr[__X_AT(i, 64, (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1457, 17, 56289)]), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1457, 19, 56291))->link), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1457, 25, 56297))->name[0] != 0x00) {
			OPP_err(128);
		}
		OPP_FwdPtr[__X_AT(i, 64, (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1458, 14, 56342)] = NIL;
		i += 1;
	}
	((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1461, 17, 56418))->adr = OPM_errpos;
	*procdec = NIL;
	lastdec = NIL;
	while (OPP_sym == 61) {
		OPS_Get(&OPP_sym);
		OPP_ProcedureDeclaration(&x);
		if (x != NIL) {
			if (lastdec == NIL) {
				*procdec = x;
			} else {
				((OPT_Node)__NIL_AT((ADDRESS)(lastdec), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1466, 56, 56630))->link = x;
			}
			lastdec = x;
		}
		OPP_CheckSym(39);
	}
	if (OPP_sym == 57) {
		OPS_Get(&OPP_sym);
		OPP_StatSeq(&*statseq);
	} else {
		*statseq = NIL;
	}
	if ((OPP_level == 0 && OPP_TDinit != NIL)) {
		((OPT_Node)__NIL_AT((ADDRESS)(OPP_lastTDinit), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1475, 17, 56871))->link = *statseq;
		*statseq = OPP_TDinit;
	}
	OPP_CheckSym(41);
}

void OPP_Module (OPT_Node *prog, UINT32 opt)
{
	OPS_Name impName, aliasName;
	OPT_Node procdec = NIL, statseq = NIL;
	INT32 c;
	BOOLEAN done;
	OPS_Init();
	OPP_LoopLevel = 0;
	OPP_AllCounter = 0;
	OPP_ReductionDepth = 0;
	OPP_level = 0;
	OPS_Get(&OPP_sym);
	if (OPP_sym == 63) {
		OPS_Get(&OPP_sym);
	} else {
		OPP_err(16);
	}
	if (OPP_sym == 38) {
		OPM_LogCompiling(OPS_name, 256);
		OPT_Init(OPS_name, opt);
		OPS_Get(&OPP_sym);
		OPP_CheckSym(39);
		if (OPP_sym == 62) {
			OPS_Get(&OPP_sym);
			for (;;) {
				if (OPP_sym == 38) {
					__COPY(OPS_name, aliasName, 256);
					__COPY(aliasName, impName, 256);
					OPS_Get(&OPP_sym);
					if (OPP_sym == 34) {
						OPS_Get(&OPP_sym);
						if (OPP_sym == 38) {
							__COPY(OPS_name, impName, 256);
							OPS_Get(&OPP_sym);
						} else {
							OPP_err(38);
						}
					}
					OPT_Import(aliasName, impName, &done);
				} else {
					OPP_err(38);
				}
				if (OPP_sym == 19) {
					OPS_Get(&OPP_sym);
				} else if (OPP_sym == 38) {
					OPP_err(19);
				} else {
					break;
				}
			}
			OPP_CheckSym(39);
		}
		if (OPM_noerr) {
			OPP_TDinit = NIL;
			OPP_lastTDinit = NIL;
			c = OPM_errpos;
			OPP_Block(&procdec, &statseq);
			OPB_Enter(&procdec, statseq, NIL);
			*prog = procdec;
			((OPT_Node)__NIL_AT((ADDRESS)(*prog), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1509, 13, 58206))->conval = OPT_NewConst();
			((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*prog), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1509, 45, 58238))->conval), (CHAR*)"../../src/compiler/OPP.Mod", 27, (CHAR*)"OPP", 4, 1509, 53, 58246))->intval = c;
			if (OPP_sym == 38) {
				if (__STRCMP(OPS_name, OPT_SelfName) != 0) {
					OPP_err(4);
				}
				OPS_Get(&OPP_sym);
			} else {
				OPP_err(38);
			}
			if (OPP_sym != 18) {
				OPP_err(18);
			}
		}
	} else {
		OPP_err(38);
	}
	OPP_TDinit = NIL;
	OPP_lastTDinit = NIL;
}

static void EnumPtrs(void (*P)(void*))
{
	P(OPP_TDinit);
	P(OPP_lastTDinit);
	__ENUMP(OPP_FwdPtr, 64, P);
}

__TDESC(OPP__1, 1, 0) = {__TDFLDS("", 8), {-8}};

export void *OPP__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(OPB);
	__MODULE_IMPORT(OPM);
	__MODULE_IMPORT(OPS);
	__MODULE_IMPORT(OPT);
	__REGMOD("OPP", EnumPtrs);
	__INITYP(OPP__1, OPP__1, 0);
/* BEGIN */
	__ENDMOD;
}
