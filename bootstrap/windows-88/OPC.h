/* voc 1.95 [2016/08/20] for gcc LP64 on cygwin xtspkaSfF */

#ifndef OPC__h
#define OPC__h

#define LARGE
#include "SYSTEM.h"
#include "OPT.h"




import void OPC_Align (LONGINT *adr, LONGINT base);
import void OPC_Andent (OPT_Struct typ);
import LONGINT OPC_Base (OPT_Struct typ);
import OPT_Object OPC_BaseTProc (OPT_Object obj);
import void OPC_BegBlk (void);
import void OPC_BegStat (void);
import void OPC_Case (LONGINT caseVal, INTEGER form);
import void OPC_Cmp (INTEGER rel);
import void OPC_CompleteIdent (OPT_Object obj);
import void OPC_Constant (OPT_Const con, INTEGER form);
import void OPC_DefineInter (OPT_Object proc);
import void OPC_EndBlk (void);
import void OPC_EndBlk0 (void);
import void OPC_EndStat (void);
import void OPC_EnterBody (void);
import void OPC_EnterProc (OPT_Object proc);
import void OPC_ExitBody (void);
import void OPC_ExitProc (OPT_Object proc, BOOLEAN eoBlock, BOOLEAN implicitRet);
import void OPC_GenBdy (OPT_Node n);
import void OPC_GenEnumPtrs (OPT_Object var);
import void OPC_GenHdr (OPT_Node n);
import void OPC_GenHdrIncludes (void);
import void OPC_Halt (LONGINT n);
import void OPC_Ident (OPT_Object obj);
import void OPC_Increment (BOOLEAN decrement);
import void OPC_Indent (INTEGER count);
import void OPC_Init (void);
import void OPC_InitTDesc (OPT_Struct typ);
import void OPC_Len (OPT_Object obj, OPT_Struct array, LONGINT dim);
import LONGINT OPC_NofPtrs (OPT_Struct typ);
import void OPC_SetInclude (BOOLEAN exclude);
import void OPC_TDescDecl (OPT_Struct typ);
import void OPC_TypeDefs (OPT_Object obj, INTEGER vis);
import void OPC_TypeOf (OPT_Object ap);
import void *OPC__init(void);


#endif
