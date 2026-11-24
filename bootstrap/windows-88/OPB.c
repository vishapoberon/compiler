/* voc 5.4.2 [2026/11/24] for gcc LP64 on gentoo xnrtspaSF */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32

#include "SYSTEM.h"
#include "OPM.h"
#include "OPS.h"
#include "OPT.h"
#include "Platform.h"


static INT16 OPB_exp;
static INT64 OPB_maxExp;


export void OPB_Assign (OPT_Node *x, OPT_Node y);
static void OPB_BindNodes (INT8 class, OPT_Struct typ, OPT_Node *x, OPT_Node y);
static INT16 OPB_BoolToInt (BOOLEAN b);
export void OPB_Call (OPT_Node *x, OPT_Node apar, OPT_Object fp);
static void OPB_CharToString (OPT_Node n);
static void OPB_CheckAssign (OPT_Struct x, OPT_Node ynode);
static void OPB_CheckLeaf (OPT_Node x, BOOLEAN dynArrToo);
export void OPB_CheckParameters (OPT_Object fp, OPT_Object ap, BOOLEAN checkNames);
static void OPB_CheckProc (OPT_Struct x, OPT_Object y);
static void OPB_CheckPtr (OPT_Node x, OPT_Node y);
static void OPB_CheckRealType (INT16 f, INT16 nr, OPT_Const x);
static void OPB_CheckReceiver (OPT_Node *x, OPT_Object fp);
static void OPB_ConstOp (INT16 op, OPT_Node x, OPT_Node y);
export void OPB_Construct (INT8 class, OPT_Node *x, OPT_Node y);
static void OPB_Convert (OPT_Node *x, OPT_Struct typ);
export void OPB_DeRef (OPT_Node *x);
static void OPB_DynArrParCheck (OPT_Struct ftyp, OPT_Struct atyp, BOOLEAN fvarpar);
export OPT_Node OPB_EmptySet (void);
export void OPB_Enter (OPT_Node *procdec, OPT_Node stat, OPT_Object proc);
export void OPB_Field (OPT_Node *x, OPT_Object y);
export void OPB_In (OPT_Node *x, OPT_Node y);
export void OPB_Index (OPT_Node *x, OPT_Node y);
export void OPB_Inittd (OPT_Node *inittd, OPT_Node *last, OPT_Struct typ);
static BOOLEAN OPB_IntToBool (INT64 i);
export void OPB_Link (OPT_Node *x, OPT_Node *last, OPT_Node y);
export void OPB_MOp (INT8 op, OPT_Node *x);
export OPT_Node OPB_NewBoolConst (BOOLEAN boolval);
export OPT_Node OPB_NewIntConst (INT64 intval);
export OPT_Node OPB_NewLeaf (OPT_Object obj);
export OPT_Node OPB_NewRealConst (LONGREAL realval, OPT_Struct typ);
export OPT_Node OPB_NewString (CHAR *str, INT64 len);
export OPT_Node OPB_Nil (void);
static BOOLEAN OPB_NotVar (OPT_Node x);
export void OPB_Op (INT8 op, OPT_Node *x, OPT_Node y);
export void OPB_OptIf (OPT_Node *x);
export void OPB_Param (OPT_Node ap, OPT_Object fp);
export void OPB_PrepCall (OPT_Node *x, OPT_Object *fpar);
export void OPB_Return (OPT_Node *x, OPT_Object proc);
export void OPB_SetElem (OPT_Node *x);
static void OPB_SetIntType (OPT_Node node);
export void OPB_SetRange (OPT_Node *x, OPT_Node y);
static void OPB_SetSetType (OPT_Node node);
export void OPB_StFct (OPT_Node *par0, INT8 fctno, INT16 parno);
export void OPB_StPar0 (OPT_Node *par0, INT16 fctno);
export void OPB_StPar1 (OPT_Node *par0, OPT_Node x, INT8 fctno);
export void OPB_StParN (OPT_Node *par0, OPT_Node x, INT16 fctno, INT16 n);
export void OPB_StaticLink (INT8 dlev);
export void OPB_TypTest (OPT_Node *x, OPT_Object obj, BOOLEAN guard);
static void OPB_err (INT16 n);
static INT64 OPB_log (INT64 x);


static void OPB_err (INT16 n)
{
	OPM_err(n);
}

OPT_Node OPB_NewLeaf (OPT_Object obj)
{
	OPT_Node node = NIL;
	switch (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 24, 13, 505))->mode) {
		case 14: 
			node = OPT_NewNode(0);
			((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 25, 54, 568))->readonly = 1;
			break;
		case 15: 
			node = OPT_NewNode(0);
			break;
		case 1: 
			node = OPT_NewNode(0);
			((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 28, 23, 708))->readonly = (((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 28, 41, 726))->vis == 2 && ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 28, 70, 755))->mnolev < 0);
			break;
		case 2: 
			node = OPT_NewNode(1);
			((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 29, 57, 825))->readonly = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 29, 74, 842))->vis == 3;
			break;
		case 3: 
			node = OPT_NewNode(7);
			((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 31, 23, 939))->conval = OPT_NewConst();
			__GUARDEQPN_AT(((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 32, 23, 989))->conval, OPT_ConstDesc, (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 32, 31, 997) = *((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 32, 39, 1005))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 32, 47, 1013));
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
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 38, 9, 1247))->obj = obj;
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 38, 27, 1265))->typ = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 38, 39, 1277))->typ;
	return node;
}

void OPB_Construct (INT8 class, OPT_Node *x, OPT_Node y)
{
	OPT_Node node = NIL;
	node = OPT_NewNode(class);
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 45, 37, 1456))->typ = OPT_notyp;
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 46, 9, 1484))->left = *x;
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 46, 26, 1501))->right = y;
	*x = node;
}

void OPB_Link (OPT_Node *x, OPT_Node *last, OPT_Node y)
{
	if (*x == NIL) {
		*x = y;
	} else {
		((OPT_Node)__NIL_AT((ADDRESS)(*last), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 51, 37, 1642))->link = y;
	}
	while (((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 52, 12, 1671))->link != NIL) {
		y = ((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 52, 34, 1693))->link;
	}
	*last = y;
}

static INT16 OPB_BoolToInt (BOOLEAN b)
{
	if (b) {
		return 1;
	} else {
		return 0;
	}
	__RETCHK;
}

static BOOLEAN OPB_IntToBool (INT64 i)
{
	return i != 0;
}

OPT_Node OPB_NewBoolConst (BOOLEAN boolval)
{
	OPT_Node x = NIL;
	x = OPT_NewNode(7);
	((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 68, 36, 2051))->typ = OPT_booltyp;
	((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 69, 6, 2078))->conval = OPT_NewConst();
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 69, 35, 2107))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 69, 43, 2115))->intval = OPB_BoolToInt(boolval);
	return x;
}

void OPB_OptIf (OPT_Node *x)
{
	OPT_Node if_ = NIL, pred = NIL;
	if_ = ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 75, 12, 2282))->left;
	while (((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(if_), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 76, 13, 2302))->left), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 76, 19, 2308))->class == 7) {
		if (OPB_IntToBool(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(if_), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 77, 22, 2353))->left), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 77, 28, 2359))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 77, 36, 2367))->intval)) {
			*x = ((OPT_Node)__NIL_AT((ADDRESS)(if_), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 77, 58, 2389))->right;
			return;
		} else if (((OPT_Node)__NIL_AT((ADDRESS)(if_), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 78, 15, 2419))->link == NIL) {
			*x = ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 78, 39, 2443))->right;
			return;
		} else {
			if_ = ((OPT_Node)__NIL_AT((ADDRESS)(if_), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 79, 20, 2478))->link;
			((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 79, 29, 2487))->left = if_;
		}
	}
	pred = if_;
	if_ = ((OPT_Node)__NIL_AT((ADDRESS)(if_), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 82, 25, 2544))->link;
	while (if_ != NIL) {
		if (((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(if_), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 84, 12, 2585))->left), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 84, 18, 2591))->class == 7) {
			if (OPB_IntToBool(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(if_), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 85, 24, 2640))->left), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 85, 30, 2646))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 85, 38, 2654))->intval)) {
				((OPT_Node)__NIL_AT((ADDRESS)(pred), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 86, 15, 2683))->link = NIL;
				((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 86, 31, 2699))->right = ((OPT_Node)__NIL_AT((ADDRESS)(if_), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 86, 44, 2712))->right;
				return;
			} else {
				if_ = ((OPT_Node)__NIL_AT((ADDRESS)(if_), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 87, 22, 2749))->link;
				((OPT_Node)__NIL_AT((ADDRESS)(pred), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 87, 34, 2761))->link = if_;
			}
		} else {
			pred = if_;
			if_ = ((OPT_Node)__NIL_AT((ADDRESS)(if_), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 89, 32, 2817))->link;
		}
	}
}

OPT_Node OPB_Nil (void)
{
	OPT_Node x = NIL;
	x = OPT_NewNode(7);
	((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 97, 36, 2950))->typ = OPT_niltyp;
	((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 98, 6, 2976))->conval = OPT_NewConst();
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 98, 35, 3005))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 98, 43, 3013))->intval = 0;
	return x;
}

OPT_Node OPB_EmptySet (void)
{
	OPT_Node x = NIL;
	x = OPT_NewNode(7);
	((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 104, 36, 3157))->typ = OPT_settyp;
	((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 105, 6, 3183))->conval = OPT_NewConst();
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 105, 35, 3212))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 105, 43, 3220))->setval = 0x0;
	return x;
}

static void OPB_SetIntType (OPT_Node node)
{
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 109, 13, 3314))->typ = OPT_IntType(OPT_IntSize(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 109, 49, 3350))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 109, 56, 3357))->intval));
}

static void OPB_SetSetType (OPT_Node node)
{
	INT32 i32;
	if (Platform_LittleEndian) {
		__GET((ADDRESS)&((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 116, 33, 3527))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 116, 40, 3534))->setval + 4, i32, INT32);
	} else {
		__GET((ADDRESS)&((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 118, 33, 3594))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 118, 40, 3601))->setval, i32, INT32);
	}
	if (i32 == 0) {
		((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 120, 25, 3649))->typ = OPT_set32typ;
	} else {
		((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 120, 55, 3679))->typ = OPT_set64typ;
	}
}

OPT_Node OPB_NewIntConst (INT64 intval)
{
	OPT_Node x = NIL;
	x = OPT_NewNode(7);
	((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 126, 37, 3846))->conval = OPT_NewConst();
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 127, 6, 3879))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 127, 14, 3887))->intval = intval;
	OPB_SetIntType(x);
	return x;
}

OPT_Node OPB_NewRealConst (LONGREAL realval, OPT_Struct typ)
{
	OPT_Node x = NIL;
	x = OPT_NewNode(7);
	((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 133, 36, 4088))->conval = OPT_NewConst();
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 134, 6, 4121))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 134, 14, 4129))->realval = realval;
	((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 134, 37, 4152))->typ = typ;
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 134, 52, 4167))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 134, 60, 4175))->intval = -1;
	return x;
}

OPT_Node OPB_NewString (CHAR *str, INT64 len)
{
	OPT_Node x = NIL;
	x = OPT_NewNode(7);
	((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 141, 36, 4378))->conval = OPT_NewConst();
	((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 141, 65, 4407))->typ = OPT_stringtyp;
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 142, 6, 4436))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 142, 14, 4444))->intval = -1;
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 142, 46, 4476))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 142, 54, 4484))->intval2 = OPM_Longint(len);
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 143, 6, 4520))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 143, 14, 4528))->ext = OPT_NewExt();
	__MOVE(str, *((OPT_ConstExt)__NIL_AT((ADDRESS)(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 143, 38, 4552))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 143, 46, 4560))->ext), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 143, 51, 4565)), 1024);
	return x;
}

static void OPB_CharToString (OPT_Node n)
{
	CHAR ch;
	((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 150, 6, 4676))->typ = OPT_stringtyp;
	ch = __CHR(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 150, 41, 4711))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 150, 49, 4719))->intval);
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 150, 61, 4731))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 150, 69, 4739))->ext = OPT_NewExt();
	if (ch == 0x00) {
		((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 151, 22, 4783))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 151, 30, 4791))->intval2 = 1;
	} else {
		((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 151, 51, 4812))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 151, 59, 4820))->intval2 = 2;
		(*((OPT_ConstExt)__NIL_AT((ADDRESS)(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 151, 76, 4837))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 151, 84, 4845))->ext), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 151, 89, 4850)))[1] = 0x00;
	}
	(*((OPT_ConstExt)__NIL_AT((ADDRESS)(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 152, 6, 4871))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 152, 14, 4879))->ext), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 152, 19, 4884)))[0] = ch;
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 152, 31, 4896))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 152, 39, 4904))->intval = -1;
	((OPT_Node)__NIL_AT((ADDRESS)(n), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 152, 71, 4936))->obj = NIL;
}

static void OPB_BindNodes (INT8 class, OPT_Struct typ, OPT_Node *x, OPT_Node y)
{
	OPT_Node node = NIL;
	node = OPT_NewNode(class);
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 158, 37, 5125))->typ = typ;
	if (*x != NIL) {
		((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 159, 25, 5163))->pos = ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 159, 35, 5173))->pos;
	}
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 160, 9, 5192))->left = *x;
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 160, 26, 5209))->right = y;
	*x = node;
}

static BOOLEAN OPB_NotVar (OPT_Node x)
{
	return (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 164, 18, 5310))->class >= 7 && ((((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 164, 46, 5338))->class != 11 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 164, 71, 5363))->subcl != 29) || ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 164, 95, 5387))->left), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 164, 101, 5393))->class >= 7));
}

void OPB_DeRef (OPT_Node *x)
{
	OPT_Object strobj = NIL, bstrobj = NIL;
	OPT_Struct typ = NIL, btyp = NIL;
	typ = ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 170, 13, 5549))->typ;
	if (((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 171, 9, 5564))->class >= 7) {
		OPB_err(78);
	} else if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 172, 14, 5612))->form == 11) {
		if (typ == OPT_sysptrtyp) {
			OPB_err(57);
		}
		btyp = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 174, 18, 5703))->BaseTyp;
		strobj = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 174, 42, 5727))->strobj;
		bstrobj = ((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 174, 67, 5752))->strobj;
		if ((((((strobj != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(strobj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 175, 34, 5795))->name[0] != 0x00)) && bstrobj != NIL)) && ((OPT_Object)__NIL_AT((ADDRESS)(bstrobj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 175, 75, 5836))->name[0] != 0x00)) {
			((OPT_Struct)__NIL_AT((ADDRESS)(btyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 176, 13, 5866))->pbused = 1;
		}
		OPB_BindNodes(3, btyp, &*x, NIL);
	} else {
		OPB_err(84);
	}
}

void OPB_Index (OPT_Node *x, OPT_Node y)
{
	INT16 f;
	OPT_Struct typ = NIL;
	f = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 186, 11, 6081))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 186, 16, 6086))->form;
	if (((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 187, 9, 6102))->class >= 7) {
		OPB_err(79);
	} else if (f != 4 || __IN(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 188, 30, 6166))->class, 0x0300, 32)) {
		OPB_err(80);
		((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 188, 80, 6216))->typ = OPT_inttyp;
	}
	if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 189, 9, 6250))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 189, 14, 6255))->comp == 2) {
		typ = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 189, 46, 6287))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 189, 51, 6292))->BaseTyp;
		if ((((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 190, 12, 6314))->class == 7 && (((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 190, 39, 6341))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 190, 47, 6349))->intval < 0 || ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 190, 66, 6368))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 190, 74, 6376))->intval >= (INT64)((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 190, 87, 6389))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 190, 92, 6394))->n))) {
			OPB_err(81);
		}
	} else if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 191, 12, 6428))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 191, 17, 6433))->comp == 3) {
		typ = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 191, 50, 6466))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 191, 55, 6471))->BaseTyp;
		if ((((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 192, 12, 6493))->class == 7 && ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 192, 38, 6519))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 192, 46, 6527))->intval < 0)) {
			OPB_err(81);
		}
	} else {
		OPB_err(82);
		typ = OPT_undftyp;
	}
	OPB_BindNodes(4, typ, &*x, y);
	((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 195, 40, 6644))->readonly = ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 195, 55, 6659))->left), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 195, 61, 6665))->readonly;
}

void OPB_Field (OPT_Node *x, OPT_Object y)
{
	if (((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 200, 9, 6788))->class >= 7) {
		OPB_err(77);
	}
	if ((y != NIL && __IN(((OPT_Object)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 201, 22, 6850))->mode, 0x2010, 32))) {
		OPB_BindNodes(2, ((OPT_Object)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 202, 30, 6916))->typ, &*x, NIL);
		((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 202, 47, 6933))->obj = y;
		((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 203, 8, 6952))->readonly = ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 203, 23, 6967))->left), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 203, 29, 6973))->readonly || (((OPT_Object)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 203, 46, 6990))->vis == 2 && ((OPT_Object)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 203, 73, 7017))->mnolev < 0);
	} else {
		OPB_err(83);
		((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 204, 20, 7051))->typ = OPT_undftyp;
	}
}

static struct TypTest__58 {
	OPT_Node *x;
	OPT_Object *obj;
	BOOLEAN *guard;
	struct TypTest__58 *lnk;
} *TypTest__58_s;

static void GTT__59 (OPT_Struct t0, OPT_Struct t1);

static void GTT__59 (OPT_Struct t0, OPT_Struct t1)
{
	OPT_Node node = NIL;
	OPT_Struct t = NIL;
	t = t0;
	while ((((t != NIL && t != t1)) && t != OPT_undftyp)) {
		t = ((OPT_Struct)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 213, 63, 7328))->BaseTyp;
	}
	if (t != t1) {
		while ((((t1 != NIL && t1 != t0)) && t1 != OPT_undftyp)) {
			t1 = ((OPT_Struct)__NIL_AT((ADDRESS)(t1), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 215, 70, 7434))->BaseTyp;
		}
		if (t1 == t0 || ((OPT_Struct)__NIL_AT((ADDRESS)(t0), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 216, 28, 7477))->form == 0) {
			if (*TypTest__58_s->guard) {
				OPB_BindNodes(5, NIL, &*TypTest__58_s->x, NIL);
				((OPT_Node)__NIL_AT((ADDRESS)(*TypTest__58_s->x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 217, 62, 7577))->readonly = ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*TypTest__58_s->x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 217, 77, 7592))->left), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 217, 83, 7598))->readonly;
			} else {
				node = OPT_NewNode(11);
				((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 218, 51, 7659))->subcl = 16;
				((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 218, 74, 7682))->left = *TypTest__58_s->x;
				((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 219, 17, 7711))->obj = *TypTest__58_s->obj;
				*TypTest__58_s->x = node;
			}
		} else {
			OPB_err(85);
		}
	} else if (t0 != t1) {
		OPB_err(85);
	} else if (!*TypTest__58_s->guard) {
		if (((OPT_Node)__NIL_AT((ADDRESS)(*TypTest__58_s->x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 225, 13, 7877))->class == 5) {
			node = OPT_NewNode(11);
			((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 226, 46, 7973))->subcl = 16;
			((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 226, 69, 7996))->left = *TypTest__58_s->x;
			((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 227, 15, 8023))->obj = *TypTest__58_s->obj;
			*TypTest__58_s->x = node;
		} else {
			*TypTest__58_s->x = OPB_NewBoolConst(1);
		}
	}
}

void OPB_TypTest (OPT_Node *x, OPT_Object obj, BOOLEAN guard)
{
	struct TypTest__58 _s;
	_s.x = x;
	_s.obj = &obj;
	_s.guard = &guard;
	_s.lnk = TypTest__58_s;
	TypTest__58_s = &_s;
	if (OPB_NotVar(*x)) {
		OPB_err(112);
	} else if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 235, 12, 8170))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 235, 17, 8175))->form == 11) {
		if ((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 236, 12, 8212))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 236, 17, 8217))->BaseTyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 236, 26, 8226))->comp != 4 && ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 236, 51, 8251))->typ != OPT_sysptrtyp)) {
			OPB_err(85);
		} else if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 237, 16, 8302))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 237, 21, 8307))->form == 11) {
			GTT__59(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 237, 52, 8338))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 237, 57, 8343))->BaseTyp, ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 237, 71, 8357))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 237, 76, 8362))->BaseTyp);
		} else {
			OPB_err(86);
		}
	} else if ((((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 240, 13, 8414))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 240, 18, 8419))->comp == 4 && ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 240, 43, 8444))->class == 1)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 240, 72, 8473))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 240, 77, 8478))->comp == 4)) {
		GTT__59(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 241, 12, 8515))->typ, ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 241, 22, 8525))->typ);
	} else {
		OPB_err(87);
	}
	if (guard) {
		((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 244, 20, 8578))->typ = ((OPT_Object)__NIL_AT((ADDRESS)(obj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 244, 32, 8590))->typ;
	} else {
		((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 244, 44, 8602))->typ = OPT_booltyp;
	}
	TypTest__58_s = _s.lnk;
}

void OPB_In (OPT_Node *x, OPT_Node y)
{
	INT16 f;
	INT64 k;
	f = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 249, 15, 8741))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 249, 20, 8746))->form;
	if (((((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 250, 10, 8763))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 250, 36, 8789))->class == 9) || ((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 250, 62, 8815))->class == 8) || ((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 250, 88, 8841))->class == 9) {
		OPB_err(126);
	} else if ((f == 4 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 251, 29, 8904))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 251, 34, 8909))->form == 7)) {
		if (((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 252, 11, 8942))->class == 7) {
			k = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 253, 15, 8982))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 253, 23, 8990))->intval;
			if (k < 0 || k >= (INT64)__ASHL(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 254, 30, 9029))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 254, 34, 9033))->size, 3)) {
				OPB_err(202);
			} else if (((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 255, 16, 9071))->class == 7) {
				((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 255, 43, 9098))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 255, 51, 9106))->intval = OPB_BoolToInt(__IN(k, ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 255, 79, 9134))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 255, 87, 9142))->setval, 64));
				((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 255, 99, 9154))->obj = NIL;
			} else {
				OPB_BindNodes(12, OPT_booltyp, &*x, y);
				((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 256, 55, 9221))->subcl = 15;
			}
		} else {
			OPB_BindNodes(12, OPT_booltyp, &*x, y);
			((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 258, 53, 9303))->subcl = 15;
		}
	} else {
		OPB_err(92);
	}
	((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 262, 6, 9363))->typ = OPT_booltyp;
}

static INT64 OPB_log (INT64 x)
{
	OPB_exp = 0;
	if (x > 0) {
		while (!__ODD(x)) {
			x = __ASHR(x, 1);
			OPB_exp += 1;
		}
	}
	return x;
}

static void OPB_CheckRealType (INT16 f, INT16 nr, OPT_Const x)
{
	LONGREAL min, max, r;
	if (f == 5) {
		min = OPM_MinReal;
		max = OPM_MaxReal;
	} else {
		min = OPM_MinLReal;
		max = OPM_MaxLReal;
	}
	r = __ABS(((OPT_Const)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 279, 15, 9798))->realval);
	if (r > max || r < min) {
		OPB_err(nr);
		((OPT_Const)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 281, 19, 9863))->realval = (LONGREAL)1.0e0;
	} else if (f == 5) {
		((OPT_Const)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 282, 30, 9909))->realval = ((OPT_Const)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 282, 50, 9929))->realval;
	}
	((OPT_Const)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 284, 6, 9984))->intval = -1;
}

static struct MOp__28 {
	struct MOp__28 *lnk;
} *MOp__28_s;

static OPT_Node NewOp__29 (INT8 op, OPT_Struct typ, OPT_Node z);

static OPT_Node NewOp__29 (INT8 op, OPT_Struct typ, OPT_Node z)
{
	OPT_Node node = NIL;
	node = OPT_NewNode(11);
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 293, 42, 10288))->subcl = op;
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 293, 61, 10307))->typ = typ;
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 294, 11, 10331))->left = z;
	return node;
}

void OPB_MOp (INT8 op, OPT_Node *x)
{
	INT16 f;
	OPT_Struct typ = NIL;
	OPT_Node z = NIL;
	struct MOp__28 _s;
	_s.lnk = MOp__28_s;
	MOp__28_s = &_s;
	z = *x;
	if (((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 298, 10, 10397))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 298, 36, 10423))->class == 9) {
		OPB_err(126);
	} else {
		typ = ((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 299, 18, 10475))->typ;
		f = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 299, 33, 10490))->form;
		switch (op) {
			case 33: 
				if (f == 2) {
					if (((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 302, 25, 10578))->class == 7) {
						((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 303, 24, 10627))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 303, 32, 10635))->intval = OPB_BoolToInt(!OPB_IntToBool(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 303, 66, 10669))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 303, 74, 10677))->intval));
						((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 303, 87, 10690))->obj = NIL;
					} else {
						z = NewOp__29(op, typ, z);
					}
				} else {
					OPB_err(98);
				}
				break;
			case 6: 
				if (!__IN(f, 0x70, 32)) {
					OPB_err(96);
				}
				break;
			case 7: 
				if (__IN(f, 0xf0, 32)) {
					if (((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 310, 25, 10986))->class == 7) {
						if (f == 4) {
							if (((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 312, 29, 11082))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 312, 37, 11090))->intval == (-9223372036854775807LL-1)) {
								OPB_err(203);
							} else {
								((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 313, 31, 11163))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 313, 39, 11171))->intval = -((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 313, 53, 11185))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 313, 61, 11193))->intval;
								OPB_SetIntType(z);
							}
						} else if (__IN(f, 0x60, 32)) {
							((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 315, 52, 11296))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 315, 60, 11304))->realval = -((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 315, 75, 11319))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 315, 83, 11327))->realval;
						} else {
							if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 317, 29, 11392))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 317, 33, 11396))->size == 8) {
								((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 318, 28, 11438))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 318, 36, 11446))->setval = ~((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 318, 50, 11460))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 318, 58, 11468))->setval;
							} else {
								((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 320, 28, 11533))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 320, 35, 11540))->setval = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 320, 47, 11552))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 320, 54, 11559))->setval ^ 0xffffffff;
							}
						}
						((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 323, 24, 11655))->obj = NIL;
					} else {
						z = NewOp__29(op, typ, z);
					}
				} else {
					OPB_err(97);
				}
				break;
			case 21: 
				if (__IN(f, 0x70, 32)) {
					if (((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 329, 25, 11872))->class == 7) {
						if (f == 4) {
							if (((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 331, 29, 11968))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 331, 37, 11976))->intval == (-9223372036854775807LL-1)) {
								OPB_err(203);
							} else {
								((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 332, 31, 12049))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 332, 39, 12057))->intval = __ABS(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 332, 56, 12074))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 332, 64, 12082))->intval);
								OPB_SetIntType(z);
							}
						} else {
							((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 334, 29, 12163))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 334, 37, 12171))->realval = __ABS(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 334, 55, 12189))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 334, 63, 12197))->realval);
						}
						((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 336, 24, 12259))->obj = NIL;
					} else {
						z = NewOp__29(op, typ, z);
					}
				} else {
					OPB_err(111);
				}
				break;
			case 22: 
				if (f == 3) {
					if (((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 342, 25, 12461))->class == 7) {
						((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 343, 24, 12510))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 343, 32, 12518))->intval = (INT16)__CAP(__CHR(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 343, 57, 12543))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 343, 65, 12551))->intval));
						((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 343, 79, 12565))->obj = NIL;
					} else {
						z = NewOp__29(op, typ, z);
					}
				} else {
					OPB_err(111);
					((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 346, 35, 12684))->typ = OPT_chartyp;
				}
				break;
			case 23: 
				if (f == 4) {
					if (((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 349, 25, 12789))->class == 7) {
						((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 350, 24, 12838))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 350, 32, 12846))->intval = OPB_BoolToInt(__ODD(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 350, 59, 12873))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 350, 67, 12881))->intval));
						((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 350, 80, 12894))->obj = NIL;
					} else {
						z = NewOp__29(op, typ, z);
					}
				} else {
					OPB_err(111);
				}
				((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 355, 20, 13054))->typ = OPT_booltyp;
				break;
			case 24: 
				if ((((((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 356, 24, 13098))->class == 7 && f == 3)) && ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 356, 67, 13141))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 356, 75, 13149))->intval >= 32)) {
					OPB_CharToString(z);
					f = 8;
				}
				if ((((((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 359, 24, 13288))->class == 0 && ((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 359, 48, 13312))->obj != NIL)) && __IN(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 360, 25, 13351))->obj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 360, 30, 13356))->mode, 0xc000, 32))) {
					OPB_err(127);
				}
				if (((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 361, 24, 13435))->class < 7 || f == 8) {
					z = NewOp__29(op, typ, z);
				} else {
					OPB_err(127);
				}
				((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 364, 20, 13580))->typ = OPT_adrtyp;
				break;
			case 25: 
				if ((f == 4 && ((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 365, 40, 13639))->class == 7)) {
					if ((0 <= ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 366, 31, 13739))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 366, 39, 13747))->intval && ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 366, 53, 13761))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 366, 61, 13769))->intval <= -1)) {
						z = NewOp__29(op, typ, z);
					} else {
						OPB_err(219);
					}
				} else {
					OPB_err(69);
				}
				((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 369, 20, 13912))->typ = OPT_booltyp;
				break;
			default: 
				OPM_LogWStr((CHAR*)"unhandled case in OPB.MOp, op = ", 33);
				OPM_LogWNum(op, 0);
				OPM_LogWLn();
				break;
		}
	}
	*x = z;
	MOp__28_s = _s.lnk;
}

static void OPB_CheckPtr (OPT_Node x, OPT_Node y)
{
	INT16 g;
	OPT_Struct p = NIL, q = NIL, t = NIL;
	g = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 378, 15, 14161))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 378, 20, 14166))->form;
	if (g == 11) {
		p = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 380, 13, 14214))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 380, 18, 14219))->BaseTyp;
		q = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 380, 35, 14236))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 380, 40, 14241))->BaseTyp;
		if ((((OPT_Struct)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 381, 12, 14263))->comp == 4 && ((OPT_Struct)__NIL_AT((ADDRESS)(q), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 381, 37, 14288))->comp == 4)) {
			if (((OPT_Struct)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 382, 13, 14326))->extlev < ((OPT_Struct)__NIL_AT((ADDRESS)(q), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 382, 25, 14338))->extlev) {
				t = p;
				p = q;
				q = t;
			}
			while ((((p != q && p != NIL)) && p != OPT_undftyp)) {
				p = ((OPT_Struct)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 383, 64, 14444))->BaseTyp;
			}
			if (p == NIL) {
				OPB_err(100);
			}
		} else {
			OPB_err(100);
		}
	} else if (g != 9) {
		OPB_err(100);
	}
}

void OPB_CheckParameters (OPT_Object fp, OPT_Object ap, BOOLEAN checkNames)
{
	OPT_Struct ft = NIL, at = NIL;
	while (fp != NIL) {
		if (ap != NIL) {
			ft = ((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 396, 17, 14759))->typ;
			at = ((OPT_Object)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 396, 32, 14774))->typ;
			while ((((OPT_Struct)__NIL_AT((ADDRESS)(ft), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 397, 18, 14798))->comp == 3 && ((OPT_Struct)__NIL_AT((ADDRESS)(at), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 397, 44, 14824))->comp == 3)) {
				ft = ((OPT_Struct)__NIL_AT((ADDRESS)(ft), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 398, 19, 14866))->BaseTyp;
				at = ((OPT_Struct)__NIL_AT((ADDRESS)(at), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 398, 38, 14885))->BaseTyp;
			}
			if (ft != at) {
				if ((((OPT_Struct)__NIL_AT((ADDRESS)(ft), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 401, 17, 14949))->form == 12 && ((OPT_Struct)__NIL_AT((ADDRESS)(at), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 401, 44, 14976))->form == 12)) {
					if (((OPT_Struct)__NIL_AT((ADDRESS)(ft), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 402, 18, 15020))->BaseTyp == ((OPT_Struct)__NIL_AT((ADDRESS)(at), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 402, 32, 15034))->BaseTyp) {
						OPB_CheckParameters(((OPT_Struct)__NIL_AT((ADDRESS)(ft), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 402, 65, 15067))->link, ((OPT_Struct)__NIL_AT((ADDRESS)(at), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 402, 75, 15077))->link, 0);
					} else {
						OPB_err(117);
					}
				} else {
					OPB_err(115);
				}
			}
			if (((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 408, 15, 15200))->mode != ((OPT_Object)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 408, 26, 15211))->mode || (checkNames && __STRCMP(((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 408, 53, 15238))->name, ((OPT_Object)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 408, 64, 15249))->name) != 0)) {
				OPB_err(115);
			}
			ap = ((OPT_Object)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 409, 17, 15293))->link;
		} else {
			OPB_err(116);
		}
		fp = ((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 412, 15, 15346))->link;
	}
	if (ap != NIL) {
		OPB_err(116);
	}
}

static void OPB_CheckProc (OPT_Struct x, OPT_Object y)
{
	if (__IN(((OPT_Object)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 419, 9, 15539))->mode, 0x04c0, 32)) {
		if (((OPT_Object)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 420, 11, 15598))->mode == 6) {
			if (((OPT_Object)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 421, 13, 15634))->mnolev == 0) {
				((OPT_Object)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 421, 32, 15653))->mode = 7;
			} else {
				OPB_err(73);
			}
		}
		if (((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 425, 11, 15728))->BaseTyp == ((OPT_Object)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 425, 24, 15741))->typ) {
			OPB_CheckParameters(((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 425, 52, 15769))->link, ((OPT_Object)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 425, 61, 15778))->link, 0);
		} else {
			OPB_err(117);
		}
	} else {
		OPB_err(113);
	}
}

static struct ConstOp__13 {
	OPT_Node *x;
	INT16 *f;
	OPT_Const *xval, *yval;
	struct ConstOp__13 *lnk;
} *ConstOp__13_s;

static INT16 ConstCmp__14 (void);

static INT16 ConstCmp__14 (void)
{
	INT16 res;
	switch (*ConstOp__13_s->f) {
		case 0: 
			res = 9;
			break;
		case 1: case 3: case 4: 
			if (((OPT_Const)__NIL_AT((ADDRESS)(*ConstOp__13_s->xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 443, 27, 16214))->intval < ((OPT_Const)__NIL_AT((ADDRESS)(*ConstOp__13_s->yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 443, 42, 16229))->intval) {
				res = 11;
			} else if (((OPT_Const)__NIL_AT((ADDRESS)(*ConstOp__13_s->xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 444, 31, 16288))->intval > ((OPT_Const)__NIL_AT((ADDRESS)(*ConstOp__13_s->yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 444, 46, 16303))->intval) {
				res = 13;
			} else {
				res = 9;
			}
			break;
		case 5: case 6: 
			if (((OPT_Const)__NIL_AT((ADDRESS)(*ConstOp__13_s->xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 448, 28, 16440))->realval < ((OPT_Const)__NIL_AT((ADDRESS)(*ConstOp__13_s->yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 448, 44, 16456))->realval) {
				res = 11;
			} else if (((OPT_Const)__NIL_AT((ADDRESS)(*ConstOp__13_s->xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 449, 31, 16516))->realval > ((OPT_Const)__NIL_AT((ADDRESS)(*ConstOp__13_s->yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 449, 47, 16532))->realval) {
				res = 13;
			} else {
				res = 9;
			}
			break;
		case 2: 
			if (((OPT_Const)__NIL_AT((ADDRESS)(*ConstOp__13_s->xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 452, 28, 16653))->intval != ((OPT_Const)__NIL_AT((ADDRESS)(*ConstOp__13_s->yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 452, 43, 16668))->intval) {
				res = 10;
			} else {
				res = 9;
			}
			break;
		case 7: 
			if (((OPT_Const)__NIL_AT((ADDRESS)(*ConstOp__13_s->xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 455, 28, 16788))->setval != ((OPT_Const)__NIL_AT((ADDRESS)(*ConstOp__13_s->yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 455, 43, 16803))->setval) {
				res = 10;
			} else {
				res = 9;
			}
			break;
		case 8: 
			if (__STRCMP(*((OPT_ConstExt)__NIL_AT((ADDRESS)(((OPT_Const)__NIL_AT((ADDRESS)(*ConstOp__13_s->xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 458, 28, 16923))->ext), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 458, 33, 16928)), *((OPT_ConstExt)__NIL_AT((ADDRESS)(((OPT_Const)__NIL_AT((ADDRESS)(*ConstOp__13_s->yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 458, 41, 16936))->ext), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 458, 46, 16941))) < 0) {
				res = 11;
			} else if (__STRCMP(*((OPT_ConstExt)__NIL_AT((ADDRESS)(((OPT_Const)__NIL_AT((ADDRESS)(*ConstOp__13_s->xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 459, 31, 16993))->ext), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 459, 36, 16998)), *((OPT_ConstExt)__NIL_AT((ADDRESS)(((OPT_Const)__NIL_AT((ADDRESS)(*ConstOp__13_s->yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 459, 44, 17006))->ext), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 459, 49, 17011))) > 0) {
				res = 13;
			} else {
				res = 9;
			}
			break;
		case 9: case 11: case 12: 
			if (((OPT_Const)__NIL_AT((ADDRESS)(*ConstOp__13_s->xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 464, 28, 17163))->intval != ((OPT_Const)__NIL_AT((ADDRESS)(*ConstOp__13_s->yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 464, 43, 17178))->intval) {
				res = 10;
			} else {
				res = 9;
			}
			break;
		default: 
			OPM_LogWStr((CHAR*)"unhandled case in OPB.ConstCmp, f = ", 37);
			OPM_LogWNum(*ConstOp__13_s->f, 0);
			OPM_LogWLn();
			break;
	}
	((OPT_Node)__NIL_AT((ADDRESS)(*ConstOp__13_s->x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 469, 8, 17385))->typ = OPT_booltyp;
	return res;
}

static void OPB_ConstOp (INT16 op, OPT_Node x, OPT_Node y)
{
	INT16 f, g;
	OPT_Const xval = NIL, yval = NIL;
	INT64 xv, yv;
	BOOLEAN temp;
	struct ConstOp__13 _s;
	_s.x = &x;
	_s.f = &f;
	_s.xval = &xval;
	_s.yval = &yval;
	_s.lnk = ConstOp__13_s;
	ConstOp__13_s = &_s;
	f = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 474, 11, 17522))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 474, 16, 17527))->form;
	g = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 474, 30, 17541))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 474, 35, 17546))->form;
	xval = ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 474, 52, 17563))->conval;
	yval = ((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 474, 71, 17582))->conval;
	if (f != g) {
		switch (f) {
			case 3: 
				if (g == 8) {
					OPB_CharToString(x);
				} else {
					OPB_err(100);
					((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 478, 37, 17721))->typ = ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 478, 47, 17731))->typ;
					__GUARDEQPN_AT(yval, OPT_ConstDesc, (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 478, 58, 17742) = *((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 478, 67, 17751));
				}
				break;
			case 4: 
				if (g == 4) {
					if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 481, 27, 17845))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 481, 31, 17849))->size <= ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 481, 41, 17859))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 481, 45, 17863))->size) {
						((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 481, 57, 17875))->typ = ((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 481, 66, 17884))->typ;
					} else {
						((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 481, 77, 17895))->typ = OPT_IntType(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 481, 98, 17916))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 481, 102, 17920))->size);
					}
				} else if (g == 5) {
					((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 482, 46, 17976))->typ = OPT_realtyp;
					((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 482, 72, 18002))->realval = ((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 482, 89, 18019))->intval;
				} else if (g == 6) {
					((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 483, 47, 18074))->typ = OPT_lrltyp;
					((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 483, 72, 18099))->realval = ((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 483, 89, 18116))->intval;
				} else {
					OPB_err(100);
					((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 484, 38, 18162))->typ = ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 484, 48, 18172))->typ;
					__GUARDEQPN_AT(yval, OPT_ConstDesc, (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 484, 59, 18183) = *((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 484, 68, 18192));
				}
				break;
			case 5: 
				if (g == 4) {
					((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 486, 42, 18259))->typ = ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 486, 52, 18269))->typ;
					((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 486, 63, 18280))->realval = ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 486, 80, 18297))->intval;
				} else if (g == 6) {
					((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 487, 47, 18352))->typ = OPT_lrltyp;
				} else {
					OPB_err(100);
					((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 488, 38, 18409))->typ = ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 488, 48, 18419))->typ;
					__GUARDEQPN_AT(yval, OPT_ConstDesc, (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 488, 59, 18430) = *((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 488, 68, 18439));
				}
				break;
			case 6: 
				if (g == 4) {
					((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 490, 42, 18506))->typ = ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 490, 52, 18516))->typ;
					((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 490, 63, 18527))->realval = ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 490, 80, 18544))->intval;
				} else if (g == 5) {
					((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 491, 46, 18598))->typ = OPT_lrltyp;
				} else {
					OPB_err(100);
					((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 492, 38, 18655))->typ = ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 492, 48, 18665))->typ;
					__GUARDEQPN_AT(yval, OPT_ConstDesc, (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 492, 59, 18676) = *((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 492, 68, 18685));
				}
				break;
			case 8: 
				if (g == 3) {
					OPB_CharToString(y);
					g = 8;
				} else {
					OPB_err(100);
					((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 495, 37, 18821))->typ = ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 495, 47, 18831))->typ;
					__GUARDEQPN_AT(yval, OPT_ConstDesc, (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 495, 58, 18842) = *((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 495, 67, 18851));
				}
				break;
			case 9: 
				if (!__IN(g, 0x1800, 32)) {
					OPB_err(100);
				}
				break;
			case 11: 
				OPB_CheckPtr(x, y);
				break;
			case 12: 
				if (g != 9) {
					OPB_err(100);
				}
				break;
			default: 
				OPB_err(100);
				((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 500, 23, 19068))->typ = ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 500, 33, 19078))->typ;
				__GUARDEQPN_AT(yval, OPT_ConstDesc, (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 500, 44, 19089) = *((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 500, 53, 19098));
				break;
		}
		f = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 502, 13, 19124))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 502, 18, 19129))->form;
	}
	switch (op) {
		case 1: 
			if (f == 4) {
				xv = ((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 505, 47, 19232))->intval;
				yv = ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 505, 67, 19252))->intval;
				if (((((xv == 0 || yv == 0) || (((xv > 0 && yv > 0)) && yv <= __DIV(9223372036854775807LL, xv))) || (((xv > 0 && yv < 0)) && yv >= __DIV((-9223372036854775807LL-1), xv))) || (((xv < 0 && yv > 0)) && xv >= __DIV((-9223372036854775807LL-1), yv))) || (((((((xv < 0 && yv < 0)) && xv != (-9223372036854775807LL-1))) && yv != (-9223372036854775807LL-1))) && -xv <= __DIV(9223372036854775807LL, -yv))) {
					((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 511, 25, 19757))->intval = xv * yv;
					OPB_SetIntType(x);
				} else {
					OPB_err(204);
				}
			} else if (__IN(f, 0x60, 32)) {
				temp = __ABS(((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 515, 35, 19924))->realval) <= (LONGREAL)1.0e0;
				if (temp || __ABS(((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 516, 39, 19981))->realval) <= (LONGREAL)1.7976931348623157e308 / (LONGREAL)__ABS(((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 516, 77, 20019))->realval)) {
					((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 517, 25, 20060))->realval = ((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 517, 42, 20077))->realval * ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 517, 58, 20093))->realval;
					OPB_CheckRealType(f, 204, xval);
				} else {
					OPB_err(204);
				}
			} else if (f == 7) {
				((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 521, 23, 20247))->setval = (((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 521, 39, 20263))->setval & ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 521, 54, 20278))->setval);
				OPB_SetSetType(x);
			} else if (f != 0) {
				OPB_err(101);
			}
			break;
		case 2: 
			if (f == 4) {
				if (((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 525, 26, 20433))->intval != 0) {
					((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 526, 25, 20475))->realval = ((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 526, 42, 20492))->intval / (REAL)((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 526, 57, 20507))->intval;
					OPB_CheckRealType(5, 205, xval);
				} else {
					OPB_err(205);
					((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 527, 38, 20589))->realval = (LONGREAL)1.0e0;
				}
				((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 529, 20, 20649))->typ = OPT_realtyp;
			} else if (__IN(f, 0x60, 32)) {
				temp = __ABS(((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 531, 35, 20748))->realval) >= (LONGREAL)1.0e0;
				if (temp || __ABS(((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 532, 39, 20805))->realval) <= (LONGREAL)1.7976931348623157e308 * __ABS(((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 532, 77, 20843))->realval)) {
					((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 533, 25, 20884))->realval = ((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 533, 42, 20901))->realval / ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 533, 58, 20917))->realval;
					OPB_CheckRealType(f, 205, xval);
				} else {
					OPB_err(205);
				}
			} else if (f == 7) {
				((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 537, 23, 21071))->setval = ((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 537, 39, 21087))->setval ^ ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 537, 54, 21102))->setval;
				OPB_SetSetType(x);
			} else if (f != 0) {
				OPB_err(102);
			}
			break;
		case 3: 
			if (f == 4) {
				if (((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 541, 26, 21257))->intval != 0) {
					((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 542, 25, 21299))->intval = __DIV(((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 542, 41, 21315))->intval, ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 542, 58, 21332))->intval);
					OPB_SetIntType(x);
				} else {
					OPB_err(205);
				}
			} else if (f != 0) {
				OPB_err(103);
			}
			break;
		case 4: 
			if (f == 4) {
				if (((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 548, 26, 21541))->intval != 0) {
					((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 549, 25, 21583))->intval = __MOD(((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 549, 41, 21599))->intval, ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 549, 58, 21616))->intval);
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
				((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 555, 23, 21823))->intval = OPB_BoolToInt((OPB_IntToBool(((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 555, 59, 21859))->intval) && OPB_IntToBool(((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 555, 85, 21885))->intval)));
			} else {
				OPB_err(94);
			}
			break;
		case 6: 
			if (f == 4) {
				temp = (((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 559, 32, 22012))->intval >= 0 && ((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 559, 54, 22034))->intval <= 9223372036854775807LL - ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 559, 90, 22070))->intval);
				if (temp || (((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 560, 35, 22115))->intval < 0 && ((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 560, 56, 22136))->intval >= (-9223372036854775807LL-1) - ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 560, 92, 22172))->intval)) {
					((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 561, 31, 22217))->intval += ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 561, 45, 22231))->intval;
					OPB_SetIntType(x);
				} else {
					OPB_err(206);
				}
			} else if (__IN(f, 0x60, 32)) {
				temp = (((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 565, 32, 22385))->realval >= (LONGREAL)0.0e0 && ((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 565, 57, 22410))->realval <= (LONGREAL)1.7976931348623157e308 - ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 565, 90, 22443))->realval);
				if (temp || (((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 566, 35, 22489))->realval < (LONGREAL)0.0e0 && ((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 566, 59, 22513))->realval >= (LONGREAL)-1.7976931348623157e308 - ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 566, 93, 22547))->realval)) {
					((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 567, 27, 22589))->realval = ((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 567, 44, 22606))->realval + ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 567, 60, 22622))->realval;
					OPB_CheckRealType(f, 206, xval);
				} else {
					OPB_err(206);
				}
			} else if (f == 7) {
				((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 571, 23, 22776))->setval = ((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 571, 39, 22792))->setval | ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 571, 54, 22807))->setval;
				OPB_SetSetType(x);
			} else if (f != 0) {
				OPB_err(105);
			}
			break;
		case 7: 
			if (f == 4) {
				if ((((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 575, 27, 22963))->intval >= 0 && ((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 575, 49, 22985))->intval >= (-9223372036854775807LL-1) + ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 575, 85, 23021))->intval) || (((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 576, 26, 23059))->intval < 0 && ((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 576, 47, 23080))->intval <= 9223372036854775807LL + ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 576, 84, 23117))->intval)) {
					((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 577, 31, 23162))->intval -= ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 577, 45, 23176))->intval;
					OPB_SetIntType(x);
				} else {
					OPB_err(207);
				}
			} else if (__IN(f, 0x60, 32)) {
				temp = (((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 581, 32, 23330))->realval >= (LONGREAL)0.0e0 && ((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 581, 57, 23355))->realval >= (LONGREAL)-1.7976931348623157e308 + ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 581, 91, 23389))->realval);
				if (temp || (((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 582, 35, 23435))->realval < (LONGREAL)0.0e0 && ((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 582, 59, 23459))->realval <= (LONGREAL)1.7976931348623157e308 + ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 582, 92, 23492))->realval)) {
					((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 583, 27, 23534))->realval = ((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 583, 44, 23551))->realval - ((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 583, 60, 23567))->realval;
					OPB_CheckRealType(f, 207, xval);
				} else {
					OPB_err(207);
				}
			} else if (f == 7) {
				((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 587, 23, 23721))->setval = (((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 587, 39, 23737))->setval & ~((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 587, 54, 23752))->setval);
				OPB_SetSetType(x);
			} else if (f != 0) {
				OPB_err(106);
			}
			break;
		case 8: 
			if (f == 2) {
				((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 591, 23, 23905))->intval = OPB_BoolToInt(OPB_IntToBool(((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 591, 59, 23941))->intval) || OPB_IntToBool(((OPT_Const)__NIL_AT((ADDRESS)(yval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 591, 86, 23968))->intval));
			} else {
				OPB_err(95);
			}
			break;
		case 9: 
			((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 594, 21, 24048))->intval = OPB_BoolToInt(ConstCmp__14() == 9);
			break;
		case 10: 
			((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 595, 21, 24112))->intval = OPB_BoolToInt(ConstCmp__14() != 9);
			break;
		case 11: 
			if (__IN(f, 0x0a84, 32)) {
				OPB_err(108);
			} else {
				((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 597, 26, 24264))->intval = OPB_BoolToInt(ConstCmp__14() == 11);
			}
			break;
		case 12: 
			if (__IN(f, 0x0a84, 32)) {
				OPB_err(108);
			} else {
				((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 600, 26, 24436))->intval = OPB_BoolToInt(ConstCmp__14() != 13);
			}
			break;
		case 13: 
			if (__IN(f, 0x0a84, 32)) {
				OPB_err(108);
			} else {
				((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 603, 26, 24608))->intval = OPB_BoolToInt(ConstCmp__14() == 13);
			}
			break;
		case 14: 
			if (__IN(f, 0x0a84, 32)) {
				OPB_err(108);
			} else {
				((OPT_Const)__NIL_AT((ADDRESS)(xval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 606, 26, 24780))->intval = OPB_BoolToInt(ConstCmp__14() != 11);
			}
			break;
		default: 
			OPM_LogWStr((CHAR*)"unhandled case in OPB.ConstOp, op = ", 37);
			OPM_LogWNum(op, 0);
			OPM_LogWLn();
			break;
	}
	ConstOp__13_s = _s.lnk;
}

static void OPB_Convert (OPT_Node *x, OPT_Struct typ)
{
	OPT_Node node = NIL;
	INT16 f, g;
	INT64 k;
	LONGREAL r;
	f = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 615, 15, 25144))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 615, 20, 25149))->form;
	g = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 615, 36, 25165))->form;
	if (((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 616, 9, 25213))->class == 7) {
		if ((((f == 7 && g == 7)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 617, 44, 25282))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 617, 48, 25286))->size > ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 617, 59, 25297))->size)) {
			OPB_SetSetType(*x);
			if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 619, 13, 25344))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 619, 17, 25348))->size > ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 619, 28, 25359))->size) {
				OPB_err(203);
				((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 619, 50, 25381))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 619, 58, 25389))->setval = 0x0;
			}
		} else if (f == 4) {
			if (g == 4) {
				if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 622, 15, 25479))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 622, 19, 25483))->size > ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 622, 30, 25494))->size) {
					OPB_SetIntType(*x);
					if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 623, 17, 25536))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 623, 21, 25540))->size > ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 623, 32, 25551))->size) {
						OPB_err(203);
						((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 623, 54, 25573))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 623, 62, 25581))->intval = 1;
					}
				}
			} else if (__IN(g, 0x60, 32)) {
				((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 625, 38, 25650))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 625, 46, 25658))->realval = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 625, 60, 25672))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 625, 68, 25680))->intval;
				((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 625, 79, 25691))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 625, 87, 25699))->intval = -1;
			} else {
				k = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 626, 37, 25765))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 626, 45, 25773))->intval;
				if (0 > k || k > 255) {
					OPB_err(220);
				}
			}
		} else if (__IN(f, 0x60, 32)) {
			if (__IN(g, 0x60, 32)) {
				OPB_CheckRealType(g, 203, ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 630, 57, 25938))->conval);
			} else {
				r = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 632, 17, 25995))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 632, 25, 26003))->realval;
				if (r < (LONGREAL)-9.2233720368547758e18 || r > (LONGREAL)9.2233720368547758e18) {
					OPB_err(203);
					r = (LONGREAL)1.0e0;
				}
				((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 634, 12, 26117))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 634, 20, 26125))->intval = __SHORT(__ENTIER(r), 2147483648LL);
				OPB_SetIntType(*x);
			}
		}
		((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 638, 8, 26290))->obj = NIL;
	} else if ((((((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 639, 13, 26315))->class == 11 && ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 639, 37, 26339))->subcl == 20)) && ((INT16)((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 639, 62, 26364))->left), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 639, 68, 26370))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 639, 73, 26375))->form < f || f > g))) {
		if (((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 641, 11, 26448))->left), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 641, 17, 26454))->typ == typ) {
			*x = ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 641, 73, 26510))->left;
		}
	} else {
		node = OPT_NewNode(11);
		((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 642, 45, 26565))->subcl = 20;
		((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 642, 70, 26590))->left = *x;
		*x = node;
	}
	((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 644, 6, 26628))->typ = typ;
}

static struct Op__38 {
	INT16 *f, *g;
	struct Op__38 *lnk;
} *Op__38_s;

static void NewOp__39 (INT8 op, OPT_Struct typ, OPT_Node *x, OPT_Node y);
static BOOLEAN strings__41 (OPT_Node *x, OPT_Node *y);

static void NewOp__39 (INT8 op, OPT_Struct typ, OPT_Node *x, OPT_Node y)
{
	OPT_Node node = NIL;
	node = OPT_NewNode(12);
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 653, 42, 26966))->subcl = op;
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 653, 61, 26985))->typ = typ;
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 654, 11, 27009))->left = *x;
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 654, 28, 27026))->right = y;
	*x = node;
}

static BOOLEAN strings__41 (OPT_Node *x, OPT_Node *y)
{
	BOOLEAN ok, xCharArr, yCharArr;
	xCharArr = (__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 660, 22, 27192))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 660, 27, 27197))->comp, 0x0c, 32) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 660, 66, 27236))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 660, 71, 27241))->BaseTyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 660, 80, 27250))->form == 3) || *Op__38_s->f == 8;
	yCharArr = (__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 661, 23, 27309))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 661, 28, 27314))->comp, 0x0c, 32) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 661, 67, 27353))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 661, 72, 27358))->BaseTyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 661, 81, 27367))->form == 3) || *Op__38_s->g == 8;
	if ((((xCharArr && *Op__38_s->g == 3)) && ((OPT_Node)__NIL_AT((ADDRESS)(*y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 662, 40, 27444))->class == 7)) {
		OPB_CharToString(*y);
		*Op__38_s->g = 8;
		yCharArr = 1;
	}
	if ((((yCharArr && *Op__38_s->f == 3)) && ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 663, 40, 27567))->class == 7)) {
		OPB_CharToString(*x);
		*Op__38_s->f = 8;
		xCharArr = 1;
	}
	ok = (xCharArr && yCharArr);
	if (ok) {
		if ((*Op__38_s->f == 8 && ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 666, 31, 27798))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 666, 39, 27806))->intval2 == 1)) {
			((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 667, 12, 27863))->typ = OPT_chartyp;
			((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 667, 35, 27886))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 667, 43, 27894))->intval = 0;
			OPB_Index(&*y, OPB_NewIntConst(0));
		} else if ((*Op__38_s->g == 8 && ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 669, 34, 27977))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 669, 42, 27985))->intval2 == 1)) {
			((OPT_Node)__NIL_AT((ADDRESS)(*y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 670, 12, 28042))->typ = OPT_chartyp;
			((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 670, 35, 28065))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 670, 43, 28073))->intval = 0;
			OPB_Index(&*x, OPB_NewIntConst(0));
		}
	}
	return ok;
}

void OPB_Op (INT8 op, OPT_Node *x, OPT_Node y)
{
	INT16 f, g;
	OPT_Node t = NIL, z = NIL;
	OPT_Struct typ = NIL;
	BOOLEAN do_;
	INT64 val;
	struct Op__38 _s;
	_s.f = &f;
	_s.g = &g;
	_s.lnk = Op__38_s;
	Op__38_s = &_s;
	z = *x;
	if (((((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 679, 10, 28207))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 679, 36, 28233))->class == 9) || ((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 679, 62, 28259))->class == 8) || ((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 679, 88, 28285))->class == 9) {
		OPB_err(126);
	} else if ((((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 680, 13, 28332))->class == 7 && ((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 680, 39, 28358))->class == 7)) {
		OPB_ConstOp(op, z, y);
		((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 680, 86, 28405))->obj = NIL;
	} else {
		if (((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 682, 11, 28437))->typ != ((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 682, 20, 28446))->typ) {
			g = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 683, 15, 28471))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 683, 20, 28476))->form;
			switch (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 684, 15, 28498))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 684, 20, 28503))->form) {
				case 3: 
					if (((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 685, 27, 28539))->class == 7) {
						OPB_CharToString(z);
					} else {
						OPB_err(100);
					}
					break;
				case 4: 
					if ((g == 4 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 686, 44, 28642))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 686, 48, 28646))->size < ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 686, 57, 28655))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 686, 61, 28659))->size)) {
						OPB_Convert(&y, ((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 686, 85, 28683))->typ);
					} else if (__IN(g, 0x70, 32)) {
						OPB_Convert(&z, ((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 687, 85, 28773))->typ);
					} else {
						OPB_err(100);
					}
					break;
				case 7: 
					if ((g == 7 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 690, 44, 28884))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 690, 48, 28888))->size < ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 690, 57, 28897))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 690, 61, 28901))->size)) {
						OPB_Convert(&y, ((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 690, 85, 28925))->typ);
					} else if (g == 7) {
						OPB_Convert(&z, ((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 691, 85, 29015))->typ);
					} else {
						OPB_err(100);
					}
					break;
				case 5: 
					if (g == 4) {
						OPB_Convert(&y, ((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 694, 55, 29137))->typ);
					} else if (__IN(g, 0x60, 32)) {
						OPB_Convert(&z, ((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 695, 63, 29206))->typ);
					} else {
						OPB_err(100);
					}
					break;
				case 6: 
					if (__IN(g, 0x70, 32)) {
						OPB_Convert(&y, ((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 698, 72, 29347))->typ);
					} else if (__IN(g, 0x60, 32)) {
						OPB_Convert(&y, ((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 699, 63, 29416))->typ);
					} else {
						OPB_err(100);
					}
					break;
				case 9: 
					if (!__IN(g, 0x1800, 32)) {
						OPB_err(100);
					}
					break;
				case 11: 
					OPB_CheckPtr(z, y);
					break;
				case 12: 
					if (g != 9) {
						OPB_err(100);
					}
					break;
				case 8: 
					break;
				case 13: 
					if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 706, 27, 29758))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 706, 32, 29763))->comp == 4) {
						OPB_err(100);
					}
					break;
				default: 
					OPB_err(100);
					break;
			}
		}
		typ = ((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 710, 15, 29886))->typ;
		f = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 710, 30, 29901))->form;
		g = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 710, 44, 29915))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 710, 49, 29920))->form;
		switch (op) {
			case 1: 
				do_ = 1;
				if (f == 4) {
					if (((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 714, 25, 30037))->class == 7) {
						val = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 714, 59, 30071))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 714, 67, 30079))->intval;
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
							((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 719, 41, 30334))->typ = OPT_sinttyp;
							((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 719, 64, 30357))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 719, 72, 30365))->intval = OPB_exp;
							((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 719, 90, 30383))->obj = NIL;
						}
					} else if (((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 721, 28, 30449))->class == 7) {
						val = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 721, 62, 30483))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 721, 70, 30491))->intval;
						if (val == 1) {
							do_ = 0;
						} else if (val == 0) {
							do_ = 0;
							z = y;
						} else if (OPB_log(val) == 1) {
							op = 17;
							((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 725, 41, 30698))->typ = OPT_sinttyp;
							((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 725, 64, 30721))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 725, 72, 30729))->intval = OPB_exp;
							((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 725, 90, 30747))->obj = NIL;
						}
					}
				} else if (!__IN(f, 0xe1, 32)) {
					OPB_err(105);
					typ = OPT_undftyp;
				}
				if (do_) {
					NewOp__39(op, typ, &z, y);
				}
				break;
			case 2: 
				if (f == 4) {
					if ((((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 732, 26, 31048))->class == 7 && ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 732, 52, 31074))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 732, 60, 31082))->intval == 0)) {
						OPB_err(205);
					}
					OPB_Convert(&z, OPT_realtyp);
					OPB_Convert(&y, OPT_realtyp);
					typ = OPT_realtyp;
				} else if (__IN(f, 0x60, 32)) {
					if ((((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 736, 26, 31296))->class == 7 && ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 736, 52, 31322))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 736, 60, 31330))->realval == (LONGREAL)0.0e0)) {
						OPB_err(205);
					}
				} else if ((f != 7 && f != 0)) {
					OPB_err(102);
					typ = OPT_undftyp;
				}
				NewOp__39(op, typ, &z, y);
				break;
			case 3: 
				do_ = 1;
				if (f == 4) {
					if (((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 742, 25, 31610))->class == 7) {
						val = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 742, 59, 31644))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 742, 67, 31652))->intval;
						if (val == 0) {
							OPB_err(205);
						} else if (val == 1) {
							do_ = 0;
						} else if (OPB_log(val) == 1) {
							op = 17;
							((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 746, 41, 31848))->typ = OPT_sinttyp;
							((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 746, 64, 31871))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 746, 72, 31879))->intval = -OPB_exp;
							((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 746, 91, 31898))->obj = NIL;
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
				if (f == 4) {
					if (((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 753, 25, 32173))->class == 7) {
						if (((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 754, 27, 32225))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 754, 35, 32233))->intval == 0) {
							OPB_err(205);
						} else if (OPB_log(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 755, 34, 32293))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 755, 42, 32301))->intval) == 1) {
							op = 18;
							((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 756, 41, 32360))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 756, 49, 32368))->intval = __ASH(-1, OPB_exp);
							((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 756, 76, 32395))->obj = NIL;
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
					if (((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 763, 25, 32656))->class == 7) {
						if (OPB_IntToBool(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 764, 37, 32718))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 764, 45, 32726))->intval)) {
							z = y;
						}
					} else if ((((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 765, 29, 32780))->class == 7 && OPB_IntToBool(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 765, 64, 32815))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 765, 72, 32823))->intval))) {
					} else {
						NewOp__39(op, typ, &z, y);
					}
				} else if (f != 0) {
					OPB_err(94);
					((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 770, 54, 33160))->typ = OPT_undftyp;
				}
				break;
			case 6: 
				if (!__IN(f, 0xf1, 32)) {
					OPB_err(105);
					typ = OPT_undftyp;
				}
				do_ = 1;
				if (f == 4) {
					if ((((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 775, 26, 33395))->class == 7 && ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 775, 52, 33421))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 775, 60, 33429))->intval == 0)) {
						do_ = 0;
						z = y;
					}
					if ((((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 776, 26, 33499))->class == 7 && ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 776, 52, 33525))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 776, 60, 33533))->intval == 0)) {
						do_ = 0;
					}
				}
				if (do_) {
					NewOp__39(op, typ, &z, y);
				}
				break;
			case 7: 
				if (!__IN(f, 0xf1, 32)) {
					OPB_err(106);
					typ = OPT_undftyp;
				}
				if ((f != 4 || ((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 780, 41, 33785))->class != 7) || ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 780, 68, 33812))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 780, 76, 33820))->intval != 0) {
					NewOp__39(op, typ, &z, y);
				}
				break;
			case 8: 
				if (f == 2) {
					if (((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 782, 25, 33927))->class == 7) {
						if (!OPB_IntToBool(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 783, 38, 33990))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 783, 46, 33998))->intval)) {
							z = y;
						}
					} else if ((((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 784, 29, 34052))->class == 7 && !OPB_IntToBool(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 784, 65, 34088))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 784, 73, 34096))->intval))) {
					} else {
						NewOp__39(op, typ, &z, y);
					}
				} else if (f != 0) {
					OPB_err(95);
					((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 789, 54, 34433))->typ = OPT_undftyp;
				}
				break;
			case 9: case 10: 
				if (__IN(f, 0x1aff, 32) || strings__41(&z, &y)) {
					typ = OPT_booltyp;
				} else {
					OPB_err(107);
					typ = OPT_undftyp;
				}
				NewOp__39(op, typ, &z, y);
				break;
			case 11: case 12: case 13: case 14: 
				if (__IN(f, 0x79, 32) || strings__41(&z, &y)) {
					typ = OPT_booltyp;
				} else {
					OPM_LogWLn();
					OPM_LogWStr((CHAR*)"ELSE in Op()", 13);
					OPM_LogWLn();
					OPB_err(108);
					typ = OPT_undftyp;
				}
				NewOp__39(op, typ, &z, y);
				break;
			default: 
				OPM_LogWStr((CHAR*)"unhandled case in OPB.Op, op = ", 32);
				OPM_LogWNum(op, 0);
				OPM_LogWLn();
				break;
		}
	}
	*x = z;
	Op__38_s = _s.lnk;
}

void OPB_SetRange (OPT_Node *x, OPT_Node y)
{
	INT64 k, l;
	if (((((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 814, 10, 35324))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 814, 36, 35350))->class == 9) || ((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 814, 62, 35376))->class == 8) || ((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 814, 88, 35402))->class == 9) {
		OPB_err(126);
	} else if ((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 815, 13, 35449))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 815, 18, 35454))->form == 4 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 815, 40, 35476))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 815, 45, 35481))->form == 4)) {
		if (((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 816, 11, 35514))->class == 7) {
			k = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 817, 15, 35554))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 817, 23, 35562))->intval;
			if (0 > k || k > 63) {
				OPB_err(202);
			}
		}
		if (((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 820, 11, 35658))->class == 7) {
			l = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 821, 15, 35698))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 821, 23, 35706))->intval;
			if (0 > l || l > 63) {
				OPB_err(202);
			}
		}
		if ((((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 824, 12, 35803))->class == 7 && ((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 824, 38, 35829))->class == 7)) {
			if (k <= l) {
				((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 826, 12, 35890))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 826, 20, 35898))->setval = __SETRNG(k, l, 32);
				OPB_SetSetType(*x);
			} else {
				OPB_err(201);
				((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 827, 25, 35956))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 827, 33, 35964))->setval = __SETRNG(l, k, 32);
			}
			((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 829, 10, 36006))->obj = NIL;
		} else {
			OPB_BindNodes(10, OPT_settyp, &*x, y);
		}
	} else {
		OPB_err(93);
	}
	((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 834, 6, 36111))->typ = OPT_settyp;
}

void OPB_SetElem (OPT_Node *x)
{
	INT64 k;
	if (((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 840, 10, 36298))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 840, 36, 36324))->class == 9) {
		OPB_err(126);
	} else if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 841, 12, 36370))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 841, 17, 36375))->form != 4) {
		OPB_err(93);
	} else if (((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 842, 12, 36416))->class == 7) {
		k = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 843, 13, 36454))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 843, 21, 36462))->intval;
		if ((0 <= k && k <= 63)) {
			((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 845, 10, 36531))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 845, 18, 36539))->setval = 0x0;
			((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 845, 40, 36561))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 845, 47, 36568))->setval |= __SETOF(k,64);
		} else {
			OPB_err(202);
		}
		OPB_SetSetType(*x);
		((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 848, 23, 36634))->obj = NIL;
	} else {
		OPB_Convert(&*x, OPT_settyp);
		((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 850, 33, 36688))->typ = OPT_settyp;
	}
}

static void OPB_CheckAssign (OPT_Struct x, OPT_Node ynode)
{
	OPT_Struct y = NIL;
	INT16 f, g;
	OPT_Struct p = NIL, q = NIL;
	y = ((OPT_Node)__NIL_AT((ADDRESS)(ynode), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 861, 15, 37058))->typ;
	f = ((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 861, 28, 37071))->form;
	g = ((OPT_Struct)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 861, 42, 37085))->form;
	if (((OPT_Node)__NIL_AT((ADDRESS)(ynode), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 873, 14, 37557))->class == 8 || (((OPT_Node)__NIL_AT((ADDRESS)(ynode), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 873, 44, 37587))->class == 9 && f != 12)) {
		OPB_err(126);
	}
	switch (f) {
		case 0: case 8: 
			break;
		case 1: 
			if (!((__IN(g, 0x1a, 32) && ((OPT_Struct)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 877, 67, 37763))->size == 1))) {
				OPB_err(113);
			}
			break;
		case 2: case 3: 
			if (g != f) {
				OPB_err(113);
			}
			break;
		case 4: case 7: 
			if (g != f || ((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 881, 37, 37907))->size < ((OPT_Struct)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 881, 46, 37916))->size) {
				OPB_err(113);
			}
			break;
		case 5: 
			if (!__IN(g, 0x30, 32)) {
				OPB_err(113);
			}
			break;
		case 6: 
			if (!__IN(g, 0x70, 32)) {
				OPB_err(113);
			}
			break;
		case 11: 
			if ((x == y || g == 9) || (x == OPT_sysptrtyp && g == 11)) {
			} else if (g == 11) {
				p = ((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 886, 29, 38264))->BaseTyp;
				q = ((OPT_Struct)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 886, 46, 38281))->BaseTyp;
				if ((((OPT_Struct)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 887, 28, 38319))->comp == 4 && ((OPT_Struct)__NIL_AT((ADDRESS)(q), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 887, 53, 38344))->comp == 4)) {
					while ((((q != p && q != NIL)) && q != OPT_undftyp)) {
						q = ((OPT_Struct)__NIL_AT((ADDRESS)(q), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 888, 80, 38449))->BaseTyp;
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
		case 12: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(ynode), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 894, 29, 38666))->class == 9) {
				OPB_CheckProc(x, ((OPT_Node)__NIL_AT((ADDRESS)(ynode), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 894, 72, 38709))->obj);
			} else if (x == y || g == 9) {
			} else {
				OPB_err(113);
			}
			break;
		case 10: case 9: 
			OPB_err(113);
			break;
		case 13: 
			((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 900, 22, 38909))->pvused = 1;
			if (((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 901, 25, 39011))->comp == 2) {
				if ((((OPT_Node)__NIL_AT((ADDRESS)(ynode), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 902, 32, 39066))->class == 7 && g == 3)) {
					OPB_CharToString(ynode);
					y = ((OPT_Node)__NIL_AT((ADDRESS)(ynode), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 902, 107, 39141))->typ;
					g = 8;
				}
				if (x == y) {
				} else if ((((((OPT_Struct)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 904, 31, 39245))->comp == 2 && ((OPT_Struct)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 904, 54, 39268))->BaseTyp == ((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 904, 66, 39280))->BaseTyp)) && ((OPT_Struct)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 904, 80, 39294))->n <= ((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 904, 87, 39301))->n)) {
				} else if ((((OPT_Struct)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 905, 31, 39367))->comp == 3 && ((OPT_Struct)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 905, 55, 39391))->BaseTyp == ((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 905, 67, 39403))->BaseTyp)) {
				} else if (((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 906, 30, 39500))->BaseTyp == OPT_chartyp) {
					if (g == 8) {
						if (((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(ynode), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 908, 35, 39676))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 908, 43, 39684))->intval2 > ((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 908, 56, 39697))->n) {
							OPB_err(114);
						}
					} else {
						OPB_err(113);
					}
				} else {
					OPB_err(113);
				}
			} else if (((OPT_Struct)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 913, 28, 39874))->comp == 4) {
				if (x == y) {
				} else if (((OPT_Struct)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 915, 30, 39973))->comp == 4) {
					q = ((OPT_Struct)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 916, 31, 40028))->BaseTyp;
					while ((((q != NIL && q != x)) && q != OPT_undftyp)) {
						q = ((OPT_Struct)__NIL_AT((ADDRESS)(q), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 917, 80, 40118))->BaseTyp;
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
			OPM_LogWStr((CHAR*)"unhandled case in OPB.CheckAssign, f = ", 40);
			OPM_LogWNum(f, 0);
			OPM_LogWLn();
			break;
	}
	if ((((((((OPT_Node)__NIL_AT((ADDRESS)(ynode), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 925, 14, 40467))->class == 7 && g < f)) && __IN(g, 0x30, 32))) && __IN(f, 0x70, 32))) {
		OPB_Convert(&ynode, x);
	}
}

static void OPB_CheckLeaf (OPT_Node x, BOOLEAN dynArrToo)
{
}

void OPB_StPar0 (OPT_Node *par0, INT16 fctno)
{
	INT16 f;
	OPT_Struct typ = NIL;
	OPT_Node x = NIL;
	x = *par0;
	f = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 941, 26, 41191))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 941, 31, 41196))->form;
	switch (fctno) {
		case 0: 
			if ((f == 4 && ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 944, 41, 41290))->class == 7)) {
				if ((0 <= ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 945, 44, 41360))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 945, 52, 41368))->intval && ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 945, 66, 41382))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 945, 74, 41390))->intval <= 255)) {
					OPB_BindNodes(28, OPT_notyp, &x, x);
				} else {
					OPB_err(218);
				}
			} else {
				OPB_err(69);
			}
			((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 951, 21, 41620))->typ = OPT_notyp;
			break;
		case 1: 
			typ = OPT_notyp;
			if (OPB_NotVar(x)) {
				OPB_err(112);
			} else if (f == 11) {
				if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 957, 26, 41890))->readonly) {
					OPB_err(76);
				}
				f = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 958, 28, 41947))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 958, 33, 41952))->BaseTyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 958, 42, 41961))->comp;
				if (__IN(f, 0x1c, 32)) {
					if (f == 3) {
						typ = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 960, 55, 42093))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 960, 60, 42098))->BaseTyp;
					}
					OPB_BindNodes(19, OPT_notyp, &x, NIL);
					((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 961, 68, 42181))->subcl = 1;
				} else {
					OPB_err(111);
				}
			} else {
				OPB_err(111);
			}
			((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 966, 21, 42340))->typ = typ;
			break;
		case 2: 
			OPB_MOp(21, &x);
			break;
		case 3: 
			OPB_MOp(22, &x);
			break;
		case 4: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 972, 25, 42528))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 972, 51, 42554))->class == 9) {
				OPB_err(126);
			} else if (f == 3) {
				OPB_Convert(&x, OPT_inttyp);
			} else {
				OPB_err(111);
			}
			((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 976, 21, 42733))->typ = OPT_inttyp;
			break;
		case 5: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 978, 25, 42807))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 978, 51, 42833))->class == 9) {
				OPB_err(126);
			} else if (__IN(f, 0x60, 32)) {
				OPB_Convert(&x, OPT_linttyp);
			} else {
				OPB_err(111);
			}
			((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 982, 21, 43017))->typ = OPT_linttyp;
			break;
		case 6: 
			OPB_MOp(23, &x);
			break;
		case 7: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 986, 24, 43150))->class == 8) {
				switch (f) {
					case 2: 
						x = OPB_NewBoolConst(0);
						break;
					case 3: 
						x = OPB_NewIntConst(0);
						((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 989, 57, 43321))->typ = OPT_chartyp;
						break;
					case 4: 
						x = OPB_NewIntConst(OPM_SignedMinimum(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 990, 71, 43412))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 990, 75, 43416))->size));
						break;
					case 7: 
						x = OPB_NewIntConst(0);
						((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 991, 57, 43480))->typ = OPT_inttyp;
						break;
					case 5: 
						x = OPB_NewRealConst(OPM_MinReal, OPT_realtyp);
						break;
					case 6: 
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
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 999, 24, 43822))->class == 8) {
				switch (f) {
					case 2: 
						x = OPB_NewBoolConst(1);
						break;
					case 3: 
						x = OPB_NewIntConst(255);
						((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1002, 60, 43995))->typ = OPT_chartyp;
						break;
					case 4: 
						x = OPB_NewIntConst(OPM_SignedMaximum(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1003, 71, 44086))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1003, 75, 44090))->size));
						break;
					case 7: 
						x = OPB_NewIntConst(__ASHL(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1004, 53, 44150))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1004, 57, 44154))->size, 3) - 1);
						((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1004, 70, 44167))->typ = OPT_inttyp;
						break;
					case 5: 
						x = OPB_NewRealConst(OPM_MaxReal, OPT_realtyp);
						break;
					case 6: 
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
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1012, 25, 44510))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1012, 51, 44536))->class == 9) {
				OPB_err(126);
			} else if (__IN(f, 0x11, 32)) {
				OPB_Convert(&x, OPT_chartyp);
			} else {
				OPB_err(111);
				((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1014, 36, 44686))->typ = OPT_chartyp;
			}
			break;
		case 10: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1017, 25, 44783))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1017, 51, 44809))->class == 9) {
				OPB_err(126);
			} else if (f == 4) {
				typ = OPT_ShorterOrLongerType(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1019, 54, 44939))->typ, -1);
				if (typ == NIL) {
					OPB_err(111);
				} else {
					OPB_Convert(&x, typ);
				}
			} else if (f == 6) {
				OPB_Convert(&x, OPT_realtyp);
			} else {
				OPB_err(111);
			}
			break;
		case 11: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1025, 25, 45199))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1025, 51, 45225))->class == 9) {
				OPB_err(126);
			} else if (f == 4) {
				typ = OPT_ShorterOrLongerType(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1027, 54, 45355))->typ, 1);
				if (typ == NIL) {
					OPB_err(111);
				} else {
					OPB_Convert(&x, typ);
				}
			} else if (f == 5) {
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
			} else if (f != 4) {
				OPB_err(111);
			} else if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1037, 27, 45798))->readonly) {
				OPB_err(76);
			}
			break;
		case 15: case 16: 
			if (OPB_NotVar(x)) {
				OPB_err(112);
			} else if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1042, 27, 45968))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1042, 31, 45972))->form != 7) {
				OPB_err(111);
				((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1042, 63, 46004))->typ = OPT_settyp;
			} else if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1043, 27, 46050))->readonly) {
				OPB_err(76);
			}
			break;
		case 17: 
			if (!__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1046, 26, 46149))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1046, 31, 46154))->comp, 0x0c, 32)) {
				OPB_err(131);
			}
			break;
		case 18: 
			if ((((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1048, 25, 46259))->class == 7 && f == 3)) {
				OPB_CharToString(x);
				f = 8;
			}
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1049, 25, 46366))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1049, 51, 46392))->class == 9) {
				OPB_err(126);
			} else if (((!__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1050, 30, 46456))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1050, 35, 46461))->comp, 0x0c, 32) || ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1050, 75, 46501))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1050, 80, 46506))->BaseTyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1050, 89, 46515))->form != 3) && f != 8)) {
				OPB_err(111);
			}
			break;
		case 19: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1054, 25, 46664))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1054, 51, 46690))->class == 9) {
				OPB_err(126);
			} else if (f == 4) {
				if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1056, 26, 46792))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1056, 30, 46796))->size < ((OPT_Struct)__NIL_AT((ADDRESS)(OPT_linttyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1056, 49, 46815))->size) {
					OPB_Convert(&x, OPT_linttyp);
				}
			} else {
				OPB_err(111);
				((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1057, 36, 46889))->typ = OPT_linttyp;
			}
			break;
		case 20: 
			OPB_CheckLeaf(x, 0);
			OPB_MOp(24, &x);
			break;
		case 12: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1062, 24, 47074))->class != 8) {
				OPB_err(110);
				x = OPB_NewIntConst(1);
			} else if (__IN(f, 0x18fe, 32) || __IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1064, 28, 47234))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1064, 33, 47239))->comp, 0x14, 32)) {
				OPT_TypSize(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1065, 35, 47313))->typ);
				((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1065, 44, 47322))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1065, 49, 47327))->pvused = 1;
				x = OPB_NewIntConst(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1065, 85, 47363))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1065, 90, 47368))->size);
			} else {
				OPB_err(111);
				x = OPB_NewIntConst(1);
			}
			break;
		case 21: 
			OPB_MOp(25, &x);
			break;
		case 22: case 23: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1072, 25, 47606))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1072, 51, 47632))->class == 9) {
				OPB_err(126);
			} else if (!__IN(f, 0x9a, 32)) {
				OPB_err(111);
			}
			break;
		case 24: case 25: case 28: case 31: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1079, 25, 47919))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1079, 51, 47945))->class == 9) {
				OPB_err(126);
			} else if ((((((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1080, 28, 48007))->class == 7 && f == 4)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1080, 70, 48049))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1080, 74, 48053))->size < ((OPT_Struct)__NIL_AT((ADDRESS)(OPT_adrtyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1080, 92, 48071))->size)) {
				OPB_Convert(&x, OPT_adrtyp);
			} else if (!((__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1081, 30, 48135))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1081, 34, 48139))->form, 0x0810, 32) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1081, 71, 48176))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1081, 75, 48180))->size == OPM_AddressSize))) {
				OPB_err(111);
				((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1081, 117, 48222))->typ = OPT_adrtyp;
			}
			break;
		case 26: case 27: 
			if ((f == 4 && ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1085, 41, 48374))->class == 7)) {
				if (((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1086, 27, 48427))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1086, 35, 48435))->intval < 0 || ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1086, 65, 48465))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1086, 73, 48473))->intval > -1) {
					OPB_err(220);
				}
			} else {
				OPB_err(69);
			}
			break;
		case 29: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1090, 24, 48628))->class != 8) {
				OPB_err(110);
			} else if (__IN(f, 0x0501, 32) || ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1091, 73, 48734))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1091, 78, 48739))->comp == 3) {
				OPB_err(111);
			}
			break;
		case 30: 
			if (OPB_NotVar(x)) {
				OPB_err(112);
			} else if (f == 11) {
			} else {
				OPB_err(111);
			}
			break;
		case 32: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1100, 25, 49101))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1100, 51, 49127))->class == 9) {
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
			OPM_LogWStr((CHAR*)"unhandled case in OPB.StPar0, fctno = ", 39);
			OPM_LogWNum(fctno, 0);
			OPM_LogWLn();
			break;
	}
	*par0 = x;
}

static struct StPar1__53 {
	struct StPar1__53 *lnk;
} *StPar1__53_s;

static OPT_Node NewOp__54 (INT8 class, INT8 subcl, OPT_Node left, OPT_Node right);

static OPT_Node NewOp__54 (INT8 class, INT8 subcl, OPT_Node left, OPT_Node right)
{
	OPT_Node node = NIL;
	node = OPT_NewNode(class);
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1115, 39, 49791))->subcl = subcl;
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1116, 11, 49819))->left = left;
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1116, 31, 49839))->right = right;
	return node;
}

void OPB_StPar1 (OPT_Node *par0, OPT_Node x, INT8 fctno)
{
	INT16 f, L;
	OPT_Struct typ = NIL;
	OPT_Node p = NIL, t = NIL;
	struct StPar1__53 _s;
	_s.lnk = StPar1__53_s;
	StPar1__53_s = &_s;
	p = *par0;
	f = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1119, 26, 49910))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1119, 31, 49915))->form;
	switch (fctno) {
		case 13: case 14: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1123, 25, 50012))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1123, 51, 50038))->class == 9) {
				OPB_err(126);
				((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1123, 88, 50075))->typ = OPT_notyp;
			} else {
				if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1125, 26, 50143))->typ != ((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1125, 35, 50152))->typ) {
					if ((f == 4 && (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1127, 33, 50235))->class == 7 || (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1128, 33, 50289))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1128, 37, 50293))->form == 4 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1128, 58, 50314))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1128, 62, 50318))->size <= ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1128, 72, 50328))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1128, 76, 50332))->size)))) {
						OPB_Convert(&x, ((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1128, 101, 50357))->typ);
					} else {
						OPB_err(111);
					}
				}
				p = NewOp__54(19, fctno, p, x);
				((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1133, 23, 50536))->typ = OPT_notyp;
			}
			break;
		case 15: case 16: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1137, 25, 50653))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1137, 51, 50679))->class == 9) {
				OPB_err(126);
			} else if (f == 4) {
				if ((((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1139, 27, 50782))->class == 7 && (0 > ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1139, 58, 50813))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1139, 66, 50821))->intval || ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1139, 81, 50836))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1139, 89, 50844))->intval >= (INT64)__ASHL(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1139, 102, 50857))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1139, 106, 50861))->size, 3)))) {
					OPB_err(202);
				}
				p = NewOp__54(19, fctno, p, x);
			} else {
				OPB_err(111);
			}
			((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1144, 21, 51047))->typ = OPT_notyp;
			break;
		case 17: 
			if (!(f == 4) || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1146, 43, 51135))->class != 7) {
				OPB_err(69);
			} else if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1147, 27, 51196))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1147, 31, 51200))->size == 1) {
				L = OPM_Integer(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1148, 40, 51289))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1148, 48, 51297))->intval);
				typ = ((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1148, 67, 51316))->typ;
				while ((L > 0 && __IN(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1149, 42, 51364))->comp, 0x0c, 32))) {
					typ = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1149, 90, 51412))->BaseTyp;
					L -= 1;
				}
				if (L != 0 || !__IN(((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1150, 41, 51476))->comp, 0x0c, 32)) {
					OPB_err(132);
				} else {
					((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1151, 28, 51552))->obj = NIL;
					if (((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1152, 30, 51595))->comp == 3) {
						while (((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1153, 33, 51652))->class == 4) {
							p = ((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1153, 63, 51682))->left;
							((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1153, 76, 51695))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1153, 84, 51703))->intval += 1;
						}
						p = NewOp__54(12, 19, p, x);
						((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1154, 64, 51818))->typ = OPT_linttyp;
					} else {
						p = x;
						((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1155, 38, 51876))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1155, 46, 51884))->intval = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1155, 61, 51899))->n;
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
			} else if ((__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1162, 28, 52127))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1162, 33, 52132))->comp, 0x0c, 32) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1162, 72, 52171))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1162, 77, 52176))->BaseTyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1162, 86, 52185))->form == 3)) {
				if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1163, 26, 52234))->readonly) {
					OPB_err(76);
				}
				t = x;
				x = p;
				p = t;
				p = NewOp__54(19, 18, p, x);
			} else {
				OPB_err(111);
			}
			((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1167, 21, 52429))->typ = OPT_notyp;
			break;
		case 19: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1169, 25, 52499))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1169, 51, 52525))->class == 9) {
				OPB_err(126);
			} else if (f == 4) {
				if ((((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1171, 27, 52628))->class == 7 && ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1171, 53, 52654))->class == 7)) {
					if (-OPB_maxExp > ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1172, 39, 52719))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1172, 47, 52727))->intval || ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1172, 62, 52742))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1172, 70, 52750))->intval > OPB_maxExp) {
						OPB_err(208);
						((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1172, 105, 52785))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1172, 113, 52793))->intval = 1;
					} else if (((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1173, 31, 52837))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1173, 39, 52845))->intval >= 0) {
						if (__ABS(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1174, 34, 52897))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1174, 42, 52905))->intval) <= __DIV(9223372036854775807LL, (INT64)__ASH(1, ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1174, 85, 52948))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1174, 93, 52956))->intval))) {
							((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1175, 29, 52999))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1175, 37, 53007))->intval = ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1175, 50, 53020))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1175, 58, 53028))->intval * (INT64)__ASH(1, ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1175, 77, 53047))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1175, 85, 53055))->intval);
						} else {
							OPB_err(208);
							((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1176, 42, 53106))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1176, 50, 53114))->intval = 1;
						}
					} else {
						((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1178, 30, 53186))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1178, 38, 53194))->intval = __ASH(((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1178, 55, 53211))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1178, 63, 53219))->intval, ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1178, 74, 53230))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1178, 82, 53238))->intval);
					}
					((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1180, 25, 53301))->obj = NIL;
				} else {
					p = NewOp__54(12, 17, p, x);
					((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1181, 65, 53378))->typ = ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1181, 75, 53388))->left), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1181, 80, 53393))->typ;
				}
			} else {
				OPB_err(111);
			}
			break;
		case 1: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1186, 25, 53573))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1186, 51, 53599))->class == 9) {
				OPB_err(126);
			} else if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1187, 27, 53660))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1187, 32, 53665))->comp == 3) {
				if (f == 4) {
					if ((((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1189, 29, 53759))->class == 7 && (((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1189, 56, 53786))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1189, 64, 53794))->intval <= 0 || ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1189, 84, 53814))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1189, 92, 53822))->intval > OPM_MaxIndex))) {
						OPB_err(63);
					}
				} else {
					OPB_err(111);
				}
				((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1192, 23, 53949))->right = x;
				((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1192, 38, 53964))->typ = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1192, 48, 53974))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1192, 53, 53979))->BaseTyp;
			} else {
				OPB_err(64);
			}
			break;
		case 22: case 23: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1197, 25, 54130))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1197, 51, 54156))->class == 9) {
				OPB_err(126);
			} else if (f != 4) {
				OPB_err(111);
			} else {
				if (fctno == 22) {
					p = NewOp__54(12, 27, p, x);
				} else {
					p = NewOp__54(12, 28, p, x);
				}
				((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1201, 23, 54418))->typ = ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1201, 33, 54428))->left), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1201, 39, 54434))->typ;
			}
			break;
		case 24: case 25: case 26: case 27: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1207, 25, 54612))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1207, 51, 54638))->class == 9) {
				OPB_err(126);
			} else if (__IN(f, 0x18ff, 32)) {
				if (fctno == 24 || fctno == 26) {
					if (OPB_NotVar(x)) {
						OPB_err(112);
					} else if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1211, 31, 54908))->readonly) {
						OPB_err(76);
					}
					t = x;
					x = p;
					p = t;
				}
				p = NewOp__54(19, fctno, p, x);
			} else {
				OPB_err(111);
			}
			((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1218, 21, 55170))->typ = OPT_notyp;
			break;
		case 28: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1220, 25, 55247))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1220, 51, 55273))->class == 9) {
				OPB_err(126);
			} else if (f == 4) {
				p = NewOp__54(12, 26, p, x);
			} else {
				OPB_err(111);
			}
			((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1225, 21, 55485))->typ = OPT_booltyp;
			break;
		case 29: 
			if (((((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1229, 25, 55779))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1230, 25, 55824))->class == 9) || __IN(f, 0x0501, 32)) || ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1232, 25, 55933))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1232, 30, 55938))->comp == 3) {
				OPB_err(126);
			}
			OPT_TypSize(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1236, 33, 56151))->typ);
			OPT_TypSize(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1236, 53, 56171))->typ);
			if ((((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1237, 25, 56202))->class != 7 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1237, 50, 56227))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1237, 54, 56231))->size < ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1237, 63, 56240))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1237, 67, 56244))->size)) {
				OPB_err(-308);
			}
			if ((((((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1239, 25, 56296))->class == 7 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1239, 50, 56321))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1239, 54, 56325))->form == 4)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1239, 75, 56346))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1239, 79, 56350))->form == 4)) {
				OPB_Convert(&x, ((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1241, 34, 56500))->typ);
			} else {
				t = OPT_NewNode(11);
				((OPT_Node)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1243, 51, 56580))->subcl = 29;
				((OPT_Node)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1243, 72, 56601))->left = x;
				((OPT_Node)__NIL_AT((ADDRESS)(t), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1243, 86, 56615))->readonly = ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1243, 101, 56630))->readonly;
				x = t;
				((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1250, 23, 56993))->typ = ((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1250, 33, 57003))->typ;
			}
			p = x;
			break;
		case 30: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1254, 25, 57118))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1254, 51, 57144))->class == 9) {
				OPB_err(126);
			} else if (f == 4) {
				p = NewOp__54(19, 30, p, x);
			} else {
				OPB_err(111);
			}
			((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1259, 21, 57364))->typ = OPT_notyp;
			break;
		case 31: 
			if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1261, 25, 57442))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1261, 51, 57468))->class == 9) {
				OPB_err(126);
			} else if ((((((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1262, 28, 57530))->class == 7 && f == 4)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1262, 70, 57572))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1262, 74, 57576))->size < ((OPT_Struct)__NIL_AT((ADDRESS)(OPT_adrtyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1262, 92, 57594))->size)) {
				OPB_Convert(&x, OPT_adrtyp);
			} else if (!((__IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1263, 30, 57658))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1263, 34, 57662))->form, 0x0810, 32) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1263, 71, 57699))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1263, 75, 57703))->size == OPM_AddressSize))) {
				OPB_err(111);
				((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1263, 117, 57745))->typ = OPT_adrtyp;
			}
			((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1265, 21, 57809))->link = x;
			break;
		case 32: 
			if ((f == 4 && ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1267, 41, 57891))->class == 7)) {
				if ((0 <= ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1268, 44, 57961))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1268, 52, 57969))->intval && ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1268, 66, 57983))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1268, 74, 57991))->intval <= 255)) {
					OPB_BindNodes(28, OPT_notyp, &x, x);
					((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1270, 25, 58109))->conval = OPT_NewConst();
					((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1270, 54, 58138))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1270, 62, 58146))->intval = OPM_errpos;
					OPB_Construct(15, &p, x);
					((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1271, 51, 58220))->conval = OPT_NewConst();
					((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1271, 80, 58249))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1271, 88, 58257))->intval = OPM_errpos;
					OPB_Construct(20, &p, NIL);
					OPB_OptIf(&p);
					if (p == NIL) {
					} else if (((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1274, 31, 58435))->class == 28) {
						OPB_err(99);
					} else {
						((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1275, 30, 58497))->subcl = 32;
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
	StPar1__53_s = _s.lnk;
}

void OPB_StParN (OPT_Node *par0, OPT_Node x, INT16 fctno, INT16 n)
{
	OPT_Node node = NIL;
	INT16 f;
	OPT_Node p = NIL;
	p = *par0;
	f = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1288, 26, 58906))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1288, 31, 58911))->form;
	if (fctno == 1) {
		if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1290, 12, 58981))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1290, 38, 59007))->class == 9) {
			OPB_err(126);
		} else if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1291, 14, 59055))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1291, 19, 59060))->comp != 3) {
			OPB_err(64);
		} else if (f == 4) {
			if ((((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1293, 14, 59135))->class == 7 && (((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1293, 41, 59162))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1293, 49, 59170))->intval <= 0 || ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1293, 69, 59190))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1293, 77, 59198))->intval > OPM_MaxIndex))) {
				OPB_err(63);
			}
			node = ((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1294, 18, 59260))->right;
			while (((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1294, 37, 59279))->link != NIL) {
				node = ((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1294, 65, 59307))->link;
			}
			((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1295, 13, 59331))->link = x;
			((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1295, 27, 59345))->typ = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1295, 37, 59355))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1295, 42, 59360))->BaseTyp;
		} else {
			OPB_err(111);
		}
	} else if ((fctno == 31 && n == 2)) {
		if (((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1299, 12, 59473))->class == 8 || ((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1299, 38, 59499))->class == 9) {
			OPB_err(126);
		} else if (f == 4) {
			node = OPT_NewNode(19);
			((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1301, 47, 59609))->subcl = 31;
			((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1301, 74, 59636))->right = p;
			((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1302, 13, 59662))->left = ((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1302, 24, 59673))->link;
			((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1302, 33, 59682))->link = x;
			p = node;
		} else {
			OPB_err(111);
		}
		((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1305, 8, 59744))->typ = OPT_notyp;
	} else {
		OPB_err(64);
	}
	*par0 = p;
}

void OPB_StFct (OPT_Node *par0, INT8 fctno, INT16 parno)
{
	INT16 dim;
	OPT_Node x = NIL, p = NIL;
	p = *par0;
	if (fctno <= 19) {
		if ((fctno == 1 && ((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1315, 34, 60013))->typ != OPT_notyp)) {
			if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1316, 13, 60049))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1316, 18, 60054))->comp == 3) {
				OPB_err(65);
			}
			((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1317, 10, 60102))->typ = OPT_notyp;
		} else if (fctno <= 12) {
			if (parno < 1) {
				OPB_err(65);
			}
		} else {
			if (((fctno == 13 || fctno == 14) && parno == 1)) {
				OPB_BindNodes(19, OPT_notyp, &p, OPB_NewIntConst(1));
				((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1322, 66, 60398))->subcl = fctno;
				((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1322, 85, 60417))->right), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1322, 92, 60424))->typ = ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1322, 102, 60434))->left), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1322, 108, 60440))->typ;
			} else if ((fctno == 17 && parno == 1)) {
				if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1324, 15, 60521))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1324, 20, 60526))->comp == 3) {
					dim = 0;
					while (((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1325, 20, 60580))->class == 4) {
						p = ((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1325, 50, 60610))->left;
						dim += 1;
					}
					OPB_BindNodes(12, OPT_linttyp, &p, OPB_NewIntConst(dim));
					((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1326, 69, 60737))->subcl = 19;
				} else {
					p = OPB_NewIntConst(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1328, 31, 60801))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1328, 36, 60806))->n);
				}
			} else if (parno < 2) {
				OPB_err(65);
			}
		}
	} else if (fctno == 32) {
		if (parno == 1) {
			x = NIL;
			OPB_BindNodes(28, OPT_notyp, &x, OPB_NewIntConst(0));
			((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1336, 10, 61032))->conval = OPT_NewConst();
			((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1336, 39, 61061))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1336, 47, 61069))->intval = OPM_errpos;
			OPB_Construct(15, &p, x);
			((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1337, 36, 61128))->conval = OPT_NewConst();
			((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1337, 65, 61157))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1337, 73, 61165))->intval = OPM_errpos;
			OPB_Construct(20, &p, NIL);
			OPB_OptIf(&p);
			if (p == NIL) {
			} else if (((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1340, 16, 61298))->class == 28) {
				OPB_err(99);
			} else {
				((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1341, 15, 61345))->subcl = 32;
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
	INT16 f;
	f = ((OPT_Struct)__NIL_AT((ADDRESS)(atyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1357, 14, 61759))->comp;
	ftyp = ((OPT_Struct)__NIL_AT((ADDRESS)(ftyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1357, 34, 61779))->BaseTyp;
	atyp = ((OPT_Struct)__NIL_AT((ADDRESS)(atyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1357, 57, 61802))->BaseTyp;
	if ((fvarpar && ftyp == OPT_bytetyp)) {
		if (!__IN(f, 0x0c, 32) || !((__IN(((OPT_Struct)__NIL_AT((ADDRESS)(atyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1359, 52, 61925))->form, 0x1e, 32) && ((OPT_Struct)__NIL_AT((ADDRESS)(atyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1359, 99, 61972))->size == 1))) {
			if (__IN(18, OPM_Options, 32)) {
				OPB_err(-301);
			}
		}
	} else if (__IN(f, 0x0c, 32)) {
		if (((OPT_Struct)__NIL_AT((ADDRESS)(ftyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1363, 14, 62113))->comp == 3) {
			OPB_DynArrParCheck(ftyp, atyp, fvarpar);
		} else if (ftyp != atyp) {
			if ((((!fvarpar && ((OPT_Struct)__NIL_AT((ADDRESS)(ftyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1365, 28, 62230))->form == 11)) && ((OPT_Struct)__NIL_AT((ADDRESS)(atyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1365, 56, 62258))->form == 11)) {
				ftyp = ((OPT_Struct)__NIL_AT((ADDRESS)(ftyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1366, 23, 62306))->BaseTyp;
				atyp = ((OPT_Struct)__NIL_AT((ADDRESS)(atyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1366, 46, 62329))->BaseTyp;
				if ((((OPT_Struct)__NIL_AT((ADDRESS)(ftyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1367, 19, 62358))->comp == 4 && ((OPT_Struct)__NIL_AT((ADDRESS)(atyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1367, 47, 62386))->comp == 4)) {
					while ((((ftyp != atyp && atyp != NIL)) && atyp != OPT_undftyp)) {
						atyp = ((OPT_Struct)__NIL_AT((ADDRESS)(atyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1368, 86, 62497))->BaseTyp;
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
	if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1381, 10, 62764))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1381, 15, 62769))->form == 11) {
		if (((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1382, 11, 62805))->class == 3) {
			*x = ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1382, 43, 62837))->left;
		} else {
			OPB_err(71);
		}
	}
}

void OPB_PrepCall (OPT_Node *x, OPT_Object *fpar)
{
	if ((((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1388, 10, 63015))->obj != NIL && __IN(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1388, 27, 63032))->obj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1388, 32, 63037))->mode, 0x22c0, 32))) {
		*fpar = ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1389, 16, 63113))->obj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1389, 21, 63118))->link;
		if (((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1390, 11, 63136))->obj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1390, 16, 63141))->mode == 13) {
			OPB_CheckReceiver(&((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1390, 55, 63180))->left, *fpar);
			*fpar = ((OPT_Object)__NIL_AT((ADDRESS)(*fpar), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1390, 82, 63207))->link;
		}
	} else if ((((((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1391, 13, 63230))->class != 8 && ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1391, 38, 63255))->typ != NIL)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1391, 55, 63272))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1391, 60, 63277))->form == 12)) {
		*fpar = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1392, 16, 63319))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1392, 21, 63324))->link;
	} else {
		OPB_err(121);
		*fpar = NIL;
		((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1393, 34, 63364))->typ = OPT_undftyp;
	}
}

void OPB_Param (OPT_Node ap, OPT_Object fp)
{
	OPT_Struct q = NIL;
	if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1400, 10, 63500))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1400, 14, 63504))->form != 0) {
		if (((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1401, 12, 63538))->mode == 2) {
			if (OPB_NotVar(ap)) {
				OPB_err(122);
			} else {
				OPB_CheckLeaf(ap, 0);
			}
			if ((((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1405, 14, 63660))->readonly && ((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1405, 30, 63676))->vis != 3)) {
				OPB_err(76);
			}
			if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1406, 14, 63733))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1406, 19, 63738))->comp == 3) {
				OPB_DynArrParCheck(((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1406, 61, 63780))->typ, ((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1406, 70, 63789))->typ, 1);
			} else if ((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1407, 18, 63819))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1407, 23, 63824))->comp == 4 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1407, 49, 63850))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1407, 54, 63855))->comp == 4)) {
				q = ((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1408, 18, 63898))->typ;
				while ((((q != ((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1409, 24, 63928))->typ && q != NIL)) && q != OPT_undftyp)) {
					q = ((OPT_Struct)__NIL_AT((ADDRESS)(q), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1409, 72, 63976))->BaseTyp;
				}
				if (q == NIL) {
					OPB_err(111);
				}
			} else if ((((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1411, 18, 64048))->typ == OPT_sysptrtyp && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1411, 46, 64076))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1411, 51, 64081))->form == 11)) {
			} else if ((((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1412, 18, 64134))->typ != ((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1412, 28, 64144))->typ && !((((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1413, 22, 64172))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1413, 27, 64177))->form == 1 && __IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1414, 22, 64217))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1414, 26, 64221))->form, 0x1e, 32))) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1415, 22, 64282))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1415, 26, 64286))->size == 1)))) {
				OPB_err(123);
			} else if ((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1416, 18, 64329))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1416, 23, 64334))->form == 11 && ((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1416, 50, 64361))->class == 5)) {
				OPB_err(123);
			}
		} else if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1418, 15, 64423))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1418, 20, 64428))->comp == 3) {
			if ((((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1419, 15, 64467))->class == 7 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1419, 42, 64494))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1419, 47, 64499))->form == 3)) {
				OPB_CharToString(ap);
			}
			if ((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1420, 15, 64560))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1420, 20, 64565))->form == 8 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1420, 46, 64591))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1420, 51, 64596))->BaseTyp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1420, 60, 64605))->form == 3)) {
			} else if (((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1421, 17, 64654))->class >= 7) {
				OPB_err(59);
			} else {
				OPB_DynArrParCheck(((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1422, 31, 64719))->typ, ((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1422, 40, 64728))->typ, 0);
			}
		} else if ((((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1424, 16, 64769))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1424, 21, 64774))->comp == 2 && __IN(((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1424, 46, 64799))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1424, 51, 64804))->comp, 0x0c, 32))) && ((OPT_Node)__NIL_AT((ADDRESS)(ap), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1424, 91, 64844))->typ != ((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1424, 101, 64854))->typ)) {
			OPB_err(113);
		} else {
			OPB_CheckAssign(((OPT_Object)__NIL_AT((ADDRESS)(fp), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1428, 26, 65060))->typ, ap);
		}
	}
}

void OPB_StaticLink (INT8 dlev)
{
	OPT_Object scope = NIL;
	scope = OPT_topScope;
	while (dlev > 0) {
		dlev -= 1;
		while ((((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1438, 19, 65257))->left != NIL && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1438, 41, 65279))->left), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1438, 47, 65285))->mnolev == ((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1438, 63, 65301))->mnolev)) {
			scope = ((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1438, 90, 65328))->left;
		}
		((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1439, 17, 65356))->link), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1439, 23, 65362))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1439, 31, 65370))->setval |= __SETOF(3,64);
		scope = ((OPT_Object)__NIL_AT((ADDRESS)(scope), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1440, 21, 65415))->left;
	}
}

void OPB_Call (OPT_Node *x, OPT_Node apar, OPT_Object fp)
{
	OPT_Struct typ = NIL;
	OPT_Node p = NIL;
	INT8 lev;
	if (((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1447, 9, 65586))->class == 9) {
		typ = ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1447, 42, 65619))->typ;
		lev = ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1448, 15, 65640))->obj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1448, 20, 65645))->mnolev;
		if (lev > 0) {
			OPB_StaticLink(((OPT_Object)__NIL_AT((ADDRESS)(OPT_topScope), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1449, 46, 65700))->mnolev - lev);
		}
		if (((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1450, 11, 65730))->obj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1450, 16, 65735))->mode == 10) {
			OPB_err(121);
		}
	} else if ((((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1451, 13, 65784))->class == 2 && ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1451, 39, 65810))->obj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1451, 44, 65815))->mode == 13)) {
		typ = ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1451, 77, 65848))->typ;
		((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1452, 8, 65862))->class = 9;
		p = ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1452, 36, 65890))->left;
		((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1452, 45, 65899))->left = NIL;
		((OPT_Node)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1452, 61, 65915))->link = apar;
		apar = p;
		fp = ((OPT_Object)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1452, 95, 65949))->obj), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1452, 100, 65954))->link;
	} else {
		typ = ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1453, 18, 65978))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1453, 23, 65983))->BaseTyp;
	}
	OPB_BindNodes(13, typ, &*x, apar);
	((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1455, 42, 66044))->obj = fp;
}

void OPB_Enter (OPT_Node *procdec, OPT_Node stat, OPT_Object proc)
{
	OPT_Node x = NIL;
	x = OPT_NewNode(18);
	((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1461, 36, 66210))->typ = OPT_notyp;
	((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1461, 57, 66231))->obj = proc;
	((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1462, 6, 66251))->left = *procdec;
	((OPT_Node)__NIL_AT((ADDRESS)(x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1462, 26, 66271))->right = stat;
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
			OPB_CheckAssign(((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1471, 39, 66533))->typ, *x);
		} else if (((OPT_Object)__NIL_AT((ADDRESS)(proc), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1472, 17, 66559))->typ != OPT_notyp) {
			OPB_err(124);
		}
	}
	node = OPT_NewNode(26);
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1475, 43, 66653))->typ = OPT_notyp;
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1475, 67, 66677))->obj = proc;
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1475, 86, 66696))->left = *x;
	*x = node;
}

void OPB_Assign (OPT_Node *x, OPT_Node y)
{
	OPT_Node z = NIL;
	if (((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1481, 9, 66822))->class >= 7) {
		OPB_err(56);
	}
	OPB_CheckAssign(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1482, 18, 66880))->typ, y);
	if (((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1483, 9, 66899))->readonly) {
		OPB_err(76);
	}
	if (((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1484, 9, 66937))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1484, 14, 66942))->comp == 4) {
		if (((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1485, 11, 66977))->class == 5) {
			z = ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1485, 43, 67009))->left;
		} else {
			z = *x;
		}
		if ((((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1486, 12, 67045))->class == 3 && ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1486, 38, 67071))->left), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1486, 44, 67077))->class == 5)) {
			((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1487, 10, 67113))->left = ((OPT_Node)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1487, 21, 67124))->left), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1487, 27, 67130))->left;
		}
		if ((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1489, 12, 67199))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1489, 17, 67204))->strobj != NIL && (((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1489, 38, 67225))->class == 3 || ((OPT_Node)__NIL_AT((ADDRESS)(z), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1489, 65, 67252))->class == 1))) {
			OPB_BindNodes(6, ((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1490, 33, 67313))->typ, &z, NIL);
			*x = z;
		}
	} else if ((((((((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1492, 13, 67358))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1492, 18, 67363))->comp == 2 && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1492, 42, 67387))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1492, 47, 67392))->BaseTyp == OPT_chartyp)) && ((OPT_Struct)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1493, 11, 67429))->typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1493, 16, 67434))->form == 8)) && ((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1493, 41, 67459))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1493, 49, 67467))->intval2 == 1)) {
		((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1494, 8, 67541))->typ = OPT_chartyp;
		((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(y), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1494, 31, 67564))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1494, 39, 67572))->intval = 0;
		OPB_Index(&*x, OPB_NewIntConst(0));
	}
	OPB_BindNodes(19, OPT_notyp, &*x, y);
	((OPT_Node)__NIL_AT((ADDRESS)(*x), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1498, 6, 67677))->subcl = 0;
}

void OPB_Inittd (OPT_Node *inittd, OPT_Node *last, OPT_Struct typ)
{
	OPT_Node node = NIL;
	node = OPT_NewNode(14);
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1504, 43, 67855))->typ = typ;
	((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1505, 9, 67877))->conval = OPT_NewConst();
	((OPT_Const)__NIL_AT((ADDRESS)(((OPT_Node)__NIL_AT((ADDRESS)(node), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1505, 41, 67909))->conval), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1505, 49, 67917))->intval = ((OPT_Struct)__NIL_AT((ADDRESS)(typ), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1505, 64, 67932))->txtpos;
	if (*inittd == NIL) {
		*inittd = node;
	} else {
		((OPT_Node)__NIL_AT((ADDRESS)(*last), (CHAR*)"../../src/compiler/OPB.Mod", 27, (CHAR*)"OPB", 4, 1506, 50, 67991))->link = node;
	}
	*last = node;
}


export void *OPB__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(OPM);
	__MODULE_IMPORT(OPS);
	__MODULE_IMPORT(OPT);
	__MODULE_IMPORT(Platform);
	__REGMOD("OPB", 0);
/* BEGIN */
	OPB_maxExp = OPB_log(4611686018427387904LL);
	OPB_maxExp = OPB_exp;
	__ENDMOD;
}
