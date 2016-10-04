/* voc 1.95 [2016/10/04]. Bootstrapping compiler for address size 8, alignment 8. xtspaSfF */

#ifndef OPM__h
#define OPM__h

#include "SYSTEM.h"


import CHAR OPM_Model[10];
import int16 OPM_AddressSize, OPM_Alignment;
import uint32 OPM_GlobalOptions, OPM_Options;
import int16 OPM_ShortintSize, OPM_IntegerSize, OPM_LongintSize, OPM_SetSize;
import int64 OPM_MaxIndex;
import LONGREAL OPM_MinReal, OPM_MaxReal, OPM_MinLReal, OPM_MaxLReal;
import BOOLEAN OPM_noerr;
import int32 OPM_curpos, OPM_errpos, OPM_breakpc;
import int16 OPM_currFile, OPM_level, OPM_pc, OPM_entno;
import CHAR OPM_modName[32];
import CHAR OPM_objname[64];
import CHAR OPM_ResourceDir[1024];


import void OPM_CloseFiles (void);
import void OPM_CloseOldSym (void);
import void OPM_DeleteNewSym (void);
import void OPM_FPrint (int32 *fp, int64 val);
import void OPM_FPrintLReal (int32 *fp, LONGREAL lr);
import void OPM_FPrintReal (int32 *fp, REAL real);
import void OPM_FPrintSet (int32 *fp, uint64 set);
import void OPM_Get (CHAR *ch);
import void OPM_Init (BOOLEAN *done, CHAR *mname, LONGINT mname__len);
import void OPM_InitOptions (void);
import int16 OPM_Integer (int64 n);
import void OPM_LogW (CHAR ch);
import void OPM_LogWLn (void);
import void OPM_LogWNum (int64 i, int64 len);
import void OPM_LogWStr (CHAR *s, LONGINT s__len);
import int32 OPM_Longint (int64 n);
import void OPM_Mark (int16 n, int32 pos);
import void OPM_NewSym (CHAR *modName, LONGINT modName__len);
import void OPM_OldSym (CHAR *modName, LONGINT modName__len, BOOLEAN *done);
import void OPM_OpenFiles (CHAR *moduleName, LONGINT moduleName__len);
import BOOLEAN OPM_OpenPar (void);
import void OPM_RegisterNewSym (void);
import int64 OPM_SignedMaximum (int32 bytecount);
import int64 OPM_SignedMinimum (int32 bytecount);
import void OPM_SymRCh (CHAR *ch);
import int32 OPM_SymRInt (void);
import int64 OPM_SymRInt64 (void);
import void OPM_SymRLReal (LONGREAL *lr);
import void OPM_SymRReal (REAL *r);
import void OPM_SymRSet (uint64 *s);
import void OPM_SymWCh (CHAR ch);
import void OPM_SymWInt (int64 i);
import void OPM_SymWLReal (LONGREAL lr);
import void OPM_SymWReal (REAL r);
import void OPM_SymWSet (uint64 s);
import void OPM_Write (CHAR ch);
import void OPM_WriteHex (int64 i);
import void OPM_WriteInt (int64 i);
import void OPM_WriteLn (void);
import void OPM_WriteReal (LONGREAL r, CHAR suffx);
import void OPM_WriteString (CHAR *s, LONGINT s__len);
import void OPM_WriteStringVar (CHAR *s, LONGINT s__len);
import BOOLEAN OPM_eofSF (void);
import void OPM_err (int16 n);
import void *OPM__init(void);


#endif // OPM
