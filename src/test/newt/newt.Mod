MODULE newt;

IMPORT SYSTEM;

TYPE Int32* = INTEGER;
     Int64* = LONGINT;

PROCEDURE -Init*(): Int32
   "newtInit()";

PROCEDURE -Cls*()
   "newtCls()";

PROCEDURE -Finished*() : Int32
   "newtFinished()";

PROCEDURE -ResizeScreen*(redraw: Int32)
   "newtResizeScreen(redraw)";

PROCEDURE -WaitForKey*()
   "newtWaitForKey()";

PROCEDURE -ClearKeyBuffer*()
   "newtClearKeyBuffer()";

PROCEDURE -Delay*(i : Int32)
   "newtDelay(i)";

PROCEDURE -DrawRootText*(left, top: Int32; VAR text: ARRAY OF CHAR)
   "newtDrawRootText(left, top, text)";

PROCEDURE -PushHelpLine*(VAR text: ARRAY OF CHAR)
   "newtPushHelpLine(text)";

PROCEDURE -PopHelpLine*()
   "newtPopHelpLine()";

BEGIN




END newt.
