MODULE UnixTermios;

  (* Unix terminal mode for an in-process line editor. Keep the actual libc
     termios structure opaque; Platform owns saving/restoring its storage. *)
  IMPORT SYSTEM, Platform;

  TYPE State* = Platform.TerminalState;

  PROCEDURE -AInclude '#include <termios.h>';
  PROCEDURE -raw(h: Platform.FileHandle): SYSTEM.INT32
    '({ struct termios t; int rc = tcgetattr(h, &t); if (rc == 0) { t.c_lflag &= ~(ICANON | ECHO | ISIG | IEXTEN); t.c_iflag &= ~(ICRNL | IXON); t.c_cc[VMIN] = 1; t.c_cc[VTIME] = 0; rc = tcsetattr(h, TCSANOW, &t); } rc; })';

  PROCEDURE Restore*(VAR state: State);
    VAR error: Platform.ErrorCode;
  BEGIN
    IF state # 0 THEN
      REPEAT error := Platform.RestoreTerminalState(Platform.StdIn, state)
      UNTIL ~Platform.Interrupted(error);
      Platform.ReleaseTerminalState(state)
    END
  END Restore;

  PROCEDURE Enter*(VAR state: State): Platform.ErrorCode;
    VAR error: Platform.ErrorCode;
  BEGIN
    error := Platform.CaptureTerminalState(Platform.StdIn, state);
    IF error = 0 THEN
      IF raw(Platform.StdIn) < 0 THEN error := Platform.Error(); Restore(state) END
    END;
    RETURN error
  END Enter;

END UnixTermios.
