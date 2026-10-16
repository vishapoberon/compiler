MODULE TLSTestHandshake;
IMPORT Out, TLSBytes, TLS13Handshake;

PROCEDURE PrintHex(VAR b: TLSBytes.Buffer);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE i < b.len DO Out.Hex(ORD(b.data[i]), 2); INC(i) END
END PrintHex;

PROCEDURE Assert(name: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  Out.String(name);
  IF ok THEN Out.String("  OK") ELSE Out.String("  FAIL") END;
  Out.Ln
END Assert;

PROCEDURE FillRange(VAR b: TLSBytes.Buffer; first: LONGINT);
VAR i: LONGINT;
BEGIN
  TLSBytes.Init(b);
  i := 0;
  WHILE i < 32 DO TLSBytes.AppendByte(b, first + i); INC(i) END
END FillRange;

PROCEDURE MakeFakeServerHello(VAR srvKey: TLSBytes.Buffer; VAR msg: TLSBytes.Buffer);
VAR body, exts, e, rnd: TLSBytes.Buffer;
BEGIN
  FillRange(rnd, 128);

  TLSBytes.Init(exts);
  TLSBytes.Init(e);
  TLSBytes.AppendByte(e, 3); TLSBytes.AppendByte(e, 4);
  TLSBytes.PutBE16(exts, 43); TLSBytes.PutBE16(exts, e.len); TLSBytes.Append(exts, e);

  TLSBytes.Init(e);
  TLSBytes.AppendByte(e, 0); TLSBytes.AppendByte(e, 29);
  TLSBytes.PutBE16(e, srvKey.len);
  TLSBytes.Append(e, srvKey);
  TLSBytes.PutBE16(exts, 51); TLSBytes.PutBE16(exts, e.len); TLSBytes.Append(exts, e);

  TLSBytes.Init(body);
  TLSBytes.AppendByte(body, 3); TLSBytes.AppendByte(body, 3);
  TLSBytes.Append(body, rnd);
  TLSBytes.AppendByte(body, 0);       (* session id len *)
  TLSBytes.AppendByte(body, 19); TLSBytes.AppendByte(body, 1);
  TLSBytes.AppendByte(body, 0);       (* compression *)
  TLSBytes.PutBE16(body, exts.len);
  TLSBytes.Append(body, exts);

  TLSBytes.Init(msg);
  TLSBytes.AppendByte(msg, 2);
  TLSBytes.PutBE24(msg, body.len);
  TLSBytes.Append(msg, body)
END MakeFakeServerHello;

PROCEDURE Main;
VAR random, cliKey, srvKey, ch, rec, payload, sh, parsed: TLSBytes.Buffer; ok: BOOLEAN;
BEGIN
  FillRange(random, 0);
  FillRange(cliKey, 32);
  TLS13Handshake.BuildClientHelloMessage("example.com", random, cliKey, ch);
  Out.String("client hello len = "); Out.Int(ch.len, 0); Out.Ln;
  Out.String("client hello prefix = "); PrintHex(ch); Out.Ln;
  Assert("client hello type", ORD(ch.data[0]) = TLS13Handshake.ClientHello);
  Assert("client hello length", TLSBytes.GetBE24(ch, 1) = ch.len - 4);
  Assert("client hello legacy version", (ORD(ch.data[4]) = 3) & (ORD(ch.data[5]) = 3));

  TLS13Handshake.BuildPlainHandshakeRecord(ch, rec);
  Assert("record type", TLS13Handshake.IsPlainHandshakeRecord(rec));
  ok := TLS13Handshake.GetRecordPayload(rec, payload);
  Assert("record payload", ok & TLSBytes.EqualConstTime(ch, payload));

  FillRange(srvKey, 64);
  MakeFakeServerHello(srvKey, sh);
  ok := TLS13Handshake.ExtractServerHelloKeyShare(sh, parsed);
  Assert("server keyshare parse", ok);
  Assert("server keyshare value", TLSBytes.EqualConstTime(srvKey, parsed));
END Main;

BEGIN
  Main
END TLSTestHandshake.
