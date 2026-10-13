MODULE TestOpenArrayRows;
  (* Regression for vishap-bugs issue 11, including partially indexed cubes. *)
  IMPORT Out;
  TYPE Cube = POINTER TO ARRAY OF ARRAY OF ARRAY OF LONGINT;
  VAR matrix: ARRAY 3, 4 OF LONGINT; cube: ARRAY 2, 3, 4 OF LONGINT;
    dynamic: Cube; a, b, c: LONGINT;

  PROCEDURE Sum(row: ARRAY OF LONGINT): LONGINT;
    VAR i, result: LONGINT;
  BEGIN
    result := 0;
    FOR i := 0 TO LEN(row)-1 DO INC(result, row[i]) END;
    RETURN result
  END Sum;

  PROCEDURE Change(VAR row: ARRAY OF LONGINT);
  BEGIN INC(row[LEN(row)-1], 1000) END Change;

  PROCEDURE Rows(VAR m: ARRAY OF ARRAY OF LONGINT; base: LONGINT);
    VAR r: LONGINT;
  BEGIN
    ASSERT((LEN(m) = 3) & (LEN(m, 1) = 4));
    FOR r := 0 TO LEN(m)-1 DO
      ASSERT(Sum(m[r]) = 4*base + 40*r + 6);
      Change(m[r]); ASSERT(m[r, 3] = base + 10*r + 1003)
    END
  END Rows;

  PROCEDURE Planes(VAR x: ARRAY OF ARRAY OF ARRAY OF LONGINT);
    VAR p: LONGINT;
  BEGIN
    FOR p := 0 TO LEN(x)-1 DO Rows(x[p], 100*p) END
  END Planes;

BEGIN
  FOR b := 0 TO 2 DO FOR c := 0 TO 3 DO matrix[b, c] := 10*b + c END END;
  Rows(matrix, 0);
  FOR b := 0 TO 2 DO ASSERT(matrix[b, 3] = 10*b + 1003) END;
  NEW(dynamic, 2, 3, 4);
  FOR a := 0 TO 1 DO FOR b := 0 TO 2 DO FOR c := 0 TO 3 DO
    cube[a, b, c] := 100*a + 10*b + c;
    dynamic[a, b, c] := cube[a, b, c]
  END END END;
  Planes(cube); Planes(dynamic^);
  FOR a := 0 TO 1 DO FOR b := 0 TO 2 DO
    ASSERT(cube[a, b, 3] = 100*a + 10*b + 1003);
    ASSERT(dynamic[a, b, 3] = cube[a, b, 3])
  END END;
  Out.String("open array row tests passed"); Out.Ln
END TestOpenArrayRows.
