/* voc 1.95 [2016/11/24]. Bootstrapping compiler for address size 8, alignment 8. xtspaSF */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32

#include "SYSTEM.h"
#include "Configuration.h"
#include "Modules.h"
#include "OPM.h"
#include "Out.h"
#include "Platform.h"
#include "Strings.h"


static CHAR extTools_CFLAGS[1023];


export void extTools_Assemble (CHAR *moduleName, LONGINT moduleName__len);
static void extTools_InitialiseCompilerCommand (CHAR *s, LONGINT s__len);
export void extTools_LinkMain (CHAR *moduleName, LONGINT moduleName__len, BOOLEAN statically, CHAR *additionalopts, LONGINT additionalopts__len);
static void extTools_execute (CHAR *title, LONGINT title__len, CHAR *cmd, LONGINT cmd__len);


static void extTools_execute (CHAR *title, LONGINT title__len, CHAR *cmd, LONGINT cmd__len)
{
	INT16 r, status, exitcode;
	__DUP(title, title__len, CHAR);
	__DUP(cmd, cmd__len, CHAR);
	if (__IN(18, OPM_Options, 32)) {
		Out_String(title, title__len);
		Out_String(cmd, cmd__len);
		Out_Ln();
	}
	r = Platform_System(cmd, cmd__len);
	status = __MASK(r, -128);
	exitcode = __ASHR(r, 8);
	if (exitcode > 127) {
		exitcode = exitcode - 256;
	}
	if (r != 0) {
		Out_String(title, title__len);
		Out_String(cmd, cmd__len);
		Out_Ln();
		Out_String((CHAR*)"-- failed: status ", 19);
		Out_Int(status, 1);
		Out_String((CHAR*)", exitcode ", 12);
		Out_Int(exitcode, 1);
		Out_String((CHAR*)".", 2);
		Out_Ln();
		if ((status == 0 && exitcode == 127)) {
			Out_String((CHAR*)"Is the C compiler in the current command path\?", 47);
			Out_Ln();
		}
		if (status != 0) {
			Modules_Halt(status);
		} else {
			Modules_Halt(exitcode);
		}
	}
	__DEL(title);
	__DEL(cmd);
}

static void extTools_InitialiseCompilerCommand (CHAR *s, LONGINT s__len)
{
	__COPY("gcc -g", s, s__len);
	Strings_Append((CHAR*)" -I \"", 6, (void*)s, s__len);
	Strings_Append(OPM_ResourceDir, 1024, (void*)s, s__len);
	Strings_Append((CHAR*)"/include\" ", 11, (void*)s, s__len);
	Platform_GetEnv((CHAR*)"CFLAGS", 7, (void*)extTools_CFLAGS, 1023);
	Strings_Append(extTools_CFLAGS, 1023, (void*)s, s__len);
	Strings_Append((CHAR*)" ", 2, (void*)s, s__len);
}

void extTools_Assemble (CHAR *moduleName, LONGINT moduleName__len)
{
	CHAR cmd[1023];
	__DUP(moduleName, moduleName__len, CHAR);
	extTools_InitialiseCompilerCommand((void*)cmd, 1023);
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
	extTools_InitialiseCompilerCommand((void*)cmd, 1023);
	Strings_Append(moduleName, moduleName__len, (void*)cmd, 1023);
	Strings_Append((CHAR*)".c ", 4, (void*)cmd, 1023);
	Strings_Append(additionalopts, additionalopts__len, (void*)cmd, 1023);
	if (statically) {
		Strings_Append((CHAR*)"-static", 8, (void*)cmd, 1023);
	}
	Strings_Append((CHAR*)" -o ", 5, (void*)cmd, 1023);
	Strings_Append(moduleName, moduleName__len, (void*)cmd, 1023);
	Strings_Append((CHAR*)" -L\"", 5, (void*)cmd, 1023);
	Strings_Append((CHAR*)"", 1, (void*)cmd, 1023);
	Strings_Append((CHAR*)"/lib\"", 6, (void*)cmd, 1023);
	Strings_Append((CHAR*)" -l voc", 8, (void*)cmd, 1023);
	Strings_Append((CHAR*)"-O", 3, (void*)cmd, 1023);
	Strings_Append(OPM_Model, 10, (void*)cmd, 1023);
	Strings_Append((CHAR*)"", 1, (void*)cmd, 1023);
	extTools_execute((CHAR*)"Assemble and link: ", 20, cmd, 1023);
	__DEL(additionalopts);
}


export void *extTools__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(Configuration);
	__MODULE_IMPORT(Modules);
	__MODULE_IMPORT(OPM);
	__MODULE_IMPORT(Out);
	__MODULE_IMPORT(Platform);
	__MODULE_IMPORT(Strings);
	__REGMOD("extTools", 0);
/* BEGIN */
	__ENDMOD;
}
