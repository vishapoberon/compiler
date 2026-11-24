/* voc 5.4.2 [2026/11/24] for gcc LP64 on gentoo xnrtspaSF */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32

#include "SYSTEM.h"
#include "OPC.h"
#include "OPM.h"
#include "OPS.h"
#include "OPT.h"

typedef
	struct OPV_ExitInfo {
		INT16 level, label;
	} OPV_ExitInfo;

typedef
	struct OPV_GPUValueDesc *OPV_GPUValue;

typedef
	struct OPV_GPUValueDesc {
		OPV_GPUValue next;
		OPT_Node node;
		INT32 number;
		INT64 maximum;
		INT32 maximumPos, rangedPos;
		BOOLEAN array, written, ranged;
	} OPV_GPUValueDesc;

typedef
	struct OPV_ReductionDesc *OPV_Reduction;

typedef
	struct OPV_ReductionDesc {
		OPV_Reduction next;
		OPT_Node node;
		OPV_GPUValue values;
	} OPV_ReductionDesc;


static INT16 OPV_stamp;
static OPV_ExitInfo OPV_exit;
static INT16 OPV_nofExitLabels;
static BOOLEAN OPV_parallelBody;
static OPT_Node OPV_parallelRange;
static BOOLEAN OPV_gpuBody;
static OPT_Node OPV_gpuRange;
static OPV_GPUValue OPV_gpuValues;
static BOOLEAN OPV_reductionBody, OPV_reductionBounds;
static OPV_Reduction OPV_reductions;

export ADDRESS *OPV_ExitInfo__typ;
export ADDRESS *OPV_GPUValueDesc__typ;
export ADDRESS *OPV_ReductionDesc__typ;

static void OPV_ActualPar (OPT_Node n, OPT_Object fp, BOOLEAN receiver, OPT_Node site);
export void OPV_AdrAndSize (OPT_Object topScope);
static void OPV_AllName (OPT_Node range, CHAR *suffix, ADDRESS suffix__len);
static void OPV_AllStat (OPT_Node n, OPT_Object outerProc);
static void OPV_CapturedValue (OPV_GPUValue value);
static void OPV_CaseStat (OPT_Node n, OPT_Object outerProc);
static void OPV_Convert (OPT_Node n, OPT_Struct newtype, INT16 prec);
static void OPV_DeclareAllLocals (OPT_Node range);
static void OPV_DefineTDescs (OPT_Node n);
static BOOLEAN OPV_DirectAllRange (OPT_Node range);
static void OPV_DirectReduction (OPT_Node n);
static void OPV_Entier (OPT_Node n, INT16 prec);
static OPV_Reduction OPV_FindReduction (OPT_Node n);
static void OPV_GPUAllStat (OPT_Node n, OPT_Object outerProc);
static OPV_GPUValue OPV_GPUCapture (OPT_Node n, BOOLEAN written, OPV_GPUValue *values);
static void OPV_GPUCheck (OPT_Node n, OPV_GPUValue *values);
static void OPV_GPUConversion (OPT_Struct from, OPT_Struct to);
static void OPV_GPUDeclarations (OPT_Node range, OPV_GPUValue values);
static void OPV_GPUExpression (OPT_Node n, OPT_Node range, BOOLEAN written, OPV_GPUValue *values);
static OPV_GPUValue OPV_GPUFind (OPV_GPUValue values, OPT_Object obj);
static void OPV_GPUName (OPT_Node range, OPV_GPUValue value, CHAR *suffix, ADDRESS suffix__len);
static void OPV_GPUPragma (OPT_Node range, OPV_GPUValue values, INT8 operation);
static BOOLEAN OPV_GPUScalar (OPT_Struct typ);
static void OPV_GPUValidateBounds (OPT_Node range, OPV_GPUValue values);
static void OPV_GetTProcNum (OPT_Object obj);
static void OPV_IfStat (OPT_Node n, BOOLEAN withtrap, OPT_Object outerProc);
static BOOLEAN OPV_ImplicitReturn (OPT_Node n);
static BOOLEAN OPV_InclusiveAllRange (OPT_Node range);
static void OPV_Index (OPT_Node n, OPT_Node d, INT16 prec, INT16 dim);
export void OPV_Init (void);
static void OPV_InitTDescs (OPT_Node n);
static void OPV_Len (OPT_Node n, INT64 dim);
export void OPV_Module (OPT_Node prog);
static void OPV_MultiAllLoops (OPT_Node range, OPT_Node body, OPT_Node locals, OPT_Object outerProc);
static void OPV_MultiAllStat (OPT_Node n, OPT_Object outerProc);
static void OPV_NewArr (OPT_Node d, OPT_Node x);
static void OPV_ParIntLiteral (INT64 n, INT32 size);
static void OPV_ParallelAllStat (OPT_Node n, OPT_Object outerProc);
static BOOLEAN OPV_ParallelIndexSafe (OPT_Node n);
static void OPV_Pointer (OPT_Node n, INT16 prec, OPT_Node site);
static INT16 OPV_Precedence (INT16 class, INT16 subclass, INT16 form, INT16 comp);
static void OPV_ReductionCall (OPT_Node n);
static void OPV_ReductionCollect (OPT_Node n, OPT_Node range, OPV_GPUValue *values);
static void OPV_ReductionCombine (OPT_Node n);
static void OPV_ReductionHelper (OPV_Reduction item);
static void OPV_ReductionHelpers (OPT_Node n);
static void OPV_ReductionType (OPT_Struct typ);
static BOOLEAN OPV_SideEffects (OPT_Node n);
static void OPV_SizeCast (OPT_Node n, INT32 to);
static void OPV_Stamp (CHAR *s);
static OPT_Object OPV_SuperProc (OPT_Node n);
static void OPV_Traverse (OPT_Object obj, OPT_Object outerScope, BOOLEAN exported);
static void OPV_TraverseRecord (OPT_Struct typ);
static void OPV_TypeOf (OPT_Node n);
static void OPV_design (OPT_Node n, INT16 prec);
static void OPV_expr (OPT_Node n, INT16 prec);
static void OPV_stat (OPT_Node n, OPT_Object outerProc);


void OPV_Init (void)
{
	OPV_stamp = 0;
	OPV_nofExitLabels = 0;
	OPV_parallelBody = 0;
	OPV_parallelRange = NIL;
	OPV_gpuBody = 0;
	OPV_gpuRange = NIL;
	OPV_gpuValues = NIL;
	OPV_reductionBody = 0;
	OPV_reductionBounds = 0;
	OPV_reductions = NIL;
}

static void OPV_GetTProcNum (OPT_Object obj)
{
	INT32 oldPos;
	OPT_Struct typ = NIL;
	OPT_Object redef = NIL;
	oldPos = OPM_errpos;
	OPM_errpos = ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 91, 44, 2726))->scope), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 91, 51, 2733))->adr;
	typ = ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 92, 15, 2754))->link), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 92, 21, 2760))->typ;
	if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 93, 11, 2777))->form == 11) {
		typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 93, 47, 2813))->BaseTyp;
	}
	OPT_FindField(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 94, 22, 2850))->name, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 94, 33, 2861))->BaseTyp, &redef);
	if (redef != NIL) {
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 95, 28, 2907))->adr = __ASHL(__ASHR(((OPT_Object)__NIL_AT((ADDRESS)(redef), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 95, 50, 2929))->adr, 16), 16);
		if (!__IN(2, ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 96, 30, 2987))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 96, 38, 2995))->setval, 64)) {
			OPM_err(119);
		}
	} else {
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 97, 17, 3043))->adr += __ASHL(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 97, 34, 3060))->n, 16);
		((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 97, 47, 3073))->n += 1;
	}
	OPM_errpos = oldPos;
}

static void OPV_TraverseRecord (OPT_Struct typ)
{
	if (!((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 104, 12, 3197))->allocated) {
		if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 105, 13, 3226))->BaseTyp != NIL) {
			OPV_TraverseRecord(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 105, 52, 3265))->BaseTyp);
			((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 105, 67, 3280))->n = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 105, 77, 3290))->BaseTyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 105, 86, 3299))->n;
		}
		((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 106, 11, 3319))->allocated = 1;
		OPV_Traverse(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 106, 44, 3352))->link, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 106, 55, 3363))->strobj, 0);
	}
}

static void OPV_Stamp (CHAR *s)
{
	INT16 i, j, k;
	CHAR n[10];
	OPV_stamp += 1;
	i = 0;
	j = OPV_stamp;
	while (s[__X_AT(i, 256, (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 114, 13, 3550)] != 0x00) {
		i += 1;
	}
	if (i > 25) {
		i = 25;
	}
	s[__X_AT(i, 256, (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 116, 7, 3613)] = '_';
	s[__X_AT(i + 1, 256, (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 116, 20, 3626)] = '_';
	i += 2;
	k = 0;
	do {
		n[__X_AT(k, 10, (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 117, 14, 3671)] = __CHR((int)__MOD(j, 10) + 48);
		j = __DIV(j, 10);
		k += 1;
	} while (!(j == 0));
	do {
		k -= 1;
		s[__X_AT(i, 256, (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 118, 22, 3761)] = n[__X_AT(k, 10, (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 118, 30, 3769)];
		i += 1;
	} while (!(k == 0));
	s[__X_AT(i, 256, (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 119, 7, 3799)] = 0x00;
}

static void OPV_Traverse (OPT_Object obj, OPT_Object outerScope, BOOLEAN exported)
{
	INT16 mode;
	OPT_Object scope = NIL;
	OPT_Struct typ = NIL;
	if (obj != NIL) {
		OPV_Traverse(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 126, 19, 4001))->left, outerScope, exported);
		if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 127, 13, 4044))->name[0] == '@') {
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 127, 37, 4068))->name[0] = '_';
			OPV_Stamp(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 127, 64, 4095))->name);
		}
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 128, 10, 4161))->linkadr = 0;
		mode = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 129, 18, 4206))->mode;
		if ((mode == 5 && (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 130, 34, 4247))->vis != 0) == exported)) {
			typ = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 131, 19, 4304))->typ;
			OPT_TypSize(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 131, 41, 4326))->typ);
			if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 132, 15, 4348))->form == 11) {
				typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 132, 51, 4384))->BaseTyp;
			}
			if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 133, 15, 4414))->comp == 4) {
				OPV_TraverseRecord(typ);
			}
		} else if (mode == 13) {
			OPV_GetTProcNum(obj);
		} else if (mode == 1) {
			OPT_TypSize(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 135, 48, 4561))->typ);
		}
		if (!exported) {
			if ((__IN(mode, 0x60, 32) && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 138, 49, 4676))->mnolev > 0)) {
				OPV_Stamp(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 138, 77, 4704))->name);
			}
			if (__IN(mode, 0x26, 32)) {
				((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 140, 14, 4786))->scope = outerScope;
			} else if (__IN(mode, 0x26c0, 32)) {
				if (((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 142, 17, 4907))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 142, 25, 4915))->setval == 0x0) {
					OPM_err(129);
				}
				scope = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 143, 23, 4975))->scope;
				((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 144, 16, 4999))->leaf = 1;
				__MOVE(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 145, 29, 5043))->name, ((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 145, 16, 5030))->name, 256);
				OPV_Stamp(((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 145, 48, 5062))->name);
				if (mode == 9) {
					((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 146, 39, 5109))->adr = 1;
				}
				if (((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 147, 19, 5169))->mnolev > 1) {
					((OPT_Object)__NIL_AT((ADDRESS)(outerScope), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 147, 47, 5197))->leaf = 0;
				}
				OPV_Traverse(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 148, 24, 5242))->scope), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 148, 31, 5249))->right, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 148, 43, 5261))->scope, 0);
			}
		}
		OPV_Traverse(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 151, 19, 5318))->right, outerScope, exported);
	}
}

void OPV_AdrAndSize (OPT_Object topScope)
{
	__ASSERT(OPT_sinttyp != NIL, 0);
	__ASSERT(OPT_inttyp != NIL, 0);
	__ASSERT(OPT_linttyp != NIL, 0);
	OPM_errpos = ((OPT_Object)__NIL_AT((ADDRESS)(topScope), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 159, 27, 5542))->adr;
	((OPT_Object)__NIL_AT((ADDRESS)(topScope), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 160, 13, 5605))->leaf = 1;
	OPV_Traverse(((OPT_Object)__NIL_AT((ADDRESS)(topScope), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 161, 22, 5642))->right, topScope, 1);
	OPV_Traverse(((OPT_Object)__NIL_AT((ADDRESS)(topScope), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 162, 22, 5746))->right, topScope, 0);
	((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_chartyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 165, 16, 5883))->strobj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 165, 24, 5891))->linkadr = 2;
	((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_cpbytetyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 166, 18, 5939))->strobj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 166, 26, 5947))->linkadr = 2;
	((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_settyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 167, 15, 5990))->strobj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 167, 23, 5998))->linkadr = 2;
	((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_realtyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 168, 16, 6045))->strobj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 168, 24, 6053))->linkadr = 2;
	((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_adrtyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 169, 15, 6098))->strobj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 169, 23, 6106))->linkadr = 2;
	((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_int8typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 170, 16, 6153))->strobj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 170, 24, 6161))->linkadr = 2;
	((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_int16typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 171, 17, 6208))->strobj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 171, 25, 6216))->linkadr = 2;
	((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_int32typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 172, 17, 6262))->strobj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 172, 25, 6270))->linkadr = 2;
	((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_int64typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 173, 17, 6316))->strobj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 173, 25, 6324))->linkadr = 2;
	((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_set32typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 174, 17, 6370))->strobj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 174, 25, 6378))->linkadr = 2;
	((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_set64typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 175, 17, 6424))->strobj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 175, 25, 6432))->linkadr = 2;
	((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_hinttyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 176, 16, 6477))->strobj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 176, 23, 6484))->linkadr = 2;
	((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_lrltyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 177, 15, 6530))->strobj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 177, 23, 6538))->linkadr = 2;
	((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_booltyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 178, 16, 6585))->strobj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 178, 24, 6593))->linkadr = 2;
	((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_bytetyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 179, 16, 6639))->strobj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 179, 24, 6647))->linkadr = 2;
	((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_sysptrtyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 180, 18, 6695))->strobj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 180, 26, 6703))->linkadr = 2;
}

static INT16 OPV_Precedence (INT16 class, INT16 subclass, INT16 form, INT16 comp)
{
	switch (class) {
		case 7: case 0: case 2: case 4: case 9: 
		case 13: case 31: 
			return 10;
			break;
		case 5: 
			if (__IN(3, OPM_Options, 32)) {
				return 10;
			} else {
				return 9;
			}
			break;
		case 1: 
			if (__IN(comp, 0x0c, 32)) {
				return 10;
			} else {
				return 9;
			}
			break;
		case 3: 
			return 9;
			break;
		case 11: 
			switch (subclass) {
				case 33: case 7: case 24: case 29: case 20: 
					return 9;
					break;
				case 16: case 21: case 22: case 23: case 25: 
					return 10;
					break;
				default: 
					OPM_LogWStr((CHAR*)"unhandled case in OPV.Precedence OPT.Nmop, subclass = ", 55);
					OPM_LogWNum(subclass, 0);
					OPM_LogWLn();
					break;
			}
			break;
		case 12: 
			switch (subclass) {
				case 1: 
					if (form == 7) {
						return 4;
					} else {
						return 8;
					}
					break;
				case 2: 
					if (form == 7) {
						return 3;
					} else {
						return 8;
					}
					break;
				case 3: case 4: 
					return 10;
					break;
				case 6: 
					if (form == 7) {
						return 2;
					} else {
						return 7;
					}
					break;
				case 7: 
					if (form == 7) {
						return 4;
					} else {
						return 7;
					}
					break;
				case 11: case 12: case 13: case 14: 
					return 6;
					break;
				case 9: case 10: 
					return 5;
					break;
				case 5: 
					return 1;
					break;
				case 8: 
					return 0;
					break;
				case 19: case 15: case 17: case 18: case 26: 
				case 27: case 28: 
					return 10;
					break;
				default: 
					OPM_LogWStr((CHAR*)"unhandled case in OPV.Precedence OPT.Ndop, subclass = ", 55);
					OPM_LogWNum(subclass, 0);
					OPM_LogWLn();
					break;
			}
			break;
		case 10: 
			return 10;
			break;
		case 8: case 6: 
			return 12;
			break;
		default: 
			OPM_LogWStr((CHAR*)"unhandled case in OPV.Precedence, class = ", 43);
			OPM_LogWNum(class, 0);
			OPM_LogWLn();
			break;
	}
	__RETCHK;
}

static void OPV_Pointer (OPT_Node n, INT16 prec, OPT_Node site)
{
	if (__IN(1, OPM_Options, 32)) {
		OPM_Write('(');
		OPC_PointerCast(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 240, 40, 9391))->typ);
		OPM_WriteString((CHAR*)"__NIL_AT((ADDRESS)(", 20);
		OPV_expr(n, -1);
		OPM_Write(')');
		OPC_SourceLocation(((OPT_Node)__NIL_AT((ADDRESS)(site), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 241, 64, 9502))->pos);
		OPM_WriteString((CHAR*)"))", 3);
	} else {
		OPV_expr(n, prec);
	}
}

static OPV_GPUValue OPV_GPUFind (OPV_GPUValue values, OPT_Object obj)
{
	while ((values != NIL && ((OPT_Node)__NIL_AT((ADDRESS)(((OPV_GPUValue)__NIL_AT((ADDRESS)(values), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 248, 35, 9687))->node), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 248, 41, 9693))->obj != obj)) {
		values = ((OPV_GPUValue)__NIL_AT((ADDRESS)(values), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 248, 73, 9725))->next;
	}
	return values;
}

static void OPV_GPUName (OPT_Node range, OPV_GPUValue value, CHAR *suffix, ADDRESS suffix__len)
{
	__DUP(suffix, suffix__len, CHAR);
	OPC_Ident(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 254, 20, 9876))->obj);
	OPM_WriteString((CHAR*)"__gpu", 6);
	OPM_WriteInt(((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 254, 72, 9928))->number);
	OPM_WriteString(suffix, suffix__len);
	__DEL(suffix);
}

static void OPV_CapturedValue (OPV_GPUValue value)
{
	if ((OPV_reductionBounds && !((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 259, 32, 10062))->array)) {
		OPM_WriteString((CHAR*)"(*", 3);
		OPV_GPUName(OPV_gpuRange, value, (CHAR*)"__ref", 6);
		OPM_Write(')');
	} else {
		OPV_GPUName(OPV_gpuRange, value, (CHAR*)"", 1);
	}
}

static void OPV_Len (OPT_Node n, INT64 dim)
{
	INT64 d;
	OPT_Struct array = NIL;
	OPV_GPUValue value = NIL;
	if (((OPV_gpuBody || OPV_reductionBody) && __IN(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 269, 39, 10380))->class, 0x03, 32))) {
		value = OPV_GPUFind(OPV_gpuValues, ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 270, 36, 10456))->obj);
		if (value != NIL) {
			OPV_GPUName(OPV_gpuRange, value, (CHAR*)"__len", 6);
			return;
		}
	}
	while ((((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 273, 13, 10557))->class == 4 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 273, 39, 10583))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 273, 44, 10588))->comp == 3)) {
		dim += 1;
		n = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 273, 97, 10641))->left;
	}
	if ((((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 274, 10, 10663))->class == 3 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 274, 36, 10689))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 274, 41, 10694))->comp == 3)) {
		d = dim;
		array = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 275, 24, 10743))->typ;
		while (d > 0) {
			array = ((OPT_Struct)__NIL_AT((ADDRESS)(array), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 276, 33, 10782))->BaseTyp;
			d -= 1;
		}
		if (((OPT_Struct)__NIL_AT((ADDRESS)(array), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 277, 12, 10816))->comp == 3) {
			OPV_Pointer(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 278, 18, 10858))->left, 10, n);
			OPM_WriteString((CHAR*)"->len[", 7);
			OPM_WriteInt(dim);
			OPM_Write(']');
		} else {
			OPM_WriteInt(((OPT_Struct)__NIL_AT((ADDRESS)(array), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 280, 27, 10969))->n);
		}
	} else {
		OPC_Len(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 283, 16, 11005))->obj, ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 283, 24, 11013))->typ, dim);
	}
}

static BOOLEAN OPV_SideEffects (OPT_Node n)
{
	if (n != NIL) {
		return (__IN(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 289, 30, 11129))->class, 0x80002000, 32) || OPV_SideEffects(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 289, 83, 11182))->left)) || OPV_SideEffects(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 289, 107, 11206))->right);
	} else {
		return 0;
	}
	__RETCHK;
}

static void OPV_Entier (OPT_Node n, INT16 prec)
{
	if (__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 296, 9, 11329))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 296, 14, 11334))->form, 0x60, 32)) {
		OPM_WriteString((CHAR*)"__ENTIER(", 10);
		OPV_expr(n, -1);
		OPM_Write(')');
	} else {
		OPV_expr(n, prec);
	}
}

static void OPV_SizeCast (OPT_Node n, INT32 to)
{
	if ((to < ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 304, 15, 11562))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 304, 19, 11566))->size && __IN(2, OPM_Options, 32))) {
		OPM_WriteString((CHAR*)"__SHORT", 8);
		if (OPV_SideEffects(n)) {
			OPM_Write('F');
		}
		OPM_Write('(');
		OPV_Entier(n, -1);
		OPM_WriteString((CHAR*)", ", 3);
		OPM_WriteInt(OPM_SignedMaximum(to) + 1);
		OPM_Write(')');
	} else {
		if ((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 309, 12, 11846))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 309, 16, 11850))->size != to && (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 309, 33, 11867))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 309, 37, 11871))->size > 4 || to != 4))) {
			OPM_WriteString((CHAR*)"(INT", 5);
			OPM_WriteInt(__ASHL(to, 3));
			OPM_WriteString((CHAR*)")", 2);
		}
		OPV_Entier(n, 9);
	}
}

static void OPV_Convert (OPT_Node n, OPT_Struct newtype, INT16 prec)
{
	INT16 from, to;
	from = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 318, 18, 12165))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 318, 23, 12170))->form;
	to = ((OPT_Struct)__NIL_AT((ADDRESS)(newtype), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 318, 44, 12191))->form;
	if (to == 7) {
		if (from == 7) {
			OPV_SizeCast(n, ((OPT_Struct)__NIL_AT((ADDRESS)(newtype), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 321, 28, 12308))->size);
		} else {
			OPM_WriteString((CHAR*)"__SETOF(", 9);
			OPV_Entier(n, -1);
			OPM_WriteString((CHAR*)",", 2);
			OPM_WriteInt(__ASHL(((OPT_Struct)__NIL_AT((ADDRESS)(newtype), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 324, 51, 12457))->size, 3));
			OPM_Write(')');
		}
	} else if (to == 4) {
		OPV_SizeCast(n, ((OPT_Struct)__NIL_AT((ADDRESS)(newtype), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 327, 26, 12585))->size);
	} else if (to == 3) {
		if (__IN(2, OPM_Options, 32)) {
			OPM_WriteString((CHAR*)"__CHR", 6);
			if (OPV_SideEffects(n)) {
				OPM_Write('F');
			}
			OPM_Write('(');
			OPV_Entier(n, -1);
			OPM_Write(')');
		} else {
			OPM_WriteString((CHAR*)"(CHAR)", 7);
			OPV_Entier(n, 9);
		}
	} else {
		OPV_expr(n, prec);
	}
}

static void OPV_TypeOf (OPT_Node n)
{
	if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 340, 9, 12969))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 340, 14, 12974))->form == 11) {
		OPM_WriteString((CHAR*)"__TYPEOF(", 10);
		OPV_Pointer(n, -1, n);
		OPM_Write(')');
	} else if (__IN(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 342, 12, 13083))->class, 0x15, 32)) {
		OPC_Andent(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 343, 19, 13188))->typ);
		OPM_WriteString((CHAR*)"__typ", 6);
	} else if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 344, 12, 13234))->class == 3) {
		OPM_WriteString((CHAR*)"__TYPEOF(", 10);
		OPV_Pointer(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 345, 43, 13312))->left, -1, n);
		OPM_Write(')');
	} else if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 346, 12, 13359))->class == 5) {
		OPV_TypeOf(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 347, 15, 13411))->left);
	} else if ((((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 348, 13, 13449))->class == 11 && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 348, 37, 13473))->subcl == 29)) {
		OPC_TypeOf(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 350, 19, 13554))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 350, 25, 13560))->obj);
	} else {
		OPC_TypeOf(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 352, 19, 13613))->obj);
	}
}

static BOOLEAN OPV_ParallelIndexSafe (OPT_Node n)
{
	OPT_Node range = NIL, index = NIL;
	if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 359, 9, 13744))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 359, 15, 13750))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 359, 20, 13755))->comp != 2) {
		return 0;
	}
	index = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 360, 15, 13811))->right;
	while ((((((((((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 361, 17, 13836))->class == 11 && ((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 361, 45, 13864))->subcl == 20)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 362, 15, 13900))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 362, 20, 13905))->form == 4)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 362, 46, 13931))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 362, 52, 13937))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 362, 57, 13942))->form == 4)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 363, 15, 13976))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 363, 20, 13981))->size >= ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 363, 35, 13996))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 363, 41, 14002))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 363, 46, 14007))->size)) {
		index = ((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 363, 71, 14032))->left;
	}
	if (((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 364, 13, 14056))->class != 0) {
		return 0;
	}
	range = OPV_parallelRange;
	while (range != NIL) {
		if (((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 367, 15, 14165))->obj == ((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 367, 28, 14178))->obj) {
			return (((((((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 368, 22, 14210))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 368, 28, 14216))->class == 7 && ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 368, 58, 14246))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 368, 65, 14253))->class == 7)) && ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 369, 17, 14293))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 369, 23, 14299))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 369, 31, 14307))->intval >= 0)) && ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 369, 54, 14330))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 369, 61, 14337))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 369, 69, 14345))->intval < (INT64)((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 369, 81, 14357))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 369, 87, 14363))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 369, 92, 14368))->n);
		}
		range = ((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 371, 21, 14404))->link;
	}
	return 0;
}

static void OPV_Index (OPT_Node n, OPT_Node d, INT16 prec, INT16 dim)
{
	if (((OPV_gpuBody || !__IN(0, OPM_Options, 32)) || (((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 379, 10, 14582))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 379, 17, 14589))->class == 7 && (((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 379, 44, 14616))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 379, 51, 14623))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 379, 59, 14631))->intval == 0 || ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 379, 78, 14650))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 379, 84, 14656))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 379, 89, 14661))->comp != 3))) || OPV_ParallelIndexSafe(n)) {
		OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 381, 13, 14728))->right, prec);
	} else {
		if (OPV_SideEffects(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 383, 23, 14774))->right)) {
			OPM_WriteString((CHAR*)"__XF_AT(", 9);
		} else {
			OPM_WriteString((CHAR*)"__X_AT(", 8);
		}
		OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 384, 13, 14866))->right, -1);
		OPM_WriteString((CHAR*)", ", 3);
		OPV_Len(d, dim);
		OPC_SourceLocation(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 384, 89, 14942))->pos);
		OPM_Write(')');
	}
}

static void OPV_design (OPT_Node n, INT16 prec)
{
	OPT_Object obj = NIL;
	OPT_Struct typ = NIL;
	INT16 class, designPrec, comp;
	OPT_Node d = NIL, x = NIL;
	INT16 dims, i;
	OPV_GPUValue value = NIL;
	INT16 _for__56;
	comp = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 393, 14, 15202))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 393, 19, 15207))->comp;
	obj = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 393, 35, 15223))->obj;
	class = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 393, 52, 15240))->class;
	designPrec = OPV_Precedence(class, ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 394, 38, 15286))->subcl, ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 394, 48, 15296))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 394, 53, 15301))->form, comp);
	if ((((((class == 0 && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 395, 33, 15348))->mnolev > 0)) && (INT16)((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 395, 53, 15368))->mnolev != OPM_level)) && prec == 10)) {
		designPrec = 9;
	}
	if (prec > designPrec) {
		OPM_Write('(');
	}
	if (prec == 11) {
		OPM_Write('*');
	}
	switch (class) {
		case 9: 
			OPC_Ident(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 399, 31, 15639))->obj);
			break;
		case 0: 
			value = NIL;
			if (OPV_gpuBody || OPV_reductionBody) {
				value = OPV_GPUFind(OPV_gpuValues, obj);
			}
			if (value != NIL) {
				OPV_CapturedValue(value);
			} else {
				OPC_CompleteIdent(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 401, 85, 15834))->obj);
			}
			break;
		case 1: 
			value = NIL;
			if (OPV_gpuBody || OPV_reductionBody) {
				value = OPV_GPUFind(OPV_gpuValues, obj);
			}
			if (value != NIL) {
				OPV_CapturedValue(value);
			} else {
				if (!__IN(comp, 0x0c, 32)) {
					OPM_Write('*');
				}
				OPC_CompleteIdent(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 406, 41, 16159))->obj);
			}
			break;
		case 2: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 408, 24, 16212))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 408, 30, 16218))->class == 3) {
				OPV_Pointer(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 408, 65, 16253))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 408, 71, 16259))->left, designPrec, ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 408, 92, 16280))->left);
				OPM_WriteString((CHAR*)"->", 3);
			} else {
				OPV_design(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 409, 33, 16343))->left, designPrec);
				OPM_Write('.');
			}
			OPC_Ident(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 411, 31, 16434))->obj);
			break;
		case 3: 
			if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 412, 24, 16464))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 412, 29, 16469))->comp == 3) {
				OPV_Pointer(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 412, 63, 16503))->left, 10, n);
				OPM_WriteString((CHAR*)"->data", 7);
			} else {
				OPM_Write('*');
				OPV_Pointer(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 413, 52, 16596))->left, designPrec, n);
			}
			break;
		case 4: 
			d = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 415, 26, 16667))->left;
			if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(d), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 416, 24, 16698))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 416, 29, 16703))->comp == 3) {
				dims = 0;
				while (((OPT_Node)__NIL_AT((ADDRESS)(d), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 417, 29, 16767))->class == 4) {
					d = ((OPT_Node)__NIL_AT((ADDRESS)(d), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 417, 59, 16797))->left;
					dims += 1;
				}
				if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 418, 26, 16846))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 418, 31, 16851))->comp == 3) {
					OPM_Write('&');
				}
				OPV_design(d, designPrec);
				OPM_Write('[');
				if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 421, 26, 17011))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 421, 31, 17016))->comp == 3) {
					OPM_Write('(');
				}
				i = dims;
				x = n;
				while (x != d) {
					if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 424, 28, 17192))->left != d) {
						OPV_Index(x, d, 7, i);
						OPM_WriteString((CHAR*)" + ", 4);
						OPV_Len(d, i);
						OPM_WriteString((CHAR*)" * (", 5);
						i -= 1;
					} else {
						OPV_Index(x, d, -1, i);
					}
					x = ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 427, 30, 17405))->left;
				}
				_for__56 = dims;
				i = 1;
				while (i <= _for__56) {
					OPM_Write(')');
					i += 1;
				}
				if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 430, 26, 17528))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 430, 31, 17533))->comp == 3) {
					OPM_Write(')');
					typ = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 434, 48, 17864))->typ;
					while (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 435, 33, 17903))->comp == 3) {
						OPM_WriteString((CHAR*)" * ", 4);
						OPV_Len(d, i);
						i += 1;
						typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 437, 44, 18029))->BaseTyp;
					}
				}
				OPM_Write(']');
			} else {
				OPV_design(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 442, 30, 18191))->left, designPrec);
				OPM_Write('[');
				OPV_Index(n, ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 444, 32, 18288))->left, -1, 0);
				OPM_Write(']');
			}
			break;
		case 5: 
			typ = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 447, 28, 18404))->typ;
			obj = ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 447, 43, 18419))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 447, 49, 18425))->obj;
			if (__IN(3, OPM_Options, 32)) {
				if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 449, 28, 18512))->comp == 4) {
					OPM_WriteString((CHAR*)"__GUARDR(", 10);
					if ((INT16)((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 450, 30, 18597))->mnolev != OPM_level) {
						OPM_WriteStringVar((void*)((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 451, 48, 18708))->scope), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 451, 55, 18715))->name, 256);
						OPM_WriteString((CHAR*)"__curr->", 9);
						OPC_Ident(obj);
					} else {
						OPC_Ident(obj);
					}
				} else {
					if (__IN(1, OPM_Options, 32)) {
						if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 457, 32, 19016))->BaseTyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 457, 41, 19025))->strobj == NIL) {
							OPM_WriteString((CHAR*)"__GUARDAN_AT(", 14);
						} else {
							OPM_WriteString((CHAR*)"__GUARDPN_AT(", 14);
						}
					} else {
						if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 459, 32, 19179))->BaseTyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 459, 41, 19188))->strobj == NIL) {
							OPM_WriteString((CHAR*)"__GUARDA(", 10);
						} else {
							OPM_WriteString((CHAR*)"__GUARDP(", 10);
						}
					}
					OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 461, 30, 19334))->left, -1);
					typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 461, 58, 19362))->BaseTyp;
				}
				OPM_WriteString((CHAR*)", ", 3);
				OPC_Andent(typ);
				OPM_WriteString((CHAR*)", ", 3);
				OPM_WriteInt(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 465, 38, 19543))->extlev);
				if ((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 466, 27, 19580))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 466, 32, 19585))->form == 11 && __IN(1, OPM_Options, 32))) {
					OPC_SourceLocation(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 466, 109, 19662))->pos);
				}
				OPM_Write(')');
			} else {
				if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 469, 28, 19761))->comp == 4) {
					OPM_WriteString((CHAR*)"*(", 3);
					OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 470, 60, 19903))->strobj);
					OPM_WriteString((CHAR*)"*)", 3);
					OPC_CompleteIdent(obj);
				} else {
					OPM_Write('(');
					OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 472, 53, 20062))->strobj);
					OPM_Write(')');
					OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 472, 86, 20095))->left, designPrec);
				}
			}
			break;
		case 6: 
			if (__IN(3, OPM_Options, 32)) {
				if (((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 476, 26, 20241))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 476, 32, 20247))->class == 1) {
					OPM_WriteString((CHAR*)"__GUARDEQR(", 12);
					OPC_CompleteIdent(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 477, 43, 20348))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 477, 49, 20354))->obj);
					OPM_WriteString((CHAR*)", ", 3);
					OPV_TypeOf(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 477, 89, 20394))->left);
				} else {
					if (__IN(1, OPM_Options, 32)) {
						OPM_WriteString((CHAR*)"__GUARDEQPN_AT(", 16);
					} else {
						OPM_WriteString((CHAR*)"__GUARDEQP(", 12);
					}
					OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 480, 30, 20591))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 480, 36, 20597))->left, -1);
				}
				OPM_WriteString((CHAR*)", ", 3);
				OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 482, 57, 20729))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 482, 63, 20735))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 482, 68, 20740))->strobj);
				if ((((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 483, 27, 20777))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 483, 33, 20783))->class != 1 && __IN(1, OPM_Options, 32))) {
					OPC_SourceLocation(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 483, 111, 20861))->pos);
				}
				OPM_Write(')');
			} else {
				OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 486, 28, 20960))->left, -1);
			}
			break;
		case 11: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 488, 24, 21055))->subcl == 29) {
				OPV_design(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 488, 55, 21086))->left, prec);
			}
			break;
		default: 
			OPM_LogWStr((CHAR*)"unhandled case in OPV.design, class = ", 39);
			OPM_LogWNum(class, 0);
			OPM_LogWLn();
			break;
	}
	if (prec > designPrec) {
		OPM_Write(')');
	}
}

static void OPV_ParIntLiteral (INT64 n, INT32 size)
{
	OPM_WriteInt(n);
}

static void OPV_ActualPar (OPT_Node n, OPT_Object fp, BOOLEAN receiver, OPT_Node site)
{
	OPT_Struct typ = NIL, aptyp = NIL;
	INT16 comp, form, mode, prec, dim;
	OPM_Write('(');
	while (n != NIL) {
		typ = ((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 504, 31, 21719))->typ;
		comp = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 505, 18, 21743))->comp;
		form = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 505, 37, 21762))->form;
		mode = ((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 505, 55, 21780))->mode;
		prec = -1;
		if ((((mode == 2 && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 506, 34, 21838))->class == 11)) && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 506, 58, 21862))->subcl == 29)) {
			OPM_Write('(');
			OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 507, 42, 21955))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 507, 47, 21960))->strobj);
			OPM_WriteString((CHAR*)"*)", 3);
			prec = 10;
		}
		if (!__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 509, 13, 22029))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 509, 18, 22034))->comp, 0x0c, 32)) {
			if (mode == 2) {
				if (typ != ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 511, 21, 22128))->typ) {
					OPM_WriteString((CHAR*)"(void*)", 8);
				}
				OPM_Write('&');
				prec = 9;
			} else {
				if ((__IN(comp, 0x0c, 32) && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 514, 52, 22271))->class == 7)) {
					if (comp != 2) {
						OPM_WriteString((CHAR*)"(CHAR*)", 8);
					}
				} else if ((((form == 11 && typ != ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 516, 48, 22443))->typ)) && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 516, 59, 22454))->typ != OPT_niltyp)) {
					OPM_WriteString((CHAR*)"(void*)", 8);
				}
			}
		} else {
			if (((((mode == 2 || ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 522, 40, 22680))->BaseTyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 522, 49, 22689))->form == 13) && typ != ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 522, 79, 22719))->typ)) && prec == -1)) {
				OPM_WriteString((CHAR*)"(void*)", 8);
			}
		}
		if ((((mode == 2 && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 524, 34, 22825))->class == 11)) && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 524, 58, 22849))->subcl == 29)) {
			OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 525, 15, 22887))->left, prec);
		} else if ((form == 4 && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 526, 34, 22962))->class == 7)) {
			OPV_ParIntLiteral(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 527, 24, 23012))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 527, 31, 23019))->intval, ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 527, 41, 23029))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 527, 45, 23033))->size);
		} else if ((((comp == 2 && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 528, 36, 23075))->class == 7)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 528, 62, 23101))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 528, 67, 23106))->form == 8)) {
			OPM_Write('(');
			OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 531, 38, 23289))->strobj);
			OPM_WriteString((CHAR*)"){", 3);
			OPV_expr(n, -1);
			OPM_Write('}');
		} else if ((receiver && form == 11)) {
			OPV_Pointer(n, prec, site);
		} else {
			OPV_expr(n, prec);
		}
		if ((comp == 4 && mode == 2)) {
			OPM_WriteString((CHAR*)", ", 3);
			OPV_TypeOf(n);
		} else if (comp == 3) {
			if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 541, 13, 23632))->class == 7) {
				OPM_WriteString((CHAR*)", ", 3);
				OPV_ParIntLiteral(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 542, 50, 23735))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 542, 57, 23742))->intval2, OPM_AddressSize);
			} else {
				aptyp = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 544, 21, 23802))->typ;
				dim = 0;
				while ((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 545, 21, 23839))->comp == 3 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 545, 48, 23866))->BaseTyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 545, 57, 23875))->form != 1)) {
					OPM_WriteString((CHAR*)", ", 3);
					OPV_Len(n, dim);
					typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 547, 23, 23968))->BaseTyp;
					aptyp = ((OPT_Struct)__NIL_AT((ADDRESS)(aptyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 547, 48, 23993))->BaseTyp;
					dim += 1;
				}
				if ((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 549, 18, 24046))->comp == 3 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 549, 45, 24073))->BaseTyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 549, 54, 24082))->form == 1)) {
					OPM_WriteString((CHAR*)", ", 3);
					while (((OPT_Struct)__NIL_AT((ADDRESS)(aptyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 551, 24, 24165))->comp == 3) {
						OPV_Len(n, dim);
						OPM_WriteString((CHAR*)" * ", 4);
						dim += 1;
						aptyp = ((OPT_Struct)__NIL_AT((ADDRESS)(aptyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 552, 76, 24263))->BaseTyp;
					}
					OPV_ParIntLiteral(((OPT_Struct)__NIL_AT((ADDRESS)(aptyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 555, 32, 24420))->size, OPM_AddressSize);
				}
			}
		}
		n = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 559, 13, 24494))->link;
		fp = ((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 559, 29, 24510))->link;
		receiver = 0;
		if (n != NIL) {
			OPM_WriteString((CHAR*)", ", 3);
		}
	}
	OPM_Write(')');
}

static OPT_Object OPV_SuperProc (OPT_Node n)
{
	OPT_Object obj = NIL;
	OPT_Struct typ = NIL;
	typ = ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 567, 17, 24746))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 567, 24, 24753))->typ;
	if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 568, 11, 24791))->form == 11) {
		typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 568, 47, 24827))->BaseTyp;
	}
	OPT_FindField(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 569, 20, 24862))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 569, 26, 24868))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 569, 31, 24873))->name, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 569, 42, 24884))->BaseTyp, &obj);
	return obj;
}

static void OPV_expr (OPT_Node n, INT16 prec)
{
	INT16 class, subclass, form, exprPrec;
	OPT_Struct typ = NIL;
	OPT_Node l = NIL, r = NIL;
	OPT_Object proc = NIL;
	class = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 583, 15, 25173))->class;
	subclass = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 583, 37, 25195))->subcl;
	form = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 583, 55, 25213))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 583, 60, 25218))->form;
	l = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 584, 11, 25236))->left;
	r = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 584, 25, 25250))->right;
	exprPrec = OPV_Precedence(class, subclass, form, ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 585, 53, 25311))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 585, 58, 25316))->comp);
	if ((exprPrec <= prec && __IN(class, 0x80003ce0, 32))) {
		OPM_Write('(');
	}
	switch (class) {
		case 7: 
			OPC_Constant(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 590, 33, 25549))->conval, form);
			break;
		case 31: 
			OPV_ReductionCall(n);
			break;
		case 10: 
			OPM_WriteString((CHAR*)"__SETRNG(", 10);
			OPV_expr(l, -1);
			OPM_WriteString((CHAR*)", ", 3);
			OPV_expr(r, -1);
			OPM_WriteString((CHAR*)", ", 3);
			OPM_WriteInt(__ASHL(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 594, 57, 25809))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 594, 61, 25813))->size, 3));
			OPM_Write(')');
			break;
		case 11: 
			switch (subclass) {
				case 33: 
					OPM_Write('!');
					OPV_expr(l, exprPrec);
					break;
				case 7: 
					if (form == 7) {
						OPM_Write('~');
					} else {
						OPM_Write('-');
					}
					OPV_expr(l, exprPrec);
					break;
				case 16: 
					typ = ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 600, 40, 26143))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 600, 45, 26148))->typ;
					if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 601, 36, 26190))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 601, 41, 26195))->comp == 4) {
						OPM_WriteString((CHAR*)"__IS(", 6);
						OPC_TypeOf(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 601, 103, 26257))->obj);
					} else {
						OPM_WriteString((CHAR*)"__ISP(", 7);
						OPV_expr(l, -1);
						typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 602, 91, 26354))->BaseTyp;
					}
					OPM_WriteString((CHAR*)", ", 3);
					OPC_Andent(typ);
					OPM_WriteString((CHAR*)", ", 3);
					OPM_WriteInt(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 606, 48, 26575))->extlev);
					OPM_Write(')');
					break;
				case 20: 
					OPV_Convert(l, ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 607, 44, 26644))->typ, exprPrec);
					break;
				case 21: 
					if (OPV_SideEffects(l)) {
						if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 609, 38, 26751))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 609, 43, 26756))->form < 5) {
							if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 610, 40, 26818))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 610, 44, 26822))->size <= 4) {
								OPM_WriteString((CHAR*)"(int)", 6);
							}
							OPM_WriteString((CHAR*)"__ABSF(", 8);
						} else {
							OPM_WriteString((CHAR*)"__ABSFD(", 9);
						}
					} else {
						OPM_WriteString((CHAR*)"__ABS(", 7);
					}
					OPV_expr(l, -1);
					OPM_Write(')');
					break;
				case 22: 
					OPM_WriteString((CHAR*)"__CAP(", 7);
					OPV_expr(l, -1);
					OPM_Write(')');
					break;
				case 23: 
					OPM_WriteString((CHAR*)"__ODD(", 7);
					OPV_expr(l, -1);
					OPM_Write(')');
					break;
				case 24: 
					OPM_WriteString((CHAR*)"(ADDRESS)", 10);
					if (((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 620, 36, 27546))->class == 1) {
						OPC_CompleteIdent(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 620, 82, 27592))->obj);
					} else {
						if ((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 622, 39, 27673))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 622, 44, 27678))->form != 8 && !__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 622, 70, 27704))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 622, 75, 27709))->comp, 0x0c, 32))) {
							OPM_Write('&');
						}
						OPV_expr(l, exprPrec);
					}
					break;
				case 29: 
					if (!__IN(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 625, 38, 27893))->class, 0x17, 32) || (((__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 626, 39, 28005))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 626, 44, 28010))->form, 0x1890, 32) && __IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 627, 39, 28104))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 627, 44, 28109))->form, 0x1890, 32))) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 628, 39, 28203))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 628, 44, 28208))->size == ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 628, 54, 28218))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 628, 59, 28223))->size)) {
						OPM_Write('(');
						OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 630, 67, 28333))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 630, 72, 28338))->strobj);
						OPM_Write(')');
						if (__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 631, 39, 28410))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 631, 44, 28415))->form, 0x1800, 32) || __IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 631, 87, 28458))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 631, 92, 28463))->form, 0x1800, 32)) {
							OPM_WriteString((CHAR*)"(ADDRESS)", 10);
						}
						OPV_expr(l, exprPrec);
					} else {
						OPM_WriteString((CHAR*)"__VAL(", 7);
						OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 637, 45, 28799))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 637, 50, 28804))->strobj);
						OPM_WriteString((CHAR*)", ", 3);
						OPV_expr(l, -1);
						OPM_Write(')');
					}
					break;
				default: 
					OPM_err(200);
					break;
			}
			break;
		case 12: 
			switch (subclass) {
				case 19: 
					OPV_Len(l, ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 643, 39, 29078))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 643, 47, 29086))->intval);
					break;
				case 15: case 17: case 18: case 26: case 27: 
				case 28: case 3: case 4: 
					switch (subclass) {
						case 15: 
							OPM_WriteString((CHAR*)"__IN(", 6);
							break;
						case 17: 
							if (((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 653, 47, 29458))->class == 7) {
								if (((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 654, 49, 29532))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 654, 57, 29540))->intval >= 0) {
									OPM_WriteString((CHAR*)"__ASHL(", 8);
								} else {
									OPM_WriteString((CHAR*)"__ASHR(", 8);
								}
							} else if (OPV_SideEffects(r)) {
								OPM_WriteString((CHAR*)"__ASHF(", 8);
							} else {
								OPM_WriteString((CHAR*)"__ASH(", 7);
							}
							break;
						case 18: 
							OPM_WriteString((CHAR*)"__MASK(", 8);
							break;
						case 26: 
							OPM_WriteString((CHAR*)"__BIT(", 7);
							break;
						case 27: 
							if (((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 662, 47, 30108))->class == 7) {
								if (((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 663, 49, 30182))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 663, 57, 30190))->intval >= 0) {
									OPM_WriteString((CHAR*)"__LSHL(", 8);
								} else {
									OPM_WriteString((CHAR*)"__LSHR(", 8);
								}
							} else {
								OPM_WriteString((CHAR*)"__LSH(", 7);
							}
							break;
						case 28: 
							if (((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 668, 47, 30525))->class == 7) {
								if (((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 669, 49, 30599))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 669, 57, 30607))->intval >= 0) {
									OPM_WriteString((CHAR*)"__ROTL(", 8);
								} else {
									OPM_WriteString((CHAR*)"__ROTR(", 8);
								}
							} else {
								OPM_WriteString((CHAR*)"__ROT(", 7);
							}
							break;
						case 3: 
							if (OPV_SideEffects(n)) {
								if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 675, 49, 31009))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 675, 53, 31013))->size <= 4) {
									OPM_WriteString((CHAR*)"(int)", 6);
								}
								OPM_WriteString((CHAR*)"__DIVF(", 8);
							} else {
								OPM_WriteString((CHAR*)"__DIV(", 7);
							}
							break;
						case 4: 
							if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 679, 47, 31306))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 679, 51, 31310))->size <= 4) {
								OPM_WriteString((CHAR*)"(int)", 6);
							}
							if (OPV_SideEffects(n)) {
								OPM_WriteString((CHAR*)"__MODF(", 8);
							} else {
								OPM_WriteString((CHAR*)"__MOD(", 7);
							}
							break;
						default: 
							OPM_LogWStr((CHAR*)"unhandled case in OPV.expr, subclass = ", 40);
							OPM_LogWNum(subclass, 0);
							OPM_LogWLn();
							break;
					}
					OPV_expr(l, -1);
					OPM_WriteString((CHAR*)", ", 3);
					if ((((__IN(subclass, 0x18020000, 32) && ((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 687, 80, 31924))->class == 7)) && ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 687, 106, 31950))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 687, 114, 31958))->intval < 0)) {
						OPM_WriteInt(-((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 688, 48, 32024))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 688, 56, 32032))->intval);
					} else {
						OPV_expr(r, -1);
					}
					if (__IN(subclass, 0x18008000, 32)) {
						OPM_WriteString((CHAR*)", ", 3);
						if (subclass == 15) {
							OPM_WriteInt(__ASHL(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 693, 73, 32334))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 693, 77, 32338))->size, 3));
						} else {
							OPM_WriteInt(__ASHL(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 693, 105, 32366))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 693, 109, 32370))->size, 3));
						}
					}
					OPM_Write(')');
					break;
				case 9: case 10: case 11: case 12: case 13: 
				case 14: 
					if (__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 697, 35, 32532))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 697, 40, 32537))->form, 0x2100, 32)) {
						OPM_WriteString((CHAR*)"__STRCMP(", 10);
						OPV_expr(l, -1);
						OPM_WriteString((CHAR*)", ", 3);
						OPV_expr(r, -1);
						OPM_Write(')');
						OPC_Cmp(subclass);
						OPM_Write('0');
					} else {
						OPV_expr(l, exprPrec);
						OPC_Cmp(subclass);
						typ = ((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 703, 41, 32963))->typ;
						if ((((((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 704, 40, 33009))->form == 11 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 704, 66, 33035))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 704, 71, 33040))->form != 9)) && ((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 704, 95, 33064))->typ != typ)) && ((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 704, 112, 33081))->typ != OPT_sysptrtyp)) {
							OPM_WriteString((CHAR*)"(void *) ", 10);
						}
						OPV_expr(r, exprPrec);
					}
					break;
				default: 
					if (subclass == 5 || (form == 7 && (subclass == 1 || subclass == 7))) {
						OPM_Write('(');
					}
					OPV_expr(l, exprPrec);
					switch (subclass) {
						case 1: 
							if (form == 7) {
								OPM_WriteString((CHAR*)" & ", 4);
							} else {
								OPM_WriteString((CHAR*)" * ", 4);
							}
							break;
						case 2: 
							if (form == 7) {
								OPM_WriteString((CHAR*)" ^ ", 4);
							} else {
								OPM_WriteString((CHAR*)" / ", 4);
								if (((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 717, 51, 34012))->obj == NIL || ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 717, 69, 34030))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 717, 74, 34035))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 717, 79, 34040))->form == 4) {
									OPM_Write('(');
									OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 718, 81, 34143))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 718, 86, 34148))->strobj);
									OPM_Write(')');
								}
							}
							break;
						case 5: 
							OPM_WriteString((CHAR*)" && ", 5);
							break;
						case 6: 
							if (form == 7) {
								OPM_WriteString((CHAR*)" | ", 4);
							} else {
								OPM_WriteString((CHAR*)" + ", 4);
							}
							break;
						case 7: 
							if (form == 7) {
								OPM_WriteString((CHAR*)" & ~", 5);
							} else {
								OPM_WriteString((CHAR*)" - ", 4);
							}
							break;
						case 8: 
							OPM_WriteString((CHAR*)" || ", 5);
							break;
						default: 
							OPM_LogWStr((CHAR*)"unhandled case in OPV.expr, subclass = ", 40);
							OPM_LogWNum(subclass, 0);
							OPM_LogWLn();
							break;
					}
					OPV_expr(r, exprPrec);
					if (subclass == 5 || (form == 7 && (subclass == 1 || subclass == 7))) {
						OPM_Write(')');
					}
					break;
			}
			break;
		case 13: 
			if ((((__IN(20, OPM_Options, 32) && ((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 734, 58, 35319))->obj != NIL)) && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 734, 74, 35335))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 734, 78, 35339))->mode == 9)) {
				OPM_WriteString((CHAR*)"__NATIVE_RESULT(", 17);
			}
			if ((((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 737, 24, 35465))->obj != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 737, 41, 35482))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 737, 46, 35487))->mode == 13)) {
				if (((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 738, 25, 35536))->subcl == 1) {
					proc = OPV_SuperProc(n);
				} else {
					OPM_WriteString((CHAR*)"__", 3);
					proc = OPC_BaseTProc(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 739, 72, 35653))->obj);
				}
				OPC_Ident(proc);
				((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 742, 22, 35744))->obj = ((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 742, 35, 35757))->link;
			} else if (((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 743, 26, 35789))->class == 9) {
				OPV_design(l, 10);
			} else {
				OPV_Pointer(l, 11, n);
			}
			OPV_ActualPar(r, ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 746, 33, 35934))->obj, (((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 746, 42, 35943))->obj != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 746, 59, 35960))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 746, 64, 35965))->mode == 13), n);
			if ((((__IN(20, OPM_Options, 32) && ((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 747, 58, 36047))->obj != NIL)) && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 747, 74, 36063))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 747, 78, 36067))->mode == 9)) {
				OPM_Write(')');
			}
			break;
		default: 
			OPV_design(n, prec);
			break;
	}
	if ((exprPrec <= prec && __IN(class, 0x80003ca0, 32))) {
		OPM_Write(')');
	}
}

static void OPV_IfStat (OPT_Node n, BOOLEAN withtrap, OPT_Object outerProc)
{
	OPT_Node if_ = NIL;
	OPT_Object obj = NIL;
	OPT_Struct typ = NIL;
	INT32 adr;
	if_ = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 760, 12, 36611))->left;
	while (if_ != NIL) {
		OPM_WriteString((CHAR*)"if ", 4);
		OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(if_), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 762, 38, 36696))->left, 12);
		OPM_Write(' ');
		OPC_BegBlk();
		if ((((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 764, 12, 36771))->class == 27 && ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(if_), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 764, 38, 36797))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 764, 44, 36803))->left != NIL)) {
			obj = ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(if_), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 765, 18, 36870))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 765, 24, 36876))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 765, 30, 36882))->obj;
			typ = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 765, 47, 36899))->typ;
			adr = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 765, 64, 36916))->adr;
			if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 766, 15, 36937))->comp == 4) {
				OPC_BegStat();
				OPC_Ident(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(if_), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 768, 36, 37072))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 768, 42, 37078))->obj);
				OPM_WriteString((CHAR*)" *", 3);
				OPM_WriteString(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 769, 30, 37138))->name, 256);
				OPM_WriteString((CHAR*)"__ = (void*)", 13);
				((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 770, 14, 37192))->adr = 0;
				OPC_CompleteIdent(obj);
				OPC_EndStat();
			}
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 774, 12, 37357))->adr = 1;
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 775, 12, 37449))->typ = ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(if_), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 775, 23, 37460))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 775, 29, 37466))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 775, 34, 37471))->typ;
			OPV_stat(((OPT_Node)__NIL_AT((ADDRESS)(if_), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 776, 16, 37493))->right, outerProc);
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 777, 12, 37525))->typ = typ;
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 777, 29, 37542))->adr = adr;
		} else {
			OPV_stat(((OPT_Node)__NIL_AT((ADDRESS)(if_), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 779, 16, 37581))->right, outerProc);
		}
		if_ = ((OPT_Node)__NIL_AT((ADDRESS)(if_), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 781, 15, 37627))->link;
		if ((if_ != NIL || ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 782, 26, 37660))->right != NIL) || withtrap) {
			OPC_EndBlk0();
			OPM_WriteString((CHAR*)" else ", 7);
		} else {
			OPC_EndBlk();
		}
	}
	if (withtrap) {
		OPM_WriteString((CHAR*)"__WITHCHK", 10);
		OPC_EndStat();
	} else if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 787, 12, 37850))->right != NIL) {
		OPC_BegBlk();
		OPV_stat(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 787, 49, 37887))->right, outerProc);
		OPC_EndBlk();
	}
}

static void OPV_CaseStat (OPT_Node n, OPT_Object outerProc)
{
	OPT_Node switchCase = NIL, label = NIL;
	INT64 low, high;
	INT16 form, i;
	OPM_WriteString((CHAR*)"switch ", 8);
	OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 795, 39, 38132))->left, 12);
	OPM_Write(' ');
	OPC_BegBlk();
	form = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 797, 14, 38197))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 797, 20, 38203))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 797, 25, 38208))->form;
	switchCase = ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 798, 20, 38235))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 798, 27, 38242))->left;
	while (switchCase != NIL) {
		label = ((OPT_Node)__NIL_AT((ADDRESS)(switchCase), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 800, 26, 38340))->left;
		i = 0;
		while (label != NIL) {
			low = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(label), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 803, 21, 38437))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 803, 29, 38445))->intval;
			high = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(label), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 804, 22, 38476))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 804, 30, 38484))->intval2;
			while (low <= high) {
				if (i == 0) {
					OPC_BegStat();
				}
				OPC_Case(low, form);
				low += 1;
				i += 1;
				if (i == 5) {
					OPM_WriteLn();
					i = 0;
				}
			}
			label = ((OPT_Node)__NIL_AT((ADDRESS)(label), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 811, 23, 38709))->link;
		}
		if (i > 0) {
			OPM_WriteLn();
		}
		OPC_Indent(1);
		OPV_stat(((OPT_Node)__NIL_AT((ADDRESS)(switchCase), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 815, 22, 38808))->right, outerProc);
		OPC_BegStat();
		OPM_WriteString((CHAR*)"break", 6);
		OPC_EndStat();
		OPC_Indent(-1);
		switchCase = ((OPT_Node)__NIL_AT((ADDRESS)(switchCase), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 818, 31, 38937))->link;
	}
	OPC_BegStat();
	OPM_WriteString((CHAR*)"default: ", 10);
	if (((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 821, 9, 39009))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 821, 16, 39016))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 821, 24, 39024))->setval != 0x0) {
		OPC_Indent(1);
		OPM_WriteLn();
		OPV_stat(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 822, 41, 39102))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 822, 48, 39109))->right, outerProc);
		OPC_BegStat();
		OPM_WriteString((CHAR*)"break", 6);
		OPC_Indent(-1);
	} else {
		OPM_WriteString((CHAR*)"__CASECHK", 10);
	}
	OPC_EndStat();
	OPC_EndBlk();
}

static BOOLEAN OPV_ImplicitReturn (OPT_Node n)
{
	while ((n != NIL && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 832, 25, 39369))->class != 26)) {
		n = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 832, 56, 39400))->link;
	}
	return n == NIL;
}

static void OPV_NewArr (OPT_Node d, OPT_Node x)
{
	OPT_Struct typ = NIL, base = NIL;
	INT16 nofdim, nofdyn;
	typ = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(d), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 839, 13, 39567))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 839, 18, 39572))->BaseTyp;
	base = typ;
	nofdim = 0;
	nofdyn = 0;
	while (((OPT_Struct)__NIL_AT((ADDRESS)(base), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 840, 15, 39636))->comp == 3) {
		nofdim += 1;
		nofdyn += 1;
		base = ((OPT_Struct)__NIL_AT((ADDRESS)(base), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 840, 76, 39697))->BaseTyp;
	}
	OPV_design(d, -1);
	OPM_WriteString((CHAR*)" = __NEWARR(", 13);
	while (((OPT_Struct)__NIL_AT((ADDRESS)(base), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 842, 15, 39784))->comp == 2) {
		nofdim += 1;
		base = ((OPT_Struct)__NIL_AT((ADDRESS)(base), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 842, 62, 39831))->BaseTyp;
	}
	if ((((OPT_Struct)__NIL_AT((ADDRESS)(base), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 843, 13, 39859))->comp == 4 && OPC_NofPtrs(base) != 0)) {
		OPC_Andent(base);
		OPM_WriteString((CHAR*)"__typ", 6);
	} else if (((OPT_Struct)__NIL_AT((ADDRESS)(base), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 845, 15, 39976))->form == 11) {
		OPM_WriteString((CHAR*)"POINTER__typ", 13);
	} else {
		OPM_WriteString((CHAR*)"NIL", 4);
	}
	OPM_WriteString((CHAR*)", ", 3);
	OPM_WriteInt(((OPT_Struct)__NIL_AT((ADDRESS)(base), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 848, 45, 40120))->size);
	OPM_WriteString((CHAR*)", ", 3);
	OPM_WriteInt(OPT_BaseAlignment(base));
	OPM_WriteString((CHAR*)", ", 3);
	OPM_WriteInt(nofdim);
	OPM_WriteString((CHAR*)", ", 3);
	OPM_WriteInt(nofdyn);
	while (typ != base) {
		OPM_WriteString((CHAR*)", ", 3);
		if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 854, 13, 40486))->comp == 3) {
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 855, 13, 40523))->class == 7) {
				OPC_IntLiteral(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 856, 27, 40575))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 856, 34, 40582))->intval, OPM_AddressSize);
			} else {
				OPM_WriteString((CHAR*)"((ADDRESS)(", 12);
				OPV_expr(x, 10);
				OPM_WriteString((CHAR*)"))", 3);
			}
			x = ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 859, 15, 40716))->link;
		} else {
			OPC_IntLiteral(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 861, 27, 40760))->n, OPM_AddressSize);
		}
		typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 863, 17, 40809))->BaseTyp;
	}
	OPM_Write(')');
}

static void OPV_DefineTDescs (OPT_Node n)
{
	while ((n != NIL && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 870, 25, 40934))->class == 14)) {
		OPC_TDescDecl(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 870, 66, 40975))->typ);
		n = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 870, 80, 40989))->link;
	}
}

static void OPV_InitTDescs (OPT_Node n)
{
	while ((n != NIL && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 875, 25, 41090))->class == 14)) {
		OPC_InitTDesc(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 875, 66, 41131))->typ);
		n = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 875, 80, 41145))->link;
	}
}

static void OPV_AllName (OPT_Node range, CHAR *suffix, ADDRESS suffix__len)
{
	__DUP(suffix, suffix__len, CHAR);
	OPC_Ident(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 880, 20, 41263))->obj);
	OPM_WriteString(suffix, suffix__len);
	__DEL(suffix);
}

static BOOLEAN OPV_DirectAllRange (OPT_Node range)
{
	INT64 low, high;
	if (((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 886, 14, 41419))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 886, 20, 41425))->class != 7 || ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 886, 51, 41456))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 886, 58, 41463))->class != 7) {
		return 0;
	}
	low = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 887, 17, 41524))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 887, 23, 41530))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 887, 31, 41538))->intval;
	high = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 887, 54, 41561))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 887, 61, 41568))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 887, 69, 41576))->intval;
	return (low <= high && ((low >= 0 || high < 0) || low >= high - OPM_SignedMaximum(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 889, 45, 41686))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 889, 50, 41691))->size)));
}

static BOOLEAN OPV_InclusiveAllRange (OPT_Node range)
{
	INT64 low, high, maximum;
	if (!OPV_DirectAllRange(range)) {
		return 0;
	}
	low = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 896, 17, 41900))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 896, 23, 41906))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 896, 31, 41914))->intval;
	high = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 896, 54, 41937))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 896, 61, 41944))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 896, 69, 41952))->intval;
	maximum = OPM_SignedMaximum(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 897, 39, 42000))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 897, 44, 42005))->size);
	return (high < maximum && high - low < maximum);
}

static void OPV_DeclareAllLocals (OPT_Node range)
{
	OPT_Object obj = NIL;
	obj = ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 904, 17, 42189))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 904, 22, 42194))->link;
	while (obj != NIL) {
		OPC_BegStat();
		OPC_Andent(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 906, 34, 42258))->typ);
		OPM_Write(' ');
		OPC_Ident(obj);
		OPC_EndStat();
		obj = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 907, 17, 42327))->link;
	}
}

static BOOLEAN OPV_GPUScalar (OPT_Struct typ)
{
	return (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 913, 16, 42439))->comp == 1 && __IN(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 913, 42, 42465))->form, 0x7e, 32));
}

static OPV_GPUValue OPV_GPUCapture (OPT_Node n, BOOLEAN written, OPV_GPUValue *values)
{
	OPV_GPUValue value = NIL, last = NIL;
	BOOLEAN array;
	INT32 number;
	if (!__IN(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 919, 11, 42685))->class, 0x03, 32)) {
		OPM_err(168);
		return NIL;
	}
	array = __IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 920, 15, 42770))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 920, 20, 42775))->comp, 0x0c, 32);
	if (array) {
		if (!OPV_GPUScalar(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 922, 22, 42849))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 922, 27, 42854))->BaseTyp)) {
			OPM_err(168);
			return NIL;
		}
	} else if ((!OPV_GPUScalar(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 923, 23, 42921))->typ) || written) || (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 923, 47, 42945))->class == 1 && !OPV_reductionBody)) {
		OPM_err(168);
		return NIL;
	}
	value = OPV_GPUFind(*values, ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 926, 31, 43061))->obj);
	if (value == NIL) {
		last = *values;
		number = 0;
		if (last != NIL) {
			while (((OPV_GPUValue)__NIL_AT((ADDRESS)(last), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 930, 19, 43171))->next != NIL) {
				last = ((OPV_GPUValue)__NIL_AT((ADDRESS)(last), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 930, 47, 43199))->next;
			}
			number = ((OPV_GPUValue)__NIL_AT((ADDRESS)(last), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 931, 23, 43233))->number + 1;
		}
		__NEW(value, OPV_GPUValueDesc);
		((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 933, 24, 43280))->node = n;
		((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 933, 42, 43298))->number = number;
		((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 933, 67, 43323))->array = array;
		((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 934, 12, 43352))->maximum = -1;
		if (last == NIL) {
			*values = value;
		} else {
			((OPV_GPUValue)__NIL_AT((ADDRESS)(last), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 935, 51, 43419))->next = value;
		}
	}
	((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 937, 10, 43457))->written = ((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 937, 28, 43475))->written || written;
	return value;
}

static void OPV_GPUConversion (OPT_Struct from, OPT_Struct to)
{
	if ((((OPT_Struct)__NIL_AT((ADDRESS)(to), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 943, 12, 43601))->form == 4 && __IN(((OPT_Struct)__NIL_AT((ADDRESS)(from), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 943, 37, 43626))->form, 0x60, 32)) || (__IN(2, OPM_Options, 32) && ((((OPT_Struct)__NIL_AT((ADDRESS)(to), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 945, 16, 43717))->form == 4 && ((OPT_Struct)__NIL_AT((ADDRESS)(from), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 945, 41, 43742))->size > ((OPT_Struct)__NIL_AT((ADDRESS)(to), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 945, 52, 43753))->size) || (((OPT_Struct)__NIL_AT((ADDRESS)(to), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 946, 16, 43780))->form == 3 && ((OPT_Struct)__NIL_AT((ADDRESS)(from), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 946, 42, 43806))->form != 3)))) {
		OPM_err(172);
	}
}

static void OPV_GPUExpression (OPT_Node n, OPT_Node range, BOOLEAN written, OPV_GPUValue *values)
{
	OPV_GPUValue value = NIL;
	OPT_Node index = NIL;
	if (n == NIL) {
		return;
	}
	if (!OPV_GPUScalar(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 954, 20, 44064))->typ)) {
		OPM_err(168);
		return;
	}
	switch (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 955, 11, 44112))->class) {
		case 7: 
			break;
		case 0: case 1: 
			if (!__IN(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 958, 15, 44184))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 958, 20, 44189))->mode, 0xc000, 32)) {
				value = OPV_GPUCapture(n, written, &*values);
			}
			break;
		case 4: 
			value = OPV_GPUCapture(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 960, 30, 44322))->left, written, &*values);
			if (value == NIL) {
				return;
			}
			index = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 962, 19, 44406))->right;
			while ((((((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 963, 21, 44435))->class == 11 && ((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 963, 49, 44463))->subcl == 20)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 964, 19, 44503))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 964, 24, 44508))->size >= ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 964, 39, 44523))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 964, 45, 44529))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 964, 50, 44534))->size)) {
				index = ((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 964, 75, 44559))->left;
			}
			if ((((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 965, 18, 44588))->class == 0 && ((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 965, 46, 44616))->obj == ((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 965, 59, 44629))->obj)) {
				((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 965, 76, 44646))->ranged = 1;
				((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 965, 99, 44669))->rangedPos = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 965, 115, 44685))->pos;
			} else if ((((((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 966, 21, 44711))->class == 7 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 966, 51, 44741))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 966, 56, 44746))->form == 4)) && ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 966, 82, 44772))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 966, 90, 44780))->intval >= 0)) {
				if (((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 967, 19, 44818))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 967, 27, 44826))->intval > ((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 967, 43, 44842))->maximum) {
					((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 967, 63, 44862))->maximum = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(index), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 967, 81, 44880))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 967, 89, 44888))->intval;
					((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 967, 104, 44903))->maximumPos = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 967, 121, 44920))->pos;
				}
			} else {
				OPM_err(170);
			}
			break;
		case 11: 
			if (!__IN(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 971, 15, 44998))->subcl, 0x0200f00080, 64)) {
				OPM_err(171);
				return;
			}
			if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 974, 13, 45129))->subcl == 20) {
				OPV_GPUConversion(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 974, 52, 45168))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 974, 58, 45174))->typ, ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 974, 66, 45182))->typ);
			}
			OPV_GPUExpression(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 975, 24, 45217))->left, range, 0, &*values);
			break;
		case 12: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 977, 13, 45275))->subcl == 19) {
				if (((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 978, 15, 45312))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 978, 22, 45319))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 978, 30, 45327))->intval != 0) {
					OPM_err(168);
					return;
				}
				value = OPV_GPUCapture(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 979, 32, 45402))->left, 0, &*values);
			} else if ((((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 980, 17, 45441))->subcl == 17 && ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 980, 40, 45464))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 980, 47, 45471))->class == 7)) {
				OPV_GPUExpression(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 981, 26, 45523))->left, range, 0, &*values);
			} else if (__IN(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 982, 16, 45568))->subcl, 0x047fe6, 32)) {
				OPV_GPUExpression(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 984, 26, 45709))->left, range, 0, &*values);
				OPV_GPUExpression(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 984, 72, 45755))->right, range, 0, &*values);
			} else {
				OPM_err(171);
			}
			break;
		default: 
			OPM_err(168);
			break;
	}
}

static void OPV_GPUCheck (OPT_Node n, OPV_GPUValue *values)
{
	OPT_Node statement = NIL;
	OPV_GPUValue value = NIL, other = NIL;
	*values = NIL;
	statement = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 994, 34, 46027))->right;
	while (statement != NIL) {
		OPM_errpos = OPM_Longint(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(statement), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 996, 42, 46106))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 996, 50, 46114))->intval);
		OPV_GPUExpression(((OPT_Node)__NIL_AT((ADDRESS)(statement), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 997, 30, 46154))->left, ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 997, 39, 46163))->left, 1, &*values);
		OPV_GPUExpression(((OPT_Node)__NIL_AT((ADDRESS)(statement), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 998, 30, 46215))->right, ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 998, 40, 46225))->left, 0, &*values);
		OPV_GPUConversion(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(statement), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 999, 30, 46278))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 999, 37, 46285))->typ, ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(statement), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 999, 53, 46301))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 999, 59, 46307))->typ);
		statement = ((OPT_Node)__NIL_AT((ADDRESS)(statement), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1000, 29, 46343))->link;
	}
	value = *values;
	while (value != NIL) {
		if (((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1004, 15, 46419))->array) {
			other = ((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1005, 23, 46454))->next;
			while (other != NIL) {
				if ((((OPV_GPUValue)__NIL_AT((ADDRESS)(other), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1007, 19, 46509))->array && (((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1007, 36, 46526))->node), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1007, 42, 46532))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1007, 47, 46537))->comp == 3 || ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPV_GPUValue)__NIL_AT((ADDRESS)(other), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1008, 21, 46581))->node), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1008, 27, 46587))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1008, 32, 46592))->comp == 3) || ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1009, 21, 46636))->node), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1009, 27, 46642))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1009, 32, 46647))->mode == 2) || ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPV_GPUValue)__NIL_AT((ADDRESS)(other), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1009, 62, 46677))->node), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1009, 68, 46683))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1009, 73, 46688))->mode == 2))) {
					OPM_err(169);
				}
				other = ((OPV_GPUValue)__NIL_AT((ADDRESS)(other), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1011, 25, 46767))->next;
			}
		}
		value = ((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1014, 21, 46817))->next;
	}
}

static void OPV_GPUValidateBounds (OPT_Node range, OPV_GPUValue values)
{
	OPV_GPUValue value = NIL;
	if (!__IN(0, OPM_Options, 32)) {
		return;
	}
	value = values;
	while (value != NIL) {
		if (((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1024, 15, 47061))->array) {
			if (((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1025, 17, 47090))->ranged) {
				OPC_BegStat();
				OPM_WriteString((CHAR*)"if (", 5);
				OPV_AllName(range, (CHAR*)"__start", 8);
				OPM_WriteString((CHAR*)" < 0 || (UINT64)", 17);
				OPV_AllName(range, (CHAR*)"__end", 6);
				OPM_WriteString((CHAR*)" >= (UINT64)", 13);
				OPV_GPUName(range, value, (CHAR*)"__len", 6);
				OPM_WriteString((CHAR*)") __HALT_AT(-2", 15);
				OPC_SourceLocation(((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1029, 70, 47395))->rangedPos);
				OPM_Write(')');
				OPC_EndStat();
			}
			if (((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1031, 17, 47466))->maximum >= 0) {
				OPC_BegStat();
				OPM_WriteString((CHAR*)"if ((UINT64)", 13);
				OPC_IntLiteral(((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1032, 77, 47562))->maximum, 8);
				OPM_WriteString((CHAR*)" >= (UINT64)", 13);
				OPV_GPUName(range, value, (CHAR*)"__len", 6);
				OPM_WriteString((CHAR*)") __HALT_AT(-2", 15);
				OPC_SourceLocation(((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1034, 70, 47721))->maximumPos);
				OPM_Write(')');
				OPC_EndStat();
			}
		}
		value = ((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1037, 21, 47807))->next;
	}
}

static void OPV_GPUDeclarations (OPT_Node range, OPV_GPUValue values)
{
	OPV_GPUValue value = NIL;
	value = values;
	while (value != NIL) {
		OPC_BegStat();
		if (((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1047, 15, 48024))->array) {
			OPC_Andent(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1047, 44, 48053))->node), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1047, 50, 48059))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1047, 55, 48064))->BaseTyp);
			OPM_WriteString((CHAR*)" *", 3);
		} else {
			OPC_Andent(((OPT_Node)__NIL_AT((ADDRESS)(((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1048, 28, 48125))->node), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1048, 34, 48131))->typ);
			OPM_Write(' ');
		}
		OPV_GPUName(range, value, (CHAR*)"", 1);
		OPM_WriteString((CHAR*)" = ", 4);
		OPV_expr(((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1050, 68, 48232))->node, -1);
		OPC_EndStat();
		if (((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1051, 15, 48277))->array) {
			OPC_BegStat();
			OPM_WriteString((CHAR*)"ADDRESS ", 9);
			OPV_GPUName(range, value, (CHAR*)"__len", 6);
			OPM_WriteString((CHAR*)" = ", 4);
			OPV_Len(((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1053, 42, 48413))->node, 0);
			OPC_EndStat();
		}
		value = ((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1055, 21, 48468))->next;
	}
	OPV_GPUValidateBounds(range, values);
}

static void OPV_GPUPragma (OPT_Node range, OPV_GPUValue values, INT8 operation)
{
	OPV_GPUValue value = NIL;
	OPC_BegStat();
	OPM_WriteString((CHAR*)"#pragma omp target teams distribute parallel for schedule(static)", 66);
	value = values;
	while (value != NIL) {
		if (((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1066, 15, 48820))->array) {
			if (((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1067, 17, 48849))->written) {
				OPM_WriteString((CHAR*)" map(tofrom: ", 14);
			} else {
				OPM_WriteString((CHAR*)" map(to: ", 10);
			}
			OPV_GPUName(range, value, (CHAR*)"", 1);
			OPM_WriteString((CHAR*)"[0:", 4);
			OPV_GPUName(range, value, (CHAR*)"__len", 6);
			OPM_WriteString((CHAR*)"])", 3);
		}
		value = ((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1070, 21, 49080))->next;
	}
	OPM_WriteString((CHAR*)" firstprivate(", 15);
	OPV_AllName(range, (CHAR*)"__start", 8);
	OPM_WriteString((CHAR*)", ", 3);
	OPV_AllName(range, (CHAR*)"__end", 6);
	OPM_WriteString((CHAR*)", ", 3);
	OPV_AllName(range, (CHAR*)"__count", 8);
	OPM_WriteString((CHAR*)", ", 3);
	OPV_AllName(range, (CHAR*)"__work", 7);
	value = values;
	while (value != NIL) {
		OPM_WriteString((CHAR*)", ", 3);
		if (((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1077, 15, 49402))->array) {
			OPV_GPUName(range, value, (CHAR*)"__len", 6);
		} else {
			OPV_GPUName(range, value, (CHAR*)"", 1);
		}
		value = ((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1078, 21, 49502))->next;
	}
	OPM_Write(')');
	if (operation != 0) {
		OPM_WriteString((CHAR*)" reduction(", 12);
		if (operation == 33) {
			OPM_Write('+');
		} else {
			OPM_Write('*');
		}
		OPM_WriteString((CHAR*)": ", 3);
		OPV_AllName(range, (CHAR*)"__result", 9);
		OPM_Write(')');
	}
	OPM_WriteLn();
}

static void OPV_ReductionType (OPT_Struct typ)
{
	if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1091, 11, 49855))->form == 4) {
		OPM_WriteString((CHAR*)"INT", 4);
		OPM_WriteInt(__ASHL(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1091, 73, 49917))->size, 3));
	} else if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1092, 14, 49940))->form == 5) {
		OPM_WriteString((CHAR*)"float", 6);
	} else if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1093, 14, 50001))->form == 6) {
		OPM_WriteString((CHAR*)"double", 7);
	} else {
		OPC_Andent(typ);
	}
}

static void OPV_ReductionCollect (OPT_Node n, OPT_Node range, OPV_GPUValue *values)
{
	OPV_GPUValue value = NIL;
	if (n == NIL) {
		return;
	}
	if (!OPV_GPUScalar(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1102, 20, 50262))->typ)) {
		OPM_err(175);
		return;
	}
	switch (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1103, 11, 50310))->class) {
		case 7: 
			break;
		case 0: case 1: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1106, 13, 50380))->obj != ((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1106, 26, 50393))->obj) {
				value = OPV_GPUCapture(n, 0, &*values);
			}
			break;
		case 4: 
			if ((!__IN(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1108, 15, 50478))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1108, 21, 50484))->class, 0x03, 32) || !__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1109, 16, 50538))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1109, 22, 50544))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1109, 27, 50549))->comp, 0x0c, 32)) || !OPV_GPUScalar(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1110, 25, 50611))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1110, 31, 50617))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1110, 36, 50622))->BaseTyp)) {
				OPM_err(175);
				return;
			}
			value = OPV_GPUCapture(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1111, 30, 50693))->left, 0, &*values);
			OPV_ReductionCollect(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1111, 72, 50735))->right, range, &*values);
			break;
		case 11: 
			if (!__IN(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1113, 15, 50789))->subcl, 0x0200f00080, 64)) {
				OPM_err(178);
				return;
			}
			OPV_ReductionCollect(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1116, 27, 50934))->left, range, &*values);
			break;
		case 12: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1118, 13, 50985))->subcl == 19) {
				if ((((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1119, 16, 51023))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1119, 23, 51030))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1119, 31, 51038))->intval != 0 || !__IN(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1120, 18, 51072))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1120, 24, 51078))->class, 0x03, 32)) || !OPV_GPUScalar(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1121, 27, 51143))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1121, 33, 51149))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1121, 38, 51154))->BaseTyp)) {
					OPM_err(175);
					return;
				}
				value = OPV_GPUCapture(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1122, 32, 51227))->left, 0, &*values);
			} else {
				OPV_ReductionCollect(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1123, 32, 51281))->left, range, &*values);
				OPV_ReductionCollect(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1123, 74, 51323))->right, range, &*values);
			}
			break;
		default: 
			OPM_err(175);
			break;
	}
}

static OPV_Reduction OPV_FindReduction (OPT_Node n)
{
	OPV_Reduction item = NIL;
	item = OPV_reductions;
	while ((item != NIL && ((OPV_Reduction)__NIL_AT((ADDRESS)(item), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1133, 31, 51552))->node != n)) {
		item = ((OPV_Reduction)__NIL_AT((ADDRESS)(item), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1133, 58, 51579))->next;
	}
	return item;
}

static void OPV_ReductionCall (OPT_Node n)
{
	OPV_Reduction item = NIL;
	OPV_GPUValue value = NIL;
	item = OPV_FindReduction(n);
	OPV_AllName(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1140, 40, 51758))->left, (CHAR*)"__reduce", 9);
	OPM_Write('(');
	value = ((OPV_Reduction)__NIL_AT((ADDRESS)(item), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1141, 18, 51812))->values;
	while (value != NIL) {
		if (!((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1143, 16, 51862))->array) {
			OPM_WriteString((CHAR*)"&(", 3);
		}
		OPV_expr(((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1144, 17, 51918))->node, -1);
		if (!((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1145, 16, 51951))->array) {
			OPM_Write(')');
		}
		if (((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1146, 15, 51998))->array) {
			OPM_WriteString((CHAR*)", ", 3);
			OPV_Len(((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1146, 60, 52043))->node, 0);
		}
		value = ((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1147, 21, 52079))->next;
		if (value != NIL) {
			OPM_WriteString((CHAR*)", ", 3);
		}
	}
	OPM_Write(')');
}

static void OPV_ReductionCombine (OPT_Node n)
{
	OPC_BegStat();
	OPV_AllName(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1155, 27, 52266))->left, (CHAR*)"__result", 9);
	if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1156, 9, 52295))->subcl == 33) {
		OPM_WriteString((CHAR*)" += ", 5);
	} else {
		OPM_WriteString((CHAR*)" *= ", 5);
	}
	if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1157, 9, 52386))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1157, 14, 52391))->form == 4) {
		OPM_WriteString((CHAR*)"(UINT64)(", 10);
	} else {
		OPM_Write('(');
	}
	OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1158, 11, 52477))->right, -1);
	OPM_Write(')');
	OPC_EndStat();
}

static void OPV_DirectReduction (OPT_Node n)
{
	OPT_Node range = NIL, savedRange = NIL;
	range = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1164, 15, 52650))->left;
	OPC_BegStat();
	OPM_WriteString((CHAR*)"#pragma omp parallel for schedule(static) reduction(", 53);
	if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1166, 9, 52756))->subcl == 33) {
		OPM_Write('+');
	} else {
		OPM_Write('*');
	}
	OPM_WriteString((CHAR*)": ", 3);
	OPV_AllName(range, (CHAR*)"__result", 9);
	OPM_Write(')');
	OPM_WriteLn();
	OPC_BegStat();
	OPM_WriteString((CHAR*)"for (", 6);
	OPV_ReductionType(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1168, 63, 52967))->typ);
	OPM_Write(' ');
	OPV_AllName(range, (CHAR*)"", 1);
	OPM_WriteString((CHAR*)" = ", 4);
	OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1169, 39, 53049))->left, -1);
	OPM_WriteString((CHAR*)"; ", 3);
	OPV_AllName(range, (CHAR*)"", 1);
	OPM_WriteString((CHAR*)" <= ", 5);
	OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1170, 83, 53149))->right, -1);
	OPM_WriteString((CHAR*)"; ++", 5);
	OPV_AllName(range, (CHAR*)"", 1);
	OPM_WriteString((CHAR*)") ", 3);
	OPC_BegBlk();
	savedRange = OPV_parallelRange;
	OPV_parallelRange = range;
	OPV_ReductionCombine(n);
	OPV_parallelRange = savedRange;
	OPC_EndBlk();
}

static void OPV_ReductionHelper (OPV_Reduction item)
{
	OPT_Node n = NIL, range = NIL;
	OPV_GPUValue value = NIL, other = NIL;
	BOOLEAN parallel, gpu;
	n = ((OPV_Reduction)__NIL_AT((ADDRESS)(item), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1180, 14, 53545))->node;
	range = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1180, 32, 53563))->left;
	OPM_errpos = OPM_Longint(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1181, 32, 53602))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1181, 40, 53610))->intval);
	OPV_reductionBody = 1;
	((OPV_Reduction)__NIL_AT((ADDRESS)(item), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1182, 32, 53652))->values = NIL;
	OPV_ReductionCollect(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1183, 27, 53695))->left, range, &((OPV_Reduction)__NIL_AT((ADDRESS)(item), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1183, 46, 53714))->values);
	OPV_ReductionCollect(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1184, 27, 53751))->right, range, &((OPV_Reduction)__NIL_AT((ADDRESS)(item), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1184, 47, 53771))->values);
	OPV_ReductionCollect(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1185, 23, 53804))->right, range, &((OPV_Reduction)__NIL_AT((ADDRESS)(item), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1185, 43, 53824))->values);
	gpu = __IN(25, OPM_Options, 32);
	parallel = gpu || __IN(24, OPM_Options, 32);
	if (gpu) {
		OPV_GPUExpression(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1189, 22, 53972))->right, range, 0, &((OPV_Reduction)__NIL_AT((ADDRESS)(item), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1189, 49, 53999))->values);
		value = ((OPV_Reduction)__NIL_AT((ADDRESS)(item), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1190, 20, 54029))->values;
		while (value != NIL) {
			if (((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1192, 17, 54082))->array) {
				other = ((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1193, 25, 54119))->next;
				while (other != NIL) {
					if ((((OPV_GPUValue)__NIL_AT((ADDRESS)(other), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1195, 21, 54178))->array && (((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1195, 38, 54195))->node), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1195, 44, 54201))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1195, 49, 54206))->comp == 3 || ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPV_GPUValue)__NIL_AT((ADDRESS)(other), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1196, 23, 54252))->node), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1196, 29, 54258))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1196, 34, 54263))->comp == 3) || ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1197, 23, 54309))->node), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1197, 29, 54315))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1197, 34, 54320))->mode == 2) || ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPV_GPUValue)__NIL_AT((ADDRESS)(other), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1197, 64, 54350))->node), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1197, 70, 54356))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1197, 75, 54361))->mode == 2))) {
						OPM_err(169);
					}
					other = ((OPV_GPUValue)__NIL_AT((ADDRESS)(other), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1199, 27, 54444))->next;
				}
			}
			value = ((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1202, 23, 54500))->next;
		}
	}
	OPV_reductionBody = 0;
	if (!OPM_noerr) {
		return;
	}
	OPM_WriteString((CHAR*)"static ", 8);
	OPV_ReductionType(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1207, 48, 54636))->typ);
	OPM_Write(' ');
	OPV_AllName(range, (CHAR*)"__reduce", 9);
	OPM_Write('(');
	value = ((OPV_Reduction)__NIL_AT((ADDRESS)(item), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1208, 18, 54721))->values;
	if (value == NIL) {
		OPM_WriteString((CHAR*)"void", 5);
	}
	while (value != NIL) {
		if (((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1211, 15, 54823))->array) {
			OPV_ReductionType(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1211, 47, 54855))->node), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1211, 53, 54861))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1211, 58, 54866))->BaseTyp);
			OPM_WriteString((CHAR*)" *", 3);
		} else {
			OPV_ReductionType(((OPT_Node)__NIL_AT((ADDRESS)(((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1212, 31, 54930))->node), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1212, 37, 54936))->typ);
			OPM_WriteString((CHAR*)" *", 3);
		}
		if (((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1214, 15, 54991))->array) {
			OPV_GPUName(range, value, (CHAR*)"", 1);
		} else {
			OPV_GPUName(range, value, (CHAR*)"__ref", 6);
		}
		if (((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1215, 15, 55085))->array) {
			OPM_WriteString((CHAR*)", ADDRESS ", 11);
			OPV_GPUName(range, value, (CHAR*)"__len", 6);
		}
		value = ((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1216, 21, 55185))->next;
		if (value != NIL) {
			OPM_WriteString((CHAR*)", ", 3);
		}
	}
	OPM_Write(')');
	OPM_WriteLn();
	OPC_BegBlk();
	OPV_reductionBody = 1;
	OPV_gpuRange = range;
	OPV_gpuValues = ((OPV_Reduction)__NIL_AT((ADDRESS)(item), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1220, 64, 55362))->values;
	OPC_BegStat();
	if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1222, 9, 55397))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1222, 14, 55402))->form == 4) {
		OPM_WriteString((CHAR*)"UINT64", 7);
	} else {
		OPV_ReductionType(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1222, 82, 55470))->typ);
	}
	OPM_Write(' ');
	OPV_AllName(range, (CHAR*)"__result", 9);
	OPM_WriteString((CHAR*)" = ", 4);
	if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1224, 9, 55562))->subcl == 33) {
		OPM_Write('0');
	} else {
		OPM_Write('1');
	}
	OPC_EndStat();
	OPV_reductionBounds = 1;
	OPC_BegStat();
	OPV_ReductionType(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1226, 37, 55705))->typ);
	OPM_Write(' ');
	OPV_AllName(range, (CHAR*)"__start", 8);
	OPM_WriteString((CHAR*)" = ", 4);
	OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1227, 39, 55794))->left, -1);
	OPC_EndStat();
	OPC_BegStat();
	OPV_ReductionType(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1228, 37, 55861))->typ);
	OPM_Write(' ');
	OPV_AllName(range, (CHAR*)"__end", 6);
	OPM_WriteString((CHAR*)" = ", 4);
	OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1229, 39, 55948))->right, -1);
	OPC_EndStat();
	OPV_reductionBounds = 0;
	OPC_BegStat();
	OPM_WriteString((CHAR*)"if (", 5);
	OPV_AllName(range, (CHAR*)"__start", 8);
	OPM_WriteString((CHAR*)" <= ", 5);
	OPV_AllName(range, (CHAR*)"__end", 6);
	OPM_WriteString((CHAR*)") ", 3);
	OPC_BegBlk();
	value = ((OPV_Reduction)__NIL_AT((ADDRESS)(item), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1233, 18, 56185))->values;
	while (value != NIL) {
		if (!((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1235, 16, 56235))->array) {
			OPC_BegStat();
			OPV_ReductionType(((OPT_Node)__NIL_AT((ADDRESS)(((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1236, 41, 56288))->node), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1236, 47, 56294))->typ);
			OPM_Write(' ');
			OPV_GPUName(range, value, (CHAR*)"", 1);
			OPM_WriteString((CHAR*)" = *", 5);
			OPV_GPUName(range, value, (CHAR*)"__ref", 6);
			OPC_EndStat();
		}
		value = ((OPV_GPUValue)__NIL_AT((ADDRESS)(value), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1239, 21, 56453))->next;
	}
	if (gpu) {
		OPV_GPUValidateBounds(range, ((OPV_Reduction)__NIL_AT((ADDRESS)(item), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1241, 46, 56514))->values);
	}
	if ((((parallel && !gpu)) && OPV_InclusiveAllRange(range))) {
		OPV_DirectReduction(n);
	} else {
		OPC_BegStat();
		OPM_WriteString((CHAR*)"UINT64 ", 8);
		OPV_AllName(range, (CHAR*)"__count", 8);
		OPM_WriteString((CHAR*)" = (UINT64)", 12);
		OPV_AllName(range, (CHAR*)"__end", 6);
		OPM_WriteString((CHAR*)" - (UINT64)", 12);
		OPV_AllName(range, (CHAR*)"__start", 8);
		OPC_EndStat();
		OPC_BegStat();
		OPM_WriteString((CHAR*)"UINT64 ", 8);
		OPV_AllName(range, (CHAR*)"__work", 7);
		OPM_WriteString((CHAR*)" = ", 4);
		OPV_AllName(range, (CHAR*)"__count", 8);
		OPM_WriteString((CHAR*)" == 0 \? 1 : ", 13);
		OPV_AllName(range, (CHAR*)"__count", 8);
		OPC_EndStat();
		if (gpu) {
			OPV_GPUPragma(range, ((OPV_Reduction)__NIL_AT((ADDRESS)(item), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1250, 40, 57075))->values, ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1250, 51, 57086))->subcl);
		} else if (parallel) {
			OPC_BegStat();
			OPM_WriteString((CHAR*)"#pragma omp parallel for schedule(static) reduction(", 53);
			if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1253, 13, 57227))->subcl == 33) {
				OPM_Write('+');
			} else {
				OPM_Write('*');
			}
			OPM_WriteString((CHAR*)": ", 3);
			OPV_AllName(range, (CHAR*)"__result", 9);
			OPM_Write(')');
			OPM_WriteLn();
		}
		OPC_BegStat();
		OPM_WriteString((CHAR*)"for (UINT64 ", 13);
		OPV_AllName(range, (CHAR*)"__offset", 9);
		OPM_WriteString((CHAR*)" = 0; ", 7);
		OPV_AllName(range, (CHAR*)"__offset", 9);
		OPM_WriteString((CHAR*)" < ", 4);
		OPV_AllName(range, (CHAR*)"__work", 7);
		OPM_WriteString((CHAR*)"; ++", 5);
		OPV_AllName(range, (CHAR*)"__offset", 9);
		OPM_WriteString((CHAR*)") ", 3);
		OPC_BegBlk();
		OPC_BegStat();
		OPM_WriteString((CHAR*)"UINT64 ", 8);
		OPV_AllName(range, (CHAR*)"__value", 8);
		OPM_WriteString((CHAR*)" = (UINT64)", 12);
		OPV_AllName(range, (CHAR*)"__start", 8);
		OPM_WriteString((CHAR*)" + ", 4);
		OPV_AllName(range, (CHAR*)"__offset", 9);
		OPC_EndStat();
		OPC_BegStat();
		OPV_ReductionType(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1262, 39, 57923))->typ);
		OPM_Write(' ');
		OPV_AllName(range, (CHAR*)"", 1);
		OPM_WriteString((CHAR*)" = ", 4);
		OPV_AllName(range, (CHAR*)"__value", 8);
		OPM_WriteString((CHAR*)" <= (UINT64)", 13);
		OPC_IntLiteral(OPM_SignedMaximum(8), 8);
		OPM_WriteString((CHAR*)" \? (INT64)", 11);
		OPV_AllName(range, (CHAR*)"__value", 8);
		OPM_WriteString((CHAR*)" : -1 - (INT64)~", 17);
		OPV_AllName(range, (CHAR*)"__value", 8);
		OPC_EndStat();
		OPV_gpuBody = gpu;
		if (!parallel) {
			OPC_CheckInterrupt();
		}
		OPV_ReductionCombine(n);
		OPC_BegStat();
		OPM_WriteString((CHAR*)"if (", 5);
		OPV_AllName(range, (CHAR*)"__count", 8);
		OPM_WriteString((CHAR*)" != 0 && ", 10);
		OPV_AllName(range, (CHAR*)"__offset", 9);
		OPM_WriteString((CHAR*)" == ", 5);
		OPV_AllName(range, (CHAR*)"__count", 8);
		OPM_WriteString((CHAR*)" - 1) ", 7);
		OPC_BegBlk();
		OPC_BegStat();
		OPV_AllName(range, (CHAR*)"", 1);
		OPM_WriteString((CHAR*)" = ", 4);
		OPV_AllName(range, (CHAR*)"__end", 6);
		OPC_EndStat();
		OPV_ReductionCombine(n);
		OPC_EndBlk();
		OPC_EndBlk();
	}
	OPC_EndBlk();
	OPV_gpuBody = 0;
	OPV_reductionBody = 0;
	OPV_gpuRange = NIL;
	OPV_gpuValues = NIL;
	if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1276, 9, 58833))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1276, 14, 58838))->form == 4) {
		OPC_BegStat();
		OPM_WriteString((CHAR*)"UINT", 5);
		OPM_WriteInt(__ASHL(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1277, 59, 58918))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1277, 64, 58923))->size, 3));
		OPM_Write(' ');
		OPV_AllName(range, (CHAR*)"__bits", 7);
		OPM_WriteString((CHAR*)" = (UINT", 9);
		OPM_WriteInt(__ASHL(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1278, 76, 59025))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1278, 81, 59030))->size, 3));
		OPM_Write(')');
		OPV_AllName(range, (CHAR*)"__result", 9);
		OPC_EndStat();
		OPC_BegStat();
		OPM_WriteString((CHAR*)"return ", 8);
		OPV_AllName(range, (CHAR*)"__bits", 7);
		OPM_WriteString((CHAR*)" <= (UINT64)", 13);
		OPC_IntLiteral(OPM_SignedMaximum(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1281, 41, 59250))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1281, 46, 59255))->size), 8);
		OPM_WriteString((CHAR*)" \? (INT64)", 11);
		OPV_AllName(range, (CHAR*)"__bits", 7);
		OPM_WriteString((CHAR*)" : -1 - (INT64)(UINT", 21);
		OPM_WriteInt(__ASHL(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1282, 62, 59386))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1282, 67, 59391))->size, 3));
		OPM_WriteString((CHAR*)")~", 3);
		OPV_AllName(range, (CHAR*)"__bits", 7);
		OPC_EndStat();
	} else {
		OPC_BegStat();
		OPM_WriteString((CHAR*)"return ", 8);
		OPV_AllName(range, (CHAR*)"__result", 9);
		OPC_EndStat();
	}
	OPC_EndBlk();
	OPM_WriteLn();
}

static void OPV_ReductionHelpers (OPT_Node n)
{
	OPV_Reduction item = NIL;
	if (n == NIL) {
		return;
	}
	if ((((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1293, 10, 59737))->class == 31 && OPV_FindReduction(n) == NIL)) {
		__NEW(item, OPV_ReductionDesc);
		((OPV_Reduction)__NIL_AT((ADDRESS)(item), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1294, 22, 59813))->node = n;
		((OPV_Reduction)__NIL_AT((ADDRESS)(item), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1294, 39, 59830))->next = OPV_reductions;
		OPV_reductions = item;
		OPV_ReductionHelper(item);
	}
	OPV_ReductionHelpers(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1297, 23, 59931))->left);
	OPV_ReductionHelpers(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1297, 50, 59958))->right);
	OPV_ReductionHelpers(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1297, 78, 59986))->link);
}

static void OPV_GPUAllStat (OPT_Node n, OPT_Object outerProc)
{
	OPT_Node range = NIL;
	OPV_GPUValue values = NIL, savedValues = NIL;
	OPT_Node savedRange = NIL;
	BOOLEAN savedParallel, savedGPU;
	if (((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1304, 9, 60213))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1304, 15, 60219))->link != NIL) {
		OPM_err(160);
		return;
	}
	OPV_GPUCheck(n, &values);
	if (!OPM_noerr) {
		return;
	}
	range = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1307, 15, 60337))->left;
	OPC_BegBlk();
	OPC_BegStat();
	OPC_Andent(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1309, 34, 60394))->typ);
	OPM_Write(' ');
	OPV_AllName(range, (CHAR*)"__start", 8);
	OPM_WriteString((CHAR*)" = ", 4);
	OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1310, 39, 60483))->left, -1);
	OPM_WriteString((CHAR*)", ", 3);
	OPV_AllName(range, (CHAR*)"__end", 6);
	OPM_WriteString((CHAR*)" = ", 4);
	OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1311, 87, 60587))->right, -1);
	OPC_EndStat();
	OPC_BegStat();
	OPM_WriteString((CHAR*)"if (", 5);
	OPV_AllName(range, (CHAR*)"__start", 8);
	OPM_WriteString((CHAR*)" <= ", 5);
	OPV_AllName(range, (CHAR*)"__end", 6);
	OPM_WriteString((CHAR*)") ", 3);
	OPC_BegBlk();
	OPV_GPUDeclarations(range, values);
	OPC_BegStat();
	OPM_WriteString((CHAR*)"UINT64 ", 8);
	OPV_AllName(range, (CHAR*)"__count", 8);
	OPM_WriteString((CHAR*)" = (UINT64)", 12);
	OPV_AllName(range, (CHAR*)"__end", 6);
	OPM_WriteString((CHAR*)" - (UINT64)", 12);
	OPV_AllName(range, (CHAR*)"__start", 8);
	OPC_EndStat();
	OPC_BegStat();
	OPM_WriteString((CHAR*)"UINT64 ", 8);
	OPV_AllName(range, (CHAR*)"__work", 7);
	OPM_WriteString((CHAR*)" = ", 4);
	OPV_AllName(range, (CHAR*)"__count", 8);
	OPM_WriteString((CHAR*)" == 0 \? 1 : ", 13);
	OPV_AllName(range, (CHAR*)"__count", 8);
	OPC_EndStat();
	OPV_GPUPragma(range, values, 0);
	OPC_BegStat();
	OPM_WriteString((CHAR*)"for (UINT64 ", 13);
	OPV_AllName(range, (CHAR*)"__offset", 9);
	OPM_WriteString((CHAR*)" = 0; ", 7);
	OPV_AllName(range, (CHAR*)"__offset", 9);
	OPM_WriteString((CHAR*)" < ", 4);
	OPV_AllName(range, (CHAR*)"__work", 7);
	OPM_WriteString((CHAR*)"; ++", 5);
	OPV_AllName(range, (CHAR*)"__offset", 9);
	OPM_WriteString((CHAR*)") ", 3);
	OPC_BegBlk();
	OPC_BegStat();
	OPM_WriteString((CHAR*)"UINT64 ", 8);
	OPV_AllName(range, (CHAR*)"__value", 8);
	OPM_WriteString((CHAR*)" = (UINT64)", 12);
	OPV_AllName(range, (CHAR*)"__start", 8);
	OPM_WriteString((CHAR*)" + ", 4);
	OPV_AllName(range, (CHAR*)"__offset", 9);
	OPC_EndStat();
	savedParallel = OPV_parallelBody;
	savedGPU = OPV_gpuBody;
	savedRange = OPV_gpuRange;
	savedValues = OPV_gpuValues;
	OPV_parallelBody = 1;
	OPV_gpuBody = 1;
	OPV_gpuRange = range;
	OPV_gpuValues = values;
	OPC_BegStat();
	OPC_BegBlk();
	OPC_BegStat();
	OPC_Andent(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1329, 34, 61984))->typ);
	OPM_Write(' ');
	OPV_AllName(range, (CHAR*)"", 1);
	OPM_WriteString((CHAR*)" = ", 4);
	OPV_AllName(range, (CHAR*)"__value", 8);
	OPM_WriteString((CHAR*)" <= (UINT64)", 13);
	OPC_IntLiteral(OPM_SignedMaximum(8), 8);
	OPM_WriteString((CHAR*)" \? (INT64)", 11);
	OPV_AllName(range, (CHAR*)"__value", 8);
	OPM_WriteString((CHAR*)" : -1 - (INT64)~", 17);
	OPV_AllName(range, (CHAR*)"__value", 8);
	OPC_EndStat();
	OPV_DeclareAllLocals(range);
	OPV_stat(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1332, 36, 62331))->right, outerProc);
	OPC_EndBlk();
	OPC_BegStat();
	OPM_WriteString((CHAR*)"if (", 5);
	OPV_AllName(range, (CHAR*)"__count", 8);
	OPM_WriteString((CHAR*)" != 0 && ", 10);
	OPV_AllName(range, (CHAR*)"__offset", 9);
	OPM_WriteString((CHAR*)" == ", 5);
	OPV_AllName(range, (CHAR*)"__count", 8);
	OPM_WriteString((CHAR*)" - 1) ", 7);
	OPC_BegBlk();
	OPC_BegStat();
	OPC_Andent(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1335, 34, 62619))->typ);
	OPM_Write(' ');
	OPV_AllName(range, (CHAR*)"", 1);
	OPM_WriteString((CHAR*)" = ", 4);
	OPV_AllName(range, (CHAR*)"__end", 6);
	OPC_EndStat();
	OPV_DeclareAllLocals(range);
	OPV_stat(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1337, 36, 62764))->right, outerProc);
	OPC_EndBlk();
	OPV_parallelBody = savedParallel;
	OPV_gpuBody = savedGPU;
	OPV_gpuRange = savedRange;
	OPV_gpuValues = savedValues;
	OPC_EndBlk();
	OPC_CheckInterrupt();
	OPC_EndBlk();
	OPC_EndBlk();
}

static void OPV_ParallelAllStat (OPT_Node n, OPT_Object outerProc)
{
	OPT_Node range = NIL, savedRange = NIL;
	BOOLEAN saved;
	range = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1345, 15, 63121))->left;
	OPC_BegBlk();
	OPC_BegStat();
	OPC_Andent(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1347, 34, 63178))->typ);
	OPM_Write(' ');
	OPV_AllName(range, (CHAR*)"__start", 8);
	OPM_WriteString((CHAR*)" = ", 4);
	OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1348, 39, 63267))->left, -1);
	OPM_WriteString((CHAR*)", ", 3);
	OPV_AllName(range, (CHAR*)"__end", 6);
	OPM_WriteString((CHAR*)" = ", 4);
	OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1350, 15, 63375))->right, -1);
	OPC_EndStat();
	OPC_BegStat();
	OPM_WriteString((CHAR*)"if (", 5);
	OPV_AllName(range, (CHAR*)"__start", 8);
	OPM_WriteString((CHAR*)" <= ", 5);
	OPV_AllName(range, (CHAR*)"__end", 6);
	OPM_WriteString((CHAR*)") ", 3);
	OPC_BegBlk();
	OPC_BegStat();
	OPM_WriteString((CHAR*)"UINT64 ", 8);
	OPV_AllName(range, (CHAR*)"__count", 8);
	OPM_WriteString((CHAR*)" = (UINT64)", 12);
	OPV_AllName(range, (CHAR*)"__end", 6);
	OPM_WriteString((CHAR*)" - (UINT64)", 12);
	OPV_AllName(range, (CHAR*)"__start", 8);
	OPC_EndStat();
	OPC_BegStat();
	OPM_WriteString((CHAR*)"if (", 5);
	OPV_AllName(range, (CHAR*)"__count", 8);
	OPM_WriteString((CHAR*)" != 0) ", 8);
	OPC_BegBlk();
	OPC_BegStat();
	OPM_WriteString((CHAR*)"#pragma omp parallel for schedule(static)", 42);
	OPM_WriteLn();
	OPC_BegStat();
	OPM_WriteString((CHAR*)"for (", 6);
	if (OPV_DirectAllRange(range)) {
		OPC_Andent(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1361, 23, 64078))->typ);
		OPM_Write(' ');
		OPV_AllName(range, (CHAR*)"", 1);
		OPM_WriteString((CHAR*)" = ", 4);
		OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1362, 41, 64162))->left, -1);
		OPM_WriteString((CHAR*)"; ", 3);
		OPV_AllName(range, (CHAR*)"", 1);
		OPM_WriteString((CHAR*)" < ", 4);
		OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1363, 84, 64263))->right, -1);
		OPM_WriteString((CHAR*)"; ++", 5);
		OPV_AllName(range, (CHAR*)"", 1);
		OPM_WriteString((CHAR*)") ", 3);
		OPC_BegBlk();
	} else {
		OPM_WriteString((CHAR*)"UINT64 ", 8);
		OPV_AllName(range, (CHAR*)"__offset", 9);
		OPM_WriteString((CHAR*)" = 0; ", 7);
		OPV_AllName(range, (CHAR*)"__offset", 9);
		OPM_WriteString((CHAR*)" < ", 4);
		OPV_AllName(range, (CHAR*)"__count", 8);
		OPM_WriteString((CHAR*)"; ++", 5);
		OPV_AllName(range, (CHAR*)"__offset", 9);
		OPM_WriteString((CHAR*)") ", 3);
		OPC_BegBlk();
		OPC_BegStat();
		OPM_WriteString((CHAR*)"UINT64 ", 8);
		OPV_AllName(range, (CHAR*)"__value", 8);
		OPM_WriteString((CHAR*)" = (UINT64)", 12);
		OPV_AllName(range, (CHAR*)"__start", 8);
		OPM_WriteString((CHAR*)" + ", 4);
		OPV_AllName(range, (CHAR*)"__offset", 9);
		OPC_EndStat();
		OPC_BegStat();
		OPC_Andent(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1372, 36, 64889))->typ);
		OPM_Write(' ');
		OPV_AllName(range, (CHAR*)"", 1);
		OPM_WriteString((CHAR*)" = ", 4);
		OPV_AllName(range, (CHAR*)"__value", 8);
		OPM_WriteString((CHAR*)" <= (UINT64)", 13);
		OPC_IntLiteral(OPM_SignedMaximum(8), 8);
		OPM_WriteString((CHAR*)" \? (INT64)", 11);
		OPV_AllName(range, (CHAR*)"__value", 8);
		OPM_WriteString((CHAR*)" : -1 - (INT64)~", 17);
		OPV_AllName(range, (CHAR*)"__value", 8);
		OPC_EndStat();
	}
	saved = OPV_parallelBody;
	savedRange = OPV_parallelRange;
	OPV_parallelBody = 1;
	OPV_parallelRange = range;
	OPV_DeclareAllLocals(range);
	OPV_stat(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1381, 11, 65370))->right, outerProc);
	OPV_parallelBody = saved;
	OPV_parallelRange = savedRange;
	OPC_EndBlk();
	OPC_EndBlk();
	OPC_CheckInterrupt();
	OPC_BegStat();
	OPC_BegBlk();
	OPC_BegStat();
	OPC_Andent(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1385, 34, 65557))->typ);
	OPM_Write(' ');
	OPV_AllName(range, (CHAR*)"", 1);
	OPM_WriteString((CHAR*)" = ", 4);
	OPV_AllName(range, (CHAR*)"__end", 6);
	OPC_EndStat();
	OPV_DeclareAllLocals(range);
	OPV_stat(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1388, 11, 65706))->right, outerProc);
	OPC_EndBlk();
	OPC_EndBlk();
	OPC_EndBlk();
}

static void OPV_AllStat (OPT_Node n, OPT_Object outerProc)
{
	OPT_Node range = NIL;
	range = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1395, 15, 65894))->left;
	OPC_BegBlk();
	OPC_BegStat();
	OPC_Andent(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1397, 34, 65951))->typ);
	OPM_Write(' ');
	OPC_Ident(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1397, 73, 65990))->obj);
	OPM_WriteString((CHAR*)" = ", 4);
	OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1398, 39, 66036))->left, -1);
	OPM_WriteString((CHAR*)", ", 3);
	OPC_Ident(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1399, 43, 66096))->obj);
	OPM_WriteString((CHAR*)"__end = ", 9);
	OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1400, 15, 66147))->right, -1);
	OPC_EndStat();
	OPC_BegStat();
	OPM_WriteString((CHAR*)"if (", 5);
	OPC_Ident(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1401, 58, 66236))->obj);
	OPM_WriteString((CHAR*)" <= ", 5);
	OPC_Ident(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1402, 45, 66288))->obj);
	OPM_WriteString((CHAR*)"__end) ", 8);
	OPC_BegBlk();
	OPC_BegStat();
	OPM_WriteString((CHAR*)"for (;;) ", 10);
	OPC_BegBlk();
	OPV_DeclareAllLocals(range);
	OPC_CheckInterrupt();
	OPV_stat(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1404, 56, 66450))->right, outerProc);
	OPC_BegStat();
	OPM_WriteString((CHAR*)"if (", 5);
	OPC_Ident(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1405, 58, 66528))->obj);
	OPM_WriteString((CHAR*)" == ", 5);
	OPC_Ident(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1406, 45, 66580))->obj);
	OPM_WriteString((CHAR*)"__end) break", 13);
	OPC_EndStat();
	OPC_BegStat();
	OPM_WriteString((CHAR*)"++", 3);
	OPC_Ident(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1407, 56, 66689))->obj);
	OPC_EndStat();
	OPC_EndBlk();
	OPC_EndBlk();
	OPC_EndBlk();
}

static void OPV_MultiAllLoops (OPT_Node range, OPT_Node body, OPT_Node locals, OPT_Object outerProc)
{
	BOOLEAN direct;
	direct = OPV_InclusiveAllRange(range);
	if (direct) {
		OPC_BegStat();
		OPM_WriteString((CHAR*)"for (", 6);
		OPC_Andent(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1416, 62, 66999))->typ);
		OPM_Write(' ');
		OPV_AllName(range, (CHAR*)"", 1);
		OPM_WriteString((CHAR*)" = ", 4);
		OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1417, 41, 67083))->left, -1);
		OPM_WriteString((CHAR*)"; ", 3);
		OPV_AllName(range, (CHAR*)"", 1);
		OPM_WriteString((CHAR*)" <= ", 5);
		OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1418, 85, 67185))->right, -1);
		OPM_WriteString((CHAR*)"; ++", 5);
		OPV_AllName(range, (CHAR*)"", 1);
		OPM_WriteString((CHAR*)") ", 3);
		OPC_BegBlk();
	} else {
		OPC_BegStat();
		OPC_Andent(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1421, 36, 67333))->typ);
		OPM_Write(' ');
		OPV_AllName(range, (CHAR*)"", 1);
		OPM_WriteString((CHAR*)" = ", 4);
		OPV_AllName(range, (CHAR*)"__start", 8);
		OPC_EndStat();
		OPC_BegStat();
		OPM_WriteString((CHAR*)"for (;;) ", 10);
		OPC_BegBlk();
	}
	if (((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1425, 13, 67528))->link != NIL) {
		OPV_MultiAllLoops(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1425, 50, 67565))->link, body, locals, outerProc);
	} else {
		OPV_DeclareAllLocals(locals);
		if (!OPV_parallelBody) {
			OPC_CheckInterrupt();
		}
		OPV_stat(body, outerProc);
	}
	if (!direct) {
		OPC_BegStat();
		OPM_WriteString((CHAR*)"if (", 5);
		OPV_AllName(range, (CHAR*)"", 1);
		OPM_WriteString((CHAR*)" == ", 5);
		OPV_AllName(range, (CHAR*)"__end", 6);
		OPM_WriteString((CHAR*)") break", 8);
		OPC_EndStat();
		OPC_BegStat();
		OPM_WriteString((CHAR*)"++", 3);
		OPV_AllName(range, (CHAR*)"", 1);
		OPC_EndStat();
	}
	OPC_EndBlk();
}

static void OPV_MultiAllStat (OPT_Node n, OPT_Object outerProc)
{
	OPT_Node range = NIL, previous = NIL, savedRange = NIL;
	BOOLEAN saved;
	OPC_BegBlk();
	range = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1442, 27, 68188))->left;
	previous = NIL;
	while (range != NIL) {
		OPC_BegStat();
		OPC_Andent(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1444, 36, 68273))->typ);
		OPM_Write(' ');
		OPV_AllName(range, (CHAR*)"__start", 8);
		OPM_WriteString((CHAR*)" = ", 4);
		if (((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1446, 15, 68368))->subcl == 1) {
			OPV_AllName(previous, (CHAR*)"__start", 8);
		} else {
			OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1446, 76, 68429))->left, -1);
		}
		OPC_EndStat();
		OPC_BegStat();
		OPC_Andent(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1448, 36, 68505))->typ);
		OPM_Write(' ');
		OPV_AllName(range, (CHAR*)"__end", 6);
		OPM_WriteString((CHAR*)" = ", 4);
		if (((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1450, 15, 68598))->subcl == 1) {
			OPV_AllName(previous, (CHAR*)"__end", 6);
		} else {
			OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1450, 74, 68657))->right, -1);
		}
		OPC_EndStat();
		previous = range;
		range = ((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1452, 40, 68738))->link;
	}
	OPC_BegStat();
	OPM_WriteString((CHAR*)"if (", 5);
	range = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1454, 53, 68806))->left;
	while (range != NIL) {
		OPV_AllName(range, (CHAR*)"__start", 8);
		OPM_WriteString((CHAR*)" <= ", 5);
		OPV_AllName(range, (CHAR*)"__end", 6);
		range = ((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1457, 21, 68942))->link;
		if (range != NIL) {
			OPM_WriteString((CHAR*)" && ", 5);
		}
	}
	OPM_WriteString((CHAR*)") ", 3);
	OPC_BegBlk();
	range = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1460, 50, 69062))->left;
	if (__IN(24, OPM_Options, 32)) {
		if (OPV_InclusiveAllRange(range)) {
			OPC_BegStat();
			OPM_WriteString((CHAR*)"#pragma omp parallel for schedule(static)", 42);
			OPM_WriteLn();
			OPC_BegStat();
			OPM_WriteString((CHAR*)"for (", 6);
			OPC_Andent(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1464, 64, 69311))->typ);
			OPM_Write(' ');
			OPV_AllName(range, (CHAR*)"", 1);
			OPM_WriteString((CHAR*)" = ", 4);
			OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1465, 43, 69397))->left, -1);
			OPM_WriteString((CHAR*)"; ", 3);
			OPV_AllName(range, (CHAR*)"", 1);
			OPM_WriteString((CHAR*)" <= ", 5);
			OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1466, 87, 69501))->right, -1);
			OPM_WriteString((CHAR*)"; ++", 5);
			OPV_AllName(range, (CHAR*)"", 1);
			OPM_WriteString((CHAR*)") ", 3);
			OPC_BegBlk();
			saved = OPV_parallelBody;
			savedRange = OPV_parallelRange;
			OPV_parallelBody = 1;
			OPV_parallelRange = range;
			OPV_MultiAllLoops(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1470, 28, 69749))->link, ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1470, 37, 69758))->right, range, outerProc);
			OPV_parallelBody = saved;
			OPV_parallelRange = savedRange;
			OPC_EndBlk();
			OPC_CheckInterrupt();
		} else {
			OPC_BegStat();
			OPM_WriteString((CHAR*)"UINT64 ", 8);
			OPV_AllName(range, (CHAR*)"__count", 8);
			OPM_WriteString((CHAR*)" = (UINT64)", 12);
			OPV_AllName(range, (CHAR*)"__end", 6);
			OPM_WriteString((CHAR*)" - (UINT64)", 12);
			OPV_AllName(range, (CHAR*)"__start", 8);
			OPC_EndStat();
			OPC_BegStat();
			OPM_WriteString((CHAR*)"UINT64 ", 8);
			OPV_AllName(range, (CHAR*)"__work", 7);
			OPM_WriteString((CHAR*)" = ", 4);
			OPV_AllName(range, (CHAR*)"__count", 8);
			OPM_WriteString((CHAR*)" == 0 \? 1 : ", 13);
			OPV_AllName(range, (CHAR*)"__count", 8);
			OPC_EndStat();
			OPC_BegStat();
			OPM_WriteString((CHAR*)"#pragma omp parallel for schedule(static)", 42);
			OPM_WriteLn();
			OPC_BegStat();
			OPM_WriteString((CHAR*)"for (UINT64 ", 13);
			OPV_AllName(range, (CHAR*)"__offset", 9);
			OPM_WriteString((CHAR*)" = 0; ", 7);
			OPV_AllName(range, (CHAR*)"__offset", 9);
			OPM_WriteString((CHAR*)" < ", 4);
			OPV_AllName(range, (CHAR*)"__work", 7);
			OPM_WriteString((CHAR*)"; ++", 5);
			OPV_AllName(range, (CHAR*)"__offset", 9);
			OPM_WriteString((CHAR*)") ", 3);
			OPC_BegBlk();
			OPC_BegStat();
			OPM_WriteString((CHAR*)"UINT64 ", 8);
			OPV_AllName(range, (CHAR*)"__value", 8);
			OPM_WriteString((CHAR*)" = (UINT64)", 12);
			OPV_AllName(range, (CHAR*)"__start", 8);
			OPM_WriteString((CHAR*)" + ", 4);
			OPV_AllName(range, (CHAR*)"__offset", 9);
			OPC_EndStat();
			OPC_BegStat();
			OPC_Andent(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1487, 38, 70972))->typ);
			OPM_Write(' ');
			OPV_AllName(range, (CHAR*)"", 1);
			OPM_WriteString((CHAR*)" = ", 4);
			OPV_AllName(range, (CHAR*)"__value", 8);
			OPM_WriteString((CHAR*)" <= (UINT64)", 13);
			OPC_IntLiteral(OPM_SignedMaximum(8), 8);
			OPM_WriteString((CHAR*)" \? (INT64)", 11);
			OPV_AllName(range, (CHAR*)"__value", 8);
			OPM_WriteString((CHAR*)" : -1 - (INT64)~", 17);
			OPV_AllName(range, (CHAR*)"__value", 8);
			OPC_EndStat();
			saved = OPV_parallelBody;
			savedRange = OPV_parallelRange;
			OPV_parallelBody = 1;
			OPV_parallelRange = range;
			OPV_MultiAllLoops(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1494, 28, 71449))->link, ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1494, 37, 71458))->right, range, outerProc);
			OPC_BegStat();
			OPM_WriteString((CHAR*)"if (", 5);
			OPV_AllName(range, (CHAR*)"__count", 8);
			OPM_WriteString((CHAR*)" != 0 && ", 10);
			OPV_AllName(range, (CHAR*)"__offset", 9);
			OPM_WriteString((CHAR*)" == ", 5);
			OPV_AllName(range, (CHAR*)"__count", 8);
			OPM_WriteString((CHAR*)" - 1) ", 7);
			OPC_BegBlk();
			OPC_BegStat();
			OPV_AllName(range, (CHAR*)"", 1);
			OPM_WriteString((CHAR*)" = ", 4);
			OPV_AllName(range, (CHAR*)"__end", 6);
			OPC_EndStat();
			OPV_MultiAllLoops(((OPT_Node)__NIL_AT((ADDRESS)(range), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1498, 28, 71846))->link, ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1498, 37, 71855))->right, range, outerProc);
			OPC_EndBlk();
			OPV_parallelBody = saved;
			OPV_parallelRange = savedRange;
			OPC_EndBlk();
			OPC_CheckInterrupt();
		}
	} else {
		OPV_MultiAllLoops(range, ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1502, 32, 72035))->right, range, outerProc);
	}
	OPC_EndBlk();
	OPC_EndBlk();
}

static void OPV_stat (OPT_Node n, OPT_Object outerProc)
{
	OPT_Object proc = NIL;
	OPV_ExitInfo saved;
	OPT_Node l = NIL, r = NIL;
	while ((n != NIL && OPM_noerr)) {
		OPM_errpos = OPM_Longint(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1511, 34, 72308))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1511, 42, 72316))->intval);
		if ((!OPV_parallelBody && !__IN(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1512, 29, 72355))->class, 0x044000, 32))) {
			OPC_CheckInterrupt();
		}
		if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1513, 11, 72431))->class != 14) {
			OPC_BegStat();
		}
		switch (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1514, 13, 72487))->class) {
			case 18: 
				if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1515, 26, 72523))->obj == NIL) {
					OPM_level += 1;
					OPV_stat(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1516, 46, 72604))->left, outerProc);
					OPM_level -= 1;
					OPC_GenEnumPtrs(((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1517, 52, 72691))->scope);
					OPV_DefineTDescs(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1518, 38, 72738))->right);
					OPC_EnterBody();
					OPV_InitTDescs(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1518, 75, 72775))->right);
					OPC_RegisterBody();
					OPM_WriteString((CHAR*)"/* BEGIN */", 12);
					OPM_WriteLn();
					OPV_stat(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1520, 30, 72900))->right, outerProc);
					OPC_ExitBody();
				} else {
					proc = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1522, 33, 73009))->obj;
					OPC_TypeDefs(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1523, 41, 73056))->scope), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1523, 48, 73063))->right, 0);
					if (!((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1524, 32, 73107))->scope), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1524, 39, 73114))->leaf) {
						OPC_DefineInter(proc);
					}
					OPM_level += 1;
					OPV_stat(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1525, 46, 73242))->left, proc);
					OPM_level -= 1;
					OPC_EnterProc(proc);
					OPV_stat(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1526, 51, 73323))->right, proc);
					OPC_ExitProc(proc, 1, OPV_ImplicitReturn(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1527, 65, 73403))->right));
				}
				break;
			case 14: 
				break;
			case 19: 
				switch (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1530, 28, 73514))->subcl) {
					case 0: 
						l = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1531, 45, 73569))->left;
						r = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1531, 59, 73583))->right;
						if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1532, 43, 73634))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1532, 48, 73639))->comp == 2) {
							OPM_WriteString((CHAR*)"__MOVE(", 8);
							OPV_expr(r, -1);
							OPM_WriteString((CHAR*)", ", 3);
							OPV_expr(l, -1);
							OPM_WriteString((CHAR*)", ", 3);
							if (((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1535, 45, 73944))->typ == OPT_stringtyp) {
								OPM_WriteInt(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1535, 86, 73985))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1535, 94, 73993))->intval2);
							} else if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1536, 48, 74051))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1536, 52, 74055))->comp == 3) {
								OPM_WriteString((CHAR*)"__X_AT(", 8);
								OPV_Len(r, 0);
								OPM_WriteString((CHAR*)" * ", 4);
								OPM_WriteInt(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1539, 92, 74316))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1539, 96, 74320))->BaseTyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1539, 104, 74328))->size);
								OPM_WriteString((CHAR*)", ", 3);
								OPM_WriteInt(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1541, 57, 74457))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1541, 61, 74461))->size + 1);
								OPC_SourceLocation(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1542, 63, 74579))->pos);
								OPM_Write(')');
							} else {
								__ASSERT(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1545, 51, 74766))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1545, 55, 74770))->comp == 2, 0);
								__ASSERT(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1545, 83, 74798))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1545, 87, 74802))->size <= ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1545, 97, 74812))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1545, 101, 74816))->size, 0);
								OPM_WriteInt(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1546, 57, 74880))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1546, 62, 74885))->size);
							}
							OPM_Write(')');
						} else {
							if ((((((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1550, 46, 75088))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1550, 51, 75093))->form == 11 && ((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1550, 77, 75119))->obj != NIL)) && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1550, 94, 75136))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1550, 99, 75141))->adr == 1)) && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1550, 114, 75156))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1550, 119, 75161))->mode == 1)) {
								((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1551, 44, 75227))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1551, 49, 75232))->adr = 0;
								OPV_design(l, -1);
								((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1551, 82, 75265))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1551, 87, 75270))->adr = 1;
								if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1552, 47, 75367))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1552, 52, 75372))->form != 9) {
									OPM_WriteString((CHAR*)" = (void*)", 11);
								} else {
									OPM_WriteString((CHAR*)" = ", 4);
								}
							} else {
								OPV_design(l, -1);
								OPM_WriteString((CHAR*)" = ", 4);
							}
							if (((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1558, 45, 75763))->typ == ((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1558, 54, 75772))->typ) {
								OPV_expr(r, -1);
							} else if ((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1559, 49, 75848))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1559, 54, 75853))->form == 11 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1559, 80, 75879))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1559, 85, 75884))->form != 9)) {
								if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1560, 47, 75956))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1560, 52, 75961))->strobj != NIL) {
									OPM_Write('(');
									OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1561, 72, 76052))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1561, 77, 76057))->strobj);
									OPM_Write(')');
								} else if ((((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1562, 51, 76133))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1562, 56, 76138))->BaseTyp != NIL && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1562, 77, 76159))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1562, 82, 76164))->BaseTyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1562, 91, 76173))->strobj != NIL)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1563, 49, 76237))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1563, 54, 76242))->BaseTyp != ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(r), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1563, 67, 76255))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1563, 72, 76260))->BaseTyp)) {
									OPM_Write('(');
									OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1564, 72, 76347))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1564, 77, 76352))->BaseTyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1564, 86, 76361))->strobj);
									OPM_WriteString((CHAR*)"*)", 3);
								}
								OPV_expr(r, -1);
							} else if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1567, 48, 76547))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1567, 53, 76552))->comp == 4) {
								OPM_WriteString((CHAR*)"*(", 3);
								OPC_Andent(((OPT_Node)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1568, 78, 76654))->typ);
								OPM_WriteString((CHAR*)"*)&", 4);
								OPV_expr(r, 9);
							} else {
								OPV_expr(r, -1);
							}
						}
						break;
					case 1: 
						if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1572, 43, 76887))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1572, 49, 76893))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1572, 54, 76898))->BaseTyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1572, 63, 76907))->comp == 4) {
							OPM_WriteString((CHAR*)"__NEW(", 7);
							OPV_design(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1573, 76, 77007))->left, -1);
							OPM_WriteString((CHAR*)", ", 3);
							OPC_Andent(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1574, 53, 77100))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1574, 59, 77106))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1574, 64, 77111))->BaseTyp);
							OPM_WriteString((CHAR*)")", 2);
						} else if (__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1575, 46, 77189))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1575, 52, 77195))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1575, 57, 77200))->BaseTyp), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1575, 66, 77209))->comp, 0x0c, 32)) {
							OPV_NewArr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1576, 49, 77296))->left, ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1576, 58, 77305))->right);
						}
						break;
					case 13: case 14: 
						OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1579, 45, 77434))->left, -1);
						OPC_Increment(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1579, 78, 77467))->subcl == 14);
						OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1579, 106, 77495))->right, -1);
						break;
					case 15: case 16: 
						OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1581, 45, 77592))->left, -1);
						OPC_SetInclude(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1581, 79, 77626))->subcl == 16);
						OPM_WriteString((CHAR*)"__SETOF(", 9);
						OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1582, 74, 77722))->right, -1);
						OPM_WriteString((CHAR*)",", 2);
						OPM_WriteInt(__ASHL(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1583, 75, 77815))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1583, 80, 77820))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1583, 84, 77824))->size, 3));
						OPM_Write(')');
						break;
					case 18: 
						OPM_WriteString((CHAR*)"__COPY(", 8);
						OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1585, 45, 77965))->right, -1);
						OPM_WriteString((CHAR*)", ", 3);
						OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1585, 94, 78014))->left, -1);
						OPM_WriteString((CHAR*)", ", 3);
						OPV_Len(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1586, 44, 78099))->left, 0);
						OPM_Write(')');
						break;
					case 31: 
						OPM_WriteString((CHAR*)"__MOVE(", 8);
						OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1589, 45, 78291))->right, -1);
						OPM_WriteString((CHAR*)", ", 3);
						OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1589, 94, 78340))->left, -1);
						OPM_WriteString((CHAR*)", ", 3);
						OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1590, 45, 78426))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1590, 52, 78433))->link, -1);
						OPM_Write(')');
						break;
					case 24: 
						OPM_WriteString((CHAR*)"__GET(", 7);
						OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1593, 71, 78630))->right, -1);
						OPM_WriteString((CHAR*)", ", 3);
						OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1593, 120, 78679))->left, -1);
						OPM_WriteString((CHAR*)", ", 3);
						OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1594, 74, 78770))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1594, 80, 78776))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1594, 85, 78781))->strobj);
						OPM_Write(')');
						break;
					case 25: 
						OPM_WriteString((CHAR*)"__PUT(", 7);
						OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1596, 71, 78933))->left, -1);
						OPM_WriteString((CHAR*)", ", 3);
						OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1596, 119, 78981))->right, -1);
						OPM_WriteString((CHAR*)", ", 3);
						OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1597, 74, 79073))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1597, 81, 79080))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1597, 86, 79085))->strobj);
						OPM_Write(')');
						break;
					case 26: case 27: 
						OPM_err(200);
						break;
					case 30: 
						OPM_WriteString((CHAR*)"__SYSNEW(", 10);
						OPV_design(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1602, 47, 79392))->left, -1);
						OPM_WriteString((CHAR*)", ", 3);
						OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1603, 45, 79477))->right, -1);
						OPM_Write(')');
						break;
					default: 
						OPM_LogWStr((CHAR*)"unhandled case in OPV.expr, n^.subcl = ", 40);
						OPM_LogWNum(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1605, 95, 79643))->subcl, 0);
						OPM_LogWLn();
						break;
				}
				break;
			case 13: 
				if ((((__IN(20, OPM_Options, 32) && ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1607, 61, 79753))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1607, 66, 79758))->obj != NIL)) && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1607, 82, 79774))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1607, 87, 79779))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1607, 91, 79783))->mode == 9)) {
					OPM_WriteString((CHAR*)"SYSTEM_CommandCritical(1)", 26);
					OPC_EndStat();
					OPC_BegStat();
				}
				if ((((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1610, 27, 79953))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1610, 33, 79959))->obj != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1610, 50, 79976))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1610, 56, 79982))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1610, 61, 79987))->mode == 13)) {
					if (((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1611, 28, 80039))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1611, 34, 80045))->subcl == 1) {
						proc = OPV_SuperProc(n);
					} else {
						OPM_WriteString((CHAR*)"__", 3);
						proc = OPC_BaseTProc(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1612, 75, 80165))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1612, 81, 80171))->obj);
					}
					OPC_Ident(proc);
					((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1615, 25, 80271))->obj = ((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1615, 38, 80284))->link;
				} else if (((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1616, 29, 80319))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1616, 35, 80325))->class == 9) {
					OPV_design(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1616, 68, 80358))->left, 10);
				} else {
					OPV_Pointer(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1617, 36, 80405))->left, 11, n);
				}
				OPV_ActualPar(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1619, 33, 80488))->right, ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1619, 43, 80498))->obj, (((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1619, 52, 80507))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1619, 58, 80513))->obj != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1619, 75, 80530))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1619, 81, 80536))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1619, 86, 80541))->mode == 13), n);
				if ((((__IN(20, OPM_Options, 32) && ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1620, 61, 80626))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1620, 66, 80631))->obj != NIL)) && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1620, 82, 80647))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1620, 87, 80652))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1620, 91, 80656))->mode == 9)) {
					OPC_EndStat();
					OPC_BegStat();
					OPM_WriteString((CHAR*)"SYSTEM_CommandCritical(0)", 26);
				}
				break;
			case 20: 
				if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1623, 26, 80824))->subcl != 32) {
					OPV_IfStat(n, 0, outerProc);
				} else if (__IN(7, OPM_Options, 32)) {
					OPM_WriteString((CHAR*)"__ASSERT(", 10);
					OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1625, 60, 80997))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1625, 66, 81003))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1625, 72, 81009))->left, -1);
					OPM_WriteString((CHAR*)", ", 3);
					OPM_WriteInt(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1626, 38, 81088))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1626, 44, 81094))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1626, 51, 81101))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1626, 58, 81108))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1626, 66, 81116))->intval);
					OPM_Write(')');
					OPC_EndStat();
				}
				break;
			case 21: 
				OPV_exit.level += 1;
				OPV_CaseStat(n, outerProc);
				OPV_exit.level -= 1;
				break;
			case 29: 
				if (__IN(25, OPM_Options, 32)) {
					OPV_GPUAllStat(n, outerProc);
				} else if (((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1630, 29, 81378))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1630, 35, 81384))->link != NIL) {
					OPV_MultiAllStat(n, outerProc);
				} else if (__IN(24, OPM_Options, 32)) {
					OPV_ParallelAllStat(n, outerProc);
				} else {
					OPV_AllStat(n, outerProc);
				}
				break;
			case 22: 
				OPV_exit.level += 1;
				OPM_WriteString((CHAR*)"while ", 7);
				OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1634, 72, 81666))->left, 12);
				OPM_Write(' ');
				OPC_BegBlk();
				OPC_CheckInterrupt();
				OPV_stat(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1635, 78, 81761))->right, outerProc);
				OPC_EndBlk();
				OPV_exit.level -= 1;
				break;
			case 23: 
				OPV_exit.level += 1;
				OPM_WriteString((CHAR*)"do ", 4);
				OPC_BegBlk();
				OPC_CheckInterrupt();
				OPV_stat(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1637, 101, 81931))->left, outerProc);
				OPC_EndBlk0();
				OPM_WriteString((CHAR*)" while (!", 10);
				OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1638, 59, 82022))->right, 9);
				OPM_Write(')');
				OPV_exit.level -= 1;
				break;
			case 24: 
				saved = OPV_exit;
				OPV_exit.level = 0;
				OPV_exit.label = -1;
				OPM_WriteString((CHAR*)"for (;;) ", 10);
				OPC_BegBlk();
				OPC_CheckInterrupt();
				OPV_stat(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1641, 90, 82255))->left, outerProc);
				OPC_EndBlk();
				if (OPV_exit.label != -1) {
					OPC_BegStat();
					OPM_WriteString((CHAR*)"exit__", 7);
					OPM_WriteInt(OPV_exit.label);
					OPM_Write(':');
					OPC_EndStat();
				}
				OPV_exit = saved;
				break;
			case 25: 
				if (OPV_exit.level == 0) {
					OPM_WriteString((CHAR*)"break", 6);
				} else {
					if (OPV_exit.label == -1) {
						OPV_exit.label = OPV_nofExitLabels;
						OPV_nofExitLabels += 1;
					}
					OPM_WriteString((CHAR*)"goto exit__", 12);
					OPM_WriteInt(OPV_exit.label);
				}
				break;
			case 26: 
				if (OPM_level == 0) {
					OPC_FinishBody();
					OPC_BegStat();
					if (__IN(10, OPM_Options, 32)) {
						OPM_WriteString((CHAR*)"__FINI", 7);
					} else {
						OPM_WriteString((CHAR*)"__ENDMOD", 9);
					}
				} else if (OPC_NeedsRetval(outerProc)) {
					OPM_WriteString((CHAR*)"__retval = ", 12);
					if ((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1656, 29, 83169))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1656, 35, 83175))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1656, 40, 83180))->form == 11 && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1656, 66, 83206))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1656, 71, 83211))->typ != ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1656, 80, 83220))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1656, 86, 83226))->typ)) {
						OPM_WriteString((CHAR*)"(void*)", 8);
						OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1657, 60, 83297))->left, 10);
					} else {
						OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1659, 32, 83368))->left, -1);
					}
					OPC_EndStat();
					OPC_BegStat();
					OPC_ExitProc(outerProc, 0, 0);
					OPC_EndStat();
					OPC_BegStat();
					OPM_WriteString((CHAR*)"return __retval", 16);
				} else {
					OPC_ExitProc(outerProc, 0, 0);
					OPM_WriteString((CHAR*)"return", 7);
					if (((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1667, 28, 83775))->left != NIL) {
						OPM_Write(' ');
						if ((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1669, 31, 83866))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1669, 37, 83872))->typ), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1669, 42, 83877))->form == 11 && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1669, 68, 83903))->obj), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1669, 73, 83908))->typ != ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1669, 82, 83917))->left), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1669, 88, 83923))->typ)) {
							OPM_WriteString((CHAR*)"(void*)", 8);
							OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1670, 62, 83996))->left, 10);
						} else {
							OPV_expr(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1672, 34, 84071))->left, -1);
						}
					}
				}
				break;
			case 27: 
				OPV_IfStat(n, ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1676, 33, 84201))->subcl == 0, outerProc);
				break;
			case 28: 
				OPC_Halt(OPM_Longint(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1677, 44, 84268))->right), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1677, 51, 84275))->conval), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1677, 59, 84283))->intval));
				break;
			default: 
				OPM_LogWStr((CHAR*)"unhandled case in OPV.expr, n^.class = ", 40);
				OPM_LogWNum(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1678, 81, 84374))->class, 0);
				OPM_LogWLn();
				break;
		}
		if (!__IN(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1680, 13, 84422))->class, 0x29744000, 32)) {
			OPC_EndStat();
		}
		n = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1681, 13, 84563))->link;
	}
}

void OPV_Module (OPT_Node prog)
{
	if (!__IN(10, OPM_Options, 32)) {
		OPC_GenHdr(((OPT_Node)__NIL_AT((ADDRESS)(prog), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1687, 59, 84694))->right);
		OPC_GenHdrIncludes();
	}
	OPC_GenBdy(((OPT_Node)__NIL_AT((ADDRESS)(prog), (CHAR*)"../../src/compiler/OPV.Mod", 27, (CHAR*)"OPV", 4, 1688, 20, 84748))->right);
	OPV_ReductionHelpers(prog);
	OPV_stat(prog, NIL);
}

static void EnumPtrs(void (*P)(void*))
{
	P(OPV_parallelRange);
	P(OPV_gpuRange);
	P(OPV_gpuValues);
	P(OPV_reductions);
}

__TDESC(OPV_ExitInfo, 1, 0) = {__TDFLDS("ExitInfo", 4), {-8}};
__TDESC(OPV_GPUValueDesc, 1, 2) = {__TDFLDS("GPUValueDesc", 48), {0, 8, -24}};
__TDESC(OPV_ReductionDesc, 1, 3) = {__TDFLDS("ReductionDesc", 24), {0, 8, 16, -32}};

export void *OPV__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(OPC);
	__MODULE_IMPORT(OPM);
	__MODULE_IMPORT(OPS);
	__MODULE_IMPORT(OPT);
	__REGMOD("OPV", EnumPtrs);
	__REGCMD("Init", OPV_Init);
	__INITYP(OPV_ExitInfo, OPV_ExitInfo, 0);
	__INITYP(OPV_GPUValueDesc, OPV_GPUValueDesc, 0);
	__INITYP(OPV_ReductionDesc, OPV_ReductionDesc, 0);
/* BEGIN */
	__ENDMOD;
}
