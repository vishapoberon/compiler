/* voc 5.4.1 [2026/11/24] for gcc LP64 on gentoo xnrtspaSF */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32

#include "SYSTEM.h"
#include "Files.h"
#include "Modules.h"
#include "Platform.h"
#include "Reals.h"

typedef
	struct Texts_RunDesc *Texts_Run;

typedef
	struct Texts_FontDesc *Texts_FontsFont;

typedef
	struct Texts_RunDesc {
		Texts_Run prev, next;
		INT32 len;
		Texts_FontsFont fnt;
		INT8 col, voff;
		BOOLEAN ascii;
	} Texts_RunDesc;

typedef
	struct Texts_ElemDesc *Texts_Elem;

typedef
	struct Texts_ElemMsg {
		char _prvt0[1];
	} Texts_ElemMsg;

typedef
	void (*Texts_Handler)(Texts_Elem, Texts_ElemMsg*, ADDRESS *);

typedef
	struct Texts_TextDesc *Texts_Text;

typedef
	struct Texts_ElemDesc {
		Texts_Run prev, next;
		INT32 len;
		Texts_FontsFont fnt;
		INT8 col, voff;
		BOOLEAN ascii;
		INT32 W, H;
		Texts_Handler handle;
		Texts_Text base;
	} Texts_ElemDesc;

struct Texts__1 { /* Texts_ElemDesc */
	Texts_Run prev, next;
	INT32 len;
	Texts_FontsFont fnt;
	INT8 col, voff;
	BOOLEAN ascii;
	INT32 W, H;
	Texts_Handler handle;
	Texts_Text base;
	Files_File file;
	INT32 org, span;
	CHAR mod[32], proc[32];
};

typedef
	struct Texts__1 *Texts_Alien;

typedef
	struct Texts_BufDesc {
		INT32 len;
		Texts_Run head;
	} Texts_BufDesc;

typedef
	Texts_BufDesc *Texts_Buffer;

typedef
	struct Texts_CopyMsg { /* Texts_ElemMsg */
		Texts_Elem e;
	} Texts_CopyMsg;

typedef
	struct Texts_FileMsg { /* Texts_ElemMsg */
		INT16 id;
		INT32 pos;
		Files_Rider r;
	} Texts_FileMsg;

typedef
	struct Texts_FontDesc {
		CHAR name[32];
	} Texts_FontDesc;

typedef
	struct Texts_IdentifyMsg { /* Texts_ElemMsg */
		CHAR mod[32], proc[32];
	} Texts_IdentifyMsg;

typedef
	void (*Texts_Notifier)(Texts_Text, INT16, INT32, INT32);

typedef
	struct Texts_PieceDesc *Texts_Piece;

typedef
	struct Texts_PieceDesc {
		Texts_Run prev, next;
		INT32 len;
		Texts_FontsFont fnt;
		INT8 col, voff;
		BOOLEAN ascii;
		Files_File file;
		INT32 org;
	} Texts_PieceDesc;

typedef
	struct Texts_Reader {
		BOOLEAN eot;
		Texts_FontsFont fnt;
		INT8 col, voff;
		Texts_Elem elem;
		Files_Rider rider;
		Texts_Run run;
		INT32 org, off;
	} Texts_Reader;

typedef
	struct Texts_Scanner { /* Texts_Reader */
		BOOLEAN eot;
		Texts_FontsFont fnt;
		INT8 col, voff;
		Texts_Elem elem;
		Files_Rider rider;
		Texts_Run run;
		INT32 org, off;
		CHAR nextCh;
		INT16 line, class;
		INT32 i;
		REAL x;
		LONGREAL y;
		CHAR c;
		INT8 len;
		CHAR s[64];
	} Texts_Scanner;

typedef
	struct Texts_TextDesc {
		INT32 len;
		Texts_Notifier notify;
		Texts_Run head, cache;
		INT32 corg;
	} Texts_TextDesc;

typedef
	struct Texts_Writer {
		Texts_Buffer buf;
		Texts_FontsFont fnt;
		INT8 col, voff;
		Files_Rider rider;
		Files_File file;
	} Texts_Writer;


export Texts_Elem Texts_new;
static Texts_Buffer Texts_del;
static Texts_FontsFont Texts_FontsDefault;

export ADDRESS *Texts_FontDesc__typ;
export ADDRESS *Texts_RunDesc__typ;
export ADDRESS *Texts_PieceDesc__typ;
export ADDRESS *Texts_ElemMsg__typ;
export ADDRESS *Texts_ElemDesc__typ;
export ADDRESS *Texts_FileMsg__typ;
export ADDRESS *Texts_CopyMsg__typ;
export ADDRESS *Texts_IdentifyMsg__typ;
export ADDRESS *Texts_BufDesc__typ;
export ADDRESS *Texts_TextDesc__typ;
export ADDRESS *Texts_Reader__typ;
export ADDRESS *Texts_Scanner__typ;
export ADDRESS *Texts_Writer__typ;
export ADDRESS *Texts__1__typ;

export void Texts_Append (Texts_Text T, Texts_Buffer B);
export void Texts_ChangeLooks (Texts_Text T, INT32 beg, INT32 end, UINT32 sel, Texts_FontsFont fnt, INT8 col, INT8 voff);
static Texts_Elem Texts_CloneElem (Texts_Elem e);
static Texts_Piece Texts_ClonePiece (Texts_Piece p);
export void Texts_Close (Texts_Text T, CHAR *name, ADDRESS name__len);
export void Texts_Copy (Texts_Buffer SB, Texts_Buffer DB);
export void Texts_CopyElem (Texts_Elem SE, Texts_Elem DE);
export void Texts_Delete (Texts_Text T, INT32 beg, INT32 end);
export Texts_Text Texts_ElemBase (Texts_Elem E);
export INT32 Texts_ElemPos (Texts_Elem E);
static void Texts_Find (Texts_Text T, INT32 *pos, Texts_Run *u, INT32 *org, INT32 *off);
static Texts_FontsFont Texts_FontsThis (CHAR *name, ADDRESS name__len);
static void Texts_HandleAlien (Texts_Elem E, Texts_ElemMsg *msg, ADDRESS *msg__typ);
export void Texts_Insert (Texts_Text T, INT32 pos, Texts_Buffer B);
export void Texts_Load (Files_Rider *r, ADDRESS *r__typ, Texts_Text T);
static void Texts_Load0 (Files_Rider *r, ADDRESS *r__typ, Texts_Text T);
static void Texts_Merge (Texts_Text T, Texts_Run u, Texts_Run *v);
export void Texts_Open (Texts_Text T, CHAR *name, ADDRESS name__len);
export void Texts_OpenBuf (Texts_Buffer B);
export void Texts_OpenReader (Texts_Reader *R, ADDRESS *R__typ, Texts_Text T, INT32 pos);
export void Texts_OpenScanner (Texts_Scanner *S, ADDRESS *S__typ, Texts_Text T, INT32 pos);
export void Texts_OpenWriter (Texts_Writer *W, ADDRESS *W__typ);
export INT32 Texts_Pos (Texts_Reader *R, ADDRESS *R__typ);
export void Texts_Read (Texts_Reader *R, ADDRESS *R__typ, CHAR *ch);
export void Texts_ReadElem (Texts_Reader *R, ADDRESS *R__typ);
export void Texts_ReadPrevElem (Texts_Reader *R, ADDRESS *R__typ);
export void Texts_Recall (Texts_Buffer *B);
export void Texts_Save (Texts_Text T, INT32 beg, INT32 end, Texts_Buffer B);
export void Texts_Scan (Texts_Scanner *S, ADDRESS *S__typ);
export void Texts_SetColor (Texts_Writer *W, ADDRESS *W__typ, INT8 col);
export void Texts_SetFont (Texts_Writer *W, ADDRESS *W__typ, Texts_FontsFont fnt);
export void Texts_SetOffset (Texts_Writer *W, ADDRESS *W__typ, INT8 voff);
static void Texts_Splice (Texts_Run un, Texts_Run v, Texts_Run w, Texts_Text base);
static void Texts_Split (INT32 off, Texts_Run *u, Texts_Run *un);
export void Texts_Store (Files_Rider *r, ADDRESS *r__typ, Texts_Text T);
export void Texts_Write (Texts_Writer *W, ADDRESS *W__typ, CHAR ch);
export void Texts_WriteDate (Texts_Writer *W, ADDRESS *W__typ, INT32 t, INT32 d);
export void Texts_WriteElem (Texts_Writer *W, ADDRESS *W__typ, Texts_Elem e);
export void Texts_WriteHex (Texts_Writer *W, ADDRESS *W__typ, INT32 x);
export void Texts_WriteInt (Texts_Writer *W, ADDRESS *W__typ, INT64 x, INT64 n);
export void Texts_WriteLn (Texts_Writer *W, ADDRESS *W__typ);
export void Texts_WriteLongReal (Texts_Writer *W, ADDRESS *W__typ, LONGREAL x, INT16 n);
export void Texts_WriteLongRealHex (Texts_Writer *W, ADDRESS *W__typ, LONGREAL x);
export void Texts_WriteReal (Texts_Writer *W, ADDRESS *W__typ, REAL x, INT16 n);
export void Texts_WriteRealFix (Texts_Writer *W, ADDRESS *W__typ, REAL x, INT16 n, INT16 k);
export void Texts_WriteRealHex (Texts_Writer *W, ADDRESS *W__typ, REAL x);
export void Texts_WriteString (Texts_Writer *W, ADDRESS *W__typ, CHAR *s, ADDRESS s__len);


static Texts_FontsFont Texts_FontsThis (CHAR *name, ADDRESS name__len)
{
	Texts_FontsFont F = NIL;
	__NEW(F, Texts_FontDesc);
	__COPY(name, ((Texts_FontsFont)__NIL_AT((ADDRESS)(F), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 126, 25, 2747))->name, 32);
	return F;
}

static void Texts_Find (Texts_Text T, INT32 *pos, Texts_Run *u, INT32 *org, INT32 *off)
{
	Texts_Run v = NIL;
	INT32 m;
	if (*pos >= ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 134, 16, 2938))->len) {
		*pos = ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 134, 34, 2956))->len;
		*u = ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 134, 46, 2968))->head;
		*org = ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 134, 61, 2983))->len;
		*off = 0;
		((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 134, 78, 3000))->cache = ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 134, 89, 3011))->head;
		((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 134, 97, 3019))->corg = 0;
	} else {
		v = ((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 135, 16, 3045))->cache), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 135, 22, 3051))->next;
		m = *pos - ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 135, 41, 3070))->corg;
		if (*pos >= ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 136, 18, 3094))->corg) {
			while (m >= ((Texts_Run)__NIL_AT((ADDRESS)(v), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 137, 21, 3125))->len) {
				m -= ((Texts_Run)__NIL_AT((ADDRESS)(v), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 137, 37, 3141))->len;
				v = ((Texts_Run)__NIL_AT((ADDRESS)(v), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 137, 50, 3154))->next;
			}
		} else {
			while (m < 0) {
				v = ((Texts_Run)__NIL_AT((ADDRESS)(v), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 139, 30, 3204))->prev;
				m += ((Texts_Run)__NIL_AT((ADDRESS)(v), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 139, 45, 3219))->len;
			}
		}
		*u = v;
		*org = *pos - m;
		*off = m;
		((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 141, 42, 3282))->cache = ((Texts_Run)__NIL_AT((ADDRESS)(v), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 141, 53, 3293))->prev;
		((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 141, 61, 3301))->corg = *org;
	}
}

static void Texts_Split (INT32 off, Texts_Run *u, Texts_Run *un)
{
	Texts_Piece p = NIL, U = NIL;
	if (off == 0) {
		*un = *u;
		*u = ((Texts_Run)__NIL_AT((ADDRESS)(*un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 148, 37, 3450))->prev;
	} else if (off >= ((Texts_Run)__NIL_AT((ADDRESS)(*u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 149, 19, 3474))->len) {
		*un = ((Texts_Run)__NIL_AT((ADDRESS)(*u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 149, 36, 3491))->next;
	} else {
		__NEW(p, Texts_PieceDesc);
		*un = (Texts_Run)p;
		U = __GUARDPN_AT(*u, Texts_PieceDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 150, 33, 3529);
		__GUARDEQPN_AT(p, Texts_PieceDesc, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 151, 8, 3545) = *((Texts_Piece)__NIL_AT((ADDRESS)(U), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 151, 14, 3551));
		((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 151, 22, 3559))->org += off;
		((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 151, 39, 3576))->len -= off;
		((Texts_Piece)__NIL_AT((ADDRESS)(U), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 151, 56, 3593))->len -= ((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 151, 63, 3600))->len;
		((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 152, 8, 3614))->ascii = ((Texts_Run)__NIL_AT((ADDRESS)(*u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 152, 19, 3625))->ascii;
		((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 152, 28, 3634))->prev = (Texts_Run)U;
		((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 152, 41, 3647))->next = ((Texts_Piece)__NIL_AT((ADDRESS)(U), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 152, 51, 3657))->next;
		((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 152, 59, 3665))->next), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 152, 64, 3670))->prev = (Texts_Run)p;
		((Texts_Piece)__NIL_AT((ADDRESS)(U), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 152, 77, 3683))->next = (Texts_Run)p;
	}
}

static void Texts_Merge (Texts_Text T, Texts_Run u, Texts_Run *v)
{
	Texts_Piece p = NIL, q = NIL;
	if ((((((((((__ISP(u, Texts_PieceDesc, 1) && __ISP(*v, Texts_PieceDesc, 1))) && __STRCMP(((Texts_FontsFont)__NIL_AT((ADDRESS)(((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 159, 40, 3843))->fnt), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 159, 44, 3847))->name, ((Texts_FontsFont)__NIL_AT((ADDRESS)(((Texts_Run)__NIL_AT((ADDRESS)(*v), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 159, 53, 3856))->fnt), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 159, 57, 3860))->name) == 0)) && ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 159, 68, 3871))->col == ((Texts_Run)__NIL_AT((ADDRESS)(*v), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 159, 76, 3879))->col)) && ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 159, 86, 3889))->voff == ((Texts_Run)__NIL_AT((ADDRESS)(*v), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 159, 95, 3898))->voff)) && ((Texts_Piece)__NIL_AT((ADDRESS)(__GUARDPN_AT(u, Texts_PieceDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 160, 9, 3913)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 160, 16, 3920))->ascii == ((Texts_Piece)__NIL_AT((ADDRESS)(__GUARDPN_AT(*v, Texts_PieceDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 160, 26, 3930)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 160, 33, 3937))->ascii)) {
		p = __GUARDPN_AT(u, Texts_PieceDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 161, 13, 3972);
		q = __GUARDPN_AT(*v, Texts_PieceDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 161, 28, 3987);
		if ((((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 162, 12, 4007))->file == ((Texts_Piece)__NIL_AT((ADDRESS)(q), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 162, 21, 4016))->file && ((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 162, 32, 4027))->org + ((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 162, 40, 4035))->len == ((Texts_Piece)__NIL_AT((ADDRESS)(q), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 162, 48, 4043))->org)) {
			if (((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 163, 13, 4066))->cache == u) {
				((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 163, 34, 4087))->corg += ((Texts_Piece)__NIL_AT((ADDRESS)(q), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 163, 42, 4095))->len;
			} else if (((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 164, 16, 4116))->cache == *v) {
				((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 164, 33, 4133))->cache = ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 164, 44, 4144))->head;
				((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 164, 52, 4152))->corg = 0;
			}
			((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 166, 14, 4189))->len += ((Texts_Piece)__NIL_AT((ADDRESS)(q), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 166, 21, 4196))->len;
			*v = ((Texts_Run)__NIL_AT((ADDRESS)(*v), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 166, 34, 4209))->next;
		}
	}
}

static void Texts_Splice (Texts_Run un, Texts_Run v, Texts_Run w, Texts_Text base)
{
	Texts_Run u = NIL;
	if (v != ((Texts_Run)__NIL_AT((ADDRESS)(w), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 174, 13, 4363))->next) {
		u = ((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 174, 31, 4381))->prev;
		((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 175, 8, 4395))->next = v;
		((Texts_Run)__NIL_AT((ADDRESS)(v), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 175, 21, 4408))->prev = u;
		((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 175, 35, 4422))->prev = w;
		((Texts_Run)__NIL_AT((ADDRESS)(w), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 175, 48, 4435))->next = un;
		do {
			if (__ISP(v, Texts_ElemDesc, 1)) {
				((Texts_Elem)__NIL_AT((ADDRESS)(__GUARDPN_AT(v, Texts_ElemDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 177, 28, 4488)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 177, 34, 4494))->base = base;
			}
			v = ((Texts_Run)__NIL_AT((ADDRESS)(v), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 178, 15, 4527))->next;
		} while (!(v == un));
	}
}

static Texts_Piece Texts_ClonePiece (Texts_Piece p)
{
	Texts_Piece q = NIL;
	__NEW(q, Texts_PieceDesc);
	__GUARDEQPN_AT(q, Texts_PieceDesc, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 185, 18, 4652) = *((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 185, 24, 4658));
	return q;
}

static Texts_Elem Texts_CloneElem (Texts_Elem e)
{
	Texts_CopyMsg msg;
	msg.e = NIL;
	((Texts_Handler)__NIL_AT((ADDRESS)(((Texts_Elem)__NIL_AT((ADDRESS)(e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 190, 24, 4773))->handle), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 190, 24, 4773))(e, (void*)&msg, Texts_CopyMsg__typ);
	return msg.e;
}

void Texts_CopyElem (Texts_Elem SE, Texts_Elem DE)
{
	((Texts_Elem)__NIL_AT((ADDRESS)(DE), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 197, 11, 4890))->len = ((Texts_Elem)__NIL_AT((ADDRESS)(SE), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 197, 21, 4900))->len;
	((Texts_Elem)__NIL_AT((ADDRESS)(DE), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 197, 29, 4908))->fnt = ((Texts_Elem)__NIL_AT((ADDRESS)(SE), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 197, 39, 4918))->fnt;
	((Texts_Elem)__NIL_AT((ADDRESS)(DE), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 197, 47, 4926))->col = ((Texts_Elem)__NIL_AT((ADDRESS)(SE), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 197, 57, 4936))->col;
	((Texts_Elem)__NIL_AT((ADDRESS)(DE), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 197, 65, 4944))->voff = ((Texts_Elem)__NIL_AT((ADDRESS)(SE), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 197, 76, 4955))->voff;
	((Texts_Elem)__NIL_AT((ADDRESS)(DE), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 198, 7, 4968))->W = ((Texts_Elem)__NIL_AT((ADDRESS)(SE), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 198, 15, 4976))->W;
	((Texts_Elem)__NIL_AT((ADDRESS)(DE), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 198, 21, 4982))->H = ((Texts_Elem)__NIL_AT((ADDRESS)(SE), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 198, 29, 4990))->H;
	((Texts_Elem)__NIL_AT((ADDRESS)(DE), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 198, 35, 4996))->handle = ((Texts_Elem)__NIL_AT((ADDRESS)(SE), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 198, 48, 5009))->handle;
}

Texts_Text Texts_ElemBase (Texts_Elem E)
{
	return ((Texts_Elem)__NIL_AT((ADDRESS)(E), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 202, 17, 5089))->base;
}

INT32 Texts_ElemPos (Texts_Elem E)
{
	Texts_Run u = NIL;
	INT32 pos;
	u = ((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Text)__NIL_AT((ADDRESS)(((Texts_Elem)__NIL_AT((ADDRESS)(E), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 207, 15, 5197))->base), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 207, 20, 5202))->head), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 207, 25, 5207))->next;
	pos = 0;
	while (u != (void *) E) {
		pos = pos + ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 208, 34, 5257))->len;
		u = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 208, 46, 5269))->next;
	}
	return pos;
}

static void Texts_HandleAlien (Texts_Elem E, Texts_ElemMsg *msg, ADDRESS *msg__typ)
{
	Texts_Alien e = NIL;
	Files_Rider r;
	INT32 i;
	CHAR ch;
	if (__ISP(E, Texts__1, 2)) {
		if (__IS(msg__typ, Texts_CopyMsg, 1)) {
			if (__IS(msg__typ, Texts_CopyMsg, 1)) {
				Texts_CopyMsg *msg__ = (void*)msg;
				__NEW(e, Texts__1);
				Texts_CopyElem((void*)(*(Texts_Alien*)&E), (void*)e);
				((Texts_Alien)__NIL_AT((ADDRESS)(e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 219, 12, 5543))->file = ((Texts_Alien)__NIL_AT((ADDRESS)((*(Texts_Alien*)&E)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 219, 22, 5553))->file;
				((Texts_Alien)__NIL_AT((ADDRESS)(e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 219, 30, 5561))->org = ((Texts_Alien)__NIL_AT((ADDRESS)((*(Texts_Alien*)&E)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 219, 39, 5570))->org;
				((Texts_Alien)__NIL_AT((ADDRESS)(e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 219, 46, 5577))->span = ((Texts_Alien)__NIL_AT((ADDRESS)((*(Texts_Alien*)&E)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 219, 56, 5587))->span;
				__MOVE(((Texts_Alien)__NIL_AT((ADDRESS)((*(Texts_Alien*)&E)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 219, 73, 5604))->mod, ((Texts_Alien)__NIL_AT((ADDRESS)(e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 219, 64, 5595))->mod, 32);
				__MOVE(((Texts_Alien)__NIL_AT((ADDRESS)((*(Texts_Alien*)&E)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 219, 90, 5621))->proc, ((Texts_Alien)__NIL_AT((ADDRESS)(e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 219, 80, 5611))->proc, 32);
				(*msg__).e = (Texts_Elem)e;
			} else __WITHCHK;
		} else if (__IS(msg__typ, Texts_IdentifyMsg, 1)) {
			if (__IS(msg__typ, Texts_IdentifyMsg, 1)) {
				Texts_IdentifyMsg *msg__ = (void*)msg;
				__COPY(((Texts_Alien)__NIL_AT((ADDRESS)((*(Texts_Alien*)&E)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 224, 17, 5746))->mod, (*msg__).mod, 32);
				__COPY(((Texts_Alien)__NIL_AT((ADDRESS)((*(Texts_Alien*)&E)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 224, 39, 5768))->proc, (*msg__).proc, 32);
				(*msg__).mod[31] = 0x01;
			} else __WITHCHK;
		} else if (__IS(msg__typ, Texts_FileMsg, 1)) {
			if (__IS(msg__typ, Texts_FileMsg, 1)) {
				Texts_FileMsg *msg__ = (void*)msg;
				if ((*msg__).id == 1) {
					Files_Set(&r, Files_Rider__typ, ((Texts_Alien)__NIL_AT((ADDRESS)((*(Texts_Alien*)&E)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 228, 48, 5934))->file, ((Texts_Alien)__NIL_AT((ADDRESS)((*(Texts_Alien*)&E)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 228, 56, 5942))->org);
					i = ((Texts_Alien)__NIL_AT((ADDRESS)((*(Texts_Alien*)&E)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 228, 69, 5955))->span;
					while (i > 0) {
						Files_Read(&r, Files_Rider__typ, (void*)&ch);
						Files_Write(&(*msg__).r, Files_Rider__typ, ch);
						i -= 1;
					}
				}
			} else __WITHCHK;
		}
	} else __WITHCHK;
}

void Texts_OpenBuf (Texts_Buffer B)
{
	Texts_Run u = NIL;
	Platform_CommandCritical(1);
	__NEW(u, Texts_RunDesc);
	((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 243, 14, 6234))->next = u;
	((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 243, 27, 6247))->prev = u;
	((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 243, 40, 6260))->head = u;
	((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 243, 53, 6273))->len = 0;
	Platform_CommandCritical(0);
}

void Texts_Copy (Texts_Buffer SB, Texts_Buffer DB)
{
	Texts_Run u = NIL, v = NIL, vn = NIL;
	Platform_CommandCritical(1);
	u = ((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Buffer)__NIL_AT((ADDRESS)(SB), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 249, 48, 6442))->head), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 249, 53, 6447))->next;
	v = ((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Buffer)__NIL_AT((ADDRESS)(DB), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 249, 67, 6461))->head), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 249, 72, 6466))->prev;
	while (u != ((Texts_Buffer)__NIL_AT((ADDRESS)(SB), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 250, 17, 6489))->head) {
		if (__ISP(u, Texts_PieceDesc, 1)) {
			vn = (Texts_Run)Texts_ClonePiece(__GUARDPN_AT(u, Texts_PieceDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 251, 44, 6541));
		} else {
			vn = (Texts_Run)Texts_CloneElem(__GUARDPN_AT(u, Texts_ElemDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 251, 75, 6572));
		}
		((Texts_Run)__NIL_AT((ADDRESS)(v), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 252, 8, 6592))->next = vn;
		((Texts_Run)__NIL_AT((ADDRESS)(vn), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 252, 23, 6607))->prev = v;
		v = vn;
		u = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 252, 50, 6634))->next;
	}
	((Texts_Run)__NIL_AT((ADDRESS)(v), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 254, 6, 6654))->next = ((Texts_Buffer)__NIL_AT((ADDRESS)(DB), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 254, 17, 6665))->head;
	((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Buffer)__NIL_AT((ADDRESS)(DB), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 254, 26, 6674))->head), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 254, 31, 6679))->prev = v;
	((Texts_Buffer)__NIL_AT((ADDRESS)(DB), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 255, 11, 6701))->len += ((Texts_Buffer)__NIL_AT((ADDRESS)(SB), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 255, 19, 6709))->len;
	Platform_CommandCritical(0);
}

void Texts_Recall (Texts_Buffer *B)
{
	Platform_CommandCritical(1);
	*B = Texts_del;
	Texts_del = NIL;
	Platform_CommandCritical(0);
}

void Texts_Save (Texts_Text T, INT32 beg, INT32 end, Texts_Buffer B)
{
	Texts_Run u = NIL, v = NIL, w = NIL, wn = NIL;
	INT32 uo, ud, vo, vd;
	Platform_CommandCritical(1);
	Texts_Find(T, &beg, &u, &uo, &ud);
	Texts_Find(T, &end, &v, &vo, &vd);
	w = ((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 269, 11, 7139))->head), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 269, 16, 7144))->prev;
	while (u != v) {
		if (__ISP(u, Texts_PieceDesc, 1)) {
			wn = (Texts_Run)Texts_ClonePiece(__GUARDPN_AT(u, Texts_PieceDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 271, 44, 7213));
			((Texts_Run)__NIL_AT((ADDRESS)(wn), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 271, 60, 7229))->len -= ud;
			((Texts_Piece)__NIL_AT((ADDRESS)(__GUARDPN_AT(wn, Texts_PieceDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 271, 77, 7246)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 271, 84, 7253))->org += ud;
		} else {
			wn = (Texts_Run)Texts_CloneElem(__GUARDPN_AT(u, Texts_ElemDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 272, 29, 7291));
		}
		((Texts_Run)__NIL_AT((ADDRESS)(w), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 274, 8, 7317))->next = wn;
		((Texts_Run)__NIL_AT((ADDRESS)(wn), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 274, 23, 7332))->prev = w;
		w = wn;
		u = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 274, 50, 7359))->next;
		ud = 0;
	}
	if (vd > 0) {
		wn = (Texts_Run)Texts_ClonePiece(__GUARDPN_AT(v, Texts_PieceDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 276, 53, 7435));
		((Texts_Run)__NIL_AT((ADDRESS)(wn), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 276, 65, 7447))->len = vd - ud;
		((Texts_Piece)__NIL_AT((ADDRESS)(__GUARDPN_AT(wn, Texts_PieceDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 276, 88, 7470)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 276, 95, 7477))->org += ud;
		((Texts_Run)__NIL_AT((ADDRESS)(w), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 277, 8, 7495))->next = wn;
		((Texts_Run)__NIL_AT((ADDRESS)(wn), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 277, 23, 7510))->prev = w;
		w = wn;
	}
	((Texts_Run)__NIL_AT((ADDRESS)(w), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 279, 6, 7544))->next = ((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 279, 16, 7554))->head;
	((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 279, 24, 7562))->head), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 279, 29, 7567))->prev = w;
	((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 280, 10, 7588))->len += end - beg;
	Platform_CommandCritical(0);
}

void Texts_Insert (Texts_Text T, INT32 pos, Texts_Buffer B)
{
	Texts_Run u = NIL, un = NIL, v = NIL;
	Texts_Piece p = NIL, q = NIL;
	INT32 uo, ud, len;
	Platform_CommandCritical(1);
	Texts_Find(T, &pos, &u, &uo, &ud);
	Texts_Split(ud, &u, &un);
	len = ((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 287, 13, 7864))->len;
	v = ((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 287, 25, 7876))->head), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 287, 30, 7881))->next;
	Texts_Merge(T, u, &v);
	Texts_Splice(un, v, ((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 288, 36, 7923))->head), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 288, 41, 7928))->prev, T);
	((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 289, 10, 7948))->len += len;
	((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 289, 23, 7961))->head), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 289, 28, 7966))->next = ((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 289, 38, 7976))->head;
	((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 289, 46, 7984))->head), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 289, 51, 7989))->prev = ((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 289, 61, 7999))->head;
	((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 289, 69, 8007))->len = 0;
	Platform_CommandCritical(0);
	if (((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 291, 9, 8063))->notify != NIL) {
		((Texts_Notifier)__NIL_AT((ADDRESS)(((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 291, 29, 8083))->notify), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 291, 29, 8083))(T, 1, pos, pos + len);
	}
}

void Texts_Append (Texts_Text T, Texts_Buffer B)
{
	Texts_Run v = NIL;
	INT32 pos, len;
	Platform_CommandCritical(1);
	pos = ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 296, 49, 8260))->len;
	len = ((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 296, 63, 8274))->len;
	v = ((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 296, 75, 8286))->head), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 296, 80, 8291))->next;
	Texts_Merge(T, ((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 297, 15, 8312))->head), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 297, 20, 8317))->prev, &v);
	Texts_Splice(((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 297, 39, 8336))->head, v, ((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 297, 50, 8347))->head), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 297, 55, 8352))->prev, T);
	((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 298, 10, 8372))->len += len;
	((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 298, 23, 8385))->head), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 298, 28, 8390))->next = ((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 298, 38, 8400))->head;
	((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 298, 46, 8408))->head), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 298, 51, 8413))->prev = ((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 298, 61, 8423))->head;
	((Texts_Buffer)__NIL_AT((ADDRESS)(B), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 298, 69, 8431))->len = 0;
	Platform_CommandCritical(0);
	if (((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 300, 9, 8487))->notify != NIL) {
		((Texts_Notifier)__NIL_AT((ADDRESS)(((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 300, 29, 8507))->notify), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 300, 29, 8507))(T, 1, pos, pos + len);
	}
}

void Texts_Delete (Texts_Text T, INT32 beg, INT32 end)
{
	Texts_Run c = NIL, u = NIL, un = NIL, v = NIL, vn = NIL;
	INT32 co, uo, ud, vo, vd;
	Platform_CommandCritical(1);
	Texts_Find(T, &beg, &u, &uo, &ud);
	Texts_Split(ud, &u, &un);
	c = ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 307, 54, 8765))->cache;
	co = ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 307, 69, 8780))->corg;
	Texts_Find(T, &end, &v, &vo, &vd);
	Texts_Split(vd, &v, &vn);
	((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 308, 49, 8835))->cache = c;
	((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 308, 63, 8849))->corg = co;
	__NEW(Texts_del, Texts_BufDesc);
	Texts_OpenBuf(Texts_del);
	((Texts_Buffer)__NIL_AT((ADDRESS)(Texts_del), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 309, 32, 8893))->len = end - beg;
	Texts_Splice(((Texts_Buffer)__NIL_AT((ADDRESS)(Texts_del), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 310, 15, 8926))->head, un, v, NIL);
	Texts_Merge(T, u, &vn);
	((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 311, 23, 8968))->next = vn;
	((Texts_Run)__NIL_AT((ADDRESS)(vn), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 311, 38, 8983))->prev = u;
	((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 312, 10, 9004))->len -= end - beg;
	Platform_CommandCritical(0);
	if (((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 314, 9, 9067))->notify != NIL) {
		((Texts_Notifier)__NIL_AT((ADDRESS)(((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 314, 29, 9087))->notify), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 314, 29, 9087))(T, 2, beg, end);
	}
}

void Texts_ChangeLooks (Texts_Text T, INT32 beg, INT32 end, UINT32 sel, Texts_FontsFont fnt, INT8 col, INT8 voff)
{
	Texts_Run c = NIL, u = NIL, un = NIL, v = NIL, vn = NIL;
	INT32 co, uo, ud, vo, vd;
	Platform_CommandCritical(1);
	Texts_Find(T, &beg, &u, &uo, &ud);
	Texts_Split(ud, &u, &un);
	c = ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 319, 90, 9388))->cache;
	co = ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 319, 105, 9403))->corg;
	Texts_Find(T, &end, &v, &vo, &vd);
	Texts_Split(vd, &v, &vn);
	((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 320, 49, 9458))->cache = c;
	((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 320, 63, 9472))->corg = co;
	while (un != vn) {
		if ((__IN(0, sel, 32) && fnt != NIL)) {
			((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 322, 42, 9547))->fnt = fnt;
		}
		if (__IN(1, sel, 32)) {
			((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 323, 26, 9589))->col = col;
		}
		if (__IN(2, sel, 32)) {
			((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 324, 26, 9631))->voff = voff;
		}
		Texts_Merge(T, u, &un);
		if (((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 326, 11, 9683))->next == un) {
			u = un;
			un = ((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 326, 44, 9716))->next;
		} else {
			((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 326, 56, 9728))->next = un;
			((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 326, 71, 9743))->prev = u;
		}
	}
	Texts_Merge(T, u, &un);
	((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 328, 23, 9789))->next = un;
	((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 328, 38, 9804))->prev = u;
	Platform_CommandCritical(0);
	if (((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 330, 9, 9861))->notify != NIL) {
		((Texts_Notifier)__NIL_AT((ADDRESS)(((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 330, 29, 9881))->notify), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 330, 29, 9881))(T, 0, beg, end);
	}
}

void Texts_OpenReader (Texts_Reader *R, ADDRESS *R__typ, Texts_Text T, INT32 pos)
{
	Texts_Run u = NIL;
	Platform_CommandCritical(1);
	if (pos >= ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 340, 16, 10094))->len) {
		pos = ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 340, 34, 10112))->len;
	}
	Texts_Find(T, &pos, &u, &(*R).org, &(*R).off);
	(*R).run = u;
	(*R).eot = 0;
	if (__ISP(u, Texts_PieceDesc, 1)) {
		Files_Set(&(*R).rider, Files_Rider__typ, ((Texts_Piece)__NIL_AT((ADDRESS)(__GUARDPN_AT(u, Texts_PieceDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 343, 27, 10234)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 343, 34, 10241))->file, ((Texts_Piece)__NIL_AT((ADDRESS)(__GUARDPN_AT(u, Texts_PieceDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 343, 42, 10249)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 343, 49, 10256))->org + (*R).off);
	}
	Platform_CommandCritical(0);
}

void Texts_Read (Texts_Reader *R, ADDRESS *R__typ, CHAR *ch)
{
	Texts_Run u = NIL;
	INT32 pos;
	CHAR nextch;
	Platform_CommandCritical(1);
	u = (*R).run;
	(*R).fnt = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 350, 63, 10489))->fnt;
	(*R).col = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 350, 79, 10505))->col;
	(*R).voff = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 350, 96, 10522))->voff;
	(*R).off += 1;
	if (__ISP(u, Texts_PieceDesc, 1)) {
		Files_Read(&(*R).rider, Files_Rider__typ, (void*)&*ch);
		(*R).elem = NIL;
		if ((*ch == 0x0a && ((Texts_Piece)__NIL_AT((ADDRESS)(__GUARDPN_AT(u, Texts_PieceDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 352, 24, 10627)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 352, 31, 10634))->ascii)) {
			*ch = 0x0d;
		} else if ((*ch == 0x0d && ((Texts_Piece)__NIL_AT((ADDRESS)(__GUARDPN_AT(u, Texts_PieceDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 353, 26, 10698)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 353, 33, 10705))->ascii)) {
			pos = Files_Pos(&(*R).rider, Files_Rider__typ);
			Files_Read(&(*R).rider, Files_Rider__typ, (void*)&nextch);
			if (nextch == 0x0a) {
				(*R).off += 1;
			} else {
				Files_Set(&(*R).rider, Files_Rider__typ, ((Texts_Piece)__NIL_AT((ADDRESS)(__GUARDPN_AT(u, Texts_PieceDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 355, 65, 10866)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 355, 72, 10873))->file, pos);
			}
		}
	} else if (__ISP(u, Texts_ElemDesc, 1)) {
		*ch = 0x1c;
		(*R).elem = __GUARDPN_AT(u, Texts_ElemDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 357, 53, 10951);
	} else {
		*ch = 0x00;
		(*R).elem = NIL;
		(*R).eot = 1;
	}
	if ((*R).off == ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 360, 17, 11031))->len) {
		(*R).org += ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 360, 39, 11053))->len;
		u = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 360, 52, 11066))->next;
		if (__ISP(u, Texts_PieceDesc, 1)) {
			if (__ISP(u, Texts_PieceDesc, 1)) {
				Files_Set(&(*R).rider, Files_Rider__typ, ((Texts_Piece)__NIL_AT((ADDRESS)((*(Texts_Piece*)&u)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 362, 46, 11143))->file, ((Texts_Piece)__NIL_AT((ADDRESS)((*(Texts_Piece*)&u)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 362, 54, 11151))->org);
			} else __WITHCHK;
		}
		(*R).run = u;
		(*R).off = 0;
	}
	Platform_CommandCritical(0);
}

void Texts_ReadElem (Texts_Reader *R, ADDRESS *R__typ)
{
	Texts_Run u = NIL, un = NIL;
	u = (*R).run;
	while (__ISP(u, Texts_PieceDesc, 1)) {
		(*R).org += ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 372, 37, 11374))->len;
		u = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 372, 50, 11387))->next;
	}
	if (__ISP(u, Texts_ElemDesc, 1)) {
		un = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 373, 30, 11427))->next;
		(*R).run = un;
		(*R).org += 1;
		(*R).off = 0;
		(*R).fnt = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 374, 17, 11487))->fnt;
		(*R).col = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 374, 33, 11503))->col;
		(*R).voff = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 374, 50, 11520))->voff;
		(*R).elem = __GUARDPN_AT(u, Texts_ElemDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 374, 68, 11538);
		if (__ISP(un, Texts_PieceDesc, 1)) {
			if (__ISP(un, Texts_PieceDesc, 1)) {
				Files_Set(&(*R).rider, Files_Rider__typ, ((Texts_Piece)__NIL_AT((ADDRESS)((*(Texts_Piece*)&un)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 376, 48, 11619))->file, ((Texts_Piece)__NIL_AT((ADDRESS)((*(Texts_Piece*)&un)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 376, 57, 11628))->org);
			} else __WITHCHK;
		}
	} else {
		(*R).eot = 1;
		(*R).elem = NIL;
	}
}

void Texts_ReadPrevElem (Texts_Reader *R, ADDRESS *R__typ)
{
	Texts_Run u = NIL;
	u = ((Texts_Run)__NIL_AT((ADDRESS)((*R).run), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 384, 19, 11788))->prev;
	while (__ISP(u, Texts_PieceDesc, 1)) {
		(*R).org -= ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 385, 37, 11831))->len;
		u = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 385, 50, 11844))->prev;
	}
	if (__ISP(u, Texts_ElemDesc, 1)) {
		(*R).run = u;
		(*R).org -= 1;
		(*R).off = 0;
		(*R).fnt = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 387, 17, 11929))->fnt;
		(*R).col = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 387, 33, 11945))->col;
		(*R).voff = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 387, 50, 11962))->voff;
		(*R).elem = __GUARDPN_AT(u, Texts_ElemDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 387, 68, 11980);
	} else {
		(*R).eot = 1;
		(*R).elem = NIL;
	}
}

INT32 Texts_Pos (Texts_Reader *R, ADDRESS *R__typ)
{
	return (*R).org + (*R).off;
}

void Texts_OpenScanner (Texts_Scanner *S, ADDRESS *S__typ, Texts_Text T, INT32 pos)
{
	Texts_OpenReader((void*)&*S, S__typ, T, pos);
	(*S).line = 0;
	(*S).nextCh = ' ';
}

static struct Scan__31 {
	Texts_Scanner *S;
	ADDRESS *S__typ;
	CHAR *ch;
	BOOLEAN *negE, *sticky, *tooLong, *invalid;
	INT16 *i;
	INT64 *e, *scale;
	INT32 *digit;
	CHAR (*d)[1100];
	struct Scan__31 *lnk;
} *Scan__31_s;

static void Digit__33 (CHAR ch, BOOLEAN fraction);
static void ReadScaleFactor__35 (void);

static void Digit__33 (CHAR ch, BOOLEAN fraction)
{
	if (*Scan__31_s->i > 0 || ch != '0') {
		if (*Scan__31_s->i < 1100) {
			(*Scan__31_s->d)[__X_AT(*Scan__31_s->i, 1100, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 422, 13, 13116)] = ch;
			*Scan__31_s->i += 1;
			if (fraction) {
				if (*Scan__31_s->scale > (-9223372036854775807LL-1)) {
					*Scan__31_s->scale -= 1;
				} else {
					*Scan__31_s->invalid = 1;
				}
			}
		} else {
			*Scan__31_s->sticky = *Scan__31_s->sticky || ch != '0';
			if (!fraction) {
				*Scan__31_s->tooLong = 1;
				if (*Scan__31_s->scale < 9223372036854775807LL) {
					*Scan__31_s->scale += 1;
				} else {
					*Scan__31_s->invalid = 1;
				}
			}
		}
	} else if (fraction) {
		if (*Scan__31_s->scale > (-9223372036854775807LL-1)) {
			*Scan__31_s->scale -= 1;
		} else {
			*Scan__31_s->invalid = 1;
		}
	}
}

static void ReadScaleFactor__35 (void)
{
	BOOLEAN seen;
	Texts_Read((void*)&*Scan__31_s->S, Scan__31_s->S__typ, &*Scan__31_s->ch);
	if (*Scan__31_s->ch == '-') {
		*Scan__31_s->negE = 1;
		Texts_Read((void*)&*Scan__31_s->S, Scan__31_s->S__typ, &*Scan__31_s->ch);
	} else {
		*Scan__31_s->negE = 0;
		if (*Scan__31_s->ch == '+') {
			Texts_Read((void*)&*Scan__31_s->S, Scan__31_s->S__typ, &*Scan__31_s->ch);
		}
	}
	seen = 0;
	while (('0' <= *Scan__31_s->ch && *Scan__31_s->ch <= '9')) {
		seen = 1;
		*Scan__31_s->digit = (INT16)*Scan__31_s->ch - 48;
		if (*Scan__31_s->e <= __DIV(9223372036854775807LL - (INT64)*Scan__31_s->digit, 10)) {
			*Scan__31_s->e = *Scan__31_s->e * 10 + (INT64)*Scan__31_s->digit;
		} else {
			*Scan__31_s->invalid = 1;
		}
		Texts_Read((void*)&*Scan__31_s->S, Scan__31_s->S__typ, &*Scan__31_s->ch);
	}
	if (!seen) {
		*Scan__31_s->invalid = 1;
	}
}

void Texts_Scan (Texts_Scanner *S, ADDRESS *S__typ)
{
	CHAR ch, term, swap;
	BOOLEAN neg, negE, hex, sticky, tooLong, invalid;
	INT16 i, j, n;
	INT64 e, scale;
	INT32 k, digit, limit;
	CHAR d[1100];
	CHAR number[1164];
	INT16 _for__32;
	struct Scan__31 _s;
	_s.S = S; _s.S__typ = S__typ;
	_s.ch = &ch;
	_s.negE = &negE;
	_s.sticky = &sticky;
	_s.tooLong = &tooLong;
	_s.invalid = &invalid;
	_s.i = &i;
	_s.e = &e;
	_s.scale = &scale;
	_s.digit = &digit;
	_s.d = (void*)d;
	_s.lnk = Scan__31_s;
	Scan__31_s = &_s;
	ch = (*S).nextCh;
	i = 0;
	for (;;) {
		if (ch == 0x0d) {
			(*S).line += 1;
		} else if ((ch != ' ' && ch != 0x09)) {
			break;
		}
		Texts_Read((void*)&*S, S__typ, &ch);
	}
	if ((('A' <= __CAP(ch) && __CAP(ch) <= 'Z') || ch == '/') || ch == '.') {
		do {
			(*S).s[__X_AT(i, 64, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 463, 18, 14394)] = ch;
			i += 1;
			Texts_Read((void*)&*S, S__typ, &ch);
		} while (!((((__CAP(ch) > 'Z' && ch != '_') || ('A' > __CAP(ch) && ch > '9')) || ((('0' > ch && ch != '.')) && ch != '/')) || i == 63));
		(*S).s[__X_AT(i, 64, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 468, 11, 14614)] = 0x00;
		(*S).len = __SHORT(i, 128);
		(*S).class = 1;
	} else if (ch == '"') {
		Texts_Read((void*)&*S, S__typ, &ch);
		while ((((ch != '"' && ch >= ' ')) && i != 63)) {
			(*S).s[__X_AT(i, 64, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 472, 13, 14791)] = ch;
			i += 1;
			Texts_Read((void*)&*S, S__typ, &ch);
		}
		(*S).s[__X_AT(i, 64, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 474, 11, 14842)] = 0x00;
		(*S).len = __SHORT(i + 1, 128);
		Texts_Read((void*)&*S, S__typ, &ch);
		(*S).class = 2;
	} else {
		if (ch == '-') {
			neg = 1;
			Texts_Read((void*)&*S, S__typ, &ch);
		} else {
			neg = 0;
		}
		if (('0' <= ch && ch <= '9')) {
			hex = 0;
			sticky = 0;
			tooLong = 0;
			invalid = 0;
			negE = 0;
			scale = 0;
			e = 0;
			for (;;) {
				Digit__33(ch, 0);
				Texts_Read((void*)&*S, S__typ, &ch);
				if (ch < '0') {
					break;
				}
				if ('9' < ch) {
					if (('A' <= ch && ch <= 'F')) {
						hex = 1;
						ch = __CHR((INT16)ch - 7);
					} else if (('a' <= ch && ch <= 'f')) {
						hex = 1;
						ch = __CHR((INT16)ch - 39);
					} else {
						break;
					}
				}
			}
			if (ch == 'H') {
				Texts_Read((void*)&*S, S__typ, &ch);
				(*S).class = 3;
				k = 0;
				if (tooLong) {
					(*S).class = 0;
				} else if (i > 0) {
					if (i > 8) {
						j = i - 8;
					} else {
						j = 0;
					}
					k = (INT16)d[__X_AT(j, 1100, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 494, 24, 15719)] - 48;
					j += 1;
					if ((i - j == 7 && k >= 8)) {
						k -= 16;
					}
					while (j < i) {
						k = __ASHL(k, 4) + ((INT16)d[__X_AT(j, 1100, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 496, 48, 15840)] - 48);
						j += 1;
					}
				}
				if ((neg && k == (-2147483647-1))) {
					(*S).class = 0;
				} else if (neg) {
					(*S).i = -k;
				} else {
					(*S).i = k;
				}
			} else if (ch == '.') {
				Texts_Read((void*)&*S, S__typ, &ch);
				while (('0' <= ch && ch <= '9')) {
					Digit__33(ch, 1);
					Texts_Read((void*)&*S, S__typ, &ch);
				}
				term = ch;
				if (term == 'D') {
					(*S).class = 5;
					ReadScaleFactor__35();
				} else {
					(*S).class = 4;
					if (term == 'E') {
						ReadScaleFactor__35();
					}
				}
				if (hex || invalid) {
					(*S).class = 0;
				} else {
					if (negE) {
						e = -e;
					}
					if ((e > 0 && scale > 9223372036854775807LL - e)) {
						scale = 9223372036854775807LL;
					} else if ((e < 0 && scale < (-9223372036854775807LL-1) - e)) {
						scale = (-9223372036854775807LL-1);
					} else {
						scale += e;
					}
					if (scale > 1000000) {
						scale = 1000000;
					} else if (scale < -1000000) {
						scale = -1000000;
					}
					n = 0;
					if (neg) {
						number[__X_AT(n, 1164, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 519, 32, 16955)] = '-';
						n += 1;
					}
					if (i == 0) {
						number[__X_AT(n, 1164, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 520, 34, 17011)] = '0';
						n += 1;
					} else {
						_for__32 = i - 1;
						j = 0;
						while (j <= _for__32) {
							number[__X_AT(n, 1164, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 521, 46, 17074)] = d[__X_AT(j, 1100, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 521, 54, 17082)];
							n += 1;
							j += 1;
						}
					}
					if (sticky) {
						number[__X_AT(n, 1164, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 525, 35, 17300)] = '1';
						n += 1;
						scale -= 1;
					}
					number[__X_AT(n, 1164, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 527, 20, 17435)] = 'E';
					n += 1;
					if (scale < 0) {
						number[__X_AT(n, 1164, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 528, 38, 17491)] = '-';
						n += 1;
						scale = -scale;
					}
					j = n;
					do {
						number[__X_AT(n, 1164, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 530, 27, 17577)] = __CHR(__MOD(scale, 10) + 48);
						scale = __DIV(scale, 10);
						n += 1;
					} while (!(scale == 0));
					number[__X_AT(n, 1164, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 531, 20, 17674)] = 0x00;
					n -= 1;
					while (j < n) {
						swap = number[__X_AT(j, 1164, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 532, 43, 17734)];
						number[__X_AT(j, 1164, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 532, 54, 17745)] = number[__X_AT(n, 1164, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 532, 67, 17758)];
						number[__X_AT(n, 1164, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 532, 78, 17769)] = swap;
						j += 1;
						n -= 1;
					}
					if ((*S).class == 5) {
						(*S).y = Reals_ParseLongReal(number, 1164);
					} else {
						(*S).x = Reals_ParseReal(number, 1164);
					}
				}
			} else {
				(*S).class = 3;
				k = 0;
				j = 0;
				limit = 7;
				if (neg) {
					limit += 1;
				}
				while ((j < i && !invalid)) {
					digit = (INT16)d[__X_AT(j, 1100, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 539, 28, 18137)] - 48;
					if ((digit > 9 || k < -214748364) || (k == -214748364 && digit > limit)) {
						invalid = 1;
					} else {
						k = k * 10 - digit;
						j += 1;
					}
				}
				if ((hex || tooLong) || invalid) {
					(*S).class = 0;
				} else if (neg) {
					(*S).i = k;
				} else {
					(*S).i = -k;
				}
			}
		} else {
			(*S).class = 6;
			if (neg) {
				(*S).c = '-';
			} else {
				(*S).c = ch;
				Texts_Read((void*)&*S, S__typ, &ch);
			}
		}
	}
	(*S).nextCh = ch;
	Scan__31_s = _s.lnk;
}

void Texts_OpenWriter (Texts_Writer *W, ADDRESS *W__typ)
{
	Platform_CommandCritical(1);
	__NEW((*W).buf, Texts_BufDesc);
	Texts_OpenBuf((*W).buf);
	(*W).fnt = Texts_FontsDefault;
	(*W).col = 15;
	(*W).voff = 0;
	(*W).file = Files_New((CHAR*)"", 1);
	Files_Set(&(*W).rider, Files_Rider__typ, (*W).file, 0);
	Platform_CommandCritical(0);
}

void Texts_SetFont (Texts_Writer *W, ADDRESS *W__typ, Texts_FontsFont fnt)
{
	(*W).fnt = fnt;
}

void Texts_SetColor (Texts_Writer *W, ADDRESS *W__typ, INT8 col)
{
	(*W).col = col;
}

void Texts_SetOffset (Texts_Writer *W, ADDRESS *W__typ, INT8 voff)
{
	(*W).voff = voff;
}

void Texts_Write (Texts_Writer *W, ADDRESS *W__typ, CHAR ch)
{
	Texts_Run u = NIL, un = NIL;
	Texts_Piece p = NIL;
	Platform_CommandCritical(1);
	Files_Write(&(*W).rider, Files_Rider__typ, ch);
	((Texts_Buffer)__NIL_AT((ADDRESS)((*W).buf), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 580, 76, 19375))->len += 1;
	un = ((Texts_Buffer)__NIL_AT((ADDRESS)((*W).buf), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 580, 94, 19393))->head;
	u = ((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 580, 108, 19407))->prev;
	if ((((((((((__ISP(u, Texts_PieceDesc, 1) && ((Texts_Piece)__NIL_AT((ADDRESS)(__GUARDPN_AT(u, Texts_PieceDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 581, 25, 19438)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 581, 32, 19445))->file == (*W).file)) && __STRCMP(((Texts_FontsFont)__NIL_AT((ADDRESS)(((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 581, 52, 19465))->fnt), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 581, 56, 19469))->name, ((Texts_FontsFont)__NIL_AT((ADDRESS)((*W).fnt), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 581, 69, 19482))->name) == 0)) && ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 581, 80, 19493))->col == (*W).col)) && ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 581, 98, 19511))->voff == (*W).voff)) && !((Texts_Piece)__NIL_AT((ADDRESS)(__GUARDPN_AT(u, Texts_PieceDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 582, 9, 19535)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 582, 16, 19542))->ascii)) {
		((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 583, 12, 19574))->len += 1;
	} else {
		__NEW(p, Texts_PieceDesc);
		((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 584, 19, 19598))->next = (Texts_Run)p;
		((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 584, 32, 19611))->prev = u;
		((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 584, 45, 19624))->next = un;
		((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 584, 60, 19639))->prev = (Texts_Run)p;
		((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 585, 8, 19658))->len = 1;
		((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 585, 20, 19670))->fnt = (*W).fnt;
		((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 585, 36, 19686))->col = (*W).col;
		((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 585, 52, 19702))->voff = (*W).voff;
		((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 586, 8, 19726))->file = (*W).file;
		((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 586, 26, 19744))->org = Files_Length((*W).file) - 1;
		((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 586, 61, 19779))->ascii = 0;
	}
	Platform_CommandCritical(0);
}

void Texts_WriteElem (Texts_Writer *W, ADDRESS *W__typ, Texts_Elem e)
{
	Texts_Run u = NIL, un = NIL;
	Platform_CommandCritical(1);
	if (((Texts_Elem)__NIL_AT((ADDRESS)(e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 595, 9, 19984))->base != NIL) {
		__HALT(99);
	}
	((Texts_Buffer)__NIL_AT((ADDRESS)((*W).buf), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 596, 14, 20028))->len += 1;
	((Texts_Elem)__NIL_AT((ADDRESS)(e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 596, 22, 20036))->len = 1;
	((Texts_Elem)__NIL_AT((ADDRESS)(e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 596, 34, 20048))->fnt = (*W).fnt;
	((Texts_Elem)__NIL_AT((ADDRESS)(e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 596, 50, 20064))->col = (*W).col;
	((Texts_Elem)__NIL_AT((ADDRESS)(e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 596, 66, 20080))->voff = (*W).voff;
	un = ((Texts_Buffer)__NIL_AT((ADDRESS)((*W).buf), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 597, 16, 20112))->head;
	u = ((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 597, 30, 20126))->prev;
	((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 597, 38, 20134))->next = (Texts_Run)e;
	((Texts_Elem)__NIL_AT((ADDRESS)(e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 597, 51, 20147))->prev = u;
	((Texts_Elem)__NIL_AT((ADDRESS)(e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 597, 64, 20160))->next = un;
	((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 597, 79, 20175))->prev = (Texts_Run)e;
	Platform_CommandCritical(0);
}

void Texts_WriteLn (Texts_Writer *W, ADDRESS *W__typ)
{
	Texts_Write(&*W, W__typ, 0x0d);
}

void Texts_WriteString (Texts_Writer *W, ADDRESS *W__typ, CHAR *s, ADDRESS s__len)
{
	INT32 i;
	__DUP(s, s__len, CHAR);
	i = 0;
	while (s[__X_AT(i, s__len, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 608, 13, 20424)] >= ' ') {
		Texts_Write(&*W, W__typ, s[__X_AT(i, s__len, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 608, 37, 20448)]);
		i += 1;
	}
	__DEL(s);
}

void Texts_WriteInt (Texts_Writer *W, ADDRESS *W__typ, INT64 x, INT64 n)
{
	INT16 i;
	INT64 x0;
	CHAR a[24];
	i = 0;
	if (x < 0) {
		if (x == (-9223372036854775807LL-1)) {
			Texts_WriteString(&*W, W__typ, (CHAR*)" -9223372036854775808", 22);
			return;
		} else {
			n -= 1;
			x0 = -x;
		}
	} else {
		x0 = x;
	}
	do {
		a[__X_AT(i, 24, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 623, 9, 20809)] = __CHR(__MOD(x0, 10) + 48);
		x0 = __DIV(x0, 10);
		i += 1;
	} while (!(x0 == 0));
	while (n > (INT64)i) {
		Texts_Write(&*W, W__typ, ' ');
		n -= 1;
	}
	if (x < 0) {
		Texts_Write(&*W, W__typ, '-');
	}
	do {
		i -= 1;
		Texts_Write(&*W, W__typ, a[__X_AT(i, 24, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 627, 31, 20992)]);
	} while (!(i == 0));
}

void Texts_WriteHex (Texts_Writer *W, ADDRESS *W__typ, INT32 x)
{
	INT16 i;
	INT32 y;
	CHAR a[20];
	i = 0;
	Texts_Write(&*W, W__typ, ' ');
	do {
		y = __MASK(x, -16);
		if (y < 10) {
			a[__X_AT(i, 20, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 635, 24, 21216)] = __CHR(y + 48);
		} else {
			a[__X_AT(i, 20, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 635, 50, 21242)] = __CHR(y + 55);
		}
		x = __ASHR(x, 4);
		i += 1;
	} while (!(i == 8));
	do {
		i -= 1;
		Texts_Write(&*W, W__typ, a[__X_AT(i, 20, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 638, 31, 21342)]);
	} while (!(i == 0));
}

void Texts_WriteReal (Texts_Writer *W, ADDRESS *W__typ, REAL x, INT16 n)
{
	INT16 e;
	REAL x0;
	CHAR d[9];
	e = Reals_Expo(x);
	if (e == 0) {
		Texts_WriteString(&*W, W__typ, (CHAR*)"  0", 4);
		do {
			Texts_Write(&*W, W__typ, ' ');
			n -= 1;
		} while (!(n <= 3));
	} else if (e == 255) {
		Texts_WriteString(&*W, W__typ, (CHAR*)" NaN", 5);
		while (n > 4) {
			Texts_Write(&*W, W__typ, ' ');
			n -= 1;
		}
	} else {
		if (n <= 9) {
			n = 3;
		} else {
			n -= 6;
		}
		do {
			Texts_Write(&*W, W__typ, ' ');
			n -= 1;
		} while (!(n <= 8));
		if (x < (REAL)0.0e0) {
			Texts_Write(&*W, W__typ, '-');
			x = -x;
		} else {
			Texts_Write(&*W, W__typ, ' ');
		}
		e = __ASHR((e - 127) * 77, 8);
		if (e >= 0) {
			x = x / (REAL)Reals_Ten(e);
		} else {
			x = Reals_Ten(-e) * x;
		}
		if (x >= (REAL)1.0e1) {
			x = (REAL)1.0000000149011612e-1 * x;
			e += 1;
		}
		x0 = Reals_Ten(n - 1);
		x = x0 * x + (REAL)5.0e-1;
		if (x >= (REAL)1.0e1 * x0) {
			x = x * (REAL)1.0000000149011612e-1;
			e += 1;
		}
		Reals_Convert(x, n, (void*)d, 9);
		n -= 1;
		Texts_Write(&*W, W__typ, d[__X_AT(n, 9, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 662, 26, 22256)]);
		Texts_Write(&*W, W__typ, '.');
		do {
			n -= 1;
			Texts_Write(&*W, W__typ, d[__X_AT(n, 9, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 663, 33, 22308)]);
		} while (!(n == 0));
		Texts_Write(&*W, W__typ, 'E');
		if (e < 0) {
			Texts_Write(&*W, W__typ, '-');
			e = -e;
		} else {
			Texts_Write(&*W, W__typ, '+');
		}
		Texts_Write(&*W, W__typ, __CHR(__DIV(e, 10) + 48));
		Texts_Write(&*W, W__typ, __CHR((int)__MOD(e, 10) + 48));
	}
}

static struct WriteRealFix__56 {
	Texts_Writer *W;
	ADDRESS *W__typ;
	INT16 *i;
	CHAR (*d)[9];
	struct WriteRealFix__56 *lnk;
} *WriteRealFix__56_s;

static void dig__57 (INT16 n);
static void seq__59 (CHAR ch, INT16 n);

static void seq__59 (CHAR ch, INT16 n)
{
	while (n > 0) {
		Texts_Write(&*WriteRealFix__56_s->W, WriteRealFix__56_s->W__typ, ch);
		n -= 1;
	}
}

static void dig__57 (INT16 n)
{
	while (n > 0) {
		*WriteRealFix__56_s->i -= 1;
		Texts_Write(&*WriteRealFix__56_s->W, WriteRealFix__56_s->W__typ, (*WriteRealFix__56_s->d)[__X_AT(*WriteRealFix__56_s->i, 9, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 681, 28, 22842)]);
		n -= 1;
	}
}

void Texts_WriteRealFix (Texts_Writer *W, ADDRESS *W__typ, REAL x, INT16 n, INT16 k)
{
	INT16 e, i;
	CHAR sign;
	REAL x0;
	CHAR d[9];
	struct WriteRealFix__56 _s;
	_s.W = W; _s.W__typ = W__typ;
	_s.i = &i;
	_s.d = (void*)d;
	_s.lnk = WriteRealFix__56_s;
	WriteRealFix__56_s = &_s;
	e = Reals_Expo(x);
	if (k < 0) {
		k = 0;
	}
	if (e == 0) {
		seq__59(' ', (n - k) - 2);
		Texts_Write(&*W, W__typ, '0');
		seq__59(' ', k + 1);
	} else if (e == 255) {
		Texts_WriteString(&*W, W__typ, (CHAR*)" NaN", 5);
		seq__59(' ', n - 4);
	} else {
		e = __ASHR((e - 127) * 77, 8);
		if (x < (REAL)0.0e0) {
			sign = '-';
			x = -x;
		} else {
			sign = ' ';
		}
		if (e >= 0) {
			x = x / (REAL)Reals_Ten(e);
		} else {
			x = Reals_Ten(-e) * x;
		}
		if (x >= (REAL)1.0e1) {
			x = (REAL)1.0000000149011612e-1 * x;
			e += 1;
		}
		if (k + e >= 8) {
			k = 8 - e;
		} else if (k + e < 0) {
			k = -e;
			x = (REAL)0.0e0;
		}
		x0 = Reals_Ten(k + e);
		x = x0 * x + (REAL)5.0e-1;
		if (x >= (REAL)1.0e1 * x0) {
			e += 1;
		}
		e += 1;
		i = k + e;
		Reals_Convert(x, i, (void*)d, 9);
		if (e > 0) {
			seq__59(' ', ((n - e) - k) - 2);
			Texts_Write(&*W, W__typ, sign);
			dig__57(e);
			Texts_Write(&*W, W__typ, '.');
			dig__57(k);
		} else {
			seq__59(' ', (n - k) - 3);
			Texts_Write(&*W, W__typ, sign);
			Texts_Write(&*W, W__typ, '0');
			Texts_Write(&*W, W__typ, '.');
			seq__59('0', -e);
			dig__57(k + e);
		}
	}
	WriteRealFix__56_s = _s.lnk;
}

void Texts_WriteRealHex (Texts_Writer *W, ADDRESS *W__typ, REAL x)
{
	INT16 i;
	CHAR d[8];
	Reals_ConvertH(x, (void*)d, 8);
	i = 0;
	do {
		Texts_Write(&*W, W__typ, d[__X_AT(i, 8, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 717, 23, 24055)]);
		i += 1;
	} while (!(i == 8));
}

void Texts_WriteLongReal (Texts_Writer *W, ADDRESS *W__typ, LONGREAL x, INT16 n)
{
	INT16 e;
	LONGREAL x0;
	CHAR d[16];
	e = Reals_ExpoL(x);
	if (e == 0) {
		Texts_WriteString(&*W, W__typ, (CHAR*)"  0", 4);
		do {
			Texts_Write(&*W, W__typ, ' ');
			n -= 1;
		} while (!(n <= 3));
	} else if (e == 2047) {
		Texts_WriteString(&*W, W__typ, (CHAR*)" NaN", 5);
		while (n > 4) {
			Texts_Write(&*W, W__typ, ' ');
			n -= 1;
		}
	} else {
		if (n <= 10) {
			n = 3;
		} else {
			n -= 7;
		}
		do {
			Texts_Write(&*W, W__typ, ' ');
			n -= 1;
		} while (!(n <= 16));
		if (x < (LONGREAL)0.0e0) {
			Texts_Write(&*W, W__typ, '-');
			x = -x;
		} else {
			Texts_Write(&*W, W__typ, ' ');
		}
		e = __SHORT(__ASHR((e - 1023) * 77, 8), 32768);
		if (e >= 0) {
			x = x / (LONGREAL)Reals_TenL(e);
		} else {
			x = Reals_TenL(-e) * x;
		}
		if (x >= (LONGREAL)1.0e1) {
			x = (LONGREAL)1.0000000000000001e-1 * x;
			e += 1;
		}
		x0 = Reals_TenL(n - 1);
		x = x0 * x + (LONGREAL)5.0e-1;
		if (x >= (LONGREAL)1.0e1 * x0) {
			x = (LONGREAL)1.0000000000000001e-1 * x;
			e += 1;
		}
		Reals_ConvertL(x, n, (void*)d, 16);
		n -= 1;
		Texts_Write(&*W, W__typ, d[__X_AT(n, 16, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 749, 26, 25215)]);
		Texts_Write(&*W, W__typ, '.');
		do {
			n -= 1;
			Texts_Write(&*W, W__typ, d[__X_AT(n, 16, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 750, 33, 25267)]);
		} while (!(n == 0));
		Texts_Write(&*W, W__typ, 'D');
		if (e < 0) {
			Texts_Write(&*W, W__typ, '-');
			e = -e;
		} else {
			Texts_Write(&*W, W__typ, '+');
		}
		Texts_Write(&*W, W__typ, __CHR(__DIV(e, 100) + 48));
		e = (int)__MOD(e, 100);
		Texts_Write(&*W, W__typ, __CHR(__DIV(e, 10) + 48));
		Texts_Write(&*W, W__typ, __CHR((int)__MOD(e, 10) + 48));
	}
}

void Texts_WriteLongRealHex (Texts_Writer *W, ADDRESS *W__typ, LONGREAL x)
{
	INT16 i;
	CHAR d[16];
	Reals_ConvertHL(x, (void*)d, 16);
	i = 0;
	do {
		Texts_Write(&*W, W__typ, d[__X_AT(i, 16, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 764, 23, 25698)]);
		i += 1;
	} while (!(i == 16));
}

static struct WriteDate__46 {
	Texts_Writer *W;
	ADDRESS *W__typ;
	struct WriteDate__46 *lnk;
} *WriteDate__46_s;

static void WritePair__47 (CHAR ch, INT32 x);

static void WritePair__47 (CHAR ch, INT32 x)
{
	Texts_Write(&*WriteDate__46_s->W, WriteDate__46_s->W__typ, ch);
	Texts_Write(&*WriteDate__46_s->W, WriteDate__46_s->W__typ, __CHR(__DIV(x, 10) + 48));
	Texts_Write(&*WriteDate__46_s->W, WriteDate__46_s->W__typ, __CHR((int)__MOD(x, 10) + 48));
}

void Texts_WriteDate (Texts_Writer *W, ADDRESS *W__typ, INT32 t, INT32 d)
{
	struct WriteDate__46 _s;
	_s.W = W; _s.W__typ = W__typ;
	_s.lnk = WriteDate__46_s;
	WriteDate__46_s = &_s;
	WritePair__47(' ', __MASK(d, -32));
	WritePair__47('.', __MASK(__ASHR(d, 5), -16));
	WritePair__47('.', __MASK(__ASHR(d, 9), -128));
	WritePair__47(' ', __MASK(__ASHR(t, 12), -32));
	WritePair__47(':', __MASK(__ASHR(t, 6), -64));
	WritePair__47(':', __MASK(t, -64));
	WriteDate__46_s = _s.lnk;
}

static struct Load0__16 {
	Texts_Text *T;
	INT8 *ecnt;
	Files_File *f;
	Texts_FileMsg *msg;
	CHAR (*mods)[64][32], (*procs)[64][32];
	struct Load0__16 *lnk;
} *Load0__16_s;

static void LoadElem__17 (Files_Rider *r, ADDRESS *r__typ, INT32 pos, INT32 span, Texts_Elem *e);

static void LoadElem__17 (Files_Rider *r, ADDRESS *r__typ, INT32 pos, INT32 span, Texts_Elem *e)
{
	Heap_Module M = NIL;
	Heap_Command Cmd;
	Texts_Alien a = NIL;
	INT32 org, ew, eh;
	INT8 eno;
	Texts_new = NIL;
	Files_ReadLInt(&*r, r__typ, &ew);
	Files_ReadLInt(&*r, r__typ, &eh);
	Files_Read(&*r, r__typ, (void*)&eno);
	if (eno > *Load0__16_s->ecnt) {
		*Load0__16_s->ecnt = eno;
		Files_ReadString(&*r, r__typ, (void*)(*Load0__16_s->mods)[__X_AT(eno, 64, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 797, 64, 26881)], 32);
		Files_ReadString(&*r, r__typ, (void*)(*Load0__16_s->procs)[__X_AT(eno, 64, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 797, 97, 26914)], 32);
	}
	org = Files_Pos(&*r, r__typ);
	M = Modules_ThisMod((*Load0__16_s->mods)[__X_AT(eno, 64, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 798, 54, 26978)], 32);
	if (M != NIL) {
		Cmd = Modules_ThisCommand(M, (*Load0__16_s->procs)[__X_AT(eno, 64, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 799, 59, 27043)], 32);
		if (Cmd != NIL) {
			((Heap_Command)__NIL_AT((ADDRESS)(Cmd), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 800, 27, 27076))();
		}
	}
	*e = Texts_new;
	if (*e != NIL) {
		((Texts_Elem)__NIL_AT((ADDRESS)(*e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 803, 24, 27134))->W = ew;
		((Texts_Elem)__NIL_AT((ADDRESS)(*e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 803, 35, 27145))->H = eh;
		((Texts_Elem)__NIL_AT((ADDRESS)(*e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 803, 46, 27156))->base = *Load0__16_s->T;
		(*Load0__16_s->msg).pos = pos;
		((Texts_Handler)__NIL_AT((ADDRESS)(((Texts_Elem)__NIL_AT((ADDRESS)(*e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 804, 26, 27193))->handle), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 804, 26, 27193))(*e, (void*)&*Load0__16_s->msg, Texts_FileMsg__typ);
		if (Files_Pos(&*r, r__typ) != org + span) {
			*e = NIL;
		}
	}
	if (*e == NIL) {
		Files_Set(&*r, r__typ, *Load0__16_s->f, org + span);
		__NEW(a, Texts__1);
		((Texts_Alien)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 808, 18, 27344))->W = ew;
		((Texts_Alien)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 808, 29, 27355))->H = eh;
		((Texts_Alien)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 808, 40, 27366))->handle = Texts_HandleAlien;
		((Texts_Alien)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 808, 65, 27391))->base = *Load0__16_s->T;
		((Texts_Alien)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 809, 10, 27412))->file = *Load0__16_s->f;
		((Texts_Alien)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 809, 23, 27425))->org = org;
		((Texts_Alien)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 809, 37, 27439))->span = span;
		__COPY((*Load0__16_s->mods)[__X_AT(eno, 64, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 810, 19, 27472)], ((Texts_Alien)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 810, 26, 27479))->mod, 32);
		__COPY((*Load0__16_s->procs)[__X_AT(eno, 64, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 810, 44, 27497)], ((Texts_Alien)__NIL_AT((ADDRESS)(a), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 810, 51, 27504))->proc, 32);
		*e = (Texts_Elem)a;
	}
}

static void Texts_Load0 (Files_Rider *r, ADDRESS *r__typ, Texts_Text T)
{
	Texts_Run u = NIL, un = NIL;
	Texts_Piece p = NIL;
	Texts_Elem e = NIL;
	INT32 org, pos, hlen, plen;
	INT8 ecnt, fcnt, fno, col, voff;
	Files_File f = NIL;
	Texts_FileMsg msg;
	CHAR mods[64][32], procs[64][32];
	CHAR name[32];
	Texts_FontsFont fnts[32];
	struct Load0__16 _s;
	_s.T = &T;
	_s.ecnt = &ecnt;
	_s.f = &f;
	_s.msg = &msg;
	_s.mods = (void*)mods;
	_s.procs = (void*)procs;
	_s.lnk = Load0__16_s;
	Load0__16_s = &_s;
	pos = Files_Pos(&*r, r__typ);
	f = Files_Base(&*r, r__typ);
	__NEW(u, Texts_RunDesc);
	((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 816, 14, 27618))->len = 2147483647;
	((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 816, 63, 27667))->fnt = NIL;
	((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 816, 77, 27681))->col = 15;
	((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 817, 6, 27708))->head = u;
	ecnt = 0;
	fcnt = 0;
	msg.id = 0;
	msg.r = *r;
	Files_ReadLInt(&msg.r, Files_Rider__typ, &hlen);
	org = (pos - 2) + hlen;
	pos = org;
	Files_Read(&msg.r, Files_Rider__typ, (void*)&fno);
	while (fno != 0) {
		if (fno > fcnt) {
			fcnt = fno;
			Files_ReadString(&msg.r, Files_Rider__typ, (void*)name, 32);
			fnts[__X_AT(fno, 32, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 821, 75, 27986)] = Texts_FontsThis((void*)name, 32);
		}
		Files_Read(&msg.r, Files_Rider__typ, (void*)&col);
		Files_Read(&msg.r, Files_Rider__typ, (void*)&voff);
		Files_ReadLInt(&msg.r, Files_Rider__typ, &plen);
		if (plen > 0) {
			__NEW(p, Texts_PieceDesc);
			((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 823, 33, 28131))->file = f;
			((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 823, 46, 28144))->org = pos;
			((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 823, 60, 28158))->ascii = 0;
			un = (Texts_Run)p;
			((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 823, 88, 28186))->len = plen;
		} else {
			LoadElem__17(&msg.r, Files_Rider__typ, pos - org, -plen, &e);
			un = (Texts_Run)e;
			((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 824, 61, 28259))->len = 1;
		}
		((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 826, 34, 28313))->col = col;
		((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 826, 49, 28328))->voff = voff;
		pos += ((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 827, 18, 28360))->len;
		((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 827, 26, 28368))->next = un;
		((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 827, 41, 28383))->prev = u;
		u = un;
		Files_Read(&msg.r, Files_Rider__typ, (void*)&fno);
	}
	((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 829, 6, 28441))->next = ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 829, 16, 28451))->head;
	((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 829, 24, 28459))->head), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 829, 29, 28464))->prev = u;
	((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 829, 42, 28477))->cache = ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 829, 53, 28488))->head;
	((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 829, 61, 28496))->corg = 0;
	Files_ReadLInt(&msg.r, Files_Rider__typ, &((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 830, 28, 28535))->len);
	Files_Set(&*r, r__typ, f, Files_Pos(&msg.r, Files_Rider__typ) + ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 830, 71, 28578))->len);
	Load0__16_s = _s.lnk;
}

void Texts_Load (Files_Rider *r, ADDRESS *r__typ, Texts_Text T)
{
	INT16 tag;
	Platform_CommandCritical(1);
	Files_ReadInt(&*r, r__typ, &tag);
	if (tag != -4095) {
		Files_Set(&*r, r__typ, Files_Base(&*r, r__typ), Files_Pos(&*r, r__typ) - 2);
	}
	Texts_Load0(&*r, r__typ, T);
	Platform_CommandCritical(0);
}

void Texts_Open (Texts_Text T, CHAR *name, ADDRESS name__len)
{
	Files_File f = NIL;
	Files_Rider r;
	Texts_Run u = NIL;
	Texts_Piece p = NIL;
	CHAR tag, version;
	INT32 hlen;
	__DUP(name, name__len, CHAR);
	Platform_CommandCritical(1);
	f = Files_Old(name, name__len);
	if (f == NIL) {
		f = Files_New((CHAR*)"", 1);
	}
	Files_Set(&r, Files_Rider__typ, f, 0);
	Files_Read(&r, Files_Rider__typ, (void*)&tag);
	Files_Read(&r, Files_Rider__typ, (void*)&version);
	if (tag == 0xf0 || (tag == 0x01 && version == 0xf0)) {
		Texts_Load0(&r, Files_Rider__typ, T);
	} else {
		__NEW(u, Texts_RunDesc);
		((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 851, 16, 29429))->len = 2147483647;
		((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 851, 39, 29452))->fnt = NIL;
		((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 851, 53, 29466))->col = 15;
		__NEW(p, Texts_PieceDesc);
		if ((tag == 0xf7 && version == 0x07)) {
			Files_Set(&r, Files_Rider__typ, f, 28);
			Files_ReadLInt(&r, Files_Rider__typ, &hlen);
			Files_Set(&r, Files_Rider__typ, f, 22 + hlen);
			Files_ReadLInt(&r, Files_Rider__typ, &((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 855, 56, 29715))->len);
			((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 855, 64, 29723))->org = 26 + hlen;
		} else {
			((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 857, 10, 29761))->len = Files_Length(f);
			((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 857, 36, 29787))->org = 0;
		}
		if (((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 859, 11, 29819))->len > 0) {
			((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 859, 26, 29834))->len = ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 859, 35, 29843))->len;
			((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 859, 42, 29850))->fnt = Texts_FontsDefault;
			((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 860, 10, 29881))->col = 15;
			((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 860, 33, 29904))->voff = 0;
			((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 860, 46, 29917))->file = f;
			((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 860, 59, 29930))->ascii = 1;
			((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 861, 10, 29955))->next = (Texts_Run)p;
			((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 861, 23, 29968))->prev = (Texts_Run)p;
			((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 861, 36, 29981))->next = u;
			((Texts_Piece)__NIL_AT((ADDRESS)(p), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 861, 49, 29994))->prev = u;
		} else {
			((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 862, 13, 30017))->next = u;
			((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 862, 26, 30030))->prev = u;
		}
		((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 864, 8, 30059))->head = u;
		((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 864, 21, 30072))->cache = ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 864, 32, 30083))->head;
		((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 864, 40, 30091))->corg = 0;
	}
	Platform_CommandCritical(0);
	__DEL(name);
}

static struct Store__42 {
	INT8 *ecnt;
	Texts_FileMsg *msg;
	Texts_IdentifyMsg *iden;
	CHAR (*mods)[64][32], (*procs)[64][32];
	struct Store__42 *lnk;
} *Store__42_s;

static void StoreElem__43 (Files_Rider *r, ADDRESS *r__typ, INT32 pos, Texts_Elem e);

static void StoreElem__43 (Files_Rider *r, ADDRESS *r__typ, INT32 pos, Texts_Elem e)
{
	Files_Rider r1;
	INT32 org, span;
	INT8 eno;
	__COPY((*Store__42_s->iden).mod, (*Store__42_s->mods)[__X_AT(*Store__42_s->ecnt, 64, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 879, 31, 30673)], 32);
	__COPY((*Store__42_s->iden).proc, (*Store__42_s->procs)[__X_AT(*Store__42_s->ecnt, 64, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 879, 61, 30703)], 32);
	eno = 1;
	while (__STRCMP((*Store__42_s->mods)[__X_AT(eno, 64, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 880, 19, 30739)], (*Store__42_s->iden).mod) != 0 || __STRCMP((*Store__42_s->procs)[__X_AT(eno, 64, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 880, 46, 30766)], (*Store__42_s->iden).proc) != 0) {
		eno += 1;
	}
	Files_Set(&r1, Files_Rider__typ, Files_Base(&*r, r__typ), Files_Pos(&*r, r__typ));
	Files_WriteLInt(&*r, r__typ, 0);
	Files_WriteLInt(&*r, r__typ, 0);
	Files_WriteLInt(&*r, r__typ, 0);
	Files_Write(&*r, r__typ, eno);
	if (eno == *Store__42_s->ecnt) {
		*Store__42_s->ecnt += 1;
		Files_WriteString(&*r, r__typ, (*Store__42_s->iden).mod, 32);
		Files_WriteString(&*r, r__typ, (*Store__42_s->iden).proc, 32);
	}
	(*Store__42_s->msg).pos = pos;
	org = Files_Pos(&*r, r__typ);
	((Texts_Handler)__NIL_AT((ADDRESS)(((Texts_Elem)__NIL_AT((ADDRESS)(e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 885, 45, 31117))->handle), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 885, 45, 31117))(e, (void*)&*Store__42_s->msg, Texts_FileMsg__typ);
	span = Files_Pos(&*r, r__typ) - org;
	Files_WriteLInt(&r1, Files_Rider__typ, -span);
	Files_WriteLInt(&r1, Files_Rider__typ, ((Texts_Elem)__NIL_AT((ADDRESS)(e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 886, 56, 31217))->W);
	Files_WriteLInt(&r1, Files_Rider__typ, ((Texts_Elem)__NIL_AT((ADDRESS)(e), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 886, 82, 31243))->H);
}

void Texts_Store (Files_Rider *r, ADDRESS *r__typ, Texts_Text T)
{
	Files_Rider r1;
	Texts_Run u = NIL, un = NIL;
	Texts_Elem e = NIL;
	INT32 org, pos, delta, hlen, rlen;
	INT8 ecnt, fcnt;
	CHAR ch;
	INT8 fno;
	Texts_FileMsg msg;
	Texts_IdentifyMsg iden;
	CHAR mods[64][32], procs[64][32];
	Texts_FontsFont fnts[32];
	CHAR block[1024];
	struct Store__42 _s;
	_s.ecnt = &ecnt;
	_s.msg = &msg;
	_s.iden = &iden;
	_s.mods = (void*)mods;
	_s.procs = (void*)procs;
	_s.lnk = Store__42_s;
	Store__42_s = &_s;
	org = Files_Pos(&*r, r__typ);
	msg.id = 1;
	msg.r = *r;
	Files_WriteLInt(&msg.r, Files_Rider__typ, 0);
	u = ((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 891, 11, 31391))->head), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 891, 16, 31396))->next;
	pos = 0;
	delta = 0;
	fcnt = 1;
	ecnt = 1;
	while (u != ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 892, 16, 31462))->head) {
		if (__ISP(u, Texts_ElemDesc, 1)) {
			iden.mod[0] = 0x00;
			((Texts_Handler)__NIL_AT((ADDRESS)(((Texts_Elem)__NIL_AT((ADDRESS)(__GUARDPN_AT(u, Texts_ElemDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 893, 45, 31515)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 893, 51, 31521))->handle), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 893, 51, 31521))(__GUARDPN_AT(u, Texts_ElemDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 893, 60, 31530), (void*)&iden, Texts_IdentifyMsg__typ);
		} else {
			iden.mod[0] = 0x01;
		}
		if (iden.mod[0] != 0x00) {
			fnts[__X_AT(fcnt, 32, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 895, 14, 31616)] = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 895, 24, 31626))->fnt;
			fno = 1;
			while (__STRCMP(((Texts_FontsFont)__NIL_AT((ADDRESS)(fnts[__X_AT(fno, 32, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 896, 20, 31661)]), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 896, 24, 31665))->name, ((Texts_FontsFont)__NIL_AT((ADDRESS)(((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 896, 33, 31674))->fnt), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 896, 37, 31678))->name) != 0) {
				fno += 1;
			}
			Files_Write(&msg.r, Files_Rider__typ, fno);
			if (fno == fcnt) {
				fcnt += 1;
				Files_WriteString(&msg.r, Files_Rider__typ, ((Texts_FontsFont)__NIL_AT((ADDRESS)(((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 898, 65, 31798))->fnt), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 898, 69, 31802))->name, 32);
			}
			Files_Write(&msg.r, Files_Rider__typ, ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 899, 29, 31842))->col);
			Files_Write(&msg.r, Files_Rider__typ, ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 899, 56, 31869))->voff);
		}
		if (__ISP(u, Texts_PieceDesc, 1)) {
			rlen = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 901, 35, 31921))->len;
			un = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 901, 48, 31934))->next;
			while ((((((__ISP(un, Texts_PieceDesc, 1) && ((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 902, 34, 31974))->fnt == ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 902, 42, 31982))->fnt)) && ((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 902, 53, 31993))->col == ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 902, 61, 32001))->col)) && ((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 902, 72, 32012))->voff == ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 902, 81, 32021))->voff)) {
				rlen += ((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 903, 23, 32053))->len;
				un = ((Texts_Run)__NIL_AT((ADDRESS)(un), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 903, 38, 32068))->next;
			}
			Files_WriteLInt(&msg.r, Files_Rider__typ, rlen);
			pos += rlen;
			u = un;
		} else if (iden.mod[0] != 0x00) {
			StoreElem__43(&msg.r, Files_Rider__typ, pos, __GUARDPN_AT(u, Texts_ElemDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 906, 58, 32206));
			pos += 1;
			u = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 906, 83, 32231))->next;
		} else {
			delta += 1;
			u = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 907, 30, 32266))->next;
		}
	}
	Files_Write(&msg.r, Files_Rider__typ, 0);
	Files_WriteLInt(&msg.r, Files_Rider__typ, ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 910, 52, 32342))->len - delta);
	hlen = (Files_Pos(&msg.r, Files_Rider__typ) - org) + 2;
	Files_Set(&r1, Files_Rider__typ, Files_Base(&msg.r, Files_Rider__typ), org);
	Files_WriteLInt(&r1, Files_Rider__typ, hlen);
	u = ((Texts_Run)__NIL_AT((ADDRESS)(((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 913, 11, 32526))->head), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 913, 16, 32531))->next;
	while (u != ((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 914, 16, 32553))->head) {
		if (__ISP(u, Texts_PieceDesc, 1)) {
			if (__ISP(u, Texts_PieceDesc, 1)) {
				if (((Texts_Piece)__NIL_AT((ADDRESS)((*(Texts_Piece*)&u)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 917, 15, 32626))->ascii) {
					Files_Set(&r1, Files_Rider__typ, ((Texts_Piece)__NIL_AT((ADDRESS)((*(Texts_Piece*)&u)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 917, 42, 32653))->file, ((Texts_Piece)__NIL_AT((ADDRESS)((*(Texts_Piece*)&u)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 917, 50, 32661))->org);
					delta = ((Texts_Piece)__NIL_AT((ADDRESS)((*(Texts_Piece*)&u)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 917, 67, 32678))->len;
					while (delta > 0) {
						Files_Read(&r1, Files_Rider__typ, (void*)&ch);
						delta -= 1;
						if (ch == 0x0a) {
							Files_Write(&msg.r, Files_Rider__typ, 0x0d);
						} else {
							Files_Write(&msg.r, Files_Rider__typ, ch);
						}
					}
				} else {
					Files_Set(&r1, Files_Rider__typ, ((Texts_Piece)__NIL_AT((ADDRESS)((*(Texts_Piece*)&u)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 921, 31, 32898))->file, ((Texts_Piece)__NIL_AT((ADDRESS)((*(Texts_Piece*)&u)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 921, 39, 32906))->org);
					delta = ((Texts_Piece)__NIL_AT((ADDRESS)((*(Texts_Piece*)&u)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 921, 56, 32923))->len;
					while (delta > 1024) {
						Files_ReadBytes(&r1, Files_Rider__typ, (void*)block, 1024, 1024);
						Files_WriteBytes(&msg.r, Files_Rider__typ, (void*)block, 1024, 1024);
						delta -= 1024;
					}
					Files_ReadBytes(&r1, Files_Rider__typ, (void*)block, 1024, delta);
					Files_WriteBytes(&msg.r, Files_Rider__typ, (void*)block, 1024, delta);
				}
			} else __WITHCHK;
		} else {
			iden.mod[0] = 0x00;
			((Texts_Handler)__NIL_AT((ADDRESS)(((Texts_Elem)__NIL_AT((ADDRESS)(__GUARDPN_AT(u, Texts_ElemDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 928, 32, 33249)), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 928, 38, 33255))->handle), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 928, 38, 33255))(__GUARDPN_AT(u, Texts_ElemDesc, 1, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 928, 47, 33264), (void*)&iden, Texts_IdentifyMsg__typ);
			if (iden.mod[0] != 0x00) {
				Files_Write(&msg.r, Files_Rider__typ, 0x1c);
			}
		}
		u = ((Texts_Run)__NIL_AT((ADDRESS)(u), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 931, 13, 33368))->next;
	}
	__GUARDEQR(r, r__typ, Files_Rider) = msg.r;
	if (((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 934, 9, 33407))->notify != NIL) {
		((Texts_Notifier)__NIL_AT((ADDRESS)(((Texts_Text)__NIL_AT((ADDRESS)(T), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 934, 29, 33427))->notify), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 934, 29, 33427))(T, 3, 0, 0);
	}
	Store__42_s = _s.lnk;
}

void Texts_Close (Texts_Text T, CHAR *name, ADDRESS name__len)
{
	Files_File f = NIL;
	Files_Rider r;
	INT16 i, res;
	CHAR bak[64];
	__DUP(name, name__len, CHAR);
	f = Files_New(name, name__len);
	Files_Set(&r, Files_Rider__typ, f, 0);
	Files_Write(&r, Files_Rider__typ, 0xf0);
	Files_Write(&r, Files_Rider__typ, 0x01);
	Texts_Store(&r, Files_Rider__typ, T);
	i = 0;
	while (name[__X_AT(i, name__len, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 941, 24, 33740)] != 0x00) {
		i += 1;
	}
	__COPY(name, bak, 64);
	bak[__X_AT(i, 64, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 942, 26, 33788)] = '.';
	bak[__X_AT(i + 1, 64, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 942, 41, 33803)] = 'B';
	bak[__X_AT(i + 2, 64, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 942, 58, 33820)] = 'a';
	bak[__X_AT(i + 3, 64, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 942, 75, 33837)] = 'k';
	bak[__X_AT(i + 4, 64, (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 942, 92, 33854)] = 0x00;
	Files_Rename(name, name__len, bak, 64, &res);
	Files_Register(f);
	__DEL(name);
}

static void EnumPtrs(void (*P)(void*))
{
	P(Texts_new);
	P(Texts_del);
	P(Texts_FontsDefault);
}

__TDESC(Texts_FontDesc, 1, 0) = {__TDFLDS("FontDesc", 32), {-8}};
__TDESC(Texts_RunDesc, 1, 3) = {__TDFLDS("RunDesc", 40), {0, 8, 24, -32}};
__TDESC(Texts_PieceDesc, 1, 4) = {__TDFLDS("PieceDesc", 56), {0, 8, 24, 40, -40}};
__TDESC(Texts_ElemMsg, 1, 0) = {__TDFLDS("ElemMsg", 1), {-8}};
__TDESC(Texts_ElemDesc, 1, 4) = {__TDFLDS("ElemDesc", 64), {0, 8, 24, 56, -40}};
__TDESC(Texts_FileMsg, 1, 1) = {__TDFLDS("FileMsg", 32), {16, -16}};
__TDESC(Texts_CopyMsg, 1, 1) = {__TDFLDS("CopyMsg", 8), {0, -16}};
__TDESC(Texts_IdentifyMsg, 1, 0) = {__TDFLDS("IdentifyMsg", 64), {-8}};
__TDESC(Texts_BufDesc, 1, 1) = {__TDFLDS("BufDesc", 16), {8, -16}};
__TDESC(Texts_TextDesc, 1, 2) = {__TDFLDS("TextDesc", 40), {16, 24, -24}};
__TDESC(Texts_Reader, 1, 4) = {__TDFLDS("Reader", 72), {8, 24, 40, 56, -40}};
__TDESC(Texts_Scanner, 1, 4) = {__TDFLDS("Scanner", 168), {8, 24, 40, 56, -40}};
__TDESC(Texts_Writer, 1, 4) = {__TDFLDS("Writer", 56), {0, 8, 32, 48, -40}};
__TDESC(Texts__1, 1, 5) = {__TDFLDS("", 144), {0, 8, 24, 56, 64, -48}};

export void *Texts__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(Files);
	__MODULE_IMPORT(Modules);
	__MODULE_IMPORT(Platform);
	__MODULE_IMPORT(Reals);
	__REGMOD("Texts", EnumPtrs);
	__INITYP(Texts_FontDesc, Texts_FontDesc, 0);
	__INITYP(Texts_RunDesc, Texts_RunDesc, 0);
	__INITYP(Texts_PieceDesc, Texts_RunDesc, 1);
	__INITYP(Texts_ElemMsg, Texts_ElemMsg, 0);
	__INITYP(Texts_ElemDesc, Texts_RunDesc, 1);
	__INITYP(Texts_FileMsg, Texts_ElemMsg, 1);
	__INITYP(Texts_CopyMsg, Texts_ElemMsg, 1);
	__INITYP(Texts_IdentifyMsg, Texts_ElemMsg, 1);
	__INITYP(Texts_BufDesc, Texts_BufDesc, 0);
	__INITYP(Texts_TextDesc, Texts_TextDesc, 0);
	__INITYP(Texts_Reader, Texts_Reader, 0);
	__INITYP(Texts_Scanner, Texts_Reader, 1);
	__INITYP(Texts_Writer, Texts_Writer, 0);
	__INITYP(Texts__1, Texts_ElemDesc, 2);
/* BEGIN */
	Texts_del = NIL;
	__NEW(Texts_FontsDefault, Texts_FontDesc);
	__MOVE("Syntax10.Scn.Fnt", ((Texts_FontsFont)__NIL_AT((ADDRESS)(Texts_FontsDefault), (CHAR*)"../../src/runtime/Texts.Mod", 28, (CHAR*)"Texts", 6, 946, 50, 33981))->name, 17);
	__ENDMOD;
}
