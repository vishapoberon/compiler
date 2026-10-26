MODULE DomainVectors;
IMPORT IDNA, Punycode, UnicodeNFC, In, Out;
VAR line: ARRAY 32768 OF CHAR; bytes, encoded: ARRAY 16385 OF CHAR;
  scalars, normalized: ARRAY 4096 OF LONGINT;
  i, n, size, count, written, result: LONGINT; mode: CHAR; ok: BOOLEAN;
  unicode, ascii: IDNA.String;

PROCEDURE Hex(byte: CHAR): LONGINT;
BEGIN
  IF byte <= "9" THEN RETURN ORD(byte)-ORD("0") END;
  IF byte >= "a" THEN RETURN ORD(byte)-ORD("a")+10 END;
  RETURN ORD(byte)-ORD("A")+10
END Hex;

PROCEDURE Print(value, digits: LONGINT);
  VAR buffer: ARRAY 6 OF CHAR; i: LONGINT;
BEGIN
  FOR i := digits-1 TO 0 BY -1 DO
    IF value MOD 16 < 10 THEN buffer[i] := CHR(ORD("0")+value MOD 16)
    ELSE buffer[i] := CHR(ORD("A")+value MOD 16-10)
    END;
    value := value DIV 16
  END;
  FOR i := 0 TO digits-1 DO Out.Char(buffer[i]) END
END Print;

PROCEDURE Text(text: ARRAY OF CHAR);
  VAR i: LONGINT;
BEGIN
  i := 0; WHILE text[i] # 0X DO Print(ORD(text[i]), 2); INC(i) END
END Text;

BEGIN
  In.Open; In.Line(line);
  WHILE In.Done DO
    mode := line[0]; i := 2; size := 0;
    IF (mode = "I") OR (mode = "D") THEN
      WHILE line[i] # 0X DO
        bytes[size] := CHR(Hex(line[i])*16+Hex(line[i+1])); INC(size); INC(i, 2)
      END;
      bytes[size] := 0X
    ELSE
      WHILE line[i] # 0X DO
        n := 0;
        FOR count := 1 TO 6 DO n := n*16+Hex(line[i]); INC(i) END;
        scalars[size] := n; INC(size)
      END
    END;
    IF mode = "I" THEN
      IDNA.Names(bytes, unicode, ascii, result);
      Out.Int(result, 0);
      IF result = 0 THEN Out.Char(9X); Text(ascii^); Out.Char(9X); Text(unicode^) END
    ELSIF mode = "E" THEN
      Punycode.Encode(scalars, size, encoded, written, result); Out.Int(result, 0);
      IF result = 0 THEN Out.Char(9X); FOR i := 0 TO written-1 DO Print(ORD(encoded[i]), 2) END END
    ELSIF mode = "D" THEN
      Punycode.Decode(bytes, size, normalized, written, result); Out.Int(result, 0);
      IF result = 0 THEN Out.Char(9X); FOR i := 0 TO written-1 DO Print(normalized[i], 6) END END
    ELSE
      UnicodeNFC.Normalize(scalars, size, normalized, written, ok);
      IF ok THEN
        Out.Int(0, 0); Out.Char(9X); FOR i := 0 TO written-1 DO Print(normalized[i], 6) END
      ELSE Out.Int(-1, 0)
      END
    END;
    Out.Ln; In.Line(line)
  END
END DomainVectors.
