MODULE Oberon; (*JG 6.9.90 / 23.9.93*)

  IMPORT SYSTEM, Unix, Kernel, Modules, Input, Display, Fonts, Viewers, Texts, X11;  (* << *)

  CONST

    (*message ids*)
    consume* = 0; track* = 1;
    defocus* = 0; neutralize* = 1; mark* = 2;

    BasicCycle = 20;

    ESC = 1BX; SETUP = 0A4X;

  TYPE

    Painter* = PROCEDURE (x, y: INTEGER);
    Marker* = RECORD Fade*, Draw*: Painter END;
    
    Cursor* = RECORD
        marker*: Marker; on*: BOOLEAN; X*, Y*: INTEGER
    END;

    ParList* = POINTER TO ParRec;

    ParRec* = RECORD
      vwr*: Viewers.Viewer;
      frame*: Display.Frame;
      text*: Texts.Text;
      pos*: LONGINT
    END;

    InputMsg* = RECORD (Display.FrameMsg)
      id*: INTEGER;
      keys*: SET;
      X*, Y*: INTEGER;
      ch*: CHAR;
      fnt*: Fonts.Font;
      col*, voff*: SHORTINT
    END;

    SelectionMsg* = RECORD (Display.FrameMsg)
      time*: LONGINT;
      text*: Texts.Text;
      beg*, end*: LONGINT
    END;

    ControlMsg* = RECORD (Display.FrameMsg)
      id*, X*, Y*: INTEGER
    END;

    CopyOverMsg* = RECORD (Display.FrameMsg)
      text*: Texts.Text;
      beg*, end*: LONGINT
    END;

    CopyMsg* = RECORD (Display.FrameMsg)
      F*: Display.Frame
    END;

    Task* = POINTER TO TaskDesc;

    Handler* = PROCEDURE;

    TaskDesc* = RECORD
      next: Task;
      safe*: BOOLEAN;
      time*: LONGINT;
      handle*: Handler
    END;

  VAR
    User*: ARRAY 12 OF CHAR;  (* << *)

    Arrow*, Star*: Marker;
    Mouse*, Pointer*: Cursor;

    FocusViewer*: Viewers.Viewer;

    Log*: Texts.Text;
    Par*: ParList; (*actual parameters*)

    CurTask*, PrevTask: Task;

    CurFnt*: Fonts.Font; CurCol*, CurOff*: SHORTINT;
    Password*: LONGINT;

    DW, DH, CL, H0, H1, H2, H3: INTEGER;
    unitW: INTEGER;

    ActCnt: INTEGER; (*action count for GC*)
    Mod: Modules.Module;
    ArrowFade: Painter;  (* << *)

  (*user identification*)

  PROCEDURE Code(VAR s: ARRAY OF CHAR): LONGINT;
    VAR i: INTEGER; a, b, c: LONGINT;
  BEGIN
    a := 0; b := 0; i := 0;
    WHILE s[i] # 0X DO
      c := b; b := a; a := (c MOD 509 + 1) * 127 + ORD(s[i]);
      INC(i)
    END;
    IF b >= 32768 THEN b := b - 65536 END;
    RETURN b * 65536 + a
  END Code;

  PROCEDURE SetUser* (VAR user, password: ARRAY OF CHAR);
  BEGIN COPY(user, User); Password := Code(password)
  END SetUser;

  (*clocks*)

  PROCEDURE GetClock* (VAR t, d: LONGINT);
  BEGIN Kernel.GetClock(t, d)
  END GetClock;

  PROCEDURE SetClock* (t, d: LONGINT);
  BEGIN Kernel.SetClock(t, d)
  END SetClock;

  PROCEDURE Time* (): LONGINT;
  BEGIN RETURN Input.Time()
  END Time;

  (*cursor handling*)

  PROCEDURE FlipArrow (X, Y: INTEGER);  (* << *)
  END FlipArrow;

  PROCEDURE FlipStar (X, Y: INTEGER);
  BEGIN
    IF X < CL THEN
      IF X < 7 THEN X := 7 ELSIF X > DW - 8 THEN X := DW - 8 END
    ELSE
      IF X < CL + 7 THEN X := CL + 7 ELSIF X > CL + DW - 8 THEN X := CL + DW - 8 END
    END ;
    IF Y < 7 THEN Y := 7 ELSIF Y > DH - 8 THEN Y := DH - 8 END;
    Display.CopyPattern(Display.white, Display.star, X - 7, Y - 7, 2)
  END FlipStar;

  PROCEDURE OpenCursor* (VAR c: Cursor);
  BEGIN c.on := FALSE; c.X := 0; c.Y := 0
  END OpenCursor;
 
  PROCEDURE FadeCursor* (VAR c: Cursor);
  BEGIN IF c.on THEN c.marker.Fade(c.X, c.Y); c.on := FALSE END
  END FadeCursor;

  PROCEDURE DrawCursor* (VAR c: Cursor; VAR m: Marker; X, Y: INTEGER);                              (* << RC *)
  BEGIN
    IF c.on & ((X # c.X) OR (Y # c.Y) OR (m.Draw # c.marker.Draw)) THEN
      c.marker.Fade(c.X, c.Y); c.on := FALSE
    END;
    IF c.marker.Fade = ArrowFade THEN
      IF m.Fade # ArrowFade THEN X11.DefineCursor(X11.display, X11.primary, X11.noCursor) END
    ELSE
      IF m.Fade = ArrowFade THEN X11.DefineCursor(X11.display, X11.primary, X11.arrow) END
    END ;
    IF ~c.on THEN
      m.Draw(X, Y); c.marker := m; c.X := X; c.Y := Y; c.on := TRUE
    END
  END DrawCursor;

  (*display management*)

  PROCEDURE RemoveMarks* (X, Y, W, H: INTEGER);
  BEGIN
    IF (Mouse.X > X - 16) & (Mouse.X < X + W + 16) & (Mouse.Y > Y - 16) & (Mouse.Y < Y + H + 16) THEN
      FadeCursor(Mouse)
    END;
    IF (Pointer.X > X - 8) & (Pointer.X < X + W + 8) & (Pointer.Y > Y - 8) & (Pointer.Y < Y + H + 8) THEN
      FadeCursor(Pointer)
    END
  END RemoveMarks;

  PROCEDURE HandleFiller (V: Display.Frame; VAR M: Display.FrameMsg);
  BEGIN
    WITH V: Viewers.Viewer DO
      IF M IS InputMsg THEN
        WITH M: InputMsg DO
          IF M.id = track THEN DrawCursor(Mouse, Arrow, M.X, M.Y) END
        END;
      ELSIF M IS ControlMsg THEN
         WITH M: ControlMsg DO
           IF M.id = mark THEN DrawCursor(Pointer, Star, M.X, M.Y) END
         END
      ELSIF M IS Viewers.ViewerMsg THEN
        WITH M: Viewers.ViewerMsg DO
          IF (M.id = Viewers.restore) & (V.W > 0) & (V.H > 0) THEN
            RemoveMarks(V.X, V.Y, V.W, V.H);
            Display.ReplConst(Display.black, V.X, V.Y, V.W, V.H, 0)
          ELSIF (M.id = Viewers.modify) & (M.Y < V.Y) THEN
            RemoveMarks(V.X, M.Y, V.W, V.Y - M.Y);
            Display.ReplConst(Display.black, V.X, M.Y, V.W, V.Y - M.Y, 0)
          END
        END
      END
    END
  END HandleFiller;

  PROCEDURE OpenDisplay* (UW, SW, H: INTEGER);
    VAR Filler: Viewers.Viewer;
  BEGIN
     Input.SetMouseLimits(Viewers.curW + UW + SW, H);
     Display.ReplConst(Display.black, Viewers.curW, 0, UW + SW, H, 0);
     NEW(Filler); Filler.handle := HandleFiller;
     Viewers.InitTrack(UW, H, Filler); (*init user track*)
     NEW(Filler); Filler.handle := HandleFiller;
     Viewers.InitTrack(SW, H, Filler) (*init system track*)
  END OpenDisplay;

  PROCEDURE DisplayWidth* (X: INTEGER): INTEGER;
  BEGIN RETURN DW
  END DisplayWidth;

  PROCEDURE DisplayHeight* (X: INTEGER): INTEGER;
  BEGIN RETURN DH
  END DisplayHeight;

  PROCEDURE OpenTrack* (X, W: INTEGER);
    VAR Filler: Viewers.Viewer;
  BEGIN
    NEW(Filler); Filler.handle := HandleFiller;
    Viewers.OpenTrack(X, W, Filler)
  END OpenTrack;

  PROCEDURE UserTrack* (X: INTEGER): INTEGER;
  BEGIN RETURN X DIV DW * DW
  END UserTrack;

  PROCEDURE SystemTrack* (X: INTEGER): INTEGER;
  BEGIN RETURN X DIV DW * DW + DW DIV 8 * 5
  END SystemTrack;

  PROCEDURE UY (X: INTEGER): INTEGER;
    VAR fil, bot, alt, max: Display.Frame;
  BEGIN
    Viewers.Locate(X, 0, fil, bot, alt, max);
    IF fil.H >= DH DIV 8 THEN RETURN DH END;
    RETURN max.Y + max.H DIV 2
  END UY;

  PROCEDURE AllocateUserViewer* (DX: INTEGER; VAR X, Y: INTEGER);
  BEGIN
    IF Pointer.on THEN X := Pointer.X; Y := Pointer.Y
    ELSE X := DX DIV DW * DW; Y := UY(X)
    END
  END AllocateUserViewer;

  PROCEDURE SY (X: INTEGER): INTEGER;
    VAR fil, bot, alt, max: Display.Frame;
  BEGIN
    Viewers.Locate(X, DH, fil, bot, alt, max);
    IF fil.H >= DH DIV 8 THEN RETURN DH END;
    IF max.H >= DH - H0 THEN RETURN max.Y + H3 END;
    IF max.H >= H3 - H0 THEN RETURN max.Y + H2 END;
    IF max.H >= H2 - H0 THEN RETURN max.Y + H1 END;
    IF max # bot THEN RETURN max.Y + max.H DIV 2 END;
    IF bot.H >= H1 THEN RETURN bot.H DIV 2 END;
    RETURN alt.Y + alt.H DIV 2
  END SY;

  PROCEDURE AllocateSystemViewer* (DX: INTEGER; VAR X, Y: INTEGER);
  BEGIN
    IF Pointer.on THEN X := Pointer.X; Y := Pointer.Y
    ELSE X := DX DIV DW * DW + DW DIV 8 * 5; Y := SY(X)
    END
  END AllocateSystemViewer;

  PROCEDURE MarkedViewer* (): Viewers.Viewer;
  BEGIN RETURN Viewers.This(Pointer.X, Pointer.Y)
  END MarkedViewer;

  PROCEDURE PassFocus* (V: Viewers.Viewer);
    VAR M: ControlMsg;
  BEGIN M.id := defocus; FocusViewer.handle(FocusViewer, M); FocusViewer := V
  END PassFocus;

  (*command interpretation*)

  PROCEDURE Call* (name: ARRAY OF CHAR; par: ParList; new: BOOLEAN; VAR res: INTEGER);
    VAR Mod: Modules.Module; P: Modules.Command; i, j: INTEGER;
  BEGIN res := 1;
    i := 0; j := 0;
    WHILE name[j] # 0X DO
      IF name[j] = "." THEN i := j END;
      INC(j)
    END;
    IF i > 0 THEN
      name[i] := 0X;
      Mod := Modules.ThisMod(name);
      IF Modules.res = 0 THEN
        INC(i); j := i;
        WHILE name[j] # 0X DO name[j - i] := name[j]; INC(j) END;
        name[j - i] := 0X;
        P := Modules.ThisCommand(Mod, name);
        IF Modules.res = 0 THEN
          Par := par; Par.vwr := Viewers.This(par.frame.X, par.frame.Y); P; res := 0
        ELSE res := -1
        END
      ELSE res := Modules.res
      END
    ELSE res := -1
    END
  END Call;

  PROCEDURE GetSelection* (VAR text: Texts.Text; VAR beg, end, time: LONGINT);
    VAR M: SelectionMsg;
  BEGIN
    M.time := -1; Viewers.Broadcast(M); time := M.time;
    IF time >= 0 THEN text := M.text; beg := M.beg; end := M.end END
  END GetSelection;

  PROCEDURE GC;
  BEGIN IF ActCnt <= 0 THEN Kernel.GC(FALSE); ActCnt := BasicCycle END
  END GC;

  PROCEDURE Install* (T: Task);
    VAR t: Task;
  BEGIN t := PrevTask;
    WHILE (t.next # PrevTask) & (t.next # T) DO t := t.next END;
    IF (t.next # T) & (CurTask # T) THEN
      IF CurTask # NIL THEN (* called from a task *)
        T.next := CurTask.next; CurTask.next := T
      ELSE (* no task is currently running *)
        T.next := PrevTask.next; PrevTask.next := T
      END
    END
  END Install;

  PROCEDURE Remove* (T: Task);
    VAR t: Task;
  BEGIN t := PrevTask;
    WHILE (t.next # T) & (t.next # PrevTask) DO t := t.next END;
    IF t.next = T THEN t.next := t.next.next; PrevTask := t.next END;
    IF CurTask = T THEN CurTask := PrevTask.next END
  END Remove;

  PROCEDURE Collect* (count: INTEGER);
  BEGIN ActCnt := count
  END Collect;

  PROCEDURE SetFont* (fnt: Fonts.Font);
  BEGIN CurFnt := fnt
  END SetFont;

  PROCEDURE SetColor* (col: SHORTINT);
  BEGIN CurCol := col
  END SetColor;

  PROCEDURE SetOffset* (voff: SHORTINT);
  BEGIN CurOff := voff
  END SetOffset;

  PROCEDURE MinTime(): LONGINT;  (* << *)
    VAR minTime: LONGINT; t: Task;
  BEGIN
    minTime := MAX(LONGINT); t := PrevTask;
    REPEAT
      IF (t.time # -1) & (t.time < minTime) THEN minTime := t.time END ;
      t := t.next;
    UNTIL t = PrevTask ;
    RETURN minTime
  END MinTime;

  PROCEDURE NotifyTasks;  (* << *)
    VAR t0, p: Task;
  BEGIN t0 := PrevTask;
    REPEAT
      CurTask := PrevTask.next;
      IF CurTask.time = -1 THEN
        IF ~CurTask.safe THEN PrevTask.next := CurTask.next END;
        p := CurTask; CurTask.handle; PrevTask.next := CurTask;
        IF CurTask # p THEN RETURN END (*detect Remove(CurTask)*)
      END;
      PrevTask := CurTask
    UNTIL CurTask = t0
  END NotifyTasks;

  PROCEDURE Loop*;
    VAR V: Viewers.Viewer; M: InputMsg; N: ControlMsg;
      prevX, prevY, X, Y: INTEGER; keys: SET; ch: CHAR;
      VM: Viewers.ViewerMsg; i: INTEGER; res: LONGINT;  (* << *)
  BEGIN
    res := Kernel.sigsetjmp(Kernel.trapEnv, 1);  (* << *)
    LOOP
      CurTask := NIL;
      Input.Mouse(keys, X, Y);
      IF Input.Available() > 0 THEN Input.Read(ch);
        IF ch < 0F0X THEN
          IF ch = ESC THEN
            N.id := neutralize; Viewers.Broadcast(N); FadeCursor(Pointer)
          ELSIF ch = SETUP THEN
            N.id := mark; N.X := X; N.Y := Y; V := Viewers.This(X, Y); V.handle(V, N)
          ELSIF ch = 0CX THEN  (* << *)
            N.id := neutralize; Viewers.Broadcast(N); FadeCursor(Pointer);
            VM.id := Viewers.suspend; Viewers.Broadcast(VM);
            VM.id := Viewers.restore; Viewers.Broadcast(VM)
          ELSE
            M.id := consume; M.ch := ch; M.fnt := CurFnt; M.col := CurCol; M.voff := CurOff;
            FocusViewer.handle(FocusViewer, M);
            DEC(ActCnt); NotifyTasks
          END
        ELSIF ch = 0F1X THEN Display.SetMode(0, {})
        ELSIF ch = 0F2X THEN Display.SetMode(0, {0})
        ELSIF ch = 0F3X THEN Display.SetMode(0, {2})
        ELSIF ch = 0F4X THEN X11.InitColors
        ELSIF Kernel.FKey[ORD(ch) - 0F0H] # NIL THEN Kernel.FKey[ORD(ch) - 0F0H]
        END
      ELSIF keys # {} THEN
        M.id := track; M.X := X; M.Y := Y; M.keys := keys;
        REPEAT
          V := Viewers.This(M.X, M.Y); V.handle(V, M);
          Input.Mouse(M.keys, M.X, M.Y)
        UNTIL M.keys = {};
        DEC(ActCnt); NotifyTasks
      ELSE
        IF (X # prevX) OR (Y # prevY) OR ~Mouse.on THEN
          M.id := track; M.X := X; M.Y := Y; M.keys := keys; V := Viewers.This(X, Y); V.handle(V, M);
          prevX := X; prevY := Y
        END;
        X11.DoSync;  (* << *)
        IF X11.EventsQueued(X11.display, X11.QueuedAfterReading) = 0 THEN  (* << *)
          Kernel.Select(MinTime() - Input.Time()); NotifyTasks;
          FOR i := 0 TO 7 DO Kernel.readySet[i] := {} END
        END ;
        CurTask := PrevTask.next;
        IF (CurTask.time <= Input.Time()) & (CurTask.time # -1) THEN
          IF ~CurTask.safe THEN PrevTask.next := CurTask.next END;
          CurTask.handle; PrevTask.next := CurTask
        END;
        PrevTask := CurTask
      END
    END
  END Loop;

BEGIN User[0] := 0X;
  Arrow.Fade := FlipArrow; Arrow.Draw := FlipArrow;
  ArrowFade := FlipArrow;  (* << *)
  Star.Fade := FlipStar; Star.Draw := FlipStar;
  OpenCursor(Mouse); OpenCursor(Pointer);

  DW := Display.Width; DH := Display.Height; CL := Display.ColLeft;
  H3 := DH - DH DIV 3;
  H2 := H3 - H3 DIV 2;
  H1 := DH DIV 5;
  H0 := DH DIV 10;

(* moved into Configuration.Mod
  unitW := DW DIV 8;
  OpenDisplay(unitW * 5, unitW * 3, DH);
  FocusViewer := Viewers.This(0, 0);
*)

  CurFnt := Fonts.Default;
  CurCol := Display.white;
  CurOff := 0;

  Collect(BasicCycle);
  NEW(PrevTask);
  PrevTask.handle := GC;
  PrevTask.safe := TRUE;
  PrevTask.time := -1;  (* << *)
  PrevTask.next := PrevTask;
  CurTask := NIL;

  Display.SetMode(0, {});

END Oberon.
