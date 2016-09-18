/* voc 1.95 [2016/09/18] for gcc LP64 on cygwin xtspkaSfF */

#define INTEGER int32
#define LONGINT int64
#define SET     uint64

#include "SYSTEM.h"
#include "Platform.h"


static CHAR Console_line[128];
static int32 Console_pos;


export void Console_Bool (BOOLEAN b);
export void Console_Char (CHAR ch);
export void Console_Flush (void);
export void Console_Hex (int64 i);
export void Console_Int (int64 i, int64 n);
export void Console_Ln (void);
export void Console_Read (CHAR *ch);
export void Console_ReadLine (CHAR *line, LONGINT line__len);
export void Console_String (CHAR *s, LONGINT s__len);


void Console_Flush (void)
{
	int32 error;
	error = Platform_Write(1, (address)Console_line, Console_pos);
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
	int32 i;
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
	int64 i1, k;
	if (i == __LSHL(1, 63, 64)) {
		__MOVE("8085774586302733229", s, 20);
		k = 19;
	} else {
		i1 = __ABS(i);
		s[0] = (CHAR)(__MOD(i1, 10) + 48);
		i1 = __DIV(i1, 10);
		k = 1;
		while (i1 > 0) {
			s[__X(k, 32)] = (CHAR)(__MOD(i1, 10) + 48);
			i1 = __DIV(i1, 10);
			k += 1;
		}
	}
	if (i < 0) {
		s[__X(k, 32)] = '-';
		k += 1;
	}
	while (n > k) {
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

void Console_Hex (int64 i)
{
	int32 k;
	int64 n;
	k = -60;
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
	int64 n;
	int32 error;
	Console_Flush();
	error = Platform_ReadBuf(0, (void*)&*ch, 1, &n);
	if (n != 1) {
		*ch = 0x00;
	}
}

void Console_ReadLine (CHAR *line, LONGINT line__len)
{
	int64 i;
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
