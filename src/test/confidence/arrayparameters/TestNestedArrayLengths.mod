MODULE TestNestedArrayLengths;
  (* Regression for vishap-bugs issue 12: all captured dimensions. *)
  IMPORT Out;
  VAR cube: ARRAY 2, 3, 7 OF LONGINT;

  PROCEDURE Captured(VAR x: ARRAY OF ARRAY OF ARRAY OF LONGINT);
    PROCEDURE Inner;
      PROCEDURE Deep;
      BEGIN
        ASSERT((LEN(x) = 2) & (LEN(x, 1) = 3) & (LEN(x, 2) = 7));
        ASSERT(x[1, 2, 6] = 126); INC(x[1, 2, 6])
      END Deep;
    BEGIN Deep END Inner;
  BEGIN Inner END Captured;

  PROCEDURE Value(x: ARRAY OF ARRAY OF ARRAY OF LONGINT);
    PROCEDURE Inner;
    BEGIN
      ASSERT((LEN(x) = 2) & (LEN(x, 1) = 3) & (LEN(x, 2) = 7));
      ASSERT(x[1, 2, 6] = 127); x[1, 2, 6] := 999
    END Inner;
  BEGIN Inner END Value;

BEGIN
  cube[1, 2, 6] := 126; Captured(cube);
  ASSERT(cube[1, 2, 6] = 127);
  Value(cube); ASSERT(cube[1, 2, 6] = 127);
  Out.String("nested array length tests passed"); Out.Ln
END TestNestedArrayLengths.
