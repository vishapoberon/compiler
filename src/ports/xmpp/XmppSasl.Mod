MODULE XmppSasl;

(* SASL PLAIN initial response: empty authorization identity, UTF-8 authentication
   identity and password. Callers explicitly authorize PLAIN over verified TLS. *)

IMPORT Msg, S := LongStrings, T := XmppTypes, Items := XmppItems,
  C := XMLUnicodeCodec, UTF8 := XMLUnicodeCodecUTF8, B := XmppBase64;

CONST maxFieldUnits* = 1024;

TYPE
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (c: Context) GetTemplate(message: Msg.Msg; VAR text: Msg.LString);
BEGIN S.Long("SASL PLAIN requires verified TLS and valid bounded UTF-16 credentials", text) END GetTemplate;

PROCEDURE Wipe*(text: T.String);
  VAR i: LONGINT;
BEGIN IF text # NIL THEN FOR i := 0 TO LEN(text^)-1 DO text[i] := 0 END END END Wipe;

PROCEDURE Encode(VAR text: ARRAY OF T.CodeUnit; VAR bytes: Items.Bytes; VAR length: LONGINT): BOOLEAN;
  VAR codec: C.Codec; pos, units: LONGINT;
BEGIN
  units := S.Length(text); length := 0; bytes := NIL;
  IF (units = 0) OR (units > maxFieldUnits) THEN RETURN FALSE END;
  NEW(bytes, 3*units+8); codec := UTF8.factory.NewCodec(); pos := 0;
  WHILE pos < units DO
    codec.Encode(text, pos, units, bytes^, length, LEN(bytes^), pos, length)
  END;
  RETURN codec.invalidChars = 0
END Encode;

PROCEDURE Plain*(VAR username, password: ARRAY OF T.CodeUnit; verifiedTLS: BOOLEAN;
                  VAR response: T.String; VAR error: Msg.Msg);
  VAR userBytes, passBytes, plain, encoded: Items.Bytes; userLen, passLen, length, i: LONGINT;
    ok: BOOLEAN;
BEGIN
  response := NIL; error := NIL; userBytes := NIL; passBytes := NIL;
  plain := NIL; encoded := NIL;
  ok := verifiedTLS;
  IF ok THEN ok := Encode(username, userBytes, userLen) END;
  IF ok THEN ok := Encode(password, passBytes, passLen) END;
  IF ok THEN
    length := userLen+passLen+2; NEW(plain, length);
    plain[0] := 0X; plain[userLen+1] := 0X;
    FOR i := 0 TO userLen-1 DO plain[i+1] := userBytes[i] END;
    FOR i := 0 TO passLen-1 DO plain[i+userLen+2] := passBytes[i] END;
    encoded := B.Encode(plain^, 0, length);
    IF encoded = NIL THEN ok := FALSE ELSE response := Items.Latin1(encoded^) END
  END;
  IF ~ok THEN error := Msg.New(context, 1) END;
  IF userBytes # NIL THEN FOR i := 0 TO LEN(userBytes^)-1 DO userBytes[i] := 0X END END;
  IF passBytes # NIL THEN FOR i := 0 TO LEN(passBytes^)-1 DO passBytes[i] := 0X END END;
  IF plain # NIL THEN FOR i := 0 TO LEN(plain^)-1 DO plain[i] := 0X END END;
  IF encoded # NIL THEN FOR i := 0 TO LEN(encoded^)-1 DO encoded[i] := 0X END END
END Plain;

BEGIN
  NEW(context); Msg.InitContext(context, "XmppSasl")
END XmppSasl.
