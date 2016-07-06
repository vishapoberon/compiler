/* voc  1.95 [2016/06/30] for gcc LP64 on cygwin xtspkaSfF */
#define LARGE
#include "SYSTEM.h"
#include "Configuration.h"
#include "OPM.h"
#include "OPT.h"


static INTEGER OPC_indentLevel;
static BOOLEAN OPC_ptrinit, OPC_mainprog, OPC_ansi;
static SHORTINT OPC_hashtab[105];
static CHAR OPC_keytab[36][9];
static BOOLEAN OPC_GlbPtrs;
static CHAR OPC_BodyNameExt[13];


export void OPC_Align (LONGINT *adr, LONGINT base);
export void OPC_Andent (OPT_Struct typ);
static void OPC_AnsiParamList (OPT_Object obj, BOOLEAN showParamNames);
export LONGINT OPC_Base (OPT_Struct typ);
export OPT_Object OPC_BaseTProc (OPT_Object obj);
export void OPC_BegBlk (void);
export void OPC_BegStat (void);
static void OPC_CProcDefs (OPT_Object obj, INTEGER vis);
export void OPC_Case (LONGINT caseVal, INTEGER form);
export void OPC_Cmp (INTEGER rel);
export void OPC_CompleteIdent (OPT_Object obj);
export void OPC_Constant (OPT_Const con, INTEGER form);
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
static void OPC_FieldList (OPT_Struct typ, BOOLEAN last, LONGINT *off, LONGINT *n, LONGINT *curAlign);
static void OPC_FillGap (LONGINT gap, LONGINT off, LONGINT align, LONGINT *n, LONGINT *curAlign);
export void OPC_GenBdy (OPT_Node n);
static void OPC_GenDynTypes (OPT_Node n, INTEGER vis);
export void OPC_GenEnumPtrs (OPT_Object var);
export void OPC_GenHdr (OPT_Node n);
export void OPC_GenHdrIncludes (void);
static void OPC_GenHeaderMsg (void);
export void OPC_Halt (LONGINT n);
export void OPC_Ident (OPT_Object obj);
static void OPC_IdentList (OPT_Object obj, INTEGER vis);
static void OPC_Include (CHAR *name, LONGINT name__len);
static void OPC_IncludeImports (OPT_Object obj, INTEGER vis);
export void OPC_Increment (BOOLEAN decrement);
export void OPC_Indent (INTEGER count);
export void OPC_Init (void);
static void OPC_InitImports (OPT_Object obj);
static void OPC_InitKeywords (void);
export void OPC_InitTDesc (OPT_Struct typ);
static void OPC_InitTProcs (OPT_Object typ, OPT_Object obj);
export void OPC_Len (OPT_Object obj, OPT_Struct array, LONGINT dim);
static void OPC_LenList (OPT_Object par, BOOLEAN ansiDefine, BOOLEAN showParamName);
static INTEGER OPC_Length (CHAR *s, LONGINT s__len);
export LONGINT OPC_NofPtrs (OPT_Struct typ);
static INTEGER OPC_PerfectHash (CHAR *s, LONGINT s__len);
static BOOLEAN OPC_Prefixed (OPT_ConstExt x, CHAR *y, LONGINT y__len);
static void OPC_ProcHeader (OPT_Object proc, BOOLEAN define);
static void OPC_ProcPredefs (OPT_Object obj, SHORTINT vis);
static void OPC_PutBase (OPT_Struct typ);
static void OPC_PutPtrOffsets (OPT_Struct typ, LONGINT adr, LONGINT *cnt);
static void OPC_RegCmds (OPT_Object obj);
export void OPC_SetInclude (BOOLEAN exclude);
static void OPC_Stars (OPT_Struct typ, BOOLEAN *openClause);
static void OPC_Str1 (CHAR *s, LONGINT s__len, LONGINT x);
export void OPC_TDescDecl (OPT_Struct typ);
export void OPC_TypeDefs (OPT_Object obj, INTEGER vis);
export void OPC_TypeOf (OPT_Object ap);
static BOOLEAN OPC_Undefined (OPT_Object obj);


void OPC_Init (void)
{
	OPC_indentLevel = 0;
	OPC_ptrinit = __IN(5, OPM_opt);
	OPC_mainprog = OPM_mainProg || OPM_mainLinkStat;
	OPC_ansi = __IN(6, OPM_opt);
	if (OPC_ansi) {
		__MOVE("__init(void)", OPC_BodyNameExt, 13);
	} else {
		__MOVE("__init()", OPC_BodyNameExt, 9);
	}
}

void OPC_Indent (INTEGER count)
{
	OPC_indentLevel += count;
}

void OPC_BegStat (void)
{
	INTEGER i;
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

static void OPC_Str1 (CHAR *s, LONGINT s__len, LONGINT x)
{
	CHAR ch;
	INTEGER i;
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
		ch = s[__X(i, s__len)];
	}
	__DEL(s);
}

static INTEGER OPC_Length (CHAR *s, LONGINT s__len)
{
	INTEGER _o_result;
	INTEGER i;
	i = 0;
	while (s[__X(i, s__len)] != 0x00) {
		i += 1;
	}
	_o_result = i;
	return _o_result;
}

static INTEGER OPC_PerfectHash (CHAR *s, LONGINT s__len)
{
	INTEGER _o_result;
	INTEGER i, h;
	i = 0;
	h = 0;
	while ((s[__X(i, s__len)] != 0x00 && i < 5)) {
		h = 3 * h + (int)s[__X(i, s__len)];
		i += 1;
	}
	_o_result = (int)__MOD(h, 105);
	return _o_result;
}

void OPC_Ident (OPT_Object obj)
{
	INTEGER mode, level, h;
	mode = obj->mode;
	level = obj->mnolev;
	if ((__IN(mode, 0x62) && level > 0) || __IN(mode, 0x14)) {
		OPM_WriteStringVar((void*)obj->name, ((LONGINT)(256)));
		h = OPC_PerfectHash((void*)obj->name, ((LONGINT)(256)));
		if (OPC_hashtab[__X(h, ((LONGINT)(105)))] >= 0) {
			if (__STRCMP(OPC_keytab[__X(OPC_hashtab[__X(h, ((LONGINT)(105)))], ((LONGINT)(36)))], obj->name) == 0) {
				OPM_Write('_');
			}
		}
	} else {
		if (mode != 5 || obj->linkadr != 2) {
			if (mode == 13) {
				OPC_Ident(obj->link->typ->strobj);
			} else if (level < 0) {
				OPM_WriteStringVar((void*)OPT_GlbMod[__X(-level, ((LONGINT)(64)))]->name, ((LONGINT)(256)));
				if (OPM_currFile == 0) {
					OPT_GlbMod[__X(-level, ((LONGINT)(64)))]->vis = 1;
				}
			} else {
				OPM_WriteStringVar((void*)OPM_modName, ((LONGINT)(32)));
			}
			OPM_Write('_');
		} else if (obj == OPT_sysptrtyp->strobj || obj == OPT_bytetyp->strobj) {
			OPM_WriteString((CHAR*)"SYSTEM_", (LONGINT)8);
		}
		OPM_WriteStringVar((void*)obj->name, ((LONGINT)(256)));
	}
}

static void OPC_Stars (OPT_Struct typ, BOOLEAN *openClause)
{
	INTEGER pointers;
	*openClause = 0;
	if (((typ->strobj == NIL || typ->strobj->name[0] == 0x00) && typ->comp != 4)) {
		if (__IN(typ->comp, 0x0c)) {
			OPC_Stars(typ->BaseTyp, &*openClause);
			*openClause = typ->comp == 2;
		} else if (typ->form == 14) {
			OPM_Write('(');
			OPM_Write('*');
		} else {
			pointers = 0;
			while (((typ->strobj == NIL || typ->strobj->name[0] == 0x00) && typ->form == 13)) {
				pointers += 1;
				typ = typ->BaseTyp;
			}
			if (pointers > 0) {
				if (typ->comp != 3) {
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
	INTEGER form, comp;
	typ = dcl->typ;
	varPar = ((dcl->mode == 2 && typ->comp != 2) || typ->comp == 3) || scopeDef;
	OPC_Stars(typ, &openClause);
	if (varPar) {
		if (openClause) {
			OPM_Write('(');
		}
		OPM_Write('*');
	}
	if (dcl->name[0] != 0x00) {
		OPC_Ident(dcl);
	}
	if ((varPar && openClause)) {
		OPM_Write(')');
	}
	openClause = 0;
	for (;;) {
		form = typ->form;
		comp = typ->comp;
		if (((typ->strobj != NIL && typ->strobj->name[0] != 0x00) || form == 12) || comp == 4) {
			break;
		} else if ((form == 13 && typ->BaseTyp->comp != 3)) {
			openClause = 1;
		} else if (form == 14 || __IN(comp, 0x0c)) {
			if (openClause) {
				OPM_Write(')');
				openClause = 0;
			}
			if (form == 14) {
				if (OPC_ansi) {
					OPM_Write(')');
					OPC_AnsiParamList(typ->link, 0);
				} else {
					OPM_WriteString((CHAR*)")()", (LONGINT)4);
				}
				break;
			} else if (comp == 2) {
				OPM_Write('[');
				OPM_WriteInt(typ->n);
				OPM_Write(']');
			}
		} else {
			break;
		}
		typ = typ->BaseTyp;
	}
}

void OPC_Andent (OPT_Struct typ)
{
	if (typ->strobj == NIL || typ->align >= 65536) {
		OPM_WriteStringVar((void*)OPM_modName, ((LONGINT)(32)));
		OPC_Str1((CHAR*)"__#", (LONGINT)4, __ASHR(typ->align, 16));
	} else {
		OPC_Ident(typ->strobj);
	}
}

static BOOLEAN OPC_Undefined (OPT_Object obj)
{
	BOOLEAN _o_result;
	_o_result = (((obj->mnolev >= 0 && obj->linkadr != (LONGINT)(3 + OPM_currFile))) && obj->linkadr != 2) || obj->name[0] == 0x00;
	return _o_result;
}

static void OPC_DeclareBase (OPT_Object dcl)
{
	OPT_Struct typ = NIL, prev = NIL;
	OPT_Object obj = NIL;
	INTEGER nofdims;
	LONGINT off, n, dummy;
	typ = dcl->typ;
	prev = typ;
	while ((((((((typ->strobj == NIL || typ->comp == 3) || OPC_Undefined(typ->strobj)) && typ->comp != 4)) && typ->form != 12)) && !((typ->form == 13 && typ->BaseTyp->comp == 3)))) {
		prev = typ;
		typ = typ->BaseTyp;
	}
	obj = typ->strobj;
	if (typ->form == 12) {
		OPM_WriteString((CHAR*)"void", (LONGINT)5);
	} else if ((obj != NIL && !OPC_Undefined(obj))) {
		OPC_Ident(obj);
	} else if (typ->comp == 4) {
		OPM_WriteString((CHAR*)"struct ", (LONGINT)8);
		OPC_Andent(typ);
		if ((prev->form != 13 && (obj != NIL || dcl->name[0] == 0x00))) {
			if ((typ->BaseTyp != NIL && typ->BaseTyp->strobj->vis != 0)) {
				OPM_WriteString((CHAR*)" { /* ", (LONGINT)7);
				OPC_Ident(typ->BaseTyp->strobj);
				OPM_WriteString((CHAR*)" */", (LONGINT)4);
				OPM_WriteLn();
				OPC_Indent(1);
			} else {
				OPM_Write(' ');
				OPC_BegBlk();
			}
			OPC_FieldList(typ, 1, &off, &n, &dummy);
			OPC_EndBlk0();
		}
	} else if ((typ->form == 13 && typ->BaseTyp->comp == 3)) {
		typ = typ->BaseTyp->BaseTyp;
		nofdims = 1;
		while (typ->comp == 3) {
			nofdims += 1;
			typ = typ->BaseTyp;
		}
		OPM_WriteString((CHAR*)"struct ", (LONGINT)8);
		OPC_BegBlk();
		OPC_BegStat();
		OPC_Str1((CHAR*)"LONGINT len[#]", (LONGINT)15, nofdims);
		OPC_EndStat();
		OPC_BegStat();
		__NEW(obj, OPT_ObjDesc);
		__NEW(obj->typ, OPT_StrDesc);
		obj->typ->form = 15;
		obj->typ->comp = 2;
		obj->typ->n = 1;
		obj->typ->BaseTyp = typ;
		obj->mode = 4;
		__MOVE("data", obj->name, 5);
		obj->linkadr = 0;
		OPC_DeclareBase(obj);
		OPM_Write(' ');
		OPC_DeclareObj(obj, 0);
		OPC_EndStat();
		OPC_EndBlk0();
	}
}

LONGINT OPC_NofPtrs (OPT_Struct typ)
{
	LONGINT _o_result;
	OPT_Object fld = NIL;
	OPT_Struct btyp = NIL;
	LONGINT n;
	if ((typ->form == 13 && typ->sysflag == 0)) {
		_o_result = 1;
		return _o_result;
	} else if ((typ->comp == 4 && __MASK(typ->sysflag, -256) == 0)) {
		btyp = typ->BaseTyp;
		if (btyp != NIL) {
			n = OPC_NofPtrs(btyp);
		} else {
			n = 0;
		}
		fld = typ->link;
		while ((fld != NIL && fld->mode == 4)) {
			if (__STRCMP(fld->name, "@ptr") != 0) {
				n = n + OPC_NofPtrs(fld->typ);
			} else {
				n += 1;
			}
			fld = fld->link;
		}
		_o_result = n;
		return _o_result;
	} else if (typ->comp == 2) {
		btyp = typ->BaseTyp;
		n = typ->n;
		while (btyp->comp == 2) {
			n = btyp->n * n;
			btyp = btyp->BaseTyp;
		}
		_o_result = OPC_NofPtrs(btyp) * n;
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

static void OPC_PutPtrOffsets (OPT_Struct typ, LONGINT adr, LONGINT *cnt)
{
	OPT_Object fld = NIL;
	OPT_Struct btyp = NIL;
	LONGINT n, i;
	if ((typ->form == 13 && typ->sysflag == 0)) {
		OPM_WriteInt(adr);
		OPM_WriteString((CHAR*)", ", (LONGINT)3);
		*cnt += 1;
		if (__MASK(*cnt, -16) == 0) {
			OPM_WriteLn();
			OPM_Write(0x09);
		}
	} else if ((typ->comp == 4 && __MASK(typ->sysflag, -256) == 0)) {
		btyp = typ->BaseTyp;
		if (btyp != NIL) {
			OPC_PutPtrOffsets(btyp, adr, &*cnt);
		}
		fld = typ->link;
		while ((fld != NIL && fld->mode == 4)) {
			if (__STRCMP(fld->name, "@ptr") != 0) {
				OPC_PutPtrOffsets(fld->typ, adr + fld->adr, &*cnt);
			} else {
				OPM_WriteInt(adr + fld->adr);
				OPM_WriteString((CHAR*)", ", (LONGINT)3);
				*cnt += 1;
				if (__MASK(*cnt, -16) == 0) {
					OPM_WriteLn();
					OPM_Write(0x09);
				}
			}
			fld = fld->link;
		}
	} else if (typ->comp == 2) {
		btyp = typ->BaseTyp;
		n = typ->n;
		while (btyp->comp == 2) {
			n = btyp->n * n;
			btyp = btyp->BaseTyp;
		}
		if (OPC_NofPtrs(btyp) > 0) {
			i = 0;
			while (i < n) {
				OPC_PutPtrOffsets(btyp, adr + i * btyp->size, &*cnt);
				i += 1;
			}
		}
	}
}

static void OPC_InitTProcs (OPT_Object typ, OPT_Object obj)
{
	if (obj != NIL) {
		OPC_InitTProcs(typ, obj->left);
		if (obj->mode == 13) {
			OPC_BegStat();
			OPM_WriteString((CHAR*)"__INITBP(", (LONGINT)10);
			OPC_Ident(typ);
			OPM_WriteString((CHAR*)", ", (LONGINT)3);
			OPC_Ident(obj);
			OPC_Str1((CHAR*)", #)", (LONGINT)5, __ASHR(obj->adr, 16));
			OPC_EndStat();
		}
		OPC_InitTProcs(typ, obj->right);
	}
}

static void OPC_PutBase (OPT_Struct typ)
{
	if (typ != NIL) {
		OPC_PutBase(typ->BaseTyp);
		OPC_Ident(typ->strobj);
		OPM_WriteString((CHAR*)"__typ", (LONGINT)6);
		OPM_WriteString((CHAR*)", ", (LONGINT)3);
	}
}

static void OPC_LenList (OPT_Object par, BOOLEAN ansiDefine, BOOLEAN showParamName)
{
	OPT_Struct typ = NIL;
	INTEGER dim;
	if (showParamName) {
		OPC_Ident(par);
		OPM_WriteString((CHAR*)"__len", (LONGINT)6);
	}
	dim = 1;
	typ = par->typ->BaseTyp;
	while (typ->comp == 3) {
		if (ansiDefine) {
			OPM_WriteString((CHAR*)", LONGINT ", (LONGINT)11);
		} else {
			OPM_WriteString((CHAR*)", ", (LONGINT)3);
		}
		if (showParamName) {
			OPC_Ident(par);
			OPM_WriteString((CHAR*)"__len", (LONGINT)6);
			OPM_WriteInt(dim);
		}
		typ = typ->BaseTyp;
		dim += 1;
	}
}

static void OPC_DeclareParams (OPT_Object par, BOOLEAN macro)
{
	OPM_Write('(');
	while (par != NIL) {
		if (macro) {
			OPM_WriteStringVar((void*)par->name, ((LONGINT)(256)));
		} else {
			if ((par->mode == 1 && par->typ->form == 7)) {
				OPM_Write('_');
			}
			OPC_Ident(par);
		}
		if (par->typ->comp == 3) {
			OPM_WriteString((CHAR*)", ", (LONGINT)3);
			OPC_LenList(par, 0, 1);
		} else if ((par->mode == 2 && par->typ->comp == 4)) {
			OPM_WriteString((CHAR*)", ", (LONGINT)3);
			OPM_WriteStringVar((void*)par->name, ((LONGINT)(256)));
			OPM_WriteString((CHAR*)"__typ", (LONGINT)6);
		}
		par = par->link;
		if (par != NIL) {
			OPM_WriteString((CHAR*)", ", (LONGINT)3);
		}
	}
	OPM_Write(')');
}

static void OPC_DefineTProcTypes (OPT_Object obj)
{
	OPT_Object par = NIL;
	if (obj->typ != OPT_notyp) {
		OPC_DefineType(obj->typ);
	}
	if (OPC_ansi) {
		par = obj->link;
		while (par != NIL) {
			OPC_DefineType(par->typ);
			par = par->link;
		}
	}
}

static void OPC_DeclareTProcs (OPT_Object obj, BOOLEAN *empty)
{
	if (obj != NIL) {
		OPC_DeclareTProcs(obj->left, &*empty);
		if (obj->mode == 13) {
			if (obj->typ != OPT_notyp) {
				OPC_DefineType(obj->typ);
			}
			if (OPM_currFile == 0) {
				if (obj->vis == 1) {
					OPC_DefineTProcTypes(obj);
					OPM_WriteString((CHAR*)"import ", (LONGINT)8);
					*empty = 0;
					OPC_ProcHeader(obj, 0);
				}
			} else {
				*empty = 0;
				OPC_DefineTProcTypes(obj);
				if (obj->vis == 0) {
					OPM_WriteString((CHAR*)"static ", (LONGINT)8);
				} else {
					OPM_WriteString((CHAR*)"export ", (LONGINT)8);
				}
				OPC_ProcHeader(obj, 0);
			}
		}
		OPC_DeclareTProcs(obj->right, &*empty);
	}
}

OPT_Object OPC_BaseTProc (OPT_Object obj)
{
	OPT_Object _o_result;
	OPT_Struct typ = NIL, base = NIL;
	LONGINT mno;
	typ = obj->link->typ;
	if (typ->form == 13) {
		typ = typ->BaseTyp;
	}
	base = typ->BaseTyp;
	mno = __ASHR(obj->adr, 16);
	while ((base != NIL && mno < base->n)) {
		typ = base;
		base = typ->BaseTyp;
	}
	OPT_FindField(obj->name, typ, &obj);
	_o_result = obj;
	return _o_result;
}

static void OPC_DefineTProcMacros (OPT_Object obj, BOOLEAN *empty)
{
	if (obj != NIL) {
		OPC_DefineTProcMacros(obj->left, &*empty);
		if ((((obj->mode == 13 && obj == OPC_BaseTProc(obj))) && (OPM_currFile != 0 || obj->vis == 1))) {
			OPM_WriteString((CHAR*)"#define __", (LONGINT)11);
			OPC_Ident(obj);
			OPC_DeclareParams(obj->link, 1);
			OPM_WriteString((CHAR*)" __SEND(", (LONGINT)9);
			if (obj->link->typ->form == 13) {
				OPM_WriteString((CHAR*)"__TYPEOF(", (LONGINT)10);
				OPC_Ident(obj->link);
				OPM_Write(')');
			} else {
				OPC_Ident(obj->link);
				OPM_WriteString((CHAR*)"__typ", (LONGINT)6);
			}
			OPC_Str1((CHAR*)", #, ", (LONGINT)6, __ASHR(obj->adr, 16));
			if (obj->typ == OPT_notyp) {
				OPM_WriteString((CHAR*)"void", (LONGINT)5);
			} else {
				OPC_Ident(obj->typ->strobj);
			}
			OPM_WriteString((CHAR*)"(*)", (LONGINT)4);
			if (OPC_ansi) {
				OPC_AnsiParamList(obj->link, 0);
			} else {
				OPM_WriteString((CHAR*)"()", (LONGINT)3);
			}
			OPM_WriteString((CHAR*)", ", (LONGINT)3);
			OPC_DeclareParams(obj->link, 1);
			OPM_Write(')');
			OPM_WriteLn();
		}
		OPC_DefineTProcMacros(obj->right, &*empty);
	}
}

static void OPC_DefineType (OPT_Struct str)
{
	OPT_Object obj = NIL, field = NIL, par = NIL;
	BOOLEAN empty;
	if (OPM_currFile == 1 || str->ref < 255) {
		obj = str->strobj;
		if (obj == NIL || OPC_Undefined(obj)) {
			if (obj != NIL) {
				if (obj->linkadr == 1) {
					if (str->form != 13) {
						OPM_Mark(244, str->txtpos);
						obj->linkadr = 2;
					}
				} else {
					obj->linkadr = 1;
				}
			}
			if (str->comp == 4) {
				if (str->BaseTyp != NIL) {
					OPC_DefineType(str->BaseTyp);
				}
				field = str->link;
				while ((field != NIL && field->mode == 4)) {
					if (field->vis != 0 || OPM_currFile == 1) {
						OPC_DefineType(field->typ);
					}
					field = field->link;
				}
			} else if (str->form == 13) {
				if (str->BaseTyp->comp != 4) {
					OPC_DefineType(str->BaseTyp);
				}
			} else if (__IN(str->comp, 0x0c)) {
				OPC_DefineType(str->BaseTyp);
			} else if (str->form == 14) {
				if (str->BaseTyp != OPT_notyp) {
					OPC_DefineType(str->BaseTyp);
				}
				field = str->link;
				while (field != NIL) {
					OPC_DefineType(field->typ);
					field = field->link;
				}
			}
		}
		if ((obj != NIL && OPC_Undefined(obj))) {
			OPM_WriteString((CHAR*)"typedef", (LONGINT)8);
			OPM_WriteLn();
			OPM_Write(0x09);
			OPC_Indent(1);
			obj->linkadr = 1;
			OPC_DeclareBase(obj);
			OPM_Write(' ');
			obj->typ->strobj = NIL;
			OPC_DeclareObj(obj, 0);
			obj->typ->strobj = obj;
			obj->linkadr = 3 + OPM_currFile;
			OPC_EndStat();
			OPC_Indent(-1);
			OPM_WriteLn();
			if (obj->typ->comp == 4) {
				empty = 1;
				OPC_DeclareTProcs(str->link, &empty);
				OPC_DefineTProcMacros(str->link, &empty);
				if (!empty) {
					OPM_WriteLn();
				}
			}
		}
	}
}

static BOOLEAN OPC_Prefixed (OPT_ConstExt x, CHAR *y, LONGINT y__len)
{
	BOOLEAN _o_result;
	INTEGER i;
	BOOLEAN r;
	__DUP(y, y__len, CHAR);
	i = 0;
	while ((*x)[__X(i + 1, ((LONGINT)(256)))] == y[__X(i, y__len)]) {
		i += 1;
	}
	r = y[__X(i, y__len)] == 0x00;
	_o_result = r;
	__DEL(y);
	return _o_result;
}

static void OPC_CProcDefs (OPT_Object obj, INTEGER vis)
{
	INTEGER i;
	OPT_ConstExt ext = NIL;
	INTEGER _for__9;
	if (obj != NIL) {
		OPC_CProcDefs(obj->left, vis);
		if ((((obj->mode == 9 && (int)obj->vis >= vis)) && obj->adr == 1)) {
			ext = obj->conval->ext;
			i = 1;
			if (((*ext)[1] != '#' && !(OPC_Prefixed(ext, (CHAR*)"extern ", (LONGINT)8) || OPC_Prefixed(ext, (CHAR*)"import ", (LONGINT)8)))) {
				OPM_WriteString((CHAR*)"#define ", (LONGINT)9);
				OPC_Ident(obj);
				OPC_DeclareParams(obj->link, 1);
				OPM_Write(0x09);
			}
			_for__9 = (int)(*obj->conval->ext)[0];
			i = i;
			while (i <= _for__9) {
				OPM_Write((*obj->conval->ext)[__X(i, ((LONGINT)(256)))]);
				i += 1;
			}
			OPM_WriteLn();
		}
		OPC_CProcDefs(obj->right, vis);
	}
}

void OPC_TypeDefs (OPT_Object obj, INTEGER vis)
{
	if (obj != NIL) {
		OPC_TypeDefs(obj->left, vis);
		if ((obj->mode == 5 && obj->typ->txtpos > 0)) {
			OPC_DefineType(obj->typ);
		}
		OPC_TypeDefs(obj->right, vis);
	}
}

static void OPC_DefAnonRecs (OPT_Node n)
{
	OPT_Object o = NIL;
	OPT_Struct typ = NIL;
	while ((n != NIL && n->class == 14)) {
		typ = n->typ;
		if ((typ->strobj == NIL && (OPM_currFile == 1 || typ->ref < 255))) {
			OPC_DefineType(typ);
			__NEW(o, OPT_ObjDesc);
			o->typ = typ;
			o->name[0] = 0x00;
			OPC_DeclareBase(o);
			OPC_EndStat();
			OPM_WriteLn();
		}
		n = n->link;
	}
}

void OPC_TDescDecl (OPT_Struct typ)
{
	LONGINT nofptrs;
	OPT_Object o = NIL;
	OPC_BegStat();
	OPM_WriteString((CHAR*)"__TDESC(", (LONGINT)9);
	OPC_Andent(typ);
	OPC_Str1((CHAR*)", #", (LONGINT)4, typ->n + 1);
	OPC_Str1((CHAR*)", #) = {__TDFLDS(", (LONGINT)18, OPC_NofPtrs(typ));
	OPM_Write('\"');
	if (typ->strobj != NIL) {
		OPM_WriteStringVar((void*)typ->strobj->name, ((LONGINT)(256)));
	}
	OPC_Str1((CHAR*)"\", #), {", (LONGINT)9, typ->size);
	nofptrs = 0;
	OPC_PutPtrOffsets(typ, ((LONGINT)(0)), &nofptrs);
	OPC_Str1((CHAR*)"#}}", (LONGINT)4, -((nofptrs + 1) * (LONGINT)OPM_LIntSize));
	OPC_EndStat();
}

void OPC_InitTDesc (OPT_Struct typ)
{
	OPC_BegStat();
	OPM_WriteString((CHAR*)"__INITYP(", (LONGINT)10);
	OPC_Andent(typ);
	OPM_WriteString((CHAR*)", ", (LONGINT)3);
	if (typ->BaseTyp != NIL) {
		OPC_Andent(typ->BaseTyp);
	} else {
		OPC_Andent(typ);
	}
	OPC_Str1((CHAR*)", #)", (LONGINT)5, typ->extlev);
	OPC_EndStat();
	if (typ->strobj != NIL) {
		OPC_InitTProcs(typ->strobj, typ->link);
	}
}

void OPC_Align (LONGINT *adr, LONGINT base)
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

LONGINT OPC_Base (OPT_Struct typ)
{
	LONGINT _o_result;
	switch (typ->form) {
		case 1: 
			_o_result = 1;
			return _o_result;
			break;
		case 3: 
			_o_result = OPM_CharAlign;
			return _o_result;
			break;
		case 2: 
			_o_result = OPM_BoolAlign;
			return _o_result;
			break;
		case 4: 
			_o_result = OPM_SIntAlign;
			return _o_result;
			break;
		case 5: 
			_o_result = OPM_IntAlign;
			return _o_result;
			break;
		case 6: 
			_o_result = OPM_LIntAlign;
			return _o_result;
			break;
		case 7: 
			_o_result = OPM_RealAlign;
			return _o_result;
			break;
		case 8: 
			_o_result = OPM_LRealAlign;
			return _o_result;
			break;
		case 9: 
			_o_result = OPM_SetAlign;
			return _o_result;
			break;
		case 13: 
			_o_result = OPM_PointerAlign;
			return _o_result;
			break;
		case 14: 
			_o_result = OPM_ProcAlign;
			return _o_result;
			break;
		case 15: 
			if (typ->comp == 4) {
				_o_result = __MASK(typ->align, -65536);
				return _o_result;
			} else {
				_o_result = OPC_Base(typ->BaseTyp);
				return _o_result;
			}
			break;
		default: 
			OPM_LogWStr((CHAR*)"unhandled case in OPC.Base, typ^form = ", (LONGINT)40);
			OPM_LogWNum(typ->form, ((LONGINT)(0)));
			OPM_LogWLn();
			break;
	}
	__RETCHK;
}

static void OPC_FillGap (LONGINT gap, LONGINT off, LONGINT align, LONGINT *n, LONGINT *curAlign)
{
	LONGINT adr;
	adr = off;
	OPC_Align(&adr, align);
	if ((*curAlign < align && gap - (adr - off) >= align)) {
		gap -= (adr - off) + align;
		OPC_BegStat();
		if (align == (LONGINT)OPM_IntSize) {
			OPM_WriteString((CHAR*)"INTEGER", (LONGINT)8);
		} else if (align == (LONGINT)OPM_LIntSize) {
			OPM_WriteString((CHAR*)"LONGINT", (LONGINT)8);
		} else if (align == (LONGINT)OPM_LRealSize) {
			OPM_WriteString((CHAR*)"LONGREAL", (LONGINT)9);
		}
		OPC_Str1((CHAR*)" _prvt#", (LONGINT)8, *n);
		*n += 1;
		OPC_EndStat();
		*curAlign = align;
	}
	if (gap > 0) {
		OPC_BegStat();
		OPC_Str1((CHAR*)"char _prvt#", (LONGINT)12, *n);
		*n += 1;
		OPC_Str1((CHAR*)"[#]", (LONGINT)4, gap);
		OPC_EndStat();
	}
}

static void OPC_FieldList (OPT_Struct typ, BOOLEAN last, LONGINT *off, LONGINT *n, LONGINT *curAlign)
{
	OPT_Object fld = NIL;
	OPT_Struct base = NIL;
	LONGINT gap, adr, align, fldAlign;
	fld = typ->link;
	align = __MASK(typ->align, -65536);
	if (typ->BaseTyp != NIL) {
		OPC_FieldList(typ->BaseTyp, 0, &*off, &*n, &*curAlign);
	} else {
		*off = 0;
		*n = 0;
		*curAlign = 1;
	}
	while ((fld != NIL && fld->mode == 4)) {
		if ((OPM_currFile == 0 && fld->vis == 0) || (((OPM_currFile == 1 && fld->vis == 0)) && typ->mno != 0)) {
			fld = fld->link;
			while ((((fld != NIL && fld->mode == 4)) && fld->vis == 0)) {
				fld = fld->link;
			}
		} else {
			adr = *off;
			fldAlign = OPC_Base(fld->typ);
			OPC_Align(&adr, fldAlign);
			gap = fld->adr - adr;
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
			*off = fld->adr + fld->typ->size;
			base = fld->typ;
			fld = fld->link;
			while ((((((((fld != NIL && fld->mode == 4)) && fld->typ == base)) && fld->adr == *off)) && ((OPM_currFile == 1 || fld->vis != 0) || fld->typ->strobj == NIL))) {
				OPM_WriteString((CHAR*)", ", (LONGINT)3);
				OPC_DeclareObj(fld, 0);
				*off = fld->adr + fld->typ->size;
				fld = fld->link;
			}
			OPC_EndStat();
		}
	}
	if (last) {
		adr = typ->size - (LONGINT)__ASHR(typ->sysflag, 8);
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

static void OPC_IdentList (OPT_Object obj, INTEGER vis)
{
	OPT_Struct base = NIL;
	BOOLEAN first;
	INTEGER lastvis;
	base = NIL;
	first = 1;
	while ((obj != NIL && obj->mode != 13)) {
		if ((__IN(vis, 0x05) || (vis == 1 && obj->vis != 0)) || (vis == 3 && !obj->leaf)) {
			if (obj->typ != base || (int)obj->vis != lastvis) {
				if (!first) {
					OPC_EndStat();
				}
				first = 0;
				base = obj->typ;
				lastvis = obj->vis;
				OPC_BegStat();
				if ((vis == 1 && obj->vis != 0)) {
					OPM_WriteString((CHAR*)"import ", (LONGINT)8);
				} else if ((obj->mnolev == 0 && vis == 0)) {
					if (obj->vis == 0) {
						OPM_WriteString((CHAR*)"static ", (LONGINT)8);
					} else {
						OPM_WriteString((CHAR*)"export ", (LONGINT)8);
					}
				}
				if ((((vis == 2 && obj->mode == 1)) && base->form == 7)) {
					OPM_WriteString((CHAR*)"double", (LONGINT)7);
				} else {
					OPC_DeclareBase(obj);
				}
			} else {
				OPM_Write(',');
			}
			OPM_Write(' ');
			if ((((vis == 2 && obj->mode == 1)) && base->form == 7)) {
				OPM_Write('_');
			}
			OPC_DeclareObj(obj, vis == 3);
			if (obj->typ->comp == 3) {
				OPC_EndStat();
				OPC_BegStat();
				base = OPT_linttyp;
				OPM_WriteString((CHAR*)"LONGINT ", (LONGINT)9);
				OPC_LenList(obj, 0, 1);
			} else if ((obj->mode == 2 && obj->typ->comp == 4)) {
				OPC_EndStat();
				OPC_BegStat();
				OPM_WriteString((CHAR*)"LONGINT *", (LONGINT)10);
				OPC_Ident(obj);
				OPM_WriteString((CHAR*)"__typ", (LONGINT)6);
				base = NIL;
			} else if ((((((OPC_ptrinit && vis == 0)) && obj->mnolev > 0)) && obj->typ->form == 13)) {
				OPM_WriteString((CHAR*)" = NIL", (LONGINT)7);
			}
		}
		obj = obj->link;
	}
	if (!first) {
		OPC_EndStat();
	}
}

static void OPC_AnsiParamList (OPT_Object obj, BOOLEAN showParamNames)
{
	CHAR name[32];
	OPM_Write('(');
	if (obj == NIL || obj->mode == 13) {
		OPM_WriteString((CHAR*)"void", (LONGINT)5);
	} else {
		for (;;) {
			OPC_DeclareBase(obj);
			if (showParamNames) {
				OPM_Write(' ');
				OPC_DeclareObj(obj, 0);
			} else {
				__COPY(obj->name, name, ((LONGINT)(32)));
				obj->name[0] = 0x00;
				OPC_DeclareObj(obj, 0);
				__COPY(name, obj->name, ((LONGINT)(256)));
			}
			if (obj->typ->comp == 3) {
				OPM_WriteString((CHAR*)", LONGINT ", (LONGINT)11);
				OPC_LenList(obj, 1, showParamNames);
			} else if ((obj->mode == 2 && obj->typ->comp == 4)) {
				OPM_WriteString((CHAR*)", LONGINT *", (LONGINT)12);
				if (showParamNames) {
					OPC_Ident(obj);
					OPM_WriteString((CHAR*)"__typ", (LONGINT)6);
				}
			}
			if (obj->link == NIL || obj->link->mode == 13) {
				break;
			}
			OPM_WriteString((CHAR*)", ", (LONGINT)3);
			obj = obj->link;
		}
	}
	OPM_Write(')');
}

static void OPC_ProcHeader (OPT_Object proc, BOOLEAN define)
{
	if (proc->typ == OPT_notyp) {
		OPM_WriteString((CHAR*)"void", (LONGINT)5);
	} else {
		OPC_Ident(proc->typ->strobj);
	}
	OPM_Write(' ');
	OPC_Ident(proc);
	OPM_Write(' ');
	if (OPC_ansi) {
		OPC_AnsiParamList(proc->link, 1);
		if (!define) {
			OPM_Write(';');
		}
		OPM_WriteLn();
	} else if (define) {
		OPC_DeclareParams(proc->link, 0);
		OPM_WriteLn();
		OPC_Indent(1);
		OPC_IdentList(proc->link, 2);
		OPC_Indent(-1);
	} else {
		OPM_WriteString((CHAR*)"();", (LONGINT)4);
		OPM_WriteLn();
	}
}

static void OPC_ProcPredefs (OPT_Object obj, SHORTINT vis)
{
	if (obj != NIL) {
		OPC_ProcPredefs(obj->left, vis);
		if ((((__IN(obj->mode, 0xc0) && obj->vis >= vis)) && (obj->history != 4 || obj->mode == 6))) {
			if (vis == 1) {
				OPM_WriteString((CHAR*)"import ", (LONGINT)8);
			} else if (obj->vis == 0) {
				OPM_WriteString((CHAR*)"static ", (LONGINT)8);
			} else {
				OPM_WriteString((CHAR*)"export ", (LONGINT)8);
			}
			OPC_ProcHeader(obj, 0);
		}
		OPC_ProcPredefs(obj->right, vis);
	}
}

static void OPC_Include (CHAR *name, LONGINT name__len)
{
	__DUP(name, name__len, CHAR);
	OPM_WriteString((CHAR*)"#include ", (LONGINT)10);
	OPM_Write('\"');
	OPM_WriteStringVar((void*)name, name__len);
	OPM_WriteString((CHAR*)".h", (LONGINT)3);
	OPM_Write('\"');
	OPM_WriteLn();
	__DEL(name);
}

static void OPC_IncludeImports (OPT_Object obj, INTEGER vis)
{
	if (obj != NIL) {
		OPC_IncludeImports(obj->left, vis);
		if ((((obj->mode == 11 && obj->mnolev != 0)) && (int)OPT_GlbMod[__X(-obj->mnolev, ((LONGINT)(64)))]->vis >= vis)) {
			OPC_Include(OPT_GlbMod[__X(-obj->mnolev, ((LONGINT)(64)))]->name, ((LONGINT)(256)));
		}
		OPC_IncludeImports(obj->right, vis);
	}
}

static void OPC_GenDynTypes (OPT_Node n, INTEGER vis)
{
	OPT_Struct typ = NIL;
	while ((n != NIL && n->class == 14)) {
		typ = n->typ;
		if (vis == 0 || typ->ref < 255) {
			OPC_BegStat();
			if (vis == 1) {
				OPM_WriteString((CHAR*)"import ", (LONGINT)8);
			} else if ((typ->strobj != NIL && typ->strobj->mnolev > 0)) {
				OPM_WriteString((CHAR*)"static ", (LONGINT)8);
			} else {
				OPM_WriteString((CHAR*)"export ", (LONGINT)8);
			}
			OPM_WriteString((CHAR*)"LONGINT *", (LONGINT)10);
			OPC_Andent(typ);
			OPM_WriteString((CHAR*)"__typ", (LONGINT)6);
			OPC_EndStat();
		}
		n = n->link;
	}
}

void OPC_GenHdr (OPT_Node n)
{
	OPM_currFile = 0;
	OPC_DefAnonRecs(n);
	OPC_TypeDefs(OPT_topScope->right, 1);
	OPM_WriteLn();
	OPC_IdentList(OPT_topScope->scope, 1);
	OPM_WriteLn();
	OPC_GenDynTypes(n, 1);
	OPM_WriteLn();
	OPC_ProcPredefs(OPT_topScope->right, 1);
	OPM_WriteString((CHAR*)"import ", (LONGINT)8);
	OPM_WriteString((CHAR*)"void *", (LONGINT)7);
	OPM_WriteStringVar((void*)OPM_modName, ((LONGINT)(32)));
	OPM_WriteString(OPC_BodyNameExt, ((LONGINT)(13)));
	OPC_EndStat();
	OPM_WriteLn();
	OPC_CProcDefs(OPT_topScope->right, 1);
	OPM_WriteLn();
	OPM_WriteString((CHAR*)"#endif", (LONGINT)7);
	OPM_WriteLn();
}

static void OPC_GenHeaderMsg (void)
{
	INTEGER i;
	OPM_WriteString((CHAR*)"/*", (LONGINT)3);
	OPM_WriteString((CHAR*)" voc ", (LONGINT)6);
	OPM_Write(' ');
	OPM_WriteString((CHAR*)"1.95 [2016/06/30] for gcc LP64 on cygwin", (LONGINT)41);
	OPM_Write(' ');
	i = 0;
	while (i <= 63) {
		if (__IN(i, OPM_glbopt)) {
			switch (i) {
				case 0: 
					OPM_Write('x');
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
				case 6: 
					OPM_Write('k');
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
				default: 
					OPM_LogWStr((CHAR*)"( more options defined in OPM than checked in OPC.GenHeaderMsg, if you are a compiler developer, add them to OPC.GenHeaderMsg", (LONGINT)126);
					OPM_LogWLn();
					break;
			}
		}
		i += 1;
	}
	OPM_WriteString((CHAR*)" */", (LONGINT)4);
	OPM_WriteLn();
}

void OPC_GenHdrIncludes (void)
{
	OPM_currFile = 2;
	OPC_GenHeaderMsg();
	OPM_WriteLn();
	OPM_WriteString((CHAR*)"#ifndef ", (LONGINT)9);
	OPM_WriteStringVar((void*)OPM_modName, ((LONGINT)(32)));
	OPM_WriteString((CHAR*)"__h", (LONGINT)4);
	OPM_WriteLn();
	OPM_WriteString((CHAR*)"#define ", (LONGINT)9);
	OPM_WriteStringVar((void*)OPM_modName, ((LONGINT)(32)));
	OPM_WriteString((CHAR*)"__h", (LONGINT)4);
	OPM_WriteLn();
	OPM_WriteLn();
	if (OPM_LIntSize == 8) {
		OPM_WriteString((CHAR*)"#define LARGE", (LONGINT)14);
		OPM_WriteLn();
	}
	OPC_Include((CHAR*)"SYSTEM", (LONGINT)7);
	OPC_IncludeImports(OPT_topScope->right, 1);
	OPM_WriteLn();
}

void OPC_GenBdy (OPT_Node n)
{
	OPM_currFile = 1;
	OPC_GenHeaderMsg();
	if (OPM_LIntSize == 8) {
		OPM_WriteString((CHAR*)"#define LARGE", (LONGINT)14);
		OPM_WriteLn();
	}
	OPC_Include((CHAR*)"SYSTEM", (LONGINT)7);
	OPC_IncludeImports(OPT_topScope->right, 0);
	OPM_WriteLn();
	OPC_DefAnonRecs(n);
	OPC_TypeDefs(OPT_topScope->right, 0);
	OPM_WriteLn();
	OPC_IdentList(OPT_topScope->scope, 0);
	OPM_WriteLn();
	OPC_GenDynTypes(n, 0);
	OPM_WriteLn();
	OPC_ProcPredefs(OPT_topScope->right, 0);
	OPM_WriteLn();
	OPC_CProcDefs(OPT_topScope->right, 0);
	OPM_WriteLn();
}

static void OPC_RegCmds (OPT_Object obj)
{
	if (obj != NIL) {
		OPC_RegCmds(obj->left);
		if ((obj->mode == 7 && obj->history != 4)) {
			if ((((obj->vis != 0 && obj->link == NIL)) && obj->typ == OPT_notyp)) {
				OPC_BegStat();
				OPM_WriteString((CHAR*)"__REGCMD(\"", (LONGINT)11);
				OPM_WriteStringVar((void*)obj->name, ((LONGINT)(256)));
				OPM_WriteString((CHAR*)"\", ", (LONGINT)4);
				OPC_Ident(obj);
				OPM_Write(')');
				OPC_EndStat();
			}
		}
		OPC_RegCmds(obj->right);
	}
}

static void OPC_InitImports (OPT_Object obj)
{
	if (obj != NIL) {
		OPC_InitImports(obj->left);
		if ((obj->mode == 11 && obj->mnolev != 0)) {
			OPC_BegStat();
			OPM_WriteString((CHAR*)"__MODULE_IMPORT(", (LONGINT)17);
			OPM_WriteStringVar((void*)OPT_GlbMod[__X(-obj->mnolev, ((LONGINT)(64)))]->name, ((LONGINT)(256)));
			OPM_Write(')');
			OPC_EndStat();
		}
		OPC_InitImports(obj->right);
	}
}

void OPC_GenEnumPtrs (OPT_Object var)
{
	OPT_Struct typ = NIL;
	LONGINT n;
	OPC_GlbPtrs = 0;
	while (var != NIL) {
		typ = var->typ;
		if (OPC_NofPtrs(typ) > 0) {
			if (!OPC_GlbPtrs) {
				OPC_GlbPtrs = 1;
				OPM_WriteString((CHAR*)"static ", (LONGINT)8);
				if (OPC_ansi) {
					OPM_WriteString((CHAR*)"void EnumPtrs(void (*P)(void*))", (LONGINT)32);
				} else {
					OPM_WriteString((CHAR*)"void EnumPtrs(P)", (LONGINT)17);
					OPM_WriteLn();
					OPM_Write(0x09);
					OPM_WriteString((CHAR*)"void (*P)();", (LONGINT)13);
				}
				OPM_WriteLn();
				OPC_BegBlk();
			}
			OPC_BegStat();
			if (typ->form == 13) {
				OPM_WriteString((CHAR*)"P(", (LONGINT)3);
				OPC_Ident(var);
				OPM_Write(')');
			} else if (typ->comp == 4) {
				OPM_WriteString((CHAR*)"__ENUMR(&", (LONGINT)10);
				OPC_Ident(var);
				OPM_WriteString((CHAR*)", ", (LONGINT)3);
				OPC_Andent(typ);
				OPM_WriteString((CHAR*)"__typ", (LONGINT)6);
				OPC_Str1((CHAR*)", #", (LONGINT)4, typ->size);
				OPM_WriteString((CHAR*)", 1, P)", (LONGINT)8);
			} else if (typ->comp == 2) {
				n = typ->n;
				typ = typ->BaseTyp;
				while (typ->comp == 2) {
					n = n * typ->n;
					typ = typ->BaseTyp;
				}
				if (typ->form == 13) {
					OPM_WriteString((CHAR*)"__ENUMP(", (LONGINT)9);
					OPC_Ident(var);
					OPC_Str1((CHAR*)", #, P)", (LONGINT)8, n);
				} else if (typ->comp == 4) {
					OPM_WriteString((CHAR*)"__ENUMR(", (LONGINT)9);
					OPC_Ident(var);
					OPM_WriteString((CHAR*)", ", (LONGINT)3);
					OPC_Andent(typ);
					OPM_WriteString((CHAR*)"__typ", (LONGINT)6);
					OPC_Str1((CHAR*)", #", (LONGINT)4, typ->size);
					OPC_Str1((CHAR*)", #, P)", (LONGINT)8, n);
				}
			}
			OPC_EndStat();
		}
		var = var->link;
	}
	if (OPC_GlbPtrs) {
		OPC_EndBlk();
		OPM_WriteLn();
	}
}

void OPC_EnterBody (void)
{
	OPM_WriteLn();
	OPM_WriteString((CHAR*)"export ", (LONGINT)8);
	if (OPC_mainprog) {
		if (OPC_ansi) {
			OPM_WriteString((CHAR*)"int main(int argc, char **argv)", (LONGINT)32);
			OPM_WriteLn();
		} else {
			OPM_WriteString((CHAR*)"main(argc, argv)", (LONGINT)17);
			OPM_WriteLn();
			OPM_Write(0x09);
			OPM_WriteString((CHAR*)"int argc; char **argv;", (LONGINT)23);
			OPM_WriteLn();
		}
	} else {
		OPM_WriteString((CHAR*)"void *", (LONGINT)7);
		OPM_WriteString(OPM_modName, ((LONGINT)(32)));
		OPM_WriteString(OPC_BodyNameExt, ((LONGINT)(13)));
		OPM_WriteLn();
	}
	OPC_BegBlk();
	OPC_BegStat();
	if (OPC_mainprog) {
		OPM_WriteString((CHAR*)"__INIT(argc, argv)", (LONGINT)19);
	} else {
		OPM_WriteString((CHAR*)"__DEFMOD", (LONGINT)9);
	}
	OPC_EndStat();
	if ((OPC_mainprog && 0)) {
		OPC_BegStat();
		OPM_WriteString((CHAR*)"/*don`t do it!*/ printf(\"DEMO VERSION: DO NOT USE THIS PROGRAM FOR ANY COMMERCIAL PURPOSE\\n\")", (LONGINT)94);
		OPC_EndStat();
	}
	OPC_InitImports(OPT_topScope->right);
	OPC_BegStat();
	if (OPC_mainprog) {
		OPM_WriteString((CHAR*)"__REGMAIN(\"", (LONGINT)12);
	} else {
		OPM_WriteString((CHAR*)"__REGMOD(\"", (LONGINT)11);
	}
	OPM_WriteString(OPM_modName, ((LONGINT)(32)));
	if (OPC_GlbPtrs) {
		OPM_WriteString((CHAR*)"\", EnumPtrs)", (LONGINT)13);
	} else {
		OPM_WriteString((CHAR*)"\", 0)", (LONGINT)6);
	}
	OPC_EndStat();
	if (__STRCMP(OPM_modName, "SYSTEM") != 0) {
		OPC_RegCmds(OPT_topScope);
	}
}

void OPC_ExitBody (void)
{
	OPC_BegStat();
	if (OPC_mainprog) {
		OPM_WriteString((CHAR*)"__FINI;", (LONGINT)8);
	} else {
		OPM_WriteString((CHAR*)"__ENDMOD;", (LONGINT)10);
	}
	OPM_WriteLn();
	OPC_EndBlk();
}

void OPC_DefineInter (OPT_Object proc)
{
	OPT_Object scope = NIL;
	scope = proc->scope;
	OPM_WriteString((CHAR*)"static ", (LONGINT)8);
	OPM_WriteString((CHAR*)"struct ", (LONGINT)8);
	OPM_WriteStringVar((void*)scope->name, ((LONGINT)(256)));
	OPM_Write(' ');
	OPC_BegBlk();
	OPC_IdentList(proc->link, 3);
	OPC_IdentList(scope->scope, 3);
	OPC_BegStat();
	OPM_WriteString((CHAR*)"struct ", (LONGINT)8);
	OPM_WriteStringVar((void*)scope->name, ((LONGINT)(256)));
	OPM_Write(' ');
	OPM_Write('*');
	OPM_WriteString((CHAR*)"lnk", (LONGINT)4);
	OPC_EndStat();
	OPC_EndBlk0();
	OPM_Write(' ');
	OPM_Write('*');
	OPM_WriteStringVar((void*)scope->name, ((LONGINT)(256)));
	OPM_WriteString((CHAR*)"_s", (LONGINT)3);
	OPC_EndStat();
	OPM_WriteLn();
	OPC_ProcPredefs(scope->right, 0);
	OPM_WriteLn();
}

void OPC_EnterProc (OPT_Object proc)
{
	OPT_Object var = NIL, scope = NIL;
	OPT_Struct typ = NIL;
	INTEGER dim;
	if (proc->vis != 1) {
		OPM_WriteString((CHAR*)"static ", (LONGINT)8);
	}
	OPC_ProcHeader(proc, 1);
	OPC_BegBlk();
	if (proc->typ != OPT_notyp) {
		OPC_BegStat();
		OPC_Ident(proc->typ->strobj);
		OPM_WriteString((CHAR*)" _o_result;", (LONGINT)12);
		OPM_WriteLn();
	}
	scope = proc->scope;
	OPC_IdentList(scope->scope, 0);
	if (!scope->leaf) {
		OPC_BegStat();
		OPM_WriteString((CHAR*)"struct ", (LONGINT)8);
		OPM_WriteStringVar((void*)scope->name, ((LONGINT)(256)));
		OPM_Write(' ');
		OPM_WriteString((CHAR*)"_s", (LONGINT)3);
		OPC_EndStat();
	}
	var = proc->link;
	while (var != NIL) {
		if ((var->typ->comp == 2 && var->mode == 1)) {
			OPC_BegStat();
			if (var->typ->strobj == NIL) {
				OPM_Mark(200, var->typ->txtpos);
			} else {
				OPC_Ident(var->typ->strobj);
			}
			OPM_Write(' ');
			OPC_Ident(var);
			OPM_WriteString((CHAR*)"__copy", (LONGINT)7);
			OPC_EndStat();
		}
		var = var->link;
	}
	if (!OPC_ansi) {
		var = proc->link;
		while (var != NIL) {
			if ((var->typ->form == 7 && var->mode == 1)) {
				OPC_BegStat();
				OPC_Ident(var->typ->strobj);
				OPM_Write(' ');
				OPC_Ident(var);
				OPM_WriteString((CHAR*)" = _", (LONGINT)5);
				OPC_Ident(var);
				OPC_EndStat();
			}
			var = var->link;
		}
	}
	var = proc->link;
	while (var != NIL) {
		if ((((__IN(var->typ->comp, 0x0c) && var->mode == 1)) && var->typ->sysflag == 0)) {
			OPC_BegStat();
			if (var->typ->comp == 2) {
				OPM_WriteString((CHAR*)"__DUPARR(", (LONGINT)10);
				OPC_Ident(var);
				OPM_WriteString((CHAR*)", ", (LONGINT)3);
				if (var->typ->strobj == NIL) {
					OPM_Mark(200, var->typ->txtpos);
				} else {
					OPC_Ident(var->typ->strobj);
				}
			} else {
				OPM_WriteString((CHAR*)"__DUP(", (LONGINT)7);
				OPC_Ident(var);
				OPM_WriteString((CHAR*)", ", (LONGINT)3);
				OPC_Ident(var);
				OPM_WriteString((CHAR*)"__len", (LONGINT)6);
				typ = var->typ->BaseTyp;
				dim = 1;
				while (typ->comp == 3) {
					OPM_WriteString((CHAR*)" * ", (LONGINT)4);
					OPC_Ident(var);
					OPM_WriteString((CHAR*)"__len", (LONGINT)6);
					OPM_WriteInt(dim);
					typ = typ->BaseTyp;
					dim += 1;
				}
				OPM_WriteString((CHAR*)", ", (LONGINT)3);
				if (typ->strobj == NIL) {
					OPM_Mark(200, typ->txtpos);
				} else {
					OPC_Ident(typ->strobj);
				}
			}
			OPM_Write(')');
			OPC_EndStat();
		}
		var = var->link;
	}
	if (!scope->leaf) {
		var = proc->link;
		while (var != NIL) {
			if (!var->leaf) {
				OPC_BegStat();
				OPM_WriteString((CHAR*)"_s", (LONGINT)3);
				OPM_Write('.');
				OPC_Ident(var);
				OPM_WriteString((CHAR*)" = ", (LONGINT)4);
				if (__IN(var->typ->comp, 0x0c)) {
					OPM_WriteString((CHAR*)"(void*)", (LONGINT)8);
				} else if (var->mode != 2) {
					OPM_Write('&');
				}
				OPC_Ident(var);
				if (var->typ->comp == 3) {
					typ = var->typ;
					dim = 0;
					do {
						OPM_WriteString((CHAR*)"; ", (LONGINT)3);
						OPM_WriteString((CHAR*)"_s", (LONGINT)3);
						OPM_Write('.');
						OPC_Ident(var);
						OPM_WriteString((CHAR*)"__len", (LONGINT)6);
						if (dim != 0) {
							OPM_WriteInt(dim);
						}
						OPM_WriteString((CHAR*)" = ", (LONGINT)4);
						OPC_Ident(var);
						OPM_WriteString((CHAR*)"__len", (LONGINT)6);
						if (dim != 0) {
							OPM_WriteInt(dim);
						}
						typ = typ->BaseTyp;
					} while (!(typ->comp != 3));
				} else if ((var->mode == 2 && var->typ->comp == 4)) {
					OPM_WriteString((CHAR*)"; ", (LONGINT)3);
					OPM_WriteString((CHAR*)"_s", (LONGINT)3);
					OPM_Write('.');
					OPC_Ident(var);
					OPM_WriteString((CHAR*)"__typ", (LONGINT)6);
					OPM_WriteString((CHAR*)" = ", (LONGINT)4);
					OPC_Ident(var);
					OPM_WriteString((CHAR*)"__typ", (LONGINT)6);
				}
				OPC_EndStat();
			}
			var = var->link;
		}
		var = scope->scope;
		while (var != NIL) {
			if (!var->leaf) {
				OPC_BegStat();
				OPM_WriteString((CHAR*)"_s", (LONGINT)3);
				OPM_Write('.');
				OPC_Ident(var);
				OPM_WriteString((CHAR*)" = ", (LONGINT)4);
				if (var->typ->comp != 2) {
					OPM_Write('&');
				} else {
					OPM_WriteString((CHAR*)"(void*)", (LONGINT)8);
				}
				OPC_Ident(var);
				OPC_EndStat();
			}
			var = var->link;
		}
		OPC_BegStat();
		OPM_WriteString((CHAR*)"_s", (LONGINT)3);
		OPM_Write('.');
		OPM_WriteString((CHAR*)"lnk", (LONGINT)4);
		OPM_WriteString((CHAR*)" = ", (LONGINT)4);
		OPM_WriteStringVar((void*)scope->name, ((LONGINT)(256)));
		OPM_WriteString((CHAR*)"_s", (LONGINT)3);
		OPC_EndStat();
		OPC_BegStat();
		OPM_WriteStringVar((void*)scope->name, ((LONGINT)(256)));
		OPM_WriteString((CHAR*)"_s", (LONGINT)3);
		OPM_WriteString((CHAR*)" = ", (LONGINT)4);
		OPM_Write('&');
		OPM_WriteString((CHAR*)"_s", (LONGINT)3);
		OPC_EndStat();
	}
}

void OPC_ExitProc (OPT_Object proc, BOOLEAN eoBlock, BOOLEAN implicitRet)
{
	OPT_Object var = NIL;
	BOOLEAN indent;
	indent = eoBlock;
	if ((implicitRet && proc->typ != OPT_notyp)) {
		OPM_Write(0x09);
		OPM_WriteString((CHAR*)"__RETCHK;", (LONGINT)10);
		OPM_WriteLn();
	} else if (!eoBlock || implicitRet) {
		if (!proc->scope->leaf) {
			if (indent) {
				OPC_BegStat();
			} else {
				indent = 1;
			}
			OPM_WriteStringVar((void*)proc->scope->name, ((LONGINT)(256)));
			OPM_WriteString((CHAR*)"_s", (LONGINT)3);
			OPM_WriteString((CHAR*)" = ", (LONGINT)4);
			OPM_WriteString((CHAR*)"_s", (LONGINT)3);
			OPM_Write('.');
			OPM_WriteString((CHAR*)"lnk", (LONGINT)4);
			OPC_EndStat();
		}
		var = proc->link;
		while (var != NIL) {
			if ((((var->typ->comp == 3 && var->mode == 1)) && var->typ->sysflag == 0)) {
				if (indent) {
					OPC_BegStat();
				} else {
					indent = 1;
				}
				OPM_WriteString((CHAR*)"__DEL(", (LONGINT)7);
				OPC_Ident(var);
				OPM_Write(')');
				OPC_EndStat();
			}
			var = var->link;
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
	INTEGER comp, level;
	level = obj->mnolev;
	if (obj->adr == 1) {
		if (obj->typ->comp == 4) {
			OPC_Ident(obj);
			OPM_WriteString((CHAR*)"__", (LONGINT)3);
		} else {
			OPM_WriteString((CHAR*)"((", (LONGINT)3);
			OPC_Ident(obj->typ->strobj);
			OPM_Write(')');
			OPC_Ident(obj);
			OPM_Write(')');
		}
	} else if ((level != OPM_level && level > 0)) {
		comp = obj->typ->comp;
		if ((obj->mode != 2 && comp != 3)) {
			OPM_Write('*');
		}
		OPM_WriteStringVar((void*)obj->scope->name, ((LONGINT)(256)));
		OPM_WriteString((CHAR*)"_s", (LONGINT)3);
		OPM_WriteString((CHAR*)"->", (LONGINT)3);
		OPC_Ident(obj);
	} else {
		OPC_Ident(obj);
	}
}

void OPC_TypeOf (OPT_Object ap)
{
	INTEGER i;
	__ASSERT(ap->typ->comp == 4, 0);
	if (ap->mode == 2) {
		if ((int)ap->mnolev != OPM_level) {
			OPM_WriteStringVar((void*)ap->scope->name, ((LONGINT)(256)));
			OPM_WriteString((CHAR*)"_s->", (LONGINT)5);
			OPC_Ident(ap);
		} else {
			OPC_Ident(ap);
		}
		OPM_WriteString((CHAR*)"__typ", (LONGINT)6);
	} else if (ap->typ->strobj != NIL) {
		OPC_Ident(ap->typ->strobj);
		OPM_WriteString((CHAR*)"__typ", (LONGINT)6);
	} else {
		OPC_Andent(ap->typ);
	}
}

void OPC_Cmp (INTEGER rel)
{
	switch (rel) {
		case 9: 
			OPM_WriteString((CHAR*)" == ", (LONGINT)5);
			break;
		case 10: 
			OPM_WriteString((CHAR*)" != ", (LONGINT)5);
			break;
		case 11: 
			OPM_WriteString((CHAR*)" < ", (LONGINT)4);
			break;
		case 12: 
			OPM_WriteString((CHAR*)" <= ", (LONGINT)5);
			break;
		case 13: 
			OPM_WriteString((CHAR*)" > ", (LONGINT)4);
			break;
		case 14: 
			OPM_WriteString((CHAR*)" >= ", (LONGINT)5);
			break;
		default: 
			OPM_LogWStr((CHAR*)"unhandled case in OPC.Cmp, rel = ", (LONGINT)34);
			OPM_LogWNum(rel, ((LONGINT)(0)));
			OPM_LogWLn();
			break;
	}
}

void OPC_Case (LONGINT caseVal, INTEGER form)
{
	CHAR ch;
	OPM_WriteString((CHAR*)"case ", (LONGINT)6);
	switch (form) {
		case 3: 
			ch = (CHAR)caseVal;
			if ((ch >= ' ' && ch <= '~')) {
				OPM_Write('\'');
				if (((ch == '\\' || ch == '\?') || ch == '\'') || ch == '\"') {
					OPM_Write('\\');
					OPM_Write(ch);
				} else {
					OPM_Write(ch);
				}
				OPM_Write('\'');
			} else {
				OPM_WriteString((CHAR*)"0x", (LONGINT)3);
				OPM_WriteHex(caseVal);
			}
			break;
		case 4: case 5: case 6: 
			OPM_WriteInt(caseVal);
			break;
		default: 
			OPM_LogWStr((CHAR*)"unhandled case in OPC.Case, form = ", (LONGINT)36);
			OPM_LogWNum(form, ((LONGINT)(0)));
			OPM_LogWLn();
			break;
	}
	OPM_WriteString((CHAR*)": ", (LONGINT)3);
}

void OPC_SetInclude (BOOLEAN exclude)
{
	if (exclude) {
		OPM_WriteString((CHAR*)" &= ~", (LONGINT)6);
	} else {
		OPM_WriteString((CHAR*)" |= ", (LONGINT)5);
	}
}

void OPC_Increment (BOOLEAN decrement)
{
	if (decrement) {
		OPM_WriteString((CHAR*)" -= ", (LONGINT)5);
	} else {
		OPM_WriteString((CHAR*)" += ", (LONGINT)5);
	}
}

void OPC_Halt (LONGINT n)
{
	OPC_Str1((CHAR*)"__HALT(#)", (LONGINT)10, n);
}

void OPC_Len (OPT_Object obj, OPT_Struct array, LONGINT dim)
{
	if (array->comp == 3) {
		OPC_CompleteIdent(obj);
		OPM_WriteString((CHAR*)"__len", (LONGINT)6);
		if (dim != 0) {
			OPM_WriteInt(dim);
		}
	} else {
		while (dim > 0) {
			array = array->BaseTyp;
			dim -= 1;
		}
		OPM_WriteString((CHAR*)"((LONGINT)(", (LONGINT)12);
		OPM_WriteInt(array->n);
		OPM_WriteString((CHAR*)"))", (LONGINT)3);
	}
}

void OPC_Constant (OPT_Const con, INTEGER form)
{
	INTEGER i, len;
	CHAR ch;
	SET s;
	LONGINT hex;
	BOOLEAN skipLeading;
	switch (form) {
		case 1: 
			OPM_WriteInt(con->intval);
			break;
		case 2: 
			OPM_WriteInt(con->intval);
			break;
		case 3: 
			ch = (CHAR)con->intval;
			if ((ch >= ' ' && ch <= '~')) {
				OPM_Write('\'');
				if (((ch == '\\' || ch == '\?') || ch == '\'') || ch == '\"') {
					OPM_Write('\\');
				}
				OPM_Write(ch);
				OPM_Write('\'');
			} else {
				OPM_WriteString((CHAR*)"0x", (LONGINT)3);
				OPM_WriteHex(con->intval);
			}
			break;
		case 4: case 5: case 6: 
			OPM_WriteInt(con->intval);
			break;
		case 7: 
			OPM_WriteReal(con->realval, 'f');
			break;
		case 8: 
			OPM_WriteReal(con->realval, 0x00);
			break;
		case 9: 
			OPM_WriteString((CHAR*)"0x", (LONGINT)3);
			skipLeading = 1;
			s = con->setval;
			i = 64;
			do {
				hex = 0;
				do {
					i -= 1;
					hex = __ASHL(hex, 1);
					if (__IN(i, s)) {
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
		case 10: 
			OPM_Write('\"');
			len = (int)con->intval2 - 1;
			i = 0;
			while (i < len) {
				ch = (*con->ext)[__X(i, ((LONGINT)(256)))];
				if (((ch == '\\' || ch == '\?') || ch == '\'') || ch == '\"') {
					OPM_Write('\\');
				}
				OPM_Write(ch);
				i += 1;
			}
			OPM_Write('\"');
			break;
		case 11: 
			OPM_WriteString((CHAR*)"NIL", (LONGINT)4);
			break;
		default: 
			OPM_LogWStr((CHAR*)"unhandled case in OPC.Constant, form = ", (LONGINT)40);
			OPM_LogWNum(form, ((LONGINT)(0)));
			OPM_LogWLn();
			break;
	}
}

static struct InitKeywords__47 {
	SHORTINT *n;
	struct InitKeywords__47 *lnk;
} *InitKeywords__47_s;

static void Enter__48 (CHAR *s, LONGINT s__len);

static void Enter__48 (CHAR *s, LONGINT s__len)
{
	INTEGER h;
	__DUP(s, s__len, CHAR);
	h = OPC_PerfectHash((void*)s, s__len);
	OPC_hashtab[__X(h, ((LONGINT)(105)))] = *InitKeywords__47_s->n;
	__COPY(s, OPC_keytab[__X(*InitKeywords__47_s->n, ((LONGINT)(36)))], ((LONGINT)(9)));
	*InitKeywords__47_s->n += 1;
	__DEL(s);
}

static void OPC_InitKeywords (void)
{
	SHORTINT n, i;
	struct InitKeywords__47 _s;
	_s.n = &n;
	_s.lnk = InitKeywords__47_s;
	InitKeywords__47_s = &_s;
	n = 0;
	i = 0;
	while (i <= 104) {
		OPC_hashtab[__X(i, ((LONGINT)(105)))] = -1;
		i += 1;
	}
	Enter__48((CHAR*)"asm", (LONGINT)4);
	Enter__48((CHAR*)"auto", (LONGINT)5);
	Enter__48((CHAR*)"break", (LONGINT)6);
	Enter__48((CHAR*)"case", (LONGINT)5);
	Enter__48((CHAR*)"char", (LONGINT)5);
	Enter__48((CHAR*)"const", (LONGINT)6);
	Enter__48((CHAR*)"continue", (LONGINT)9);
	Enter__48((CHAR*)"default", (LONGINT)8);
	Enter__48((CHAR*)"do", (LONGINT)3);
	Enter__48((CHAR*)"double", (LONGINT)7);
	Enter__48((CHAR*)"else", (LONGINT)5);
	Enter__48((CHAR*)"enum", (LONGINT)5);
	Enter__48((CHAR*)"extern", (LONGINT)7);
	Enter__48((CHAR*)"export", (LONGINT)7);
	Enter__48((CHAR*)"float", (LONGINT)6);
	Enter__48((CHAR*)"for", (LONGINT)4);
	Enter__48((CHAR*)"fortran", (LONGINT)8);
	Enter__48((CHAR*)"goto", (LONGINT)5);
	Enter__48((CHAR*)"if", (LONGINT)3);
	Enter__48((CHAR*)"import", (LONGINT)7);
	Enter__48((CHAR*)"int", (LONGINT)4);
	Enter__48((CHAR*)"long", (LONGINT)5);
	Enter__48((CHAR*)"register", (LONGINT)9);
	Enter__48((CHAR*)"return", (LONGINT)7);
	Enter__48((CHAR*)"short", (LONGINT)6);
	Enter__48((CHAR*)"signed", (LONGINT)7);
	Enter__48((CHAR*)"sizeof", (LONGINT)7);
	Enter__48((CHAR*)"static", (LONGINT)7);
	Enter__48((CHAR*)"struct", (LONGINT)7);
	Enter__48((CHAR*)"switch", (LONGINT)7);
	Enter__48((CHAR*)"typedef", (LONGINT)8);
	Enter__48((CHAR*)"union", (LONGINT)6);
	Enter__48((CHAR*)"unsigned", (LONGINT)9);
	Enter__48((CHAR*)"void", (LONGINT)5);
	Enter__48((CHAR*)"volatile", (LONGINT)9);
	Enter__48((CHAR*)"while", (LONGINT)6);
	InitKeywords__47_s = _s.lnk;
}


export void *OPC__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(Configuration);
	__MODULE_IMPORT(OPM);
	__MODULE_IMPORT(OPT);
	__REGMOD("OPC", 0);
	__REGCMD("BegBlk", OPC_BegBlk);
	__REGCMD("BegStat", OPC_BegStat);
	__REGCMD("EndBlk", OPC_EndBlk);
	__REGCMD("EndBlk0", OPC_EndBlk0);
	__REGCMD("EndStat", OPC_EndStat);
	__REGCMD("EnterBody", OPC_EnterBody);
	__REGCMD("ExitBody", OPC_ExitBody);
	__REGCMD("GenHdrIncludes", OPC_GenHdrIncludes);
	__REGCMD("Init", OPC_Init);
/* BEGIN */
	OPC_InitKeywords();
	__ENDMOD;
}
