MODULE TestStackFaults;
IMPORT SYSTEM, Heap, Modules, Out;
TYPE Pointer = POINTER TO RECORD value: LONGINT END;
VAR retained: Pointer; mode: ARRAY 32 OF CHAR; byte: CHAR;

PROCEDURE Finish(obj: SYSTEM.PTR);
BEGIN
  Out.String("finalizer ran"); Out.Ln
END Finish;

PROCEDURE Recurse(depth: LONGINT);
VAR data: ARRAY 4096 OF CHAR; i: LONGINT;
BEGIN
  FOR i := 0 TO LEN(data)-1 DO data[i] := CHR(depth MOD 256) END;
  IF depth < 4096 THEN Recurse(depth+1) END;
  Out.Char(data[depth MOD LEN(data)])
END Recurse;

PROCEDURE LargeFrame;
VAR data: ARRAY 1024*1024 OF CHAR; i: LONGINT;
BEGIN
  FOR i := 0 TO LEN(data)-1 DO data[i] := "x" END;
  Out.Char(data[0])
END LargeFrame;

BEGIN
  NEW(retained); Heap.RegisterFinalizer(retained, Finish);
  Modules.GetArg(1, mode);
  Out.String("entering fault test"); Out.Ln;
  Out.String("buffered output");
  IF mode = "recursion" THEN Recurse(0)
  ELSIF mode = "array" THEN LargeFrame
  ELSIF mode = "raw" THEN byte := 0X; SYSTEM.PUT(1, byte)
  ELSE HALT(100)
  END;
  Out.String("unexpected continuation"); Out.Ln;
  HALT(100)
END TestStackFaults.
