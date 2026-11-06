MODULE XmppBase64;

(* Bounded binary Base64 with explicit lengths and canonical padding. *)

IMPORT Items := XmppItems;

CONST maxBytes* = 65535; maxText* = 87380;

VAR alphabet: ARRAY 65 OF CHAR;

PROCEDURE Encode*(bytes: ARRAY OF CHAR; start, count: LONGINT): Items.Bytes;
  VAR text: Items.Bytes; i, j, a, b, c: LONGINT;
BEGIN
  IF (start < 0) OR (count < 0) OR (count > maxBytes) OR (start > LEN(bytes)) OR
     (count > LEN(bytes)-start) THEN RETURN NIL END;
  NEW(text, 4*((count+2) DIV 3)+1); i := start; j := 0;
  WHILE i < start+count DO
    a := ORD(bytes[i]); b := 0; c := 0;
    IF i+1 < start+count THEN b := ORD(bytes[i+1]) END;
    IF i+2 < start+count THEN c := ORD(bytes[i+2]) END;
    text[j] := alphabet[a DIV 4]; text[j+1] := alphabet[a MOD 4*16+b DIV 16];
    text[j+2] := "="; text[j+3] := "=";
    IF i+1 < start+count THEN text[j+2] := alphabet[b MOD 16*4+c DIV 64] END;
    IF i+2 < start+count THEN text[j+3] := alphabet[c MOD 64] END;
    INC(i, 3); INC(j, 4)
  END;
  text[j] := 0X; RETURN text
END Encode;

PROCEDURE Digit(c: CHAR): LONGINT;
BEGIN
  IF (c >= "A") & (c <= "Z") THEN RETURN ORD(c)-ORD("A")
  ELSIF (c >= "a") & (c <= "z") THEN RETURN ORD(c)-ORD("a")+26
  ELSIF (c >= "0") & (c <= "9") THEN RETURN ORD(c)-ORD("0")+52
  ELSIF c = "+" THEN RETURN 62
  ELSIF c = "/" THEN RETURN 63
  ELSE RETURN -1
  END
END Digit;

PROCEDURE Decode*(text: ARRAY OF CHAR; count, maximum: LONGINT; VAR length: LONGINT): Items.Bytes;
  VAR bytes: Items.Bytes; i, j, size, a, b, c, d: LONGINT;
BEGIN
  length := 0;
  IF (count < 0) OR (count > LEN(text)) OR (count > maxText) OR (count MOD 4 # 0) OR
     (maximum < 0) OR (maximum > maxBytes) THEN RETURN NIL END;
  size := count DIV 4*3;
  IF count > 0 THEN
    IF text[count-1] = "=" THEN DEC(size) END;
    IF text[count-2] = "=" THEN DEC(size) END
  END;
  IF size > maximum THEN RETURN NIL END;
  NEW(bytes, size+1); i := 0; j := 0;
  WHILE i < count DO
    a := Digit(text[i]); b := Digit(text[i+1]);
    IF (a < 0) OR (b < 0) THEN RETURN NIL END;
    c := Digit(text[i+2]); d := Digit(text[i+3]);
    IF text[i+2] = "=" THEN
      IF (text[i+3] # "=") OR (i+4 # count) OR (b MOD 16 # 0) THEN RETURN NIL END;
      c := 0; d := 0
    ELSIF text[i+3] = "=" THEN
      IF (c < 0) OR (i+4 # count) OR (c MOD 4 # 0) THEN RETURN NIL END;
      d := 0
    ELSIF (c < 0) OR (d < 0) THEN RETURN NIL
    END;
    bytes[j] := CHR(a*4+b DIV 16); INC(j);
    IF text[i+2] # "=" THEN bytes[j] := CHR(b MOD 16*16+c DIV 4); INC(j) END;
    IF text[i+3] # "=" THEN bytes[j] := CHR(c MOD 4*64+d); INC(j) END;
    INC(i, 4)
  END;
  bytes[size] := 0X; length := size; RETURN bytes
END Decode;

BEGIN COPY("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", alphabet)
END XmppBase64.
