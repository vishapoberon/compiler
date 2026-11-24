/* voc 5.4.1 [2026/11/24] for gcc LP64 on gentoo xnrtspaSF */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32

#include "SYSTEM.h"
#include "Configuration.h"
#include "OPM.h"
#include "OPT.h"
#include "Strings.h"


static INT16 OPC_indentLevel;
static INT8 OPC_hashtab[257];
static CHAR OPC_keytab[96][32];
static BOOLEAN OPC_GlbPtrs;
static CHAR OPC_BodyNameExt[13];


export void OPC_Andent (OPT_Struct typ);
static void OPC_AnsiParamList (OPT_Object obj, BOOLEAN showParamNames);
export OPT_Object OPC_BaseTProc (OPT_Object obj);
export void OPC_BegBlk (void);
export void OPC_BegStat (void);
static void OPC_CProcDefs (OPT_Object obj, INT16 vis);
export void OPC_Case (INT64 caseVal, INT16 form);
static void OPC_CharacterLiteral (INT64 c);
export void OPC_CheckInterrupt (void);
export void OPC_Cmp (INT16 rel);
export void OPC_CompleteIdent (OPT_Object obj);
export void OPC_Constant (OPT_Const con, INT16 form);
static void OPC_DeclareBase (OPT_Object dcl);
static void OPC_DeclareObj (OPT_Object dcl, BOOLEAN scopeDef);
static void OPC_DeclareParams (OPT_Object par, BOOLEAN macro);
static void OPC_DeclareTProcs (OPT_Object obj, BOOLEAN *empty);
static void OPC_DefAnonRecs (OPT_Node n);
export void OPC_DefineInter (OPT_Object proc);
static void OPC_DefineTProcMacros (OPT_Object obj, BOOLEAN *empty);
static void OPC_DefineTProcTypes (OPT_Object obj);
static void OPC_DefineType (OPT_Struct str);
export void OPC_EndBlk (void);
export void OPC_EndBlk0 (void);
export void OPC_EndStat (void);
export void OPC_EnterBody (void);
export void OPC_EnterProc (OPT_Object proc);
export void OPC_ExitBody (void);
export void OPC_ExitProc (OPT_Object proc, BOOLEAN eoBlock, BOOLEAN implicitRet);
static void OPC_FieldList (OPT_Struct typ, BOOLEAN last, INT32 *off, INT32 *n, INT32 *curAlign);
static void OPC_FillGap (INT32 gap, INT32 off, INT32 align, INT32 *n, INT32 *curAlign);
export void OPC_FinishBody (void);
export void OPC_GenBdy (OPT_Node n);
static void OPC_GenDynTypes (OPT_Node n, INT16 vis);
export void OPC_GenEnumPtrs (OPT_Object var);
export void OPC_GenHdr (OPT_Node n);
export void OPC_GenHdrIncludes (void);
static void OPC_GenHeaderMsg (void);
export void OPC_Halt (INT32 n);
export void OPC_Ident (OPT_Object obj);
static void OPC_IdentList (OPT_Object obj, INT16 vis);
static void OPC_Include (CHAR *name, ADDRESS name__len);
static void OPC_IncludeImports (OPT_Object obj, INT16 vis);
export void OPC_Increment (BOOLEAN decrement);
export void OPC_Indent (INT16 count);
export void OPC_Init (void);
static void OPC_InitImports (OPT_Object obj);
static void OPC_InitKeywords (void);
export void OPC_InitTDesc (OPT_Struct typ);
static void OPC_InitTProcs (OPT_Object typ, OPT_Object obj);
export void OPC_IntLiteral (INT64 n, INT32 size);
static INT16 OPC_KeywordHash (CHAR *s, ADDRESS s__len);
export void OPC_Len (OPT_Object obj, OPT_Struct array, INT64 dim);
static void OPC_LenList (OPT_Object par, BOOLEAN ansiDefine, BOOLEAN showParamName);
static INT16 OPC_Length (CHAR *s, ADDRESS s__len);
export BOOLEAN OPC_NeedsRetval (OPT_Object proc);
export INT32 OPC_NofPtrs (OPT_Struct typ);
export void OPC_PointerCast (OPT_Struct typ);
static BOOLEAN OPC_Prefixed (OPT_ConstExt x, CHAR *y, ADDRESS y__len);
static void OPC_ProcHeader (OPT_Object proc, BOOLEAN define);
static void OPC_ProcPredefs (OPT_Object obj, INT8 vis);
static void OPC_PutBase (OPT_Struct typ);
static void OPC_PutPtrOffsets (OPT_Struct typ, INT32 adr, INT32 *cnt);
static void OPC_RegCmds (OPT_Object obj);
static void OPC_RegProcs (OPT_Object obj);
export void OPC_RegisterBody (void);
static void OPC_RegisterImports (OPT_Object obj);
export void OPC_SetInclude (BOOLEAN exclude);
export void OPC_SourceLocation (INT32 pos);
static void OPC_Stars (OPT_Struct typ, BOOLEAN *openClause);
static void OPC_Str1 (CHAR *s, ADDRESS s__len, INT32 x);
static void OPC_StringLiteral (CHAR *s, ADDRESS s__len, INT32 l);
export void OPC_TDescDecl (OPT_Struct typ);
export void OPC_TypeDefs (OPT_Object obj, INT16 vis);
export void OPC_TypeOf (OPT_Object ap);
static BOOLEAN OPC_Undefined (OPT_Object obj);


void OPC_Init (void)
{
	OPC_indentLevel = 0;
	__MOVE("__init(void)", OPC_BodyNameExt, 13);
}

void OPC_Indent (INT16 count)
{
	OPC_indentLevel += count;
}

void OPC_BegStat (void)
{
	INT16 i;
	i = OPC_indentLevel;
	while (i > 0) {
		OPM_Write(0x09);
		i -= 1;
	}
}

void OPC_EndStat (void)
{
	OPM_Write(';');
	OPM_WriteLn();
}

void OPC_BegBlk (void)
{
	OPM_Write('{');
	OPM_WriteLn();
	OPC_indentLevel += 1;
}

void OPC_EndBlk (void)
{
	OPC_indentLevel -= 1;
	OPC_BegStat();
	OPM_Write('}');
	OPM_WriteLn();
}

void OPC_EndBlk0 (void)
{
	OPC_indentLevel -= 1;
	OPC_BegStat();
	OPM_Write('}');
}

static void OPC_Str1 (CHAR *s, ADDRESS s__len, INT32 x)
{
	CHAR ch;
	INT16 i;
	__DUP(s, s__len, CHAR);
	ch = s[0];
	i = 0;
	while (ch != 0x00) {
		if (ch == '#') {
			OPM_WriteInt(x);
		} else {
			OPM_Write(ch);
		}
		i += 1;
		ch = s[__X_AT(i, s__len, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 86, 23, 2423)];
	}
	__DEL(s);
}

static INT16 OPC_Length (CHAR *s, ADDRESS s__len)
{
	INT16 i;
	i = 0;
	while (s[__X_AT(i, s__len, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 93, 13, 2546)] != 0x00) {
		i += 1;
	}
	return i;
}

static INT16 OPC_KeywordHash (CHAR *s, ADDRESS s__len)
{
	INT16 i, h;
	i = 0;
	h = 0;
	while ((s[__X_AT(i, s__len, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 100, 14, 2715)] != 0x00 && i < 5)) {
		h = 3 * h + (INT16)s[__X_AT(i, s__len, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 100, 53, 2754)];
		i += 1;
	}
	return (int)__MOD(h, 257);
}

void OPC_Ident (OPT_Object obj)
{
	INT16 mode, level, h;
	mode = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 107, 16, 2915))->mode;
	level = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 107, 36, 2935))->mnolev;
	if (mode == 14) {
		OPM_WriteString((CHAR*)"__all", 6);
		OPM_WriteInt(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 109, 49, 3022))->x);
	} else if (mode == 15) {
		OPM_WriteString((CHAR*)"__alllocal", 11);
		OPM_WriteInt(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 111, 54, 3115))->x);
	} else if ((__IN(mode, 0x62, 32) && level > 0) || __IN(mode, 0x14, 32)) {
		OPM_WriteStringVar((void*)((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 113, 29, 3252))->name, 256);
		h = OPC_KeywordHash((void*)((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 114, 27, 3287))->name, 256);
		while ((OPC_hashtab[__X_AT(h, 257, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 115, 22, 3317)] >= 0 && __STRCMP(OPC_keytab[__X_AT(OPC_hashtab[__X_AT(h, 257, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 115, 49, 3344)], 96, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 115, 41, 3336)], ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 115, 58, 3353))->name) != 0)) {
			h = (int)__MOD(h + 1, 257);
		}
		if (OPC_hashtab[__X_AT(h, 257, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 118, 18, 3430)] >= 0) {
			if (__STRCMP(OPC_keytab[__X_AT(OPC_hashtab[__X_AT(h, 257, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 119, 27, 3469)], 96, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 119, 19, 3461)], ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 119, 36, 3478))->name) == 0) {
				OPM_Write('_');
			}
		}
	} else if ((mode == 5 && __IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 121, 34, 3552))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 121, 38, 3556))->form, 0x90, 32))) {
		if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 122, 13, 3602))->typ == OPT_adrtyp) {
			OPM_WriteString((CHAR*)"ADDRESS", 8);
		} else {
			if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 124, 15, 3677))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 124, 19, 3681))->form == 4) {
				OPM_WriteString((CHAR*)"INT", 4);
			} else {
				OPM_WriteString((CHAR*)"UINT", 5);
			}
			OPM_WriteInt(__ASHL(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 125, 25, 3783))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 125, 29, 3787))->size, 3));
		}
	} else {
		if (mode != 5 || ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 128, 34, 3848))->linkadr != 2) {
			if (mode == 13) {
				OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 129, 43, 3923))->link), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 129, 49, 3929))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 129, 54, 3934))->strobj);
			} else if (level < 0) {
				OPM_WriteStringVar((void*)((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(-level, 64, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 131, 41, 4045)]), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 131, 48, 4052))->name, 256);
				if (OPM_currFile == 0) {
					((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(-level, 64, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 132, 60, 4119)]), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 132, 67, 4126))->vis = 1;
				}
			} else {
				OPM_WriteStringVar((void*)OPM_modName, 64);
			}
			OPM_Write('_');
		} else if (obj == ((OPT_Struct)__NIL_AT((ADDRESS)(OPT_sysptrtyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 136, 33, 4283))->strobj || obj == ((OPT_Struct)__NIL_AT((ADDRESS)(OPT_bytetyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 137, 31, 4323))->strobj) {
			OPM_WriteString((CHAR*)"SYSTEM_", 8);
		}
		OPM_WriteStringVar((void*)((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 140, 29, 4412))->name, 256);
	}
}

static void OPC_Stars (OPT_Struct typ, BOOLEAN *openClause)
{
	INT16 pointers;
	*openClause = 0;
	if (((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 148, 13, 4577))->strobj == NIL || ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 148, 36, 4600))->strobj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 148, 44, 4608))->name[0] == 0x00) && ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 148, 64, 4628))->comp != 4)) {
		if (__IN(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 149, 13, 4666))->comp, 0x0c, 32)) {
			OPC_Stars(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 150, 19, 4723))->BaseTyp, &*openClause);
			*openClause = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 151, 27, 4773))->comp == 2;
		} else if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 152, 16, 4808))->form == 12) {
			OPM_Write('(');
			OPM_Write('*');
		} else {
			pointers = 0;
			while (((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 158, 20, 5125))->strobj == NIL || ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 158, 43, 5148))->strobj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 158, 51, 5156))->name[0] == 0x00) && ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 158, 71, 5176))->form == 11)) {
				pointers += 1;
				typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 159, 38, 5238))->BaseTyp;
			}
			if (pointers > 0) {
				if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 162, 19, 5309))->comp != 3) {
					OPC_Stars(typ, &*openClause);
				}
				if (*openClause) {
					OPM_Write('(');
					*openClause = 0;
				}
				while (pointers > 0) {
					OPM_Write('*');
					pointers -= 1;
				}
			}
		}
	}
}

static void OPC_DeclareObj (OPT_Object dcl, BOOLEAN scopeDef)
{
	OPT_Struct typ = NIL;
	BOOLEAN varPar, openClause;
	INT16 form, comp;
	typ = ((OPT_Object)__NIL_AT((ADDRESS)(dcl), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 177, 15, 5787))->typ;
	varPar = ((((OPT_Object)__NIL_AT((ADDRESS)(dcl), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 178, 20, 5813))->mode == 2 && ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 178, 47, 5840))->comp != 2) || ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 178, 75, 5868))->comp == 3) || scopeDef;
	OPC_Stars(typ, &openClause);
	if (varPar) {
		if (openClause) {
			OPM_Write('(');
		}
		OPM_Write('*');
	}
	if (((OPT_Object)__NIL_AT((ADDRESS)(dcl), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 184, 11, 6036))->name[0] != 0x00) {
		OPC_Ident(dcl);
	}
	if ((varPar && openClause)) {
		OPM_Write(')');
	}
	openClause = 0;
	for (;;) {
		form = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 188, 18, 6173))->form;
		comp = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 189, 18, 6198))->comp;
		if (((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 190, 15, 6220))->strobj != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 190, 37, 6242))->strobj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 190, 45, 6250))->name[0] != 0x00) || form == 10) || comp == 4) {
			break;
		} else if ((form == 11 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 191, 40, 6358))->BaseTyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 191, 49, 6367))->comp != 3)) {
			openClause = 1;
		} else if (form == 12 || __IN(comp, 0x0c, 32)) {
			if (openClause) {
				OPM_Write(')');
				openClause = 0;
			}
			if (form == 12) {
				OPM_Write(')');
				OPC_AnsiParamList(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 196, 44, 6642))->link, 0);
				break;
			} else if (comp == 2) {
				OPM_Write('[');
				OPM_WriteInt(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 199, 43, 6751))->n);
				OPM_Write(']');
			}
		} else {
			break;
		}
		typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 204, 17, 6836))->BaseTyp;
	}
}

void OPC_Andent (OPT_Struct typ)
{
	if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 210, 12, 6977))->strobj == NIL || ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 210, 35, 7000))->align >= 65536) {
		OPM_WriteStringVar((void*)OPM_modName, 64);
		OPC_Str1((CHAR*)"__#", 4, __ASHR(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 211, 55, 7078))->align, 16));
	} else {
		OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 212, 19, 7116))->strobj);
	}
}

static BOOLEAN OPC_Undefined (OPT_Object obj)
{
	return ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 220, 16, 7325))->name[0] == 0x00 || (((((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 221, 18, 7355))->mnolev >= 0 && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 222, 18, 7387))->linkadr != (3 + OPM_currFile))) && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 223, 18, 7433))->linkadr != 2);
}

static void OPC_DeclareBase (OPT_Object dcl)
{
	OPT_Struct typ = NIL, prev = NIL;
	OPT_Object obj = NIL;
	INT16 nofdims;
	INT32 off, n, dummy;
	typ = ((OPT_Object)__NIL_AT((ADDRESS)(dcl), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 231, 15, 7763))->typ;
	prev = typ;
	while ((((((((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 232, 16, 7798))->strobj == NIL || ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 232, 39, 7821))->comp == 3) || OPC_Undefined(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 232, 76, 7858))->strobj)) && ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 233, 15, 7883))->comp != 4)) && ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 234, 15, 7918))->form != 10)) && !((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 235, 17, 7954))->form == 11 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 235, 45, 7982))->BaseTyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 235, 54, 7991))->comp == 3)))) {
		prev = typ;
		typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 236, 30, 8045))->BaseTyp;
	}
	obj = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 238, 15, 8080))->strobj;
	if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 239, 11, 8100))->form == 10) {
		OPM_WriteString((CHAR*)"void", 5);
	} else if ((obj != NIL && !OPC_Undefined(obj))) {
		OPC_Ident(obj);
	} else if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 243, 14, 8289))->comp == 4) {
		OPM_WriteString((CHAR*)"struct ", 8);
		OPC_Andent(typ);
		if ((((OPT_Struct)__NIL_AT((ADDRESS)(prev), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 245, 15, 8375))->form != 11 && (obj != NIL || ((OPT_Object)__NIL_AT((ADDRESS)(dcl), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 245, 58, 8418))->name[0] == 0x00))) {
			if ((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 247, 16, 8536))->BaseTyp != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 247, 39, 8559))->BaseTyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 247, 48, 8568))->strobj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 247, 56, 8576))->vis != 0)) {
				OPM_WriteString((CHAR*)" { /* ", 7);
				OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 248, 47, 8648))->BaseTyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 248, 56, 8657))->strobj);
				OPM_WriteString((CHAR*)" */", 4);
				OPM_WriteLn();
				OPC_Indent(1);
			} else {
				OPM_Write(' ');
				OPC_BegBlk();
			}
			OPC_FieldList(typ, 1, &off, &n, &dummy);
			OPC_EndBlk0();
		}
	} else if ((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 254, 15, 8850))->form == 11 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 254, 43, 8878))->BaseTyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 254, 52, 8887))->comp == 3)) {
		typ = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 255, 17, 8929))->BaseTyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 255, 26, 8938))->BaseTyp;
		nofdims = 1;
		while (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 256, 16, 8978))->comp == 3) {
			nofdims += 1;
			typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 256, 63, 9025))->BaseTyp;
		}
		OPM_WriteString((CHAR*)"struct ", 8);
		OPC_BegBlk();
		OPC_BegStat();
		OPC_Str1((CHAR*)"ADDRESS len[#]", 15, nofdims);
		OPC_EndStat();
		OPC_BegStat();
		__NEW(obj, OPT_ObjDesc);
		__NEW(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 259, 33, 9172))->typ, OPT_StrDesc);
		((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 260, 10, 9228))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 260, 14, 9232))->form = 13;
		((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 260, 36, 9254))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 260, 40, 9258))->comp = 2;
		((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 260, 63, 9281))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 260, 67, 9285))->n = 1;
		((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 260, 79, 9297))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 260, 83, 9301))->BaseTyp = typ;
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 260, 103, 9321))->mode = 4;
		__MOVE("data", ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 260, 124, 9342))->name, 5);
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 261, 10, 9368))->linkadr = 0;
		OPC_DeclareBase(obj);
		OPM_Write(' ');
		OPC_DeclareObj(obj, 0);
		OPC_EndStat();
		OPC_EndBlk0();
	}
}

void OPC_PointerCast (OPT_Struct typ)
{
	OPT_Object obj = NIL;
	OPM_Write('(');
	if ((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 270, 12, 9612))->strobj != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 270, 34, 9634))->strobj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 270, 42, 9642))->name[0] != 0x00)) {
		OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 270, 69, 9669))->strobj);
	} else {
		obj = OPT_NewObj();
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 272, 31, 9718))->mode = 1;
		((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 272, 53, 9740))->typ = typ;
		OPC_DeclareBase(obj);
		OPM_Write(' ');
		OPC_DeclareObj(obj, 0);
	}
	OPM_Write(')');
}

void OPC_SourceLocation (INT32 pos)
{
	INT32 line, column;
	if (pos < 0) {
		pos = 0;
	}
	OPM_SourceLocation(pos, &line, &column);
	OPM_WriteString((CHAR*)", (CHAR*)", 10);
	OPC_StringLiteral(OPM_SourceFileName, 256, Strings_Length(OPM_SourceFileName, 256));
	OPM_WriteString((CHAR*)", ", 3);
	OPM_WriteInt(Strings_Length(OPM_SourceFileName, 256) + 1);
	OPM_WriteString((CHAR*)", (CHAR*)\"", 11);
	OPM_WriteStringVar((void*)OPM_modName, 64);
	OPM_WriteString((CHAR*)"\", ", 4);
	OPM_WriteInt(Strings_Length(OPM_modName, 64) + 1);
	OPM_WriteString((CHAR*)", ", 3);
	OPM_WriteInt(line);
	OPM_WriteString((CHAR*)", ", 3);
	OPM_WriteInt(column);
	OPM_WriteString((CHAR*)", ", 3);
	OPM_WriteInt(pos);
}

INT32 OPC_NofPtrs (OPT_Struct typ)
{
	OPT_Object fld = NIL;
	OPT_Struct btyp = NIL;
	INT32 n;
	if ((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 295, 12, 10691))->form == 11 && ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 295, 40, 10719))->sysflag == 0)) {
		return 1;
	} else if ((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 296, 15, 10762))->comp == 4 && __MASK(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 296, 42, 10789))->sysflag, -256) == 0)) {
		btyp = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 297, 18, 10835))->BaseTyp;
		if (btyp != NIL) {
			n = OPC_NofPtrs(btyp);
		} else {
			n = 0;
		}
		fld = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 299, 17, 10924))->link;
		while ((fld != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 300, 31, 10962))->mode == 4)) {
			if (__STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 301, 15, 10997))->name, "@ptr") != 0) {
				n = n + OPC_NofPtrs(((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 301, 63, 11045))->typ);
			} else {
				n += 1;
			}
			fld = ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 304, 19, 11104))->link;
		}
		return n;
	} else if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 307, 14, 11151))->comp == 2) {
		btyp = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 308, 18, 11192))->BaseTyp;
		n = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 308, 37, 11211))->n;
		while (((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 309, 17, 11232))->comp == 2) {
			n = ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 309, 48, 11263))->n * n;
			btyp = ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 309, 69, 11284))->BaseTyp;
		}
		return OPC_NofPtrs(btyp) * n;
	} else {
		return 0;
	}
	__RETCHK;
}

static void OPC_PutPtrOffsets (OPT_Struct typ, INT32 adr, INT32 *cnt)
{
	OPT_Object fld = NIL;
	OPT_Struct btyp = NIL;
	INT32 n, i;
	if ((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 318, 12, 11527))->form == 11 && ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 318, 40, 11555))->sysflag == 0)) {
		OPM_WriteInt(adr);
		OPM_WriteString((CHAR*)", ", 3);
		*cnt += 1;
		if (__MASK(*cnt, -16) == 0) {
			OPM_WriteLn();
			OPM_Write(0x09);
		}
	} else if ((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 321, 15, 11708))->comp == 4 && __MASK(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 321, 42, 11735))->sysflag, -256) == 0)) {
		btyp = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 322, 18, 11781))->BaseTyp;
		if (btyp != NIL) {
			OPC_PutPtrOffsets(btyp, adr, &*cnt);
		}
		fld = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 324, 17, 11869))->link;
		while ((fld != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 325, 31, 11907))->mode == 4)) {
			if (__STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 326, 15, 11942))->name, "@ptr") != 0) {
				OPC_PutPtrOffsets(((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 326, 60, 11987))->typ, adr + ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 326, 76, 12003))->adr, &*cnt);
			} else {
				OPM_WriteInt(adr + ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 328, 33, 12060))->adr);
				OPM_WriteString((CHAR*)", ", 3);
				*cnt += 1;
				if (__MASK(*cnt, -16) == 0) {
					OPM_WriteLn();
					OPM_Write(0x09);
				}
			}
			fld = ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 331, 19, 12198))->link;
		}
	} else if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 333, 14, 12228))->comp == 2) {
		btyp = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 334, 18, 12269))->BaseTyp;
		n = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 334, 37, 12288))->n;
		while (((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 335, 17, 12309))->comp == 2) {
			n = ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 335, 48, 12340))->n * n;
			btyp = ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 335, 69, 12361))->BaseTyp;
		}
		if (OPC_NofPtrs(btyp) > 0) {
			i = 0;
			while (i < n) {
				OPC_PutPtrOffsets(btyp, adr + i * ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 337, 58, 12474))->size, &*cnt);
				i += 1;
			}
		}
	}
}

static void OPC_InitTProcs (OPT_Object typ, OPT_Object obj)
{
	if (obj != NIL) {
		OPC_InitTProcs(typ, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 345, 26, 12640))->left);
		if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 346, 13, 12661))->mode == 13) {
			OPC_BegStat();
			OPM_WriteString((CHAR*)"__INITBP(", 10);
			OPC_Ident(typ);
			OPM_WriteString((CHAR*)", ", 3);
			OPC_Ident(obj);
			OPC_Str1((CHAR*)", #)", 5, __ASHR(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 350, 25, 12819))->adr, 16));
			OPC_EndStat();
		}
		OPC_InitTProcs(typ, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 353, 26, 12891))->right);
	}
}

static void OPC_PutBase (OPT_Struct typ)
{
	if (typ != NIL) {
		OPC_PutBase(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 360, 18, 13012))->BaseTyp);
		OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 361, 16, 13039))->strobj);
		OPM_WriteString((CHAR*)"__typ", 6);
		OPM_WriteString((CHAR*)", ", 3);
	}
}

static void OPC_LenList (OPT_Object par, BOOLEAN ansiDefine, BOOLEAN showParamName)
{
	OPT_Struct typ = NIL;
	INT16 dim;
	if (showParamName) {
		OPC_Ident(par);
		OPM_WriteString((CHAR*)"__len", 6);
	}
	dim = 1;
	typ = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 369, 25, 13337))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 369, 30, 13342))->BaseTyp;
	while (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 370, 14, 13366))->comp == 3) {
		if (ansiDefine) {
			OPM_WriteString((CHAR*)", ADDRESS ", 11);
		} else {
			OPM_WriteString((CHAR*)", ", 3);
		}
		if (showParamName) {
			OPC_Ident(par);
			OPM_WriteString((CHAR*)"__len", 6);
			OPM_WriteInt(dim);
		}
		typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 373, 17, 13582))->BaseTyp;
		dim += 1;
	}
}

static void OPC_DeclareParams (OPT_Object par, BOOLEAN macro)
{
	OPM_Write('(');
	while (par != NIL) {
		if (macro) {
			OPM_WriteStringVar((void*)((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 381, 43, 13779))->name, 256);
		} else {
			OPC_Ident(par);
		}
		if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 385, 13, 13840))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 385, 18, 13845))->comp == 3) {
			OPM_WriteString((CHAR*)", ", 3);
			OPC_LenList(par, 0, 1);
		} else if ((((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 387, 17, 13944))->mode == 2 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 387, 44, 13971))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 387, 49, 13976))->comp == 4)) {
			OPM_WriteString((CHAR*)", ", 3);
			OPM_WriteStringVar((void*)((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 388, 54, 14055))->name, 256);
			OPM_WriteString((CHAR*)"__typ", 6);
		}
		par = ((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 390, 17, 14115))->link;
		if (par != NIL) {
			OPM_WriteString((CHAR*)", ", 3);
		}
	}
	OPM_Write(')');
}

static void OPC_DefineTProcTypes (OPT_Object obj)
{
	OPT_Object par = NIL;
	if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 402, 11, 14481))->typ != OPT_notyp) {
		OPC_DefineType(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 402, 48, 14518))->typ);
	}
	par = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 403, 15, 14545))->link;
	while (par != NIL) {
		OPC_DefineType(((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 403, 56, 14586))->typ);
		par = ((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 403, 74, 14604))->link;
	}
}

static void OPC_DeclareTProcs (OPT_Object obj, BOOLEAN *empty)
{
	if (obj != NIL) {
		OPC_DeclareTProcs(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 409, 24, 14757))->left, &*empty);
		if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 410, 13, 14785))->mode == 13) {
			if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 411, 15, 14823))->typ != OPT_notyp) {
				OPC_DefineType(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 411, 52, 14860))->typ);
			}
			if (OPM_currFile == 0) {
				if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 413, 17, 14935))->vis == 1) {
					OPC_DefineTProcTypes(obj);
					OPM_WriteString((CHAR*)"import ", 8);
					*empty = 0;
					OPC_ProcHeader(obj, 0);
				}
			} else {
				*empty = 0;
				OPC_DefineTProcTypes(obj);
				if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 420, 17, 15176))->vis == 0) {
					OPM_WriteString((CHAR*)"static ", 8);
				} else {
					OPM_WriteString((CHAR*)"export ", 8);
				}
				OPC_ProcHeader(obj, 0);
			}
		}
		OPC_DeclareTProcs(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 426, 24, 15364))->right, &*empty);
	}
}

OPT_Object OPC_BaseTProc (OPT_Object obj)
{
	OPT_Struct typ = NIL, base = NIL;
	INT32 mno;
	typ = ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 432, 19, 15526))->link), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 432, 25, 15532))->typ;
	if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 433, 11, 15570))->form == 11) {
		typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 433, 47, 15606))->BaseTyp;
	}
	base = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 434, 16, 15637))->BaseTyp;
	mno = __ASHR(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 434, 37, 15658))->adr, 16);
	while ((base != NIL && mno < ((OPT_Struct)__NIL_AT((ADDRESS)(base), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 435, 37, 15712))->n)) {
		typ = base;
		base = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 435, 69, 15744))->BaseTyp;
	}
	OPT_FindField(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 436, 22, 15781))->name, typ, &obj);
	return obj;
}

static void OPC_DefineTProcMacros (OPT_Object obj, BOOLEAN *empty)
{
	BOOLEAN checked;
	if (obj != NIL) {
		OPC_DefineTProcMacros(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 444, 28, 15984))->left, &*empty);
		if ((((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 445, 14, 16013))->mode == 13 && obj == OPC_BaseTProc(obj))) {
			if (OPM_currFile == 1 || (OPM_currFile == 0 && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 446, 86, 16148))->vis == 1)) {
				checked = (__IN(1, OPM_Options, 32) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 447, 60, 16235))->link), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 447, 66, 16241))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 447, 71, 16246))->form == 11);
				if (checked) {
					OPM_WriteString((CHAR*)"#ifndef __", 11);
					OPC_Ident(obj);
					OPM_WriteString((CHAR*)"__defined", 10);
					OPM_WriteLn();
					OPM_WriteString((CHAR*)"#define __", 11);
					OPC_Ident(obj);
					OPM_WriteString((CHAR*)"__defined", 10);
					OPM_WriteLn();
					OPM_WriteString((CHAR*)"static inline ", 15);
					if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 452, 23, 16576))->typ == OPT_notyp) {
						OPM_WriteString((CHAR*)"void", 5);
					} else {
						OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 452, 84, 16637))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 452, 89, 16642))->strobj);
					}
					OPM_WriteString((CHAR*)" __", 4);
				} else {
					OPM_WriteString((CHAR*)"#define __", 11);
				}
				OPC_Ident(obj);
				if (checked) {
					OPC_AnsiParamList(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 458, 34, 16853))->link, 1);
					OPM_WriteString((CHAR*)" { ", 4);
					if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 459, 23, 16914))->typ != OPT_notyp) {
						OPM_WriteString((CHAR*)"return ", 8);
					}
				} else {
					OPC_DeclareParams(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 460, 37, 17004))->link, 1);
				}
				OPM_WriteString((CHAR*)" __SEND(", 9);
				if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 463, 21, 17100))->link), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 463, 27, 17106))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 463, 32, 17111))->form == 11) {
					OPM_WriteString((CHAR*)"__TYPEOF(", 10);
					if (checked) {
						OPM_WriteString((CHAR*)"__NIL((ADDRESS)", 16);
					}
					OPC_Ident(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 466, 28, 17286))->link);
					if (checked) {
						OPM_Write(')');
					}
					OPM_Write(')');
				} else {
					OPC_Ident(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 469, 29, 17410))->link);
					OPM_WriteString((CHAR*)"__typ", 6);
				}
				OPC_Str1((CHAR*)", #, ", 6, __ASHR(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 471, 32, 17494))->adr, 16));
				if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 472, 21, 17533))->typ == OPT_notyp) {
					OPM_WriteString((CHAR*)"void", 5);
				} else {
					OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 472, 82, 17594))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 472, 87, 17599))->strobj);
				}
				OPM_WriteString((CHAR*)"(*)", 4);
				OPC_AnsiParamList(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 474, 32, 17684))->link, 0);
				OPM_WriteString((CHAR*)", ", 3);
				OPC_DeclareParams(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 476, 32, 17768))->link, !checked);
				OPM_Write(')');
				if (checked) {
					OPM_WriteString((CHAR*)"; }", 4);
				}
				OPM_WriteLn();
				if (checked) {
					OPM_WriteString((CHAR*)"#endif", 7);
					OPM_WriteLn();
				}
			}
		}
		OPC_DefineTProcMacros(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 483, 28, 18028))->right, &*empty);
	}
}

static void OPC_DefineType (OPT_Struct str)
{
	OPT_Object obj = NIL, field = NIL, par = NIL;
	BOOLEAN empty;
	if ((OPM_currFile == 1 || ((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 490, 45, 18251))->ref < 255) || (((OPM_currFile == 0 && ((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 490, 134, 18340))->strobj != NIL)) && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 490, 156, 18362))->strobj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 490, 164, 18370))->vis == 1)) {
		obj = ((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 491, 17, 18414))->strobj;
		if (obj == NIL || OPC_Undefined(obj)) {
			if (obj != NIL) {
				if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 494, 17, 18533))->linkadr == 1) {
					if (((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 495, 19, 18583))->form != 11) {
						OPM_Mark(244, ((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 495, 62, 18626))->txtpos);
						((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 495, 76, 18640))->linkadr = 2;
					}
				} else {
					((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 496, 19, 18690))->linkadr = 1;
				}
			}
			if (((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 499, 15, 18760))->comp == 4) {
				if (((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 501, 17, 18908))->BaseTyp != NIL) {
					OPC_DefineType(((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 501, 52, 18943))->BaseTyp);
				}
				field = ((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 502, 23, 18982))->link;
				while ((field != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(field), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 503, 39, 19028))->mode == 4)) {
					if (((OPT_Object)__NIL_AT((ADDRESS)(field), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 504, 22, 19070))->vis != 0 || OPM_currFile == 1) {
						OPC_DefineType(((OPT_Object)__NIL_AT((ADDRESS)(field), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 504, 98, 19146))->typ);
					}
					field = ((OPT_Object)__NIL_AT((ADDRESS)(field), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 505, 27, 19185))->link;
				}
			} else if (((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 507, 18, 19223))->form == 11) {
				if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 508, 17, 19265))->BaseTyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 508, 26, 19274))->comp != 4) {
					OPC_DefineType(((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 508, 65, 19313))->BaseTyp);
				}
			} else if (__IN(((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 509, 18, 19345))->comp, 0x0c, 32)) {
				if ((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 510, 18, 19401))->BaseTyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 510, 27, 19410))->strobj != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 510, 49, 19432))->BaseTyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 510, 58, 19441))->strobj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 510, 66, 19449))->linkadr == 1)) {
					OPM_Mark(244, ((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 511, 30, 19532))->txtpos);
					((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 511, 45, 19547))->BaseTyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 511, 54, 19556))->strobj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 511, 62, 19564))->linkadr = 2;
				}
				OPC_DefineType(((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 513, 25, 19632))->BaseTyp);
			} else if (((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 514, 18, 19660))->form == 12) {
				if (((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 515, 17, 19702))->BaseTyp != OPT_notyp) {
					OPC_DefineType(((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 515, 58, 19743))->BaseTyp);
				}
				field = ((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 516, 23, 19782))->link;
				while (field != NIL) {
					OPC_DefineType(((OPT_Object)__NIL_AT((ADDRESS)(field), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 517, 48, 19837))->typ);
					field = ((OPT_Object)__NIL_AT((ADDRESS)(field), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 517, 70, 19859))->link;
				}
			}
		}
		if ((obj != NIL && OPC_Undefined(obj))) {
			OPM_WriteString((CHAR*)"typedef", 8);
			OPM_WriteLn();
			OPM_Write(0x09);
			OPC_Indent(1);
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 522, 12, 20024))->linkadr = 1;
			OPC_DeclareBase(obj);
			OPM_Write(' ');
			((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 524, 12, 20106))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 524, 17, 20111))->strobj = NIL;
			OPC_DeclareObj(obj, 0);
			((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 526, 12, 20223))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 526, 17, 20228))->strobj = obj;
			((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 527, 12, 20279))->linkadr = 3 + OPM_currFile;
			OPC_EndStat();
			OPC_Indent(-1);
			OPM_WriteLn();
			if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 529, 15, 20364))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 529, 20, 20369))->comp == 4) {
				empty = 1;
				OPC_DeclareTProcs(((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 530, 28, 20436))->link, &empty);
				OPC_DefineTProcMacros(((OPT_Struct)__NIL_AT((ADDRESS)(str), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 530, 65, 20473))->link, &empty);
				if (!empty) {
					OPM_WriteLn();
				}
			} else if ((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 532, 19, 20548))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 532, 24, 20553))->form == 11 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 532, 52, 20581))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 532, 57, 20586))->BaseTyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 532, 66, 20595))->comp == 4)) {
				empty = 1;
				OPC_DeclareTProcs(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 534, 28, 20673))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 534, 33, 20678))->BaseTyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 534, 42, 20687))->link, &empty);
				OPC_DefineTProcMacros(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 535, 32, 20734))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 535, 37, 20739))->BaseTyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 535, 46, 20748))->link, &empty);
				if (!empty) {
					OPM_WriteLn();
				}
			}
		}
	}
}

static BOOLEAN OPC_Prefixed (OPT_ConstExt x, CHAR *y, ADDRESS y__len)
{
	INT16 i;
	__DUP(y, y__len, CHAR);
	i = 0;
	while ((*((OPT_ConstExt)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 545, 12, 20968)))[__X_AT(i + 1, 1024, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 545, 13, 20969)] == y[__X_AT(i, y__len, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 545, 22, 20978)]) {
		i += 1;
	}
	__DEL(y);
	return y[__X_AT(i, y__len, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 546, 14, 21009)] == 0x00;
}

static void OPC_CProcDefs (OPT_Object obj, INT16 vis)
{
	INT16 i;
	OPT_ConstExt ext = NIL;
	INT16 _for__7;
	if (obj != NIL) {
		OPC_CProcDefs(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 553, 20, 21177))->left, vis);
		if ((((((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 555, 14, 21317))->mode == 9 && (INT16)((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 555, 40, 21343))->vis >= vis)) && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 555, 60, 21363))->adr == 1)) {
			ext = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 556, 19, 21397))->conval), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 556, 26, 21404))->ext;
			i = 1;
			if (((*((OPT_ConstExt)__NIL_AT((ADDRESS)(ext), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 557, 16, 21433)))[1] != '#' && !(OPC_Prefixed(ext, (CHAR*)"extern ", 8) || OPC_Prefixed(ext, (CHAR*)"import ", 8)))) {
				OPM_WriteString((CHAR*)"#define ", 9);
				OPC_Ident(obj);
				OPC_DeclareParams(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 559, 28, 21582))->link, 1);
				OPM_Write(0x09);
			}
			_for__7 = (INT16)(*((OPT_ConstExt)__NIL_AT((ADDRESS)(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 562, 30, 21666))->conval), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 562, 37, 21673))->ext), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 562, 41, 21677)))[0];
			i = i;
			while (i <= _for__7) {
				OPM_Write((*((OPT_ConstExt)__NIL_AT((ADDRESS)(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 562, 62, 21698))->conval), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 562, 69, 21705))->ext), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 562, 73, 21709)))[__X_AT(i, 1024, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 562, 74, 21710)]);
				i += 1;
			}
			OPM_WriteLn();
		}
		OPC_CProcDefs(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 565, 20, 21770))->right, vis);
	}
}

void OPC_TypeDefs (OPT_Object obj, INT16 vis)
{
	if (obj != NIL) {
		OPC_TypeDefs(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 572, 19, 21959))->left, vis);
		if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 574, 13, 22090))->mode == 5) {
			if ((((((OPM_currFile == 0 && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 577, 50, 22310))->vis == 1)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 578, 17, 22350))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 578, 22, 22355))->strobj != NIL)) && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 578, 44, 22377))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 578, 49, 22382))->strobj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 578, 57, 22390))->mnolev < 0)) {
				((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(-((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 579, 26, 22434))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 579, 31, 22439))->strobj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 579, 39, 22447))->mnolev, 64, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 579, 22, 22430)]), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 579, 48, 22456))->vis = 1;
			}
			if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 581, 15, 22493))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 581, 20, 22498))->txtpos > 0) {
				OPC_DefineType(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 581, 52, 22530))->typ);
			}
		}
		OPC_TypeDefs(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 583, 19, 22570))->right, vis);
	}
}

static void OPC_DefAnonRecs (OPT_Node n)
{
	OPT_Object o = NIL;
	OPT_Struct typ = NIL;
	while ((n != NIL && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 590, 25, 22719))->class == 14)) {
		typ = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 591, 15, 22759))->typ;
		if ((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 592, 14, 22779))->strobj == NIL && (OPM_currFile == 1 || ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 592, 70, 22835))->ref < 255))) {
			OPC_DefineType(typ);
			__NEW(o, OPT_ObjDesc);
			((OPT_Object)__NIL_AT((ADDRESS)(o), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 594, 18, 22949))->typ = typ;
			((OPT_Object)__NIL_AT((ADDRESS)(o), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 594, 32, 22963))->name[0] = 0x00;
			OPC_DeclareBase(o);
			OPC_EndStat();
			OPM_WriteLn();
		}
		n = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 598, 13, 23191))->link;
	}
}

void OPC_TDescDecl (OPT_Struct typ)
{
	INT32 nofptrs;
	OPT_Object o = NIL;
	OPC_BegStat();
	OPM_WriteString((CHAR*)"__TDESC(", 9);
	OPC_Andent(typ);
	OPC_Str1((CHAR*)", #", 4, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 608, 20, 23401))->n + 1);
	OPC_Str1((CHAR*)", #) = {__TDFLDS(", 18, OPC_NofPtrs(typ));
	OPM_Write('"');
	if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 610, 11, 23490))->strobj != NIL) {
		OPM_WriteStringVar((void*)((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 610, 53, 23532))->strobj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 610, 61, 23540))->name, 256);
	}
	OPM_Write('"');
	OPC_Str1((CHAR*)", #), {", 8, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 612, 24, 23605))->size);
	nofptrs = 0;
	OPC_PutPtrOffsets(typ, 0, &nofptrs);
	OPC_Str1((CHAR*)"#}}", 4, -((nofptrs + 1) * OPM_AddressSize));
	OPC_EndStat();
}

void OPC_InitTDesc (OPT_Struct typ)
{
	OPC_BegStat();
	OPM_WriteString((CHAR*)"__INITYP(", 10);
	OPC_Andent(typ);
	OPM_WriteString((CHAR*)", ", 3);
	if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 621, 11, 23883))->BaseTyp != NIL) {
		OPC_Andent(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 621, 42, 23914))->BaseTyp);
	} else {
		OPC_Andent(typ);
	}
	OPC_Str1((CHAR*)", #)", 5, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 622, 21, 23968))->extlev);
	OPC_EndStat();
	if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 624, 11, 24002))->strobj != NIL) {
		OPC_InitTProcs(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 624, 45, 24036))->strobj, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 624, 58, 24049))->link);
	}
}

static void OPC_FillGap (INT32 gap, INT32 off, INT32 align, INT32 *n, INT32 *curAlign)
{
	INT32 adr;
	adr = off;
	OPT_Align(&adr, align);
	if ((*curAlign < align && gap - (adr - off) >= align)) {
		gap -= (adr - off) + align;
		OPC_BegStat();
		switch (align) {
			case 2: 
				OPM_WriteString((CHAR*)"INT16", 6);
				break;
			case 4: 
				OPM_WriteString((CHAR*)"INT32", 6);
				break;
			case 8: 
				OPM_WriteString((CHAR*)"INT64", 6);
				break;
			default: 
				OPM_LogWLn();
				OPM_LogWStr((CHAR*)"Unexpected enclosing alignment in FillGap.", 43);
				break;
		}
		OPC_Str1((CHAR*)" _prvt#", 8, *n);
		*n += 1;
		OPC_EndStat();
		*curAlign = align;
	}
	if (gap > 0) {
		OPC_BegStat();
		OPC_Str1((CHAR*)"char _prvt#", 12, *n);
		*n += 1;
		OPC_Str1((CHAR*)"[#]", 4, gap);
		OPC_EndStat();
	}
}

static void OPC_FieldList (OPT_Struct typ, BOOLEAN last, INT32 *off, INT32 *n, INT32 *curAlign)
{
	OPT_Object fld = NIL;
	OPT_Struct base = NIL;
	INT32 gap, adr, align, fldAlign;
	fld = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 655, 17, 25271))->link;
	align = __MASK(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 656, 17, 25294))->align, -65536);
	if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 657, 11, 25324))->BaseTyp != NIL) {
		OPC_FieldList(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 657, 44, 25357))->BaseTyp, 0, &*off, &*n, &*curAlign);
	} else {
		*off = 0;
		*n = 0;
		*curAlign = 1;
	}
	while ((fld != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 665, 29, 25701))->mode == 4)) {
		if ((OPM_currFile == 0 && ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 666, 48, 25768))->vis == 0) || (((OPM_currFile == 1 && ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 667, 48, 25836))->vis == 0)) && ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 667, 75, 25863))->mno != 0)) {
			fld = ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 669, 19, 25931))->link;
			while ((((fld != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 670, 33, 25970))->mode == 4)) && ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 670, 56, 25993))->vis == 0)) {
				fld = ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 670, 90, 26027))->link;
			}
		} else {
			adr = *off;
			fldAlign = OPT_BaseAlignment(((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 674, 42, 26182))->typ);
			OPT_Align(&adr, fldAlign);
			gap = ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 676, 19, 26242))->adr - adr;
			if (fldAlign > *curAlign) {
				*curAlign = fldAlign;
			}
			if (gap > 0) {
				OPC_FillGap(gap, *off, align, &*n, &*curAlign);
			}
			OPC_BegStat();
			OPC_DeclareBase(fld);
			OPM_Write(' ');
			OPC_DeclareObj(fld, 0);
			*off = ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 682, 19, 26494))->adr + ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 682, 29, 26504))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 682, 33, 26508))->size;
			base = ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 682, 51, 26526))->typ;
			fld = ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 682, 67, 26542))->link;
			while ((((((((fld != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 684, 19, 26593))->mode == 4)) && ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 685, 19, 26628))->typ == base)) && ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 686, 19, 26660))->adr == *off)) && ((OPM_currFile == 1 || ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 687, 53, 26725))->vis != 0) || ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 687, 81, 26753))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 687, 85, 26757))->strobj == NIL))) {
				OPM_WriteString((CHAR*)", ", 3);
				OPC_DeclareObj(fld, 0);
				*off = ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 688, 68, 26843))->adr + ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 688, 78, 26853))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 688, 82, 26857))->size;
				fld = ((OPT_Object)__NIL_AT((ADDRESS)(fld), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 688, 99, 26874))->link;
			}
			OPC_EndStat();
		}
	}
	if (last) {
		adr = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 694, 17, 26961))->size - __ASHR(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 694, 28, 26972))->sysflag, 8);
		if (adr == 0) {
			gap = 1;
		} else {
			gap = adr - *off;
		}
		if (gap > 0) {
			OPC_FillGap(gap, *off, align, &*n, &*curAlign);
		}
	}
}

static void OPC_IdentList (OPT_Object obj, INT16 vis)
{
	OPT_Struct base = NIL;
	BOOLEAN first;
	INT16 lastvis;
	base = NIL;
	first = 1;
	while ((obj != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 705, 29, 27465))->mode != 13)) {
		if ((__IN(vis, 0x05, 32) || (vis == 1 && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 706, 46, 27533))->vis != 0)) || (vis == 3 && !((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 706, 78, 27565))->leaf)) {
			if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 707, 16, 27593))->typ != base || (INT16)((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 707, 37, 27614))->vis != lastvis) {
				if (!first) {
					OPC_EndStat();
				}
				first = 0;
				base = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 710, 22, 27772))->typ;
				lastvis = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 710, 43, 27793))->vis;
				OPC_BegStat();
				if ((vis == 1 && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 712, 30, 27848))->vis != 0)) {
					OPM_WriteString((CHAR*)"import ", 8);
				} else if ((((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 713, 21, 27919))->mnolev == 0 && vis == 0)) {
					if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 714, 19, 27968))->vis == 0) {
						OPM_WriteString((CHAR*)"static ", 8);
					} else {
						OPM_WriteString((CHAR*)"export ", 8);
					}
				}
				if ((((vis == 2 && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 718, 30, 28123))->mode == 1)) && ((OPT_Struct)__NIL_AT((ADDRESS)(base), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 718, 55, 28148))->form == 5)) {
					OPM_WriteString((CHAR*)"double", 7);
				} else {
					OPC_DeclareBase(obj);
				}
			} else {
				OPM_Write(',');
			}
			OPM_Write(' ');
			if ((((vis == 2 && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 724, 28, 28338))->mode == 1)) && ((OPT_Struct)__NIL_AT((ADDRESS)(base), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 724, 53, 28363))->form == 5)) {
				OPM_Write('_');
			}
			OPC_DeclareObj(obj, vis == 3);
			if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 726, 15, 28456))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 726, 20, 28461))->comp == 3) {
				OPC_EndStat();
				OPC_BegStat();
				base = OPT_adrtyp;
				OPM_WriteString((CHAR*)"ADDRESS ", 9);
				OPC_LenList(obj, 0, 1);
			} else if ((((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 730, 19, 28658))->mode == 2 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 730, 46, 28685))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 730, 51, 28690))->comp == 4)) {
				OPC_EndStat();
				OPC_BegStat();
				OPM_WriteString((CHAR*)"ADDRESS *", 10);
				OPC_Ident(obj);
				OPM_WriteString((CHAR*)"__typ", 6);
				base = NIL;
			} else if ((((((__IN(5, OPM_Options, 32) && vis == 0)) && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 734, 62, 28904))->mnolev > 0)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 734, 82, 28924))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 734, 87, 28929))->form == 11)) {
				OPM_WriteString((CHAR*)" = NIL", 7);
			}
		}
		obj = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 738, 17, 29032))->link;
	}
	if (!first) {
		OPC_EndStat();
	}
}

static void OPC_AnsiParamList (OPT_Object obj, BOOLEAN showParamNames)
{
	CHAR name[32];
	OPT_Object par = NIL;
	OPT_Struct typ = NIL;
	OPM_Write('(');
	if (obj == NIL || ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 747, 27, 29288))->mode == 13) {
		OPM_WriteString((CHAR*)"void", 5);
	} else {
		for (;;) {
			par = obj;
			if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 751, 15, 29391))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 751, 20, 29396))->comp == 2) {
				__NEW(par, OPT_ObjDesc);
				__GUARDEQPN_AT(par, OPT_ObjDesc, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 755, 24, 29676) = *((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 755, 32, 29684));
				__NEW(typ, OPT_StrDesc);
				((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 756, 24, 29710))->form = 11;
				((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 756, 50, 29736))->comp = 1;
				((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 757, 14, 29770))->BaseTyp = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 757, 30, 29786))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 757, 35, 29791))->BaseTyp;
				((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 758, 14, 29815))->typ = typ;
				((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 758, 31, 29832))->mode = 1;
			}
			OPC_DeclareBase(par);
			if (showParamNames) {
				OPM_Write(' ');
				OPC_DeclareObj(par, 0);
			} else {
				__COPY(((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 764, 19, 30000))->name, name, 32);
				((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 764, 37, 30018))->name[0] = 0x00;
				OPC_DeclareObj(par, 0);
				__COPY(name, ((OPT_Object)__NIL_AT((ADDRESS)(par), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 764, 89, 30070))->name, 256);
			}
			if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 766, 15, 30106))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 766, 20, 30111))->comp == 3) {
				OPM_WriteString((CHAR*)", ADDRESS ", 11);
				OPC_LenList(obj, 1, showParamNames);
			} else if ((((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 769, 19, 30240))->mode == 2 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 769, 46, 30267))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 769, 51, 30272))->comp == 4)) {
				OPM_WriteString((CHAR*)", ADDRESS *", 12);
				if (showParamNames) {
					OPC_Ident(obj);
					OPM_WriteString((CHAR*)"__typ", 6);
				}
			}
			if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 773, 16, 30442))->link == NIL || ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 773, 37, 30463))->link), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 773, 43, 30469))->mode == 13) {
				break;
			}
			OPM_WriteString((CHAR*)", ", 3);
			obj = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 775, 19, 30553))->link;
		}
	}
	OPM_Write(')');
}

static void OPC_ProcHeader (OPT_Object proc, BOOLEAN define)
{
	if (((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 783, 12, 30699))->typ == OPT_notyp) {
		OPM_WriteString((CHAR*)"void", 5);
	} else {
		OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 783, 74, 30761))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 783, 79, 30766))->strobj);
	}
	OPM_Write(' ');
	OPC_Ident(proc);
	OPM_Write(' ');
	OPC_AnsiParamList(((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 785, 23, 30853))->link, 1);
	if (!define) {
		OPM_Write(';');
	}
	OPM_WriteLn();
}

static void OPC_ProcPredefs (OPT_Object obj, INT8 vis)
{
	if (obj != NIL) {
		OPC_ProcPredefs(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 793, 22, 31093))->left, vis);
		if ((((__IN(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 794, 14, 31120))->mode, 0xc0, 32) && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 794, 54, 31160))->vis >= vis)) && (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 794, 75, 31181))->history != 4 || ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 794, 107, 31213))->mode == 6))) {
			if (vis == 1) {
				OPM_WriteString((CHAR*)"import ", 8);
			} else if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 797, 18, 31405))->vis == 0) {
				OPM_WriteString((CHAR*)"static ", 8);
			} else {
				OPM_WriteString((CHAR*)"export ", 8);
			}
			OPC_ProcHeader(obj, 0);
		}
		OPC_ProcPredefs(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 802, 22, 31574))->right, vis);
	}
}

static void OPC_Include (CHAR *name, ADDRESS name__len)
{
	__DUP(name, name__len, CHAR);
	OPM_WriteString((CHAR*)"#include ", 10);
	OPM_Write('"');
	OPM_WriteStringVar((void*)name, name__len);
	OPM_WriteString((CHAR*)".h", 3);
	OPM_Write('"');
	OPM_WriteLn();
	__DEL(name);
}

static void OPC_IncludeImports (OPT_Object obj, INT16 vis)
{
	INT16 i;
	if (vis == 1) {
		i = 1;
		while (i < (INT16)OPT_nofGmod) {
			if ((INT16)((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(i, 64, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 820, 23, 32175)]), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 820, 25, 32177))->vis >= vis) {
				OPC_Include(((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(i, 64, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 820, 61, 32213)]), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 820, 63, 32215))->name, 256);
			}
			i += 1;
		}
		return;
	}
	if (obj != NIL) {
		OPC_IncludeImports(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 826, 25, 32321))->left, vis);
		if ((((((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 827, 14, 32348))->mode == 11 && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 827, 38, 32372))->mnolev != 0)) && (INT16)((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(-((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 827, 70, 32404))->mnolev, 64, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 827, 66, 32400)]), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 827, 79, 32413))->vis >= vis)) {
			OPC_Include(((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(-((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 828, 32, 32502))->mnolev, 64, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 828, 28, 32498)]), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 828, 41, 32511))->name, 256);
		}
		OPC_IncludeImports(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 830, 25, 32586))->right, vis);
	}
}

static void OPC_GenDynTypes (OPT_Node n, INT16 vis)
{
	OPT_Struct typ = NIL;
	while ((n != NIL && ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 837, 25, 32743))->class == 14)) {
		typ = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 838, 15, 32783))->typ;
		if (vis == 0 || ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 839, 38, 32827))->ref < 255) {
			OPC_BegStat();
			if (vis == 1) {
				OPM_WriteString((CHAR*)"import ", 8);
			} else if ((((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 842, 19, 32980))->strobj != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 842, 41, 33002))->strobj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 842, 49, 33010))->mnolev > 0)) {
				OPM_WriteString((CHAR*)"static ", 8);
			} else {
				OPM_WriteString((CHAR*)"export ", 8);
			}
			OPM_WriteString((CHAR*)"ADDRESS *", 10);
			OPC_Andent(typ);
			OPM_WriteString((CHAR*)"__typ", 6);
			OPC_EndStat();
		}
		n = ((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 848, 13, 33226))->link;
	}
}

void OPC_GenHdr (OPT_Node n)
{
	OPM_currFile = 0;
	OPC_DefAnonRecs(n);
	OPC_TypeDefs(((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 857, 26, 33469))->right, 1);
	OPM_WriteLn();
	OPC_IdentList(((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 858, 27, 33521))->scope, 1);
	OPM_WriteLn();
	OPC_GenDynTypes(n, 1);
	OPM_WriteLn();
	OPC_ProcPredefs(((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 860, 29, 33622))->right, 1);
	OPM_WriteString((CHAR*)"import ", 8);
	OPM_WriteString((CHAR*)"void *", 7);
	OPM_WriteStringVar((void*)OPM_modName, 64);
	OPM_WriteString(OPC_BodyNameExt, 13);
	OPC_EndStat();
	OPM_WriteLn();
	OPC_CProcDefs(((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 864, 27, 33810))->right, 1);
	OPM_WriteLn();
	OPM_WriteString((CHAR*)"#endif // ", 11);
	OPM_WriteStringVar((void*)OPM_modName, 64);
	OPM_WriteLn();
}

static void OPC_GenHeaderMsg (void)
{
	INT16 i;
	OPM_WriteString((CHAR*)"/* ", 4);
	OPM_WriteString((CHAR*)"voc", 4);
	OPM_Write(' ');
	OPM_WriteString(Configuration_versionLong, 76);
	OPM_Write(' ');
	i = 0;
	while (i <= 31) {
		if (__IN(i, OPM_Options, 32)) {
			switch (i) {
				case 0: 
					OPM_Write('x');
					break;
				case 1:
					OPM_Write('n');
					break;
				case 2: 
					OPM_Write('r');
					break;
				case 3: 
					OPM_Write('t');
					break;
				case 4: 
					OPM_Write('s');
					break;
				case 5: 
					OPM_Write('p');
					break;
				case 7: 
					OPM_Write('a');
					break;
				case 9: 
					OPM_Write('e');
					break;
				case 10: 
					OPM_Write('m');
					break;
				case 13: 
					OPM_Write('S');
					break;
				case 14: 
					OPM_Write('c');
					break;
				case 15: 
					OPM_Write('M');
					break;
				case 16: 
					OPM_Write('f');
					break;
				case 17: 
					OPM_Write('F');
					break;
				case 18: 
					OPM_Write('v');
					break;
				case 19: 
					OPM_Write('l');
					break;
				case 20: 
					OPM_Write('L');
					break;
				case 21: 
					OPM_Write('d');
					break;
				case 22: 
					OPM_Write('D');
					break;
				case 23: 
					OPM_Write('j');
					break;
				case 24: 
					OPM_Write('P');
					break;
				case 25: 
					OPM_Write('G');
					break;
				default: 
					OPM_LogWStr((CHAR*)"( more options defined in OPM than checked in OPC.GenHeaderMsg, if you are a compiler developer, add them to OPC.GenHeaderMsg", 126);
					OPM_LogWLn();
					break;
			}
		}
		i += 1;
	}
	OPM_WriteString((CHAR*)" */", 4);
	OPM_WriteLn();
}

void OPC_GenHdrIncludes (void)
{
	OPM_currFile = 2;
	OPC_GenHeaderMsg();
	OPM_WriteLn();
	OPM_WriteString((CHAR*)"#ifndef ", 9);
	OPM_WriteStringVar((void*)OPM_modName, 64);
	OPM_WriteString((CHAR*)"__h", 4);
	OPM_WriteLn();
	OPM_WriteString((CHAR*)"#define ", 9);
	OPM_WriteStringVar((void*)OPM_modName, 64);
	OPM_WriteString((CHAR*)"__h", 4);
	OPM_WriteLn();
	OPM_WriteLn();
	OPC_Include((CHAR*)"SYSTEM", 7);
	OPC_IncludeImports(((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 915, 32, 35903))->right, 1);
	OPM_WriteLn();
}

void OPC_GenBdy (OPT_Node n)
{
	OPM_currFile = 1;
	OPC_GenHeaderMsg();
	OPM_WriteLn();
	if (__IN(25, OPM_Options, 32)) {
		OPM_WriteString((CHAR*)"#if !defined(_OPENMP) || _OPENMP < 201511", 42);
		OPM_WriteLn();
		OPM_WriteString((CHAR*)"#error \"OpenMP GPU output requires an OpenMP 4.5+ C compiler\"", 62);
		OPM_WriteLn();
		OPM_WriteString((CHAR*)"#endif", 7);
		OPM_WriteLn();
	} else if (__IN(24, OPM_Options, 32)) {
		OPM_WriteString((CHAR*)"#if !defined(_OPENMP) || _OPENMP < 200805", 42);
		OPM_WriteLn();
		OPM_WriteString((CHAR*)"#error \"OpenMP CPU output requires an OpenMP 3.0+ C compiler\"", 62);
		OPM_WriteLn();
		OPM_WriteString((CHAR*)"#endif", 7);
		OPM_WriteLn();
	}
	OPM_WriteString((CHAR*)"#define SHORTINT INT", 21);
	OPM_WriteInt(__ASHL(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_sinttyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 934, 71, 36729))->size, 3));
	OPM_WriteLn();
	OPM_WriteString((CHAR*)"#define INTEGER  INT", 21);
	OPM_WriteInt(__ASHL(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_inttyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 935, 70, 36821))->size, 3));
	OPM_WriteLn();
	OPM_WriteString((CHAR*)"#define LONGINT  INT", 21);
	OPM_WriteInt(__ASHL(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_linttyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 936, 71, 36915))->size, 3));
	OPM_WriteLn();
	OPM_WriteString((CHAR*)"#define SET      UINT", 22);
	OPM_WriteInt(__ASHL(((OPT_Struct)__NIL_AT((ADDRESS)(OPT_settyp), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 937, 70, 37007))->size, 3));
	OPM_WriteLn();
	if (__IN(10, OPM_Options, 32)) {
		OPM_WriteString((CHAR*)"#define VOC_MAIN_PROGRAM 1", 27);
		OPM_WriteLn();
	}
	OPM_WriteLn();
	OPC_Include((CHAR*)"SYSTEM", 7);
	OPC_IncludeImports(((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 944, 32, 37225))->right, 0);
	OPM_WriteLn();
	if (__IN(20, OPM_Options, 32)) {
		OPM_WriteString((CHAR*)"static void *__module_owner;", 29);
		OPM_WriteLn();
	}
	if (__IN(19, OPM_Options, 32)) {
		OPC_Include((CHAR*)"Heap", 5);
		OPM_WriteString((CHAR*)"extern const INT32 VOC_CoreABI;", 32);
		OPM_WriteLn();
		OPM_WriteString((CHAR*)"export const void *const ", 26);
		OPM_WriteStringVar((void*)OPM_modName, 64);
		OPM_WriteString((CHAR*)"__voc_runtime = &VOC_CoreABI;", 30);
		OPM_WriteLn();
		OPM_WriteString((CHAR*)"export const INT32 ", 20);
		OPM_WriteStringVar((void*)OPM_modName, 64);
		OPM_WriteString((CHAR*)"__voc_abi[] = {VOC_SHARED_ABI_FORMAT, sizeof(ADDRESS), sizeof(SHORTINT), sizeof(INTEGER),", 90);
		OPM_WriteLn();
		OPM_WriteString((CHAR*)"sizeof(LONGINT), sizeof(SET), sizeof(Heap_ModuleDesc), sizeof(Heap_CmdDesc), VOC_CORE_ABI_PROFILE};", 100);
		OPM_WriteLn();
	}
	OPC_DefAnonRecs(n);
	OPC_TypeDefs(((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 958, 26, 38061))->right, 0);
	OPM_WriteLn();
	OPC_IdentList(((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 959, 27, 38113))->scope, 0);
	OPM_WriteLn();
	OPC_GenDynTypes(n, 0);
	OPM_WriteLn();
	OPC_ProcPredefs(((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 961, 29, 38214))->right, 0);
	OPM_WriteLn();
	OPC_CProcDefs(((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 962, 27, 38266))->right, 0);
	OPM_WriteLn();
}

static void OPC_RegCmds (OPT_Object obj)
{
	if (obj != NIL) {
		OPC_RegCmds(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 968, 18, 38391))->left);
		if ((((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 969, 14, 38413))->mode == 7 && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 969, 40, 38439))->history != 4)) {
			if ((((((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 970, 16, 38484))->vis != 0 && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 970, 33, 38501))->link == NIL)) && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 970, 53, 38521))->typ == OPT_notyp)) {
				if ((__IN(20, OPM_Options, 32) && Strings_Length(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 971, 67, 38623))->name, 256) >= 64)) {
					OPM_LogWStr((CHAR*)"Modular-build command names must fit the 63-character runtime registry.", 72);
					OPM_LogWLn();
					OPM_noerr = 0;
				}
				OPC_BegStat();
				OPM_WriteString((CHAR*)"__REGCMD(\"", 11);
				OPM_WriteStringVar((void*)((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 976, 33, 38898))->name, 256);
				OPM_WriteString((CHAR*)"\", ", 4);
				OPC_Ident(obj);
				OPM_Write(')');
				OPC_EndStat();
			}
		}
		OPC_RegCmds(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 979, 18, 39007))->right);
	}
}

static void OPC_RegProcs (OPT_Object obj)
{
	if (obj != NIL) {
		OPC_RegProcs(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 986, 19, 39127))->left);
		if ((__IN(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 987, 14, 39148))->mode, 0x20c0, 32) && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 987, 64, 39198))->history != 4)) {
			OPC_BegStat();
			OPM_WriteString((CHAR*)"Heap_REGPROC(m, (ADDRESS)", 26);
			OPC_Ident(obj);
			OPM_WriteString((CHAR*)")", 2);
			OPC_EndStat();
			OPC_RegProcs(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 990, 21, 39361))->scope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 990, 27, 39367))->right);
		}
		OPC_RegProcs(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 992, 19, 39404))->right);
	}
}

void OPC_RegisterBody (void)
{
	if (__IN(20, OPM_Options, 32)) {
		OPC_RegProcs(OPT_topScope);
		if (__STRCMP(OPM_modName, "SYSTEM") != 0) {
			OPC_RegCmds(OPT_topScope);
		}
		OPC_BegStat();
		OPM_WriteString((CHAR*)"__ENTERMODULE(m)", 17);
		OPC_EndStat();
	}
}

void OPC_CheckInterrupt (void)
{
	if (__IN(20, OPM_Options, 32)) {
		OPC_BegStat();
		OPM_WriteString((CHAR*)"SYSTEM_CheckCommandInterrupt()", 31);
		OPC_EndStat();
	}
}

static void OPC_InitImports (OPT_Object obj)
{
	INT16 i;
	if (obj != NIL) {
		OPC_InitImports(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1016, 22, 39994))->left);
		if ((((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1017, 14, 40016))->mode == 11 && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1017, 38, 40040))->mnolev != 0)) {
			if (__IN(20, OPM_Options, 32)) {
				if (__STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(-((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1019, 29, 40133))->mnolev, 64, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1019, 25, 40129)]), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1019, 38, 40142))->name, "core") == 0) {
					OPM_LogWStr((CHAR*)"The library name core is reserved for the minimal runtime.", 59);
					OPM_LogWLn();
					OPM_noerr = 0;
					return;
				}
				if (Strings_Length(((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(-((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1023, 44, 40358))->mnolev, 64, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1023, 40, 40354)]), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1023, 53, 40367))->name, 256) >= 64) {
					OPM_LogWStr((CHAR*)"Modular imports must fit the 63-character runtime registry.", 60);
					OPM_LogWLn();
					OPM_noerr = 0;
					return;
				}
				i = 0;
				while ((i < OPM_SharedImportCount && __STRCMP(OPM_SharedImports[__X_AT(i, 64, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1029, 34, 40652)], ((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(-((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1029, 54, 40672))->mnolev, 64, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1029, 50, 40668)]), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1029, 63, 40681))->name) != 0)) {
					i += 1;
				}
				if (i == OPM_SharedImportCount) {
					if (i >= 64) {
						OPM_LogWStr((CHAR*)"Too many modular imports.", 26);
						OPM_LogWLn();
						OPM_noerr = 0;
						return;
					}
					__COPY(((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(-((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1035, 33, 40953))->mnolev, 64, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1035, 29, 40949)]), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1035, 42, 40962))->name, OPM_SharedImports[__X_AT(i, 64, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1035, 67, 40987)], 64);
					OPM_SharedImportCount += 1;
				}
			}
			OPC_BegStat();
			OPM_WriteString((CHAR*)"__MODULE_IMPORT(", 17);
			OPM_WriteStringVar((void*)((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(-((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1040, 43, 41154))->mnolev, 64, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1040, 39, 41150)]), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1040, 52, 41163))->name, 256);
			OPM_Write(')');
			OPC_EndStat();
		}
		OPC_InitImports(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1043, 22, 41236))->right);
	}
}

static void OPC_RegisterImports (OPT_Object obj)
{
	if (obj != NIL) {
		OPC_RegisterImports(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1050, 26, 41374))->left);
		if ((((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1051, 14, 41395))->mode == 11 && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1051, 37, 41418))->mnolev != 0)) {
			OPC_BegStat();
			OPM_WriteString((CHAR*)"Heap_REGIMPORT(m, ", 19);
			OPM_WriteStringVar((void*)((OPT_Object)__NIL_AT((ADDRESS)(OPT_GlbMod[__X_AT(-((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1053, 43, 41534))->mnolev, 64, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1053, 39, 41530)]), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1053, 51, 41542))->name, 256);
			OPM_WriteString((CHAR*)"__init())", 10);
			OPC_EndStat();
		}
		OPC_RegisterImports(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1056, 26, 41632))->right);
	}
}

void OPC_GenEnumPtrs (OPT_Object var)
{
	OPT_Struct typ = NIL;
	INT32 n;
	OPC_GlbPtrs = 0;
	while (var != NIL) {
		typ = ((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1064, 17, 41818))->typ;
		if (OPC_NofPtrs(typ) > 0) {
			if (!OPC_GlbPtrs) {
				OPC_GlbPtrs = 1;
				OPM_WriteString((CHAR*)"static void EnumPtrs(void (*P)(void*))", 39);
				OPM_WriteLn();
				OPC_BegBlk();
			}
			OPC_BegStat();
			if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1071, 15, 42042))->form == 11) {
				OPM_WriteString((CHAR*)"P(", 3);
				OPC_Ident(var);
				OPM_Write(')');
			} else if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1073, 18, 42146))->comp == 4) {
				OPM_WriteString((CHAR*)"__ENUMR(&", 10);
				OPC_Ident(var);
				OPM_WriteString((CHAR*)", ", 3);
				OPC_Andent(typ);
				OPM_WriteString((CHAR*)"__typ", 6);
				OPC_Str1((CHAR*)", #", 4, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1075, 67, 42312))->size);
				OPM_WriteString((CHAR*)", 1, P)", 8);
			} else if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1076, 18, 42365))->comp == 2) {
				n = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1077, 19, 42407))->n;
				typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1077, 34, 42422))->BaseTyp;
				while (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1078, 20, 42452))->comp == 2) {
					n = n * ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1078, 54, 42486))->n;
					typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1078, 69, 42501))->BaseTyp;
				}
				if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1079, 17, 42533))->form == 11) {
					OPM_WriteString((CHAR*)"__ENUMP(", 9);
					OPC_Ident(var);
					OPC_Str1((CHAR*)", #, P)", 8, n);
				} else if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1081, 20, 42650))->comp == 4) {
					OPM_WriteString((CHAR*)"__ENUMR(", 9);
					OPC_Ident(var);
					OPM_WriteString((CHAR*)", ", 3);
					OPC_Andent(typ);
					OPM_WriteString((CHAR*)"__typ", 6);
					OPC_Str1((CHAR*)", #", 4, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1083, 69, 42819))->size);
					OPC_Str1((CHAR*)", #, P)", 8, n);
				}
			}
			OPC_EndStat();
		}
		var = ((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1088, 17, 42919))->link;
	}
	if (OPC_GlbPtrs) {
		OPC_EndBlk();
		OPM_WriteLn();
	}
}

void OPC_EnterBody (void)
{
	OPM_WriteLn();
	OPM_WriteString((CHAR*)"export ", 8);
	if (__IN(10, OPM_Options, 32)) {
		OPM_WriteString((CHAR*)"int main(int argc, char **argv)", 32);
		OPM_WriteLn();
	} else {
		OPM_WriteString((CHAR*)"void *", 7);
		OPM_WriteString(OPM_modName, 64);
		OPM_WriteString(OPC_BodyNameExt, 13);
		OPM_WriteLn();
	}
	OPC_BegBlk();
	OPC_BegStat();
	if (__IN(10, OPM_Options, 32)) {
		OPM_WriteString((CHAR*)"__INIT(argc, argv)", 19);
	} else {
		OPM_WriteString((CHAR*)"__DEFMOD", 9);
	}
	OPC_EndStat();
	if ((__IN(10, OPM_Options, 32) && 0)) {
		OPC_BegStat();
		OPM_WriteString((CHAR*)"/*don`t do it!*/ printf(\"DEMO VERSION: DO NOT USE THIS PROGRAM FOR ANY COMMERCIAL PURPOSE\\n\")", 94);
		OPC_EndStat();
	}
	OPC_InitImports(((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1111, 29, 43714))->right);
	OPC_BegStat();
	if (__IN(10, OPM_Options, 32)) {
		OPM_WriteString((CHAR*)"__REGMAIN(\"", 12);
	} else {
		OPM_WriteString((CHAR*)"__REGMOD(\"", 11);
	}
	OPM_WriteString(OPM_modName, 64);
	if (OPC_GlbPtrs) {
		OPM_WriteString((CHAR*)"\", EnumPtrs)", 13);
	} else {
		OPM_WriteString((CHAR*)"\", 0)", 6);
	}
	OPC_EndStat();
	if (__IN(20, OPM_Options, 32)) {
		OPC_BegStat();
		OPM_WriteString((CHAR*)"__module_owner = m", 19);
		OPC_EndStat();
		OPC_RegisterImports(((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1119, 35, 44123))->right);
	}
	if ((!__IN(20, OPM_Options, 32) && __STRCMP(OPM_modName, "SYSTEM") != 0)) {
		OPC_RegCmds(OPT_topScope);
	}
}

void OPC_FinishBody (void)
{
	if (__IN(20, OPM_Options, 32)) {
		OPC_BegStat();
		OPM_WriteString((CHAR*)"__LEAVEMODULE()", 16);
		OPC_EndStat();
		OPC_BegStat();
		OPM_WriteString((CHAR*)"Heap_MODREADY(m, (ADDRESS)", 27);
		if (__IN(10, OPM_Options, 32)) {
			OPM_WriteString((CHAR*)"main", 5);
		} else {
			OPM_WriteStringVar((void*)OPM_modName, 64);
			OPM_WriteString((CHAR*)"__init", 7);
		}
		OPM_WriteString((CHAR*)")", 2);
		OPC_EndStat();
	}
}

void OPC_ExitBody (void)
{
	OPC_FinishBody();
	OPC_BegStat();
	if (__IN(10, OPM_Options, 32)) {
		OPM_WriteString((CHAR*)"__FINI;", 8);
	} else {
		OPM_WriteString((CHAR*)"__ENDMOD;", 10);
	}
	OPM_WriteLn();
	OPC_EndBlk();
}

void OPC_DefineInter (OPT_Object proc)
{
	OPT_Object scope = NIL;
	scope = ((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1146, 18, 45014))->scope;
	OPM_WriteString((CHAR*)"static ", 8);
	OPM_WriteString((CHAR*)"struct ", 8);
	OPM_WriteStringVar((void*)((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1147, 85, 45107))->name, 256);
	OPM_Write(' ');
	OPC_BegBlk();
	OPC_IdentList(((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1149, 19, 45162))->link, 3);
	OPC_IdentList(((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1150, 20, 45210))->scope, 3);
	OPC_BegStat();
	OPM_WriteString((CHAR*)"struct ", 8);
	OPM_WriteStringVar((void*)((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1152, 58, 45350))->name, 256);
	OPM_Write(' ');
	OPM_Write('*');
	OPM_WriteString((CHAR*)"lnk", 4);
	OPC_EndStat();
	OPC_EndBlk0();
	OPM_Write(' ');
	OPM_Write('*');
	OPM_WriteStringVar((void*)((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1155, 46, 45505))->name, 256);
	OPM_WriteString((CHAR*)"_s", 3);
	OPC_EndStat();
	OPM_WriteLn();
	OPC_ProcPredefs(((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1156, 23, 45588))->right, 0);
	OPM_WriteLn();
}

BOOLEAN OPC_NeedsRetval (OPT_Object proc)
{
	return (((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1162, 17, 45838))->typ != OPT_notyp && (!((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1162, 44, 45865))->scope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1162, 51, 45872))->leaf || __IN(20, OPM_Options, 32)));
}

void OPC_EnterProc (OPT_Object proc)
{
	OPT_Object var = NIL, scope = NIL;
	OPT_Struct typ = NIL;
	INT16 dim;
	if (((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1168, 12, 46060))->vis != 1) {
		OPM_WriteString((CHAR*)"static ", 8);
	}
	OPC_ProcHeader(proc, 1);
	OPC_BegBlk();
	scope = ((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1171, 18, 46176))->scope;
	OPC_IdentList(((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1172, 20, 46204))->scope, 0);
	if (!((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1173, 14, 46230))->leaf) {
		OPC_BegStat();
		OPM_WriteString((CHAR*)"struct ", 8);
		OPM_WriteStringVar((void*)((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1174, 69, 46368))->name, 256);
		OPM_Write(' ');
		OPM_WriteString((CHAR*)"_s", 3);
		OPC_EndStat();
	}
	if (OPC_NeedsRetval(proc)) {
		OPC_BegStat();
		OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1177, 50, 46495))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1177, 55, 46500))->strobj);
		OPM_WriteString((CHAR*)" __retval", 10);
		OPC_EndStat();
	}
	if (__IN(20, OPM_Options, 32)) {
		OPC_BegStat();
		OPM_WriteString((CHAR*)"__ENTERMODULE(__module_owner)", 30);
		OPC_EndStat();
	}
	var = ((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1181, 16, 46693))->link;
	while (var != NIL) {
		if ((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1183, 14, 46793))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1183, 19, 46798))->comp == 2 && ((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1183, 45, 46824))->mode == 1)) {
			OPC_BegStat();
			if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1185, 15, 46878))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1185, 20, 46883))->strobj == NIL) {
				OPM_Mark(200, ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1185, 57, 46920))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1185, 62, 46925))->txtpos);
			} else {
				OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1185, 86, 46949))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1185, 91, 46954))->strobj);
			}
			OPM_Write(' ');
			OPC_Ident(var);
			OPM_WriteString((CHAR*)"__copy", 7);
			OPC_EndStat();
		}
		var = ((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1189, 17, 47077))->link;
	}
	var = ((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1191, 16, 47109))->link;
	while (var != NIL) {
		if ((((__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1193, 14, 47187))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1193, 19, 47192))->comp, 0x0c, 32) && ((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1193, 60, 47233))->mode == 1)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1193, 84, 47257))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1193, 89, 47262))->sysflag == 0)) {
			OPC_BegStat();
			if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1195, 15, 47313))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1195, 20, 47318))->comp == 2) {
				OPM_WriteString((CHAR*)"__DUPARR(", 10);
				OPC_Ident(var);
				OPM_WriteString((CHAR*)", ", 3);
				if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1198, 17, 47443))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1198, 22, 47448))->strobj == NIL) {
					OPM_Mark(200, ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1198, 59, 47485))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1198, 64, 47490))->txtpos);
				} else {
					OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1198, 88, 47514))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1198, 93, 47519))->strobj);
				}
			} else {
				OPM_WriteString((CHAR*)"__DUP(", 7);
				OPC_Ident(var);
				OPM_WriteString((CHAR*)", ", 3);
				OPC_Ident(var);
				OPM_WriteString((CHAR*)"__len", 6);
				typ = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1202, 21, 47685))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1202, 26, 47690))->BaseTyp;
				dim = 1;
				while (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1203, 20, 47730))->comp == 3) {
					OPM_WriteString((CHAR*)" * ", 4);
					OPC_Ident(var);
					OPM_WriteString((CHAR*)"__len", 6);
					OPM_WriteInt(dim);
					typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1205, 23, 47867))->BaseTyp;
					dim += 1;
				}
				OPM_WriteString((CHAR*)", ", 3);
				if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1208, 18, 47953))->strobj == NIL) {
					OPM_Mark(200, ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1208, 56, 47991))->txtpos);
				} else {
					OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1209, 25, 48025))->strobj);
				}
			}
			OPM_Write(')');
			OPC_EndStat();
		}
		var = ((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1214, 17, 48123))->link;
	}
	if (!((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1216, 14, 48153))->leaf) {
		var = ((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1217, 18, 48182))->link;
		while (var != NIL) {
			if (!((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1219, 16, 48289))->leaf) {
				OPC_BegStat();
				OPM_WriteString((CHAR*)"_s", 3);
				OPM_Write('.');
				OPC_Ident(var);
				OPM_WriteString((CHAR*)" = ", 4);
				if (__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1223, 17, 48478))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1223, 22, 48483))->comp, 0x0c, 32)) {
					OPM_WriteString((CHAR*)"(void*)", 8);
				} else if (((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1225, 20, 48640))->mode != 2) {
					OPM_Write('&');
				}
				OPC_Ident(var);
				if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1228, 17, 48734))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1228, 22, 48739))->comp == 3) {
					typ = ((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1229, 23, 48786))->typ;
					dim = 0;
					do {
						OPM_WriteString((CHAR*)"; ", 3);
						OPM_WriteString((CHAR*)"_s", 3);
						OPM_Write('.');
						OPC_Ident(var);
						OPM_WriteString((CHAR*)"__len", 6);
						if (dim != 0) {
							OPM_WriteInt(dim);
						}
						OPM_WriteString((CHAR*)" = ", 4);
						OPC_Ident(var);
						OPM_WriteString((CHAR*)"__len", 6);
						if (dim != 0) {
							OPM_WriteInt(dim);
						}
						typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1236, 25, 49180))->BaseTyp;
						dim += 1;
					} while (!(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1237, 22, 49221))->comp != 3));
				} else if ((((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1238, 21, 49262))->mode == 2 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1238, 48, 49289))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1238, 53, 49294))->comp == 4)) {
					OPM_WriteString((CHAR*)"; ", 3);
					OPM_WriteString((CHAR*)"_s", 3);
					OPM_Write('.');
					OPC_Ident(var);
					OPM_WriteString((CHAR*)"__typ", 6);
					OPM_WriteString((CHAR*)" = ", 4);
					OPC_Ident(var);
					OPM_WriteString((CHAR*)"__typ", 6);
				}
				OPC_EndStat();
			}
			var = ((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1245, 19, 49586))->link;
		}
		var = ((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1247, 19, 49623))->scope;
		while (var != NIL) {
			if (!((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1249, 16, 49730))->leaf) {
				OPC_BegStat();
				OPM_WriteString((CHAR*)"_s", 3);
				OPM_Write('.');
				OPC_Ident(var);
				OPM_WriteString((CHAR*)" = ", 4);
				if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1252, 17, 49909))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1252, 22, 49914))->comp != 2) {
					OPM_Write('&');
				} else {
					OPM_WriteString((CHAR*)"(void*)", 8);
				}
				OPC_Ident(var);
				OPC_EndStat();
			}
			var = ((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1257, 19, 50134))->link;
		}
		OPC_BegStat();
		OPM_WriteString((CHAR*)"_s", 3);
		OPM_Write('.');
		OPM_WriteString((CHAR*)"lnk", 4);
		OPM_WriteString((CHAR*)" = ", 4);
		OPM_WriteStringVar((void*)((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1261, 55, 50324))->name, 256);
		OPM_WriteString((CHAR*)"_s", 3);
		OPC_EndStat();
		OPC_BegStat();
		OPM_WriteStringVar((void*)((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1262, 40, 50411))->name, 256);
		OPM_WriteString((CHAR*)"_s", 3);
		OPM_WriteString((CHAR*)" = ", 4);
		OPM_Write('&');
		OPM_WriteString((CHAR*)"_s", 3);
		OPC_EndStat();
	}
	OPC_CheckInterrupt();
}

void OPC_ExitProc (OPT_Object proc, BOOLEAN eoBlock, BOOLEAN implicitRet)
{
	OPT_Object var = NIL;
	BOOLEAN indent;
	indent = eoBlock;
	if ((implicitRet && ((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1272, 27, 50750))->typ != OPT_notyp)) {
		OPM_Write(0x09);
		OPM_WriteString((CHAR*)"__RETCHK;", 10);
		OPM_WriteLn();
	} else if (!eoBlock || implicitRet) {
		if (!((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1275, 15, 50891))->scope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1275, 22, 50898))->leaf) {
			if (indent) {
				OPC_BegStat();
			} else {
				indent = 1;
			}
			OPM_WriteStringVar((void*)((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1278, 32, 51069))->scope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1278, 39, 51076))->name, 256);
			OPM_WriteString((CHAR*)"_s", 3);
			OPM_WriteString((CHAR*)" = ", 4);
			OPM_WriteString((CHAR*)"_s", 3);
			OPM_Write('.');
			OPM_WriteString((CHAR*)"lnk", 4);
			OPC_EndStat();
		}
		var = ((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1283, 18, 51305))->link;
		while (var != NIL) {
			if ((((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1285, 16, 51353))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1285, 21, 51358))->comp == 3 && ((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1285, 48, 51385))->mode == 1)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1285, 72, 51409))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1285, 77, 51414))->sysflag == 0)) {
				if (indent) {
					OPC_BegStat();
				} else {
					indent = 1;
				}
				OPM_WriteString((CHAR*)"__DEL(", 7);
				OPC_Ident(var);
				OPM_Write(')');
				OPC_EndStat();
			}
			var = ((OPT_Object)__NIL_AT((ADDRESS)(var), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1289, 19, 51598))->link;
		}
		if (__IN(20, OPM_Options, 32)) {
			if (indent) {
				OPC_BegStat();
			} else {
				indent = 1;
			}
			OPM_WriteString((CHAR*)"__LEAVEMODULE()", 16);
			OPC_EndStat();
		}
	}
	if (eoBlock) {
		OPC_EndBlk();
		OPM_WriteLn();
	} else if (indent) {
		OPC_BegStat();
	}
}

void OPC_CompleteIdent (OPT_Object obj)
{
	INT16 comp, level;
	level = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1304, 17, 51982))->mnolev;
	if (__IN(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1305, 11, 52002))->mode, 0xc000, 32)) {
		OPC_Ident(obj);
	} else if (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1306, 14, 52067))->adr == 1) {
		if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1307, 13, 52115))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1307, 18, 52120))->comp == 4) {
			OPC_Ident(obj);
			OPM_WriteString((CHAR*)"__", 3);
		} else {
			OPM_WriteString((CHAR*)"(*(", 4);
			OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1309, 42, 52266))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1309, 47, 52271))->strobj);
			OPM_WriteString((CHAR*)"*)&", 4);
			OPC_Ident(obj);
			OPM_Write(')');
		}
	} else if ((level != OPM_level && level > 0)) {
		comp = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1312, 18, 52432))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1312, 23, 52437))->comp;
		if ((((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1313, 14, 52458))->mode != 2 && comp != 3)) {
			OPM_Write('*');
		}
		OPM_WriteStringVar((void*)((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1314, 29, 52555))->scope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1314, 36, 52562))->name, 256);
		OPM_WriteString((CHAR*)"_s", 3);
		OPM_WriteString((CHAR*)"->", 3);
		OPC_Ident(obj);
	} else {
		OPC_Ident(obj);
	}
}

void OPC_TypeOf (OPT_Object ap)
{
	INT16 i;
	__ASSERT(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1324, 14, 52775))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1324, 18, 52779))->comp == 4, 0);
	if (((OPT_Object)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1325, 10, 52809))->mode == 2) {
		if ((INT16)((OPT_Object)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1326, 12, 52844))->mnolev != OPM_level) {
			OPM_WriteStringVar((void*)((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1327, 30, 52960))->scope), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1327, 37, 52967))->name, 256);
			OPM_WriteString((CHAR*)"_s->", 5);
			OPC_Ident(ap);
		} else {
			OPC_Ident(ap);
		}
		OPM_WriteString((CHAR*)"__typ", 6);
	} else if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1332, 13, 53119))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1332, 18, 53124))->strobj != NIL) {
		OPC_Ident(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1333, 15, 53158))->typ), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1333, 20, 53163))->strobj);
		OPM_WriteString((CHAR*)"__typ", 6);
	} else {
		OPC_Andent(((OPT_Object)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1334, 19, 53219))->typ);
	}
}

void OPC_Cmp (INT16 rel)
{
	switch (rel) {
		case 9: 
			OPM_WriteString((CHAR*)" == ", 5);
			break;
		case 10: 
			OPM_WriteString((CHAR*)" != ", 5);
			break;
		case 11: 
			OPM_WriteString((CHAR*)" < ", 4);
			break;
		case 12: 
			OPM_WriteString((CHAR*)" <= ", 5);
			break;
		case 13: 
			OPM_WriteString((CHAR*)" > ", 4);
			break;
		case 14: 
			OPM_WriteString((CHAR*)" >= ", 5);
			break;
		default: 
			OPM_LogWStr((CHAR*)"unhandled case in OPC.Cmp, rel = ", 34);
			OPM_LogWNum(rel, 0);
			OPM_LogWLn();
			break;
	}
}

static void OPC_CharacterLiteral (INT64 c)
{
	if (c < 32 || c > 126) {
		OPM_WriteString((CHAR*)"0x", 3);
		OPM_WriteHex(c);
	} else {
		OPM_Write('\'');
		if ((c == 92 || c == 39) || c == 63) {
			OPM_Write('\\');
		}
		OPM_Write(__CHR(c));
		OPM_Write('\'');
	}
}

static void OPC_StringLiteral (CHAR *s, ADDRESS s__len, INT32 l)
{
	INT32 i;
	INT16 c;
	__DUP(s, s__len, CHAR);
	OPM_Write('"');
	i = 0;
	while (i < l) {
		c = (INT16)s[__X_AT(i, s__len, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1370, 18, 54202)];
		if (c < 32 || c > 126) {
			OPM_Write('\\');
			OPM_Write(__CHR(48 + __ASHR(c, 6)));
			c = __MASK(c, -64);
			OPM_Write(__CHR(48 + __ASHR(c, 3)));
			c = __MASK(c, -8);
			OPM_Write(__CHR(48 + c));
		} else {
			if ((c == 92 || c == 34) || c == 63) {
				OPM_Write('\\');
			}
			OPM_Write(__CHR(c));
		}
		i += 1;
	}
	OPM_Write('"');
	__DEL(s);
}

void OPC_Case (INT64 caseVal, INT16 form)
{
	CHAR ch;
	OPM_WriteString((CHAR*)"case ", 6);
	switch (form) {
		case 3: 
			OPC_CharacterLiteral(caseVal);
			break;
		case 4: 
			OPM_WriteInt(caseVal);
			break;
		default: 
			OPM_LogWStr((CHAR*)"unhandled case in OPC.Case, form = ", 36);
			OPM_LogWNum(form, 0);
			OPM_LogWLn();
			break;
	}
	OPM_WriteString((CHAR*)": ", 3);
}

void OPC_SetInclude (BOOLEAN exclude)
{
	if (exclude) {
		OPM_WriteString((CHAR*)" &= ~", 6);
	} else {
		OPM_WriteString((CHAR*)" |= ", 5);
	}
}

void OPC_Increment (BOOLEAN decrement)
{
	if (decrement) {
		OPM_WriteString((CHAR*)" -= ", 5);
	} else {
		OPM_WriteString((CHAR*)" += ", 5);
	}
}

void OPC_Halt (INT32 n)
{
	OPC_Str1((CHAR*)"__HALT(#)", 10, n);
}

void OPC_IntLiteral (INT64 n, INT32 size)
{
	if ((((size > 4 && n <= 2147483647)) && n > (-2147483647-1))) {
		OPM_WriteString((CHAR*)"((INT", 6);
		OPM_WriteInt(__ASHL(size, 3));
		OPM_WriteString((CHAR*)")(", 3);
		OPM_WriteInt(n);
		OPM_WriteString((CHAR*)"))", 3);
	} else {
		OPM_WriteInt(n);
	}
}

void OPC_Len (OPT_Object obj, OPT_Struct array, INT64 dim)
{
	INT64 d;
	d = dim;
	while (d > 0) {
		array = ((OPT_Struct)__NIL_AT((ADDRESS)(array), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1434, 34, 56133))->BaseTyp;
		d -= 1;
	}
	if (((OPT_Struct)__NIL_AT((ADDRESS)(array), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1435, 13, 56168))->comp == 3) {
		OPC_CompleteIdent(obj);
		OPM_WriteString((CHAR*)"__len", 6);
		if (dim != 0) {
			OPM_WriteInt(dim);
		}
	} else {
		OPM_WriteInt(((OPT_Struct)__NIL_AT((ADDRESS)(array), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1439, 25, 56333))->n);
	}
}

void OPC_Constant (OPT_Const con, INT16 form)
{
	INT16 i;
	UINT64 s;
	INT64 hex;
	BOOLEAN skipLeading;
	switch (form) {
		case 1: 
			OPM_WriteInt(((OPT_Const)__NIL_AT((ADDRESS)(con), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1448, 35, 56555))->intval);
			break;
		case 2: 
			OPM_WriteInt(((OPT_Const)__NIL_AT((ADDRESS)(con), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1449, 35, 56599))->intval);
			break;
		case 3: 
			OPC_CharacterLiteral(((OPT_Const)__NIL_AT((ADDRESS)(con), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1450, 39, 56647))->intval);
			break;
		case 4: 
			OPM_WriteInt(((OPT_Const)__NIL_AT((ADDRESS)(con), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1451, 35, 56690))->intval);
			break;
		case 5: 
			OPM_WriteReal(((OPT_Const)__NIL_AT((ADDRESS)(con), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1452, 36, 56735))->realval, 'f');
			break;
		case 6: 
			OPM_WriteReal(((OPT_Const)__NIL_AT((ADDRESS)(con), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1453, 36, 56786))->realval, 0x00);
			break;
		case 7: 
			OPM_WriteString((CHAR*)"0x", 3);
			skipLeading = 1;
			s = ((OPT_Const)__NIL_AT((ADDRESS)(con), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1456, 27, 56907))->setval;
			i = 64;
			do {
				hex = 0;
				do {
					i -= 1;
					hex = __ASHL(hex, 1);
					if (__IN(i, s, 64)) {
						hex += 1;
					}
				} while (!(__MASK(i, -8) == 0));
				if (hex != 0 || !skipLeading) {
					OPM_WriteHex(hex);
					skipLeading = 0;
				}
			} while (!(i == 0));
			if (skipLeading) {
				OPM_Write('0');
			}
			break;
		case 8: 
			OPC_StringLiteral(*((OPT_ConstExt)__NIL_AT((ADDRESS)(((OPT_Const)__NIL_AT((ADDRESS)(con), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1469, 36, 57447))->ext), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1469, 40, 57451)), 1024, ((OPT_Const)__NIL_AT((ADDRESS)(con), (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1469, 46, 57457))->intval2 - 1);
			break;
		case 9: 
			OPM_WriteString((CHAR*)"NIL", 4);
			break;
		default: 
			OPM_LogWStr((CHAR*)"unhandled case in OPC.Constant, form = ", 40);
			OPM_LogWNum(form, 0);
			OPM_LogWLn();
			break;
	}
}

static struct InitKeywords__48 {
	INT8 *n;
	struct InitKeywords__48 *lnk;
} *InitKeywords__48_s;

static void Enter__49 (CHAR *s, ADDRESS s__len);

static void Enter__49 (CHAR *s, ADDRESS s__len)
{
	INT16 h;
	__DUP(s, s__len, CHAR);
	h = OPC_KeywordHash((void*)s, s__len);
	while (OPC_hashtab[__X_AT(h, 257, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1483, 21, 57815)] >= 0) {
		h = (int)__MOD(h + 1, 257);
	}
	OPC_hashtab[__X_AT(h, 257, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1484, 15, 57875)] = *InitKeywords__48_s->n;
	__COPY(s, OPC_keytab[__X_AT(*InitKeywords__48_s->n, 96, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1484, 39, 57899)], 32);
	*InitKeywords__48_s->n += 1;
	__DEL(s);
}

static void OPC_InitKeywords (void)
{
	INT8 n;
	INT16 i;
	struct InitKeywords__48 _s;
	_s.n = &n;
	_s.lnk = InitKeywords__48_s;
	InitKeywords__48_s = &_s;
	n = 0;
	i = 0;
	while (i <= 256) {
		OPC_hashtab[__X_AT(i, 257, (CHAR*)"../../src/compiler/OPC.Mod", 27, (CHAR*)"OPC", 4, 1488, 45, 57987)] = -1;
		i += 1;
	}
	Enter__49((CHAR*)"ADDRESS", 8);
	Enter__49((CHAR*)"INT16", 6);
	Enter__49((CHAR*)"INT32", 6);
	Enter__49((CHAR*)"INT64", 6);
	Enter__49((CHAR*)"INT8", 5);
	Enter__49((CHAR*)"UINT16", 7);
	Enter__49((CHAR*)"UINT32", 7);
	Enter__49((CHAR*)"UINT64", 7);
	Enter__49((CHAR*)"UINT8", 6);
	Enter__49((CHAR*)"asm", 4);
	Enter__49((CHAR*)"auto", 5);
	Enter__49((CHAR*)"break", 6);
	Enter__49((CHAR*)"case", 5);
	Enter__49((CHAR*)"char", 5);
	Enter__49((CHAR*)"const", 6);
	Enter__49((CHAR*)"continue", 9);
	Enter__49((CHAR*)"default", 8);
	Enter__49((CHAR*)"do", 3);
	Enter__49((CHAR*)"double", 7);
	Enter__49((CHAR*)"else", 5);
	Enter__49((CHAR*)"enum", 5);
	Enter__49((CHAR*)"extern", 7);
	Enter__49((CHAR*)"export", 7);
	Enter__49((CHAR*)"float", 6);
	Enter__49((CHAR*)"for", 4);
	Enter__49((CHAR*)"fortran", 8);
	Enter__49((CHAR*)"goto", 5);
	Enter__49((CHAR*)"if", 3);
	Enter__49((CHAR*)"import", 7);
	Enter__49((CHAR*)"int", 4);
	Enter__49((CHAR*)"long", 5);
	Enter__49((CHAR*)"register", 9);
	Enter__49((CHAR*)"return", 7);
	Enter__49((CHAR*)"short", 6);
	Enter__49((CHAR*)"signed", 7);
	Enter__49((CHAR*)"sizeof", 7);
	Enter__49((CHAR*)"size_t", 7);
	Enter__49((CHAR*)"static", 7);
	Enter__49((CHAR*)"struct", 7);
	Enter__49((CHAR*)"switch", 7);
	Enter__49((CHAR*)"typedef", 8);
	Enter__49((CHAR*)"union", 6);
	Enter__49((CHAR*)"unsigned", 9);
	Enter__49((CHAR*)"void", 5);
	Enter__49((CHAR*)"volatile", 9);
	Enter__49((CHAR*)"while", 6);
	Enter__49((CHAR*)"inline", 7);
	Enter__49((CHAR*)"restrict", 9);
	Enter__49((CHAR*)"_Bool", 6);
	Enter__49((CHAR*)"_Complex", 9);
	Enter__49((CHAR*)"_Imaginary", 11);
	Enter__49((CHAR*)"_Alignas", 9);
	Enter__49((CHAR*)"_Alignof", 9);
	Enter__49((CHAR*)"_Atomic", 8);
	Enter__49((CHAR*)"_Generic", 9);
	Enter__49((CHAR*)"_Noreturn", 10);
	Enter__49((CHAR*)"_Static_assert", 15);
	Enter__49((CHAR*)"_Thread_local", 14);
	Enter__49((CHAR*)"_BitInt", 8);
	Enter__49((CHAR*)"_Decimal32", 11);
	Enter__49((CHAR*)"_Decimal64", 11);
	Enter__49((CHAR*)"_Decimal128", 12);
	Enter__49((CHAR*)"alignas", 8);
	Enter__49((CHAR*)"alignof", 8);
	Enter__49((CHAR*)"bool", 5);
	Enter__49((CHAR*)"constexpr", 10);
	Enter__49((CHAR*)"false", 6);
	Enter__49((CHAR*)"nullptr", 8);
	Enter__49((CHAR*)"static_assert", 14);
	Enter__49((CHAR*)"thread_local", 13);
	Enter__49((CHAR*)"true", 5);
	Enter__49((CHAR*)"typeof", 7);
	Enter__49((CHAR*)"typeof_unqual", 14);
	InitKeywords__48_s = _s.lnk;
}


export void *OPC__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(Configuration);
	__MODULE_IMPORT(OPM);
	__MODULE_IMPORT(OPT);
	__MODULE_IMPORT(Strings);
	__REGMOD("OPC", 0);
	__REGCMD("BegBlk", OPC_BegBlk);
	__REGCMD("BegStat", OPC_BegStat);
	__REGCMD("CheckInterrupt", OPC_CheckInterrupt);
	__REGCMD("EndBlk", OPC_EndBlk);
	__REGCMD("EndBlk0", OPC_EndBlk0);
	__REGCMD("EndStat", OPC_EndStat);
	__REGCMD("EnterBody", OPC_EnterBody);
	__REGCMD("ExitBody", OPC_ExitBody);
	__REGCMD("FinishBody", OPC_FinishBody);
	__REGCMD("GenHdrIncludes", OPC_GenHdrIncludes);
	__REGCMD("Init", OPC_Init);
	__REGCMD("RegisterBody", OPC_RegisterBody);
/* BEGIN */
	OPC_InitKeywords();
	__ENDMOD;
}
