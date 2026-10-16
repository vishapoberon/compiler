MODULE UnixTermios;

  (* Unix terminal mode for an in-process line editor. Keep the actual libc
     termios structure opaque; Platform owns saving/restoring its storage. *)
  IMPORT Platform;

  TYPE State* = Platform.TerminalState;

  PROCEDURE Restore*(VAR state: State);
    VAR error: Platform.ErrorCode;
  BEGIN
    Platform.CommandCritical(TRUE);
    IF state # 0 THEN
      REPEAT error := Platform.RestoreTerminalState(Platform.StdIn, state)
      UNTIL ~Platform.Interrupted(error);
      Platform.ReleaseTerminalState(state)
    END;
    Platform.CommandCritical(FALSE)
  END Restore;

  PROCEDURE Enter*(VAR state: State): Platform.ErrorCode;
    VAR error: Platform.ErrorCode;
      working: State;
  BEGIN
    Platform.CommandCritical(TRUE);
    error := Platform.CaptureTerminalState(Platform.StdIn, state);
    IF error = 0 THEN
      error := Platform.CopyTerminalState(state, working);
      IF error = 0 THEN
        Platform.MakeTerminalRaw(working);
        error := Platform.RestoreTerminalState(Platform.StdIn, working);
        Platform.ReleaseTerminalState(working)
      END;
      IF error # 0 THEN Restore(state) END
    END;
    Platform.CommandCritical(FALSE);
    RETURN error
  END Enter;

END UnixTermios.
