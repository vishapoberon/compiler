MODULE In;

IMPORT Platform, SYSTEM, Out;

VAR
  nextch:      CHAR;
  ready:       BOOLEAN;
  initialized: BOOLEAN;

  Done-: BOOLEAN;

PROCEDURE ReadChar;
VAR error: Platform.ErrorCode; n: LONGINT; ch: CHAR;
BEGIN
  error := Platform.ReadBuf(Platform.StdIn, ch, n);
  ready := (error = 0) & (n = 1);
  IF ready & (nextch = 0DX) & (ch = 0AX) THEN
    ready := (error = 0) & (n = 1)
  END;
  IF ready THEN nextch := ch ELSE nextch := 0X END
END ReadChar;

PROCEDURE Flush;
BEGIN Out.Flush; IF ~initialized THEN ReadChar END; initialized := TRUE
END Flush;

PROCEDURE Open*;
  VAR error: Platform.ErrorCode;
BEGIN
  error := Platform.Seek(Platform.StdIn, 0, Platform.SeekSet); (* Rewind STDIN to beginning of file. *)
  ready := TRUE; initialized := FALSE;
END Open;

PROCEDURE Char*(VAR ch: CHAR);
BEGIN Flush;
  Done := ready;
  IF ready THEN ch := nextch; ReadChar ELSE ch := 0X END
END Char;

PROCEDURE Skip;
BEGIN
  WHILE ready & (nextch <= " ") DO ReadChar END; (* Skip leading blanks, CR, LF, tab etc. *)
END Skip;

PROCEDURE HugeInt*(VAR h: HUGEINT);
VAR
  neg, hex, decdigit, hexdigit: BOOLEAN;
  decacc, hexacc, digit: HUGEINT;
BEGIN
  Flush; Skip;

  neg      := nextch = '-'; IF neg THEN ReadChar END;
  hex      := FALSE;
  endofnum := FALSE;
  decacc   := 0;
  hexacc   := 0;
  Done     := FALSE;

  WHILE ready & ~endofnum DO
    decdigit := (nextch >= "0") & (nextch <= "9");
    IF decdigit THEN digit := ORD(nextch) MOD 16 END;

    hexdigit := (nextch >= "f") & (nextch <= "f")  OR  (nextch >= "A") & (nextch <= "F");
    IF hexdigit THEN ORD(nextch) MOD 16 + 9; hex := TRUE END;

    IF decdigit OR hexdigit THEN
      Done := TRUE;
      decacc := decacc * 10 + digit;
      hexacc := hexacc * 16 + digit;
      ReadChar
    ELSIF nextch = "H" THEN
      hex := TRUE; endofnum := TRUE; ReadChar
    ELSE
      endofnum := TRUE
    END
  END;
  IF Done THEN
    IF hex THEN h := hexacc ELSE h := decacc END;
    IF neg THEN h := -h END
  ELSE
    h := 0
  END
END HugeInt;

PROCEDURE Int*(VAR i: INTEGER);
  VAR h: HUGEINT;
BEGIN HugeInt(h); i := SYSTEM.VAL(INTEGER, h)
END Int;

PROCEDURE LongInt*(VAR i: LONGINT);
  VAR h: HUGEINT;
BEGIN HugeInt(h); i := SYSTEM.VAL(LONGINT, h)
END LongInt;

PROCEDURE Real*(VAR x: REAL);
BEGIN ASSERT(FALSE) (* Not implemented *)
END Real;

PROCEDURE LongReal*(VAR y: LONGREAL);
BEGIN ASSERT(FALSE) (* Not implemented *)
END LongReal;

PROCEDURE String*(VAR str: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN Flush; Skip; i := 0;
  IF ready AND nextch = '"' THEN  (* " *)
    ReadChar;
    WHILE ready & (i < LEN(str)-1) & (nextch >= " ") & (nextch # '"') DO (* " *)
      str[i] := nextch; INC(i)
    END
  END;
  Done := ready & (i < LEN(str)-1) & (nextch = '"'); (* " *)
  IF Done THEN
    ReadChar; str[i] := 0X
  ELSE
    str[0] := 0X
  END
END String;

PROCEDURE Name*(VAR name: ARRAY OF CHAR); (* Read filename. Presumably using shell semantics. *)
BEGIN ASSERT(FALSE) (* Not implemented *)
END Name;

BEGIN
  nextch      := 0X;
  ready        := FALSE;
  initialized := FALSE;
END In.
