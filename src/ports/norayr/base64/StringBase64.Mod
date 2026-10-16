MODULE StringBase64;
 IMPORT Out, Strings;  (* polpo: Out := out, Strings := strings *)
VAR
  EncodingTable : ARRAY 65 OF CHAR;  (* 64 characters and 0X: with 64, COPY dropped the "/" *)
  fixToIncludeEOL*: BOOLEAN;
(* Function to safely access characters in the EncodingTable *)
PROCEDURE GetEncodingChar(index: LONGINT): CHAR;
BEGIN
    RETURN EncodingTable[index];
END GetEncodingChar;

PROCEDURE fix(VAR src: ARRAY OF CHAR);
VAR
  l: LONGINT;
BEGIN
  l := Strings.Length(src);
  IF l+1 < LEN(src) THEN
    src[l] := 0AX;
    src[l+1] := 0X;
  ELSE
    Out.String("warning, passed string has not enough capacity to be fixed to contain 0A"); Out.Ln;
  END;
END fix;

(* Encodes the input string into Base64 format and returns the result via a VAR parameter. *)

PROCEDURE EncodeString*(src: ARRAY OF CHAR; VAR dst: ARRAY OF CHAR);
VAR
  i, j, k, srcLength, dstLen: LONGINT;
  block: ARRAY 3 OF LONGINT;
  enc: ARRAY 4 OF LONGINT;
  pad: LONGINT;
BEGIN
  IF fixToIncludeEOL THEN fix(src) END;
  dstLen := LEN(dst);
  j := 0; (* Index for dst string *)
  i := 0; (* Index for src string *)
  srcLength := Strings.Length(src); (* Use the total allocated length of src *)

  WHILE i < srcLength DO
    (* Fill the block with up to three bytes of input *)
    k := 0;
    WHILE k <= 2 DO
      IF i+k < srcLength THEN
        block[k] := ORD(src[i+k])
      ELSE
        block[k] := 0;
      END;
      INC(k)
    END;

    (* Convert the 3 bytes into 4 encoded Base64 characters *)
    enc[0] := block[0] DIV 4;
    enc[1] := (block[0] MOD 4) * 16 + block[1] DIV 16;
    enc[2] := (block[1] MOD 16) * 4 + block[2] DIV 64;
    enc[3] := block[2] MOD 64;

    (* Determine the number of padding characters required *)
    IF i+3 > srcLength THEN
      pad := 3 - (srcLength - i)
    ELSE
      pad := 0;
    END;

    (* Write the encoded characters *)
    k := 0;
    WHILE k <= 3 DO
      IF j+k < dstLen THEN
        IF k >= 4 - pad THEN
          dst[j+k] := "=";
        ELSE
          dst[j+k] := GetEncodingChar(enc[k]);
        END;
      ELSE
        Out.String("destination capacity is not enough to fit base64 encoded string"); Out.Ln;
        HALT(100);
      END;
      INC(k)
    END;

    INC(i, 3);
    INC(j, 4);
  END;
  IF j < dstLen THEN dst[j] := 0X  (* Null-terminate the dst string *)
  ELSE Out.String("destination capacity is not enough for the 0X after the base64 encoded string"); Out.Ln; HALT(100)
  END
END EncodeString;

PROCEDURE GetDecodingChar(ch: CHAR): LONGINT;
VAR
  i: LONGINT;
BEGIN
  i := 0;
  WHILE i < 64 DO
    IF EncodingTable[i] = ch THEN
      RETURN i;
    END;
    INC(i)
  END;
  Out.String("Invalid character in Base64 encoded string"); Out.Ln;
  HALT(100);
END GetDecodingChar;

(* Decodes the input string from Base64 format and returns the result via a VAR parameter. *)

PROCEDURE DecodeString*(src: ARRAY OF CHAR; VAR dst: ARRAY OF CHAR);
VAR
  i, j, k, n, srcLength, dstLen: LONGINT;
  block: ARRAY 4 OF LONGINT;
  dec: ARRAY 3 OF LONGINT;
BEGIN
  dstLen := LEN(dst);
  j := 0; (* index for dst string *)
  i := 0; (* index for src string *)
  srcLength := Strings.Length(src);
  IF (dstLen = 0) OR (srcLength MOD 4 # 0) THEN
    Out.String("invalid base64 length or empty destination"); Out.Ln; HALT(100)
  END;

  WHILE i < srcLength DO
    (* initialize block *)
    k := 0;
    WHILE k <= 3 DO
      block[k] := 0;
      INC(k)
    END;

    (* convert base64 characters to indices *)
    k := 0;
    WHILE (k < 4) & (i+k < srcLength) & (src[i+k] # '=') DO
      block[k] := GetDecodingChar(src[i+k]);
      INC(k);
    END;
    IF k < 4 THEN
      IF (i + 4 # srcLength) OR (k < 2) THEN
        Out.String("invalid base64 padding"); Out.Ln; HALT(100)
      END;
      n := k;
      WHILE n < 4 DO
        IF src[i+n] # '=' THEN
          Out.String("invalid base64 padding"); Out.Ln; HALT(100)
        END;
        INC(n)
      END;
      IF ((k = 2) & (block[1] MOD 16 # 0)) OR
         ((k = 3) & (block[2] MOD 4 # 0)) THEN
        Out.String("invalid base64 padding bits"); Out.Ln; HALT(100)
      END
    END;

    (* convert indices to original bytes *)
    dec[0] := (block[0] * 4) + (block[1] DIV 16);
    dec[1] := ((block[1] MOD 16) * 16) + (block[2] DIV 4);
    dec[2] := ((block[2] MOD 4) * 64) + block[3];

    (* write the decoded bytes: n characters before the padding give n - 1 bytes *)
    n := k - 1; k := 0;
    WHILE k < n DO
      IF j < dstLen - 1 THEN
        dst[j] := CHR(dec[k]);
        INC(j);
      ELSE
        Out.String("destination capacity is not enough to fit base64 decoded string"); Out.Ln;
        HALT(100)
      END;
      INC(k)
    END;

    INC(i, 4);
  END;
  dst[j] := 0X;
END DecodeString;


BEGIN
  fixToIncludeEOL := TRUE;
  COPY("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", EncodingTable);

END StringBase64.
