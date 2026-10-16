MODULE optsosv; (* v for vishap *)
(* os/compiler dependent argument functions to use in opts.Mod *)
(* voc version, uses Args module. should work with ofront as well *)

IMPORT Args, Strings;

TYPE
  string* = POINTER TO ARRAY OF CHAR;

VAR
  argscount-: INTEGER;
  cur:        INTEGER;

PROCEDURE Get*(): string;
VAR
  capacity: LONGINT;
  s: string;
BEGIN
  s := NIL;
  INC(cur);
  IF cur <= argscount THEN
    capacity := 64;
    LOOP
      NEW(s, capacity);
      Args.Get(cur, s^);
      IF Strings.Length(s^) < capacity - 1 THEN EXIT END;
      ASSERT(capacity <= MAX(LONGINT) DIV 2);
      capacity := capacity * 2
    END
  END;
  RETURN s
END Get;

BEGIN
  argscount := Args.argc - 1;
  cur := 0;
END optsosv. (* v for vishap *)
