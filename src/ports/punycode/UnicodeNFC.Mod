MODULE UnicodeNFC;

IMPORT Punycode, Data := IDNAData;

CONST maxScalars* = 4096;

PROCEDURE Normalize*(input: ARRAY OF LONGINT; count: LONGINT;
                     VAR output: ARRAY OF LONGINT; VAR written: LONGINT; VAR ok: BOOLEAN);
  VAR buffer: ARRAY maxScalars OF LONGINT;
    i, j, character, offset, size, n, index, combining, previous, starter, composite, length: LONGINT;

  PROCEDURE Append(character: LONGINT): BOOLEAN;
    VAR at, combining: LONGINT;
  BEGIN
    IF size = maxScalars THEN RETURN FALSE END;
    combining := Data.Combining(character); at := size;
    IF combining # 0 THEN
      WHILE (at > 0) & (Data.Combining(buffer[at-1]) > combining) DO
        buffer[at] := buffer[at-1]; DEC(at)
      END
    END;
    buffer[at] := character; INC(size); RETURN TRUE
  END Append;

BEGIN
  written := 0; ok := FALSE;
  IF (count < 0) OR (count > LEN(input)) OR (count > maxScalars) THEN RETURN END;
  size := 0;
  FOR i := 0 TO count-1 DO
    character := input[i]; IF ~Punycode.Scalar(character) THEN RETURN END;
    IF (character >= 0AC00H) & (character < 0D7A4H) THEN
      index := character-0AC00H;
      IF ~Append(1100H+index DIV 588) OR ~Append(1161H+index MOD 588 DIV 28) THEN RETURN END;
      IF (index MOD 28 # 0) & ~Append(11A7H+index MOD 28) THEN RETURN END
    ELSE
      Data.Decomposition(character, offset, n);
      IF n = 0 THEN IF ~Append(character) THEN RETURN END
      ELSE FOR j := 0 TO n-1 DO IF ~Append(Data.Word(offset+j)) THEN RETURN END END
      END
    END
  END;
  IF size = 0 THEN ok := TRUE; RETURN END;
  starter := 0; length := 1; previous := Data.Combining(buffer[0]);
  FOR i := 1 TO size-1 DO
    character := buffer[i]; combining := Data.Combining(character);
    composite := Data.Compose(buffer[starter], character);
    IF (composite >= 0) & ((previous < combining) OR (previous = 0)) THEN
      buffer[starter] := composite
    ELSE
      IF combining = 0 THEN starter := length END;
      buffer[length] := character; INC(length); previous := combining
    END
  END;
  IF length > LEN(output) THEN RETURN END;
  FOR i := 0 TO length-1 DO output[i] := buffer[i] END;
  written := length; ok := TRUE
END Normalize;

END UnicodeNFC.
