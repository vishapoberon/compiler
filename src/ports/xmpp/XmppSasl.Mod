MODULE XmppSasl;

(* SASL PLAIN initial response: empty authorization identity, UTF-8 authentication
   identity and password. Callers explicitly authorize PLAIN over verified TLS. *)

IMPORT Msg, S := LongStrings, T := XmppTypes, Items := XmppItems,
  C := XMLUnicodeCodec, UTF8 := XMLUnicodeCodecUTF8;

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
  VAR userBytes, passBytes: Items.Bytes; userLen, passLen, length, i, j, k, value: LONGINT;
    block: ARRAY 3 OF LONGINT; ok: BOOLEAN; alphabet: ARRAY 65 OF CHAR;
BEGIN
  alphabet := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  response := NIL; error := NIL; userBytes := NIL; passBytes := NIL;
  ok := verifiedTLS;
  IF ok THEN ok := Encode(username, userBytes, userLen) END;
  IF ok THEN ok := Encode(password, passBytes, passLen) END;
  IF ok THEN
    length := userLen+passLen+2; NEW(response, ((length+2) DIV 3)*4+1); i := 0; j := 0;
    WHILE i < length DO
      FOR k := 0 TO 2 DO
        value := i+k;
        IF (value = 0) OR (value = userLen+1) OR (value >= length) THEN block[k] := 0
        ELSIF value <= userLen THEN block[k] := ORD(userBytes[value-1])
        ELSE block[k] := ORD(passBytes[value-userLen-2])
        END
      END;
      response[j] := ORD(alphabet[block[0] DIV 4]);
      response[j+1] := ORD(alphabet[(block[0] MOD 4)*16+block[1] DIV 16]);
      IF i+1 < length THEN response[j+2] := ORD(alphabet[(block[1] MOD 16)*4+block[2] DIV 64])
      ELSE response[j+2] := ORD("=")
      END;
      IF i+2 < length THEN response[j+3] := ORD(alphabet[block[2] MOD 64])
      ELSE response[j+3] := ORD("=")
      END;
      INC(i, 3); INC(j, 4)
    END;
    response[j] := 0
  ELSE error := Msg.New(context, 1)
  END;
  IF userBytes # NIL THEN FOR i := 0 TO LEN(userBytes^)-1 DO userBytes[i] := 0X END END;
  IF passBytes # NIL THEN FOR i := 0 TO LEN(passBytes^)-1 DO passBytes[i] := 0X END END
END Plain;

BEGIN
  NEW(context); Msg.InitContext(context, "XmppSasl")
END XmppSasl.
