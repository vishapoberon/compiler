MODULE TestSsqTerminal;
IMPORT Sys := ssqSys, Types := ssqTypes, Kbd;
VAR mode: ARRAY 32 OF CHAR; rows, cols: Types.Integer;
BEGIN
  ASSERT(Sys.Argv(mode, 1));
  Sys.XtermAlt; Sys.XtermAlt; (* Re-entry must not overwrite the saved state. *)
  Sys.XtermSize(rows, cols); ASSERT((rows = 24) & (cols = 80));
  Sys.Out('ready'); Sys.OutChr(0AX);
  ASSERT(Kbd.GetKey() = Kbd.AKey(0, 'x'));
  IF mode = 'halt' THEN HALT(7)
  ELSIF mode = 'fail' THEN Sys.ExitFail
  ELSIF mode = 'explicit' THEN Sys.XtermStd; Sys.XtermStd
  END
END TestSsqTerminal.
