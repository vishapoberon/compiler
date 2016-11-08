/* voc 1.95 [2016/11/08]. Bootstrapping compiler for address size 8, alignment 8. xtspamSf */

#define SHORTINT INT8
#define INTEGER  INT16
#define LONGINT  INT32
#define SET      UINT32

#include "SYSTEM.h"
#include "Configuration.h"
#include "Heap.h"
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


static CHAR Compiler_mname[256];


export void Compiler_Module (BOOLEAN *done);
static void Compiler_PropagateElementaryTypeSizes (void);
export void Compiler_Translate (void);
static void Compiler_Trap (INT32 sig);


void Compiler_Module (BOOLEAN *done)
{
	BOOLEAN ext, new;
	OPT_Node p = NIL;
	OPP_Module(&p, OPM_Options);
	if (OPM_noerr) {
		OPV_Init();
		OPT_InitRecno();
		OPV_AdrAndSize(OPT_topScope);
		OPT_Export(&ext, &new);
		if (OPM_noerr) {
			OPM_OpenFiles((void*)OPT_SelfName, 256);
			OPC_Init();
			OPV_Module(p);
			if (OPM_noerr) {
				if ((__IN(10, OPM_Options, 32) && __STRCMP(OPM_modName, "SYSTEM") != 0)) {
					OPM_DeleteNewSym();
					if (!__IN(16, OPM_Options, 32)) {
						VT100_SetAttr((CHAR*)"32m", 4);
					}
					OPM_LogWStr((CHAR*)"  Main program.", 16);
					if (!__IN(16, OPM_Options, 32)) {
						VT100_SetAttr((CHAR*)"0m", 3);
					}
				} else {
					if (new) {
						if (!__IN(16, OPM_Options, 32)) {
							VT100_SetAttr((CHAR*)"32m", 4);
						}
						OPM_LogWStr((CHAR*)"  New symbol file.", 19);
						if (!__IN(16, OPM_Options, 32)) {
							VT100_SetAttr((CHAR*)"0m", 3);
						}
						OPM_RegisterNewSym();
					} else if (ext) {
						OPM_LogWStr((CHAR*)"  Extended symbol file.", 24);
						OPM_RegisterNewSym();
					}
				}
			} else {
				OPM_DeleteNewSym();
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
	OPT_adrtyp->size = OPM_AddressSize;
	adrinttyp = OPT_IntType(OPM_AddressSize);
	OPT_adrtyp->strobj = adrinttyp->strobj;
	OPT_sinttyp = OPT_IntType(OPM_ShortintSize);
	OPT_inttyp = OPT_IntType(OPM_IntegerSize);
	OPT_linttyp = OPT_IntType(OPM_LongintSize);
	OPT_sintobj->typ = OPT_sinttyp;
	OPT_intobj->typ = OPT_inttyp;
	OPT_lintobj->typ = OPT_linttyp;
	switch (OPM_LongintSize) {
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

void Compiler_Translate (void)
{
	BOOLEAN done;
	CHAR modulesobj[2048];
	modulesobj[0] = 0x00;
	if (OPM_OpenPar()) {
		for (;;) {
			OPM_Init(&done, (void*)Compiler_mname, 256);
			if (!done) {
				return;
			}
			OPM_InitOptions();
			Compiler_PropagateElementaryTypeSizes();
			Heap_GC(0);
			Compiler_Module(&done);
			if (!done) {
				OPM_LogWLn();
				OPM_LogWStr((CHAR*)"Module compilation failed.", 27);
				OPM_LogWLn();
				Platform_Exit(1);
			}
			if (!__IN(13, OPM_Options, 32)) {
				if (__IN(14, OPM_Options, 32)) {
					extTools_Assemble(OPM_modName, 32);
				} else {
					if (!__IN(10, OPM_Options, 32)) {
						extTools_Assemble(OPM_modName, 32);
						Strings_Append((CHAR*)" ", 2, (void*)modulesobj, 2048);
						Strings_Append(OPM_modName, 32, (void*)modulesobj, 2048);
						Strings_Append((CHAR*)".o", 3, (void*)modulesobj, 2048);
					} else {
						extTools_LinkMain((void*)OPM_modName, 32, __IN(15, OPM_Options, 32), modulesobj, 2048);
					}
				}
			}
		}
	}
}

static void Compiler_Trap (INT32 sig)
{
	Heap_FINALL();
	if (sig == 3) {
		Platform_Exit(0);
	} else {
		if ((sig == 4 && Platform_HaltCode == -15)) {
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
	__REGCMD("Translate", Compiler_Translate);
/* BEGIN */
	Platform_SetInterruptHandler(Compiler_Trap);
	Platform_SetQuitHandler(Compiler_Trap);
	Platform_SetBadInstructionHandler(Compiler_Trap);
	Compiler_Translate();
	__FINI;
}
