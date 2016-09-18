/* voc 1.95 [2016/09/18] for gcc LP64 on cygwin xtspkamSf */

#define INTEGER int32
#define LONGINT int64
#define SET     uint64

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
#include "extTools.h"
#include "vt100.h"


static CHAR Vishap_mname[256];


export void Vishap_Module (BOOLEAN *done);
static void Vishap_PropagateElementaryTypeSizes (void);
export void Vishap_Translate (void);
static void Vishap_Trap (int32 sig);


void Vishap_Module (BOOLEAN *done)
{
	BOOLEAN ext, new;
	OPT_Node p = NIL;
	OPP_Module(&p, OPM_opt);
	if (OPM_noerr) {
		OPV_Init();
		OPV_AdrAndSize(OPT_topScope);
		OPT_Export(&ext, &new);
		if (OPM_noerr) {
			OPM_OpenFiles((void*)OPT_SelfName, 256);
			OPC_Init();
			OPV_Module(p);
			if (OPM_noerr) {
				if (((OPM_mainProg || OPM_mainLinkStat) && __STRCMP(OPM_modName, "SYSTEM") != 0)) {
					OPM_DeleteNewSym();
					if (!OPM_notColorOutput) {
						vt100_SetAttr((CHAR*)"32m", 4);
					}
					OPM_LogWStr((CHAR*)"  Main program.", 16);
					if (!OPM_notColorOutput) {
						vt100_SetAttr((CHAR*)"0m", 3);
					}
				} else {
					if (new) {
						if (!OPM_notColorOutput) {
							vt100_SetAttr((CHAR*)"32m", 4);
						}
						OPM_LogWStr((CHAR*)"  New symbol file.", 19);
						if (!OPM_notColorOutput) {
							vt100_SetAttr((CHAR*)"0m", 3);
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

static void Vishap_PropagateElementaryTypeSizes (void)
{
	OPT_bytetyp->size = OPM_ByteSize;
	OPT_sysptrtyp->size = OPM_PointerSize;
	OPT_chartyp->size = OPM_CharSize;
	OPT_settyp->size = OPM_SetSize;
	OPT_realtyp->size = OPM_RealSize;
	OPT_adrtyp->size = OPM_PointerSize;
	OPT_lrltyp->size = OPM_LRealSize;
	OPT_booltyp->size = OPM_BoolSize;
	OPT_sinttyp = OPT_int8typ;
	if (OPM_IntSize == 2) {
		OPT_inttyp = OPT_int16typ;
		OPT_linttyp = OPT_int32typ;
	} else {
		OPT_inttyp = OPT_int32typ;
		OPT_linttyp = OPT_int64typ;
	}
	OPT_sintobj->typ = OPT_sinttyp;
	OPT_intobj->typ = OPT_inttyp;
	OPT_lintobj->typ = OPT_linttyp;
}

void Vishap_Translate (void)
{
	BOOLEAN done;
	CHAR modulesobj[2048];
	modulesobj[0] = 0x00;
	if (OPM_OpenPar()) {
		for (;;) {
			OPM_Init(&done, (void*)Vishap_mname, 256);
			if (!done) {
				return;
			}
			OPM_InitOptions();
			Vishap_PropagateElementaryTypeSizes();
			Heap_GC(0);
			Vishap_Module(&done);
			if (!done) {
				OPM_LogWLn();
				OPM_LogWStr((CHAR*)"Module compilation failed.", 27);
				OPM_LogWLn();
				Platform_Exit(1);
			}
			if (!OPM_dontAsm) {
				if (OPM_dontLink) {
					extTools_Assemble(OPM_modName, 32);
				} else {
					if (!(OPM_mainProg || OPM_mainLinkStat)) {
						extTools_Assemble(OPM_modName, 32);
						Strings_Append((CHAR*)" ", 2, (void*)modulesobj, 2048);
						Strings_Append(OPM_modName, 32, (void*)modulesobj, 2048);
						Strings_Append((CHAR*)".o", 3, (void*)modulesobj, 2048);
					} else {
						extTools_LinkMain((void*)OPM_modName, 32, OPM_mainLinkStat, modulesobj, 2048);
					}
				}
			}
		}
	}
}

static void Vishap_Trap (int32 sig)
{
	Heap_FINALL();
	if (sig == 3) {
		Platform_Exit(0);
	} else {
		if ((sig == 4 && Platform_HaltCode == -15)) {
			OPM_LogWStr((CHAR*)" --- Vishap Oberon: internal error", 35);
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
	__MODULE_IMPORT(extTools);
	__MODULE_IMPORT(vt100);
	__REGMAIN("Vishap", 0);
	__REGCMD("Translate", Vishap_Translate);
/* BEGIN */
	Platform_SetInterruptHandler(Vishap_Trap);
	Platform_SetQuitHandler(Vishap_Trap);
	Platform_SetBadInstructionHandler(Vishap_Trap);
	OPB_typSize = OPV_TypSize;
	OPT_typSize = OPV_TypSize;
	Vishap_Translate();
	__FINI;
}
