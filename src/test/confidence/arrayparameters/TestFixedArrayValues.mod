MODULE TestFixedArrayValues;
  IMPORT Out;
  TYPE Name = ARRAY 8 OF CHAR; Alias = Name;
    Vector = ARRAY 3 OF LONGINT;
  VAR name: Alias; small: ARRAY 4 OF CHAR; vector: Vector;
    operation: PROCEDURE(value: Name);

  PROCEDURE CheckString(value: Name);
    VAR i: LONGINT;
  BEGIN
    ASSERT(value = "abc");
    FOR i := 4 TO LEN(value)-1 DO ASSERT(value[i] = 0X) END;
    value[0] := "X"
  END CheckString;

  PROCEDURE CheckEmpty(value: Name);
    VAR i: LONGINT;
  BEGIN FOR i := 0 TO LEN(value)-1 DO ASSERT(value[i] = 0X) END END CheckEmpty;

  PROCEDURE CheckCharacter(value: Name);
    VAR i: LONGINT;
  BEGIN
    ASSERT(value[0] = "q");
    FOR i := 1 TO LEN(value)-1 DO ASSERT(value[i] = 0X) END
  END CheckCharacter;

  PROCEDURE CheckFull(value: Name);
  BEGIN ASSERT((value = "1234567") & (value[7] = 0X)) END CheckFull;

  PROCEDURE CheckVector(value: Vector);
  BEGIN ASSERT(value[2] = 3); value[2] := 99 END CheckVector;

  PROCEDURE Assign(value: ARRAY OF CHAR);
    VAR copy: Name;
  BEGIN copy := value; ASSERT(copy = "abc") END Assign;

BEGIN
  name := "abc"; CheckString(name); ASSERT(name = "abc");
  CheckString("abc"); operation := CheckString; operation("abc");
  CheckEmpty(""); CheckCharacter("q"); CheckFull("1234567");
  small := "abc"; Assign(small); name := small; ASSERT(name = "abc");
  vector[2] := 3; CheckVector(vector); ASSERT(vector[2] = 3);
  Out.String("fixed array value tests passed"); Out.Ln
END TestFixedArrayValues.
