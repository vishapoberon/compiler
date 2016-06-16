MODULE Oberon;

(* this version should not have dependency on graphics -- noch *)

  IMPORT Platform, Texts, Args, Console;

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
    R:    Texts.Reader;
    W:    Texts.Writer;
    OptionChar*: CHAR;

  (*clocks*)

  PROCEDURE GetClock* (VAR t, d: LONGINT);
  BEGIN Platform.GetClock(t, d)
  END GetClock;

  PROCEDURE Time* (): LONGINT;
  BEGIN
     RETURN Platform.Time()
  END Time;

  PROCEDURE PopulateParams;
  VAR
    W:   Texts.Writer;
    i:   INTEGER;
    str: ARRAY 32 OF CHAR;
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

  PROCEDURE GetSelection*(VAR text: Texts.Text; VAR beg, end, time: LONGINT);
  BEGIN text := NIL; beg := 0; end := 0; time := 0;
  END GetSelection;

(* --- Notifier for echoing all text appended to the log onto the console. --- *)

PROCEDURE LogNotifier(Log: Texts.Text; op: INTEGER; beg, end: LONGINT);
  VAR ch: CHAR;
BEGIN
  Texts.OpenReader(R, Log, beg);
  WHILE ~R.eot & (beg < end) DO
    Texts.Read(R, ch);
    IF ch = 0DX THEN Console.Ln ELSE Console.Char(ch) END;
    INC(beg)
  END
END LogNotifier;

BEGIN
   NEW(Par);
   NEW(Par.text);
   Par.pos := 0;
   OptionChar := '-';
   Texts.Open(Par.text, "");
   PopulateParams;
   NEW(Log);
   Texts.Open(Log, "");
   Log.notify := LogNotifier;
END Oberon.
