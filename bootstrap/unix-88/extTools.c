/* voc 1.95 [2016/09/12] for gcc LP64 on cygwin xtspkaSfF */

#define INTEGER int32
#define LONGINT int64
#define SET     uint64

#include "SYSTEM.h"
#include "Configuration.h"
#include "Console.h"
#include "OPM.h"
#include "Platform.h"
#include "Strings.h"


static CHAR extTools_compilationOptions[1023], extTools_CFLAGS[1023];


export void extTools_Assemble (CHAR *moduleName, LONGINT moduleName__len);
export void extTools_LinkMain (CHAR *moduleName, LONGINT moduleName__len, BOOLEAN statically, CHAR *additionalopts, LONGINT additionalopts__len);
static void extTools_execute (CHAR *title, LONGINT title__len, CHAR *cmd, LONGINT cmd__len);


static void extTools_execute (CHAR *title, LONGINT title__len, CHAR *cmd, LONGINT cmd__len)
{
	int32 r, status, exitcode;
	__DUP(title, title__len, CHAR);
	__DUP(cmd, cmd__len, CHAR);
	if (OPM_Verbose) {
		Console_String(title, title__len);
		Console_String(cmd, cmd__len);
		Console_Ln();
	}
	r = Platform_System(cmd, cmd__len);
	status = __MASK(r, -128);
	exitcode = __ASHR(r, 8);
	if (exitcode > 127) {
		exitcode = exitcode - 256;
	}
	if (r != 0) {
		Console_String(title, title__len);
		Console_String(cmd, cmd__len);
		Console_Ln();
		Console_String((CHAR*)"-- failed: status ", 19);
		Console_Int(status, 1);
		Console_String((CHAR*)", exitcode ", 12);
		Console_Int(exitcode, 1);
		Console_String((CHAR*)".", 2);
		Console_Ln();
		if ((status == 0 && exitcode == 127)) {
			Console_String((CHAR*)"Is the C compiler in the current command path\?", 47);
			Console_Ln();
		}
		if (status != 0) {
			Platform_Halt(status);
		} else {
			Platform_Halt(exitcode);
		}
	}
	__DEL(title);
	__DEL(cmd);
}

void extTools_Assemble (CHAR *moduleName, LONGINT moduleName__len)
{
	CHAR cmd[1023];
	__DUP(moduleName, moduleName__len, CHAR);
	__MOVE("gcc -g -O1", cmd, 11);
	Strings_Append(extTools_compilationOptions, 1023, (void*)cmd, 1023);
	Strings_Append((CHAR*)"-c ", 4, (void*)cmd, 1023);
	Strings_Append(moduleName, moduleName__len, (void*)cmd, 1023);
	Strings_Append((CHAR*)".c", 3, (void*)cmd, 1023);
	extTools_execute((CHAR*)"Assemble: ", 11, cmd, 1023);
	__DEL(moduleName);
}

void extTools_LinkMain (CHAR *moduleName, LONGINT moduleName__len, BOOLEAN statically, CHAR *additionalopts, LONGINT additionalopts__len)
{
	CHAR cmd[1023];
	__DUP(additionalopts, additionalopts__len, CHAR);
	__MOVE("gcc -g -O1", cmd, 11);
	Strings_Append((CHAR*)" ", 2, (void*)cmd, 1023);
	Strings_Append(extTools_compilationOptions, 1023, (void*)cmd, 1023);
	Strings_Append(moduleName, moduleName__len, (void*)cmd, 1023);
	Strings_Append((CHAR*)".c ", 4, (void*)cmd, 1023);
	Strings_Append(additionalopts, additionalopts__len, (void*)cmd, 1023);
	if (statically) {
		Strings_Append((CHAR*)"-static", 8, (void*)cmd, 1023);
	}
	Strings_Append((CHAR*)" -o ", 5, (void*)cmd, 1023);
	Strings_Append(moduleName, moduleName__len, (void*)cmd, 1023);
	Strings_Append((CHAR*)" -L\"", 5, (void*)cmd, 1023);
	Strings_Append((CHAR*)"/opt/voc", 9, (void*)cmd, 1023);
	Strings_Append((CHAR*)"/lib\"", 6, (void*)cmd, 1023);
	Strings_Append((CHAR*)" -l voc", 8, (void*)cmd, 1023);
	extTools_execute((CHAR*)"Assemble and link: ", 20, cmd, 1023);
	__DEL(additionalopts);
}


export void *extTools__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(Configuration);
	__MODULE_IMPORT(Console);
	__MODULE_IMPORT(OPM);
	__MODULE_IMPORT(Platform);
	__MODULE_IMPORT(Strings);
	__REGMOD("extTools", 0);
/* BEGIN */
	Strings_Append((CHAR*)" -I \"", 6, (void*)extTools_compilationOptions, 1023);
	Strings_Append((CHAR*)"/opt/voc", 9, (void*)extTools_compilationOptions, 1023);
	Strings_Append((CHAR*)"/include\" ", 11, (void*)extTools_compilationOptions, 1023);
	Platform_GetEnv((CHAR*)"CFLAGS", 7, (void*)extTools_CFLAGS, 1023);
	Strings_Append(extTools_CFLAGS, 1023, (void*)extTools_compilationOptions, 1023);
	Strings_Append((CHAR*)" ", 2, (void*)extTools_compilationOptions, 1023);
	__ENDMOD;
}
