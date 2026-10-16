MODULE TLSTestASN1;
IMPORT Out, TLSBytes, TLSASN1;

VAR
  der: TLSBytes.Buffer;
  pos, innerPos, innerLim: LONGINT;
  t: TLSASN1.TLV;
  oid: ARRAY 64 OF CHAR;
  ok: BOOLEAN;

PROCEDURE PrintHex(VAR b: TLSBytes.Buffer);
VAR i, x: LONGINT;
BEGIN
  i := 0;
  WHILE i < b.len DO
    x := ORD(b.data[i]);
    IF x < 16 THEN Out.Char("0") END;
    Out.Hex(x, 0);
    INC(i)
  END
END PrintHex;

PROCEDURE Say(name: ARRAY OF CHAR; good: BOOLEAN);
BEGIN
  Out.String(name);
  IF good THEN Out.String(" OK") ELSE Out.String(" FAIL") END;
  Out.Ln
END Say;

BEGIN
  TLSBytes.Init(der);
  (* SEQUENCE { INTEGER 1, OID sha256WithRSAEncryption, NULL } *)
  TLSBytes.AppendByte(der, 30H); TLSBytes.AppendByte(der, 10H);
  TLSBytes.AppendByte(der, 02H); TLSBytes.AppendByte(der, 01H); TLSBytes.AppendByte(der, 01H);
  TLSBytes.AppendByte(der, 06H); TLSBytes.AppendByte(der, 09H);
  TLSBytes.AppendByte(der, 2AH); TLSBytes.AppendByte(der, 86H); TLSBytes.AppendByte(der, 48H);
  TLSBytes.AppendByte(der, 86H); TLSBytes.AppendByte(der, 0F7H); TLSBytes.AppendByte(der, 0DH);
  TLSBytes.AppendByte(der, 01H); TLSBytes.AppendByte(der, 01H); TLSBytes.AppendByte(der, 0BH);
  TLSBytes.AppendByte(der, 05H); TLSBytes.AppendByte(der, 00H);

  Out.String("der = "); PrintHex(der); Out.Ln;

  pos := 0;
  ok := TLSASN1.EnterSequence(der, pos, der.len, innerPos, innerLim);
  Say("enter seq", ok);
  IF ok THEN
    pos := innerPos;
    ok := TLSASN1.ExpectTag(der, pos, innerLim, TLSASN1.Integer, t);
    Say("integer", ok & (t.len = 1) & (ORD(der.data[t.val]) = 1));
    ok := TLSASN1.ExpectTag(der, pos, innerLim, TLSASN1.ObjectIdentifier, t);
    IF ok THEN TLSASN1.OIDToText(der, t, oid) ELSE oid[0] := 0X END;
    Out.String("oid = "); Out.String(oid); Out.Ln;
    Say("oid sha256WithRSA", ok & (oid = "1.2.840.113549.1.1.11"));
    ok := TLSASN1.ExpectTag(der, pos, innerLim, TLSASN1.Null, t);
    Say("null", ok & (t.len = 0));
    Say("end", pos = innerLim)
  END
END TLSTestASN1.
