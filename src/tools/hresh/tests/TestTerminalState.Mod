MODULE TestTerminalState;
  IMPORT SYSTEM, Platform, termios, Heap, Out;
  VAR fd, rows, cols: LONGINT; smallRows, smallCols: INTEGER;
    saved, raw, timed: termios.Termios;
    first, copy: Platform.TerminalState;

  PROCEDURE -AInclude '#include "TestTerminalSupport.h"';
  PROCEDURE -Open(): SYSTEM.INT32 'VOCTest_open_terminal()';
  PROCEDURE -Close(fd: SYSTEM.INT32) 'VOCTest_close_terminal(fd)';
  PROCEDURE -Settings(fd, raw, timed: SYSTEM.INT32): BOOLEAN
    'VOCTest_terminal_settings(fd, raw, timed)';
  PROCEDURE -Dimensions(fd: SYSTEM.INT32): SYSTEM.INT32
    'VOCTest_terminal_dimensions(fd)';

BEGIN
  fd := Open(); ASSERT(fd >= 0);
  ASSERT(termios.Get(fd, saved) = 0);
  raw := saved; termios.MakeRaw(raw);
  timed := raw; termios.Timeout(timed, 1);
  ASSERT((saved # raw) & (raw # timed));
  Heap.GC(TRUE);
  ASSERT(termios.Set(fd, timed) = 0); ASSERT(Settings(fd, 1, 1));
  ASSERT(termios.Set(fd, raw) = 0); ASSERT(Settings(fd, 1, 0));
  ASSERT(termios.Set(fd, saved) = 0); ASSERT(Settings(fd, 0, 0));
  ASSERT(Platform.CaptureTerminalState(fd, first) = 0);
  ASSERT(Platform.CopyTerminalState(first, copy) = 0); ASSERT(copy # first);
  Platform.MakeTerminalRaw(copy);
  ASSERT(Platform.RestoreTerminalState(fd, copy) = 0); ASSERT(Settings(fd, 1, 0));
  ASSERT(Platform.RestoreTerminalState(fd, first) = 0); ASSERT(Settings(fd, 0, 0));
  Platform.ReleaseTerminalState(first); Platform.ReleaseTerminalState(copy);
  Platform.ReleaseTerminalState(copy); ASSERT((first = 0) & (copy = 0));
  ASSERT(Dimensions(fd) = 0);
  ASSERT(Platform.GetTerminalDimensions(fd, rows, cols) = 0);
  ASSERT((rows = 40000) & (cols = 65535));
  ASSERT(termios.WinSize(fd, rows, cols)); ASSERT((rows = 40000) & (cols = 65535));
  smallRows := 12; smallCols := 34;
  ASSERT(Platform.GetTerminalSize(fd, smallRows, smallCols) # 0);
  ASSERT((smallRows = 12) & (smallCols = 34));
  ASSERT(Platform.CaptureTerminalState(-1, first) # 0); ASSERT(first = 0);
  Close(fd);
  Out.String("opaque terminal state tests passed"); Out.Ln
END TestTerminalState.
