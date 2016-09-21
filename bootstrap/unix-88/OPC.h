/* voc 1.95 [2016/09/21] for gcc LP64 on cygwin xtspkaSfF */

#ifndef OPC__h
#define OPC__h

#include "SYSTEM.h"
#include "OPT.h"




import void OPC_Align (int64 *adr, int64 base);
import void OPC_Andent (OPT_Struct typ);
import int64 OPC_BaseAlignment (OPT_Struct typ);
import OPT_Object OPC_BaseTProc (OPT_Object obj);
import void OPC_BegBlk (void);
import void OPC_BegStat (void);
import void OPC_Case (int64 caseVal, int32 form);
import void OPC_Cmp (int32 rel);
import void OPC_CompleteIdent (OPT_Object obj);
import void OPC_Constant (OPT_Const con, int32 form);
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
import void OPC_Halt (int64 n);
import void OPC_Ident (OPT_Object obj);
import void OPC_Increment (BOOLEAN decrement);
import void OPC_Indent (int32 count);
import void OPC_Init (void);
import void OPC_InitTDesc (OPT_Struct typ);
import void OPC_IntLiteral (int64 n, int64 size);
import void OPC_Len (OPT_Object obj, OPT_Struct array, int64 dim);
import int64 OPC_NofPtrs (OPT_Struct typ);
import void OPC_SetInclude (BOOLEAN exclude);
import int64 OPC_SizeAlignment (int64 size);
import void OPC_TDescDecl (OPT_Struct typ);
import void OPC_TypeDefs (OPT_Object obj, int32 vis);
import void OPC_TypeOf (OPT_Object ap);
import void *OPC__init(void);


#endif // OPC
