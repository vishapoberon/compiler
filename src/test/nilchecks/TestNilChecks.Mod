MODULE TestNilChecks;
IMPORT Out;
TYPE
  Action = PROCEDURE;
  Function = PROCEDURE(): LONGINT;
  Pointer = POINTER TO Record;
  Record = RECORD value: LONGINT; next: Pointer; action: Action END;
  Extension = RECORD (Record) extra: LONGINT END;
  Extended = POINTER TO Extension;
  Fixed = POINTER TO ARRAY 4 OF LONGINT;
  Dynamic = POINTER TO ARRAY OF LONGINT;
  Matrix = POINTER TO ARRAY OF ARRAY OF LONGINT;
VAR p, empty: Pointer; q: Extended; fixed: Fixed; dynamic: Dynamic; matrix: Matrix;
  anonymous: RECORD fixed: POINTER TO ARRAY 2 OF LONGINT;
    dynamic: POINTER TO ARRAY OF LONGINT; action: PROCEDURE END;
  pointers: ARRAY 2 OF Pointer;
  action: Action; function: Function;
  value, calls, checks: LONGINT;

PROCEDURE Check(ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN
    Out.String("TestNilChecks: "); Out.Int(checks, 0); Out.String(" checks, 1 failed"); Out.Ln;
    HALT(100)
  END
END Check;

PROCEDURE Index(): LONGINT;
BEGIN INC(calls); RETURN 0 END Index;

PROCEDURE Run;
BEGIN INC(value) END Run;

PROCEDURE Get(): LONGINT;
BEGIN RETURN value END Get;

PROCEDURE (p: Pointer) Read(): LONGINT;
BEGIN RETURN p.value END Read;

PROCEDURE (q: Extended) Read(): LONGINT;
BEGIN RETURN q.Read^() + q.extra END Read;

PROCEDURE (p: Pointer) Update(amount: REAL; VAR target: LONGINT; label: ARRAY OF CHAR): REAL;
BEGIN target := p.value; Check(label[0] = "x"); RETURN amount + 1 END Update;

PROCEDURE Set(VAR target: LONGINT);
BEGIN target := 17 END Set;

PROCEDURE Open(values: ARRAY OF LONGINT): LONGINT;
BEGIN RETURN values[0] END Open;

BEGIN
  Check(empty = NIL); Check(~(empty IS Extended));
  Check((empty = NIL) OR (empty.value = 0));
  NEW(p); p.value := 7; Check(p.value = 7);
  Set(p.value); Check(p.value = 17);
  NEW(q); q.value := 4; q.extra := 3; p.next := q;
  Check(p.next.value = 4); Check(p.Read() = 17); Check(q.Read() = 7);
  p := q; Check(p IS Extended); Check(p(Extended).extra = 3);
  Check(p.Read() = 7);
  NEW(fixed); fixed[0] := 19; Check(fixed[0] = 19); Check(Open(fixed^) = 19);
  NEW(dynamic, 3); dynamic[0] := 23; Check(dynamic[0] = 23); Check(LEN(dynamic^) = 3);
  Check(Open(dynamic^) = 23);
  NEW(matrix, 2, 3); matrix[1, 2] := 29; Check(matrix[1, 2] = 29);
  Check(LEN(matrix^) = 2); Check(LEN(matrix^, 1) = 3);
  pointers[0] := p; calls := 0;
  Check(pointers[Index()].value = 4); Check(calls = 1);
  calls := 0; Check(pointers[Index()].Read() = 7); Check(calls = 1);
  calls := 0; Check(pointers[Index()](Extended).extra = 3); Check(calls = 1);
  Check(p.Update(1.5, value, "x") = 2.5); Check(value = 4);
  action := Run; action(); Check(value = 5);
  function := Get; Check(function() = 5);
  p.action := Run; p.action(); Check(value = 6);
  NEW(anonymous.fixed); anonymous.fixed[0] := 31; Check(anonymous.fixed[0] = 31);
  NEW(anonymous.dynamic, 2); anonymous.dynamic[0] := 37;
  Check(anonymous.dynamic[0] = 37); Check(LEN(anonymous.dynamic^) = 2);
  anonymous.action := Run; anonymous.action(); Check(value = 7);
  Out.String("TestNilChecks: "); Out.Int(checks, 0); Out.String(" checks, 0 failed"); Out.Ln
END TestNilChecks.
