MODULE IDNA;

(* UTF-8 internationalized DNS names through libidn2. Non-transitional UTS #46
   processing supplies NFC, case mapping and IDNA2008 validation. Native buffers
   are copied into Oberon-owned arrays and released before returning. *)

IMPORT SYSTEM;

CONST invalidName* = -1; maxInputBytes* = 1023;
TYPE String* = POINTER TO ARRAY OF CHAR;

PROCEDURE -AAinclude "#include <idn2.h>";
(* Check ASCII syntax after mapping: libidn2's STD3 option can discard mapped
   punctuation, turning malformed names into a different valid identity. *)
PROCEDURE -Lookup(input: ARRAY OF CHAR; VAR output: SYSTEM.ADDRESS; VAR result: LONGINT)
  "{ uint8_t *name = NULL; *(result) = (LONGINT)idn2_lookup_u8((const uint8_t*)input, &name, IDN2_NONTRANSITIONAL); *(output) = (ADDRESS)name; }";
PROCEDURE -Unicode(input: ARRAY OF CHAR; VAR output: SYSTEM.ADDRESS; VAR result: LONGINT)
  "{ char *name = NULL; *(result) = (LONGINT)idn2_to_unicode_8z8z((const char*)input, &name, 0); *(output) = (ADDRESS)name; }";
PROCEDURE -Free(address: SYSTEM.ADDRESS) "idn2_free((void*)address)";

PROCEDURE Copy(address: SYSTEM.ADDRESS; maximum: LONGINT): String;
  VAR result: String; byte: CHAR; length, i: LONGINT;
BEGIN
  IF address = 0 THEN RETURN NIL END;
  length := 0;
  LOOP
    SYSTEM.GET(address+length, byte);
    IF byte = 0X THEN EXIT END;
    INC(length); IF length > maximum THEN RETURN NIL END
  END;
  NEW(result, length+1);
  FOR i := 0 TO length DO SYSTEM.GET(address+i, result[i]) END;
  RETURN result
END Copy;

PROCEDURE ASCIIName(name: ARRAY OF CHAR): BOOLEAN;
  VAR i, length, label: LONGINT; byte: CHAR;
BEGIN
  length := 0; WHILE (length < LEN(name)) & (name[length] # 0X) DO INC(length) END;
  IF (length = 0) OR (length > 253) OR (length = LEN(name)) THEN RETURN FALSE END;
  label := 0;
  FOR i := 0 TO length-1 DO
    byte := name[i];
    IF byte = "." THEN
      IF (label = 0) OR (name[i-1] = "-") THEN RETURN FALSE END;
      label := 0
    ELSE
      IF ~(((byte >= "a") & (byte <= "z")) OR ((byte >= "0") & (byte <= "9")) OR (byte = "-")) THEN
        RETURN FALSE
      END;
      IF (label = 0) & (byte = "-") THEN RETURN FALSE END;
      INC(label); IF label > 63 THEN RETURN FALSE END
    END
  END;
  RETURN (label > 0) & (name[length-1] # "-")
END ASCIIName;

PROCEDURE Names*(input: ARRAY OF CHAR; VAR unicodeName, asciiName: String; VAR result: LONGINT);
(* Returns both canonical UTF-8 U-labels and ASCII A-labels, or NIL outputs.
   Requires DNS host-name syntax; trailing root dots and ASCII separators such
   as @, / and : are rejected. Input is explicitly UTF-8, independent of locale. *)
  VAR address: SYSTEM.ADDRESS; i: LONGINT; byte: CHAR;
BEGIN
  unicodeName := NIL; asciiName := NIL; result := invalidName; i := 0;
  WHILE (i < LEN(input)) & (input[i] # 0X) DO
    byte := input[i];
    IF (byte < 80X) & ~(((byte >= "a") & (byte <= "z")) OR ((byte >= "A") & (byte <= "Z")) OR
       ((byte >= "0") & (byte <= "9")) OR (byte = "-") OR (byte = ".")) THEN RETURN END;
    INC(i); IF i > maxInputBytes THEN RETURN END
  END;
  IF (i = 0) OR (i = LEN(input)) THEN RETURN END;
  address := 0; Lookup(input, address, result);
  IF result = 0 THEN asciiName := Copy(address, 253) END;
  IF address # 0 THEN Free(address) END;
  IF (asciiName = NIL) OR ~ASCIIName(asciiName^) THEN
    asciiName := NIL; IF result = 0 THEN result := invalidName END; RETURN
  END;
  address := 0; Unicode(asciiName^, address, result);
  IF result = 0 THEN unicodeName := Copy(address, maxInputBytes) END;
  IF address # 0 THEN Free(address) END;
  IF unicodeName = NIL THEN asciiName := NIL; IF result = 0 THEN result := invalidName END END
END Names;

END IDNA.
