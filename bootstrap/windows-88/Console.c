/* voc 1.95 [2016/09/30]. Bootstrapping compiler for address size 8, alignment 8. xtspaSfF */

#define SHORTINT int8
#define INTEGER  int16
#define LONGINT  int32
#define SET      uint32

#include "SYSTEM.h"
#include "Platform.h"


static CHAR Console_line[128];
static int16 Console_pos;


export void Console_Bool (BOOLEAN b);
export void Console_Char (CHAR ch);
export void Console_Flush (void);
export void Console_Hex (int32 i);
export void Console_Int (int64 i, int64 n);
export void Console_Ln (void);
export void Console_Read (CHAR *ch);
export void Console_ReadLine (CHAR *line, LONGINT line__len);
export void Console_String (CHAR *s, LONGINT s__len);


void Console_Flush (void)
{
	int16 error;
	error = Platform_Write(Platform_StdOut, (address)Console_line, Console_pos);
	Console_pos = 0;
}

void Console_Char (CHAR ch)
{
	if (Console_pos == 128) {
		Console_Flush();
	}
	Console_line[__X(Console_pos, 128)] = ch;
	Console_pos += 1;
	if (ch == 0x0a) {
		Console_Flush();
	}
}

void Console_String (CHAR *s, LONGINT s__len)
{
	int16 i;
	__DUP(s, s__len, CHAR);
	i = 0;
	while (s[__X(i, s__len)] != 0x00) {
		Console_Char(s[__X(i, s__len)]);
		i += 1;
	}
	__DEL(s);
}

void Console_Int (int64 i, int64 n)
{
	CHAR s[32];
	int32 i1, k;
	if (i == (int64)__LSHL(1, 31, 32)) {
		__MOVE("8463847412", s, 11);
		k = 10;
	} else {
		i1 = __ABS(__VAL(int32, i));
		s[0] = (CHAR)((int)__MOD(i1, 10) + 48);
		i1 = __DIV(i1, 10);
		k = 1;
		while (i1 > 0) {
			s[__X(k, 32)] = (CHAR)((int)__MOD(i1, 10) + 48);
			i1 = __DIV(i1, 10);
			k += 1;
		}
	}
	if (i < 0) {
		s[__X(k, 32)] = '-';
		k += 1;
	}
	while (n > (int64)k) {
		Console_Char(' ');
		n -= 1;
	}
	while (k > 0) {
		k -= 1;
		Console_Char(s[__X(k, 32)]);
	}
}

void Console_Ln (void)
{
	Console_Char(0x0a);
}

void Console_Bool (BOOLEAN b)
{
	if (b) {
		Console_String((CHAR*)"TRUE", 5);
	} else {
		Console_String((CHAR*)"FALSE", 6);
	}
}

void Console_Hex (int32 i)
{
	int16 k;
	int64 n;
	k = -28;
	while (k <= 0) {
		n = __MASK(__ASH(i, k), -16);
		if (n <= 9) {
			Console_Char((CHAR)(48 + n));
		} else {
			Console_Char((CHAR)(55 + n));
		}
		k += 4;
	}
}

void Console_Read (CHAR *ch)
{
	int32 n;
	int16 error;
	Console_Flush();
	error = Platform_ReadBuf(Platform_StdIn, (void*)&*ch, 1, &n);
	if (n != 1) {
		*ch = 0x00;
	}
}

void Console_ReadLine (CHAR *line, LONGINT line__len)
{
	int32 i;
	CHAR ch;
	Console_Flush();
	i = 0;
	Console_Read(&ch);
	while ((((i < line__len - 1 && ch != 0x0a)) && ch != 0x00)) {
		line[__X(i, line__len)] = ch;
		i += 1;
		Console_Read(&ch);
	}
	line[__X(i, line__len)] = 0x00;
}


export void *Console__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(Platform);
	__REGMOD("Console", 0);
	__REGCMD("Flush", Console_Flush);
	__REGCMD("Ln", Console_Ln);
/* BEGIN */
	Console_pos = 0;
	__ENDMOD;
}
