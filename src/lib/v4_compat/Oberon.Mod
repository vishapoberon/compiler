MODULE Oberon;

(* this version should not have dependency on graphics -- noch *)

  IMPORT Kernel, Texts, Args;
  TYPE

    ParList* = POINTER TO ParRec;

    ParRec* = RECORD
    (*  vwr*: Viewers.Viewer;
      frame*: Display.Frame;*)
      text*: Texts.Text;
      pos*: LONGINT
    END;

  VAR

    Log*: Texts.Text;
    Par*: ParList; (*actual parameters*)
    W : Texts.Writer;
	OptionChar*: CHAR;
  (*clocks*)

  PROCEDURE GetClock* (VAR t, d: LONGINT);
  BEGIN Kernel.GetClock(t, d)
  END GetClock;

  PROCEDURE Time* (): LONGINT;
  BEGIN 
     RETURN Kernel.Time()
  END Time;

  PROCEDURE PopulateParams;
  VAR W : Texts.Writer;
  i : INTEGER;
  str : ARRAY 32 OF CHAR;
  BEGIN

    i := 1; (* skip program name *)
    Texts.OpenWriter(W);

    REPEAT
    IF i < Args.argc THEN
       Args.Get(i, str);
       Texts.WriteString(W, str);
       Texts.WriteString(W, " ");
    END;
    INC(i)
    UNTIL i >= Args.argc;

    Texts.Append (Par^.text, W.buf);

  END PopulateParams;

BEGIN
   NEW(Par);
   NEW(Par.text);
   Par.pos := 0;
   OptionChar := '-';
   Texts.Open(Par.text, "");
   PopulateParams;
END Oberon.
