MODULE TestHeapRoots;
  (* Regression for vishap-bugs issue 14. *)
  IMPORT S := SYSTEM, Heap, Out;
  TYPE String = POINTER TO ARRAY OF CHAR;
    Object = POINTER TO RECORD id: LONGINT END;
  VAR bad, i, current: LONGINT; collected: BOOLEAN;

  PROCEDURE -Include '#include "RegisterRoots.inc"';
  PROCEDURE -RegisterRoots(): INTEGER
    "GCRegisterRoots_Run(TestHeapRoots_MakeObject, TestHeapRoots_Collect, TestHeapRoots_Alive)";

  PROCEDURE Finalize(p: S.PTR);
    VAR object: Object;
  BEGIN
    object := S.VAL(Object, p);
    IF object.id = current THEN collected := TRUE END
  END Finalize;

  PROCEDURE MakeObject(): S.ADDRESS;
    VAR p: Object;
  BEGIN
    INC(current); collected := FALSE;
    NEW(p); p.id := current; Heap.RegisterFinalizer(p, Finalize);
    RETURN S.VAL(S.ADDRESS, p)
  END MakeObject;

  PROCEDURE Collect;
  BEGIN Heap.GC(TRUE) END Collect;

  PROCEDURE Alive(address: S.ADDRESS): INTEGER;
    VAR p: Object;
  BEGIN
    p := S.VAL(Object, address);
    IF ~collected & (p.id = current) THEN RETURN 1 ELSE RETURN 0 END
  END Alive;

  PROCEDURE Make(text: ARRAY OF CHAR): String;
    VAR p: String;
  BEGIN NEW(p, LEN(text)); COPY(text, p^); RETURN p END Make;

  PROCEDURE Check(a, b, c: String);
  BEGIN
    IF (a^ # "aaaaaaaaaaaa") OR (b^ # "bbbbbbbbbbbb") OR (c^ # "cccccccccccc") THEN INC(bad) END
  END Check;

BEGIN
  ASSERT(RegisterRoots() = 1);
  FOR i := 1 TO 1000000 DO
    Check(Make("aaaaaaaaaaaa"), Make("bbbbbbbbbbbb"), Make("cccccccccccc"))
  END;
  ASSERT(bad = 0);
  Out.String("heap register root tests passed"); Out.Ln
END TestHeapRoots.
