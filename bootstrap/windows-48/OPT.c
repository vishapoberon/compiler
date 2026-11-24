/* voc 5.4.1 [2026/11/24] for gcc LP64 on gentoo xnrtspaSF */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32

#include "SYSTEM.h"
#include "OPM.h"
#include "OPS.h"

typedef
	struct OPT_ConstDesc *OPT_Const;

typedef
	OPS_String *OPT_ConstExt;

typedef
	struct OPT_ConstDesc {
		OPT_ConstExt ext;
		INT64 intval;
		INT32 intval2;
		UINT64 setval;
		LONGREAL realval;
	} OPT_ConstDesc;

typedef
	struct OPT_ExpCtxt {
		INT32 reffp;
		INT16 ref;
		INT8 nofm;
		INT8 locmno[64];
	} OPT_ExpCtxt;

typedef
	struct OPT_StrDesc *OPT_Struct;

typedef
	struct OPT_ObjDesc *OPT_Object;

typedef
	struct OPT_ImpCtxt {
		INT32 nextTag, reffp;
		INT16 nofr, minr, nofm;
		BOOLEAN self;
		OPT_Struct ref[255];
		OPT_Object old[255];
		INT32 pvfp[255];
		INT8 glbmno[64];
	} OPT_ImpCtxt;

typedef
	struct OPT_LinkDesc *OPT_Link;

typedef
	struct OPT_LinkDesc {
		OPS_Name name;
		OPT_Link next;
	} OPT_LinkDesc;

typedef
	struct OPT_NodeDesc *OPT_Node;

typedef
	struct OPT_NodeDesc {
		OPT_Node left, right, link;
		INT8 class, subcl;
		BOOLEAN readonly;
		INT32 pos;
		OPT_Struct typ;
		OPT_Object obj;
		OPT_Const conval;
	} OPT_NodeDesc;

typedef
	struct OPT_ObjDesc {
		OPT_Object left, right, link, scope;
		OPS_Name name;
		BOOLEAN leaf;
		INT8 mode, mnolev, vis, history;
		BOOLEAN used, fpdone;
		INT32 fprint;
		OPT_Struct typ;
		OPT_Const conval;
		INT32 adr, linkadr;
		INT16 x;
		OPT_ConstExt comment;
	} OPT_ObjDesc;

typedef
	struct OPT_StrDesc {
		INT8 form, comp, mno, extlev;
		INT16 ref, sysflag;
		INT32 n, size, align, txtpos;
		BOOLEAN allocated, pbused, pvused, fpdone, idfpdone;
		INT32 idfp, pbfp, pvfp;
		OPT_Struct BaseTyp;
		OPT_Object link, strobj;
	} OPT_StrDesc;


export OPT_Object OPT_topScope;
export OPT_Struct OPT_undftyp, OPT_niltyp, OPT_notyp, OPT_bytetyp, OPT_cpbytetyp, OPT_booltyp, OPT_chartyp, OPT_sinttyp, OPT_inttyp, OPT_linttyp, OPT_hinttyp, OPT_int8typ, OPT_int16typ, OPT_int32typ, OPT_int64typ, OPT_settyp, OPT_set32typ, OPT_set64typ, OPT_realtyp, OPT_lrltyp, OPT_stringtyp, OPT_adrtyp, OPT_sysptrtyp;
export OPT_Object OPT_sintobj, OPT_intobj, OPT_lintobj, OPT_setobj;
export INT8 OPT_nofGmod;
export OPT_Object OPT_GlbMod[64];
export OPS_Name OPT_SelfName;
export BOOLEAN OPT_SYSimported;
static OPT_Object OPT_universe, OPT_syslink;
static OPT_ImpCtxt OPT_impCtxt;
static OPT_ExpCtxt OPT_expCtxt;
static INT32 OPT_nofhdfld;
static BOOLEAN OPT_newsf, OPT_findpc, OPT_extsf, OPT_sfpresent, OPT_symExtended, OPT_symNew;
static INT32 OPT_recno;
export OPT_Link OPT_Links;

export ADDRESS *OPT_ConstDesc__typ;
export ADDRESS *OPT_ObjDesc__typ;
export ADDRESS *OPT_StrDesc__typ;
export ADDRESS *OPT_NodeDesc__typ;
export ADDRESS *OPT_ImpCtxt__typ;
export ADDRESS *OPT_ExpCtxt__typ;
export ADDRESS *OPT_LinkDesc__typ;

export void OPT_Align (INT32 *adr, INT32 base);
export INT32 OPT_BaseAlignment (OPT_Struct typ);
export void OPT_Close (void);
export void OPT_CloseScope (void);
static void OPT_DebugStruct (OPT_Struct btyp);
static void OPT_EnterBoolConst (CHAR *name, INT32 value);
static void OPT_EnterProc (CHAR *name, INT16 num);
static void OPT_EnterTyp (CHAR *name, INT8 form, INT16 size, OPT_Struct *res);
static void OPT_EnterTypeAlias (CHAR *name, OPT_Object *res);
export void OPT_Export (BOOLEAN *ext, BOOLEAN *new);
export void OPT_FPrintErr (OPT_Object obj, INT16 errcode);
static void OPT_FPrintName (INT32 *fp, CHAR *name, ADDRESS name__len);
export void OPT_FPrintObj (OPT_Object obj);
static void OPT_FPrintSign (INT32 *fp, OPT_Struct result, OPT_Object par);
export void OPT_FPrintStr (OPT_Struct typ);
export void OPT_Find (OPT_Object *res);
export void OPT_FindField (CHAR *name, OPT_Struct typ, OPT_Object *res);
export void OPT_FindImport (OPT_Object mod, OPT_Object *res);
export void OPT_IdFPrint (OPT_Struct typ);
export void OPT_Import (CHAR *aliasName, CHAR *name, BOOLEAN *done);
static void OPT_InConstant (INT32 f, OPT_Const conval);
static OPT_Object OPT_InFld (void);
static void OPT_InLinks (void);
static void OPT_InMod (INT8 *mno);
static void OPT_InName (CHAR *name, ADDRESS name__len);
static OPT_Object OPT_InObj (INT8 mno);
static void OPT_InSign (INT8 mno, OPT_Struct *res, OPT_Object *par);
static void OPT_InStruct (OPT_Struct *typ);
static OPT_Object OPT_InTProc (INT8 mno);
static OPT_Struct OPT_InTyp (INT32 tag);
export void OPT_Init (CHAR *name, UINT32 opt);
export void OPT_InitRecno (void);
static void OPT_InitStruct (OPT_Struct *typ, INT8 form);
export void OPT_Insert (CHAR *name, OPT_Object *obj);
export void OPT_InsertImport (OPT_Object obj, OPT_Object *root, OPT_Object *old);
export INT16 OPT_IntSize (INT64 n);
export OPT_Struct OPT_IntType (INT32 size);
export OPT_Const OPT_NewConst (void);
export OPT_ConstExt OPT_NewExt (void);
export OPT_Node OPT_NewNode (INT8 class);
export OPT_Object OPT_NewObj (void);
export OPT_Struct OPT_NewStr (INT8 form, INT8 comp);
export void OPT_OpenScope (INT8 level, OPT_Object owner);
static void OPT_OutConstant (OPT_Object obj);
static void OPT_OutFlds (OPT_Object fld, INT32 adr, BOOLEAN visible);
static void OPT_OutHdFld (OPT_Struct typ, OPT_Object fld, INT32 adr);
static void OPT_OutLinks (void);
static void OPT_OutMod (INT16 mno);
static void OPT_OutName (CHAR *name, ADDRESS name__len);
static void OPT_OutObj (OPT_Object obj);
static void OPT_OutSign (OPT_Struct result, OPT_Object par);
static void OPT_OutStr (OPT_Struct typ);
static void OPT_OutTProcs (OPT_Struct typ, OPT_Object obj);
static void OPT_OutTruncatedName (CHAR *text, ADDRESS text__len);
export OPT_Struct OPT_SetType (INT32 size);
export OPT_Struct OPT_ShorterOrLongerType (OPT_Struct x, INT16 dir);
export INT32 OPT_SizeAlignment (INT32 size);
export void OPT_TypSize (OPT_Struct typ);
static void OPT_err (INT16 n);


void OPT_InitRecno (void)
{
	OPT_recno = 0;
}

static void OPT_err (INT16 n)
{
	OPM_err(n);
}

INT16 OPT_IntSize (INT64 n)
{
	INT16 bytes;
	if (n < 0) {
		n = -(n + 1);
	}
	bytes = 1;
	while ((bytes < 8 && __ASH(n, -(__ASHL(bytes, 3) - 1)) != 0)) {
		bytes += 1;
	}
	return bytes;
}

OPT_Struct OPT_IntType (INT32 size)
{
	if (size <= ((OPT_Struct)__NIL_AT((ADDRESS)(OPT_int8typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 247, 21, 8070))->size) {
		return OPT_int8typ;
	}
	if (size <= ((OPT_Struct)__NIL_AT((ADDRESS)(OPT_int16typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 248, 22, 8124))->size) {
		return OPT_int16typ;
	}
	if (size <= ((OPT_Struct)__NIL_AT((ADDRESS)(OPT_int32typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 249, 22, 8177))->size) {
		return OPT_int32typ;
	}
	return OPT_int64typ;
}

OPT_Struct OPT_SetType (INT32 size)
{
	if (size == ((OPT_Struct)__NIL_AT((ADDRESS)(OPT_set32typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 255, 21, 8310))->size) {
		return OPT_set32typ;
	}
	return OPT_set64typ;
}

OPT_Struct OPT_ShorterOrLongerType (OPT_Struct x, INT16 dir)
{
	INT16 i;
	__ASSERT(((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 262, 11, 8473))->form == 4, 0);
	__ASSERT(((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 263, 11, 8497))->BaseTyp == OPT_undftyp, 0);
	__ASSERT(dir == 1 || dir == -1, 0);
	if (dir > 0) {
		if (((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 266, 9, 8579))->size < ((OPT_Struct)__NIL_AT((ADDRESS)(OPT_sinttyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 266, 24, 8594))->size) {
			return OPT_sinttyp;
		}
		if (((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 267, 9, 8633))->size < ((OPT_Struct)__NIL_AT((ADDRESS)(OPT_inttyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 267, 23, 8647))->size) {
			return OPT_inttyp;
		}
		if (((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 268, 9, 8687))->size < ((OPT_Struct)__NIL_AT((ADDRESS)(OPT_linttyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 268, 24, 8702))->size) {
			return OPT_linttyp;
		}
		return OPT_int64typ;
	} else {
		if (((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 271, 9, 8768))->size > ((OPT_Struct)__NIL_AT((ADDRESS)(OPT_linttyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 271, 24, 8783))->size) {
			return OPT_linttyp;
		}
		if (((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 272, 9, 8822))->size > ((OPT_Struct)__NIL_AT((ADDRESS)(OPT_inttyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 272, 23, 8836))->size) {
			return OPT_inttyp;
		}
		if (((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 273, 9, 8876))->size > ((OPT_Struct)__NIL_AT((ADDRESS)(OPT_sinttyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 273, 24, 8891))->size) {
			return OPT_sinttyp;
		}
		return OPT_int8typ;
	}
	__RETCHK;
}

void OPT_Align (INT32 *adr, INT32 base)
{
	switch (base) {
		case 2: 
			*adr += __MASK(*adr, -2);
			break;
		case 4: 
			*adr += __MASK(-*adr, -4);
			break;
		case 8: 
			*adr += __MASK(-*adr, -8);
			break;
		case 16: 
			*adr += __MASK(-*adr, -16);
			break;
		default: 
			break;
	}
}

INT32 OPT_SizeAlignment (INT32 size)
{
	INT32 alignment;
	if (size < OPM_Alignment) {
		alignment = 1;
		while (alignment < size) {
			alignment = __ASHL(alignment, 1);
		}
	} else {
		alignment = OPM_Alignment;
	}
	return alignment;
}

INT32 OPT_BaseAlignment (OPT_Struct typ)
{
	INT32 alignment;
	if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 305, 9, 9694))->form == 13) {
		if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 306, 11, 9722))->comp == 4) {
			alignment = __MASK(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 307, 23, 9764))->align, -65536);
		} else {
			alignment = OPT_BaseAlignment(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 309, 37, 9827))->BaseTyp);
		}
	} else {
		alignment = OPT_SizeAlignment(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 312, 35, 9886))->size);
	}
	return alignment;
}

void OPT_TypSize (OPT_Struct typ)
{
	INT16 f, c;
	INT32 offset, size, base, fbase, off0;
	OPT_Object fld = NIL;
	OPT_Struct btyp = NIL;
	if (typ == OPT_undftyp) {
		OPM_err(58);
	} else if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 324, 12, 10127))->size == -1) {
		f = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 325, 13, 10155))->form;
		c = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 326, 13, 10174))->comp;
		if (c == 4) {
			btyp = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 327, 35, 10215))->BaseTyp;
			if (btyp == NIL) {
				offset = 0;
				base = 1;
			} else {
				OPT_TypSize(btyp);
				offset = ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 329, 41, 10314))->size - __ASHR(((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 329, 53, 10326))->sysflag, 8);
				base = ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 329, 84, 10357))->align;
			}
			fld = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 331, 17, 10392))->link;
			while ((fld != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 332, 31, 10429))->mode == 4)) {
				btyp = ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 333, 20, 10464))->typ;
				OPT_TypSize(btyp);
				size = ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 334, 21, 10505))->size;
				fbase = OPT_BaseAlignment(btyp);
				OPT_Align(&offset, fbase);
				((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 337, 12, 10591))->adr = offset;
				offset += size;
				if (fbase > base) {
					base = fbase;
				}
				fld = ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 339, 19, 10692))->link;
			}
			off0 = offset;
			if (offset == 0) {
				offset = 1;
			}
			OPT_Align(&offset, base);
			if ((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 345, 14, 10915))->strobj == NIL && __MASK(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 345, 36, 10937))->align, -65536) == 0)) {
				OPT_recno += 1;
				base += __ASHL(OPT_recno, 16);
			}
			((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 346, 10, 11018))->size = offset;
			((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 347, 10, 11044))->align = base;
			((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 349, 10, 11170))->sysflag = __MASK(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 349, 26, 11186))->sysflag, -256) + __SHORT(__ASHL(offset - off0, 8), 32768);
		} else if (c == 2) {
			OPT_TypSize(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 351, 18, 11277))->BaseTyp);
			((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 352, 10, 11297))->size = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 352, 22, 11309))->n * ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 352, 30, 11317))->BaseTyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 352, 38, 11325))->size;
		} else if (f == 11) {
			((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 354, 10, 11368))->size = OPM_AddressSize;
			if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 355, 13, 11406))->BaseTyp == OPT_undftyp) {
				OPM_Mark(128, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 355, 54, 11447))->n);
			} else {
				OPT_TypSize(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 356, 23, 11473))->BaseTyp);
			}
		} else if (f == 12) {
			((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 359, 10, 11529))->size = OPM_AddressSize;
		} else if (c == 3) {
			btyp = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 361, 18, 11598))->BaseTyp;
			OPT_TypSize(btyp);
			if (((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 362, 14, 11636))->comp == 3) {
				((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 362, 37, 11659))->size = ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 362, 50, 11672))->size + 4;
			} else {
				((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 363, 15, 11726))->size = 8;
			}
		}
	}
}

OPT_Const OPT_NewConst (void)
{
	OPT_Const const_ = NIL;
	__NEW(const_, OPT_ConstDesc);
	return const_;
}

OPT_Object OPT_NewObj (void)
{
	OPT_Object obj = NIL;
	__NEW(obj, OPT_ObjDesc);
	((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 380, 7, 11978))->typ = NIL;
	((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 381, 7, 11998))->conval = NIL;
	((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 382, 7, 12021))->comment = NIL;
	((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 383, 7, 12045))->name[0] = 0x00;
	return obj;
}

OPT_Struct OPT_NewStr (INT8 form, INT8 comp)
{
	OPT_Struct typ = NIL;
	__NEW(typ, OPT_StrDesc);
	((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 390, 20, 12174))->form = form;
	((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 390, 39, 12193))->comp = comp;
	((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 390, 58, 12212))->ref = 255;
	if (form != 0) {
		((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 391, 27, 12300))->txtpos = OPM_errpos;
	}
	((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 392, 6, 12392))->size = -1;
	((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 392, 23, 12409))->BaseTyp = OPT_undftyp;
	return typ;
}

OPT_Node OPT_NewNode (INT8 class)
{
	OPT_Node node = NIL;
	__NEW(node, OPT_NodeDesc);
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 397, 22, 12537))->class = class;
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 397, 44, 12559))->pos = OPS_pos;
	return node;
}

OPT_ConstExt OPT_NewExt (void)
{
	OPT_ConstExt ext = NIL;
	ext = __NEWARR(NIL, 1, 1, 1, 0, 1024);
	return ext;
}

void OPT_OpenScope (INT8 level, OPT_Object owner)
{
	OPT_Object head = NIL;
	head = OPT_NewObj();
	((OPT_Object)__NIL_AT((ADDRESS)(head), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 408, 7, 12799))->mode = 12;
	((OPT_Object)__NIL_AT((ADDRESS)(head), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 408, 27, 12819))->mnolev = level;
	((OPT_Object)__NIL_AT((ADDRESS)(head), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 408, 50, 12842))->link = owner;
	if (owner != NIL) {
		((OPT_Object)__NIL_AT((ADDRESS)(owner), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 409, 28, 12886))->scope = head;
	}
	((OPT_Object)__NIL_AT((ADDRESS)(head), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 410, 7, 12913))->left = OPT_topScope;
	((OPT_Object)__NIL_AT((ADDRESS)(head), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 410, 31, 12937))->right = NIL;
	((OPT_Object)__NIL_AT((ADDRESS)(head), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 410, 51, 12957))->scope = NIL;
	OPT_topScope = head;
}

void OPT_CloseScope (void)
{
	OPT_topScope = ((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 414, 27, 13055))->left;
}

void OPT_Init (CHAR *name, UINT32 opt)
{
	OPT_topScope = OPT_universe;
	OPT_OpenScope(0, NIL);
	OPT_SYSimported = 0;
	__MOVE(name, OPT_SelfName, 256);
	__MOVE(name, ((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 421, 29, 13260))->name, 256);
	OPT_GlbMod[0] = OPT_topScope;
	OPT_nofGmod = 1;
	OPT_newsf = __IN(4, opt, 32);
	OPT_findpc = __IN(8, opt, 32);
	OPT_extsf = OPT_newsf || __IN(9, opt, 32);
	OPT_sfpresent = 1;
	__NEW(OPT_Links, OPT_LinkDesc);
	__MOVE(name, ((OPT_Link)__NIL_AT((ADDRESS)(OPT_Links), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 424, 20, 13430))->name, 256);
}

void OPT_Close (void)
{
	INT16 i;
	OPT_CloseScope();
	i = 0;
	while (i < 64) {
		OPT_GlbMod[__X_AT(i, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 431, 39, 13575)] = NIL;
		i += 1;
	}
	i = 14;
	while (i < 255) {
		OPT_impCtxt.ref[__X_AT(i, 255, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 432, 53, 13650)] = NIL;
		OPT_impCtxt.old[__X_AT(i, 255, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 432, 76, 13673)] = NIL;
		i += 1;
	}
}

void OPT_FindImport (OPT_Object mod, OPT_Object *res)
{
	OPT_Object obj = NIL;
	obj = ((OPT_Object)__NIL_AT((ADDRESS)(mod), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 437, 17, 13795))->scope;
	for (;;) {
		if (obj == NIL) {
			break;
		}
		if (__STRCMP(OPS_name, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 440, 22, 13864))->name) < 0) {
			obj = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 440, 44, 13886))->left;
		} else if (__STRCMP(OPS_name, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 441, 25, 13917))->name) > 0) {
			obj = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 441, 47, 13939))->right;
		} else {
			if ((((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 443, 14, 13979))->mode == 5 && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 443, 34, 13999))->vis == 0)) {
				obj = NIL;
			} else {
				((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 444, 14, 14046))->used = 1;
			}
			break;
		}
	}
	*res = obj;
}

void OPT_Find (OPT_Object *res)
{
	OPT_Object obj = NIL, head = NIL;
	head = OPT_topScope;
	for (;;) {
		obj = ((OPT_Object)__NIL_AT((ADDRESS)(head), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 455, 19, 14229))->right;
		for (;;) {
			if (obj == NIL) {
				break;
			}
			if (__STRCMP(OPS_name, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 458, 24, 14304))->name) < 0) {
				obj = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 458, 46, 14326))->left;
			} else if (__STRCMP(OPS_name, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 459, 27, 14359))->name) > 0) {
				obj = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 459, 49, 14381))->right;
			} else {
				break;
			}
		}
		if (obj != NIL) {
			break;
		}
		head = ((OPT_Object)__NIL_AT((ADDRESS)(head), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 464, 17, 14521))->left;
		if (head == NIL) {
			break;
		}
	}
	*res = obj;
}

void OPT_FindField (CHAR *name, OPT_Struct typ, OPT_Object *res)
{
	OPT_Object obj = NIL;
	while (typ != NIL) {
		obj = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 473, 32, 14720))->link;
		while (obj != NIL) {
			if (__STRCMP(name, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 475, 20, 14770))->name) < 0) {
				obj = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 475, 42, 14792))->left;
			} else if (__STRCMP(name, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 476, 23, 14821))->name) > 0) {
				obj = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 476, 45, 14843))->right;
			} else {
				*res = obj;
				return;
			}
		}
		typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 480, 15, 14924))->BaseTyp;
	}
	*res = NIL;
}

void OPT_Insert (CHAR *name, OPT_Object *obj)
{
	OPT_Object ob0 = NIL, ob1 = NIL;
	BOOLEAN left;
	INT8 mnolev;
	CHAR commentText[1024];
	INT16 j;
	ob0 = OPT_topScope;
	ob1 = ((OPT_Object)__NIL_AT((ADDRESS)(ob0), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 494, 13, 15186))->right;
	left = 0;
	for (;;) {
		if (ob1 != NIL) {
			if (__STRCMP(name, ((OPT_Object)__NIL_AT((ADDRESS)(ob1), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 498, 20, 15260))->name) < 0) {
				ob0 = ob1;
				ob1 = ((OPT_Object)__NIL_AT((ADDRESS)(ob0), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 498, 54, 15294))->left;
				left = 1;
			} else if (__STRCMP(name, ((OPT_Object)__NIL_AT((ADDRESS)(ob1), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 499, 23, 15337))->name) > 0) {
				ob0 = ob1;
				ob1 = ((OPT_Object)__NIL_AT((ADDRESS)(ob0), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 499, 57, 15371))->right;
				left = 0;
			} else {
				OPT_err(1);
				ob0 = ob1;
				ob1 = ((OPT_Object)__NIL_AT((ADDRESS)(ob0), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 500, 57, 15450))->right;
			}
		} else {
			ob1 = OPT_NewObj();
			((OPT_Object)__NIL_AT((ADDRESS)(ob1), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 502, 41, 15508))->leaf = 1;
			if (left) {
				((OPT_Object)__NIL_AT((ADDRESS)(ob0), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 503, 23, 15546))->left = ob1;
			} else {
				((OPT_Object)__NIL_AT((ADDRESS)(ob0), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 503, 45, 15568))->right = ob1;
			}
			((OPT_Object)__NIL_AT((ADDRESS)(ob1), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 504, 10, 15597))->left = NIL;
			((OPT_Object)__NIL_AT((ADDRESS)(ob1), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 504, 28, 15615))->right = NIL;
			__COPY(name, ((OPT_Object)__NIL_AT((ADDRESS)(ob1), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 504, 58, 15645))->name, 256);
			mnolev = ((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 505, 25, 15678))->mnolev;
			((OPT_Object)__NIL_AT((ADDRESS)(ob1), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 505, 38, 15691))->mnolev = mnolev;
			OPM_GetComment((void*)commentText, 1024);
			if (commentText[0] != 0x00) {
				((OPT_Object)__NIL_AT((ADDRESS)(ob1), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 509, 16, 15830))->comment = __NEWARR(NIL, 1, 1, 1, 0, 1024);
				j = 0;
				while ((j < 1023 && commentText[__X_AT(j, 1024, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 512, 60, 15965)] != 0x00)) {
					(*((OPT_ConstExt)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(ob1), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 513, 16, 15992))->comment), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 513, 25, 16001)))[__X_AT(j, 1024, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 513, 27, 16003)] = commentText[__X_AT(j, 1024, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 513, 45, 16021)];
					j += 1;
				}
				(*((OPT_ConstExt)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(ob1), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 516, 14, 16072))->comment), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 516, 23, 16081)))[__X_AT(j, 1024, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 516, 25, 16083)] = 0x00;
			}
			break;
		}
	}
	*obj = ob1;
}

static void OPT_FPrintName (INT32 *fp, CHAR *name, ADDRESS name__len)
{
	INT16 i;
	CHAR ch;
	i = 0;
	do {
		ch = name[__X_AT(i, name__len, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 531, 21, 16413)];
		OPM_FPrint(&*fp, (INT16)ch);
		i += 1;
	} while (!(ch == 0x00));
}

static void OPT_DebugStruct (OPT_Struct btyp)
{
	OPM_LogWLn();
	if (btyp == NIL) {
		OPM_LogWStr((CHAR*)"btyp is nil", 12);
		OPM_LogWLn();
	}
	OPM_LogWStr((CHAR*)"btyp^.strobji^.name = ", 23);
	OPM_LogWStr(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 540, 58, 16695))->strobj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 540, 66, 16703))->name, 256);
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"btyp^.form = ", 14);
	OPM_LogWNum(((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 541, 51, 16774))->form, 0);
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"btyp^.comp = ", 14);
	OPM_LogWNum(((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 542, 51, 16850))->comp, 0);
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"btyp^.mno = ", 13);
	OPM_LogWNum(((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 543, 51, 16926))->mno, 0);
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"btyp^.extlev = ", 16);
	OPM_LogWNum(((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 544, 51, 17002))->extlev, 0);
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"btyp^.size = ", 14);
	OPM_LogWNum(((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 545, 51, 17078))->size, 0);
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"btyp^.align = ", 15);
	OPM_LogWNum(((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 546, 51, 17154))->align, 0);
	OPM_LogWLn();
	OPM_LogWStr((CHAR*)"btyp^.txtpos = ", 16);
	OPM_LogWNum(((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 547, 51, 17230))->txtpos, 0);
	OPM_LogWLn();
}

static void OPT_FPrintSign (INT32 *fp, OPT_Struct result, OPT_Object par)
{
	OPT_IdFPrint(result);
	OPM_FPrint(&*fp, ((OPT_Struct)__NIL_AT((ADDRESS)(result), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 553, 43, 17447))->idfp);
	while (par != NIL) {
		OPM_FPrint(&*fp, ((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 555, 25, 17537))->mode);
		OPT_IdFPrint(((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 556, 19, 17564))->typ);
		OPM_FPrint(&*fp, ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 557, 25, 17596))->typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 557, 30, 17601))->idfp);
		par = ((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 559, 17, 17676))->link;
	}
}

void OPT_IdFPrint (OPT_Struct typ)
{
	OPT_Struct btyp = NIL;
	OPT_Object strobj = NIL;
	INT32 idfp;
	INT16 f, c;
	if (!((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 566, 10, 17866))->idfpdone) {
		((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 567, 8, 17889))->idfpdone = 1;
		idfp = 0;
		f = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 569, 13, 17994))->form;
		OPM_FPrint(&idfp, f);
		if (__IN(f, 0x90, 32)) {
			OPM_FPrint(&idfp, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 569, 86, 18067))->size);
		}
		c = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 570, 13, 18091))->comp;
		OPM_FPrint(&idfp, c);
		btyp = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 571, 16, 18135))->BaseTyp;
		strobj = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 571, 40, 18159))->strobj;
		if ((strobj != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(strobj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 572, 32, 18200))->name[0] != 0x00)) {
			OPT_FPrintName(&idfp, (void*)((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 573, 35, 18252))->mno, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 573, 32, 18249)]), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 573, 41, 18258))->name, 256);
			OPT_FPrintName(&idfp, (void*)((OPT_Object)__NIL_AT((ADDRESS)(strobj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 573, 73, 18290))->name, 256);
		}
		if ((f == 11 || (c == 4 && btyp != NIL)) || c == 3) {
			OPT_IdFPrint(btyp);
			OPM_FPrint(&idfp, ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 576, 45, 18424))->idfp);
		} else if (c == 2) {
			OPT_IdFPrint(btyp);
			OPM_FPrint(&idfp, ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 578, 45, 18501))->idfp);
			OPM_FPrint(&idfp, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 578, 74, 18530))->n);
		} else if (f == 12) {
			OPT_FPrintSign(&idfp, btyp, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 579, 54, 18588))->link);
		}
		((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 581, 8, 18612))->idfp = idfp;
	}
}

static struct FPrintStr__15 {
	INT32 *pbfp, *pvfp;
	struct FPrintStr__15 *lnk;
} *FPrintStr__15_s;

static void FPrintFlds__16 (OPT_Object fld, INT32 adr, BOOLEAN visible);
static void FPrintHdFld__18 (OPT_Struct typ, OPT_Object fld, INT32 adr);
static void FPrintTProcs__20 (OPT_Object obj);

static void FPrintHdFld__18 (OPT_Struct typ, OPT_Object fld, INT32 adr)
{
	INT32 i, j, n;
	OPT_Struct btyp = NIL;
	if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 593, 11, 18985))->comp == 4) {
		FPrintFlds__16(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 593, 46, 19020))->link, adr, 0);
	} else if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 594, 14, 19053))->comp == 2) {
		btyp = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 594, 45, 19084))->BaseTyp;
		n = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 594, 64, 19103))->n;
		while (((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 595, 17, 19124))->comp == 2) {
			n = ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 595, 44, 19151))->n * n;
			btyp = ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 595, 65, 19172))->BaseTyp;
		}
		if (((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 596, 15, 19201))->form == 11 || ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 596, 41, 19227))->comp == 4) {
			j = OPT_nofhdfld;
			FPrintHdFld__18(btyp, fld, adr);
			if (j != OPT_nofhdfld) {
				i = 1;
				while ((i < n && OPT_nofhdfld <= 2048)) {
					adr += ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 600, 26, 19419))->size;
					FPrintHdFld__18(btyp, fld, adr);
					i += 1;
				}
			}
		}
	} else if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 604, 34, 19533))->form == 11 || __STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 604, 59, 19558))->name, "@ptr") == 0) {
		OPM_FPrint(&*FPrintStr__15_s->pvfp, 11);
		OPM_FPrint(&*FPrintStr__15_s->pvfp, adr);
		OPT_nofhdfld += 1;
	}
}

static void FPrintFlds__16 (OPT_Object fld, INT32 adr, BOOLEAN visible)
{
	while ((fld != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 613, 29, 19981))->mode == 4)) {
		if ((((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 614, 14, 20011))->vis != 0 && visible)) {
			OPM_FPrint(&*FPrintStr__15_s->pbfp, ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 615, 29, 20072))->vis);
			OPT_FPrintName(&*FPrintStr__15_s->pbfp, (void*)((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 615, 57, 20100))->name, 256);
			OPM_FPrint(&*FPrintStr__15_s->pbfp, ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 615, 86, 20129))->adr);
			OPT_FPrintStr(((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 616, 22, 20158))->typ);
			OPM_FPrint(&*FPrintStr__15_s->pbfp, ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 616, 50, 20186))->typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 616, 55, 20191))->pbfp);
			OPM_FPrint(&*FPrintStr__15_s->pvfp, ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 616, 84, 20220))->typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 616, 89, 20225))->pvfp);
		} else {
			FPrintHdFld__18(((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 618, 24, 20267))->typ, fld, ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 618, 39, 20282))->adr + adr);
		}
		fld = ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 620, 17, 20322))->link;
	}
}

static void FPrintTProcs__20 (OPT_Object obj)
{
	if (obj != NIL) {
		FPrintTProcs__20(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 627, 23, 20478))->left);
		if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 628, 13, 20499))->mode == 13) {
			if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 629, 15, 20533))->vis != 0) {
				OPM_FPrint(&*FPrintStr__15_s->pbfp, 13);
				OPM_FPrint(&*FPrintStr__15_s->pbfp, __ASHR(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 630, 56, 20610))->adr, 16));
				OPT_FPrintSign(&*FPrintStr__15_s->pbfp, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 631, 31, 20659))->typ, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 631, 41, 20669))->link);
				OPT_FPrintName(&*FPrintStr__15_s->pbfp, (void*)((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 631, 70, 20698))->name, 256);
			}
		}
		FPrintTProcs__20(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 636, 23, 20858))->right);
	}
}

void OPT_FPrintStr (OPT_Struct typ)
{
	INT16 f, c;
	OPT_Struct btyp = NIL;
	OPT_Object strobj = NIL, bstrobj = NIL;
	INT32 pbfp, pvfp;
	struct FPrintStr__15 _s;
	_s.pbfp = &pbfp;
	_s.pvfp = &pvfp;
	_s.lnk = FPrintStr__15_s;
	FPrintStr__15_s = &_s;
	if (!((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 641, 10, 20912))->fpdone) {
		OPT_IdFPrint(typ);
		pbfp = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 642, 31, 20956))->idfp;
		if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 643, 11, 20974))->sysflag != 0) {
			OPM_FPrint(&pbfp, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 643, 50, 21013))->sysflag);
		}
		pvfp = pbfp;
		((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 644, 22, 21050))->pbfp = pbfp;
		((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 644, 41, 21069))->pvfp = pvfp;
		((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 645, 8, 21139))->fpdone = 1;
		f = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 646, 13, 21169))->form;
		c = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 646, 29, 21185))->comp;
		btyp = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 646, 48, 21204))->BaseTyp;
		if (f == 11) {
			strobj = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 648, 20, 21258))->strobj;
			bstrobj = ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 648, 45, 21283))->strobj;
			if (((strobj == NIL || ((OPT_Object)__NIL_AT((ADDRESS)(strobj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 649, 35, 21327))->name[0] == 0x00) || bstrobj == NIL) || ((OPT_Object)__NIL_AT((ADDRESS)(bstrobj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 649, 78, 21370))->name[0] == 0x00) {
				OPT_FPrintStr(btyp);
				OPM_FPrint(&pbfp, ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 650, 47, 21434))->pbfp);
				pvfp = pbfp;
			}
		} else if (f == 12) {
		} else if (__IN(c, 0x0c, 32)) {
			OPT_FPrintStr(btyp);
			OPM_FPrint(&pbfp, ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 654, 75, 21707))->pvfp);
			pvfp = pbfp;
		} else {
			if (btyp != NIL) {
				OPT_FPrintStr(btyp);
				OPM_FPrint(&pbfp, ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 656, 64, 21818))->pbfp);
				OPM_FPrint(&pvfp, ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 656, 94, 21848))->pvfp);
			}
			OPM_FPrint(&pvfp, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 657, 27, 21887))->size);
			OPM_FPrint(&pvfp, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 657, 56, 21916))->align);
			OPM_FPrint(&pvfp, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 657, 86, 21946))->n);
			OPT_nofhdfld = 0;
			FPrintFlds__16(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 658, 36, 21987))->link, 0, 1);
			if (OPT_nofhdfld > 2048) {
				OPM_Mark(225, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 659, 56, 22060))->txtpos);
			}
			FPrintTProcs__20(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 660, 23, 22097))->link);
			OPM_FPrint(&pvfp, pbfp);
			strobj = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 660, 69, 22143))->strobj;
			if (strobj == NIL || ((OPT_Object)__NIL_AT((ADDRESS)(strobj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 661, 35, 22187))->name[0] == 0x00) {
				pbfp = pvfp;
			}
		}
		((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 663, 8, 22238))->pbfp = pbfp;
		((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 663, 27, 22257))->pvfp = pvfp;
	}
	FPrintStr__15_s = _s.lnk;
}

void OPT_FPrintObj (OPT_Object obj)
{
	INT32 fprint;
	INT16 f, m;
	REAL rval;
	OPT_ConstExt ext = NIL;
	if (!((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 670, 10, 22407))->fpdone) {
		fprint = 0;
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 671, 21, 22441))->fpdone = 1;
		OPM_FPrint(&fprint, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 672, 27, 22485))->mode);
		if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 673, 11, 22504))->mode == 3) {
			f = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 674, 15, 22536))->typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 674, 20, 22541))->form;
			OPM_FPrint(&fprint, f);
			switch (f) {
				case 2: case 3: case 4: 
					OPM_FPrint(&fprint, ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 678, 39, 22654))->conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 678, 47, 22662))->intval);
					break;
				case 7: 
					OPM_FPrintSet(&fprint, ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 679, 42, 22713))->conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 679, 50, 22721))->setval);
					break;
				case 5: 
					rval = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 680, 34, 22764))->conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 680, 42, 22772))->realval;
					OPM_FPrintReal(&fprint, rval);
					break;
				case 6: 
					OPM_FPrintLReal(&fprint, ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 681, 44, 22856))->conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 681, 52, 22864))->realval);
					break;
				case 8: 
					OPT_FPrintName(&fprint, (void*)*((OPT_ConstExt)__NIL_AT((ADDRESS)(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 682, 39, 22913))->conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 682, 47, 22921))->ext), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 682, 52, 22926)), 1024);
					break;
				case 9: 
					break;
				default: 
					OPT_err(127);
					break;
			}
		} else if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 686, 14, 22988))->mode == 1) {
			OPM_FPrint(&fprint, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 687, 29, 23034))->vis);
			OPT_FPrintStr(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 687, 50, 23055))->typ);
			OPM_FPrint(&fprint, ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 687, 80, 23085))->typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 687, 85, 23090))->pbfp);
		} else if (__IN(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 688, 14, 23111))->mode, 0x0480, 32)) {
			OPT_FPrintSign(&fprint, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 689, 29, 23170))->typ, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 689, 39, 23180))->link);
		} else if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 690, 14, 23201))->mode == 9) {
			OPT_FPrintSign(&fprint, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 691, 29, 23249))->typ, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 691, 39, 23259))->link);
			ext = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 691, 58, 23278))->conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 691, 66, 23286))->ext;
			m = (INT16)(*((OPT_ConstExt)__NIL_AT((ADDRESS)(ext), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 692, 19, 23311)))[0];
			f = 1;
			OPM_FPrint(&fprint, m);
			while (f <= m) {
				OPM_FPrint(&fprint, (INT16)(*((OPT_ConstExt)__NIL_AT((ADDRESS)(ext), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 693, 49, 23397)))[__X_AT(f, 1024, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 693, 51, 23399)]);
				f += 1;
			}
		} else if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 694, 14, 23430))->mode == 5) {
			OPT_FPrintStr(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 695, 20, 23467))->typ);
			OPM_FPrint(&fprint, ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 695, 50, 23497))->typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 695, 55, 23502))->pbfp);
		}
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 697, 8, 23526))->fprint = fprint;
	}
}

void OPT_FPrintErr (OPT_Object obj, INT16 errcode)
{
	INT16 i, j;
	CHAR ch;
	if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 704, 9, 23663))->mnolev != 0) {
		__COPY(((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(-((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 705, 21, 23701))->mnolev, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 705, 17, 23697)]), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 705, 30, 23710))->name, OPM_objname, 64);
		i = 0;
		while (OPM_objname[__X_AT(i, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 706, 23, 23762)] != 0x00) {
			i += 1;
		}
		OPM_objname[__X_AT(i, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 707, 17, 23801)] = '.';
		j = 0;
		i += 1;
		do {
			ch = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 708, 21, 23848))->name[__X_AT(j, 256, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 708, 28, 23855)];
			OPM_objname[__X_AT(i, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 708, 44, 23871)] = ch;
			j += 1;
			i += 1;
		} while (!(ch == 0x00));
	} else {
		__COPY(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 710, 13, 23930))->name, OPM_objname, 64);
	}
	if (errcode == 249) {
		if (OPM_noerr) {
			OPT_err(errcode);
		}
	} else if (errcode == 253) {
		if ((((!OPT_symNew && !OPT_symExtended)) && !OPT_extsf)) {
			OPT_err(errcode);
		}
		OPT_symExtended = 1;
	} else {
		if ((!OPT_symNew && !OPT_newsf)) {
			OPT_err(errcode);
		}
		OPT_symNew = 1;
	}
}

void OPT_InsertImport (OPT_Object obj, OPT_Object *root, OPT_Object *old)
{
	OPT_Object ob0 = NIL, ob1 = NIL;
	BOOLEAN left;
	if (*root == NIL) {
		*root = obj;
		*old = NIL;
	} else {
		ob0 = *root;
		ob1 = ((OPT_Object)__NIL_AT((ADDRESS)(ob0), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 730, 28, 24497))->right;
		left = 0;
		if (__STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 731, 14, 24534))->name, ((OPT_Object)__NIL_AT((ADDRESS)(ob0), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 731, 26, 24546))->name) < 0) {
			ob1 = ((OPT_Object)__NIL_AT((ADDRESS)(ob0), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 731, 48, 24568))->left;
			left = 1;
		} else if (__STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 732, 14, 24603))->name, ((OPT_Object)__NIL_AT((ADDRESS)(ob0), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 732, 26, 24615))->name) > 0) {
			ob1 = ((OPT_Object)__NIL_AT((ADDRESS)(ob0), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 732, 48, 24637))->right;
			left = 0;
		} else {
			*old = ob0;
			return;
		}
		for (;;) {
			if (ob1 != NIL) {
				if (__STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 737, 15, 24744))->name, ((OPT_Object)__NIL_AT((ADDRESS)(ob1), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 737, 27, 24756))->name) < 0) {
					ob0 = ob1;
					ob1 = ((OPT_Object)__NIL_AT((ADDRESS)(ob1), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 737, 61, 24790))->left;
					left = 1;
				} else if (__STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 738, 18, 24828))->name, ((OPT_Object)__NIL_AT((ADDRESS)(ob1), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 738, 30, 24840))->name) > 0) {
					ob0 = ob1;
					ob1 = ((OPT_Object)__NIL_AT((ADDRESS)(ob1), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 738, 64, 24874))->right;
					left = 0;
				} else {
					*old = ob1;
					break;
				}
			} else {
				ob1 = obj;
				if (left) {
					((OPT_Object)__NIL_AT((ADDRESS)(ob0), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 742, 25, 24986))->left = ob1;
				} else {
					((OPT_Object)__NIL_AT((ADDRESS)(ob0), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 742, 47, 25008))->right = ob1;
				}
				((OPT_Object)__NIL_AT((ADDRESS)(ob1), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 743, 12, 25039))->left = NIL;
				((OPT_Object)__NIL_AT((ADDRESS)(ob1), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 743, 30, 25057))->right = NIL;
				*old = NIL;
				break;
			}
		}
	}
}

static void OPT_InName (CHAR *name, ADDRESS name__len)
{
	INT16 i;
	CHAR ch;
	i = 0;
	do {
		OPM_SymRCh(&ch);
		name[__X_AT(i, name__len, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 753, 26, 25250)] = ch;
		i += 1;
	} while (!(ch == 0x00));
}

static void OPT_InMod (INT8 *mno)
{
	OPT_Object head = NIL;
	OPS_Name name;
	INT32 mn;
	INT8 i;
	mn = OPM_SymRInt();
	if (mn == 0) {
		*mno = OPT_impCtxt.glbmno[0];
	} else {
		if (mn == 16) {
			OPT_InName((void*)name, 256);
			if ((__STRCMP(name, OPT_SelfName) == 0 && !OPT_impCtxt.self)) {
				OPT_err(154);
			}
			i = 0;
			while ((i < OPT_nofGmod && __STRCMP(name, ((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(i, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 767, 44, 25656)]), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 767, 46, 25658))->name) != 0)) {
				i += 1;
			}
			if (i < OPT_nofGmod) {
				*mno = i;
			} else {
				head = OPT_NewObj();
				((OPT_Object)__NIL_AT((ADDRESS)(head), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 770, 31, 25784))->mode = 12;
				__COPY(name, ((OPT_Object)__NIL_AT((ADDRESS)(head), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 770, 62, 25815))->name, 256);
				*mno = OPT_nofGmod;
				((OPT_Object)__NIL_AT((ADDRESS)(head), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 771, 29, 25852))->mnolev = -*mno;
				if (OPT_nofGmod < 64) {
					OPT_GlbMod[__X_AT(*mno, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 773, 18, 25921)] = head;
					OPT_nofGmod += 1;
				} else {
					OPT_err(227);
				}
			}
			OPT_impCtxt.glbmno[__X_AT(OPT_impCtxt.nofm, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 777, 22, 26014)] = *mno;
			OPT_impCtxt.nofm += 1;
		} else {
			*mno = OPT_impCtxt.glbmno[__X_AT(-mn, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 779, 29, 26091)];
		}
	}
}

static void OPT_InLinks (void)
{
	OPS_Name linkname;
	OPT_Link l = NIL;
	OPT_InName((void*)linkname, 256);
	while (linkname[0] != 0x00) {
		l = OPT_Links;
		while ((l != NIL && __STRCMP(((OPT_Link)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 789, 37, 26345))->name, linkname) != 0)) {
			l = ((OPT_Link)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 789, 64, 26372))->next;
		}
		if (l == NIL) {
			l = OPT_Links;
			__NEW(OPT_Links, OPT_LinkDesc);
			((OPT_Link)__NIL_AT((ADDRESS)(OPT_Links), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 792, 12, 26444))->next = l;
			__MOVE(linkname, ((OPT_Link)__NIL_AT((ADDRESS)(OPT_Links), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 792, 29, 26461))->name, 256);
		}
		OPT_InName((void*)linkname, 256);
	}
}

static void OPT_InConstant (INT32 f, OPT_Const conval)
{
	CHAR ch;
	INT16 i;
	OPT_ConstExt ext = NIL;
	REAL rval;
	switch (f) {
		case 1: case 3: case 2: 
			OPM_SymRCh(&ch);
			((OPT_Const)__NIL_AT((ADDRESS)(conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 804, 35, 26705))->intval = (INT16)ch;
			break;
		case 4: 
			((OPT_Const)__NIL_AT((ADDRESS)(conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 805, 19, 26743))->intval = OPM_SymRInt();
			break;
		case 7: 
			OPM_SymRSet(&((OPT_Const)__NIL_AT((ADDRESS)(conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 806, 31, 26799))->setval);
			break;
		case 5: 
			OPM_SymRReal(&rval);
			((OPT_Const)__NIL_AT((ADDRESS)(conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 807, 39, 26847))->realval = rval;
			((OPT_Const)__NIL_AT((ADDRESS)(conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 808, 19, 26884))->intval = -1;
			break;
		case 6: 
			OPM_SymRLReal(&((OPT_Const)__NIL_AT((ADDRESS)(conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 809, 33, 26946))->realval);
			((OPT_Const)__NIL_AT((ADDRESS)(conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 810, 19, 26976))->intval = -1;
			break;
		case 8: 
			ext = OPT_NewExt();
			((OPT_Const)__NIL_AT((ADDRESS)(conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 811, 36, 27041))->ext = ext;
			i = 0;
			do {
				OPM_SymRCh(&ch);
				(*((OPT_ConstExt)__NIL_AT((ADDRESS)(ext), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 813, 34, 27115)))[__X_AT(i, 1024, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 813, 36, 27117)] = ch;
				i += 1;
			} while (!(ch == 0x00));
			((OPT_Const)__NIL_AT((ADDRESS)(conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 815, 19, 27179))->intval2 = i;
			((OPT_Const)__NIL_AT((ADDRESS)(conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 816, 19, 27213))->intval = -1;
			break;
		case 9: 
			((OPT_Const)__NIL_AT((ADDRESS)(conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 817, 19, 27261))->intval = 0;
			break;
		default: 
			OPM_LogWStr((CHAR*)"unhandled case in InConstant(), f = ", 37);
			OPM_LogWNum(f, 0);
			OPM_LogWLn();
			OPM_err(155);
			break;
	}
}

static void OPT_InSign (INT8 mno, OPT_Struct *res, OPT_Object *par)
{
	OPT_Object last = NIL, new = NIL;
	INT32 tag;
	OPT_InStruct(&*res);
	tag = OPM_SymRInt();
	last = NIL;
	while (tag != 18) {
		if (tag < 0 || tag > 100) {
			OPM_LogWStr((CHAR*)"ERROR: Invalid tag value in InSign: ", 37);
			OPM_LogWNum(tag, 0);
			OPM_LogWLn();
			OPM_err(155);
			return;
		}
		new = OPT_NewObj();
		((OPT_Object)__NIL_AT((ADDRESS)(new), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 841, 8, 27939))->mnolev = -mno;
		if (last == NIL) {
			*par = new;
		} else {
			((OPT_Object)__NIL_AT((ADDRESS)(last), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 842, 44, 28000))->link = new;
		}
		if (tag == 23) {
			((OPT_Object)__NIL_AT((ADDRESS)(new), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 843, 30, 28048))->mode = 1;
		} else if (tag == 42) {
			((OPT_Object)__NIL_AT((ADDRESS)(new), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 844, 31, 28092))->mode = 2;
			((OPT_Object)__NIL_AT((ADDRESS)(new), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 844, 52, 28113))->vis = 3;
		} else {
			((OPT_Object)__NIL_AT((ADDRESS)(new), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 845, 13, 28146))->mode = 2;
		}
		OPT_InStruct(&((OPT_Object)__NIL_AT((ADDRESS)(new), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 847, 17, 28188))->typ);
		((OPT_Object)__NIL_AT((ADDRESS)(new), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 848, 8, 28203))->adr = OPM_SymRInt();
		OPT_InName((void*)((OPT_Object)__NIL_AT((ADDRESS)(new), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 848, 42, 28237))->name, 256);
		last = new;
		tag = OPM_SymRInt();
	}
}

static OPT_Object OPT_InFld (void)
{
	INT32 tag;
	OPT_Object obj = NIL;
	tag = OPT_impCtxt.nextTag;
	obj = OPT_NewObj();
	if (tag <= 26) {
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 859, 8, 28503))->mode = 4;
		if (tag == 26) {
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 860, 28, 28545))->vis = 2;
		} else {
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 860, 55, 28572))->vis = 1;
		}
		OPT_InStruct(&((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 861, 17, 28611))->typ);
		OPT_InName((void*)((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 861, 35, 28629))->name, 256);
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 862, 8, 28645))->adr = OPM_SymRInt();
	} else {
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 864, 8, 28682))->mode = 4;
		if (tag == 27) {
			__MOVE("@ptr", ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 865, 29, 28725))->name, 5);
		} else {
			__MOVE("@proc", ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 865, 61, 28757))->name, 6);
		}
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 866, 8, 28794))->typ = OPT_undftyp;
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 866, 29, 28815))->vis = 0;
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 867, 8, 28841))->adr = OPM_SymRInt();
	}
	return obj;
}

static OPT_Object OPT_InTProc (INT8 mno)
{
	INT32 tag;
	OPT_Object obj = NIL;
	tag = OPT_impCtxt.nextTag;
	obj = OPT_NewObj();
	((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 876, 23, 29064))->mnolev = -mno;
	if (tag == 29) {
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 878, 8, 29111))->mode = 13;
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 878, 28, 29131))->conval = OPT_NewConst();
		((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 878, 55, 29158))->conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 878, 63, 29166))->intval = -1;
		OPT_InSign(mno, &((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 879, 20, 29201))->typ, &((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 879, 30, 29211))->link);
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 879, 42, 29223))->vis = 1;
		OPT_InName((void*)((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 879, 71, 29252))->name, 256);
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 880, 8, 29268))->adr = __ASHL(OPM_SymRInt(), 16);
	} else {
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 882, 8, 29333))->mode = 13;
		__MOVE("@tproc", ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 882, 28, 29353))->name, 7);
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 883, 8, 29387))->link = OPT_NewObj();
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 884, 8, 29446))->typ = OPT_undftyp;
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 884, 29, 29467))->vis = 0;
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 885, 8, 29493))->adr = __ASHL(OPM_SymRInt(), 16);
	}
	return obj;
}

static OPT_Struct OPT_InTyp (INT32 tag)
{
	if (tag == 4) {
		return OPT_IntType(OPM_SymRInt());
	} else if (tag == 7) {
		return OPT_SetType(OPM_SymRInt());
	} else if (tag == 12) {
		return OPT_adrtyp;
	} else {
		return OPT_impCtxt.ref[__X_AT(tag, 255, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 896, 27, 29775)];
	}
	__RETCHK;
}

static void OPT_InStruct (OPT_Struct *typ)
{
	INT8 mno;
	INT16 ref;
	INT32 tag;
	OPS_Name name;
	OPT_Struct t = NIL;
	OPT_Object obj = NIL, last = NIL, fld = NIL, old = NIL, dummy = NIL;
	tag = OPM_SymRInt();
	if (tag != 34) {
		*typ = OPT_InTyp(-tag);
	} else {
		ref = OPT_impCtxt.nofr;
		OPT_impCtxt.nofr += 1;
		if (ref < OPT_impCtxt.minr) {
			OPT_impCtxt.minr = ref;
		}
		OPT_InMod(&mno);
		OPT_InName((void*)name, 256);
		obj = OPT_NewObj();
		if (name[0] == 0x00) {
			if (OPT_impCtxt.self) {
				old = NIL;
			} else {
				__MOVE("@", ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 915, 12, 30326))->name, 2);
				OPT_InsertImport(obj, &((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(mno, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 915, 52, 30366)]), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 915, 56, 30370))->right, &old);
				((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 915, 81, 30395))->name[0] = 0x00;
			}
			*typ = OPT_NewStr(0, 1);
		} else {
			__MOVE(name, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 919, 10, 30471))->name, 256);
			OPT_InsertImport(obj, &((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(mno, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 919, 51, 30512)]), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 919, 55, 30516))->right, &old);
			if (old != NIL) {
				OPT_FPrintObj(old);
				OPT_impCtxt.pvfp[__X_AT(ref, 255, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 921, 38, 30646)] = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 921, 49, 30657))->typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 921, 54, 30662))->pvfp;
				if (OPT_impCtxt.self) {
					*typ = OPT_NewStr(0, 1);
				} else {
					*typ = ((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 925, 21, 30852))->typ;
					((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 925, 31, 30862))->link = NIL;
					((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 925, 49, 30880))->sysflag = 0;
					((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 926, 14, 30909))->fpdone = 0;
					((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 926, 36, 30931))->idfpdone = 0;
				}
			} else {
				*typ = OPT_NewStr(0, 1);
			}
		}
		OPT_impCtxt.ref[__X_AT(ref, 255, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 932, 17, 31045)] = *typ;
		OPT_impCtxt.old[__X_AT(ref, 255, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 932, 42, 31070)] = old;
		((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 933, 8, 31090))->ref = ref + 255;
		((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 935, 8, 31190))->mno = mno;
		((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 935, 25, 31207))->allocated = 1;
		((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 936, 8, 31235))->strobj = obj;
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 936, 28, 31255))->mode = 5;
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 936, 46, 31273))->typ = *typ;
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 937, 8, 31294))->mnolev = -mno;
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 937, 29, 31315))->vis = 0;
		tag = OPM_SymRInt();
		if (tag == 35) {
			((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 939, 27, 31414))->sysflag = __SHORTF(OPM_SymRInt(), 32768);
			tag = OPM_SymRInt();
		}
		switch (tag) {
			case 36: 
				((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 941, 17, 31507))->form = 11;
				((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 941, 39, 31529))->size = OPM_AddressSize;
				((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 942, 17, 31572))->n = 0;
				OPT_InStruct(&((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 942, 39, 31594))->BaseTyp);
				break;
			case 37: 
				((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 943, 17, 31621))->form = 13;
				((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 943, 36, 31640))->comp = 2;
				OPT_InStruct(&((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 944, 26, 31682))->BaseTyp);
				((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 944, 41, 31697))->n = OPM_SymRInt();
				OPT_TypSize(*typ);
				break;
			case 38: 
				((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 946, 17, 31788))->form = 13;
				((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 946, 36, 31807))->comp = 3;
				OPT_InStruct(&((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 946, 66, 31837))->BaseTyp);
				if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 947, 20, 31868))->BaseTyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 947, 29, 31877))->comp == 3) {
					((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 948, 19, 31916))->n = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 948, 29, 31926))->BaseTyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 948, 38, 31935))->n + 1;
				} else {
					((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 950, 19, 31979))->n = 0;
				}
				OPT_TypSize(*typ);
				break;
			case 39: 
				((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 953, 17, 32048))->form = 13;
				((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 953, 36, 32067))->comp = 4;
				OPT_InStruct(&((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 954, 26, 32110))->BaseTyp);
				if (((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 955, 20, 32141))->BaseTyp == OPT_notyp) {
					((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 955, 46, 32167))->BaseTyp = NIL;
				}
				((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 956, 17, 32205))->extlev = 0;
				t = ((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 956, 39, 32227))->BaseTyp;
				while (t != NIL) {
					((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 959, 23, 32421))->extlev += 1;
					t = ((OPT_Struct)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 959, 40, 32438))->BaseTyp;
				}
				((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 961, 17, 32491))->size = OPM_SymRInt();
				((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 961, 45, 32519))->align = OPM_SymRInt();
				((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 962, 17, 32561))->n = OPM_SymRInt();
				OPT_impCtxt.nextTag = OPM_SymRInt();
				last = NIL;
				while ((OPT_impCtxt.nextTag >= 25 && OPT_impCtxt.nextTag <= 28)) {
					fld = OPT_InFld();
					((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 965, 35, 32755))->mnolev = -mno;
					if (last != NIL) {
						((OPT_Object)__NIL_AT((ADDRESS)(last), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 966, 39, 32811))->link = fld;
					}
					last = fld;
					OPT_InsertImport(fld, &((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 967, 50, 32879))->link, &dummy);
					OPT_impCtxt.nextTag = OPM_SymRInt();
				}
				while (OPT_impCtxt.nextTag != 18) {
					fld = OPT_InTProc(mno);
					OPT_InsertImport(fld, &((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 972, 37, 33078))->link, &dummy);
					OPT_impCtxt.nextTag = OPM_SymRInt();
				}
				break;
			case 40: 
				((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 975, 17, 33175))->form = 12;
				((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 975, 39, 33197))->size = OPM_AddressSize;
				OPT_InSign(mno, &((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 976, 29, 33252))->BaseTyp, &((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 976, 43, 33266))->link);
				break;
			default: 
				OPM_LogWStr((CHAR*)"unhandled case at InStruct, tag = ", 35);
				OPM_LogWNum(tag, 0);
				OPM_LogWLn();
				break;
		}
		if (ref == OPT_impCtxt.minr) {
			while (ref < OPT_impCtxt.nofr) {
				t = OPT_InTyp(ref);
				OPT_FPrintStr(t);
				obj = ((OPT_Struct)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 982, 17, 33502))->strobj;
				if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 983, 15, 33590))->name[0] != 0x00) {
					OPT_FPrintObj(obj);
				}
				old = OPT_impCtxt.old[__X_AT(ref, 255, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 984, 28, 33654)];
				if (old != NIL) {
					((OPT_Struct)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 986, 12, 33697))->strobj = old;
					if (OPT_impCtxt.self) {
						if (((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 988, 19, 33785))->mnolev < 0) {
							if (((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 989, 21, 33823))->history != 5) {
								if (((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 990, 23, 33875))->fprint != ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 990, 37, 33889))->fprint) {
									((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 991, 22, 33924))->history = 2;
								} else if (OPT_impCtxt.pvfp[__X_AT(ref, 255, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 992, 36, 33983)] != ((OPT_Struct)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 992, 44, 33991))->pvfp) {
									((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 993, 22, 34024))->history = 3;
								}
							}
						} else if (((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 997, 22, 34152))->fprint != ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 997, 36, 34166))->fprint) {
							((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 998, 18, 34197))->history = 2;
						} else if (OPT_impCtxt.pvfp[__X_AT(ref, 255, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 999, 32, 34252)] != ((OPT_Struct)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 999, 40, 34260))->pvfp) {
							((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1000, 18, 34289))->history = 3;
						} else if (((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1001, 22, 34334))->vis == 0) {
							((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1002, 18, 34373))->history = 1;
						} else {
							((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1004, 18, 34469))->history = 0;
						}
					} else {
						if (OPT_impCtxt.pvfp[__X_AT(ref, 255, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1008, 29, 34667)] != ((OPT_Struct)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1008, 37, 34675))->pvfp) {
							((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1009, 18, 34704))->history = 5;
						}
						if (((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1011, 19, 34765))->fprint != ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1011, 33, 34779))->fprint) {
							OPT_FPrintErr(old, 249);
						}
					}
				} else if (OPT_impCtxt.self) {
					((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1016, 14, 34902))->history = 4;
				} else {
					((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1018, 14, 34949))->history = 1;
				}
				ref += 1;
			}
			OPT_impCtxt.minr = 255;
		}
	}
}

static OPT_Object OPT_InObj (INT8 mno)
{
	INT16 i, s;
	CHAR ch;
	OPT_Object obj = NIL, old = NIL;
	OPT_Struct typ = NIL;
	INT32 tag;
	OPT_ConstExt ext = NIL;
	CHAR commentText[1024];
	BOOLEAN hasComment;
	INT16 j;
	INT32 len;
	tag = OPT_impCtxt.nextTag;
	hasComment = 0;
	while (tag == 41) {
		len = OPM_SymRInt();
		if (len < 0) {
			len = 0;
		}
		if (len > 1023) {
			len = 1023;
		}
		i = 0;
		while (i < len) {
			OPM_SymRCh(&commentText[__X_AT(i, 1024, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1049, 30, 35802)]);
			i += 1;
		}
		commentText[__X_AT(i, 1024, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1051, 17, 35839)] = 0x00;
		hasComment = 1;
		tag = OPM_SymRInt();
	}
	if ((tag <= 11 && tag == 0)) {
		OPM_err(155);
		return NIL;
	}
	if (tag < 0 || tag > 50) {
		OPM_LogWStr((CHAR*)"ERROR: Invalid tag in InObj: ", 30);
		OPM_LogWNum(tag, 0);
		OPM_LogWLn();
		OPM_err(155);
		return NIL;
	}
	if (tag == 19) {
		OPT_InStruct(&typ);
		obj = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1074, 30, 36481))->strobj;
		if (!OPT_impCtxt.self) {
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1075, 30, 36520))->vis = 1;
		}
	} else {
		obj = OPT_NewObj();
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1077, 25, 36628))->mnolev = -mno;
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1077, 46, 36649))->vis = 1;
		if (tag <= 11) {
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1079, 10, 36720))->mode = 3;
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1079, 28, 36738))->conval = OPT_NewConst();
			OPT_InConstant(tag, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1079, 71, 36781))->conval);
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1080, 10, 36801))->typ = OPT_InTyp(tag);
		} else if ((tag >= 31 && tag <= 33)) {
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1082, 10, 36899))->conval = OPT_NewConst();
			((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1083, 10, 36932))->conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1083, 18, 36940))->intval = -1;
			OPT_InSign(mno, &((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1084, 22, 36977))->typ, &((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1084, 32, 36987))->link);
			switch (tag) {
				case 31: 
					((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1086, 19, 37032))->mode = 7;
					break;
				case 32: 
					((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1087, 19, 37066))->mode = 10;
					break;
				case 33: 
					((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1088, 19, 37100))->mode = 9;
					ext = OPT_NewExt();
					((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1089, 36, 37152))->conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1089, 44, 37160))->ext = ext;
					s = __SHORTF(OPM_SymRInt(), 32768);
					(*((OPT_ConstExt)__NIL_AT((ADDRESS)(ext), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1090, 46, 37219)))[0] = __CHR(s);
					i = 1;
					while (i <= s) {
						OPM_SymRCh(&(*((OPT_ConstExt)__NIL_AT((ADDRESS)(ext), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1091, 46, 37288)))[__X_AT(i, 1024, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1091, 48, 37290)]);
						i += 1;
					}
					break;
				default: 
					OPM_LogWStr((CHAR*)"unhandled case at InObj, tag = ", 32);
					OPM_LogWNum(tag, 0);
					OPM_LogWLn();
					OPM_err(155);
					return NIL;
					break;
			}
		} else if (tag == 20) {
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1096, 10, 37489))->mode = 5;
			OPT_InStruct(&((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1096, 37, 37516))->typ);
		} else if (tag == 21 || tag == 22) {
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1098, 10, 37577))->mode = 1;
			if (tag == 22) {
				((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1099, 30, 37621))->vis = 2;
			}
			OPT_InStruct(&((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1100, 19, 37663))->typ);
		} else {
			OPM_LogWStr((CHAR*)"ERROR: Unexpected tag in InObj: ", 33);
			OPM_LogWNum(tag, 0);
			OPM_LogWLn();
			OPM_err(155);
			return NIL;
		}
		OPT_InName((void*)((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1106, 15, 37851))->name, 256);
	}
	if ((hasComment && obj != NIL)) {
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1111, 12, 37977))->comment = __NEWARR(NIL, 1, 1, 1, 0, 1024);
		j = 0;
		while ((((j < 1023 && j < len)) && commentText[__X_AT(j, 1024, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1113, 66, 38066)] != 0x00)) {
			(*((OPT_ConstExt)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1114, 10, 38087))->comment), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1114, 19, 38096)))[__X_AT(j, 1024, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1114, 21, 38098)] = commentText[__X_AT(j, 1024, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1114, 39, 38116)];
			j += 1;
		}
		(*((OPT_ConstExt)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1117, 8, 38149))->comment), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1117, 17, 38158)))[__X_AT(j, 1024, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1117, 19, 38160)] = 0x00;
	}
	OPT_FPrintObj(obj);
	if ((((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1121, 10, 38205))->mode == 1 && (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1121, 31, 38226))->typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1121, 36, 38231))->strobj == NIL || ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1121, 59, 38254))->typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1121, 64, 38259))->strobj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1121, 72, 38267))->name[0] == 0x00))) {
		OPM_FPrint(&OPT_impCtxt.reffp, ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1123, 34, 38415))->typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1123, 39, 38420))->ref - 255);
	}
	if (tag != 19) {
		OPT_InsertImport(obj, &((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(mno, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1126, 30, 38497)]), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1126, 34, 38501))->right, &old);
		if (OPT_impCtxt.self) {
			if (old != NIL) {
				if (((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1130, 15, 38644))->vis == 0) {
					((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1130, 40, 38669))->history = 4;
				} else {
					OPT_FPrintObj(old);
					if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1132, 17, 38769))->fprint != ((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1132, 31, 38783))->fprint) {
						((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1132, 48, 38800))->history = 2;
					} else if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1133, 20, 38843))->typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1133, 25, 38848))->pvfp != ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1133, 37, 38860))->typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1133, 42, 38865))->pvfp) {
						((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1133, 57, 38880))->history = 3;
					} else {
						((OPT_Object)__NIL_AT((ADDRESS)(old), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1134, 19, 38922))->history = 1;
					}
				}
			} else {
				((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1137, 15, 38980))->history = 4;
			}
		}
	} else {
		if (OPT_impCtxt.self) {
			if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1143, 13, 39241))->vis == 0) {
				((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1143, 38, 39266))->history = 4;
			} else if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1144, 16, 39302))->history == 0) {
				((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1144, 45, 39331))->history = 1;
			}
		}
	}
	return obj;
}

void OPT_Import (CHAR *aliasName, CHAR *name, BOOLEAN *done)
{
	OPT_Object obj = NIL;
	INT8 mno;
	OPS_Name aliasName__copy;
	__DUPARR(aliasName, OPS_Name);
	if (__STRCMP(name, "SYSTEM") == 0) {
		OPT_SYSimported = 1;
		OPT_Insert(aliasName, &obj);
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1158, 32, 39681))->mode = 11;
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1158, 50, 39699))->mnolev = 0;
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1158, 68, 39717))->scope = OPT_syslink;
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1158, 91, 39740))->typ = OPT_notyp;
	} else {
		OPT_impCtxt.nofr = 14;
		OPT_impCtxt.minr = 255;
		OPT_impCtxt.nofm = 0;
		OPT_impCtxt.self = __STRCMP(aliasName, "@self") == 0;
		OPT_impCtxt.reffp = 0;
		if ((OPT_impCtxt.self && __IN(17, OPM_Options, 32))) {
			OPM_DeleteSym((void*)name, 256);
			*done = 0;
		} else {
			OPM_OldSym((void*)name, 256, &*done);
		}
		if (*done) {
			OPT_InMod(&mno);
			OPT_InLinks();
			OPT_impCtxt.nextTag = OPM_SymRInt();
			while (!OPM_eofSF()) {
				obj = OPT_InObj(mno);
				OPT_impCtxt.nextTag = OPM_SymRInt();
			}
			OPT_Insert(aliasName, &obj);
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1174, 10, 40279))->mode = 11;
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1174, 28, 40297))->scope = ((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(mno, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1174, 46, 40315)]), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1174, 50, 40319))->right;
			((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(mno, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1175, 14, 40340)]), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1175, 18, 40344))->link = obj;
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1176, 10, 40367))->mnolev = -mno;
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1176, 32, 40389))->typ = OPT_notyp;
			OPM_CloseOldSym();
		} else if (OPT_impCtxt.self) {
			OPT_newsf = 1;
			OPT_extsf = 1;
			OPT_sfpresent = 0;
		} else {
			OPT_err(152);
		}
	}
}

static void OPT_OutName (CHAR *name, ADDRESS name__len)
{
	INT16 i;
	CHAR ch;
	i = 0;
	do {
		ch = name[__X_AT(i, name__len, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1190, 23, 40759)];
		OPM_SymWCh(ch);
		i += 1;
	} while (!(ch == 0x00));
}

static void OPT_OutMod (INT16 mno)
{
	if (OPT_expCtxt.locmno[__X_AT(mno, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1195, 23, 40880)] < 0) {
		OPM_SymWInt(16);
		OPT_expCtxt.locmno[__X_AT(mno, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1197, 22, 40956)] = OPT_expCtxt.nofm;
		OPT_expCtxt.nofm += 1;
		OPT_OutName((void*)((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(mno, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1198, 22, 41018)]), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1198, 26, 41022))->name, 256);
	} else {
		OPM_SymWInt(-OPT_expCtxt.locmno[__X_AT(mno, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1199, 38, 41066)]);
	}
}

static void OPT_OutLinks (void)
{
	OPT_Link l = NIL;
	l = OPT_Links;
	while (l != NIL) {
		OPT_OutName((void*)((OPT_Link)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1206, 42, 41183))->name, 256);
		l = ((OPT_Link)__NIL_AT((ADDRESS)(l), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1206, 56, 41197))->next;
	}
	OPM_SymWCh(0x00);
}

static void OPT_OutHdFld (OPT_Struct typ, OPT_Object fld, INT32 adr)
{
	INT32 i, j, n;
	OPT_Struct btyp = NIL;
	if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1216, 11, 41465))->comp == 4) {
		OPT_OutFlds(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1216, 43, 41497))->link, adr, 0);
	} else if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1217, 14, 41530))->comp == 2) {
		btyp = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1217, 45, 41561))->BaseTyp;
		n = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1217, 64, 41580))->n;
		while (((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1218, 17, 41601))->comp == 2) {
			n = ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1218, 44, 41628))->n * n;
			btyp = ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1218, 65, 41649))->BaseTyp;
		}
		if (((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1219, 15, 41678))->form == 11 || ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1219, 41, 41704))->comp == 4) {
			j = OPT_nofhdfld;
			OPT_OutHdFld(btyp, fld, adr);
			if (j != OPT_nofhdfld) {
				i = 1;
				while ((i < n && OPT_nofhdfld <= 2048)) {
					adr += ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1223, 26, 41893))->size;
					OPT_OutHdFld(btyp, fld, adr);
					i += 1;
				}
			}
		}
	} else if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1227, 34, 42004))->form == 11 || __STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1227, 59, 42029))->name, "@ptr") == 0) {
		OPM_SymWInt(27);
		OPM_SymWInt(adr);
		OPT_nofhdfld += 1;
	}
}

static void OPT_OutFlds (OPT_Object fld, INT32 adr, BOOLEAN visible)
{
	while ((fld != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1236, 29, 42394))->mode == 4)) {
		if ((((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1237, 14, 42424))->vis != 0 && visible)) {
			if (((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1238, 15, 42471))->vis == 2) {
				OPM_SymWInt(26);
			} else {
				OPM_SymWInt(25);
			}
			OPT_OutStr(((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1239, 19, 42559))->typ);
			OPT_OutName((void*)((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1239, 38, 42578))->name, 256);
			OPM_SymWInt(((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1239, 62, 42602))->adr);
		} else {
			OPT_OutHdFld(((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1240, 24, 42632))->typ, fld, ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1240, 39, 42647))->adr + adr);
		}
		fld = ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1242, 17, 42687))->link;
	}
}

static void OPT_OutSign (OPT_Struct result, OPT_Object par)
{
	OPT_OutStr(result);
	while (par != NIL) {
		if (((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1250, 13, 42858))->mode == 1) {
			OPM_SymWInt(23);
		} else if (((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1251, 16, 42912))->vis == 3) {
			OPM_SymWInt(42);
		} else {
			OPM_SymWInt(24);
		}
		OPT_OutStr(((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1254, 17, 43015))->typ);
		OPM_SymWInt(((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1255, 22, 43044))->adr);
		OPT_OutName((void*)((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1256, 18, 43069))->name, 256);
		par = ((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1256, 37, 43088))->link;
	}
	OPM_SymWInt(18);
}

static void OPT_OutTProcs (OPT_Struct typ, OPT_Object obj)
{
	if (obj != NIL) {
		OPT_OutTProcs(typ, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1264, 25, 43273))->left);
		if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1265, 13, 43294))->mode == 13) {
			if ((((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1266, 16, 43329))->BaseTyp != NIL && __ASHR(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1266, 39, 43352))->adr, 16) < ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1266, 61, 43374))->BaseTyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1266, 70, 43383))->n)) && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1266, 81, 43394))->vis == 0)) {
				OPM_Mark(109, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1267, 28, 43444))->txtpos);
			}
			if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1270, 34, 43610))->vis != 0) {
				if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1271, 17, 43649))->vis != 0) {
					OPM_SymWInt(29);
					OPT_OutSign(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1272, 44, 43714))->typ, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1272, 54, 43724))->link);
					OPT_OutName((void*)((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1272, 74, 43744))->name, 256);
					OPM_SymWInt(__ASHR(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1273, 28, 43780))->adr, 16));
				} else {
					OPM_SymWInt(30);
					OPM_SymWInt(__ASHR(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1276, 28, 43874))->adr, 16));
				}
			}
		}
		OPT_OutTProcs(typ, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1280, 25, 43953))->right);
	}
}

static void OPT_OutStr (OPT_Struct typ)
{
	OPT_Object strobj = NIL;
	if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1287, 12, 44101))->ref < OPT_expCtxt.ref) {
		OPM_SymWInt(-((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1287, 54, 44143))->ref);
		if (__IN(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1288, 13, 44163))->ref, 0x90, 32)) {
			OPM_SymWInt(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1288, 52, 44202))->size);
		}
	} else {
		OPM_SymWInt(34);
		((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1291, 10, 44259))->ref = OPT_expCtxt.ref;
		OPT_expCtxt.ref += 1;
		if (OPT_expCtxt.ref >= 255) {
			OPT_err(228);
		}
		OPT_OutMod(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1293, 17, 44368))->mno);
		strobj = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1293, 38, 44389))->strobj;
		if ((strobj != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(strobj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1295, 34, 44433))->name[0] != 0x00)) {
			OPT_OutName((void*)((OPT_Object)__NIL_AT((ADDRESS)(strobj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1295, 66, 44465))->name, 256);
			switch (((OPT_Object)__NIL_AT((ADDRESS)(strobj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1296, 20, 44493))->history) {
				case 2: 
					OPT_FPrintErr(strobj, 252);
					break;
				case 3: 
					OPT_FPrintErr(strobj, 251);
					break;
				case 5: 
					OPT_FPrintErr(strobj, 249);
					break;
				default: 
					break;
			}
		} else {
			OPM_SymWCh(0x00);
		}
		if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1305, 13, 44966))->sysflag != 0) {
			OPM_SymWInt(35);
			OPM_SymWInt(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1305, 66, 45019))->sysflag);
		}
		switch (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1306, 15, 45049))->form) {
			case 11: 
				OPM_SymWInt(36);
				OPT_OutStr(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1307, 47, 45105))->BaseTyp);
				break;
			case 12: 
				OPM_SymWInt(40);
				OPT_OutSign(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1308, 48, 45163))->BaseTyp, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1308, 62, 45177))->link);
				break;
			case 13: 
				switch (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1309, 26, 45210))->comp) {
					case 2: 
						OPM_SymWInt(37);
						OPT_OutStr(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1310, 57, 45276))->BaseTyp);
						OPM_SymWInt(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1310, 84, 45303))->n);
						break;
					case 3: 
						OPM_SymWInt(38);
						OPT_OutStr(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1311, 58, 45365))->BaseTyp);
						break;
					case 4: 
						OPM_SymWInt(39);
						if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1313, 34, 45455))->BaseTyp == NIL) {
							OPT_OutStr(OPT_notyp);
						} else {
							OPT_OutStr(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1313, 84, 45505))->BaseTyp);
						}
						OPM_SymWInt(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1315, 43, 45640))->size);
						OPM_SymWInt(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1315, 67, 45664))->align);
						OPM_SymWInt(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1315, 92, 45689))->n);
						OPT_nofhdfld = 0;
						OPT_OutFlds(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1316, 54, 45748))->link, 0, 1);
						if (OPT_nofhdfld > 2048) {
							OPM_Mark(223, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1317, 77, 45842))->txtpos);
						}
						OPT_OutTProcs(typ, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1318, 46, 45902))->link);
						OPM_SymWInt(18);
						break;
					default: 
						OPM_LogWStr((CHAR*)"unhandled case at OutStr, typ^.comp = ", 39);
						OPM_LogWNum(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1319, 98, 46026))->comp, 0);
						OPM_LogWLn();
						break;
				}
				break;
			default: 
				OPM_LogWStr((CHAR*)"unhandled case at OutStr, typ^.form = ", 39);
				OPM_LogWNum(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1321, 88, 46158))->form, 0);
				OPM_LogWLn();
				break;
		}
	}
}

static void OPT_OutConstant (OPT_Object obj)
{
	INT16 f;
	REAL rval;
	f = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1329, 13, 46305))->typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1329, 18, 46310))->form;
	OPM_SymWInt(f);
	switch (f) {
		case 2: case 3: 
			OPM_SymWCh(__CHR(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1332, 33, 46392))->conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1332, 41, 46400))->intval));
			break;
		case 4: 
			OPM_SymWInt(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1333, 30, 46440))->conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1333, 38, 46448))->intval);
			OPM_SymWInt(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1333, 64, 46474))->typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1333, 68, 46478))->size);
			break;
		case 7: 
			OPM_SymWSet(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1334, 30, 46514))->conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1334, 38, 46522))->setval);
			OPM_SymWInt(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1334, 64, 46548))->typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1334, 68, 46552))->size);
			break;
		case 5: 
			rval = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1335, 32, 46590))->conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1335, 40, 46598))->realval;
			OPM_SymWReal(rval);
			break;
		case 6: 
			OPM_SymWLReal(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1336, 32, 46660))->conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1336, 40, 46668))->realval);
			break;
		case 8: 
			OPT_OutName((void*)*((OPT_ConstExt)__NIL_AT((ADDRESS)(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1337, 26, 46704))->conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1337, 34, 46712))->ext), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1337, 39, 46717)), 1024);
			break;
		case 9: 
			break;
		default: 
			OPT_err(127);
			break;
	}
}

static void OPT_OutTruncatedName (CHAR *text, ADDRESS text__len)
{
	INT16 i;
	__DUP(text, text__len, CHAR);
	i = 0;
	while ((i < 1023 && text[__X_AT(i, text__len, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1347, 41, 46906)] != 0x00)) {
		OPM_SymWCh(text[__X_AT(i, text__len, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1348, 21, 46938)]);
		i += 1;
	}
	OPM_SymWCh(0x00);
	__DEL(text);
}

static void OPT_OutObj (OPT_Object obj)
{
	INT16 i, j;
	OPT_ConstExt ext = NIL;
	INT16 k, l;
	if (obj != NIL) {
		OPT_OutObj(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1359, 15, 47122))->left);
		if (__IN(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1360, 11, 47141))->mode, 0x06ea, 32)) {
			if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1362, 13, 47256))->comment != NIL) {
				if ((__IN(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1364, 16, 47354))->mode, 0x06aa, 32) && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1364, 70, 47408))->vis != 0)) {
					OPM_SymWInt(41);
					k = 0;
					while ((k < 1023 && (*((OPT_ConstExt)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1368, 51, 47588))->comment), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1368, 60, 47597)))[__X_AT(k, 1024, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1368, 62, 47599)] != 0x00)) {
						k += 1;
					}
					OPM_SymWInt(k);
					l = 0;
					while (l < k) {
						OPM_SymWCh((*((OPT_ConstExt)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1373, 27, 47799))->comment), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1373, 36, 47808)))[__X_AT(l, 1024, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1373, 38, 47810)]);
						l += 1;
					}
				}
			}
			if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1379, 13, 47938))->history == 4) {
				OPT_FPrintErr(obj, 250);
			} else if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1380, 16, 47998))->vis != 0) {
				switch (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1381, 17, 48036))->history) {
					case 0: 
						OPT_FPrintErr(obj, 253);
						break;
					case 1: 
						break;
					case 2: 
						OPT_FPrintErr(obj, 252);
						break;
					case 3: 
						OPT_FPrintErr(obj, 251);
						break;
					default: 
						OPM_LogWStr((CHAR*)"unhandled case at OutObj, obj^.history = ", 42);
						OPM_LogWNum(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1386, 96, 48301))->history, 0);
						OPM_LogWLn();
						break;
				}
				switch (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1388, 17, 48357))->mode) {
					case 3: 
						OPT_OutConstant(obj);
						OPT_OutName((void*)((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1389, 47, 48413))->name, 256);
						break;
					case 5: 
						if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1390, 24, 48444))->typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1390, 29, 48449))->strobj == obj) {
							OPM_SymWInt(19);
							OPT_OutStr(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1390, 79, 48499))->typ);
						} else {
							OPM_SymWInt(20);
							OPT_OutStr(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1391, 54, 48559))->typ);
							OPT_OutName((void*)((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1391, 73, 48578))->name, 256);
						}
						break;
					case 1: 
						if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1393, 24, 48630))->vis == 2) {
							OPM_SymWInt(22);
						} else {
							OPM_SymWInt(21);
						}
						OPT_OutStr(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1394, 28, 48727))->typ);
						OPT_OutName((void*)((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1394, 47, 48746))->name, 256);
						if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1395, 25, 48779))->typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1395, 30, 48784))->strobj == NIL || ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1395, 53, 48807))->typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1395, 58, 48812))->strobj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1395, 66, 48820))->name[0] == 0x00) {
							OPM_FPrint(&OPT_expCtxt.reffp, ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1397, 49, 48968))->typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1397, 54, 48973))->ref);
						}
						break;
					case 7: 
						OPM_SymWInt(31);
						OPT_OutSign(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1399, 49, 49049))->typ, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1399, 59, 49059))->link);
						OPT_OutName((void*)((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1399, 79, 49079))->name, 256);
						break;
					case 10: 
						OPM_SymWInt(32);
						OPT_OutSign(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1400, 49, 49135))->typ, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1400, 59, 49145))->link);
						OPT_OutName((void*)((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1400, 79, 49165))->name, 256);
						break;
					case 9: 
						OPM_SymWInt(33);
						OPT_OutSign(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1401, 49, 49221))->typ, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1401, 59, 49231))->link);
						ext = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1401, 78, 49250))->conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1401, 86, 49258))->ext;
						j = (INT16)(*((OPT_ConstExt)__NIL_AT((ADDRESS)(ext), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1402, 30, 49294)))[0];
						i = 1;
						OPM_SymWInt(j);
						while (i <= j) {
							OPM_SymWCh((*((OPT_ConstExt)__NIL_AT((ADDRESS)(ext), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1403, 48, 49372)))[__X_AT(i, 1024, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1403, 50, 49374)]);
							i += 1;
						}
						OPT_OutName((void*)((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1404, 29, 49419))->name, 256);
						break;
					default: 
						OPM_LogWStr((CHAR*)"unhandled case at OutObj, obj.mode = ", 38);
						OPM_LogWNum(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1405, 87, 49513))->mode, 0);
						OPM_LogWLn();
						break;
				}
			}
		}
		OPT_OutObj(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1409, 15, 49581))->right);
	}
}

void OPT_Export (BOOLEAN *ext, BOOLEAN *new)
{
	INT16 i;
	INT8 nofmod;
	BOOLEAN done;
	OPT_symExtended = 0;
	OPT_symNew = 0;
	nofmod = OPT_nofGmod;
	OPT_Import((OPS_Name){"@self"}, OPT_SelfName, &done);
	OPT_nofGmod = nofmod;
	if (OPM_noerr) {
		OPM_NewSym((void*)OPT_SelfName, 256);
		if (OPM_noerr) {
			OPM_SymWInt(16);
			OPT_OutName((void*)OPT_SelfName, 256);
			OPT_OutLinks();
			OPT_expCtxt.reffp = 0;
			OPT_expCtxt.ref = 14;
			OPT_expCtxt.nofm = 1;
			OPT_expCtxt.locmno[0] = 0;
			i = 1;
			while (i < 64) {
				OPT_expCtxt.locmno[__X_AT(i, 64, (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1424, 53, 50157)] = -1;
				i += 1;
			}
			OPT_OutObj(((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1425, 24, 50202))->right);
			*ext = (OPT_sfpresent && OPT_symExtended);
			*new = (!OPT_sfpresent || OPT_symNew) || __IN(17, OPM_Options, 32);
			if ((((OPM_noerr && OPT_sfpresent)) && OPT_impCtxt.reffp != OPT_expCtxt.reffp)) {
				*new = 1;
				if (!OPT_extsf) {
					OPT_err(155);
				}
			}
			OPT_newsf = 0;
			OPT_symNew = 0;
			if (!OPM_noerr || OPT_findpc) {
				OPM_DeleteSym((void*)OPT_SelfName, 256);
			}
		}
	}
}

static void OPT_InitStruct (OPT_Struct *typ, INT8 form)
{
	*typ = OPT_NewStr(form, 1);
	((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1446, 36, 50979))->ref = form;
	((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1446, 54, 50997))->size = 1;
	((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1446, 70, 51013))->allocated = 1;
	((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1447, 8, 51041))->strobj = OPT_NewObj();
	((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1447, 33, 51066))->pbfp = form;
	((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1447, 52, 51085))->pvfp = form;
	((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1447, 71, 51104))->fpdone = 1;
	((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1448, 8, 51129))->idfp = form;
	((OPT_Struct)__NIL_AT((ADDRESS)(*typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1448, 27, 51148))->idfpdone = 1;
}

static void OPT_EnterBoolConst (CHAR *name, INT32 value)
{
	OPT_Object obj = NIL;
	OPS_Name name__copy;
	__DUPARR(name, OPS_Name);
	OPT_Insert(name, &obj);
	((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1454, 27, 51301))->conval = OPT_NewConst();
	((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1455, 8, 51332))->mode = 3;
	((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1455, 26, 51350))->typ = OPT_booltyp;
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1455, 47, 51371))->conval), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1455, 55, 51379))->intval = value;
}

static void OPT_EnterTyp (CHAR *name, INT8 form, INT16 size, OPT_Struct *res)
{
	OPT_Object obj = NIL;
	OPT_Struct typ = NIL;
	OPS_Name name__copy;
	__DUPARR(name, OPS_Name);
	OPT_Insert(name, &obj);
	typ = OPT_NewStr(form, 1);
	((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1462, 36, 51606))->mode = 5;
	((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1462, 54, 51624))->typ = typ;
	((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1462, 71, 51641))->vis = 1;
	((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1463, 8, 51667))->strobj = obj;
	((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1463, 28, 51687))->size = size;
	((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1463, 47, 51706))->ref = form;
	((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1463, 65, 51724))->allocated = 1;
	((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1464, 8, 51752))->pbfp = form;
	((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1464, 27, 51771))->pvfp = form;
	((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1464, 46, 51790))->fpdone = 1;
	((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1465, 8, 51815))->idfp = form;
	((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1465, 27, 51834))->idfpdone = 1;
	if (__IN(form, 0x90, 32)) {
		OPM_FPrint(&((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1466, 46, 51899))->idfp, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1466, 56, 51909))->size);
	}
	*res = typ;
}

static void OPT_EnterTypeAlias (CHAR *name, OPT_Object *res)
{
	OPT_Object obj = NIL;
	OPS_Name name__copy;
	__DUPARR(name, OPS_Name);
	OPT_Insert(name, &obj);
	((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1473, 27, 52069))->mode = 5;
	((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1473, 45, 52087))->typ = NIL;
	((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1473, 62, 52104))->vis = 1;
	*res = obj;
}

static void OPT_EnterProc (CHAR *name, INT16 num)
{
	OPT_Object obj = NIL;
	OPS_Name name__copy;
	__DUPARR(name, OPS_Name);
	OPT_Insert(name, &obj);
	((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1480, 8, 52269))->mode = 8;
	((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1480, 28, 52289))->typ = OPT_notyp;
	((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1480, 47, 52308))->adr = num;
}

static void EnumPtrs(void (*P)(void*))
{
	P(OPT_topScope);
	P(OPT_undftyp);
	P(OPT_niltyp);
	P(OPT_notyp);
	P(OPT_bytetyp);
	P(OPT_cpbytetyp);
	P(OPT_booltyp);
	P(OPT_chartyp);
	P(OPT_sinttyp);
	P(OPT_inttyp);
	P(OPT_linttyp);
	P(OPT_hinttyp);
	P(OPT_int8typ);
	P(OPT_int16typ);
	P(OPT_int32typ);
	P(OPT_int64typ);
	P(OPT_settyp);
	P(OPT_set32typ);
	P(OPT_set64typ);
	P(OPT_realtyp);
	P(OPT_lrltyp);
	P(OPT_stringtyp);
	P(OPT_adrtyp);
	P(OPT_sysptrtyp);
	P(OPT_sintobj);
	P(OPT_intobj);
	P(OPT_lintobj);
	P(OPT_setobj);
	__ENUMP(OPT_GlbMod, 64, P);
	P(OPT_universe);
	P(OPT_syslink);
	__ENUMR(&OPT_impCtxt, OPT_ImpCtxt__typ, 3140, 1, P);
	P(OPT_Links);
}

__TDESC(OPT_ConstDesc, 1, 1) = {__TDFLDS("ConstDesc", 40), {0, -8}};
__TDESC(OPT_ObjDesc, 1, 7) = {__TDFLDS("ObjDesc", 308), {0, 4, 8, 12, 284, 288, 304, -32}};
__TDESC(OPT_StrDesc, 1, 3) = {__TDFLDS("StrDesc", 56), {44, 48, 52, -16}};
__TDESC(OPT_NodeDesc, 1, 6) = {__TDFLDS("NodeDesc", 32), {0, 4, 8, 20, 24, 28, -28}};
__TDESC(OPT_ImpCtxt, 1, 510) = {__TDFLDS("ImpCtxt", 3140), {16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 68, 72, 76, 
	80, 84, 88, 92, 96, 100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 
	144, 148, 152, 156, 160, 164, 168, 172, 176, 180, 184, 188, 192, 196, 200, 204, 
	208, 212, 216, 220, 224, 228, 232, 236, 240, 244, 248, 252, 256, 260, 264, 268, 
	272, 276, 280, 284, 288, 292, 296, 300, 304, 308, 312, 316, 320, 324, 328, 332, 
	336, 340, 344, 348, 352, 356, 360, 364, 368, 372, 376, 380, 384, 388, 392, 396, 
	400, 404, 408, 412, 416, 420, 424, 428, 432, 436, 440, 444, 448, 452, 456, 460, 
	464, 468, 472, 476, 480, 484, 488, 492, 496, 500, 504, 508, 512, 516, 520, 524, 
	528, 532, 536, 540, 544, 548, 552, 556, 560, 564, 568, 572, 576, 580, 584, 588, 
	592, 596, 600, 604, 608, 612, 616, 620, 624, 628, 632, 636, 640, 644, 648, 652, 
	656, 660, 664, 668, 672, 676, 680, 684, 688, 692, 696, 700, 704, 708, 712, 716, 
	720, 724, 728, 732, 736, 740, 744, 748, 752, 756, 760, 764, 768, 772, 776, 780, 
	784, 788, 792, 796, 800, 804, 808, 812, 816, 820, 824, 828, 832, 836, 840, 844, 
	848, 852, 856, 860, 864, 868, 872, 876, 880, 884, 888, 892, 896, 900, 904, 908, 
	912, 916, 920, 924, 928, 932, 936, 940, 944, 948, 952, 956, 960, 964, 968, 972, 
	976, 980, 984, 988, 992, 996, 1000, 1004, 1008, 1012, 1016, 1020, 1024, 1028, 1032, 1036, 
	1040, 1044, 1048, 1052, 1056, 1060, 1064, 1068, 1072, 1076, 1080, 1084, 1088, 1092, 1096, 1100, 
	1104, 1108, 1112, 1116, 1120, 1124, 1128, 1132, 1136, 1140, 1144, 1148, 1152, 1156, 1160, 1164, 
	1168, 1172, 1176, 1180, 1184, 1188, 1192, 1196, 1200, 1204, 1208, 1212, 1216, 1220, 1224, 1228, 
	1232, 1236, 1240, 1244, 1248, 1252, 1256, 1260, 1264, 1268, 1272, 1276, 1280, 1284, 1288, 1292, 
	1296, 1300, 1304, 1308, 1312, 1316, 1320, 1324, 1328, 1332, 1336, 1340, 1344, 1348, 1352, 1356, 
	1360, 1364, 1368, 1372, 1376, 1380, 1384, 1388, 1392, 1396, 1400, 1404, 1408, 1412, 1416, 1420, 
	1424, 1428, 1432, 1436, 1440, 1444, 1448, 1452, 1456, 1460, 1464, 1468, 1472, 1476, 1480, 1484, 
	1488, 1492, 1496, 1500, 1504, 1508, 1512, 1516, 1520, 1524, 1528, 1532, 1536, 1540, 1544, 1548, 
	1552, 1556, 1560, 1564, 1568, 1572, 1576, 1580, 1584, 1588, 1592, 1596, 1600, 1604, 1608, 1612, 
	1616, 1620, 1624, 1628, 1632, 1636, 1640, 1644, 1648, 1652, 1656, 1660, 1664, 1668, 1672, 1676, 
	1680, 1684, 1688, 1692, 1696, 1700, 1704, 1708, 1712, 1716, 1720, 1724, 1728, 1732, 1736, 1740, 
	1744, 1748, 1752, 1756, 1760, 1764, 1768, 1772, 1776, 1780, 1784, 1788, 1792, 1796, 1800, 1804, 
	1808, 1812, 1816, 1820, 1824, 1828, 1832, 1836, 1840, 1844, 1848, 1852, 1856, 1860, 1864, 1868, 
	1872, 1876, 1880, 1884, 1888, 1892, 1896, 1900, 1904, 1908, 1912, 1916, 1920, 1924, 1928, 1932, 
	1936, 1940, 1944, 1948, 1952, 1956, 1960, 1964, 1968, 1972, 1976, 1980, 1984, 1988, 1992, 1996, 
	2000, 2004, 2008, 2012, 2016, 2020, 2024, 2028, 2032, 2036, 2040, 2044, 2048, 2052, -2044}};
__TDESC(OPT_ExpCtxt, 1, 0) = {__TDFLDS("ExpCtxt", 72), {-4}};
__TDESC(OPT_LinkDesc, 1, 1) = {__TDFLDS("LinkDesc", 260), {256, -8}};

export void *OPT__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(OPM);
	__MODULE_IMPORT(OPS);
	__REGMOD("OPT", EnumPtrs);
	__REGCMD("Close", OPT_Close);
	__REGCMD("CloseScope", OPT_CloseScope);
	__REGCMD("InitRecno", OPT_InitRecno);
	__INITYP(OPT_ConstDesc, OPT_ConstDesc, 0);
	__INITYP(OPT_ObjDesc, OPT_ObjDesc, 0);
	__INITYP(OPT_StrDesc, OPT_StrDesc, 0);
	__INITYP(OPT_NodeDesc, OPT_NodeDesc, 0);
	__INITYP(OPT_ImpCtxt, OPT_ImpCtxt, 0);
	__INITYP(OPT_ExpCtxt, OPT_ExpCtxt, 0);
	__INITYP(OPT_LinkDesc, OPT_LinkDesc, 0);
/* BEGIN */
	OPT_topScope = NIL;
	OPT_OpenScope(0, NIL);
	OPM_errpos = 0;
	OPT_InitStruct(&OPT_undftyp, 0);
	((OPT_Struct)__NIL_AT((ADDRESS)(OPT_undftyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1486, 41, 52440))->BaseTyp = OPT_undftyp;
	OPT_InitStruct(&OPT_notyp, 10);
	OPT_InitStruct(&OPT_stringtyp, 8);
	OPT_InitStruct(&OPT_niltyp, 9);
	OPT_EnterTyp((OPS_Name){"BYTE"}, 1, 1, &OPT_bytetyp);
	OPT_EnterTyp((OPS_Name){"PTR"}, 11, -1, &OPT_sysptrtyp);
	OPT_EnterTyp((OPS_Name){"ADDRESS"}, 4, -1, &OPT_adrtyp);
	((OPT_Struct)__NIL_AT((ADDRESS)(OPT_adrtyp), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1495, 9, 52858))->ref = 12;
	OPT_EnterTyp((OPS_Name){"INT8"}, 4, 1, &OPT_int8typ);
	OPT_EnterTyp((OPS_Name){"INT16"}, 4, 2, &OPT_int16typ);
	OPT_EnterTyp((OPS_Name){"INT32"}, 4, 4, &OPT_int32typ);
	OPT_EnterTyp((OPS_Name){"INT64"}, 4, 8, &OPT_int64typ);
	OPT_EnterTyp((OPS_Name){"SET32"}, 7, 4, &OPT_set32typ);
	OPT_EnterTyp((OPS_Name){"SET64"}, 7, 8, &OPT_set64typ);
	OPT_EnterProc((OPS_Name){"ADR"}, 20);
	OPT_EnterProc((OPS_Name){"CC"}, 21);
	OPT_EnterProc((OPS_Name){"LSH"}, 22);
	OPT_EnterProc((OPS_Name){"ROT"}, 23);
	OPT_EnterProc((OPS_Name){"GET"}, 24);
	OPT_EnterProc((OPS_Name){"PUT"}, 25);
	OPT_EnterProc((OPS_Name){"GETREG"}, 26);
	OPT_EnterProc((OPS_Name){"PUTREG"}, 27);
	OPT_EnterProc((OPS_Name){"BIT"}, 28);
	OPT_EnterProc((OPS_Name){"VAL"}, 29);
	OPT_EnterProc((OPS_Name){"NEW"}, 30);
	OPT_EnterProc((OPS_Name){"MOVE"}, 31);
	OPT_syslink = ((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1517, 23, 53615))->right;
	OPT_universe = OPT_topScope;
	((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPT.Mod", 27, (CHAR*)"OPT", 4, 1518, 33, 53656))->right = NIL;
	OPT_EnterTyp((OPS_Name){"BOOLEAN"}, 2, 1, &OPT_booltyp);
	OPT_EnterTyp((OPS_Name){"CHAR"}, 3, 1, &OPT_chartyp);
	OPT_EnterTyp((OPS_Name){"REAL"}, 5, 4, &OPT_realtyp);
	OPT_EnterTyp((OPS_Name){"LONGREAL"}, 6, 8, &OPT_lrltyp);
	OPT_EnterTyp((OPS_Name){"HUGEINT"}, 4, 8, &OPT_hinttyp);
	OPT_EnterTyp((OPS_Name){"BYTE@"}, 4, 1, &OPT_cpbytetyp);
	OPT_EnterTypeAlias((OPS_Name){"SHORTINT"}, &OPT_sintobj);
	OPT_EnterTypeAlias((OPS_Name){"INTEGER"}, &OPT_intobj);
	OPT_EnterTypeAlias((OPS_Name){"LONGINT"}, &OPT_lintobj);
	OPT_EnterTypeAlias((OPS_Name){"SET"}, &OPT_setobj);
	OPT_EnterBoolConst((OPS_Name){"FALSE"}, 0);
	OPT_EnterBoolConst((OPS_Name){"TRUE"}, 1);
	OPT_EnterProc((OPS_Name){"HALT"}, 0);
	OPT_EnterProc((OPS_Name){"NEW"}, 1);
	OPT_EnterProc((OPS_Name){"ABS"}, 2);
	OPT_EnterProc((OPS_Name){"CAP"}, 3);
	OPT_EnterProc((OPS_Name){"ORD"}, 4);
	OPT_EnterProc((OPS_Name){"ENTIER"}, 5);
	OPT_EnterProc((OPS_Name){"ODD"}, 6);
	OPT_EnterProc((OPS_Name){"MIN"}, 7);
	OPT_EnterProc((OPS_Name){"MAX"}, 8);
	OPT_EnterProc((OPS_Name){"CHR"}, 9);
	OPT_EnterProc((OPS_Name){"SHORT"}, 10);
	OPT_EnterProc((OPS_Name){"LONG"}, 11);
	OPT_EnterProc((OPS_Name){"SIZE"}, 12);
	OPT_EnterProc((OPS_Name){"INC"}, 13);
	OPT_EnterProc((OPS_Name){"DEC"}, 14);
	OPT_EnterProc((OPS_Name){"INCL"}, 15);
	OPT_EnterProc((OPS_Name){"EXCL"}, 16);
	OPT_EnterProc((OPS_Name){"LEN"}, 17);
	OPT_EnterProc((OPS_Name){"COPY"}, 18);
	OPT_EnterProc((OPS_Name){"ASH"}, 19);
	OPT_EnterProc((OPS_Name){"ASSERT"}, 32);
	OPT_EnterProc((OPS_Name){"SUM"}, 33);
	OPT_EnterProc((OPS_Name){"PROD"}, 34);
	OPT_impCtxt.ref[0] = OPT_undftyp;
	OPT_impCtxt.ref[1] = OPT_bytetyp;
	OPT_impCtxt.ref[2] = OPT_booltyp;
	OPT_impCtxt.ref[3] = OPT_chartyp;
	OPT_impCtxt.ref[4] = OPT_int32typ;
	OPT_impCtxt.ref[5] = OPT_realtyp;
	OPT_impCtxt.ref[6] = OPT_lrltyp;
	OPT_impCtxt.ref[7] = OPT_settyp;
	OPT_impCtxt.ref[8] = OPT_stringtyp;
	OPT_impCtxt.ref[9] = OPT_niltyp;
	OPT_impCtxt.ref[10] = OPT_notyp;
	OPT_impCtxt.ref[11] = OPT_sysptrtyp;
	__ENDMOD;
}
