MODULE TestTerminalState;
  IMPORT SYSTEM, Platform, termios, Heap, Out, TestTerminalNative;
  VAR fd: SYSTEM.INT32; rows, cols: LONGINT; smallRows, smallCols: INTEGER;
    saved, raw, timed: termios.Termios;
    first, copy: Platform.TerminalState;

  PROCEDURE Check(condition: BOOLEAN; stage: ARRAY OF CHAR);
  BEGIN
    IF ~condition THEN
      Out.String("terminal state check failed: "); Out.String(stage); Out.Ln;
      ASSERT(condition)
    END
  END Check;

BEGIN
  fd := TestTerminalNative.Open(); Check(fd >= 0, "open pseudo-terminal");
  Check(termios.Get(fd, saved) = 0, "capture initial settings");
  raw := saved; termios.MakeRaw(raw);
  timed := raw; termios.Timeout(timed, 1);
  Check((saved # raw) & (raw # timed), "copy-on-change settings");
  Heap.GC(TRUE);
  Check(termios.Set(fd, timed) = 0, "set timed mode");
  Check(TestTerminalNative.Settings(fd, 1, 1), "verify timed mode");
  Check(termios.Set(fd, raw) = 0, "set raw mode");
  Check(TestTerminalNative.Settings(fd, 1, 0), "verify raw mode");
  Check(termios.Set(fd, saved) = 0, "restore initial settings");
  Check(TestTerminalNative.Settings(fd, 0, 0), "verify restored settings");
  Check(Platform.CaptureTerminalState(fd, first) = 0, "capture opaque settings");
  Check(Platform.CopyTerminalState(first, copy) = 0, "copy opaque settings");
  Check(copy # first, "independent opaque copy");
  Platform.MakeTerminalRaw(copy);
  Check(Platform.RestoreTerminalState(fd, copy) = 0, "set opaque raw mode");
  Check(TestTerminalNative.Settings(fd, 1, 0), "verify opaque raw mode");
  Check(Platform.RestoreTerminalState(fd, first) = 0, "restore opaque settings");
  Check(TestTerminalNative.Settings(fd, 0, 0), "verify opaque restored settings");
  Platform.ReleaseTerminalState(first); Platform.ReleaseTerminalState(copy);
  Platform.ReleaseTerminalState(copy); Check((first = 0) & (copy = 0), "release opaque settings");
  Check(TestTerminalNative.Dimensions(fd) = 0, "set large terminal dimensions");
  Check(Platform.GetTerminalDimensions(fd, rows, cols) = 0, "get large terminal dimensions");
  Check((rows = 40000) & (cols = 65535), "preserve large terminal dimensions");
  Check(termios.WinSize(fd, rows, cols), "get termios dimensions");
  Check((rows = 40000) & (cols = 65535), "preserve termios dimensions");
  smallRows := 12; smallCols := 34;
  IF MAX(INTEGER) < 65535 THEN
    Check(Platform.GetTerminalSize(fd, smallRows, smallCols) # 0, "reject narrow dimension overflow");
    Check((smallRows = 12) & (smallCols = 34), "preserve outputs on dimension overflow")
  ELSE
    Check(Platform.GetTerminalSize(fd, smallRows, smallCols) = 0, "get wide terminal size");
    Check((smallRows = 40000) & (smallCols = 65535), "preserve wide terminal size")
  END;
  Check(Platform.CaptureTerminalState(-1, first) # 0, "reject invalid terminal descriptor");
  Check(first = 0, "clear state on invalid descriptor");
  TestTerminalNative.Close(fd);
  Out.String("opaque terminal state tests passed"); Out.Ln
END TestTerminalState.
