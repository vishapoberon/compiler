MODULE IDNA;

(* UTF-8 DNS host names: non-transitional UTS #46 mapping, Unicode 16.0 NFC,
   IDNA2008 context checks, RFC 5893 bidi rules and canonical RFC 3492 labels.
   Names returns Unicode XML identities and ASCII DNS/TLS identities together. *)

IMPORT Punycode, Mapping := IDNAMapping, Data := IDNAData, NFC := UnicodeNFC;

CONST invalidName* = -1; maxInputBytes* = 1023;
TYPE String* = POINTER TO ARRAY OF CHAR;
  Scalars = ARRAY NFC.maxScalars OF LONGINT;

PROCEDURE ReadUTF8(input: ARRAY OF CHAR; length: LONGINT; VAR position, character: LONGINT): BOOLEAN;
  VAR byte, needed, minimum, i: LONGINT;
BEGIN
  byte := ORD(input[position]); INC(position);
  IF byte < 128 THEN character := byte; RETURN TRUE END;
  IF (byte >= 0C2H) & (byte <= 0DFH) THEN needed := 1; character := byte MOD 32; minimum := 80H
  ELSIF (byte >= 0E0H) & (byte <= 0EFH) THEN needed := 2; character := byte MOD 16; minimum := 800H
  ELSIF (byte >= 0F0H) & (byte <= 0F4H) THEN needed := 3; character := byte MOD 8; minimum := 10000H
  ELSE RETURN FALSE
  END;
  IF needed > length-position THEN RETURN FALSE END;
  FOR i := 1 TO needed DO
    byte := ORD(input[position]); INC(position);
    IF (byte < 80H) OR (byte > 0BFH) THEN RETURN FALSE END;
    character := character*64+byte MOD 64
  END;
  RETURN (character >= minimum) & Punycode.Scalar(character)
END ReadUTF8;

PROCEDURE Map(input: ARRAY OF CHAR; VAR output: Scalars; VAR count: LONGINT): BOOLEAN;
  VAR mapped: Scalars; i, length, character, row, offset, n, j, used: LONGINT;
    status: CHAR; ok: BOOLEAN;
BEGIN
  length := 0; count := 0;
  WHILE (length < LEN(input)) & (input[length] # 0X) DO
    character := ORD(input[length]);
    IF (character < 128) & ~(((character >= ORD("a")) & (character <= ORD("z"))) OR
       ((character >= ORD("A")) & (character <= ORD("Z"))) OR
       ((character >= ORD("0")) & (character <= ORD("9"))) OR (character = ORD("-")) OR
       (character = ORD("."))) THEN RETURN FALSE END;
    INC(length); IF length > maxInputBytes THEN RETURN FALSE END
  END;
  IF (length = 0) OR (length = LEN(input)) THEN RETURN FALSE END;
  i := 0; used := 0;
  WHILE i < length DO
    IF ~ReadUTF8(input, length, i, character) THEN RETURN FALSE END;
    row := Mapping.Find(character); status := CHR(Mapping.Word(row+1));
    IF (status = "V") OR (status = "D") THEN
      IF used = LEN(mapped) THEN RETURN FALSE END;
      mapped[used] := character; INC(used)
    ELSIF status = "M" THEN
      offset := Mapping.pool+Mapping.Word(row+2); n := Mapping.Word(row+3);
      IF n > LEN(mapped)-used THEN RETURN FALSE END;
      FOR j := 0 TO n-1 DO mapped[used] := Mapping.Word(offset+j); INC(used) END
    ELSIF status # "I" THEN RETURN FALSE
    END
  END;
  NFC.Normalize(mapped, used, output, count, ok); RETURN ok & (count > 0)
END Map;

PROCEDURE Script(character, bit: LONGINT): BOOLEAN;
BEGIN RETURN ODD(Data.Properties(character) DIV bit)
END Script;

PROCEDURE Context(label: ARRAY OF LONGINT; count, position: LONGINT): BOOLEAN;
  VAR character, i, joining: LONGINT; left, right: BOOLEAN;
BEGIN
  character := label[position];
  IF (character = 200CH) OR (character = 200DH) THEN
    IF (position > 0) & (Data.Combining(label[position-1]) = 9) THEN RETURN TRUE END;
    IF character = 200DH THEN RETURN FALSE END;
    left := FALSE; right := FALSE; i := position-1;
    LOOP
      IF i < 0 THEN EXIT END;
      joining := Data.Properties(label[i]) DIV 2097152;
      IF joining # 4 THEN left := (joining = 1) OR (joining = 3); EXIT END;
      DEC(i)
    END;
    i := position+1;
    LOOP
      IF i >= count THEN EXIT END;
      joining := Data.Properties(label[i]) DIV 2097152;
      IF joining # 4 THEN right := (joining = 2) OR (joining = 3); EXIT END;
      INC(i)
    END;
    RETURN left & right
  ELSIF character = 0B7H THEN
    RETURN (position > 0) & (position+1 < count) & (label[position-1] = ORD("l")) & (label[position+1] = ORD("l"))
  ELSIF character = 375H THEN
    RETURN (position+1 < count) & Script(label[position+1], 65536)
  ELSIF (character = 5F3H) OR (character = 5F4H) THEN
    RETURN (position > 0) & Script(label[position-1], 131072)
  ELSIF character = 30FBH THEN
    FOR i := 0 TO count-1 DO
      IF (label[i] # 30FBH) & (Script(label[i], 262144) OR Script(label[i], 524288) OR Script(label[i], 1048576)) THEN
        RETURN TRUE
      END
    END;
    RETURN FALSE
  ELSIF (character >= 660H) & (character <= 669H) THEN
    FOR i := 0 TO count-1 DO IF (label[i] >= 6F0H) & (label[i] <= 6F9H) THEN RETURN FALSE END END;
    RETURN TRUE
  ELSIF (character >= 6F0H) & (character <= 6F9H) THEN
    FOR i := 0 TO count-1 DO IF (label[i] >= 660H) & (label[i] <= 669H) THEN RETURN FALSE END END;
    RETURN TRUE
  END;
  RETURN FALSE
END Context;

PROCEDURE Bidi(label: ARRAY OF LONGINT; start, count: LONGINT): BOOLEAN;
  VAR direction, i, number: LONGINT; rtl, ending: BOOLEAN;
BEGIN
  direction := Data.Properties(label[start]) DIV 256 MOD 32;
  rtl := (direction = 2) OR (direction = 3);
  IF ~rtl & (direction # 1) THEN RETURN FALSE END;
  ending := FALSE; number := 0;
  FOR i := start TO start+count-1 DO
    direction := Data.Properties(label[i]) DIV 256 MOD 32;
    IF rtl THEN
      IF ~((direction >= 2) & (direction <= 10) OR (direction = 14)) THEN RETURN FALSE END;
      IF (direction = 2) OR (direction = 3) OR (direction = 4) OR (direction = 7) THEN ending := TRUE
      ELSIF direction # 9 THEN ending := FALSE
      END;
      IF (direction = 4) OR (direction = 7) THEN
        IF (number # 0) & (number # direction) THEN RETURN FALSE END;
        number := direction
      END
    ELSE
      IF ~((direction = 1) OR (direction >= 4) & (direction <= 6) OR (direction >= 8) & (direction <= 10) OR (direction = 14)) THEN
        RETURN FALSE
      END;
      IF (direction = 1) OR (direction = 4) THEN ending := TRUE
      ELSIF direction # 9 THEN ending := FALSE
      END
    END
  END;
  RETURN ending
END Bidi;

PROCEDURE Label(label: ARRAY OF LONGINT; count: LONGINT): BOOLEAN;
  VAR normalized: ARRAY 63 OF LONGINT; n, i, properties, valid: LONGINT; ok: BOOLEAN;
BEGIN
  IF (count = 0) OR (count > 63) THEN RETURN FALSE END;
  IF (label[0] = ORD("-")) OR (label[count-1] = ORD("-")) OR
     (count >= 4) & (label[2] = ORD("-")) & (label[3] = ORD("-")) THEN RETURN FALSE END;
  IF ODD(Data.Properties(label[0]) DIV 8192) THEN RETURN FALSE END;
  NFC.Normalize(label, count, normalized, n, ok);
  IF ~ok OR (n # count) THEN RETURN FALSE END;
  FOR i := 0 TO count-1 DO
    IF normalized[i] # label[i] THEN RETURN FALSE END;
    properties := Data.Properties(label[i]); valid := properties DIV 16384 MOD 4;
    IF valid = 0 THEN RETURN FALSE END;
    IF (valid # 1) & ~Context(label, count, i) THEN RETURN FALSE END
  END;
  RETURN TRUE
END Label;

PROCEDURE PutUTF8(character: LONGINT; VAR output: ARRAY OF CHAR; VAR length: LONGINT): BOOLEAN;
  VAR size: LONGINT;
BEGIN
  IF character < 80H THEN size := 1
  ELSIF character < 800H THEN size := 2
  ELSIF character < 10000H THEN size := 3
  ELSE size := 4
  END;
  IF size >= LEN(output)-length THEN RETURN FALSE END;
  IF size = 1 THEN output[length] := CHR(character)
  ELSIF size = 2 THEN
    output[length] := CHR(0C0H+character DIV 64); output[length+1] := CHR(80H+character MOD 64)
  ELSIF size = 3 THEN
    output[length] := CHR(0E0H+character DIV 4096); output[length+1] := CHR(80H+character DIV 64 MOD 64);
    output[length+2] := CHR(80H+character MOD 64)
  ELSE
    output[length] := CHR(0F0H+character DIV 262144); output[length+1] := CHR(80H+character DIV 4096 MOD 64);
    output[length+2] := CHR(80H+character DIV 64 MOD 64); output[length+3] := CHR(80H+character MOD 64)
  END;
  INC(length, size); RETURN TRUE
END PutUTF8;

PROCEDURE Names*(input: ARRAY OF CHAR; VAR unicodeName, asciiName: String; VAR result: LONGINT);
  VAR mapped, canonical: Scalars;
    label, decoded: ARRAY 63 OF LONGINT;
    encoded, payload: ARRAY 256 OF CHAR;
    ascii: ARRAY 254 OF CHAR; unicode: ARRAY maxInputBytes+1 OF CHAR;
    count, position, n, i, j, written, status, decodedCount, used, aLength, uLength, direction, start: LONGINT;
    nonASCII, alabel, bidi: BOOLEAN;
BEGIN
  unicodeName := NIL; asciiName := NIL; result := invalidName;
  IF ~Map(input, mapped, count) THEN RETURN END;
  position := 0; used := 0; aLength := 0; uLength := 0; bidi := FALSE;
  WHILE position < count DO
    n := 0; nonASCII := FALSE;
    WHILE (position < count) & (mapped[position] # ORD(".")) DO
      IF n = LEN(label) THEN RETURN END;
      label[n] := mapped[position]; nonASCII := nonASCII OR (label[n] >= 128); INC(n); INC(position)
    END;
    IF n = 0 THEN RETURN END;
    alabel := ~nonASCII & (n >= 4) & (label[0] = ORD("x")) & (label[1] = ORD("n")) &
      (label[2] = ORD("-")) & (label[3] = ORD("-"));
    IF alabel THEN
      FOR i := 4 TO n-1 DO payload[i-4] := CHR(label[i]) END;
      Punycode.Decode(payload, n-4, decoded, decodedCount, status);
      IF (status # Punycode.done) OR ~Label(decoded, decodedCount) THEN RETURN END;
      Punycode.Encode(decoded, decodedCount, encoded, written, status);
      IF (status # Punycode.done) OR (written # n-4) THEN RETURN END;
      FOR i := 0 TO written-1 DO IF encoded[i] # payload[i] THEN RETURN END END;
      nonASCII := FALSE;
      FOR i := 0 TO decodedCount-1 DO
        label[i] := decoded[i]; nonASCII := nonASCII OR (label[i] >= 128)
      END;
      IF ~nonASCII THEN RETURN END;
      n := decodedCount
    ELSIF ~Label(label, n) THEN RETURN
    END;
    IF nonASCII THEN
      Punycode.Encode(label, n, payload, written, status);
      IF (status # Punycode.done) OR (written > 59) THEN RETURN END;
      encoded[0] := "x"; encoded[1] := "n"; encoded[2] := "-"; encoded[3] := "-";
      FOR i := 0 TO written-1 DO encoded[i+4] := payload[i] END;
      INC(written, 4)
    ELSE
      written := n; FOR i := 0 TO n-1 DO encoded[i] := CHR(label[i]) END
    END;
    IF written > 253-aLength THEN RETURN END;
    FOR i := 0 TO written-1 DO ascii[aLength] := encoded[i]; INC(aLength) END;
    IF n > LEN(canonical)-used THEN RETURN END;
    FOR i := 0 TO n-1 DO
      canonical[used] := label[i]; INC(used);
      IF ~PutUTF8(label[i], unicode, uLength) THEN RETURN END;
      direction := Data.Properties(label[i]) DIV 256 MOD 32;
      bidi := bidi OR (direction = 2) OR (direction = 3) OR (direction = 7)
    END;
    IF position < count THEN
      INC(position);
      IF (position = count) OR (aLength >= 253) OR (used = LEN(canonical)) THEN RETURN END;
      ascii[aLength] := "."; INC(aLength); canonical[used] := ORD("."); INC(used);
      IF ~PutUTF8(ORD("."), unicode, uLength) THEN RETURN END
    END
  END;
  IF bidi THEN
    start := 0;
    WHILE start < used DO
      j := start; WHILE (j < used) & (canonical[j] # ORD(".")) DO INC(j) END;
      IF ~Bidi(canonical, start, j-start) THEN RETURN END;
      start := j+1
    END
  END;
  ascii[aLength] := 0X; unicode[uLength] := 0X;
  NEW(asciiName, aLength+1); NEW(unicodeName, uLength+1);
  FOR i := 0 TO aLength DO asciiName[i] := ascii[i] END;
  FOR i := 0 TO uLength DO unicodeName[i] := unicode[i] END;
  result := 0
END Names;

END IDNA.
