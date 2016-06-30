/* voc  1.95 [2016/06/30] for gcc LP64 on cygwin xtspkaSfF */
#include "SYSTEM.h"
#include "OPC.h"
#include "OPM.h"
#include "OPS.h"
#include "OPT.h"

typedef
	struct OPV_ExitInfo {
		INTEGER level, label;
	} OPV_ExitInfo;


static BOOLEAN OPV_assert, OPV_inxchk, OPV_mainprog, OPV_ansi;
static INTEGER OPV_stamp;
static LONGINT OPV_recno;
static OPV_ExitInfo OPV_exit;
static INTEGER OPV_nofExitLabels;
static BOOLEAN OPV_naturalAlignment;

export LONGINT *OPV_ExitInfo__typ;

static void OPV_ActualPar (OPT_Node n, OPT_Object fp);
export void OPV_AdrAndSize (OPT_Object topScope);
static void OPV_CaseStat (OPT_Node n, OPT_Object outerProc);
static void OPV_Convert (OPT_Node n, INTEGER form, INTEGER prec);
static void OPV_DefineTDescs (OPT_Node n);
static void OPV_Entier (OPT_Node n, INTEGER prec);
static void OPV_GetTProcNum (OPT_Object obj);
static void OPV_IfStat (OPT_Node n, BOOLEAN withtrap, OPT_Object outerProc);
static BOOLEAN OPV_ImplicitReturn (OPT_Node n);
static void OPV_Index (OPT_Node n, OPT_Node d, INTEGER prec, INTEGER dim);
export void OPV_Init (void);
static void OPV_InitTDescs (OPT_Node n);
static void OPV_Len (OPT_Node n, LONGINT dim);
export void OPV_Module (OPT_Node prog);
static LONGINT OPV_NaturalAlignment (LONGINT size, LONGINT max);
static void OPV_NewArr (OPT_Node d, OPT_Node x);
static INTEGER OPV_Precedence (INTEGER class, INTEGER subclass, INTEGER form, INTEGER comp);
static BOOLEAN OPV_SideEffects (OPT_Node n);
static void OPV_Stamp (OPS_Name s);
static OPT_Object OPV_SuperProc (OPT_Node n);
static void OPV_Traverse (OPT_Object obj, OPT_Object outerScope, BOOLEAN exported);
static void OPV_TraverseRecord (OPT_Struct typ);
export void OPV_TypSize (OPT_Struct typ);
static void OPV_TypeOf (OPT_Node n);
static void OPV_design (OPT_Node n, INTEGER prec);
static void OPV_expr (OPT_Node n, INTEGER prec);
static void OPV_stat (OPT_Node n, OPT_Object outerProc);


static LONGINT OPV_NaturalAlignment (LONGINT size, LONGINT max)
{
	LONGINT _o_result;
	LONGINT i;
	if (size >= max) {
		_o_result = max;
		return _o_result;
	} else {
		i = 1;
		while (i < size) {
			i += i;
		}
		_o_result = i;
		return _o_result;
	}
	__RETCHK;
}

void OPV_TypSize (OPT_Struct typ)
{
	INTEGER f, c;
	LONGINT offset, size, base, fbase, off0;
	OPT_Object fld = NIL;
	OPT_Struct btyp = NIL;
	if (typ == OPT_undftyp) {
		OPM_err(58);
	} else if (typ->size == -1) {
		f = typ->form;
		c = typ->comp;
		if (c == 4) {
			btyp = typ->BaseTyp;
			if (btyp == NIL) {
				offset = 0;
				base = OPM_RecAlign;
			} else {
				OPV_TypSize(btyp);
				offset = btyp->size - (LONGINT)__ASHR(btyp->sysflag, 8);
				base = btyp->align;
			}
			fld = typ->link;
			while ((fld != NIL && fld->mode == 4)) {
				btyp = fld->typ;
				OPV_TypSize(btyp);
				size = btyp->size;
				fbase = OPC_Base(btyp);
				OPC_Align(&offset, fbase);
				fld->adr = offset;
				offset += size;
				if (fbase > base) {
					base = fbase;
				}
				fld = fld->link;
			}
			off0 = offset;
			if (offset == 0) {
				offset = 1;
			}
			if (OPM_RecSize == 0) {
				base = OPV_NaturalAlignment(offset, OPM_RecAlign);
			}
			OPC_Align(&offset, base);
			if ((typ->strobj == NIL && __MASK(typ->align, -65536) == 0)) {
				OPV_recno += 1;
				base += __ASHL(OPV_recno, 16);
			}
			typ->size = offset;
			typ->align = base;
			typ->sysflag = __MASK(typ->sysflag, -256) + (int)__ASHL(offset - off0, 8);
		} else if (c == 2) {
			OPV_TypSize(typ->BaseTyp);
			typ->size = typ->n * typ->BaseTyp->size;
		} else if (f == 13) {
			typ->size = OPM_PointerSize;
			if (typ->BaseTyp == OPT_undftyp) {
				OPM_Mark(128, typ->n);
			} else {
				OPV_TypSize(typ->BaseTyp);
			}
		} else if (f == 14) {
			typ->size = OPM_ProcSize;
		} else if (c == 3) {
			btyp = typ->BaseTyp;
			OPV_TypSize(btyp);
			if (btyp->comp == 3) {
				typ->size = btyp->size + 4;
			} else {
				typ->size = 8;
			}
		}
	}
}

void OPV_Init (void)
{
	OPV_stamp = 0;
	OPV_recno = 0;
	OPV_nofExitLabels = 0;
	OPV_assert = __IN(7, OPM_opt);
	OPV_inxchk = __IN(0, OPM_opt);
	OPV_mainprog = __IN(10, OPM_opt);
	OPV_ansi = __IN(6, OPM_opt);
}

static void OPV_GetTProcNum (OPT_Object obj)
{
	LONGINT oldPos;
	OPT_Struct typ = NIL;
	OPT_Object redef = NIL;
	oldPos = OPM_errpos;
	OPM_errpos = obj->scope->adr;
	typ = obj->link->typ;
	if (typ->form == 13) {
		typ = typ->BaseTyp;
	}
	OPT_FindField(obj->name, typ->BaseTyp, &redef);
	if (redef != NIL) {
		obj->adr = __ASHL(__ASHR(redef->adr, 16), 16);
		if (!__IN(2, obj->conval->setval)) {
			OPM_err(119);
		}
	} else {
		obj->adr += __ASHL(typ->n, 16);
		typ->n += 1;
	}
	OPM_errpos = oldPos;
}

static void OPV_TraverseRecord (OPT_Struct typ)
{
	if (!typ->allocated) {
		if (typ->BaseTyp != NIL) {
			OPV_TraverseRecord(typ->BaseTyp);
			typ->n = typ->BaseTyp->n;
		}
		typ->allocated = 1;
		OPV_Traverse(typ->link, typ->strobj, 0);
	}
}

static void OPV_Stamp (OPS_Name s)
{
	INTEGER i, j, k;
	CHAR n[10];
	OPV_stamp += 1;
	i = 0;
	j = OPV_stamp;
	while (s[__X(i, ((LONGINT)(256)))] != 0x00) {
		i += 1;
	}
	if (i > 25) {
		i = 25;
	}
	s[__X(i, ((LONGINT)(256)))] = '_';
	s[__X(i + 1, ((LONGINT)(256)))] = '_';
	i += 2;
	k = 0;
	do {
		n[__X(k, ((LONGINT)(10)))] = (CHAR)((int)__MOD(j, 10) + 48);
		j = __DIV(j, 10);
		k += 1;
	} while (!(j == 0));
	do {
		k -= 1;
		s[__X(i, ((LONGINT)(256)))] = n[__X(k, ((LONGINT)(10)))];
		i += 1;
	} while (!(k == 0));
	s[__X(i, ((LONGINT)(256)))] = 0x00;
}

static void OPV_Traverse (OPT_Object obj, OPT_Object outerScope, BOOLEAN exported)
{
	INTEGER mode;
	OPT_Object scope = NIL;
	OPT_Struct typ = NIL;
	if (obj != NIL) {
		OPV_Traverse(obj->left, outerScope, exported);
		if (obj->name[0] == '@') {
			obj->name[0] = '_';
			OPV_Stamp(obj->name);
		}
		obj->linkadr = 0;
		mode = obj->mode;
		if ((mode == 5 && (obj->vis != 0) == exported)) {
			typ = obj->typ;
			OPV_TypSize(obj->typ);
			if (typ->form == 13) {
				typ = typ->BaseTyp;
			}
			if (typ->comp == 4) {
				OPV_TraverseRecord(typ);
			}
		} else if (mode == 13) {
			OPV_GetTProcNum(obj);
		} else if (mode == 1) {
			OPV_TypSize(obj->typ);
		}
		if (!exported) {
			if ((__IN(mode, 0x60) && obj->mnolev > 0)) {
				OPV_Stamp(obj->name);
			}
			if (__IN(mode, 0x26)) {
				obj->scope = outerScope;
			} else if (__IN(mode, 0x26c0)) {
				if (obj->conval->setval == 0x0) {
					OPM_err(129);
				}
				scope = obj->scope;
				scope->leaf = 1;
				__COPY(obj->name, scope->name, ((LONGINT)(256)));
				OPV_Stamp(scope->name);
				if (mode == 9) {
					obj->adr = 1;
				}
				if (scope->mnolev > 1) {
					outerScope->leaf = 0;
				}
				OPV_Traverse(obj->scope->right, obj->scope, 0);
			}
		}
		OPV_Traverse(obj->right, outerScope, exported);
	}
}

void OPV_AdrAndSize (OPT_Object topScope)
{
	OPM_errpos = topScope->adr;
	topScope->leaf = 1;
	OPV_Traverse(topScope->right, topScope, 1);
	OPV_Traverse(topScope->right, topScope, 0);
	OPT_chartyp->strobj->linkadr = 2;
	OPT_settyp->strobj->linkadr = 2;
	OPT_realtyp->strobj->linkadr = 2;
	OPT_inttyp->strobj->linkadr = 2;
	OPT_linttyp->strobj->linkadr = 2;
	OPT_lrltyp->strobj->linkadr = 2;
	OPT_sinttyp->strobj->linkadr = 2;
	OPT_booltyp->strobj->linkadr = 2;
	OPT_bytetyp->strobj->linkadr = 2;
	OPT_sysptrtyp->strobj->linkadr = 2;
}

static INTEGER OPV_Precedence (INTEGER class, INTEGER subclass, INTEGER form, INTEGER comp)
{
	INTEGER _o_result;
	switch (class) {
		case 7: case 0: case 2: case 4: case 9: 
		case 13: 
			_o_result = 10;
			return _o_result;
			break;
		case 5: 
			if (__IN(3, OPM_opt)) {
				_o_result = 10;
				return _o_result;
			} else {
				_o_result = 9;
				return _o_result;
			}
			break;
		case 1: 
			if (__IN(comp, 0x0c)) {
				_o_result = 10;
				return _o_result;
			} else {
				_o_result = 9;
				return _o_result;
			}
			break;
		case 3: 
			_o_result = 9;
			return _o_result;
			break;
		case 11: 
			switch (subclass) {
				case 33: case 7: case 24: case 29: case 20: 
					_o_result = 9;
					return _o_result;
					break;
				case 16: case 21: case 22: case 23: case 25: 
					_o_result = 10;
					return _o_result;
					break;
				default: 
					OPM_LogWStr((CHAR*)"unhandled case in OPV.Precedence Nmop, subclass = ", (LONGINT)51);
					OPM_LogWNum(subclass, ((LONGINT)(0)));
					OPM_LogWLn();
					break;
			}
			break;
		case 12: 
			switch (subclass) {
				case 1: 
					if (form == 9) {
						_o_result = 4;
						return _o_result;
					} else {
						_o_result = 8;
						return _o_result;
					}
					break;
				case 2: 
					if (form == 9) {
						_o_result = 3;
						return _o_result;
					} else {
						_o_result = 8;
						return _o_result;
					}
					break;
				case 3: case 4: 
					_o_result = 10;
					return _o_result;
					break;
				case 6: 
					if (form == 9) {
						_o_result = 2;
						return _o_result;
					} else {
						_o_result = 7;
						return _o_result;
					}
					break;
				case 7: 
					if (form == 9) {
						_o_result = 4;
						return _o_result;
					} else {
						_o_result = 7;
						return _o_result;
					}
					break;
				case 11: case 12: case 13: case 14: 
					_o_result = 6;
					return _o_result;
					break;
				case 9: case 10: 
					_o_result = 5;
					return _o_result;
					break;
				case 5: 
					_o_result = 1;
					return _o_result;
					break;
				case 8: 
					_o_result = 0;
					return _o_result;
					break;
				case 19: case 15: case 17: case 18: case 26: 
				case 27: case 28: 
					_o_result = 10;
					return _o_result;
					break;
				default: 
					OPM_LogWStr((CHAR*)"unhandled case in OPV.Precedence Ndop, subclass = ", (LONGINT)51);
					OPM_LogWNum(subclass, ((LONGINT)(0)));
					OPM_LogWLn();
					break;
			}
			break;
		case 10: 
			_o_result = 10;
			return _o_result;
			break;
		case 8: case 6: 
			_o_result = 12;
			return _o_result;
			break;
		default: 
			OPM_LogWStr((CHAR*)"unhandled case in OPV.Precedence, class = ", (LONGINT)43);
			OPM_LogWNum(class, ((LONGINT)(0)));
			OPM_LogWLn();
			break;
	}
	__RETCHK;
}

static void OPV_Len (OPT_Node n, LONGINT dim)
{
	while ((n->class == 4 && n->typ->comp == 3)) {
		dim += 1;
		n = n->left;
	}
	if ((n->class == 3 && n->typ->comp == 3)) {
		OPV_design(n->left, 10);
		OPM_WriteString((CHAR*)"->len[", (LONGINT)7);
		OPM_WriteInt(dim);
		OPM_Write(']');
	} else {
		OPC_Len(n->obj, n->typ, dim);
	}
}

static BOOLEAN OPV_SideEffects (OPT_Node n)
{
	BOOLEAN _o_result;
	if (n != NIL) {
		_o_result = (n->class == 13 || OPV_SideEffects(n->left)) || OPV_SideEffects(n->right);
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

static void OPV_Entier (OPT_Node n, INTEGER prec)
{
	if (__IN(n->typ->form, 0x0180)) {
		OPM_WriteString((CHAR*)"__ENTIER(", (LONGINT)10);
		OPV_expr(n, -1);
		OPM_Write(')');
	} else {
		OPV_expr(n, prec);
	}
}

static void OPV_Convert (OPT_Node n, INTEGER form, INTEGER prec)
{
	INTEGER from;
	from = n->typ->form;
	if (form == 9) {
		OPM_WriteString((CHAR*)"__SETOF(", (LONGINT)9);
		OPV_Entier(n, -1);
		OPM_Write(')');
	} else if (form == 6) {
		if (from < 6) {
			OPM_WriteString((CHAR*)"(LONGINT)", (LONGINT)10);
		}
		OPV_Entier(n, 9);
	} else if (form == 5) {
		if (from < 5) {
			OPM_WriteString((CHAR*)"(int)", (LONGINT)6);
			OPV_expr(n, 9);
		} else {
			if (__IN(2, OPM_opt)) {
				OPM_WriteString((CHAR*)"__SHORT", (LONGINT)8);
				if (OPV_SideEffects(n)) {
					OPM_Write('F');
				}
				OPM_Write('(');
				OPV_Entier(n, -1);
				OPM_WriteString((CHAR*)", ", (LONGINT)3);
				OPM_WriteInt(OPM_MaxInt + 1);
				OPM_Write(')');
			} else {
				OPM_WriteString((CHAR*)"(int)", (LONGINT)6);
				OPV_Entier(n, 9);
			}
		}
	} else if (form == 4) {
		if (__IN(2, OPM_opt)) {
			OPM_WriteString((CHAR*)"__SHORT", (LONGINT)8);
			if (OPV_SideEffects(n)) {
				OPM_Write('F');
			}
			OPM_Write('(');
			OPV_Entier(n, -1);
			OPM_WriteString((CHAR*)", ", (LONGINT)3);
			OPM_WriteInt(OPM_MaxSInt + 1);
			OPM_Write(')');
		} else {
			OPM_WriteString((CHAR*)"(int)", (LONGINT)6);
			OPV_Entier(n, 9);
		}
	} else if (form == 3) {
		if (__IN(2, OPM_opt)) {
			OPM_WriteString((CHAR*)"__CHR", (LONGINT)6);
			if (OPV_SideEffects(n)) {
				OPM_Write('F');
			}
			OPM_Write('(');
			OPV_Entier(n, -1);
			OPM_Write(')');
		} else {
			OPM_WriteString((CHAR*)"(CHAR)", (LONGINT)7);
			OPV_Entier(n, 9);
		}
	} else {
		OPV_expr(n, prec);
	}
}

static void OPV_TypeOf (OPT_Node n)
{
	if (n->typ->form == 13) {
		OPM_WriteString((CHAR*)"__TYPEOF(", (LONGINT)10);
		OPV_expr(n, -1);
		OPM_Write(')');
	} else if (__IN(n->class, 0x15)) {
		OPC_Andent(n->typ);
		OPM_WriteString((CHAR*)"__typ", (LONGINT)6);
	} else if (n->class == 3) {
		OPM_WriteString((CHAR*)"__TYPEOF(", (LONGINT)10);
		OPV_expr(n->left, -1);
		OPM_Write(')');
	} else if (n->class == 5) {
		OPV_TypeOf(n->left);
	} else if ((n->class == 11 && n->subcl == 29)) {
		OPC_TypeOf(n->left->obj);
	} else {
		OPC_TypeOf(n->obj);
	}
}

static void OPV_Index (OPT_Node n, OPT_Node d, INTEGER prec, INTEGER dim)
{
	if (!OPV_inxchk || (n->right->class == 7 && (n->right->conval->intval == 0 || n->left->typ->comp != 3))) {
		OPV_expr(n->right, prec);
	} else {
		if (OPV_SideEffects(n->right)) {
			OPM_WriteString((CHAR*)"__XF(", (LONGINT)6);
		} else {
			OPM_WriteString((CHAR*)"__X(", (LONGINT)5);
		}
		OPV_expr(n->right, -1);
		OPM_WriteString((CHAR*)", ", (LONGINT)3);
		OPV_Len(d, dim);
		OPM_Write(')');
	}
}

static void OPV_design (OPT_Node n, INTEGER prec)
{
	OPT_Object obj = NIL;
	OPT_Struct typ = NIL;
	INTEGER class, designPrec, comp;
	OPT_Node d = NIL, x = NIL;
	INTEGER dims, i, _for__26;
	comp = n->typ->comp;
	obj = n->obj;
	class = n->class;
	designPrec = OPV_Precedence(class, n->subcl, n->typ->form, comp);
	if ((((((class == 0 && obj->mnolev > 0)) && (int)obj->mnolev != OPM_level)) && prec == 10)) {
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
			OPC_Ident(n->obj);
			break;
		case 0: 
			OPC_CompleteIdent(n->obj);
			break;
		case 1: 
			if (!__IN(comp, 0x0c)) {
				OPM_Write('*');
			}
			OPC_CompleteIdent(n->obj);
			break;
		case 2: 
			if (n->left->class == 3) {
				OPV_design(n->left->left, designPrec);
				OPM_WriteString((CHAR*)"->", (LONGINT)3);
			} else {
				OPV_design(n->left, designPrec);
				OPM_Write('.');
			}
			OPC_Ident(n->obj);
			break;
		case 3: 
			if (n->typ->comp == 3) {
				OPV_design(n->left, 10);
				OPM_WriteString((CHAR*)"->data", (LONGINT)7);
			} else {
				OPM_Write('*');
				OPV_design(n->left, designPrec);
			}
			break;
		case 4: 
			d = n->left;
			if (d->typ->comp == 3) {
				dims = 0;
				while (d->class == 4) {
					d = d->left;
					dims += 1;
				}
				if (n->typ->comp == 3) {
					OPM_Write('&');
				}
				OPV_design(d, designPrec);
				OPM_Write('[');
				if (n->typ->comp == 3) {
					OPM_Write('(');
				}
				i = dims;
				x = n;
				while (x != d) {
					if (x->left != d) {
						OPV_Index(x, d, 7, i);
						OPM_WriteString((CHAR*)" + ", (LONGINT)4);
						OPV_Len(d, i);
						OPM_WriteString((CHAR*)" * (", (LONGINT)5);
						i -= 1;
					} else {
						OPV_Index(x, d, -1, i);
					}
					x = x->left;
				}
				_for__26 = dims;
				i = 1;
				while (i <= _for__26) {
					OPM_Write(')');
					i += 1;
				}
				if (n->typ->comp == 3) {
					OPM_Write(')');
					while ((LONGINT)i < __ASHR(d->typ->size - 4, 2)) {
						OPM_WriteString((CHAR*)" * ", (LONGINT)4);
						OPV_Len(d, i);
						i += 1;
					}
				}
				OPM_Write(']');
			} else {
				OPV_design(n->left, designPrec);
				OPM_Write('[');
				OPV_Index(n, n->left, -1, 0);
				OPM_Write(']');
			}
			break;
		case 5: 
			typ = n->typ;
			obj = n->left->obj;
			if (__IN(3, OPM_opt)) {
				if (typ->comp == 4) {
					OPM_WriteString((CHAR*)"__GUARDR(", (LONGINT)10);
					if ((int)obj->mnolev != OPM_level) {
						OPM_WriteStringVar((void*)obj->scope->name, ((LONGINT)(256)));
						OPM_WriteString((CHAR*)"__curr->", (LONGINT)9);
						OPC_Ident(obj);
					} else {
						OPC_Ident(obj);
					}
				} else {
					if (typ->BaseTyp->strobj == NIL) {
						OPM_WriteString((CHAR*)"__GUARDA(", (LONGINT)10);
					} else {
						OPM_WriteString((CHAR*)"__GUARDP(", (LONGINT)10);
					}
					OPV_expr(n->left, -1);
					typ = typ->BaseTyp;
				}
				OPM_WriteString((CHAR*)", ", (LONGINT)3);
				OPC_Andent(typ);
				OPM_WriteString((CHAR*)", ", (LONGINT)3);
				OPM_WriteInt(typ->extlev);
				OPM_Write(')');
			} else {
				if (typ->comp == 4) {
					OPM_WriteString((CHAR*)"*(", (LONGINT)3);
					OPC_Ident(typ->strobj);
					OPM_WriteString((CHAR*)"*)", (LONGINT)3);
					OPC_CompleteIdent(obj);
				} else {
					OPM_Write('(');
					OPC_Ident(typ->strobj);
					OPM_Write(')');
					OPV_expr(n->left, designPrec);
				}
			}
			break;
		case 6: 
			if (__IN(3, OPM_opt)) {
				if (n->left->class == 1) {
					OPM_WriteString((CHAR*)"__GUARDEQR(", (LONGINT)12);
					OPC_CompleteIdent(n->left->obj);
					OPM_WriteString((CHAR*)", ", (LONGINT)3);
					OPV_TypeOf(n->left);
				} else {
					OPM_WriteString((CHAR*)"__GUARDEQP(", (LONGINT)12);
					OPV_expr(n->left->left, -1);
				}
				OPM_WriteString((CHAR*)", ", (LONGINT)3);
				OPC_Ident(n->left->typ->strobj);
				OPM_Write(')');
			} else {
				OPV_expr(n->left, -1);
			}
			break;
		case 11: 
			if (n->subcl == 29) {
				OPV_design(n->left, prec);
			}
			break;
		default: 
			OPM_LogWStr((CHAR*)"unhandled case in OPV.design, class = ", (LONGINT)39);
			OPM_LogWNum(class, ((LONGINT)(0)));
			OPM_LogWLn();
			break;
	}
	if (prec > designPrec) {
		OPM_Write(')');
	}
}

static void OPV_ActualPar (OPT_Node n, OPT_Object fp)
{
	OPT_Struct typ = NIL, aptyp = NIL;
	INTEGER comp, form, mode, prec, dim;
	OPM_Write('(');
	while (n != NIL) {
		typ = fp->typ;
		comp = typ->comp;
		form = typ->form;
		mode = fp->mode;
		prec = -1;
		if ((((mode == 2 && n->class == 11)) && n->subcl == 29)) {
			OPM_Write('(');
			OPC_Ident(n->typ->strobj);
			OPM_WriteString((CHAR*)"*)", (LONGINT)3);
			prec = 10;
		}
		if (!__IN(n->typ->comp, 0x0c)) {
			if (mode == 2) {
				if ((OPV_ansi && typ != n->typ)) {
					OPM_WriteString((CHAR*)"(void*)", (LONGINT)8);
				}
				OPM_Write('&');
				prec = 9;
			} else if (OPV_ansi) {
				if ((__IN(comp, 0x0c) && n->class == 7)) {
					OPM_WriteString((CHAR*)"(CHAR*)", (LONGINT)8);
				} else if ((((form == 13 && typ != n->typ)) && n->typ != OPT_niltyp)) {
					OPM_WriteString((CHAR*)"(void*)", (LONGINT)8);
				}
			} else {
				if ((__IN(form, 0x0180) && __IN(n->typ->form, 0x70))) {
					OPM_WriteString((CHAR*)"(double)", (LONGINT)9);
					prec = 9;
				} else if ((form == 6 && n->typ->form < 6)) {
					OPM_WriteString((CHAR*)"(LONGINT)", (LONGINT)10);
					prec = 9;
				}
			}
		} else if (OPV_ansi) {
			if ((((mode == 2 && typ != n->typ)) && prec == -1)) {
				OPM_WriteString((CHAR*)"(void*)", (LONGINT)8);
			}
		}
		if ((((mode == 2 && n->class == 11)) && n->subcl == 29)) {
			OPV_expr(n->left, prec);
		} else if ((((((form == 6 && n->class == 7)) && n->conval->intval <= OPM_MaxInt)) && n->conval->intval >= OPM_MinInt)) {
			OPM_WriteString((CHAR*)"((LONGINT)(", (LONGINT)12);
			OPV_expr(n, prec);
			OPM_WriteString((CHAR*)"))", (LONGINT)3);
		} else {
			OPV_expr(n, prec);
		}
		if ((comp == 4 && mode == 2)) {
			OPM_WriteString((CHAR*)", ", (LONGINT)3);
			OPV_TypeOf(n);
		} else if (comp == 3) {
			if (n->class == 7) {
				OPM_WriteString((CHAR*)", ", (LONGINT)3);
				OPM_WriteString((CHAR*)"(LONGINT)", (LONGINT)10);
				OPM_WriteInt(n->conval->intval2);
			} else {
				aptyp = n->typ;
				dim = 0;
				while ((typ->comp == 3 && typ->BaseTyp->form != 1)) {
					OPM_WriteString((CHAR*)", ", (LONGINT)3);
					OPV_Len(n, dim);
					typ = typ->BaseTyp;
					aptyp = aptyp->BaseTyp;
					dim += 1;
				}
				if ((typ->comp == 3 && typ->BaseTyp->form == 1)) {
					OPM_WriteString((CHAR*)", ", (LONGINT)3);
					while (aptyp->comp == 3) {
						OPV_Len(n, dim);
						OPM_WriteString((CHAR*)" * ", (LONGINT)4);
						dim += 1;
						aptyp = aptyp->BaseTyp;
					}
					OPM_WriteString((CHAR*)"((LONGINT)(", (LONGINT)12);
					OPM_WriteInt(aptyp->size);
					OPM_WriteString((CHAR*)"))", (LONGINT)3);
				}
			}
		}
		n = n->link;
		fp = fp->link;
		if (n != NIL) {
			OPM_WriteString((CHAR*)", ", (LONGINT)3);
		}
	}
	OPM_Write(')');
}

static OPT_Object OPV_SuperProc (OPT_Node n)
{
	OPT_Object _o_result;
	OPT_Object obj = NIL;
	OPT_Struct typ = NIL;
	typ = n->right->typ;
	if (typ->form == 13) {
		typ = typ->BaseTyp;
	}
	OPT_FindField(n->left->obj->name, typ->BaseTyp, &obj);
	_o_result = obj;
	return _o_result;
}

static void OPV_expr (OPT_Node n, INTEGER prec)
{
	INTEGER class, subclass, form, exprPrec;
	OPT_Struct typ = NIL;
	OPT_Node l = NIL, r = NIL;
	OPT_Object proc = NIL;
	class = n->class;
	subclass = n->subcl;
	form = n->typ->form;
	l = n->left;
	r = n->right;
	exprPrec = OPV_Precedence(class, subclass, form, n->typ->comp);
	if ((exprPrec <= prec && __IN(class, 0x3ce0))) {
		OPM_Write('(');
	}
	switch (class) {
		case 7: 
			OPC_Constant(n->conval, form);
			break;
		case 10: 
			OPM_WriteString((CHAR*)"__SETRNG(", (LONGINT)10);
			OPV_expr(l, -1);
			OPM_WriteString((CHAR*)", ", (LONGINT)3);
			OPV_expr(r, -1);
			OPM_Write(')');
			break;
		case 11: 
			switch (subclass) {
				case 33: 
					OPM_Write('!');
					OPV_expr(l, exprPrec);
					break;
				case 7: 
					if (form == 9) {
						OPM_Write('~');
					} else {
						OPM_Write('-');
					}
					OPV_expr(l, exprPrec);
					break;
				case 16: 
					typ = n->obj->typ;
					if (l->typ->comp == 4) {
						OPM_WriteString((CHAR*)"__IS(", (LONGINT)6);
						OPC_TypeOf(l->obj);
					} else {
						OPM_WriteString((CHAR*)"__ISP(", (LONGINT)7);
						OPV_expr(l, -1);
						typ = typ->BaseTyp;
					}
					OPM_WriteString((CHAR*)", ", (LONGINT)3);
					OPC_Andent(typ);
					OPM_WriteString((CHAR*)", ", (LONGINT)3);
					OPM_WriteInt(typ->extlev);
					OPM_Write(')');
					break;
				case 20: 
					OPV_Convert(l, form, exprPrec);
					break;
				case 21: 
					if (OPV_SideEffects(l)) {
						if (l->typ->form < 7) {
							if (l->typ->form < 6) {
								OPM_WriteString((CHAR*)"(int)", (LONGINT)6);
							}
							OPM_WriteString((CHAR*)"__ABSF(", (LONGINT)8);
						} else {
							OPM_WriteString((CHAR*)"__ABSFD(", (LONGINT)9);
						}
					} else {
						OPM_WriteString((CHAR*)"__ABS(", (LONGINT)7);
					}
					OPV_expr(l, -1);
					OPM_Write(')');
					break;
				case 22: 
					OPM_WriteString((CHAR*)"__CAP(", (LONGINT)7);
					OPV_expr(l, -1);
					OPM_Write(')');
					break;
				case 23: 
					OPM_WriteString((CHAR*)"__ODD(", (LONGINT)7);
					OPV_expr(l, -1);
					OPM_Write(')');
					break;
				case 24: 
					OPM_WriteString((CHAR*)"(LONGINT)(uintptr_t)", (LONGINT)21);
					if (l->class == 1) {
						OPC_CompleteIdent(l->obj);
					} else {
						if ((l->typ->form != 10 && !__IN(l->typ->comp, 0x0c))) {
							OPM_Write('&');
						}
						OPV_expr(l, exprPrec);
					}
					break;
				case 29: 
					if ((((__IN(n->typ->form, 0x6240) && __IN(l->typ->form, 0x6240))) && n->typ->size == l->typ->size) || !__IN(l->class, 0x17)) {
						OPM_Write('(');
						OPC_Ident(n->typ->strobj);
						OPM_Write(')');
						if (__IN(n->typ->form, 0x6000) || __IN(l->typ->form, 0x6000)) {
							OPM_WriteString((CHAR*)"(uintptr_t)", (LONGINT)12);
						}
						OPV_expr(l, exprPrec);
					} else {
						if (__IN(n->typ->form, 0x6000) || __IN(l->typ->form, 0x6000)) {
							OPM_WriteString((CHAR*)"__VALP(", (LONGINT)8);
						} else {
							OPM_WriteString((CHAR*)"__VAL(", (LONGINT)7);
						}
						OPC_Ident(n->typ->strobj);
						OPM_WriteString((CHAR*)", ", (LONGINT)3);
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
					OPV_Len(l, r->conval->intval);
					break;
				case 15: case 17: case 18: case 26: case 27: 
				case 28: case 3: case 4: 
					switch (subclass) {
						case 15: 
							OPM_WriteString((CHAR*)"__IN(", (LONGINT)6);
							break;
						case 17: 
							if (r->class == 7) {
								if (r->conval->intval >= 0) {
									OPM_WriteString((CHAR*)"__ASHL(", (LONGINT)8);
								} else {
									OPM_WriteString((CHAR*)"__ASHR(", (LONGINT)8);
								}
							} else if (OPV_SideEffects(r)) {
								OPM_WriteString((CHAR*)"__ASHF(", (LONGINT)8);
							} else {
								OPM_WriteString((CHAR*)"__ASH(", (LONGINT)7);
							}
							break;
						case 18: 
							OPM_WriteString((CHAR*)"__MASK(", (LONGINT)8);
							break;
						case 26: 
							OPM_WriteString((CHAR*)"__BIT(", (LONGINT)7);
							break;
						case 27: 
							if (r->class == 7) {
								if (r->conval->intval >= 0) {
									OPM_WriteString((CHAR*)"__LSHL(", (LONGINT)8);
								} else {
									OPM_WriteString((CHAR*)"__LSHR(", (LONGINT)8);
								}
							} else {
								OPM_WriteString((CHAR*)"__LSH(", (LONGINT)7);
							}
							break;
						case 28: 
							if (r->class == 7) {
								if (r->conval->intval >= 0) {
									OPM_WriteString((CHAR*)"__ROTL(", (LONGINT)8);
								} else {
									OPM_WriteString((CHAR*)"__ROTR(", (LONGINT)8);
								}
							} else {
								OPM_WriteString((CHAR*)"__ROT(", (LONGINT)7);
							}
							break;
						case 3: 
							if (OPV_SideEffects(n)) {
								if (form < 6) {
									OPM_WriteString((CHAR*)"(int)", (LONGINT)6);
								}
								OPM_WriteString((CHAR*)"__DIVF(", (LONGINT)8);
							} else {
								OPM_WriteString((CHAR*)"__DIV(", (LONGINT)7);
							}
							break;
						case 4: 
							if (form < 6) {
								OPM_WriteString((CHAR*)"(int)", (LONGINT)6);
							}
							if (OPV_SideEffects(n)) {
								OPM_WriteString((CHAR*)"__MODF(", (LONGINT)8);
							} else {
								OPM_WriteString((CHAR*)"__MOD(", (LONGINT)7);
							}
							break;
						default: 
							OPM_LogWStr((CHAR*)"unhandled case in OPV.expr, subclass = ", (LONGINT)40);
							OPM_LogWNum(subclass, ((LONGINT)(0)));
							OPM_LogWLn();
							break;
					}
					OPV_expr(l, -1);
					OPM_WriteString((CHAR*)", ", (LONGINT)3);
					if ((((__IN(subclass, 0x18020000) && r->class == 7)) && r->conval->intval < 0)) {
						OPM_WriteInt(-r->conval->intval);
					} else {
						OPV_expr(r, -1);
					}
					if (__IN(subclass, 0x18000000)) {
						OPM_WriteString((CHAR*)", ", (LONGINT)3);
						OPC_Ident(l->typ->strobj);
					}
					OPM_Write(')');
					break;
				case 9: case 10: case 11: case 12: case 13: 
				case 14: 
					if (__IN(l->typ->form, 0x8400)) {
						OPM_WriteString((CHAR*)"__STRCMP(", (LONGINT)10);
						OPV_expr(l, -1);
						OPM_WriteString((CHAR*)", ", (LONGINT)3);
						OPV_expr(r, -1);
						OPM_Write(')');
						OPC_Cmp(subclass);
						OPM_Write('0');
					} else {
						OPV_expr(l, exprPrec);
						OPC_Cmp(subclass);
						typ = l->typ;
						if ((((((typ->form == 13 && r->typ->form != 11)) && r->typ != typ)) && r->typ != OPT_sysptrtyp)) {
							OPM_WriteString((CHAR*)"(void *) ", (LONGINT)10);
						}
						OPV_expr(r, exprPrec);
					}
					break;
				default: 
					if (subclass == 5 || (form == 9 && (subclass == 1 || subclass == 7))) {
						OPM_Write('(');
					}
					OPV_expr(l, exprPrec);
					switch (subclass) {
						case 1: 
							if (form == 9) {
								OPM_WriteString((CHAR*)" & ", (LONGINT)4);
							} else {
								OPM_WriteString((CHAR*)" * ", (LONGINT)4);
							}
							break;
						case 2: 
							if (form == 9) {
								OPM_WriteString((CHAR*)" ^ ", (LONGINT)4);
							} else {
								OPM_WriteString((CHAR*)" / ", (LONGINT)4);
								if (r->obj == NIL || __IN(r->obj->typ->form, 0x70)) {
									OPM_Write('(');
									OPC_Ident(n->typ->strobj);
									OPM_Write(')');
								}
							}
							break;
						case 5: 
							OPM_WriteString((CHAR*)" && ", (LONGINT)5);
							break;
						case 6: 
							if (form == 9) {
								OPM_WriteString((CHAR*)" | ", (LONGINT)4);
							} else {
								OPM_WriteString((CHAR*)" + ", (LONGINT)4);
							}
							break;
						case 7: 
							if (form == 9) {
								OPM_WriteString((CHAR*)" & ~", (LONGINT)5);
							} else {
								OPM_WriteString((CHAR*)" - ", (LONGINT)4);
							}
							break;
						case 8: 
							OPM_WriteString((CHAR*)" || ", (LONGINT)5);
							break;
						default: 
							OPM_LogWStr((CHAR*)"unhandled case in OPV.expr, subclass = ", (LONGINT)40);
							OPM_LogWNum(subclass, ((LONGINT)(0)));
							OPM_LogWLn();
							break;
					}
					OPV_expr(r, exprPrec);
					if (subclass == 5 || (form == 9 && (subclass == 1 || subclass == 7))) {
						OPM_Write(')');
					}
					break;
			}
			break;
		case 13: 
			if ((l->obj != NIL && l->obj->mode == 13)) {
				if (l->subcl == 1) {
					proc = OPV_SuperProc(n);
				} else {
					OPM_WriteString((CHAR*)"__", (LONGINT)3);
					proc = OPC_BaseTProc(l->obj);
				}
				OPC_Ident(proc);
				n->obj = proc->link;
			} else if (l->class == 9) {
				OPV_design(l, 10);
			} else {
				OPV_design(l, 11);
			}
			OPV_ActualPar(r, n->obj);
			break;
		default: 
			OPV_design(n, prec);
			break;
	}
	if ((exprPrec <= prec && __IN(class, 0x3ca0))) {
		OPM_Write(')');
	}
}

static void OPV_IfStat (OPT_Node n, BOOLEAN withtrap, OPT_Object outerProc)
{
	OPT_Node if_ = NIL;
	OPT_Object obj = NIL;
	OPT_Struct typ = NIL;
	LONGINT adr;
	if_ = n->left;
	while (if_ != NIL) {
		OPM_WriteString((CHAR*)"if ", (LONGINT)4);
		OPV_expr(if_->left, 12);
		OPM_Write(' ');
		OPC_BegBlk();
		if ((n->class == 27 && if_->left->left != NIL)) {
			obj = if_->left->left->obj;
			typ = obj->typ;
			adr = obj->adr;
			if (typ->comp == 4) {
				OPC_BegStat();
				OPC_Ident(if_->left->obj);
				OPM_WriteString((CHAR*)" *", (LONGINT)3);
				OPM_WriteString(obj->name, ((LONGINT)(256)));
				OPM_WriteString((CHAR*)"__ = (void*)", (LONGINT)13);
				obj->adr = 0;
				OPC_CompleteIdent(obj);
				OPC_EndStat();
			}
			obj->adr = 1;
			obj->typ = if_->left->obj->typ;
			OPV_stat(if_->right, outerProc);
			obj->typ = typ;
			obj->adr = adr;
		} else {
			OPV_stat(if_->right, outerProc);
		}
		if_ = if_->link;
		if ((if_ != NIL || n->right != NIL) || withtrap) {
			OPC_EndBlk0();
			OPM_WriteString((CHAR*)" else ", (LONGINT)7);
		} else {
			OPC_EndBlk();
		}
	}
	if (withtrap) {
		OPM_WriteString((CHAR*)"__WITHCHK", (LONGINT)10);
		OPC_EndStat();
	} else if (n->right != NIL) {
		OPC_BegBlk();
		OPV_stat(n->right, outerProc);
		OPC_EndBlk();
	}
}

static void OPV_CaseStat (OPT_Node n, OPT_Object outerProc)
{
	OPT_Node switchCase = NIL, label = NIL;
	LONGINT low, high;
	INTEGER form, i;
	OPM_WriteString((CHAR*)"switch ", (LONGINT)8);
	OPV_expr(n->left, 12);
	OPM_Write(' ');
	OPC_BegBlk();
	form = n->left->typ->form;
	switchCase = n->right->left;
	while (switchCase != NIL) {
		label = switchCase->left;
		i = 0;
		while (label != NIL) {
			low = label->conval->intval;
			high = label->conval->intval2;
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
			label = label->link;
		}
		if (i > 0) {
			OPM_WriteLn();
		}
		OPC_Indent(1);
		OPV_stat(switchCase->right, outerProc);
		OPC_BegStat();
		OPM_WriteString((CHAR*)"break", (LONGINT)6);
		OPC_EndStat();
		OPC_Indent(-1);
		switchCase = switchCase->link;
	}
	OPC_BegStat();
	OPM_WriteString((CHAR*)"default: ", (LONGINT)10);
	if (n->right->conval->setval != 0x0) {
		OPC_Indent(1);
		OPM_WriteLn();
		OPV_stat(n->right->right, outerProc);
		OPC_BegStat();
		OPM_WriteString((CHAR*)"break", (LONGINT)6);
		OPC_Indent(-1);
	} else {
		OPM_WriteString((CHAR*)"__CASECHK", (LONGINT)10);
	}
	OPC_EndStat();
	OPC_EndBlk();
}

static BOOLEAN OPV_ImplicitReturn (OPT_Node n)
{
	BOOLEAN _o_result;
	while ((n != NIL && n->class != 26)) {
		n = n->link;
	}
	_o_result = n == NIL;
	return _o_result;
}

static void OPV_NewArr (OPT_Node d, OPT_Node x)
{
	OPT_Struct typ = NIL, base = NIL;
	INTEGER nofdim, nofdyn;
	typ = d->typ->BaseTyp;
	base = typ;
	nofdim = 0;
	nofdyn = 0;
	while (base->comp == 3) {
		nofdim += 1;
		nofdyn += 1;
		base = base->BaseTyp;
	}
	OPV_design(d, -1);
	OPM_WriteString((CHAR*)" = __NEWARR(", (LONGINT)13);
	while (base->comp == 2) {
		nofdim += 1;
		base = base->BaseTyp;
	}
	if ((base->comp == 4 && OPC_NofPtrs(base) != 0)) {
		OPC_Ident(base->strobj);
		OPM_WriteString((CHAR*)"__typ", (LONGINT)6);
	} else if (base->form == 13) {
		OPM_WriteString((CHAR*)"POINTER__typ", (LONGINT)13);
	} else {
		OPM_WriteString((CHAR*)"NIL", (LONGINT)4);
	}
	OPM_WriteString((CHAR*)", ", (LONGINT)3);
	OPM_WriteString((CHAR*)"((LONGINT)(", (LONGINT)12);
	OPM_WriteInt(base->size);
	OPM_WriteString((CHAR*)"))", (LONGINT)3);
	OPM_WriteString((CHAR*)", ", (LONGINT)3);
	OPM_WriteInt(OPC_Base(base));
	OPM_WriteString((CHAR*)", ", (LONGINT)3);
	OPM_WriteInt(nofdim);
	OPM_WriteString((CHAR*)", ", (LONGINT)3);
	OPM_WriteInt(nofdyn);
	while (typ != base) {
		OPM_WriteString((CHAR*)", ", (LONGINT)3);
		if (typ->comp == 3) {
			if (x->class == 7) {
				OPM_WriteString((CHAR*)"(LONGINT)(", (LONGINT)11);
				OPV_expr(x, -1);
				OPM_WriteString((CHAR*)")", (LONGINT)2);
			} else {
				OPM_WriteString((CHAR*)"(LONGINT)", (LONGINT)10);
				OPV_expr(x, 10);
			}
			x = x->link;
		} else {
			OPM_WriteString((CHAR*)"(LONGINT)", (LONGINT)10);
			OPM_WriteInt(typ->n);
		}
		typ = typ->BaseTyp;
	}
	OPM_Write(')');
}

static void OPV_DefineTDescs (OPT_Node n)
{
	while ((n != NIL && n->class == 14)) {
		OPC_TDescDecl(n->typ);
		n = n->link;
	}
}

static void OPV_InitTDescs (OPT_Node n)
{
	while ((n != NIL && n->class == 14)) {
		OPC_InitTDesc(n->typ);
		n = n->link;
	}
}

static void OPV_stat (OPT_Node n, OPT_Object outerProc)
{
	OPT_Object proc = NIL;
	OPV_ExitInfo saved;
	OPT_Node l = NIL, r = NIL;
	while ((n != NIL && OPM_noerr)) {
		OPM_errpos = n->conval->intval;
		if (n->class != 14) {
			OPC_BegStat();
		}
		switch (n->class) {
			case 18: 
				if (n->obj == NIL) {
					OPM_level += 1;
					OPV_stat(n->left, outerProc);
					OPM_level -= 1;
					OPC_GenEnumPtrs(OPT_topScope->scope);
					OPV_DefineTDescs(n->right);
					OPC_EnterBody();
					OPV_InitTDescs(n->right);
					OPM_WriteString((CHAR*)"/* BEGIN */", (LONGINT)12);
					OPM_WriteLn();
					OPV_stat(n->right, outerProc);
					OPC_ExitBody();
				} else {
					proc = n->obj;
					OPC_TypeDefs(proc->scope->right, 0);
					if (!proc->scope->leaf) {
						OPC_DefineInter(proc);
					}
					OPM_level += 1;
					OPV_stat(n->left, proc);
					OPM_level -= 1;
					OPC_EnterProc(proc);
					OPV_stat(n->right, proc);
					OPC_ExitProc(proc, 1, OPV_ImplicitReturn(n->right));
				}
				break;
			case 14: 
				break;
			case 19: 
				switch (n->subcl) {
					case 0: 
						l = n->left;
						r = n->right;
						if (l->typ->comp == 2) {
							OPM_WriteString((CHAR*)"__MOVE(", (LONGINT)8);
							OPV_expr(r, -1);
							OPM_WriteString((CHAR*)", ", (LONGINT)3);
							OPV_expr(l, -1);
							OPM_WriteString((CHAR*)", ", (LONGINT)3);
							if (r->typ == OPT_stringtyp) {
								OPM_WriteInt(r->conval->intval2);
							} else {
								OPM_WriteInt(r->typ->size);
							}
							OPM_Write(')');
						} else {
							if ((((((l->typ->form == 13 && l->obj != NIL)) && l->obj->adr == 1)) && l->obj->mode == 1)) {
								l->obj->adr = 0;
								OPV_design(l, -1);
								l->obj->adr = 1;
								if (r->typ->form != 11) {
									OPM_WriteString((CHAR*)" = (void*)", (LONGINT)11);
								} else {
									OPM_WriteString((CHAR*)" = ", (LONGINT)4);
								}
							} else {
								OPV_design(l, -1);
								OPM_WriteString((CHAR*)" = ", (LONGINT)4);
							}
							if (l->typ == r->typ) {
								OPV_expr(r, -1);
							} else if ((((l->typ->form == 13 && r->typ->form != 11)) && l->typ->strobj != NIL)) {
								OPM_Write('(');
								OPC_Ident(l->typ->strobj);
								OPM_Write(')');
								OPV_expr(r, -1);
							} else if (l->typ->comp == 4) {
								OPM_WriteString((CHAR*)"*(", (LONGINT)3);
								OPC_Andent(l->typ);
								OPM_WriteString((CHAR*)"*)&", (LONGINT)4);
								OPV_expr(r, 9);
							} else {
								OPV_expr(r, -1);
							}
						}
						break;
					case 1: 
						if (n->left->typ->BaseTyp->comp == 4) {
							OPM_WriteString((CHAR*)"__NEW(", (LONGINT)7);
							OPV_design(n->left, -1);
							OPM_WriteString((CHAR*)", ", (LONGINT)3);
							OPC_Andent(n->left->typ->BaseTyp);
							OPM_WriteString((CHAR*)")", (LONGINT)2);
						} else if (__IN(n->left->typ->BaseTyp->comp, 0x0c)) {
							OPV_NewArr(n->left, n->right);
						}
						break;
					case 13: case 14: 
						OPV_expr(n->left, -1);
						OPC_Increment(n->subcl == 14);
						OPV_expr(n->right, -1);
						break;
					case 15: case 16: 
						OPV_expr(n->left, -1);
						OPC_SetInclude(n->subcl == 16);
						OPM_WriteString((CHAR*)"__SETOF(", (LONGINT)9);
						OPV_expr(n->right, -1);
						OPM_Write(')');
						break;
					case 18: 
						OPM_WriteString((CHAR*)"__COPY(", (LONGINT)8);
						OPV_expr(n->right, -1);
						OPM_WriteString((CHAR*)", ", (LONGINT)3);
						OPV_expr(n->left, -1);
						OPM_WriteString((CHAR*)", ", (LONGINT)3);
						OPV_Len(n->left, ((LONGINT)(0)));
						OPM_Write(')');
						break;
					case 31: 
						OPM_WriteString((CHAR*)"__MOVE(", (LONGINT)8);
						OPV_expr(n->right, -1);
						OPM_WriteString((CHAR*)", ", (LONGINT)3);
						OPV_expr(n->left, -1);
						OPM_WriteString((CHAR*)", ", (LONGINT)3);
						OPV_expr(n->right->link, -1);
						OPM_Write(')');
						break;
					case 24: 
						OPM_WriteString((CHAR*)"__GET(", (LONGINT)7);
						OPV_expr(n->right, -1);
						OPM_WriteString((CHAR*)", ", (LONGINT)3);
						OPV_expr(n->left, -1);
						OPM_WriteString((CHAR*)", ", (LONGINT)3);
						OPC_Ident(n->left->typ->strobj);
						OPM_Write(')');
						break;
					case 25: 
						OPM_WriteString((CHAR*)"__PUT(", (LONGINT)7);
						OPV_expr(n->left, -1);
						OPM_WriteString((CHAR*)", ", (LONGINT)3);
						OPV_expr(n->right, -1);
						OPM_WriteString((CHAR*)", ", (LONGINT)3);
						OPC_Ident(n->right->typ->strobj);
						OPM_Write(')');
						break;
					case 26: case 27: 
						OPM_err(200);
						break;
					case 30: 
						OPM_WriteString((CHAR*)"__SYSNEW(", (LONGINT)10);
						OPV_design(n->left, -1);
						OPM_WriteString((CHAR*)", ", (LONGINT)3);
						OPV_expr(n->right, -1);
						OPM_Write(')');
						break;
					default: 
						OPM_LogWStr((CHAR*)"unhandled case in OPV.expr, n^.subcl = ", (LONGINT)40);
						OPM_LogWNum(n->subcl, ((LONGINT)(0)));
						OPM_LogWLn();
						break;
				}
				break;
			case 13: 
				if ((n->left->obj != NIL && n->left->obj->mode == 13)) {
					if (n->left->subcl == 1) {
						proc = OPV_SuperProc(n);
					} else {
						OPM_WriteString((CHAR*)"__", (LONGINT)3);
						proc = OPC_BaseTProc(n->left->obj);
					}
					OPC_Ident(proc);
					n->obj = proc->link;
				} else if (n->left->class == 9) {
					OPV_design(n->left, 10);
				} else {
					OPV_design(n->left, 11);
				}
				OPV_ActualPar(n->right, n->obj);
				break;
			case 20: 
				if (n->subcl != 32) {
					OPV_IfStat(n, 0, outerProc);
				} else if (OPV_assert) {
					OPM_WriteString((CHAR*)"__ASSERT(", (LONGINT)10);
					OPV_expr(n->left->left->left, -1);
					OPM_WriteString((CHAR*)", ", (LONGINT)3);
					OPM_WriteInt(n->left->right->right->conval->intval);
					OPM_Write(')');
					OPC_EndStat();
				}
				break;
			case 21: 
				OPV_exit.level += 1;
				OPV_CaseStat(n, outerProc);
				OPV_exit.level -= 1;
				break;
			case 22: 
				OPV_exit.level += 1;
				OPM_WriteString((CHAR*)"while ", (LONGINT)7);
				OPV_expr(n->left, 12);
				OPM_Write(' ');
				OPC_BegBlk();
				OPV_stat(n->right, outerProc);
				OPC_EndBlk();
				OPV_exit.level -= 1;
				break;
			case 23: 
				OPV_exit.level += 1;
				OPM_WriteString((CHAR*)"do ", (LONGINT)4);
				OPC_BegBlk();
				OPV_stat(n->left, outerProc);
				OPC_EndBlk0();
				OPM_WriteString((CHAR*)" while (!", (LONGINT)10);
				OPV_expr(n->right, 9);
				OPM_Write(')');
				OPV_exit.level -= 1;
				break;
			case 24: 
				saved = OPV_exit;
				OPV_exit.level = 0;
				OPV_exit.label = -1;
				OPM_WriteString((CHAR*)"for (;;) ", (LONGINT)10);
				OPC_BegBlk();
				OPV_stat(n->left, outerProc);
				OPC_EndBlk();
				if (OPV_exit.label != -1) {
					OPC_BegStat();
					OPM_WriteString((CHAR*)"exit__", (LONGINT)7);
					OPM_WriteInt(OPV_exit.label);
					OPM_Write(':');
					OPC_EndStat();
				}
				OPV_exit = saved;
				break;
			case 25: 
				if (OPV_exit.level == 0) {
					OPM_WriteString((CHAR*)"break", (LONGINT)6);
				} else {
					if (OPV_exit.label == -1) {
						OPV_exit.label = OPV_nofExitLabels;
						OPV_nofExitLabels += 1;
					}
					OPM_WriteString((CHAR*)"goto exit__", (LONGINT)12);
					OPM_WriteInt(OPV_exit.label);
				}
				break;
			case 26: 
				if (OPM_level == 0) {
					if (OPV_mainprog) {
						OPM_WriteString((CHAR*)"__FINI", (LONGINT)7);
					} else {
						OPM_WriteString((CHAR*)"__ENDMOD", (LONGINT)9);
					}
				} else {
					if (n->left != NIL) {
						OPM_WriteString((CHAR*)"_o_result = ", (LONGINT)13);
						if ((n->left->typ->form == 13 && n->obj->typ != n->left->typ)) {
							OPM_WriteString((CHAR*)"(void*)", (LONGINT)8);
							OPV_expr(n->left, 10);
						} else {
							OPV_expr(n->left, -1);
						}
						OPM_WriteString((CHAR*)";", (LONGINT)2);
						OPM_WriteLn();
						OPC_BegStat();
						OPC_ExitProc(outerProc, 0, 0);
						OPM_WriteString((CHAR*)"return _o_result", (LONGINT)17);
					} else {
						OPM_WriteString((CHAR*)"return", (LONGINT)7);
					}
				}
				break;
			case 27: 
				OPV_IfStat(n, n->subcl == 0, outerProc);
				break;
			case 28: 
				OPC_Halt(n->right->conval->intval);
				break;
			default: 
				OPM_LogWStr((CHAR*)"unhandled case in OPV.expr, n^.class = ", (LONGINT)40);
				OPM_LogWNum(n->class, ((LONGINT)(0)));
				OPM_LogWLn();
				break;
		}
		if (!__IN(n->class, 0x09744000)) {
			OPC_EndStat();
		}
		n = n->link;
	}
}

void OPV_Module (OPT_Node prog)
{
	if (!OPV_mainprog) {
		OPC_GenHdr(prog->right);
		OPC_GenHdrIncludes();
	}
	OPC_GenBdy(prog->right);
	OPV_stat(prog, NIL);
}

__TDESC(OPV_ExitInfo, 1, 0) = {__TDFLDS("ExitInfo", 4), {-4}};

export void *OPV__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(OPC);
	__MODULE_IMPORT(OPM);
	__MODULE_IMPORT(OPS);
	__MODULE_IMPORT(OPT);
	__REGMOD("OPV", 0);
	__REGCMD("Init", OPV_Init);
	__INITYP(OPV_ExitInfo, OPV_ExitInfo, 0);
/* BEGIN */
	__ENDMOD;
}
