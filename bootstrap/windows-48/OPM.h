/* voc 1.95 [2016/09/15] for gcc LP64 on cygwin xtspkaSfF */

#ifndef OPM__h
#define OPM__h

#include "SYSTEM.h"


import int16 OPM_Alignment, OPM_ByteSize, OPM_CharSize, OPM_BoolSize, OPM_SIntSize, OPM_IntSize, OPM_LIntSize, OPM_SetSize, OPM_RealSize, OPM_LRealSize, OPM_PointerSize, OPM_ProcSize, OPM_RecSize, OPM_MaxSet;
import int32 OPM_MaxIndex;
import LONGREAL OPM_MinReal, OPM_MaxReal, OPM_MinLReal, OPM_MaxLReal;
import BOOLEAN OPM_noerr;
import int32 OPM_curpos, OPM_errpos, OPM_breakpc;
import int16 OPM_currFile, OPM_level, OPM_pc, OPM_entno;
import CHAR OPM_modName[32];
import CHAR OPM_objname[64];
import SET OPM_opt, OPM_glbopt;
import BOOLEAN OPM_dontAsm, OPM_dontLink, OPM_mainProg, OPM_mainLinkStat, OPM_notColorOutput, OPM_forceNewSym, OPM_Verbose;


import void OPM_CloseFiles (void);
import void OPM_CloseOldSym (void);
import void OPM_DeleteNewSym (void);
import void OPM_FPrint (int32 *fp, int32 val);
import void OPM_FPrintLReal (int32 *fp, LONGREAL lr);
import void OPM_FPrintReal (int32 *fp, REAL real);
import void OPM_FPrintSet (int32 *fp, SET set);
import void OPM_Get (CHAR *ch);
import void OPM_Init (BOOLEAN *done, CHAR *mname, LONGINT mname__len);
import void OPM_InitOptions (void);
import void OPM_LogW (CHAR ch);
import void OPM_LogWLn (void);
import void OPM_LogWNum (int32 i, int32 len);
import void OPM_LogWStr (CHAR *s, LONGINT s__len);
import void OPM_Mark (int16 n, int32 pos);
import void OPM_NewSym (CHAR *modName, LONGINT modName__len);
import void OPM_OldSym (CHAR *modName, LONGINT modName__len, BOOLEAN *done);
import void OPM_OpenFiles (CHAR *moduleName, LONGINT moduleName__len);
import BOOLEAN OPM_OpenPar (void);
import void OPM_RegisterNewSym (void);
import int32 OPM_SignedMaximum (int32 bytecount);
import int32 OPM_SignedMinimum (int32 bytecount);
import void OPM_SymRCh (CHAR *ch);
import int32 OPM_SymRInt (void);
import void OPM_SymRLReal (LONGREAL *lr);
import void OPM_SymRReal (REAL *r);
import void OPM_SymRSet (SET *s);
import void OPM_SymWCh (CHAR ch);
import void OPM_SymWInt (int32 i);
import void OPM_SymWLReal (LONGREAL lr);
import void OPM_SymWReal (REAL r);
import void OPM_SymWSet (SET s);
import void OPM_Write (CHAR ch);
import void OPM_WriteHex (int32 i);
import void OPM_WriteInt (int32 i);
import void OPM_WriteLn (void);
import void OPM_WriteReal (LONGREAL r, CHAR suffx);
import void OPM_WriteString (CHAR *s, LONGINT s__len);
import void OPM_WriteStringVar (CHAR *s, LONGINT s__len);
import BOOLEAN OPM_eofSF (void);
import void OPM_err (int16 n);
import void *OPM__init(void);


#endif // OPM
