/* voc 1.95 [2016/08/30] for gcc LP64 on cygwin xtspkaSfF */
#include "SYSTEM.h"
#include "OPM.h"
#include "OPS.h"
#include "OPT.h"


export void (*OPB_typSize)(OPT_Struct);
static INTEGER OPB_exp;
static LONGINT OPB_maxExp;


export void OPB_Assign (OPT_Node *x, OPT_Node y);
static void OPB_BindNodes (SHORTINT class, OPT_Struct typ, OPT_Node *x, OPT_Node y);
static LONGINT OPB_BoolToInt (BOOLEAN b);
export void OPB_Call (OPT_Node *x, OPT_Node apar, OPT_Object fp);
static void OPB_CharToString (OPT_Node n);
static void OPB_CheckAssign (OPT_Struct x, OPT_Node ynode);
static void OPB_CheckLeaf (OPT_Node x, BOOLEAN dynArrToo);
export void OPB_CheckParameters (OPT_Object fp, OPT_Object ap, BOOLEAN checkNames);
static void OPB_CheckProc (OPT_Struct x, OPT_Object y);
static void OPB_CheckPtr (OPT_Node x, OPT_Node y);
static void OPB_CheckRealType (INTEGER f, INTEGER nr, OPT_Const x);
static void OPB_CheckReceiver (OPT_Node *x, OPT_Object fp);
static void OPB_ConstOp (INTEGER op, OPT_Node x, OPT_Node y);
export void OPB_Construct (SHORTINT class, OPT_Node *x, OPT_Node y);
static void OPB_Convert (OPT_Node *x, OPT_Struct typ);
export void OPB_DeRef (OPT_Node *x);
static void OPB_DynArrParCheck (OPT_Struct ftyp, OPT_Struct atyp, BOOLEAN fvarpar);
export OPT_Node OPB_EmptySet (void);
export void OPB_Enter (OPT_Node *procdec, OPT_Node stat, OPT_Object proc);
export void OPB_Field (OPT_Node *x, OPT_Object y);
export void OPB_In (OPT_Node *x, OPT_Node y);
export void OPB_Index (OPT_Node *x, OPT_Node y);
export void OPB_Inittd (OPT_Node *inittd, OPT_Node *last, OPT_Struct typ);
static BOOLEAN OPB_IntToBool (LONGINT i);
export void OPB_Link (OPT_Node *x, OPT_Node *last, OPT_Node y);
export void OPB_MOp (SHORTINT op, OPT_Node *x);
export OPT_Node OPB_NewBoolConst (BOOLEAN boolval);
export OPT_Node OPB_NewIntConst (LONGINT intval);
export OPT_Node OPB_NewLeaf (OPT_Object obj);
export OPT_Node OPB_NewRealConst (LONGREAL realval, OPT_Struct typ);
export OPT_Node OPB_NewString (OPS_String str, LONGINT len);
export OPT_Node OPB_Nil (void);
static BOOLEAN OPB_NotVar (OPT_Node x);
export void OPB_Op (SHORTINT op, OPT_Node *x, OPT_Node y);
export void OPB_OptIf (OPT_Node *x);
export void OPB_Param (OPT_Node ap, OPT_Object fp);
export void OPB_PrepCall (OPT_Node *x, OPT_Object *fpar);
export void OPB_Return (OPT_Node *x, OPT_Object proc);
export void OPB_SetElem (OPT_Node *x);
static void OPB_SetIntType (OPT_Node node);
export void OPB_SetRange (OPT_Node *x, OPT_Node y);
export void OPB_StFct (OPT_Node *par0, SHORTINT fctno, INTEGER parno);
export void OPB_StPar0 (OPT_Node *par0, INTEGER fctno);
export void OPB_StPar1 (OPT_Node *par0, OPT_Node x, SHORTINT fctno);
export void OPB_StParN (OPT_Node *par0, OPT_Node x, INTEGER fctno, INTEGER n);
export void OPB_StaticLink (SHORTINT dlev);
export void OPB_TypTest (OPT_Node *x, OPT_Object obj, BOOLEAN guard);
static void OPB_err (INTEGER n);
static LONGINT OPB_log (LONGINT x);


static void OPB_err (INTEGER n)
{
	OPM_err(n);
}

OPT_Node OPB_NewLeaf (OPT_Object obj)
{
	OPT_Node _o_result;
	OPT_Node node = NIL;
	switch (obj->mode) {
		case 1: 
			node = OPT_NewNode(0);
			node->readonly = (obj->vis == 2 && obj->mnolev < 0);
			break;
		case 2: 
			node = OPT_NewNode(1);
			break;
		case 3: 
			node = OPT_NewNode(7);
			node->conval = OPT_NewConst();
			__GUARDEQP(node->conval, OPT_ConstDesc) = *obj->conval;
			break;
		case 5: 
			node = OPT_NewNode(8);
			break;
		case 6: case 7: case 8: case 9: case 10: 
			node = OPT_NewNode(9);
			break;
		default: 
			node = OPT_NewNode(0);
			OPB_err(127);
			break;
	}
	node->obj = obj;
	node->typ = obj->typ;
	_o_result = node;
	return _o_result;
}

void OPB_Construct (SHORTINT class, OPT_Node *x, OPT_Node y)
{
	OPT_Node node = NIL;
	node = OPT_NewNode(class);
	node->typ = OPT_notyp;
	node->left = *x;
	node->right = y;
	*x = node;
}

void OPB_Link (OPT_Node *x, OPT_Node *last, OPT_Node y)
{
	if (*x == NIL) {
		*x = y;
	} else {
		(*last)->link = y;
	}
	while (y->link != NIL) {
		y = y->link;
	}
	*last = y;
}

static LONGINT OPB_BoolToInt (BOOLEAN b)
{
	LONGINT _o_result;
	if (b) {
		_o_result = 1;
		return _o_result;
	} else {
		_o_result = 0;
		return _o_result;
	}
	__RETCHK;
}

static BOOLEAN OPB_IntToBool (LONGINT i)
{
	BOOLEAN _o_result;
	if (i == 0) {
		_o_result = 0;
		return _o_result;
	} else {
		_o_result = 1;
		return _o_result;
	}
	__RETCHK;
}

OPT_Node OPB_NewBoolConst (BOOLEAN boolval)
{
	OPT_Node _o_result;
	OPT_Node x = NIL;
	x = OPT_NewNode(7);
	x->typ = OPT_booltyp;
	x->conval = OPT_NewConst();
	x->conval->intval = OPB_BoolToInt(boolval);
	_o_result = x;
	return _o_result;
}

void OPB_OptIf (OPT_Node *x)
{
	OPT_Node if_ = NIL, pred = NIL;
	if_ = (*x)->left;
	while (if_->left->class == 7) {
		if (OPB_IntToBool(if_->left->conval->intval)) {
			*x = if_->right;
			return;
		} else if (if_->link == NIL) {
			*x = (*x)->right;
			return;
		} else {
			if_ = if_->link;
			(*x)->left = if_;
		}
	}
	pred = if_;
	if_ = if_->link;
	while (if_ != NIL) {
		if (if_->left->class == 7) {
			if (OPB_IntToBool(if_->left->conval->intval)) {
				pred->link = NIL;
				(*x)->right = if_->right;
				return;
			} else {
				if_ = if_->link;
				pred->link = if_;
			}
		} else {
			pred = if_;
			if_ = if_->link;
		}
	}
}

OPT_Node OPB_Nil (void)
{
	OPT_Node _o_result;
	OPT_Node x = NIL;
	x = OPT_NewNode(7);
	x->typ = OPT_niltyp;
	x->conval = OPT_NewConst();
	x->conval->intval = 0;
	_o_result = x;
	return _o_result;
}

OPT_Node OPB_EmptySet (void)
{
	OPT_Node _o_result;
	OPT_Node x = NIL;
	x = OPT_NewNode(7);
	x->typ = OPT_settyp;
	x->conval = OPT_NewConst();
	x->conval->setval = 0x0;
	_o_result = x;
	return _o_result;
}

static void OPB_SetIntType (OPT_Node node)
{
	INTEGER b;
	LONGINT n;
	if (node->conval->intval >= 0) {
		n = node->conval->intval;
	} else {
		n = -(node->conval->intval + 1);
	}
	b = 1;
	while ((b < 8 && __ASH(n, -(__ASHL(b, 3) - 1)) != 0)) {
		b += 1;
	}
	node->typ = OPT_IntType(b);
}

OPT_Node OPB_NewIntConst (LONGINT intval)
{
	OPT_Node _o_result;
	OPT_Node x = NIL;
	x = OPT_NewNode(7);
	x->conval = OPT_NewConst();
	x->conval->intval = intval;
	OPB_SetIntType(x);
	_o_result = x;
	return _o_result;
}

OPT_Node OPB_NewRealConst (LONGREAL realval, OPT_Struct typ)
{
	OPT_Node _o_result;
	OPT_Node x = NIL;
	x = OPT_NewNode(7);
	x->conval = OPT_NewConst();
	x->conval->realval = realval;
	x->typ = typ;
	x->conval->intval = -1;
	_o_result = x;
	return _o_result;
}

OPT_Node OPB_NewString (OPS_String str, LONGINT len)
{
	OPT_Node _o_result;
	OPT_Node x = NIL;
	x = OPT_NewNode(7);
	x->conval = OPT_NewConst();
	x->typ = OPT_stringtyp;
	x->conval->intval = -1;
	x->conval->intval2 = len;
	x->conval->ext = OPT_NewExt();
	__COPY(str, *x->conval->ext, ((LONGINT)(256)));
	_o_result = x;
	return _o_result;
}

static void OPB_CharToString (OPT_Node n)
{
	CHAR ch;
	n->typ = OPT_stringtyp;
	ch = (CHAR)n->conval->intval;
	n->conval->ext = OPT_NewExt();
	if (ch == 0x00) {
		n->conval->intval2 = 1;
	} else {
		n->conval->intval2 = 2;
		(*n->conval->ext)[1] = 0x00;
	}
	(*n->conval->ext)[0] = ch;
	n->conval->intval = -1;
	n->obj = NIL;
}

static void OPB_BindNodes (SHORTINT class, OPT_Struct typ, OPT_Node *x, OPT_Node y)
{
	OPT_Node node = NIL;
	node = OPT_NewNode(class);
	node->typ = typ;
	node->left = *x;
	node->right = y;
	*x = node;
}

static BOOLEAN OPB_NotVar (OPT_Node x)
{
	BOOLEAN _o_result;
	_o_result = (x->class >= 7 && ((x->class != 11 || x->subcl != 29) || x->left->class >= 7));
	return _o_result;
}

void OPB_DeRef (OPT_Node *x)
{
	OPT_Object strobj = NIL, bstrobj = NIL;
	OPT_Struct typ = NIL, btyp = NIL;
	typ = (*x)->typ;
	if ((*x)->class >= 7) {
		OPB_err(78);
	} else if (typ->form == 13) {
		if (typ == OPT_sysptrtyp) {
			OPB_err(57);
		}
		btyp = typ->BaseTyp;
		strobj = typ->strobj;
		bstrobj = btyp->strobj;
		if ((((((strobj != NIL && strobj->name[0] != 0x00)) && bstrobj != NIL)) && bstrobj->name[0] != 0x00)) {
			btyp->pbused = 1;
		}
		OPB_BindNodes(3, btyp, &*x, NIL);
	} else {
		OPB_err(84);
	}
}

void OPB_Index (OPT_Node *x, OPT_Node y)
{
	INTEGER f;
	OPT_Struct typ = NIL;
	f = y->typ->form;
	if ((*x)->class >= 7) {
		OPB_err(79);
	} else if (!__IN(f, 0x70) || __IN(y->class, 0x0300)) {
		OPB_err(80);
		y->typ = OPT_inttyp;
	}
	if ((*x)->typ->comp == 2) {
		typ = (*x)->typ->BaseTyp;
		if ((y->class == 7 && (y->conval->intval < 0 || y->conval->intval >= (*x)->typ->n))) {
			OPB_err(81);
		}
	} else if ((*x)->typ->comp == 3) {
		typ = (*x)->typ->BaseTyp;
		if ((y->class == 7 && y->conval->intval < 0)) {
			OPB_err(81);
		}
	} else {
		OPB_err(82);
		typ = OPT_undftyp;
	}
	OPB_BindNodes(4, typ, &*x, y);
	(*x)->readonly = (*x)->left->readonly;
}

void OPB_Field (OPT_Node *x, OPT_Object y)
{
	if ((*x)->class >= 7) {
		OPB_err(77);
	}
	if ((y != NIL && __IN(y->mode, 0x2010))) {
		OPB_BindNodes(2, y->typ, &*x, NIL);
		(*x)->obj = y;
		(*x)->readonly = (*x)->left->readonly || (y->vis == 2 && y->mnolev < 0);
	} else {
		OPB_err(83);
		(*x)->typ = OPT_undftyp;
	}
}

static struct TypTest__57 {
	OPT_Node *x;
	OPT_Object *obj;
	BOOLEAN *guard;
	struct TypTest__57 *lnk;
} *TypTest__57_s;

static void GTT__58 (OPT_Struct t0, OPT_Struct t1);

static void GTT__58 (OPT_Struct t0, OPT_Struct t1)
{
	OPT_Node node = NIL;
	OPT_Struct t = NIL;
	t = t0;
	while ((((t != NIL && t != t1)) && t != OPT_undftyp)) {
		t = t->BaseTyp;
	}
	if (t != t1) {
		while ((((t1 != NIL && t1 != t0)) && t1 != OPT_undftyp)) {
			t1 = t1->BaseTyp;
		}
		if (t1 == t0 || t0->form == 0) {
			if (*TypTest__57_s->guard) {
				OPB_BindNodes(5, NIL, &*TypTest__57_s->x, NIL);
				(*TypTest__57_s->x)->readonly = (*TypTest__57_s->x)->left->readonly;
			} else {
				node = OPT_NewNode(11);
				node->subcl = 16;
				node->left = *TypTest__57_s->x;
				node->obj = *TypTest__57_s->obj;
				*TypTest__57_s->x = node;
			}
		} else {
			OPB_err(85);
		}
	} else if (t0 != t1) {
		OPB_err(85);
	} else if (!*TypTest__57_s->guard) {
		if ((*TypTest__57_s->x)->class == 5) {
			node = OPT_NewNode(11);
			node->subcl = 16;
			node->left = *TypTest__57_s->x;
			node->obj = *TypTest__57_s->obj;
			*TypTest__57_s->x = node;
		} else {
			*TypTest__57_s->x = OPB_NewBoolConst(1);
		}
	}
}

void OPB_TypTest (OPT_Node *x, OPT_Object obj, BOOLEAN guard)
{
	struct TypTest__57 _s;
	_s.x = x;
	_s.obj = &obj;
	_s.guard = &guard;
	_s.lnk = TypTest__57_s;
	TypTest__57_s = &_s;
	if (OPB_NotVar(*x)) {
		OPB_err(112);
	} else if ((*x)->typ->form == 13) {
		if (((*x)->typ->BaseTyp->comp != 4 && (*x)->typ != OPT_sysptrtyp)) {
			OPB_err(85);
		} else if (obj->typ->form == 13) {
			GTT__58((*x)->typ->BaseTyp, obj->typ->BaseTyp);
		} else {
			OPB_err(86);
		}
	} else if (((((*x)->typ->comp == 4 && (*x)->class == 1)) && obj->typ->comp == 4)) {
		GTT__58((*x)->typ, obj->typ);
	} else {
		OPB_err(87);
	}
	if (guard) {
		(*x)->typ = obj->typ;
	} else {
		(*x)->typ = OPT_booltyp;
	}
	TypTest__57_s = _s.lnk;
}

void OPB_In (OPT_Node *x, OPT_Node y)
{
	INTEGER f;
	LONGINT k;
	f = (*x)->typ->form;
	if ((((*x)->class == 8 || (*x)->class == 9) || y->class == 8) || y->class == 9) {
		OPB_err(126);
	} else if ((__IN(f, 0x70) && y->typ->form == 9)) {
		if ((*x)->class == 7) {
			k = (*x)->conval->intval;
			if (k < 0 || k > (int)OPM_MaxSet) {
				OPB_err(202);
			} else if (y->class == 7) {
				(*x)->conval->intval = OPB_BoolToInt(__IN(k, y->conval->setval));
				(*x)->obj = NIL;
			} else {
				OPB_BindNodes(12, OPT_booltyp, &*x, y);
				(*x)->subcl = 15;
			}
		} else {
			OPB_BindNodes(12, OPT_booltyp, &*x, y);
			(*x)->subcl = 15;
		}
	} else {
		OPB_err(92);
	}
	(*x)->typ = OPT_booltyp;
}

static LONGINT OPB_log (LONGINT x)
{
	LONGINT _o_result;
	OPB_exp = 0;
	if (x > 0) {
		while (!__ODD(x)) {
			x = __ASHR(x, 1);
			OPB_exp += 1;
		}
	}
	_o_result = x;
	return _o_result;
}

static void OPB_CheckRealType (INTEGER f, INTEGER nr, OPT_Const x)
{
	LONGREAL min, max, r;
	if (f == 7) {
		min = OPM_MinReal;
		max = OPM_MaxReal;
	} else {
		min = OPM_MinLReal;
		max = OPM_MaxLReal;
	}
	r = __ABS(x->realval);
	if (r > max || r < min) {
		OPB_err(nr);
		x->realval = (LONGREAL)1;
	} else if (f == 7) {
		x->realval = x->realval;
	}
	x->intval = -1;
}

static struct MOp__28 {
	struct MOp__28 *lnk;
} *MOp__28_s;

static OPT_Node NewOp__29 (SHORTINT op, OPT_Struct typ, OPT_Node z);

static OPT_Node NewOp__29 (SHORTINT op, OPT_Struct typ, OPT_Node z)
{
	OPT_Node _o_result;
	OPT_Node node = NIL;
	node = OPT_NewNode(11);
	node->subcl = op;
	node->typ = typ;
	node->left = z;
	_o_result = node;
	return _o_result;
}

void OPB_MOp (SHORTINT op, OPT_Node *x)
{
	INTEGER f;
	OPT_Struct typ = NIL;
	OPT_Node z = NIL;
	struct MOp__28 _s;
	_s.lnk = MOp__28_s;
	MOp__28_s = &_s;
	z = *x;
	if (z->class == 8 || z->class == 9) {
		OPB_err(126);
	} else {
		typ = z->typ;
		f = typ->form;
		switch (op) {
			case 33: 
				if (f == 2) {
					if (z->class == 7) {
						z->conval->intval = OPB_BoolToInt(!OPB_IntToBool(z->conval->intval));
						z->obj = NIL;
					} else {
						z = NewOp__29(op, typ, z);
					}
				} else {
					OPB_err(98);
				}
				break;
			case 6: 
				if (!__IN(f, 0x01f0)) {
					OPB_err(96);
				}
				break;
			case 7: 
				if (__IN(f, 0x03f0)) {
					if (z->class == 7) {
						if (__IN(f, 0x70)) {
							if (z->conval->intval == (-2147483647-1)) {
								OPB_err(203);
							} else {
								z->conval->intval = -z->conval->intval;
								OPB_SetIntType(z);
							}
						} else if (__IN(f, 0x0180)) {
							z->conval->realval = -z->conval->realval;
						} else {
							z->conval->setval = ~z->conval->setval;
						}
						z->obj = NIL;
					} else {
						z = NewOp__29(op, typ, z);
					}
				} else {
					OPB_err(97);
				}
				break;
			case 21: 
				if (__IN(f, 0x01f0)) {
					if (z->class == 7) {
						if (__IN(f, 0x70)) {
							if (z->conval->intval == (-2147483647-1)) {
								OPB_err(203);
							} else {
								z->conval->intval = __ABS(z->conval->intval);
								OPB_SetIntType(z);
							}
						} else {
							z->conval->realval = __ABS(z->conval->realval);
						}
						z->obj = NIL;
					} else {
						z = NewOp__29(op, typ, z);
					}
				} else {
					OPB_err(111);
				}
				break;
			case 22: 
				if (f == 3) {
					if (z->class == 7) {
						z->conval->intval = (int)__CAP((CHAR)z->conval->intval);
						z->obj = NIL;
					} else {
						z = NewOp__29(op, typ, z);
					}
				} else {
					OPB_err(111);
					z->typ = OPT_chartyp;
				}
				break;
			case 23: 
				if (__IN(f, 0x70)) {
					if (z->class == 7) {
						z->conval->intval = OPB_BoolToInt(__ODD(z->conval->intval));
						z->obj = NIL;
					} else {
						z = NewOp__29(op, typ, z);
					}
				} else {
					OPB_err(111);
				}
				z->typ = OPT_booltyp;
				break;
			case 24: 
				if ((((z->class == 7 && f == 3)) && z->conval->intval >= 32)) {
					OPB_CharToString(z);
					f = 10;
				}
				if (z->class < 7 || f == 10) {
					z = NewOp__29(op, typ, z);
				} else {
					OPB_err(127);
				}
				z->typ = OPT_linttyp;
				break;
			case 25: 
				if ((__IN(f, 0x70) && z->class == 7)) {
					if ((0 <= z->conval->intval && z->conval->intval <= -1)) {
						z = NewOp__29(op, typ, z);
					} else {
						OPB_err(219);
					}
				} else {
					OPB_err(69);
				}
				z->typ = OPT_booltyp;
				break;
			default: 
				OPM_LogWStr((CHAR*)"unhandled case in OPB.MOp, op = ", (LONGINT)33);
				OPM_LogWNum(op, ((LONGINT)(0)));
				OPM_LogWLn();
				break;
		}
	}
	*x = z;
	MOp__28_s = _s.lnk;
}

static void OPB_CheckPtr (OPT_Node x, OPT_Node y)
{
	INTEGER g;
	OPT_Struct p = NIL, q = NIL, t = NIL;
	g = y->typ->form;
	if (g == 13) {
		p = x->typ->BaseTyp;
		q = y->typ->BaseTyp;
		if ((p->comp == 4 && q->comp == 4)) {
			if (p->extlev < q->extlev) {
				t = p;
				p = q;
				q = t;
			}
			while ((((p != q && p != NIL)) && p != OPT_undftyp)) {
				p = p->BaseTyp;
			}
			if (p == NIL) {
				OPB_err(100);
			}
		} else {
			OPB_err(100);
		}
	} else if (g != 11) {
		OPB_err(100);
	}
}

void OPB_CheckParameters (OPT_Object fp, OPT_Object ap, BOOLEAN checkNames)
{
	OPT_Struct ft = NIL, at = NIL;
	while (fp != NIL) {
		if (ap != NIL) {
			ft = fp->typ;
			at = ap->typ;
			while ((ft->comp == 3 && at->comp == 3)) {
				ft = ft->BaseTyp;
				at = at->BaseTyp;
			}
			if (ft != at) {
				if ((ft->form == 14 && at->form == 14)) {
					if (ft->BaseTyp == at->BaseTyp) {
						OPB_CheckParameters(ft->link, at->link, 0);
					} else {
						OPB_err(117);
					}
				} else {
					OPB_err(115);
				}
			}
			if (fp->mode != ap->mode || (checkNames && __STRCMP(fp->name, ap->name) != 0)) {
				OPB_err(115);
			}
			ap = ap->link;
		} else {
			OPB_err(116);
		}
		fp = fp->link;
	}
	if (ap != NIL) {
		OPB_err(116);
	}
}

static void OPB_CheckProc (OPT_Struct x, OPT_Object y)
{
	if (__IN(y->mode, 0x04c0)) {
		if (y->mode == 6) {
			if (y->mnolev == 0) {
				y->mode = 7;
			} else {
				OPB_err(73);
			}
		}
		if (x->BaseTyp == y->typ) {
			OPB_CheckParameters(x->link, y->link, 0);
		} else {
			OPB_err(117);
		}
	} else {
		OPB_err(113);
	}
}

static struct ConstOp__13 {
	OPT_Node *x;
	INTEGER *f;
	OPT_Const *xval, *yval;
	struct ConstOp__13 *lnk;
} *ConstOp__13_s;

static INTEGER ConstCmp__14 (void);

static INTEGER ConstCmp__14 (void)
{
	INTEGER _o_result;
	INTEGER res;
	switch (*ConstOp__13_s->f) {
		case 0: 
			res = 9;
			break;
		case 1: case 3: case 4: case 5: case 6: 
			if ((*ConstOp__13_s->xval)->intval < (*ConstOp__13_s->yval)->intval) {
				res = 11;
			} else if ((*ConstOp__13_s->xval)->intval > (*ConstOp__13_s->yval)->intval) {
				res = 13;
			} else {
				res = 9;
			}
			break;
		case 7: case 8: 
			if ((*ConstOp__13_s->xval)->realval < (*ConstOp__13_s->yval)->realval) {
				res = 11;
			} else if ((*ConstOp__13_s->xval)->realval > (*ConstOp__13_s->yval)->realval) {
				res = 13;
			} else {
				res = 9;
			}
			break;
		case 2: 
			if ((*ConstOp__13_s->xval)->intval != (*ConstOp__13_s->yval)->intval) {
				res = 10;
			} else {
				res = 9;
			}
			break;
		case 9: 
			if ((*ConstOp__13_s->xval)->setval != (*ConstOp__13_s->yval)->setval) {
				res = 10;
			} else {
				res = 9;
			}
			break;
		case 10: 
			if (__STRCMP(*(*ConstOp__13_s->xval)->ext, *(*ConstOp__13_s->yval)->ext) < 0) {
				res = 11;
			} else if (__STRCMP(*(*ConstOp__13_s->xval)->ext, *(*ConstOp__13_s->yval)->ext) > 0) {
				res = 13;
			} else {
				res = 9;
			}
			break;
		case 11: case 13: case 14: 
			if ((*ConstOp__13_s->xval)->intval != (*ConstOp__13_s->yval)->intval) {
				res = 10;
			} else {
				res = 9;
			}
			break;
		default: 
			OPM_LogWStr((CHAR*)"unhandled case in OPB.ConstCmp, f = ", (LONGINT)37);
			OPM_LogWNum(*ConstOp__13_s->f, ((LONGINT)(0)));
			OPM_LogWLn();
			break;
	}
	(*ConstOp__13_s->x)->typ = OPT_booltyp;
	_o_result = res;
	return _o_result;
}

static void OPB_ConstOp (INTEGER op, OPT_Node x, OPT_Node y)
{
	INTEGER f, g;
	OPT_Const xval = NIL, yval = NIL;
	LONGINT xv, yv;
	BOOLEAN temp;
	struct ConstOp__13 _s;
	_s.x = &x;
	_s.f = &f;
	_s.xval = &xval;
	_s.yval = &yval;
	_s.lnk = ConstOp__13_s;
	ConstOp__13_s = &_s;
	f = x->typ->form;
	g = y->typ->form;
	xval = x->conval;
	yval = y->conval;
	if (f != g) {
		switch (f) {
			case 3: 
				if (g == 10) {
					OPB_CharToString(x);
				} else {
					OPB_err(100);
					y->typ = x->typ;
					__GUARDEQP(yval, OPT_ConstDesc) = *xval;
				}
				break;
			case 4: case 5: case 6: 
				if (__IN(g, 0x70)) {
					if (x->typ->size <= y->typ->size) {
						x->typ = y->typ;
					} else {
						x->typ = OPT_IntType(x->typ->size);
					}
				} else if (g == 7) {
					x->typ = OPT_realtyp;
					xval->realval = xval->intval;
				} else if (g == 8) {
					x->typ = OPT_lrltyp;
					xval->realval = xval->intval;
				} else {
					OPB_err(100);
					y->typ = x->typ;
					__GUARDEQP(yval, OPT_ConstDesc) = *xval;
				}
				break;
			case 7: 
				if (__IN(g, 0x70)) {
					y->typ = x->typ;
					yval->realval = yval->intval;
				} else if (g == 8) {
					x->typ = OPT_lrltyp;
				} else {
					OPB_err(100);
					y->typ = x->typ;
					__GUARDEQP(yval, OPT_ConstDesc) = *xval;
				}
				break;
			case 8: 
				if (__IN(g, 0x70)) {
					y->typ = x->typ;
					yval->realval = yval->intval;
				} else if (g == 7) {
					y->typ = OPT_lrltyp;
				} else {
					OPB_err(100);
					y->typ = x->typ;
					__GUARDEQP(yval, OPT_ConstDesc) = *xval;
				}
				break;
			case 10: 
				if (g == 3) {
					OPB_CharToString(y);
					g = 10;
				} else {
					OPB_err(100);
					y->typ = x->typ;
					__GUARDEQP(yval, OPT_ConstDesc) = *xval;
				}
				break;
			case 11: 
				if (!__IN(g, 0x6000)) {
					OPB_err(100);
				}
				break;
			case 13: 
				OPB_CheckPtr(x, y);
				break;
			case 14: 
				if (g != 11) {
					OPB_err(100);
				}
				break;
			default: 
				OPB_err(100);
				y->typ = x->typ;
				__GUARDEQP(yval, OPT_ConstDesc) = *xval;
				break;
		}
		f = x->typ->form;
	}
	switch (op) {
		case 1: 
			if (__IN(f, 0x70)) {
				xv = xval->intval;
				yv = yval->intval;
				if (((((xv == 0 || yv == 0) || (((xv > 0 && yv > 0)) && yv <= __DIV(2147483647, xv))) || (((xv > 0 && yv < 0)) && yv >= __DIV((-2147483647-1), xv))) || (((xv < 0 && yv > 0)) && xv >= __DIV((-2147483647-1), yv))) || (((((((xv < 0 && yv < 0)) && xv != (-2147483647-1))) && yv != (-2147483647-1))) && -xv <= __DIV(2147483647, -yv))) {
					xval->intval = xv * yv;
					OPB_SetIntType(x);
				} else {
					OPB_err(204);
				}
			} else if (__IN(f, 0x0180)) {
				temp = __ABS(yval->realval) <= (LONGREAL)1;
				if (temp || __ABS(xval->realval) <=   1.79769296342094e+308 / (LONGREAL)__ABS(yval->realval)) {
					xval->realval = xval->realval * yval->realval;
					OPB_CheckRealType(f, 204, xval);
				} else {
					OPB_err(204);
				}
			} else if (f == 9) {
				xval->setval = (xval->setval & yval->setval);
			} else if (f != 0) {
				OPB_err(101);
			}
			break;
		case 2: 
			if (__IN(f, 0x70)) {
				if (yval->intval != 0) {
					xval->realval = xval->intval / (REAL)yval->intval;
					OPB_CheckRealType(7, 205, xval);
				} else {
					OPB_err(205);
					xval->realval = (LONGREAL)1;
				}
				x->typ = OPT_realtyp;
			} else if (__IN(f, 0x0180)) {
				temp = __ABS(yval->realval) >= (LONGREAL)1;
				if (temp || __ABS(xval->realval) <=   1.79769296342094e+308 * __ABS(yval->realval)) {
					xval->realval = xval->realval / yval->realval;
					OPB_CheckRealType(f, 205, xval);
				} else {
					OPB_err(205);
				}
			} else if (f == 9) {
				xval->setval = xval->setval ^ yval->setval;
			} else if (f != 0) {
				OPB_err(102);
			}
			break;
		case 3: 
			if (__IN(f, 0x70)) {
				if (yval->intval != 0) {
					xval->intval = __DIV(xval->intval, yval->intval);
					OPB_SetIntType(x);
				} else {
					OPB_err(205);
				}
			} else if (f != 0) {
				OPB_err(103);
			}
			break;
		case 4: 
			if (__IN(f, 0x70)) {
				if (yval->intval != 0) {
					xval->intval = __MOD(xval->intval, yval->intval);
					OPB_SetIntType(x);
				} else {
					OPB_err(205);
				}
			} else if (f != 0) {
				OPB_err(104);
			}
			break;
		case 5: 
			if (f == 2) {
				xval->intval = OPB_BoolToInt((OPB_IntToBool(xval->intval) && OPB_IntToBool(yval->intval)));
			} else {
				OPB_err(94);
			}
			break;
		case 6: 
			if (__IN(f, 0x70)) {
				temp = (yval->intval >= 0 && xval->intval <= 2147483647 - yval->intval);
				if (temp || (yval->intval < 0 && xval->intval >= (-2147483647-1) - yval->intval)) {
					xval->intval += yval->intval;
					OPB_SetIntType(x);
				} else {
					OPB_err(206);
				}
			} else if (__IN(f, 0x0180)) {
				temp = (yval->realval >= (LONGREAL)0 && xval->realval <=   1.79769296342094e+308 - yval->realval);
				if (temp || (yval->realval < (LONGREAL)0 && xval->realval >=  -1.79769296342094e+308 - yval->realval)) {
					xval->realval = xval->realval + yval->realval;
					OPB_CheckRealType(f, 206, xval);
				} else {
					OPB_err(206);
				}
			} else if (f == 9) {
				xval->setval = xval->setval | yval->setval;
			} else if (f != 0) {
				OPB_err(105);
			}
			break;
		case 7: 
			if (__IN(f, 0x70)) {
				if ((yval->intval >= 0 && xval->intval >= (-2147483647-1) + yval->intval) || (yval->intval < 0 && xval->intval <= 2147483647 + yval->intval)) {
					xval->intval -= yval->intval;
					OPB_SetIntType(x);
				} else {
					OPB_err(207);
				}
			} else if (__IN(f, 0x0180)) {
				temp = (yval->realval >= (LONGREAL)0 && xval->realval >=  -1.79769296342094e+308 + yval->realval);
				if (temp || (yval->realval < (LONGREAL)0 && xval->realval <=   1.79769296342094e+308 + yval->realval)) {
					xval->realval = xval->realval - yval->realval;
					OPB_CheckRealType(f, 207, xval);
				} else {
					OPB_err(207);
				}
			} else if (f == 9) {
				xval->setval = (xval->setval & ~yval->setval);
			} else if (f != 0) {
				OPB_err(106);
			}
			break;
		case 8: 
			if (f == 2) {
				xval->intval = OPB_BoolToInt(OPB_IntToBool(xval->intval) || OPB_IntToBool(yval->intval));
			} else {
				OPB_err(95);
			}
			break;
		case 9: 
			xval->intval = OPB_BoolToInt(ConstCmp__14() == 9);
			break;
		case 10: 
			xval->intval = OPB_BoolToInt(ConstCmp__14() != 9);
			break;
		case 11: 
			if (__IN(f, 0x2a04)) {
				OPB_err(108);
			} else {
				xval->intval = OPB_BoolToInt(ConstCmp__14() == 11);
			}
			break;
		case 12: 
			if (__IN(f, 0x2a04)) {
				OPB_err(108);
			} else {
				xval->intval = OPB_BoolToInt(ConstCmp__14() != 13);
			}
			break;
		case 13: 
			if (__IN(f, 0x2a04)) {
				OPB_err(108);
			} else {
				xval->intval = OPB_BoolToInt(ConstCmp__14() == 13);
			}
			break;
		case 14: 
			if (__IN(f, 0x2a04)) {
				OPB_err(108);
			} else {
				xval->intval = OPB_BoolToInt(ConstCmp__14() != 11);
			}
			break;
		default: 
			OPM_LogWStr((CHAR*)"unhandled case in OPB.ConstOp, op = ", (LONGINT)37);
			OPM_LogWNum(op, ((LONGINT)(0)));
			OPM_LogWLn();
			break;
	}
	ConstOp__13_s = _s.lnk;
}

static void OPB_Convert (OPT_Node *x, OPT_Struct typ)
{
	OPT_Node node = NIL;
	INTEGER f, g;
	LONGINT k;
	LONGREAL r;
	f = (*x)->typ->form;
	g = typ->form;
	if ((*x)->class == 7) {
		if (__IN(f, 0x70)) {
			if (__IN(g, 0x70)) {
				if (f > g) {
					OPB_SetIntType(*x);
					if ((*x)->typ->size > typ->size) {
						OPB_err(203);
						(*x)->conval->intval = 1;
					}
				}
			} else if (__IN(g, 0x0180)) {
				(*x)->conval->realval = (*x)->conval->intval;
				(*x)->conval->intval = -1;
			} else {
				k = (*x)->conval->intval;
				if (0 > k || k > 255) {
					OPB_err(220);
				}
			}
		} else if (__IN(f, 0x0180)) {
			if (__IN(g, 0x0180)) {
				OPB_CheckRealType(g, 203, (*x)->conval);
			} else {
				r = (*x)->conval->realval;
				if (r <  -2.14748364800000e+009 || r >   2.14748364700000e+009) {
					OPB_err(203);
					r = (LONGREAL)1;
				}
				(*x)->conval->intval = (int)__ENTIER(r);
				OPB_SetIntType(*x);
			}
		}
		(*x)->obj = NIL;
	} else if (((((*x)->class == 11 && (*x)->subcl == 20)) && ((int)(*x)->left->typ->form < f || f > g))) {
		if ((*x)->left->typ == typ) {
			*x = (*x)->left;
		}
	} else {
		node = OPT_NewNode(11);
		node->subcl = 20;
		node->left = *x;
		*x = node;
	}
	(*x)->typ = typ;
}

static struct Op__38 {
	INTEGER *f, *g;
	struct Op__38 *lnk;
} *Op__38_s;

static void NewOp__39 (SHORTINT op, OPT_Struct typ, OPT_Node *x, OPT_Node y);
static BOOLEAN strings__41 (OPT_Node *x, OPT_Node *y);

static void NewOp__39 (SHORTINT op, OPT_Struct typ, OPT_Node *x, OPT_Node y)
{
	OPT_Node node = NIL;
	node = OPT_NewNode(12);
	node->subcl = op;
	node->typ = typ;
	node->left = *x;
	node->right = y;
	*x = node;
}

static BOOLEAN strings__41 (OPT_Node *x, OPT_Node *y)
{
	BOOLEAN _o_result;
	BOOLEAN ok, xCharArr, yCharArr;
	xCharArr = (__IN((*x)->typ->comp, 0x0c) && (*x)->typ->BaseTyp->form == 3) || *Op__38_s->f == 10;
	yCharArr = (__IN((*y)->typ->comp, 0x0c) && (*y)->typ->BaseTyp->form == 3) || *Op__38_s->g == 10;
	if ((((xCharArr && *Op__38_s->g == 3)) && (*y)->class == 7)) {
		OPB_CharToString(*y);
		*Op__38_s->g = 10;
		yCharArr = 1;
	}
	if ((((yCharArr && *Op__38_s->f == 3)) && (*x)->class == 7)) {
		OPB_CharToString(*x);
		*Op__38_s->f = 10;
		xCharArr = 1;
	}
	ok = (xCharArr && yCharArr);
	if (ok) {
		if ((*Op__38_s->f == 10 && (*x)->conval->intval2 == 1)) {
			(*x)->typ = OPT_chartyp;
			(*x)->conval->intval = 0;
			OPB_Index(&*y, OPB_NewIntConst(((LONGINT)(0))));
		} else if ((*Op__38_s->g == 10 && (*y)->conval->intval2 == 1)) {
			(*y)->typ = OPT_chartyp;
			(*y)->conval->intval = 0;
			OPB_Index(&*x, OPB_NewIntConst(((LONGINT)(0))));
		}
	}
	_o_result = ok;
	return _o_result;
}

void OPB_Op (SHORTINT op, OPT_Node *x, OPT_Node y)
{
	INTEGER f, g;
	OPT_Node t = NIL, z = NIL;
	OPT_Struct typ = NIL;
	BOOLEAN do_;
	LONGINT val;
	struct Op__38 _s;
	_s.f = &f;
	_s.g = &g;
	_s.lnk = Op__38_s;
	Op__38_s = &_s;
	z = *x;
	if (((z->class == 8 || z->class == 9) || y->class == 8) || y->class == 9) {
		OPB_err(126);
	} else if ((z->class == 7 && y->class == 7)) {
		OPB_ConstOp(op, z, y);
		z->obj = NIL;
	} else {
		if (z->typ != y->typ) {
			g = y->typ->form;
			switch (z->typ->form) {
				case 3: 
					if (z->class == 7) {
						OPB_CharToString(z);
					} else {
						OPB_err(100);
					}
					break;
				case 4: case 5: case 6: 
					if ((__IN(g, 0x70) && y->typ->size < z->typ->size)) {
						OPB_Convert(&y, z->typ);
					} else if (__IN(g, 0x01f0)) {
						OPB_Convert(&z, y->typ);
					} else {
						OPB_err(100);
					}
					break;
				case 7: 
					if (__IN(g, 0x70)) {
						OPB_Convert(&y, z->typ);
					} else if (__IN(g, 0x0180)) {
						OPB_Convert(&z, y->typ);
					} else {
						OPB_err(100);
					}
					break;
				case 8: 
					if (__IN(g, 0x01f0)) {
						OPB_Convert(&y, z->typ);
					} else if (__IN(g, 0x0180)) {
						OPB_Convert(&y, z->typ);
					} else {
						OPB_err(100);
					}
					break;
				case 11: 
					if (!__IN(g, 0x6000)) {
						OPB_err(100);
					}
					break;
				case 13: 
					OPB_CheckPtr(z, y);
					break;
				case 14: 
					if (g != 11) {
						OPB_err(100);
					}
					break;
				case 10: 
					break;
				case 15: 
					if (z->typ->comp == 4) {
						OPB_err(100);
					}
					break;
				default: 
					OPB_err(100);
					break;
			}
		}
		typ = z->typ;
		f = typ->form;
		g = y->typ->form;
		switch (op) {
			case 1: 
				do_ = 1;
				if (__IN(f, 0x70)) {
					if (z->class == 7) {
						val = z->conval->intval;
						if (val == 1) {
							do_ = 0;
							z = y;
						} else if (val == 0) {
							do_ = 0;
						} else if (OPB_log(val) == 1) {
							t = y;
							y = z;
							z = t;
							op = 17;
							y->typ = OPT_sinttyp;
							y->conval->intval = OPB_exp;
							y->obj = NIL;
						}
					} else if (y->class == 7) {
						val = y->conval->intval;
						if (val == 1) {
							do_ = 0;
						} else if (val == 0) {
							do_ = 0;
							z = y;
						} else if (OPB_log(val) == 1) {
							op = 17;
							y->typ = OPT_sinttyp;
							y->conval->intval = OPB_exp;
							y->obj = NIL;
						}
					}
				} else if (!__IN(f, 0x0381)) {
					OPB_err(105);
					typ = OPT_undftyp;
				}
				if (do_) {
					NewOp__39(op, typ, &z, y);
				}
				break;
			case 2: 
				if (__IN(f, 0x70)) {
					if ((y->class == 7 && y->conval->intval == 0)) {
						OPB_err(205);
					}
					OPB_Convert(&z, OPT_realtyp);
					OPB_Convert(&y, OPT_realtyp);
					typ = OPT_realtyp;
				} else if (__IN(f, 0x0180)) {
					if ((y->class == 7 && y->conval->realval == (LONGREAL)0)) {
						OPB_err(205);
					}
				} else if ((f != 9 && f != 0)) {
					OPB_err(102);
					typ = OPT_undftyp;
				}
				NewOp__39(op, typ, &z, y);
				break;
			case 3: 
				do_ = 1;
				if (__IN(f, 0x70)) {
					if (y->class == 7) {
						val = y->conval->intval;
						if (val == 0) {
							OPB_err(205);
						} else if (val == 1) {
							do_ = 0;
						} else if (OPB_log(val) == 1) {
							op = 17;
							y->typ = OPT_sinttyp;
							y->conval->intval = -OPB_exp;
							y->obj = NIL;
						}
					}
				} else if (f != 0) {
					OPB_err(103);
					typ = OPT_undftyp;
				}
				if (do_) {
					NewOp__39(op, typ, &z, y);
				}
				break;
			case 4: 
				if (__IN(f, 0x70)) {
					if (y->class == 7) {
						if (y->conval->intval == 0) {
							OPB_err(205);
						} else if (OPB_log(y->conval->intval) == 1) {
							op = 18;
							y->conval->intval = __ASH(-1, OPB_exp);
							y->obj = NIL;
						}
					}
				} else if (f != 0) {
					OPB_err(104);
					typ = OPT_undftyp;
				}
				NewOp__39(op, typ, &z, y);
				break;
			case 5: 
				if (f == 2) {
					if (z->class == 7) {
						if (OPB_IntToBool(z->conval->intval)) {
							z = y;
						}
					} else if ((y->class == 7 && OPB_IntToBool(y->conval->intval))) {
					} else {
						NewOp__39(op, typ, &z, y);
					}
				} else if (f != 0) {
					OPB_err(94);
					z->typ = OPT_undftyp;
				}
				break;
			case 6: 
				if (!__IN(f, 0x03f1)) {
					OPB_err(105);
					typ = OPT_undftyp;
				}
				do_ = 1;
				if (__IN(f, 0x70)) {
					if ((z->class == 7 && z->conval->intval == 0)) {
						do_ = 0;
						z = y;
					}
					if ((y->class == 7 && y->conval->intval == 0)) {
						do_ = 0;
					}
				}
				if (do_) {
					NewOp__39(op, typ, &z, y);
				}
				break;
			case 7: 
				if (!__IN(f, 0x03f1)) {
					OPB_err(106);
					typ = OPT_undftyp;
				}
				if ((!__IN(f, 0x70) || y->class != 7) || y->conval->intval != 0) {
					NewOp__39(op, typ, &z, y);
				}
				break;
			case 8: 
				if (f == 2) {
					if (z->class == 7) {
						if (!OPB_IntToBool(z->conval->intval)) {
							z = y;
						}
					} else if ((y->class == 7 && !OPB_IntToBool(y->conval->intval))) {
					} else {
						NewOp__39(op, typ, &z, y);
					}
				} else if (f != 0) {
					OPB_err(95);
					z->typ = OPT_undftyp;
				}
				break;
			case 9: case 10: 
				if (__IN(f, 0x6bff) || strings__41(&z, &y)) {
					typ = OPT_booltyp;
				} else {
					OPB_err(107);
					typ = OPT_undftyp;
				}
				NewOp__39(op, typ, &z, y);
				break;
			case 11: case 12: case 13: case 14: 
				if (__IN(f, 0x01f9) || strings__41(&z, &y)) {
					typ = OPT_booltyp;
				} else {
					OPM_LogWLn();
					OPM_LogWStr((CHAR*)"ELSE in Op()", (LONGINT)13);
					OPM_LogWLn();
					OPB_err(108);
					typ = OPT_undftyp;
				}
				NewOp__39(op, typ, &z, y);
				break;
			default: 
				OPM_LogWStr((CHAR*)"unhandled case in OPB.Op, op = ", (LONGINT)32);
				OPM_LogWNum(op, ((LONGINT)(0)));
				OPM_LogWLn();
				break;
		}
	}
	*x = z;
	Op__38_s = _s.lnk;
}

void OPB_SetRange (OPT_Node *x, OPT_Node y)
{
	LONGINT k, l;
	if ((((*x)->class == 8 || (*x)->class == 9) || y->class == 8) || y->class == 9) {
		OPB_err(126);
	} else if ((__IN((*x)->typ->form, 0x70) && __IN(y->typ->form, 0x70))) {
		if ((*x)->class == 7) {
			k = (*x)->conval->intval;
			if (0 > k || k > (int)OPM_MaxSet) {
				OPB_err(202);
			}
		}
		if (y->class == 7) {
			l = y->conval->intval;
			if (0 > l || l > (int)OPM_MaxSet) {
				OPB_err(202);
			}
		}
		if (((*x)->class == 7 && y->class == 7)) {
			if (k <= l) {
				(*x)->conval->setval = __SETRNG(k, l);
			} else {
				OPB_err(201);
				(*x)->conval->setval = __SETRNG(l, k);
			}
			(*x)->obj = NIL;
		} else {
			OPB_BindNodes(10, OPT_settyp, &*x, y);
		}
	} else {
		OPB_err(93);
	}
	(*x)->typ = OPT_settyp;
}

void OPB_SetElem (OPT_Node *x)
{
	LONGINT k;
	if ((*x)->class == 8 || (*x)->class == 9) {
		OPB_err(126);
	} else if (!__IN((*x)->typ->form, 0x70)) {
		OPB_err(93);
	} else if ((*x)->class == 7) {
		k = (*x)->conval->intval;
		if ((0 <= k && k <= (int)OPM_MaxSet)) {
			(*x)->conval->setval = __SETOF(k);
		} else {
			OPB_err(202);
		}
		(*x)->obj = NIL;
	} else {
		OPB_Convert(&*x, OPT_settyp);
	}
	(*x)->typ = OPT_settyp;
}

static void OPB_CheckAssign (OPT_Struct x, OPT_Node ynode)
{
	OPT_Struct y = NIL;
	INTEGER f, g;
	OPT_Struct p = NIL, q = NIL;
	if (OPM_Verbose) {
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"PROCEDURE CheckAssign", (LONGINT)22);
		OPM_LogWLn();
	}
	y = ynode->typ;
	f = x->form;
	g = y->form;
	if (OPM_Verbose) {
		OPM_LogWStr((CHAR*)"y.form = ", (LONGINT)10);
		OPM_LogWNum(y->form, ((LONGINT)(0)));
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"f = ", (LONGINT)5);
		OPM_LogWNum(f, ((LONGINT)(0)));
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"g = ", (LONGINT)5);
		OPM_LogWNum(g, ((LONGINT)(0)));
		OPM_LogWLn();
		OPM_LogWStr((CHAR*)"ynode.typ.syze = ", (LONGINT)18);
		OPM_LogWNum(ynode->typ->size, ((LONGINT)(0)));
		OPM_LogWLn();
	}
	if (ynode->class == 8 || (ynode->class == 9 && f != 14)) {
		OPB_err(126);
	}
	switch (f) {
		case 0: case 10: 
			break;
		case 1: 
			if (!((__IN(g, 0x7a) && y->size == 1))) {
				OPB_err(113);
			}
			break;
		case 2: case 3: case 9: 
			if (g != f) {
				OPB_err(113);
			}
			break;
		case 4: case 5: case 6: 
			if (!__IN(g, 0x70) || x->size < y->size) {
				OPB_err(113);
			}
			break;
		case 7: 
			if (!__IN(g, 0xf0)) {
				OPB_err(113);
			}
			break;
		case 8: 
			if (!__IN(g, 0x01f0)) {
				OPB_err(113);
			}
			break;
		case 13: 
			if ((x == y || g == 11) || (x == OPT_sysptrtyp && g == 13)) {
			} else if (g == 13) {
				p = x->BaseTyp;
				q = y->BaseTyp;
				if ((p->comp == 4 && q->comp == 4)) {
					while ((((q != p && q != NIL)) && q != OPT_undftyp)) {
						q = q->BaseTyp;
					}
					if (q == NIL) {
						OPB_err(113);
					}
				} else {
					OPB_err(113);
				}
			} else {
				OPB_err(113);
			}
			break;
		case 14: 
			if (ynode->class == 9) {
				OPB_CheckProc(x, ynode->obj);
			} else if (x == y || g == 11) {
			} else {
				OPB_err(113);
			}
			break;
		case 12: case 11: 
			OPB_err(113);
			break;
		case 15: 
			x->pvused = 1;
			if (x->comp == 2) {
				if ((ynode->class == 7 && g == 3)) {
					OPB_CharToString(ynode);
					y = ynode->typ;
					g = 10;
				}
				if (x == y) {
				} else if (x->BaseTyp == OPT_chartyp) {
					if (g == 10) {
						if (ynode->conval->intval2 > x->n) {
							OPB_err(114);
						}
					} else if ((__IN(y->comp, 0x0c) && y->BaseTyp == OPT_chartyp)) {
					} else {
						OPB_err(113);
					}
				} else {
					OPB_err(113);
				}
			} else if ((x->comp == 3 && x->BaseTyp == OPT_chartyp)) {
				if ((__IN(y->comp, 0x0c) && y->BaseTyp == OPT_chartyp)) {
				} else {
					OPB_err(113);
				}
			} else if (x->comp == 4) {
				if (x == y) {
				} else if (y->comp == 4) {
					q = y->BaseTyp;
					while ((((q != NIL && q != x)) && q != OPT_undftyp)) {
						q = q->BaseTyp;
					}
					if (q == NIL) {
						OPB_err(113);
					}
				} else {
					OPB_err(113);
				}
			} else {
				OPB_err(113);
			}
			break;
		default: 
			OPM_LogWStr((CHAR*)"unhandled case in OPB.CheckAssign, f = ", (LONGINT)40);
			OPM_LogWNum(f, ((LONGINT)(0)));
			OPM_LogWLn();
			break;
	}
	if ((((((ynode->class == 7 && g < f)) && __IN(g, 0xf0))) && __IN(f, 0x01e0))) {
		OPB_Convert(&ynode, x);
	}
}

static void OPB_CheckLeaf (OPT_Node x, BOOLEAN dynArrToo)
{
}

void OPB_StPar0 (OPT_Node *par0, INTEGER fctno)
{
	INTEGER f;
	OPT_Struct typ = NIL;
	OPT_Node x = NIL;
	x = *par0;
	f = x->typ->form;
	switch (fctno) {
		case 0: 
			if ((__IN(f, 0x70) && x->class == 7)) {
				if ((0 <= x->conval->intval && x->conval->intval <= 255)) {
					OPB_BindNodes(28, OPT_notyp, &x, x);
				} else {
					OPB_err(218);
				}
			} else {
				OPB_err(69);
			}
			x->typ = OPT_notyp;
			break;
		case 1: 
			typ = OPT_notyp;
			if (OPB_NotVar(x)) {
				OPB_err(112);
			} else if (f == 13) {
				if (x->readonly) {
					OPB_err(76);
				}
				f = x->typ->BaseTyp->comp;
				if (__IN(f, 0x1c)) {
					if (f == 3) {
						typ = x->typ->BaseTyp;
					}
					OPB_BindNodes(19, OPT_notyp, &x, NIL);
					x->subcl = 1;
				} else {
					OPB_err(111);
				}
			} else {
				OPB_err(111);
			}
			x->typ = typ;
			break;
		case 2: 
			OPB_MOp(21, &x);
			break;
		case 3: 
			OPB_MOp(22, &x);
			break;
		case 4: 
			if (x->class == 8 || x->class == 9) {
				OPB_err(126);
			} else if (f == 3) {
				OPB_Convert(&x, OPT_inttyp);
			} else {
				OPB_err(111);
			}
			x->typ = OPT_inttyp;
			break;
		case 5: 
			if (x->class == 8 || x->class == 9) {
				OPB_err(126);
			} else if (__IN(f, 0x0180)) {
				OPB_Convert(&x, OPT_linttyp);
			} else {
				OPB_err(111);
			}
			x->typ = OPT_linttyp;
			break;
		case 6: 
			OPB_MOp(23, &x);
			break;
		case 7: 
			if (x->class == 8) {
				switch (f) {
					case 2: 
						x = OPB_NewBoolConst(0);
						break;
					case 3: 
						x = OPB_NewIntConst(((LONGINT)(0)));
						x->typ = OPT_chartyp;
						break;
					case 4: case 5: case 6: 
						x = OPB_NewIntConst(OPM_SignedMinimum(x->typ->size));
						break;
					case 9: 
						x = OPB_NewIntConst(((LONGINT)(0)));
						x->typ = OPT_inttyp;
						break;
					case 7: 
						x = OPB_NewRealConst(OPM_MinReal, OPT_realtyp);
						break;
					case 8: 
						x = OPB_NewRealConst(OPM_MinLReal, OPT_lrltyp);
						break;
					default: 
						OPB_err(111);
						break;
				}
			} else {
				OPB_err(110);
			}
			break;
		case 8: 
			if (x->class == 8) {
				switch (f) {
					case 2: 
						x = OPB_NewBoolConst(1);
						break;
					case 3: 
						x = OPB_NewIntConst(((LONGINT)(255)));
						x->typ = OPT_chartyp;
						break;
					case 4: case 5: case 6: 
						x = OPB_NewIntConst(OPM_SignedMaximum(x->typ->size));
						break;
					case 9: 
						x = OPB_NewIntConst(OPM_MaxSet);
						x->typ = OPT_inttyp;
						break;
					case 7: 
						x = OPB_NewRealConst(OPM_MaxReal, OPT_realtyp);
						break;
					case 8: 
						x = OPB_NewRealConst(OPM_MaxLReal, OPT_lrltyp);
						break;
					default: 
						OPB_err(111);
						break;
				}
			} else {
				OPB_err(110);
			}
			break;
		case 9: 
			if (x->class == 8 || x->class == 9) {
				OPB_err(126);
			} else if (__IN(f, 0x71)) {
				OPB_Convert(&x, OPT_chartyp);
			} else {
				OPB_err(111);
				x->typ = OPT_chartyp;
			}
			break;
		case 10: 
			if (x->class == 8 || x->class == 9) {
				OPB_err(126);
			} else if (__IN(f, 0x70)) {
				typ = OPT_ShorterOrLongerType(x->typ, -1);
				if (typ == NIL) {
					OPB_err(111);
				} else {
					OPB_Convert(&x, typ);
				}
			} else if (f == 8) {
				OPB_Convert(&x, OPT_realtyp);
			} else {
				OPB_err(111);
			}
			break;
		case 11: 
			if (x->class == 8 || x->class == 9) {
				OPB_err(126);
			} else if (__IN(f, 0x70)) {
				typ = OPT_ShorterOrLongerType(x->typ, 1);
				if (typ == NIL) {
					OPB_err(111);
				} else {
					OPB_Convert(&x, typ);
				}
			} else if (f == 7) {
				OPB_Convert(&x, OPT_lrltyp);
			} else if (f == 3) {
				OPB_Convert(&x, OPT_linttyp);
			} else {
				OPB_err(111);
			}
			break;
		case 13: case 14: 
			if (OPB_NotVar(x)) {
				OPB_err(112);
			} else if (!__IN(f, 0x70)) {
				OPB_err(111);
			} else if (x->readonly) {
				OPB_err(76);
			}
			break;
		case 15: case 16: 
			if (OPB_NotVar(x)) {
				OPB_err(112);
			} else if (x->typ != OPT_settyp) {
				OPB_err(111);
				x->typ = OPT_settyp;
			} else if (x->readonly) {
				OPB_err(76);
			}
			break;
		case 17: 
			if (!__IN(x->typ->comp, 0x0c)) {
				OPB_err(131);
			}
			break;
		case 18: 
			if ((x->class == 7 && f == 3)) {
				OPB_CharToString(x);
				f = 10;
			}
			if (x->class == 8 || x->class == 9) {
				OPB_err(126);
			} else if (((!__IN(x->typ->comp, 0x0c) || x->typ->BaseTyp->form != 3) && f != 10)) {
				OPB_err(111);
			}
			break;
		case 19: 
			if (x->class == 8 || x->class == 9) {
				OPB_err(126);
			} else if (__IN(f, 0x70)) {
				if (x->typ->size != (int)OPM_LIntSize) {
					OPB_Convert(&x, OPT_linttyp);
				}
			} else {
				OPB_err(111);
				x->typ = OPT_linttyp;
			}
			break;
		case 20: 
			OPB_CheckLeaf(x, 0);
			OPB_MOp(24, &x);
			break;
		case 12: 
			if (x->class != 8) {
				OPB_err(110);
				x = OPB_NewIntConst(((LONGINT)(1)));
			} else if (__IN(f, 0x63fe) || __IN(x->typ->comp, 0x14)) {
				(*OPB_typSize)(x->typ);
				x->typ->pvused = 1;
				x = OPB_NewIntConst(x->typ->size);
			} else {
				OPB_err(111);
				x = OPB_NewIntConst(((LONGINT)(1)));
			}
			break;
		case 21: 
			OPB_MOp(25, &x);
			break;
		case 22: case 23: 
			if (x->class == 8 || x->class == 9) {
				OPB_err(126);
			} else if (!__IN(f, 0x027a)) {
				OPB_err(111);
			}
			break;
		case 24: case 25: case 28: case 31: 
			if (x->class == 8 || x->class == 9) {
				OPB_err(126);
			} else if ((((x->class == 7 && __IN(f, 0x70))) && x->typ->size < OPT_linttyp->size)) {
				OPB_Convert(&x, OPT_linttyp);
			} else if (!((__IN(x->typ->form, 0x2070) && x->typ->size == (int)OPM_PointerSize))) {
				OPB_err(111);
				x->typ = OPT_linttyp;
			}
			break;
		case 26: case 27: 
			if ((__IN(f, 0x70) && x->class == 7)) {
				if (x->conval->intval < 0 || x->conval->intval > -1) {
					OPB_err(220);
				}
			} else {
				OPB_err(69);
			}
			break;
		case 29: 
			if (x->class != 8) {
				OPB_err(110);
			} else if (__IN(f, 0x1401) || x->typ->comp == 3) {
				OPB_err(111);
			}
			break;
		case 30: 
			if (OPB_NotVar(x)) {
				OPB_err(112);
			} else if (f == 13) {
			} else {
				OPB_err(111);
			}
			break;
		case 32: 
			if (x->class == 8 || x->class == 9) {
				OPB_err(126);
				x = OPB_NewBoolConst(0);
			} else if (f != 2) {
				OPB_err(120);
				x = OPB_NewBoolConst(0);
			} else {
				OPB_MOp(33, &x);
			}
			break;
		default: 
			OPM_LogWStr((CHAR*)"unhandled case in OPB.StPar0, fctno = ", (LONGINT)39);
			OPM_LogWNum(fctno, ((LONGINT)(0)));
			OPM_LogWLn();
			break;
	}
	*par0 = x;
}

static struct StPar1__52 {
	struct StPar1__52 *lnk;
} *StPar1__52_s;

static OPT_Node NewOp__53 (SHORTINT class, SHORTINT subcl, OPT_Node left, OPT_Node right);

static OPT_Node NewOp__53 (SHORTINT class, SHORTINT subcl, OPT_Node left, OPT_Node right)
{
	OPT_Node _o_result;
	OPT_Node node = NIL;
	node = OPT_NewNode(class);
	node->subcl = subcl;
	node->left = left;
	node->right = right;
	_o_result = node;
	return _o_result;
}

void OPB_StPar1 (OPT_Node *par0, OPT_Node x, SHORTINT fctno)
{
	INTEGER f, L;
	OPT_Struct typ = NIL;
	OPT_Node p = NIL, t = NIL;
	struct StPar1__52 _s;
	_s.lnk = StPar1__52_s;
	StPar1__52_s = &_s;
	p = *par0;
	f = x->typ->form;
	switch (fctno) {
		case 13: case 14: 
			if (x->class == 8 || x->class == 9) {
				OPB_err(126);
				p->typ = OPT_notyp;
			} else {
				if (x->typ != p->typ) {
					if ((x->class == 7 && __IN(f, 0x70))) {
						OPB_Convert(&x, p->typ);
					} else {
						OPB_err(111);
					}
				}
				p = NewOp__53(19, fctno, p, x);
				p->typ = OPT_notyp;
			}
			break;
		case 15: case 16: 
			if (x->class == 8 || x->class == 9) {
				OPB_err(126);
			} else if (__IN(f, 0x70)) {
				if ((x->class == 7 && (0 > x->conval->intval || x->conval->intval > (int)OPM_MaxSet))) {
					OPB_err(202);
				}
				p = NewOp__53(19, fctno, p, x);
			} else {
				OPB_err(111);
			}
			p->typ = OPT_notyp;
			break;
		case 17: 
			if (!__IN(f, 0x70) || x->class != 7) {
				OPB_err(69);
			} else if (x->typ->size == 1) {
				L = (int)x->conval->intval;
				typ = p->typ;
				while ((L > 0 && __IN(typ->comp, 0x0c))) {
					typ = typ->BaseTyp;
					L -= 1;
				}
				if (L != 0 || !__IN(typ->comp, 0x0c)) {
					OPB_err(132);
				} else {
					x->obj = NIL;
					if (typ->comp == 3) {
						while (p->class == 4) {
							p = p->left;
							x->conval->intval += 1;
						}
						p = NewOp__53(12, 19, p, x);
						p->typ = OPT_linttyp;
					} else {
						p = x;
						p->conval->intval = typ->n;
						OPB_SetIntType(p);
					}
				}
			} else {
				OPB_err(132);
			}
			break;
		case 18: 
			if (OPB_NotVar(x)) {
				OPB_err(112);
			} else if ((__IN(x->typ->comp, 0x0c) && x->typ->BaseTyp->form == 3)) {
				if (x->readonly) {
					OPB_err(76);
				}
				t = x;
				x = p;
				p = t;
				p = NewOp__53(19, 18, p, x);
			} else {
				OPB_err(111);
			}
			p->typ = OPT_notyp;
			break;
		case 19: 
			if (x->class == 8 || x->class == 9) {
				OPB_err(126);
			} else if (__IN(f, 0x70)) {
				if ((p->class == 7 && x->class == 7)) {
					if (-OPB_maxExp > x->conval->intval || x->conval->intval > OPB_maxExp) {
						OPB_err(208);
						p->conval->intval = 1;
					} else if (x->conval->intval >= 0) {
						if (__ABS(p->conval->intval) <= __DIV(2147483647, __ASH(1, x->conval->intval))) {
							p->conval->intval = p->conval->intval * __ASH(1, x->conval->intval);
						} else {
							OPB_err(208);
							p->conval->intval = 1;
						}
					} else {
						p->conval->intval = __ASH(p->conval->intval, x->conval->intval);
					}
					p->obj = NIL;
				} else {
					p = NewOp__53(12, 17, p, x);
					p->typ = OPT_linttyp;
				}
			} else {
				OPB_err(111);
			}
			break;
		case 1: 
			if (x->class == 8 || x->class == 9) {
				OPB_err(126);
			} else if (p->typ->comp == 3) {
				if (__IN(f, 0x70)) {
					if ((x->class == 7 && (x->conval->intval <= 0 || x->conval->intval > OPM_MaxIndex))) {
						OPB_err(63);
					}
				} else {
					OPB_err(111);
				}
				p->right = x;
				p->typ = p->typ->BaseTyp;
			} else {
				OPB_err(64);
			}
			break;
		case 22: case 23: 
			if (x->class == 8 || x->class == 9) {
				OPB_err(126);
			} else if (!__IN(f, 0x70)) {
				OPB_err(111);
			} else {
				if (fctno == 22) {
					p = NewOp__53(12, 27, p, x);
				} else {
					p = NewOp__53(12, 28, p, x);
				}
				p->typ = p->left->typ;
			}
			break;
		case 24: case 25: case 26: case 27: 
			if (x->class == 8 || x->class == 9) {
				OPB_err(126);
			} else if (__IN(f, 0x63ff)) {
				if (fctno == 24 || fctno == 26) {
					if (OPB_NotVar(x)) {
						OPB_err(112);
					}
					t = x;
					x = p;
					p = t;
				}
				p = NewOp__53(19, fctno, p, x);
			} else {
				OPB_err(111);
			}
			p->typ = OPT_notyp;
			break;
		case 28: 
			if (x->class == 8 || x->class == 9) {
				OPB_err(126);
			} else if (__IN(f, 0x70)) {
				p = NewOp__53(12, 26, p, x);
			} else {
				OPB_err(111);
			}
			p->typ = OPT_booltyp;
			break;
		case 29: 
			if (((x->class == 8 || x->class == 9) || __IN(f, 0x1401)) || x->typ->comp == 3) {
				OPB_err(126);
			}
			if (x->typ->size < p->typ->size) {
				OPB_err(-308);
			}
			t = OPT_NewNode(11);
			t->subcl = 29;
			t->left = x;
			x = t;
			x->typ = p->typ;
			p = x;
			break;
		case 30: 
			if (x->class == 8 || x->class == 9) {
				OPB_err(126);
			} else if (__IN(f, 0x70)) {
				p = NewOp__53(19, 30, p, x);
			} else {
				OPB_err(111);
			}
			p->typ = OPT_notyp;
			break;
		case 31: 
			if (x->class == 8 || x->class == 9) {
				OPB_err(126);
			} else if ((((x->class == 7 && __IN(f, 0x70))) && x->typ->size < OPT_linttyp->size)) {
				OPB_Convert(&x, OPT_linttyp);
			} else if (!((__IN(x->typ->form, 0x2070) && x->typ->size == (int)OPM_PointerSize))) {
				OPB_err(111);
				x->typ = OPT_linttyp;
			}
			p->link = x;
			break;
		case 32: 
			if ((__IN(f, 0x70) && x->class == 7)) {
				if ((0 <= x->conval->intval && x->conval->intval <= 255)) {
					OPB_BindNodes(28, OPT_notyp, &x, x);
					x->conval = OPT_NewConst();
					x->conval->intval = OPM_errpos;
					OPB_Construct(15, &p, x);
					p->conval = OPT_NewConst();
					p->conval->intval = OPM_errpos;
					OPB_Construct(20, &p, NIL);
					OPB_OptIf(&p);
					if (p == NIL) {
					} else if (p->class == 28) {
						OPB_err(99);
					} else {
						p->subcl = 32;
					}
				} else {
					OPB_err(218);
				}
			} else {
				OPB_err(69);
			}
			break;
		default: 
			OPB_err(64);
			break;
	}
	*par0 = p;
	StPar1__52_s = _s.lnk;
}

void OPB_StParN (OPT_Node *par0, OPT_Node x, INTEGER fctno, INTEGER n)
{
	OPT_Node node = NIL;
	INTEGER f;
	OPT_Node p = NIL;
	p = *par0;
	f = x->typ->form;
	if (fctno == 1) {
		if (x->class == 8 || x->class == 9) {
			OPB_err(126);
		} else if (p->typ->comp != 3) {
			OPB_err(64);
		} else if (__IN(f, 0x70)) {
			if ((x->class == 7 && (x->conval->intval <= 0 || x->conval->intval > OPM_MaxIndex))) {
				OPB_err(63);
			}
			node = p->right;
			while (node->link != NIL) {
				node = node->link;
			}
			node->link = x;
			p->typ = p->typ->BaseTyp;
		} else {
			OPB_err(111);
		}
	} else if ((fctno == 31 && n == 2)) {
		if (x->class == 8 || x->class == 9) {
			OPB_err(126);
		} else if (__IN(f, 0x70)) {
			node = OPT_NewNode(19);
			node->subcl = 31;
			node->right = p;
			node->left = p->link;
			p->link = x;
			p = node;
		} else {
			OPB_err(111);
		}
		p->typ = OPT_notyp;
	} else {
		OPB_err(64);
	}
	*par0 = p;
}

void OPB_StFct (OPT_Node *par0, SHORTINT fctno, INTEGER parno)
{
	INTEGER dim;
	OPT_Node x = NIL, p = NIL;
	p = *par0;
	if (fctno <= 19) {
		if ((fctno == 1 && p->typ != OPT_notyp)) {
			if (p->typ->comp == 3) {
				OPB_err(65);
			}
			p->typ = OPT_notyp;
		} else if (fctno <= 12) {
			if (parno < 1) {
				OPB_err(65);
			}
		} else {
			if (((fctno == 13 || fctno == 14) && parno == 1)) {
				OPB_BindNodes(19, OPT_notyp, &p, OPB_NewIntConst(((LONGINT)(1))));
				p->subcl = fctno;
				p->right->typ = p->left->typ;
			} else if ((fctno == 17 && parno == 1)) {
				if (p->typ->comp == 3) {
					dim = 0;
					while (p->class == 4) {
						p = p->left;
						dim += 1;
					}
					OPB_BindNodes(12, OPT_linttyp, &p, OPB_NewIntConst(dim));
					p->subcl = 19;
				} else {
					p = OPB_NewIntConst(p->typ->n);
				}
			} else if (parno < 2) {
				OPB_err(65);
			}
		}
	} else if (fctno == 32) {
		if (parno == 1) {
			x = NIL;
			OPB_BindNodes(28, OPT_notyp, &x, OPB_NewIntConst(((LONGINT)(0))));
			x->conval = OPT_NewConst();
			x->conval->intval = OPM_errpos;
			OPB_Construct(15, &p, x);
			p->conval = OPT_NewConst();
			p->conval->intval = OPM_errpos;
			OPB_Construct(20, &p, NIL);
			OPB_OptIf(&p);
			if (p == NIL) {
			} else if (p->class == 28) {
				OPB_err(99);
			} else {
				p->subcl = 32;
			}
		} else if (parno < 1) {
			OPB_err(65);
		}
	} else {
		if ((parno < 1 || (fctno > 21 && parno < 2)) || (fctno == 31 && parno < 3)) {
			OPB_err(65);
		}
	}
	*par0 = p;
}

static void OPB_DynArrParCheck (OPT_Struct ftyp, OPT_Struct atyp, BOOLEAN fvarpar)
{
	INTEGER f;
	f = atyp->comp;
	ftyp = ftyp->BaseTyp;
	atyp = atyp->BaseTyp;
	if ((fvarpar && ftyp == OPT_bytetyp)) {
		if (!__IN(f, 0x0c) || !((__IN(atyp->form, 0x7e) && atyp->size == 1))) {
			if (__IN(18, OPM_opt)) {
				OPB_err(-301);
			}
		}
	} else if (__IN(f, 0x0c)) {
		if (ftyp->comp == 3) {
			OPB_DynArrParCheck(ftyp, atyp, fvarpar);
		} else if (ftyp != atyp) {
			if ((((!fvarpar && ftyp->form == 13)) && atyp->form == 13)) {
				ftyp = ftyp->BaseTyp;
				atyp = atyp->BaseTyp;
				if ((ftyp->comp == 4 && atyp->comp == 4)) {
					while ((((ftyp != atyp && atyp != NIL)) && atyp != OPT_undftyp)) {
						atyp = atyp->BaseTyp;
					}
					if (atyp == NIL) {
						OPB_err(113);
					}
				} else {
					OPB_err(66);
				}
			} else {
				OPB_err(66);
			}
		}
	} else {
		OPB_err(67);
	}
}

static void OPB_CheckReceiver (OPT_Node *x, OPT_Object fp)
{
	if (fp->typ->form == 13) {
		if ((*x)->class == 3) {
			*x = (*x)->left;
		} else {
			OPB_err(71);
		}
	}
}

void OPB_PrepCall (OPT_Node *x, OPT_Object *fpar)
{
	if (((*x)->obj != NIL && __IN((*x)->obj->mode, 0x22c0))) {
		*fpar = (*x)->obj->link;
		if ((*x)->obj->mode == 13) {
			OPB_CheckReceiver(&(*x)->left, *fpar);
			*fpar = (*fpar)->link;
		}
	} else if (((((*x)->class != 8 && (*x)->typ != NIL)) && (*x)->typ->form == 14)) {
		*fpar = (*x)->typ->link;
	} else {
		OPB_err(121);
		*fpar = NIL;
		(*x)->typ = OPT_undftyp;
	}
}

void OPB_Param (OPT_Node ap, OPT_Object fp)
{
	OPT_Struct q = NIL;
	if (fp->typ->form != 0) {
		if (fp->mode == 2) {
			if (OPB_NotVar(ap)) {
				OPB_err(122);
			} else {
				OPB_CheckLeaf(ap, 0);
			}
			if (ap->readonly) {
				OPB_err(76);
			}
			if (fp->typ->comp == 3) {
				OPB_DynArrParCheck(fp->typ, ap->typ, 1);
			} else if ((fp->typ->comp == 4 && ap->typ->comp == 4)) {
				q = ap->typ;
				while ((((q != fp->typ && q != NIL)) && q != OPT_undftyp)) {
					q = q->BaseTyp;
				}
				if (q == NIL) {
					OPB_err(111);
				}
			} else if ((fp->typ == OPT_sysptrtyp && ap->typ->form == 13)) {
			} else if ((ap->typ != fp->typ && !((fp->typ->form == 1 && ((__IN(ap->typ->form, 0x7e) && ap->typ->size == 1)))))) {
				OPB_err(123);
			} else if ((fp->typ->form == 13 && ap->class == 5)) {
				OPB_err(123);
			}
		} else if (fp->typ->comp == 3) {
			if ((ap->class == 7 && ap->typ->form == 3)) {
				OPB_CharToString(ap);
			}
			if ((ap->typ->form == 10 && fp->typ->BaseTyp->form == 3)) {
			} else if (ap->class >= 7) {
				OPB_err(59);
			} else {
				OPB_DynArrParCheck(fp->typ, ap->typ, 0);
			}
		} else {
			OPB_CheckAssign(fp->typ, ap);
		}
	}
}

void OPB_StaticLink (SHORTINT dlev)
{
	OPT_Object scope = NIL;
	scope = OPT_topScope;
	while (dlev > 0) {
		dlev -= 1;
		scope->link->conval->setval |= __SETOF(3);
		scope = scope->left;
	}
}

void OPB_Call (OPT_Node *x, OPT_Node apar, OPT_Object fp)
{
	OPT_Struct typ = NIL;
	OPT_Node p = NIL;
	SHORTINT lev;
	if ((*x)->class == 9) {
		typ = (*x)->typ;
		lev = (*x)->obj->mnolev;
		if (lev > 0) {
			OPB_StaticLink(OPT_topScope->mnolev - lev);
		}
		if ((*x)->obj->mode == 10) {
			OPB_err(121);
		}
	} else if (((*x)->class == 2 && (*x)->obj->mode == 13)) {
		typ = (*x)->typ;
		(*x)->class = 9;
		p = (*x)->left;
		(*x)->left = NIL;
		p->link = apar;
		apar = p;
		fp = (*x)->obj->link;
	} else {
		typ = (*x)->typ->BaseTyp;
	}
	OPB_BindNodes(13, typ, &*x, apar);
	(*x)->obj = fp;
}

void OPB_Enter (OPT_Node *procdec, OPT_Node stat, OPT_Object proc)
{
	OPT_Node x = NIL;
	x = OPT_NewNode(18);
	x->typ = OPT_notyp;
	x->obj = proc;
	x->left = *procdec;
	x->right = stat;
	*procdec = x;
}

void OPB_Return (OPT_Node *x, OPT_Object proc)
{
	OPT_Node node = NIL;
	if (proc == NIL) {
		if (*x != NIL) {
			OPB_err(124);
		}
	} else {
		if (*x != NIL) {
			OPB_CheckAssign(proc->typ, *x);
		} else if (proc->typ != OPT_notyp) {
			OPB_err(124);
		}
	}
	node = OPT_NewNode(26);
	node->typ = OPT_notyp;
	node->obj = proc;
	node->left = *x;
	*x = node;
}

void OPB_Assign (OPT_Node *x, OPT_Node y)
{
	OPT_Node z = NIL;
	SHORTINT subcl;
	if ((*x)->class >= 7) {
		OPB_err(56);
	}
	OPB_CheckAssign((*x)->typ, y);
	if ((*x)->readonly) {
		OPB_err(76);
	}
	if ((*x)->typ->comp == 4) {
		if ((*x)->class == 5) {
			z = (*x)->left;
		} else {
			z = *x;
		}
		if ((z->class == 3 && z->left->class == 5)) {
			z->left = z->left->left;
		}
		if (((*x)->typ->strobj != NIL && (z->class == 3 || z->class == 1))) {
			OPB_BindNodes(6, (*x)->typ, &z, NIL);
			*x = z;
		}
	} else if (((((((*x)->typ->comp == 2 && (*x)->typ->BaseTyp == OPT_chartyp)) && y->typ->form == 10)) && y->conval->intval2 == 1)) {
		y->typ = OPT_chartyp;
		y->conval->intval = 0;
		OPB_Index(&*x, OPB_NewIntConst(((LONGINT)(0))));
	}
	if ((((((__IN((*x)->typ->comp, 0x0c) && (*x)->typ->BaseTyp == OPT_chartyp)) && __IN(y->typ->comp, 0x0c))) && y->typ->BaseTyp == OPT_chartyp)) {
		subcl = 18;
	} else {
		subcl = 0;
	}
	OPB_BindNodes(19, OPT_notyp, &*x, y);
	(*x)->subcl = subcl;
}

void OPB_Inittd (OPT_Node *inittd, OPT_Node *last, OPT_Struct typ)
{
	OPT_Node node = NIL;
	node = OPT_NewNode(14);
	node->typ = typ;
	node->conval = OPT_NewConst();
	node->conval->intval = typ->txtpos;
	if (*inittd == NIL) {
		*inittd = node;
	} else {
		(*last)->link = node;
	}
	*last = node;
}


export void *OPB__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(OPM);
	__MODULE_IMPORT(OPS);
	__MODULE_IMPORT(OPT);
	__REGMOD("OPB", 0);
/* BEGIN */
	OPB_maxExp = OPB_log(1073741824);
	OPB_maxExp = OPB_exp;
	__ENDMOD;
}
