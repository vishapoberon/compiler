/* J. Templ 23.6.95
this program tests and outputs important characteristics of
the C compiler and SYSTEM.h file used to compile it.
The output of this program is accepted by voc as file voc.par. 
% cc vocparam.c; a.out > voc.par
*/


#include "SYSTEM.h"
#include "stdio.h"

struct {CHAR ch; CHAR x;} c;
struct {CHAR ch; BOOLEAN x;} b;
struct {CHAR ch; SHORTINT x;} si;
struct {CHAR ch; INTEGER x;} i;
struct {CHAR ch; LONGINT x;} li;
struct {CHAR ch; SET x;} s;
struct {CHAR ch; REAL x;} r;
struct {CHAR ch; LONGREAL x;} lr;
struct {CHAR ch; void *x;} p;
struct {CHAR ch; void (*x)();} f;
struct {CHAR ch;} rec0;
struct {CHAR ch; LONGREAL x;} rec1;
struct {char x[65];} rec2;

void main()
{
	long x, y;
	/* get size and alignment of standard types */
	printf("CHAR %d %d\n", sizeof(CHAR), (char*)&c.x - (char*)&c);
	printf("BOOLEAN %d %d\n", sizeof(BOOLEAN), (char*)&b.x - (char*)&b);
	printf("SHORTINT %d %d\n", sizeof(SHORTINT), (char*)&si.x - (char*)&si);
	printf("INTEGER %d %d\n", sizeof(INTEGER), (char*)&i.x - (char*)&i);
	printf("LONGINT %d %d\n", sizeof(LONGINT), (char*)&li.x - (char*)&li);
	printf("SET %d %d\n", sizeof(SET), (char*)&s.x - (char*)&s);
	printf("REAL %d %d\n", sizeof(REAL), (char*)&r.x - (char*)&r);
	printf("LONGREAL %d %d\n", sizeof(LONGREAL), (char*)&lr.x - (char*)&lr);
	printf("PTR %d %d\n", sizeof p.x, (char*)&p.x - (char*)&p);
	printf("PROC %d %d\n", sizeof f.x, (char*)&f.x - (char*)&f);
	printf("RECORD %d %d\n", (sizeof rec2 == 65) == (sizeof rec0 == 1), sizeof rec2 - 64);
	x = 1;
	printf("ENDIAN %d %d\n", *(char*)&x, 0);

	if (sizeof(CHAR)!=1) printf("error: CHAR should have size 1\n");
	if (sizeof(BOOLEAN)!=1) printf("error: BOOLEAN should have size 1\n");
	if (sizeof(SHORTINT)!=1) printf("error: SHORTINT should have size 1\n");
	if (sizeof(long)!=sizeof p.x) printf("error: LONGINT should have the same size as pointers\n");
	if (sizeof(long)!=sizeof f.x) printf("error: LONGINT should have the same size as function pointers\n");
	if (((sizeof rec2 == 65) == (sizeof rec0 == 1)) && ((sizeof rec2 - 64) != sizeof rec0))
		printf("error: unsupported record layout  sizeof rec0 = %d  sizeof rec2 = %d\n", sizeof rec0, sizeof rec2);

	/* test the __ASHR macro */
	if (__ASHR(-1, 1) != -1) printf("error: ASH(-1, -1) # -1\n");
	if (__ASHR(-2, 1) != -1) printf("error: ASH(-2, -1) # -1\n");
	if (__ASHR(0, 1) != 0) printf("error: ASH(0, 1) #  0\n");
	if (__ASHR(1, 1) != 0) printf("error: ASH(1, 1) #  0\n");
	if (__ASHR(2, 1) != 1) printf("error: ASH(2, 1) #  1\n");

	/* test the __SETRNG macro */
	x = 0; y = sizeof(SET)*8 - 1;
	if (__SETRNG(x, y) != -1) printf("error: SETRNG(0, MAX(SET)) != -1\n");

	/* test string comparison for extended ascii */
	{char a[10], b[10];
		a[0] = (CHAR)128; a[1] = 0;
		b[0] = 0;
		if (__STRCMP(a, b) < 0) printf("error: __STRCMP(a, b)  with extended ascii charcters; should be unsigned\n");
	}
}
