MODULE TestTerminalState;
  IMPORT SYSTEM, Platform, termios, Heap, Out, TestTerminalNative;
  VAR fd: SYSTEM.INT32; rows, cols: LONGINT; smallRows, smallCols: INTEGER;
    saved, raw, timed: termios.Termios;
    first, copy: Platform.TerminalState;

BEGIN
  fd := TestTerminalNative.Open(); ASSERT(fd >= 0);
  ASSERT(termios.Get(fd, saved) = 0);
  raw := saved; termios.MakeRaw(raw);
  timed := raw; termios.Timeout(timed, 1);
  ASSERT((saved # raw) & (raw # timed));
  Heap.GC(TRUE);
  ASSERT(termios.Set(fd, timed) = 0); ASSERT(TestTerminalNative.Settings(fd, 1, 1));
  ASSERT(termios.Set(fd, raw) = 0); ASSERT(TestTerminalNative.Settings(fd, 1, 0));
  ASSERT(termios.Set(fd, saved) = 0); ASSERT(TestTerminalNative.Settings(fd, 0, 0));
  ASSERT(Platform.CaptureTerminalState(fd, first) = 0);
  ASSERT(Platform.CopyTerminalState(first, copy) = 0); ASSERT(copy # first);
  Platform.MakeTerminalRaw(copy);
  ASSERT(Platform.RestoreTerminalState(fd, copy) = 0); ASSERT(TestTerminalNative.Settings(fd, 1, 0));
  ASSERT(Platform.RestoreTerminalState(fd, first) = 0); ASSERT(TestTerminalNative.Settings(fd, 0, 0));
  Platform.ReleaseTerminalState(first); Platform.ReleaseTerminalState(copy);
  Platform.ReleaseTerminalState(copy); ASSERT((first = 0) & (copy = 0));
  ASSERT(TestTerminalNative.Dimensions(fd) = 0);
  ASSERT(Platform.GetTerminalDimensions(fd, rows, cols) = 0);
  ASSERT((rows = 40000) & (cols = 65535));
  ASSERT(termios.WinSize(fd, rows, cols)); ASSERT((rows = 40000) & (cols = 65535));
  smallRows := 12; smallCols := 34;
  IF MAX(INTEGER) < 65535 THEN
    ASSERT(Platform.GetTerminalSize(fd, smallRows, smallCols) # 0);
    ASSERT((smallRows = 12) & (smallCols = 34))
  ELSE
    ASSERT(Platform.GetTerminalSize(fd, smallRows, smallCols) = 0);
    ASSERT((smallRows = 40000) & (smallCols = 65535))
  END;
  ASSERT(Platform.CaptureTerminalState(-1, first) # 0); ASSERT(first = 0);
  TestTerminalNative.Close(fd);
  Out.String("opaque terminal state tests passed"); Out.Ln
END TestTerminalState.
