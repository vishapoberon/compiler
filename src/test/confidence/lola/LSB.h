/* voc  1.2 [2016/06/16] for gcc LP64 on cygwin xtpka */

#ifndef LSB__h
#define LSB__h

#define LARGE
#include "SYSTEM.h"

typedef
	struct LSB_ArrayTypeDesc *LSB_ArrayType;

typedef
	struct LSB_ObjDesc *LSB_Object;

typedef
	struct LSB_TypeDesc {
		LONGINT len, size;
		LSB_Object typobj;
	} LSB_TypeDesc;

typedef
	LSB_TypeDesc *LSB_Type;

typedef
	struct LSB_ArrayTypeDesc { /* LSB_TypeDesc */
		LONGINT len, size;
		LSB_Object typobj;
		LSB_Type eltyp;
	} LSB_ArrayTypeDesc;

typedef
	struct LSB_ItemDesc *LSB_Item;

typedef
	struct LSB_ItemDesc {
		INTEGER tag;
		LSB_Type type;
		LONGINT val, size;
		LSB_Item a, b;
	} LSB_ItemDesc;

typedef
	struct LSB_ObjDesc { /* LSB_ItemDesc */
		INTEGER tag;
		LSB_Type type;
		LONGINT val, size;
		LSB_Item a, b;
		LSB_Object next;
		CHAR name[32];
		BOOLEAN marked;
	} LSB_ObjDesc;

typedef
	struct LSB_UnitTypeDesc *LSB_UnitType;

typedef
	struct LSB_UnitTypeDesc { /* LSB_TypeDesc */
		LONGINT len, size;
		LSB_Object typobj;
		LSB_Object firstobj;
	} LSB_UnitTypeDesc;


import LSB_Object LSB_root, LSB_top;
import LSB_Type LSB_bitType, LSB_integer, LSB_string;
import LSB_ArrayType LSB_byteType, LSB_wordType;
import CHAR LSB_modname[32];

import LONGINT *LSB_ItemDesc__typ;
import LONGINT *LSB_ObjDesc__typ;
import LONGINT *LSB_TypeDesc__typ;
import LONGINT *LSB_ArrayTypeDesc__typ;
import LONGINT *LSB_UnitTypeDesc__typ;

import void LSB_Register (CHAR *name, LONGINT name__len, LSB_Object list);
import void *LSB__init(void);


#endif
