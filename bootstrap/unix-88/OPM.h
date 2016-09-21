/* voc 1.95 [2016/09/21] for gcc LP64 on cygwin xtspaSfF */

#ifndef OPM__h
#define OPM__h

#include "SYSTEM.h"


import int32 OPM_Alignment, OPM_AddressSize, OPM_SetSize, OPM_ShortintSize, OPM_IntegerSize, OPM_LongintSize, OPM_MaxSet;
import int64 OPM_MaxIndex;
import LONGREAL OPM_MinReal, OPM_MaxReal, OPM_MinLReal, OPM_MaxLReal;
import BOOLEAN OPM_noerr;
import int64 OPM_curpos, OPM_errpos, OPM_breakpc;
import int32 OPM_currFile, OPM_level, OPM_pc, OPM_entno;
import CHAR OPM_modName[32];
import CHAR OPM_objname[64];
import SET OPM_opt, OPM_glbopt;


import void OPM_CloseFiles (void);
import void OPM_CloseOldSym (void);
import void OPM_DeleteNewSym (void);
import void OPM_FPrint (int64 *fp, int64 val);
import void OPM_FPrintLReal (int64 *fp, LONGREAL lr);
import void OPM_FPrintReal (int64 *fp, REAL real);
import void OPM_FPrintSet (int64 *fp, SET set);
import void OPM_Get (CHAR *ch);
import void OPM_Init (BOOLEAN *done, CHAR *mname, LONGINT mname__len);
import void OPM_InitOptions (void);
import int32 OPM_Integer (int64 n);
import void OPM_LogW (CHAR ch);
import void OPM_LogWLn (void);
import void OPM_LogWNum (int64 i, int64 len);
import void OPM_LogWStr (CHAR *s, LONGINT s__len);
import int64 OPM_Longint (int64 n);
import void OPM_Mark (int32 n, int64 pos);
import void OPM_NewSym (CHAR *modName, LONGINT modName__len);
import void OPM_OldSym (CHAR *modName, LONGINT modName__len, BOOLEAN *done);
import void OPM_OpenFiles (CHAR *moduleName, LONGINT moduleName__len);
import BOOLEAN OPM_OpenPar (void);
import void OPM_RegisterNewSym (void);
import int64 OPM_SignedMaximum (int64 bytecount);
import int64 OPM_SignedMinimum (int64 bytecount);
import void OPM_SymRCh (CHAR *ch);
import int64 OPM_SymRInt (void);
import int64 OPM_SymRInt64 (void);
import void OPM_SymRLReal (LONGREAL *lr);
import void OPM_SymRReal (REAL *r);
import void OPM_SymRSet (SET *s);
import void OPM_SymWCh (CHAR ch);
import void OPM_SymWInt (int64 i);
import void OPM_SymWLReal (LONGREAL lr);
import void OPM_SymWReal (REAL r);
import void OPM_SymWSet (SET s);
import void OPM_Write (CHAR ch);
import void OPM_WriteHex (int64 i);
import void OPM_WriteInt (int64 i);
import void OPM_WriteLn (void);
import void OPM_WriteReal (LONGREAL r, CHAR suffx);
import void OPM_WriteString (CHAR *s, LONGINT s__len);
import void OPM_WriteStringVar (CHAR *s, LONGINT s__len);
import BOOLEAN OPM_eofSF (void);
import void OPM_err (int32 n);
import void *OPM__init(void);


#endif // OPM
