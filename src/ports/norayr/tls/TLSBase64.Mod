MODULE TLSBase64;
 IMPORT Out, Strings, TLSBytes;
VAR
  EncodingTable : ARRAY 65 OF CHAR;  (* 64 characters and 0X: with 64, COPY dropped the "/" *)
  fixToIncludeEOL*: BOOLEAN;

PROCEDURE GetEncodingChar(index: LONGINT): CHAR;
BEGIN
    RETURN EncodingTable[index]
END GetEncodingChar;

PROCEDURE IsWhite(ch: CHAR): BOOLEAN;
BEGIN
  RETURN (ch = 0AX) OR (ch = 0DX) OR (ch = " ") OR (ch = 09X)
END IsWhite;

PROCEDURE DecVal(ch: CHAR; VAR v: LONGINT): BOOLEAN;
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE i < 64 DO
    IF EncodingTable[i] = ch THEN
      v := i; RETURN TRUE
    END;
    INC(i)
  END;
  v := 0; RETURN FALSE
END DecVal;

PROCEDURE fix(VAR src: ARRAY OF CHAR);
VAR
  l: LONGINT;
BEGIN
  l := Strings.Length(src);
  IF l+1 < LEN(src) THEN
    src[l] := 0AX;
    src[l+1] := 0X
  ELSE
    Out.String("warning, passed string has not enough capacity to be fixed to contain 0A"); Out.Ln
  END
END fix;

PROCEDURE EncodeString*(src: ARRAY OF CHAR; VAR dst: ARRAY OF CHAR);
VAR
  i, j, k, srcLength, dstLen: LONGINT;
  block: ARRAY 3 OF LONGINT;
  enc: ARRAY 4 OF LONGINT;
  pad: LONGINT;
BEGIN
  IF fixToIncludeEOL THEN fix(src) END;
  dstLen := LEN(dst);
  j := 0;
  i := 0;
  srcLength := Strings.Length(src);

  WHILE i < srcLength DO
    k := 0;
    WHILE k <= 2 DO
      IF i+k < srcLength THEN
        block[k] := ORD(src[i+k])
      ELSE
        block[k] := 0
      END;
      INC(k)
    END;

    enc[0] := block[0] DIV 4;
    enc[1] := (block[0] MOD 4) * 16 + block[1] DIV 16;
    enc[2] := (block[1] MOD 16) * 4 + block[2] DIV 64;
    enc[3] := block[2] MOD 64;

    IF i+3 > srcLength THEN
      pad := 3 - (srcLength - i)
    ELSE
      pad := 0
    END;

    k := 0;
    WHILE k <= 3 DO
      IF j+k < dstLen THEN
        IF k >= 4 - pad THEN
          dst[j+k] := "="
        ELSE
          dst[j+k] := GetEncodingChar(enc[k])
        END
      ELSE
        Out.String("destination capacity is not enough to fit base64 encoded string"); Out.Ln;
        HALT(100)
      END;
      INC(k)
    END;

    INC(i, 3);
    INC(j, 4)
  END;
  IF j < dstLen THEN dst[j] := 0X
  ELSE Out.String("destination capacity is not enough for the 0X after the base64 encoded string"); Out.Ln; HALT(100)
  END
END EncodeString;

(* Binary-safe decoder.  Whitespace is ignored.  dst.len is authoritative;
   decoded data may contain 0X bytes, so do not use Strings.Length on it. *)
PROCEDURE DecodeToBuffer*(src: ARRAY OF CHAR; VAR dst: TLSBytes.Buffer): BOOLEAN;
VAR
  i, n, pad, val: LONGINT;
  block: ARRAY 4 OF LONGINT;
  ch: CHAR;
  ok, finished: BOOLEAN;
BEGIN
  TLSBytes.Init(dst);
  i := 0; finished := FALSE;
  WHILE (i < LEN(src)) & (src[i] # 0X) & ~finished DO
    n := 0; pad := 0;
    WHILE (n < 4) & (i < LEN(src)) & (src[i] # 0X) DO
      ch := src[i]; INC(i);
      IF IsWhite(ch) THEN
        (* skip *)
      ELSE
        IF ch = "=" THEN
          block[n] := 0; INC(n); INC(pad)
        ELSE
          ok := DecVal(ch, val);
          IF ~ok THEN RETURN FALSE END;
          IF pad # 0 THEN RETURN FALSE END;
          block[n] := val; INC(n)
        END
      END
    END;

    IF n = 0 THEN
      finished := TRUE
    ELSE
      IF n # 4 THEN RETURN FALSE END;
      TLSBytes.AppendByte(dst, block[0] * 4 + block[1] DIV 16);
      IF pad < 2 THEN
        TLSBytes.AppendByte(dst, (block[1] MOD 16) * 16 + block[2] DIV 4)
      END;
      IF pad < 1 THEN
        TLSBytes.AppendByte(dst, (block[2] MOD 4) * 64 + block[3])
      END;
      IF pad # 0 THEN finished := TRUE END
    END
  END;
  RETURN TRUE
END DecodeToBuffer;

PROCEDURE DecodeString*(src: ARRAY OF CHAR; VAR dst: ARRAY OF CHAR);
VAR b: TLSBytes.Buffer; i: LONGINT; ok: BOOLEAN;
BEGIN
  ok := DecodeToBuffer(src, b);
  IF ~ok THEN
    Out.String("Invalid character in Base64 encoded string"); Out.Ln;
    HALT(100)
  END;
  IF b.len >= LEN(dst) THEN
    Out.String("destination capacity is not enough to fit base64 decoded string"); Out.Ln;
    HALT(100)
  END;
  i := 0;
  WHILE i < b.len DO
    dst[i] := b.data[i]; INC(i)
  END;
  dst[b.len] := 0X
END DecodeString;

BEGIN
  fixToIncludeEOL := TRUE;
  COPY("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", EncodingTable)
END TLSBase64.
