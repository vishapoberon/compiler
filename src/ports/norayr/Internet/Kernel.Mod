MODULE Kernel;  (** voc: Kernel.GetConfig of polpo, for DNS: an environment variable *)

IMPORT SYSTEM;

PROCEDURE -AAincStdlib "#include <stdlib.h>";
PROCEDURE -getenv0(name: ARRAY OF CHAR): SYSTEM.ADDRESS "(ADDRESS)getenv((char*)name)";

(** the value of the environment variable env, "" if it is not set *)
PROCEDURE GetConfig*(env: ARRAY OF CHAR; VAR val: ARRAY OF CHAR);
VAR p: SYSTEM.ADDRESS; c: CHAR; i: LONGINT;
BEGIN
  p := getenv0(env); i := 0;
  IF p # 0 THEN
    SYSTEM.GET(p, c);
    WHILE (c # 0X) & (i < LEN(val) - 1) DO val[i] := c; INC(i); INC(p); SYSTEM.GET(p, c) END
  END;
  val[i] := 0X
END GetConfig;

END Kernel.
