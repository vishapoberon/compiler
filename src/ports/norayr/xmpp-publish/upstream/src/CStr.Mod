MODULE CStr;
(*  Helpers for moving between Oberon character arrays and the C `char *'
    strings returned by libstrophe. *)

IMPORT C;

PROCEDURE CopyOut* (p: C.string; VAR s: ARRAY OF CHAR);
(*  Copy the NUL terminated C string P into S.  S is always terminated.  *)
VAR
  i: LONGINT;
BEGIN
  IF p = NIL THEN
    s[0] := 0X
  ELSE
    i := 0;
    WHILE (i < LEN(s) - 1) & (p[i] # 0X) DO
      s[i] := p[i];
      INC(i)
    END;
    s[i] := 0X
  END
END CopyOut;

END CStr.
