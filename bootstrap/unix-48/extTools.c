/* voc 4.0.0 [2026/10/15]. Bootstrapping compiler for address size 8, alignment 8. xrtspaSF */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32

#include "SYSTEM.h"
#include "Configuration.h"
#include "Files.h"
#include "Heap.h"
#include "Modules.h"
#include "OPM.h"
#include "Out.h"
#include "Platform.h"
#include "Strings.h"

typedef
	CHAR extTools_CommandString[8192];

typedef
	CHAR extTools_Path[4096];


static extTools_CommandString extTools_CFLAGS, extTools_LDFLAGS, extTools_LDLIBS;
export BOOLEAN extTools_hosted;


static void extTools_Add (CHAR *text, ADDRESS text__len, CHAR *target, ADDRESS target__len);
export void extTools_Assemble (CHAR *moduleName, ADDRESS moduleName__len);
static void extTools_Dependencies (CHAR *cmd);
static void extTools_ExtraLibraries (CHAR *cmd);
static void extTools_Fail (CHAR *message, ADDRESS message__len);
static void extTools_FindLibrary (CHAR *name, ADDRESS name__len, CHAR *extension, ADDRESS extension__len, CHAR *full);
export void extTools_GenerateLauncher (CHAR *moduleName, ADDRESS moduleName__len);
static void extTools_HostLine (Files_Rider *rider, ADDRESS *rider__typ, CHAR *text, ADDRESS text__len);
static void extTools_InitialiseCompilerCommand (CHAR *s, ADDRESS s__len, CHAR *additionalopts, ADDRESS additionalopts__len);
static BOOLEAN extTools_IsCore (CHAR *name, ADDRESS name__len);
static BOOLEAN extTools_IsTCC (void);
static void extTools_LibraryName (CHAR *name, ADDRESS name__len, CHAR *extension, ADDRESS extension__len, CHAR *file, ADDRESS file__len);
export void extTools_LinkLauncher (CHAR *moduleName, ADDRESS moduleName__len, BOOLEAN embedded);
export void extTools_LinkMain (CHAR *moduleName, ADDRESS moduleName__len, BOOLEAN statically, CHAR *additionalopts, ADDRESS additionalopts__len);
static void extTools_LinkModularMain (CHAR *moduleName, ADDRESS moduleName__len);
export void extTools_LinkModule (CHAR *moduleName, ADDRESS moduleName__len);
static void extTools_ModularCommand (CHAR *cmd);
static void extTools_ModularLinkFlags (CHAR *cmd);
static BOOLEAN extTools_NextDirectory (CHAR *path, ADDRESS path__len, INT16 *pos, CHAR *dir);
static void extTools_Quote (CHAR *text, ADDRESS text__len, CHAR *target, ADDRESS target__len);
static void extTools_SearchPath (CHAR *path);
static void extTools_execute (CHAR *title, ADDRESS title__len, CHAR *cmd, ADDRESS cmd__len);


static void extTools_execute (CHAR *title, ADDRESS title__len, CHAR *cmd, ADDRESS cmd__len)
{
	INT16 r, status, exitcode;
	extTools_CommandString fullcmd;
	__DUP(title, title__len, CHAR);
	__DUP(cmd, cmd__len, CHAR);
	if (!OPM_noerr) {
		__DEL(title);
		__DEL(cmd);
		return;
	}
	if (__IN(18, OPM_Options, 32)) {
		Out_String((CHAR*)"  ", 3);
		Out_String(cmd, cmd__len);
		Out_Ln();
	}
	__COPY(cmd, fullcmd, 8192);
	Heap_GC(extTools_hosted);
	r = Platform_System(fullcmd, 8192);
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
		if (extTools_hosted) {
			OPM_noerr = 0;
		} else if (status != 0) {
			Modules_Halt(status);
		} else {
			Modules_Halt(exitcode);
		}
	}
	__DEL(title);
	__DEL(cmd);
}

static void extTools_InitialiseCompilerCommand (CHAR *s, ADDRESS s__len, CHAR *additionalopts, ADDRESS additionalopts__len)
{
	__DUP(additionalopts, additionalopts__len, CHAR);
	__COPY("gcc -fPIC -g", s, s__len);
	Strings_Append((CHAR*)" -I \"", 6, (void*)s, s__len);
	Strings_Append(OPM_ResourceDir, 1024, (void*)s, s__len);
	Strings_Append((CHAR*)"/include\" ", 11, (void*)s, s__len);
	Strings_Append(additionalopts, additionalopts__len, (void*)s, s__len);
	Strings_Append((CHAR*)" ", 2, (void*)s, s__len);
	Platform_GetEnv((CHAR*)"CFLAGS", 7, (void*)extTools_CFLAGS, 8192);
	Strings_Append(extTools_CFLAGS, 8192, (void*)s, s__len);
	Strings_Append((CHAR*)" ", 2, (void*)s, s__len);
	__DEL(additionalopts);
}

static void extTools_Fail (CHAR *message, ADDRESS message__len)
{
	__DUP(message, message__len, CHAR);
	OPM_LogWStr(message, message__len);
	OPM_LogWLn();
	if (extTools_hosted) {
		OPM_noerr = 0;
	} else {
		Platform_Exit(1);
	}
	__DEL(message);
}

static void extTools_Add (CHAR *text, ADDRESS text__len, CHAR *target, ADDRESS target__len)
{
	__DUP(text, text__len, CHAR);
	if (!OPM_noerr) {
		__DEL(text);
		return;
	}
	if ((Strings_Length(target, target__len) + Strings_Length(text, text__len)) >= target__len) {
		extTools_Fail((CHAR*)"Compiler/linker command or library path is too long.", 53);
		__DEL(text);
		return;
	}
	Strings_Append(text, text__len, (void*)target, target__len);
	__DEL(text);
}

static void extTools_Quote (CHAR *text, ADDRESS text__len, CHAR *target, ADDRESS target__len)
{
	INT16 i;
	CHAR ch[2];
	__DUP(text, text__len, CHAR);
	extTools_Add((CHAR*)"'", 2, (void*)target, target__len);
	ch[1] = 0x00;
	i = 0;
	while (text[__X(i, text__len)] != 0x00) {
		if (text[__X(i, text__len)] == '\'') {
			extTools_Add((CHAR*)"'", 2, (void*)target, target__len);
			extTools_Add((CHAR*)"\"", 2, (void*)target, target__len);
			extTools_Add((CHAR*)"'", 2, (void*)target, target__len);
			extTools_Add((CHAR*)"\"", 2, (void*)target, target__len);
			extTools_Add((CHAR*)"'", 2, (void*)target, target__len);
		} else {
			ch[0] = text[__X(i, text__len)];
			extTools_Add(ch, 2, (void*)target, target__len);
		}
		i += 1;
	}
	extTools_Add((CHAR*)"'", 2, (void*)target, target__len);
	__DEL(text);
}

static BOOLEAN extTools_IsCore (CHAR *name, ADDRESS name__len)
{
	__DUP(name, name__len, CHAR);
	__DEL(name);
	return (((__STRCMP(name, "SYSTEM") == 0 || __STRCMP(name, "Heap") == 0) || __STRCMP(name, "PlatformNative") == 0) || __STRCMP(name, "Platform") == 0) || __STRCMP(name, "Modules") == 0;
}

static void extTools_SearchPath (CHAR *path)
{
	extTools_Path extra;
	__MOVE(".:", path, 3);
	Platform_GetEnv((CHAR*)"VOC_MODULE_PATH", 16, (void*)extra, 4096);
	if (extra[0] != 0x00) {
		extTools_Add(extra, 4096, (void*)path, 4096);
		extTools_Add((CHAR*)":", 2, (void*)path, 4096);
	}
	extTools_Add(OPM_LibraryDir, 1024, (void*)path, 4096);
}

static BOOLEAN extTools_NextDirectory (CHAR *path, ADDRESS path__len, INT16 *pos, CHAR *dir)
{
	INT16 i;
	__DUP(path, path__len, CHAR);
	if (*pos < 0) {
		__DEL(path);
		return 0;
	}
	i = 0;
	while ((path[__X(*pos, path__len)] != 0x00 && path[__X(*pos, path__len)] != ':')) {
		dir[__X(i, 4096)] = path[__X(*pos, path__len)];
		i += 1;
		*pos += 1;
	}
	dir[__X(i, 4096)] = 0x00;
	if (path[__X(*pos, path__len)] == 0x00) {
		*pos = -1;
	} else {
		*pos += 1;
	}
	if (dir[0] == 0x00) {
		__MOVE(".", dir, 2);
	}
	__DEL(path);
	return 1;
}

static void extTools_LibraryName (CHAR *name, ADDRESS name__len, CHAR *extension, ADDRESS extension__len, CHAR *file, ADDRESS file__len)
{
	__DUP(name, name__len, CHAR);
	__DUP(extension, extension__len, CHAR);
	__COPY("lib", file, file__len);
	extTools_Add((CHAR*)"voc", 4, (void*)file, file__len);
	extTools_Add((CHAR*)"-", 2, (void*)file, file__len);
	extTools_Add(name, name__len, (void*)file, file__len);
	extTools_Add((CHAR*)"-O", 3, (void*)file, file__len);
	extTools_Add(OPM_Model, 10, (void*)file, file__len);
	extTools_Add(extension, extension__len, (void*)file, file__len);
	__DEL(name);
	__DEL(extension);
}

static void extTools_FindLibrary (CHAR *name, ADDRESS name__len, CHAR *extension, ADDRESS extension__len, CHAR *full)
{
	extTools_Path path, dir;
	CHAR file[128];
	INT16 pos;
	Platform_FileIdentity id;
	__DUP(name, name__len, CHAR);
	__DUP(extension, extension__len, CHAR);
	extTools_LibraryName(name, name__len, extension, extension__len, (void*)file, 128);
	extTools_SearchPath(path);
	pos = 0;
	while (extTools_NextDirectory(path, 4096, &pos, dir)) {
		__MOVE(dir, full, 4096);
		extTools_Add((CHAR*)"/", 2, (void*)full, 4096);
		extTools_Add(file, 128, (void*)full, 4096);
		if (Platform_IdentifyByName(full, 4096, &id, Platform_FileIdentity__typ) == 0) {
			__DEL(name);
			__DEL(extension);
			return;
		}
	}
	OPM_LogWStr((CHAR*)"Shared-module link: missing ", 29);
	OPM_LogWStr(file, 128);
	OPM_LogWLn();
	extTools_Fail((CHAR*)"Build the dependency first; set VOC_MODULE_PATH/VOCLIBDIR for library directories.", 83);
	__DEL(name);
	__DEL(extension);
}

static BOOLEAN extTools_IsTCC (void)
{
	extTools_Path compiler;
	INT16 i, start;
	Platform_GetEnv((CHAR*)"CC", 3, (void*)compiler, 4096);
	if (compiler[0] == 0x00) {
		return 0;
	}
	i = 0;
	start = 0;
	while ((compiler[__X(i, 4096)] != 0x00 && compiler[__X(i, 4096)] != ' ')) {
		if (compiler[__X(i, 4096)] == '/') {
			start = i + 1;
		}
		i += 1;
	}
	return (((((i - start == 3 && compiler[__X(start, 4096)] == 't')) && compiler[__X(start + 1, 4096)] == 'c')) && compiler[__X(start + 2, 4096)] == 'c');
}

static void extTools_ModularCommand (CHAR *cmd)
{
	extTools_Path compiler, path, dir;
	INT16 pos;
	CHAR include[16];
	Platform_GetEnv((CHAR*)"CC", 3, (void*)compiler, 4096);
	if (compiler[0] == 0x00) {
		__COPY("gcc -fPIC -g", cmd, 8192);
	} else {
		__COPY(compiler, cmd, 8192);
	}
	extTools_Add((CHAR*)" ", 2, (void*)cmd, 8192);
	Platform_GetEnv((CHAR*)"CFLAGS", 7, (void*)extTools_CFLAGS, 8192);
	extTools_Add(extTools_CFLAGS, 8192, (void*)cmd, 8192);
	extTools_Add((CHAR*)" -fno-strict-aliasing -fPIC ", 29, (void*)cmd, 8192);
	extTools_SearchPath(path);
	pos = 0;
	if (extTools_IsTCC()) {
		__MOVE(" -I", include, 4);
	} else {
		__MOVE(" -iquote", include, 9);
	}
	while (extTools_NextDirectory(path, 4096, &pos, dir)) {
		extTools_Add(include, 16, (void*)cmd, 8192);
		extTools_Quote(dir, 4096, (void*)cmd, 8192);
	}
	__MOVE(OPM_ResourceDir, dir, 1024);
	extTools_Add((CHAR*)"/include", 9, (void*)dir, 4096);
	extTools_Add(include, 16, (void*)cmd, 8192);
	extTools_Quote(dir, 4096, (void*)cmd, 8192);
	extTools_Add((CHAR*)" ", 2, (void*)cmd, 8192);
}

static void extTools_ModularLinkFlags (CHAR *cmd)
{
	extTools_Path path;
	Platform_GetEnv((CHAR*)"LDFLAGS", 8, (void*)extTools_LDFLAGS, 8192);
	extTools_Add((CHAR*)" ", 2, (void*)cmd, 8192);
	extTools_Add(extTools_LDFLAGS, 8192, (void*)cmd, 8192);
	if (!extTools_IsTCC()) {
		extTools_Add((CHAR*)" -Wl,--no-as-needed ", 21, (void*)cmd, 8192);
	}
	extTools_Add((CHAR*)" -Wl,--enable-new-dtags ", 25, (void*)cmd, 8192);
	Platform_GetEnv((CHAR*)"VOC_RUNPATH", 12, (void*)path, 4096);
	if (path[0] == 0x00) {
		__MOVE("$ORIGIN:", path, 9);
		extTools_Add(OPM_LibraryDir, 1024, (void*)path, 4096);
	}
	extTools_Add((CHAR*)" -Wl,-rpath,", 13, (void*)cmd, 8192);
	extTools_Quote(path, 4096, (void*)cmd, 8192);
	extTools_Add((CHAR*)" ", 2, (void*)cmd, 8192);
}

static void extTools_Dependencies (CHAR *cmd)
{
	INT16 i;
	extTools_Path full;
	i = 0;
	while (i < OPM_SharedImportCount) {
		if (!extTools_IsCore(OPM_SharedImports[__X(i, 64)], 64)) {
			extTools_FindLibrary(OPM_SharedImports[__X(i, 64)], 64, (CHAR*)".so", 4, full);
			extTools_Quote(full, 4096, (void*)cmd, 8192);
			extTools_Add((CHAR*)" ", 2, (void*)cmd, 8192);
		}
		i += 1;
	}
}

static void extTools_ExtraLibraries (CHAR *cmd)
{
	Platform_GetEnv((CHAR*)"LDLIBS", 7, (void*)extTools_LDLIBS, 8192);
	extTools_Add((CHAR*)" ", 2, (void*)cmd, 8192);
	extTools_Add(extTools_LDLIBS, 8192, (void*)cmd, 8192);
}

void extTools_Assemble (CHAR *moduleName, ADDRESS moduleName__len)
{
	extTools_CommandString cmd;
	__DUP(moduleName, moduleName__len, CHAR);
	if (__IN(20, OPM_Options, 32)) {
		extTools_ModularCommand(cmd);
	} else {
		extTools_InitialiseCompilerCommand((void*)cmd, 8192, (CHAR*)"", 1);
	}
	Strings_Append((CHAR*)"-c ", 4, (void*)cmd, 8192);
	Strings_Append(moduleName, moduleName__len, (void*)cmd, 8192);
	Strings_Append((CHAR*)".c", 3, (void*)cmd, 8192);
	extTools_execute((CHAR*)"C compile: ", 12, cmd, 8192);
	__DEL(moduleName);
}

void extTools_LinkModule (CHAR *moduleName, ADDRESS moduleName__len)
{
	extTools_CommandString cmd;
	CHAR file[128];
	extTools_Path full;
	__DUP(moduleName, moduleName__len, CHAR);
	if (extTools_IsCore(moduleName, moduleName__len)) {
		extTools_Fail((CHAR*)"SYSTEM, PlatformNative, Platform, Heap and Modules belong to the minimal core, not separate modules.", 101);
	}
	extTools_FindLibrary((CHAR*)"core", 5, (CHAR*)".a", 3, full);
	extTools_ModularCommand(cmd);
	extTools_Add((CHAR*)" -shared ", 10, (void*)cmd, 8192);
	extTools_Add(moduleName, moduleName__len, (void*)cmd, 8192);
	extTools_Add((CHAR*)".c ", 4, (void*)cmd, 8192);
	extTools_LibraryName(moduleName, moduleName__len, (CHAR*)".so", 4, (void*)file, 128);
	extTools_Add((CHAR*)" -Wl,-soname,", 14, (void*)cmd, 8192);
	extTools_Quote(file, 128, (void*)cmd, 8192);
	extTools_Add((CHAR*)" -o ", 5, (void*)cmd, 8192);
	extTools_Quote(file, 128, (void*)cmd, 8192);
	extTools_ModularLinkFlags(cmd);
	extTools_Dependencies(cmd);
	extTools_ExtraLibraries(cmd);
	extTools_execute((CHAR*)"Shared-module link: ", 21, cmd, 8192);
	__DEL(moduleName);
}

static void extTools_LinkModularMain (CHAR *moduleName, ADDRESS moduleName__len)
{
	extTools_CommandString cmd;
	extTools_Path full;
	__DUP(moduleName, moduleName__len, CHAR);
	extTools_ModularCommand(cmd);
	extTools_Add(moduleName, moduleName__len, (void*)cmd, 8192);
	extTools_Add((CHAR*)".c -o ", 7, (void*)cmd, 8192);
	extTools_Quote(moduleName, moduleName__len, (void*)cmd, 8192);
	extTools_ModularLinkFlags(cmd);
	extTools_Dependencies(cmd);
	extTools_FindLibrary((CHAR*)"core", 5, (CHAR*)".so", 4, full);
	extTools_Quote(full, 4096, (void*)cmd, 8192);
	extTools_ExtraLibraries(cmd);
	extTools_execute((CHAR*)"Modular program link: ", 23, cmd, 8192);
	__DEL(moduleName);
}

static void extTools_HostLine (Files_Rider *rider, ADDRESS *rider__typ, CHAR *text, ADDRESS text__len)
{
	__DUP(text, text__len, CHAR);
	Files_WriteBytes(&*rider, rider__typ, (void*)text, text__len * 1, Strings_Length(text, text__len));
	Files_Write(&*rider, rider__typ, 0x0a);
	__DEL(text);
}

void extTools_GenerateLauncher (CHAR *moduleName, ADDRESS moduleName__len)
{
	Files_File file = NIL;
	Files_Rider rider;
	CHAR name[128];
	CHAR line[256];
	__DUP(moduleName, moduleName__len, CHAR);
	__COPY(moduleName, name, 128);
	extTools_Add((CHAR*)"__host.c", 9, (void*)name, 128);
	file = Files_New(name, 128);
	if (file == NIL) {
		extTools_Fail((CHAR*)"Cannot create application launcher source.", 43);
		__DEL(moduleName);
		return;
	}
	Files_Set(&rider, Files_Rider__typ, file, 0);
	extTools_HostLine(&rider, Files_Rider__typ, (CHAR*)"/* Generated VOC module host. The application is loaded, not linked. */", 72);
	extTools_HostLine(&rider, Files_Rider__typ, (CHAR*)"#include \"SYSTEM.h\"", 20);
	extTools_HostLine(&rider, Files_Rider__typ, (CHAR*)"#include \"ModuleLoader.h\"", 26);
	extTools_HostLine(&rider, Files_Rider__typ, (CHAR*)"int main(int argc, char **argv) {", 34);
	extTools_HostLine(&rider, Files_Rider__typ, (CHAR*)"  __INIT(argc, argv);", 22);
	extTools_HostLine(&rider, Files_Rider__typ, (CHAR*)"  __MODULE_IMPORT(ModuleLoader);", 33);
	extTools_HostLine(&rider, Files_Rider__typ, (CHAR*)"  __REGMAIN(\"_VOCModuleHost\", 0);", 34);
	__MOVE("  ModuleLoader_Run((CHAR*)\"", line, 28);
	extTools_Add(moduleName, moduleName__len, (void*)line, 256);
	extTools_Add((CHAR*)"\", sizeof \"", 12, (void*)line, 256);
	extTools_Add(moduleName, moduleName__len, (void*)line, 256);
	extTools_Add((CHAR*)"\");", 4, (void*)line, 256);
	extTools_HostLine(&rider, Files_Rider__typ, line, 256);
	extTools_HostLine(&rider, Files_Rider__typ, (CHAR*)"  __FINI;", 10);
	extTools_HostLine(&rider, Files_Rider__typ, (CHAR*)"}", 2);
	if (rider.res != 0) {
		extTools_Fail((CHAR*)"Cannot write application launcher source.", 42);
	}
	if (!OPM_noerr) {
		__DEL(moduleName);
		return;
	}
	Files_Register(file);
	__DEL(moduleName);
}

void extTools_LinkLauncher (CHAR *moduleName, ADDRESS moduleName__len, BOOLEAN embedded)
{
	extTools_CommandString cmd;
	extTools_Path full;
	__DUP(moduleName, moduleName__len, CHAR);
	extTools_ModularCommand(cmd);
	extTools_Add(moduleName, moduleName__len, (void*)cmd, 8192);
	extTools_Add((CHAR*)"__host.c -o ", 13, (void*)cmd, 8192);
	extTools_Quote(moduleName, moduleName__len, (void*)cmd, 8192);
	extTools_ModularLinkFlags(cmd);
	extTools_FindLibrary((CHAR*)"ModuleLoader", 13, (CHAR*)".so", 4, full);
	extTools_Quote(full, 4096, (void*)cmd, 8192);
	extTools_Add((CHAR*)" ", 2, (void*)cmd, 8192);
	if (embedded) {
		extTools_FindLibrary((CHAR*)"core", 5, (CHAR*)".a", 3, full);
		extTools_Add((CHAR*)" -Wl,--export-dynamic -Wl,--whole-archive ", 43, (void*)cmd, 8192);
		extTools_Quote(full, 4096, (void*)cmd, 8192);
		extTools_Add((CHAR*)" -Wl,--no-whole-archive ", 25, (void*)cmd, 8192);
	} else {
		extTools_FindLibrary((CHAR*)"core", 5, (CHAR*)".so", 4, full);
		extTools_Quote(full, 4096, (void*)cmd, 8192);
	}
	extTools_execute((CHAR*)"Module-host link: ", 19, cmd, 8192);
	__DEL(moduleName);
}

void extTools_LinkMain (CHAR *moduleName, ADDRESS moduleName__len, BOOLEAN statically, CHAR *additionalopts, ADDRESS additionalopts__len)
{
	extTools_CommandString cmd;
	__DUP(additionalopts, additionalopts__len, CHAR);
	if (__IN(20, OPM_Options, 32)) {
		if (statically) {
			extTools_Fail((CHAR*)"Static system linking cannot be combined with modular program linking; use -mP.", 80);
		}
		extTools_LinkModularMain(moduleName, moduleName__len);
		__DEL(additionalopts);
		return;
	}
	extTools_InitialiseCompilerCommand((void*)cmd, 8192, additionalopts, additionalopts__len);
	Strings_Append(moduleName, moduleName__len, (void*)cmd, 8192);
	Strings_Append((CHAR*)".c ", 4, (void*)cmd, 8192);
	Platform_GetEnv((CHAR*)"LDFLAGS", 8, (void*)extTools_LDFLAGS, 8192);
	Strings_Append(extTools_LDFLAGS, 8192, (void*)cmd, 8192);
	Strings_Append((CHAR*)" ", 2, (void*)cmd, 8192);
	if (statically) {
		Strings_Append((CHAR*)" -static", 9, (void*)cmd, 8192);
	}
	Strings_Append((CHAR*)" -o ", 5, (void*)cmd, 8192);
	Strings_Append(moduleName, moduleName__len, (void*)cmd, 8192);
	Strings_Append((CHAR*)" ", 2, (void*)cmd, 8192);
	Platform_GetEnv((CHAR*)"LDLIBS", 7, (void*)extTools_LDLIBS, 8192);
	Strings_Append(extTools_LDLIBS, 8192, (void*)cmd, 8192);
	Strings_Append((CHAR*)" ", 2, (void*)cmd, 8192);
	if (!statically || 1) {
		Strings_Append((CHAR*)" -L\"", 5, (void*)cmd, 8192);
		Strings_Append(OPM_LibraryDir, 1024, (void*)cmd, 8192);
		Strings_Append((CHAR*)"\"", 2, (void*)cmd, 8192);
		Strings_Append((CHAR*)" -lvoc", 7, (void*)cmd, 8192);
		Strings_Append((CHAR*)"-O", 3, (void*)cmd, 8192);
		Strings_Append(OPM_Model, 10, (void*)cmd, 8192);
		Strings_Append((CHAR*)"", 1, (void*)cmd, 8192);
	}
	extTools_execute((CHAR*)"C compile and link: ", 21, cmd, 8192);
	__DEL(additionalopts);
}


export void *extTools__init(void)
{
	__DEFMOD;
	__MODULE_IMPORT(Configuration);
	__MODULE_IMPORT(Files);
	__MODULE_IMPORT(Heap);
	__MODULE_IMPORT(Modules);
	__MODULE_IMPORT(OPM);
	__MODULE_IMPORT(Out);
	__MODULE_IMPORT(Platform);
	__MODULE_IMPORT(Strings);
	__REGMOD("extTools", 0);
/* BEGIN */
	__ENDMOD;
}
