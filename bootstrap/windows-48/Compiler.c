/* voc 4.0.0 [2026/10/15]. Bootstrapping compiler for address size 8, alignment 8. xrtspamS */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32
#define VOC_MAIN_PROGRAM 1

#include "SYSTEM.h"
#include "Configuration.h"
#include "Heap.h"
#include "Modules.h"
#include "OPB.h"
#include "OPC.h"
#include "OPM.h"
#include "OPP.h"
#include "OPT.h"
#include "OPV.h"
#include "Platform.h"
#include "Strings.h"
#include "VT100.h"
#include "extTools.h"


static BOOLEAN Compiler_busy;


export void Compiler_Abort (void);
export BOOLEAN Compiler_CompileArguments (INT16 count, OPM_ArgumentReader reader);
static void Compiler_FindLocalObjectFiles (CHAR *objectnames, ADDRESS objectnames__len);
export void Compiler_Module (BOOLEAN *done);
static void Compiler_PropagateElementaryTypeSizes (void);
static BOOLEAN Compiler_Run (void);
export void Compiler_Translate (void);
static void Compiler_Trap (INT32 sig);

#define Compiler_Standalone()	VOC_MAIN_PROGRAM

void Compiler_Module (BOOLEAN *done)
{
	BOOLEAN ext, new;
	OPT_Node p = NIL;
	OPP_Module(&p, OPM_Options);
	if ((((extTools_hosted && __IN(19, OPM_Options, 32))) && Modules_ThisMod(OPT_SelfName, 256) != NIL)) {
		OPM_LogWStr((CHAR*)"The module is loaded; free it or restart the host before rebuilding its library.", 81);
		OPM_LogWLn();
		OPM_noerr = 0;
	}
	if ((__IN(20, OPM_Options, 32) && Strings_Length(OPT_SelfName, 256) >= 64)) {
		OPM_LogWStr((CHAR*)"Modular-build names must fit the 63-character runtime registry.", 64);
		OPM_LogWLn();
		OPM_noerr = 0;
	}
	if ((__IN(20, OPM_Options, 32) && __STRCMP(OPT_SelfName, "core") == 0)) {
		OPM_LogWStr((CHAR*)"The library name core is reserved for the minimal runtime.", 59);
		OPM_LogWLn();
		OPM_noerr = 0;
	}
	if ((__IN(19, OPM_Options, 32) && (((__STRCMP(OPT_SelfName, "SYSTEM") == 0 || __STRCMP(OPT_SelfName, "Platform") == 0) || __STRCMP(OPT_SelfName, "Heap") == 0) || __STRCMP(OPT_SelfName, "Modules") == 0))) {
		OPM_LogWStr((CHAR*)"SYSTEM, Platform, Heap and Modules belong to the minimal core, not separate modules.", 85);
		OPM_LogWLn();
		OPM_noerr = 0;
	}
	if ((__IN(21, OPM_Options, 32) && __STRCMP(OPT_SelfName, "ModuleLoader") == 0)) {
		OPM_LogWStr((CHAR*)"ModuleLoader is the launcher's loader; build it as a library, not an application.", 82);
		OPM_LogWLn();
		OPM_noerr = 0;
	}
	if (OPM_noerr) {
		OPV_Init();
		OPT_InitRecno();
		OPV_AdrAndSize(OPT_topScope);
		OPT_Export(&ext, &new);
		if (OPM_noerr) {
			OPM_OpenFiles((void*)OPT_SelfName, 256);
			OPM_DeleteObj((void*)OPT_SelfName, 256);
			OPC_Init();
			OPV_Module(p);
			if (OPM_noerr) {
				if ((__IN(10, OPM_Options, 32) && __STRCMP(OPM_modName, "SYSTEM") != 0)) {
					OPM_DeleteSym((void*)OPT_SelfName, 256);
					OPM_LogVT100((CHAR*)"32m", 4);
					OPM_LogWStr((CHAR*)"  Main program.", 16);
					OPM_LogVT100((CHAR*)"0m", 3);
				} else {
					if (new) {
						OPM_LogVT100((CHAR*)"32m", 4);
						OPM_LogWStr((CHAR*)"  New symbol file.", 19);
						OPM_LogVT100((CHAR*)"0m", 3);
						OPM_RegisterNewSym();
					} else if (ext) {
						OPM_LogWStr((CHAR*)"  Extended symbol file.", 24);
						OPM_RegisterNewSym();
					}
				}
			} else {
				OPM_DeleteSym((void*)OPT_SelfName, 256);
			}
		}
	}
	OPM_CloseFiles();
	OPT_Close();
	OPM_LogWLn();
	*done = OPM_noerr;
}

static void Compiler_PropagateElementaryTypeSizes (void)
{
	OPT_Struct adrinttyp = NIL;
	OPT_sysptrtyp->size = OPM_AddressSize;
	OPT_sysptrtyp->idfp = OPT_sysptrtyp->form;
	OPM_FPrint(&OPT_sysptrtyp->idfp, OPT_sysptrtyp->size);
	OPT_adrtyp->size = OPM_AddressSize;
	OPT_adrtyp->idfp = OPT_adrtyp->form;
	OPM_FPrint(&OPT_adrtyp->idfp, OPT_adrtyp->size);
	adrinttyp = OPT_IntType(OPM_AddressSize);
	OPT_adrtyp->strobj = adrinttyp->strobj;
	OPT_sinttyp = OPT_IntType(OPM_ShortintSize);
	OPT_inttyp = OPT_IntType(OPM_IntegerSize);
	OPT_linttyp = OPT_IntType(OPM_LongintSize);
	OPT_sintobj->typ = OPT_sinttyp;
	OPT_intobj->typ = OPT_inttyp;
	OPT_lintobj->typ = OPT_linttyp;
	switch (OPM_SetSize) {
		case 4: 
			OPT_settyp = OPT_set32typ;
			break;
		default: 
			OPT_settyp = OPT_set64typ;
			break;
	}
	OPT_setobj->typ = OPT_settyp;
	if (__STRCMP(OPM_Model, "C") == 0) {
		OPT_cpbytetyp->strobj->name[4] = 0x00;
	} else {
		OPT_cpbytetyp->strobj->name[4] = '@';
	}
}

static void Compiler_FindLocalObjectFiles (CHAR *objectnames, ADDRESS objectnames__len)
{
	OPT_Link l = NIL;
	CHAR fn[64];
	Platform_FileIdentity id;
	objectnames[0] = 0x00;
	l = OPT_Links;
	while (l != NIL) {
		__COPY(l->name, fn, 64);
		Strings_Append((CHAR*)".sym", 5, (void*)fn, 64);
		if (Platform_IdentifyByName(fn, 64, &id, Platform_FileIdentity__typ) == 0) {
			__COPY(l->name, fn, 64);
			Strings_Append((CHAR*)".o", 3, (void*)fn, 64);
			if (Platform_IdentifyByName(fn, 64, &id, Platform_FileIdentity__typ) == 0) {
				Strings_Append((CHAR*)" ", 2, (void*)objectnames, objectnames__len);
				Strings_Append(fn, 64, (void*)objectnames, objectnames__len);
			} else {
				OPM_LogVT100((CHAR*)"91m", 4);
				OPM_LogWStr((CHAR*)"Link warning: a local symbol file is present for module ", 57);
				OPM_LogWStr(l->name, 256);
				OPM_LogWStr((CHAR*)", but local object file '", 26);
				OPM_LogWStr(fn, 64);
				OPM_LogWStr((CHAR*)"' is missing.", 14);
				OPM_LogVT100((CHAR*)"0m", 3);
				OPM_LogWLn();
			}
		}
		l = l->next;
	}
}

static BOOLEAN Compiler_Run (void)
{
	BOOLEAN done;
	CHAR linkfiles[2048];
	if (OPM_OpenPar()) {
		for (;;) {
			OPM_Init(&done);
			if (!done) {
				return OPM_noerr;
			}
			OPM_InitOptions();
			if (!OPM_noerr) {
				return 0;
			}
			Compiler_PropagateElementaryTypeSizes();
			Heap_GC(extTools_hosted);
			Compiler_Module(&done);
			if (!done) {
				OPM_LogWLn();
				OPM_LogWStr((CHAR*)"Module compilation failed.", 27);
				OPM_LogWLn();
				return 0;
			}
			if (__IN(21, OPM_Options, 32)) {
				extTools_GenerateLauncher(OPM_modName, 64);
			}
			if (!__IN(13, OPM_Options, 32)) {
				if ((__IN(19, OPM_Options, 32) && !__IN(14, OPM_Options, 32))) {
					extTools_LinkModule(OPM_modName, 64);
					if (__IN(21, OPM_Options, 32)) {
						extTools_LinkLauncher(OPM_modName, 64, __IN(22, OPM_Options, 32));
					}
				} else if (__IN(14, OPM_Options, 32)) {
					extTools_Assemble(OPM_modName, 64);
				} else {
					if (!__IN(10, OPM_Options, 32)) {
						extTools_Assemble(OPM_modName, 64);
					} else {
						linkfiles[0] = 0x00;
						if (!__IN(20, OPM_Options, 32)) {
							Compiler_FindLocalObjectFiles((void*)linkfiles, 2048);
						}
						extTools_LinkMain((void*)OPM_modName, 64, __IN(15, OPM_Options, 32), linkfiles, 2048);
					}
				}
			}
			if (!OPM_noerr) {
				return 0;
			}
		}
	}
	return 1;
}

BOOLEAN Compiler_CompileArguments (INT16 count, OPM_ArgumentReader reader)
{
	BOOLEAN done;
	if (Compiler_busy) {
		OPM_LogWStr((CHAR*)"compiler is already compiling", 30);
		OPM_LogWLn();
		return 0;
	}
	Compiler_busy = 1;
	extTools_hosted = 1;
	OPM_SetArguments(count, reader);
	done = Compiler_Run();
	OPM_SetArguments(0, NIL);
	extTools_hosted = 0;
	Compiler_busy = 0;
	return done;
}

void Compiler_Abort (void)
{
	if (Compiler_busy) {
		OPM_noerr = 0;
		OPM_CloseFiles();
		if (OPT_topScope != NIL) {
			OPT_Close();
		}
		OPM_SetArguments(0, NIL);
		extTools_hosted = 0;
		Compiler_busy = 0;
	}
}

void Compiler_Translate (void)
{
	BOOLEAN done;
	OPM_SetArguments(0, NIL);
	done = Compiler_Run();
	if (!done) {
		Platform_Exit(1);
	}
}

static void Compiler_Trap (INT32 sig)
{
	Heap_FINALL();
	if (sig == 3) {
		Platform_Exit(0);
	} else {
		if (sig == 4) {
			OPM_LogWStr((CHAR*)" --- Oberon compiler internal error", 36);
			OPM_LogWLn();
		}
		Platform_Exit(2);
	}
}


export int main(int argc, char **argv)
{
	__INIT(argc, argv);
	__MODULE_IMPORT(Configuration);
	__MODULE_IMPORT(Heap);
	__MODULE_IMPORT(Modules);
	__MODULE_IMPORT(OPB);
	__MODULE_IMPORT(OPC);
	__MODULE_IMPORT(OPM);
	__MODULE_IMPORT(OPP);
	__MODULE_IMPORT(OPT);
	__MODULE_IMPORT(OPV);
	__MODULE_IMPORT(Platform);
	__MODULE_IMPORT(Strings);
	__MODULE_IMPORT(VT100);
	__MODULE_IMPORT(extTools);
	__REGMAIN("Compiler", 0);
	__REGCMD("Abort", Compiler_Abort);
	__REGCMD("Translate", Compiler_Translate);
/* BEGIN */
	if (Compiler_Standalone()) {
		Platform_SetInterruptHandler(Compiler_Trap);
		Platform_SetQuitHandler(Compiler_Trap);
		Platform_SetBadInstructionHandler(Compiler_Trap);
		Compiler_Translate();
	}
	__FINI;
}
