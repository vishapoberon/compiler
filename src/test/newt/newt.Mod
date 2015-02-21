MODULE newt;

IMPORT SYSTEM;

CONST

NEWTvCOLORSETvROOT *=			2;
NEWTvCOLORSETvBORDER *=			3;
NEWTvCOLORSETvWINDOW*=			4;
NEWTvCOLORSETvSHADOW*=			5;
NEWTvCOLORSETvTITLE*=			6;
NEWTvCOLORSETvBUTTON*=			7;
NEWTvCOLORSETvACTBUTTON*=		8;
NEWTvCOLORSETvCHECKBOX*=		9;
NEWTvCOLORSETvACTCHECKBOX*=		10;
NEWTvCOLORSETvENTRY*=			11;
NEWTvCOLORSETvLABEL*=			12;
NEWTvCOLORSETvLISTBOX*=			13;
NEWTvCOLORSETvACTLISTBOX*=		14;
NEWTvCOLORSETvTEXTBOX*=			15;
NEWTvCOLORSETvACTTEXTBOX*=		16;
NEWTvCOLORSETvHELPLINE*=		17;
NEWTvCOLORSETvROOTTEXT*=		18;
NEWTvCOLORSETvEMPTYSCALE*=		19;
NEWTvCOLORSETvFULLSCALE*=		20;
NEWTvCOLORSETvDISENTRY*=		21;
NEWTvCOLORSETvCOMPACTBUTTON*=		22;
NEWTvCOLORSETvACTSELLISTBOX*=		23;
NEWTvCOLORSETvSELLISTBOX*=		24;

NEWTvARGvLAST*=				-100000;
NEWTvARGvAPPEND*=			-1;


TYPE Int32* = INTEGER;
     Int64* = LONGINT;

PROCEDURE -newtInit(): Int32
   "newtInit()";

PROCEDURE Init*(): Int32;
BEGIN
   RETURN newtInit();
END Init;

PROCEDURE -newtCls()
   "newtCls()";

PROCEDURE Cls*();
BEGIN
   newtCls
END Cls;

PROCEDURE -newtFinished() : Int32
   "newtFinished()";

PROCEDURE Finished*(): Int32;
BEGIN
   RETURN newtFinished();
END Finished;

PROCEDURE -newtResizeScreen(redraw: Int32)
   "newtResizeScreen(redraw)";

PROCEDURE ResizeScreen*(redraw : Int32);
BEGIN
   newtResizeScreen(redraw);
END ResizeScreen;

PROCEDURE -newtRefresh()
   "newtRefresh()";

PROCEDURE Refresh*();
BEGIN
   newtRefresh();
END Refresh;

PROCEDURE -newtWaitForKey()
   "newtWaitForKey()";

PROCEDURE WaitForKey*();
BEGIN
   newtWaitForKey
END WaitForKey;

PROCEDURE -newtClearKeyBuffer()
   "newtClearKeyBuffer()";

PROCEDURE ClearKeyBuffer*();
BEGIN
   newtClearKeyBuffer
END ClearKeyBuffer;

PROCEDURE -newtDelay(i : Int32)
   "newtDelay(i)";

PROCEDURE Delay*(i : Int32);
BEGIN
   newtDelay(i)
END Delay;

PROCEDURE -newtDrawRootText(left, top: Int32; VAR text: ARRAY OF CHAR)
   "newtDrawRootText(left, top, text)";

PROCEDURE DrawRootText*(left, top: Int32; text: ARRAY OF CHAR);
BEGIN
   newtDrawRootText(left, top, text)
END DrawRootText;

PROCEDURE -newtPushHelpLine(VAR text: ARRAY OF CHAR)
   "newtPushHelpLine(text)";

PROCEDURE PushHelpLine*(text : ARRAY OF CHAR);
BEGIN
   newtPushHelpLine(text)
END PushHelpLine;

PROCEDURE -newtPopHelpLine()
   "newtPopHelpLine()";

PROCEDURE PopHelpLine*();
BEGIN
   newtPopHelpLine();
END PopHelpLine;

PROCEDURE -newtBell()
   "newtBell()";

PROCEDURE Bell*();
BEGIN newtBell() END Bell;

PROCEDURE -newtGetScreenSize(VAR cols, rows: Int32)
   "newtGetScreenSize(cols, rows)";

PROCEDURE GetScreenSize*(VAR cols, rows: Int32);
BEGIN 
newtGetScreenSize(cols, rows)
END GetScreenSize;

BEGIN




END newt.
