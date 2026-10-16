MODULE TLSTestX509Names;
IMPORT Out, TLSBytes, TLSX509, TLSX509Names;

VAR cert, san: TLSBytes.Buffer;
    info: TLSX509.CertInfo;
    saw: BOOLEAN;

PROCEDURE HexVal(ch: CHAR): LONGINT;
VAR o: LONGINT;
BEGIN
  o := ORD(ch);
  IF (o >= ORD("0")) & (o <= ORD("9")) THEN RETURN o - ORD("0") END;
  IF (o >= ORD("A")) & (o <= ORD("F")) THEN RETURN o - ORD("A") + 10 END;
  IF (o >= ORD("a")) & (o <= ORD("f")) THEN RETURN o - ORD("a") + 10 END;
  RETURN 0
END HexVal;

PROCEDURE HexToBuf(hex: ARRAY OF CHAR; VAR b: TLSBytes.Buffer);
VAR i: LONGINT;
BEGIN
  TLSBytes.Init(b); i := 0;
  WHILE (i + 1 < LEN(hex)) & (hex[i] # 0X) & (hex[i+1] # 0X) DO
    TLSBytes.AppendByte(b, HexVal(hex[i]) * 16 + HexVal(hex[i+1]));
    INC(i, 2)
  END
END HexToBuf;

(* hex appended to b (for long values: the ARM compiler of polpo takes short strings) *)
PROCEDURE HexAdd(hex: ARRAY OF CHAR; VAR b: TLSBytes.Buffer);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i + 1 < LEN(hex)) & (hex[i] # 0X) & (hex[i+1] # 0X) DO
    TLSBytes.AppendByte(b, HexVal(hex[i]) * 16 + HexVal(hex[i+1]));
    INC(i, 2)
  END
END HexAdd;

PROCEDURE Say(label: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  Out.String(label);
  IF ok THEN Out.String(" OK") ELSE Out.String(" FAIL") END;
  Out.Ln
END Say;

PROCEDURE PrintHex(VAR b: TLSBytes.Buffer);
VAR i, x, hi, lo: LONGINT;
BEGIN
  i := 0;
  WHILE i < b.len DO
    x := ORD(b.data[i]); hi := x DIV 16; lo := x MOD 16;
    IF hi < 10 THEN Out.Char(CHR(ORD("0") + hi)) ELSE Out.Char(CHR(ORD("A") + hi - 10)) END;
    IF lo < 10 THEN Out.Char(CHR(ORD("0") + lo)) ELSE Out.Char(CHR(ORD("A") + lo - 10)) END;
    INC(i)
  END
END PrintHex;

BEGIN
  HexToBuf("308190307AA003020102020101300D06092A864886F70D01010B05003000301E170D3234303130313030303030305A170D32", cert);
  HexAdd("35303130313030303030305A30003014300D06092A864886F70D01010105000303003000A327302530230603551D11041C30", cert);
  HexAdd("1A82096E6F726179722E616D820D2A2E6578616D706C652E636F6D300D06092A864886F70D01010B0500030300AABB", cert);

  Say("parse", TLSX509.ParseCertificate(cert, info));
  Say("san value", TLSX509Names.SubjectAltNameValue(info, san));
  Out.String("san der = ");
  PrintHex(san); Out.Ln;
  Say("match norayr.am", TLSX509Names.SubjectAltNameMatches(san, "norayr.am", saw));
  Say("saw dns", saw);
  Say("match WWW case", TLSX509Names.SubjectAltNameMatches(san, "NORAYR.AM", saw));
  Say("wildcard yes", TLSX509Names.SubjectAltNameMatches(san, "www.example.com", saw));
  Say("wildcard no apex", ~TLSX509Names.SubjectAltNameMatches(san, "example.com", saw));
  Say("wildcard no deep", ~TLSX509Names.SubjectAltNameMatches(san, "a.b.example.com", saw));
  Say("cert host yes", TLSX509Names.CertMatchesHostname(cert, "norayr.am"));
  Say("cert host no", ~TLSX509Names.CertMatchesHostname(cert, "evil.example.net"))
END TLSTestX509Names.
