/* voc 1.95 [2016/08/26] for gcc LP64 on cygwin xtspkaSfF */

#ifndef OPM__h
#define OPM__h

#include "SYSTEM.h"


import INTEGER OPM_Alignment, OPM_ByteSize, OPM_CharSize, OPM_BoolSize, OPM_SIntSize, OPM_IntSize, OPM_LIntSize, OPM_SetSize, OPM_RealSize, OPM_LRealSize, OPM_PointerSize, OPM_ProcSize, OPM_RecSize, OPM_MaxSet;
import LONGINT OPM_MaxIndex;
import LONGREAL OPM_MinReal, OPM_MaxReal, OPM_MinLReal, OPM_MaxLReal;
import BOOLEAN OPM_noerr;
import LONGINT OPM_curpos, OPM_errpos, OPM_breakpc;
import INTEGER OPM_currFile, OPM_level, OPM_pc, OPM_entno;
import CHAR OPM_modName[32];
import CHAR OPM_objname[64];
import SET OPM_opt, OPM_glbopt;
import BOOLEAN OPM_dontAsm, OPM_dontLink, OPM_mainProg, OPM_mainLinkStat, OPM_notColorOutput, OPM_forceNewSym, OPM_Verbose;


import void OPM_CloseFiles (void);
import void OPM_CloseOldSym (void);
import void OPM_DeleteNewSym (void);
import void OPM_FPrint (LONGINT *fp, LONGINT val);
import void OPM_FPrintLReal (LONGINT *fp, LONGREAL lr);
import void OPM_FPrintReal (LONGINT *fp, REAL real);
import void OPM_FPrintSet (LONGINT *fp, SET set);
import void OPM_Get (CHAR *ch);
import void OPM_Init (BOOLEAN *done, CHAR *mname, LONGINT mname__len);
import void OPM_InitOptions (void);
import void OPM_LogW (CHAR ch);
import void OPM_LogWLn (void);
import void OPM_LogWNum (LONGINT i, LONGINT len);
import void OPM_LogWStr (CHAR *s, LONGINT s__len);
import void OPM_Mark (INTEGER n, LONGINT pos);
import void OPM_NewSym (CHAR *modName, LONGINT modName__len);
import void OPM_OldSym (CHAR *modName, LONGINT modName__len, BOOLEAN *done);
import void OPM_OpenFiles (CHAR *moduleName, LONGINT moduleName__len);
import BOOLEAN OPM_OpenPar (void);
import void OPM_RegisterNewSym (void);
import LONGINT OPM_SignedMaximum (LONGINT bytecount);
import LONGINT OPM_SignedMinimum (LONGINT bytecount);
import void OPM_SymRCh (CHAR *ch);
import LONGINT OPM_SymRInt (void);
import void OPM_SymRLReal (LONGREAL *lr);
import void OPM_SymRReal (REAL *r);
import void OPM_SymRSet (SET *s);
import void OPM_SymWCh (CHAR ch);
import void OPM_SymWInt (LONGINT i);
import void OPM_SymWLReal (LONGREAL lr);
import void OPM_SymWReal (REAL r);
import void OPM_SymWSet (SET s);
import void OPM_Write (CHAR ch);
import void OPM_WriteHex (LONGINT i);
import void OPM_WriteInt (LONGINT i);
import void OPM_WriteLn (void);
import void OPM_WriteReal (LONGREAL r, CHAR suffx);
import void OPM_WriteString (CHAR *s, LONGINT s__len);
import void OPM_WriteStringVar (CHAR *s, LONGINT s__len);
import BOOLEAN OPM_eofSF (void);
import void OPM_err (INTEGER n);
import void *OPM__init(void);


#endif
