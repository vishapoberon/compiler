MODULE termios;

  (* Native settings are opaque. Copy-on-change gives console programs value
     semantics without reproducing any Unix struct layout in Oberon. *)
  IMPORT SYSTEM, Platform, Heap;

  TYPE Termios* = POINTER TO Settings;
    Settings = RECORD state: Platform.TerminalState END;

  PROCEDURE Finalize(obj: SYSTEM.PTR);
    VAR t: Termios;
  BEGIN
    t := SYSTEM.VAL(Termios, obj); Platform.ReleaseTerminalState(t.state)
  END Finalize;

  PROCEDURE Get*(fd: LONGINT; VAR t: Termios): LONGINT;
    VAR error: Platform.ErrorCode;
  BEGIN
    Heap.Lock;
    NEW(t); error := Platform.CaptureTerminalState(fd, t.state);
    IF error = 0 THEN Heap.RegisterFinalizer(t, Finalize) ELSE t := NIL END;
    Heap.Unlock;
    RETURN -error
  END Get;

  PROCEDURE Set*(fd: LONGINT; VAR t: Termios): LONGINT;
  BEGIN
    ASSERT(t # NIL);
    RETURN -Platform.RestoreTerminalState(fd, t.state)
  END Set;

  PROCEDURE Copy(VAR t: Termios);
    VAR copy: Termios; error: Platform.ErrorCode;
  BEGIN
    ASSERT(t # NIL);
    Heap.Lock;
    NEW(copy); error := Platform.CopyTerminalState(t.state, copy.state);
    ASSERT(error = 0);
    Heap.RegisterFinalizer(copy, Finalize); t := copy;
    Heap.Unlock
  END Copy;

  PROCEDURE MakeRaw*(VAR t: Termios);
  BEGIN Copy(t); Platform.MakeTerminalRaw(t.state)
  END MakeRaw;

  PROCEDURE Timeout*(VAR t: Termios; tenths: LONGINT);
  BEGIN
    ASSERT((tenths >= 0) & (tenths <= 255));
    Copy(t); Platform.SetTerminalTimeout(t.state, SHORT(tenths))
  END Timeout;

  PROCEDURE WinSize*(fd: LONGINT; VAR rows, cols: LONGINT): BOOLEAN;
    VAR r, c: LONGINT;
  BEGIN
    IF (Platform.GetTerminalDimensions(fd, r, c) = 0) & (r > 0) & (c > 0) THEN
      rows := r; cols := c; RETURN TRUE
    END;
    RETURN FALSE
  END WinSize;

END termios.
