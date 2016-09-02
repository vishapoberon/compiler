/* voc 1.95 [2016/09/02] for gcc LP64 on cygwin xtspkaSfF */

#ifndef Texts__h
#define Texts__h

#include "SYSTEM.h"
#include "Files.h"

typedef
	struct Texts_BufDesc {
		int32 len;
		char _prvt0[4];
	} Texts_BufDesc;

typedef
	Texts_BufDesc *Texts_Buffer;

typedef
	struct Texts_ElemMsg {
		char _prvt0[1];
	} Texts_ElemMsg;

typedef
	struct Texts_ElemDesc *Texts_Elem;

typedef
	struct Texts_CopyMsg { /* Texts_ElemMsg */
		Texts_Elem e;
	} Texts_CopyMsg;

typedef
	struct Texts_RunDesc {
		LONGINT _prvt0;
		char _prvt1[15];
	} Texts_RunDesc;

typedef
	void (*Texts_Handler)(Texts_Elem, Texts_ElemMsg*, LONGINT *);

typedef
	struct Texts_ElemDesc {
		char _prvt0[20];
		int32 W, H;
		Texts_Handler handle;
		char _prvt1[4];
	} Texts_ElemDesc;

typedef
	struct Texts_FileMsg { /* Texts_ElemMsg */
		int16 id;
		int32 pos;
		Files_Rider r;
	} Texts_FileMsg;

typedef
	struct Texts_FontDesc {
		char _prvt0[32];
	} Texts_FontDesc;

typedef
	Texts_FontDesc *Texts_FontsFont;

typedef
	struct Texts_IdentifyMsg { /* Texts_ElemMsg */
		CHAR mod[32], proc[32];
	} Texts_IdentifyMsg;

typedef
	struct Texts_TextDesc *Texts_Text;

typedef
	void (*Texts_Notifier)(Texts_Text, int16, int32, int32);

typedef
	struct Texts_Reader {
		BOOLEAN eot;
		Texts_FontsFont fnt;
		int8 col, voff;
		Texts_Elem elem;
		char _prvt0[32];
	} Texts_Reader;

typedef
	struct Texts_Scanner { /* Texts_Reader */
		BOOLEAN eot;
		Texts_FontsFont fnt;
		int8 col, voff;
		Texts_Elem elem;
		char _prvt0[32];
		CHAR nextCh;
		int16 line, class;
		int32 i;
		REAL x;
		LONGREAL y;
		CHAR c;
		int8 len;
		CHAR s[64];
	} Texts_Scanner;

typedef
	struct Texts_TextDesc {
		int32 len;
		Texts_Notifier notify;
		char _prvt0[12];
	} Texts_TextDesc;

typedef
	struct Texts_Writer {
		Texts_Buffer buf;
		Texts_FontsFont fnt;
		int8 col, voff;
		char _prvt0[26];
	} Texts_Writer;


import Texts_Elem Texts_new;

import LONGINT *Texts_FontDesc__typ;
import LONGINT *Texts_RunDesc__typ;
import LONGINT *Texts_ElemMsg__typ;
import LONGINT *Texts_ElemDesc__typ;
import LONGINT *Texts_FileMsg__typ;
import LONGINT *Texts_CopyMsg__typ;
import LONGINT *Texts_IdentifyMsg__typ;
import LONGINT *Texts_BufDesc__typ;
import LONGINT *Texts_TextDesc__typ;
import LONGINT *Texts_Reader__typ;
import LONGINT *Texts_Scanner__typ;
import LONGINT *Texts_Writer__typ;

import void Texts_Append (Texts_Text T, Texts_Buffer B);
import void Texts_ChangeLooks (Texts_Text T, int32 beg, int32 end, SET sel, Texts_FontsFont fnt, int8 col, int8 voff);
import void Texts_Close (Texts_Text T, CHAR *name, LONGINT name__len);
import void Texts_Copy (Texts_Buffer SB, Texts_Buffer DB);
import void Texts_CopyElem (Texts_Elem SE, Texts_Elem DE);
import void Texts_Delete (Texts_Text T, int32 beg, int32 end);
import Texts_Text Texts_ElemBase (Texts_Elem E);
import int32 Texts_ElemPos (Texts_Elem E);
import void Texts_Insert (Texts_Text T, int32 pos, Texts_Buffer B);
import void Texts_Load (Files_Rider *r, LONGINT *r__typ, Texts_Text T);
import void Texts_Open (Texts_Text T, CHAR *name, LONGINT name__len);
import void Texts_OpenBuf (Texts_Buffer B);
import void Texts_OpenReader (Texts_Reader *R, LONGINT *R__typ, Texts_Text T, int32 pos);
import void Texts_OpenScanner (Texts_Scanner *S, LONGINT *S__typ, Texts_Text T, int32 pos);
import void Texts_OpenWriter (Texts_Writer *W, LONGINT *W__typ);
import int32 Texts_Pos (Texts_Reader *R, LONGINT *R__typ);
import void Texts_Read (Texts_Reader *R, LONGINT *R__typ, CHAR *ch);
import void Texts_ReadElem (Texts_Reader *R, LONGINT *R__typ);
import void Texts_ReadPrevElem (Texts_Reader *R, LONGINT *R__typ);
import void Texts_Recall (Texts_Buffer *B);
import void Texts_Save (Texts_Text T, int32 beg, int32 end, Texts_Buffer B);
import void Texts_Scan (Texts_Scanner *S, LONGINT *S__typ);
import void Texts_SetColor (Texts_Writer *W, LONGINT *W__typ, int8 col);
import void Texts_SetFont (Texts_Writer *W, LONGINT *W__typ, Texts_FontsFont fnt);
import void Texts_SetOffset (Texts_Writer *W, LONGINT *W__typ, int8 voff);
import void Texts_Store (Files_Rider *r, LONGINT *r__typ, Texts_Text T);
import void Texts_Write (Texts_Writer *W, LONGINT *W__typ, CHAR ch);
import void Texts_WriteDate (Texts_Writer *W, LONGINT *W__typ, int32 t, int32 d);
import void Texts_WriteElem (Texts_Writer *W, LONGINT *W__typ, Texts_Elem e);
import void Texts_WriteHex (Texts_Writer *W, LONGINT *W__typ, int32 x);
import void Texts_WriteInt (Texts_Writer *W, LONGINT *W__typ, int32 x, int32 n);
import void Texts_WriteLn (Texts_Writer *W, LONGINT *W__typ);
import void Texts_WriteLongReal (Texts_Writer *W, LONGINT *W__typ, LONGREAL x, int16 n);
import void Texts_WriteLongRealHex (Texts_Writer *W, LONGINT *W__typ, LONGREAL x);
import void Texts_WriteReal (Texts_Writer *W, LONGINT *W__typ, REAL x, int16 n);
import void Texts_WriteRealFix (Texts_Writer *W, LONGINT *W__typ, REAL x, int16 n, int16 k);
import void Texts_WriteRealHex (Texts_Writer *W, LONGINT *W__typ, REAL x);
import void Texts_WriteString (Texts_Writer *W, LONGINT *W__typ, CHAR *s, LONGINT s__len);
import void *Texts__init(void);


#endif
