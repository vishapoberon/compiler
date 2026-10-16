MODULE TLSTestHRR;  (* HelloRetryRequest (RFC 8446 4.1.4): a valid one with a group and a cookie,
  the second ClientHello echoing the cookie, and the requests we refuse *)

IMPORT TLSBytes, TLS13Handshake, Out;

CONST X25519 = TLS13Handshake.GroupX25519; P256 = TLS13Handshake.GroupP256;

VAR
  fails, checks: LONGINT;
  sid: TLSBytes.Buffer;

PROCEDURE Check(what: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN INC(fails); Out.String("FAIL "); Out.String(what); Out.Ln END
END Check;

(* the HelloRetryRequest random, SHA-256("HelloRetryRequest") *)
PROCEDURE HRRRandom(VAR b: TLSBytes.Buffer);
CONST h = "CF21AD74E59A6111BE1D8C021E65B891C2A211167ABB8C5E079E09E2C8A8339C";
VAR i, v, w: LONGINT; s: ARRAY 65 OF CHAR;
BEGIN
  s := h; i := 0;
  WHILE i < 64 DO
    v := ORD(s[i]) - ORD("0"); IF v > 9 THEN v := v - 7 END;
    w := ORD(s[i+1]) - ORD("0"); IF w > 9 THEN w := w - 7 END;
    TLSBytes.AppendByte(b, v * 16 + w); INC(i, 2)
  END
END HRRRandom;

(* a ServerHello (hrr: with the HelloRetryRequest random) with the extensions exts *)
PROCEDURE Hello(hrr: BOOLEAN; VAR s: TLSBytes.Buffer; VAR exts, msg: TLSBytes.Buffer);
VAR body: TLSBytes.Buffer; i: LONGINT;
BEGIN
  TLSBytes.Init(body); TLSBytes.AppendByte(body, 3); TLSBytes.AppendByte(body, 3);
  IF hrr THEN HRRRandom(body) ELSE i := 0; WHILE i < 32 DO TLSBytes.AppendByte(body, i + 1); INC(i) END END;
  TLSBytes.AppendByte(body, s.len); TLSBytes.Append(body, s);
  TLSBytes.AppendByte(body, 13H); TLSBytes.AppendByte(body, 1); TLSBytes.AppendByte(body, 0);
  TLSBytes.PutBE16(body, exts.len); TLSBytes.Append(body, exts);
  TLSBytes.Init(msg); TLSBytes.AppendByte(msg, 2); TLSBytes.PutBE24(msg, body.len); TLSBytes.Append(msg, body)
END Hello;

PROCEDURE Versions(VAR e: TLSBytes.Buffer);
BEGIN TLSBytes.PutBE16(e, 43); TLSBytes.PutBE16(e, 2); TLSBytes.AppendByte(e, 3); TLSBytes.AppendByte(e, 4)
END Versions;

PROCEDURE Group(VAR e: TLSBytes.Buffer; g: LONGINT);
BEGIN TLSBytes.PutBE16(e, 51); TLSBytes.PutBE16(e, 2); TLSBytes.PutBE16(e, g)
END Group;

PROCEDURE Cookie(VAR e: TLSBytes.Buffer);
BEGIN
  TLSBytes.PutBE16(e, 44); TLSBytes.PutBE16(e, 5); TLSBytes.PutBE16(e, 3);
  TLSBytes.AppendByte(e, ORD("a")); TLSBytes.AppendByte(e, ORD("b")); TLSBytes.AppendByte(e, ORD("c"))
END Cookie;

(* the extension data of type t in the ClientHello msg, FALSE if there is none *)
PROCEDURE FindExt(VAR msg: TLSBytes.Buffer; t: LONGINT; VAR data: TLSBytes.Buffer): BOOLEAN;
VAR pos, et, el: LONGINT;
BEGIN
  pos := 4 + 2 + 32; pos := pos + 1 + ORD(msg.data[pos]);
  pos := pos + 2 + TLSBytes.GetBE16(msg, pos); pos := pos + 1 + ORD(msg.data[pos]);
  INC(pos, 2);
  WHILE pos + 4 <= msg.len DO
    et := TLSBytes.GetBE16(msg, pos); el := TLSBytes.GetBE16(msg, pos + 2);
    IF et = t THEN TLSBytes.Slice(msg, pos + 4, el, data); RETURN TRUE END;
    INC(pos, 4 + el)
  END;
  RETURN FALSE
END FindExt;

PROCEDURE Run;
VAR e, msg, cookie, pub, rnd, ch, d, other: TLSBytes.Buffer; g, i: LONGINT; why: ARRAY 128 OF CHAR;
BEGIN
  TLSBytes.Init(sid); i := 0; WHILE i < 32 DO TLSBytes.AppendByte(sid, 100 + i); INC(i) END;
  TLSBytes.Init(e); Versions(e); Group(e, P256); Cookie(e); Hello(TRUE, sid, e, msg);
  Check("is a HelloRetryRequest", TLS13Handshake.IsHelloRetryRequest(msg));
  Check("valid", TLS13Handshake.CheckHelloRetryRequest(msg, sid, X25519, g, cookie, why));
  Check("group P-256", g = P256);
  Check("cookie kept", (cookie.len = 5) & (cookie.data[2] = "a") & (cookie.data[4] = "c"));
  Check("not a ServerHello", ~TLS13Handshake.CheckServerHelloGroup(msg, sid, P256, pub, why));
  (* the second ClientHello *)
  TLSBytes.Init(pub); TLSBytes.AppendByte(pub, 4); WHILE pub.len < 65 DO TLSBytes.AppendByte(pub, pub.len) END;
  TLSBytes.Copy(sid, rnd);
  TLS13Handshake.BuildClientHello2("example.com", rnd, P256, pub, cookie, ch);
  Check("cookie echoed", FindExt(ch, 44, d) & TLSBytes.EqualConstTime(d, cookie));
  Check("P-256 key share", FindExt(ch, 51, d) & (d.len = 2 + 4 + 65) & (TLSBytes.GetBE16(d, 2) = P256) & (TLSBytes.GetBE16(d, 4) = 65));
  Check("both groups offered", FindExt(ch, 10, d) & (d.len = 6) & (TLSBytes.GetBE16(d, 2) = X25519) & (TLSBytes.GetBE16(d, 4) = P256));
  TLSBytes.Init(e); Versions(e); Cookie(e); Hello(TRUE, sid, e, msg);
  Check("only a cookie", TLS13Handshake.CheckHelloRetryRequest(msg, sid, X25519, g, cookie, why) & (g = X25519));
  (* refused *)
  TLSBytes.Init(e); Versions(e); Group(e, X25519); Hello(TRUE, sid, e, msg);
  Check("the group already offered", ~TLS13Handshake.CheckHelloRetryRequest(msg, sid, X25519, g, cookie, why));
  TLSBytes.Init(e); Versions(e); Group(e, 18H); Hello(TRUE, sid, e, msg);
  Check("a group not offered", ~TLS13Handshake.CheckHelloRetryRequest(msg, sid, X25519, g, cookie, why));
  TLSBytes.Init(e); Versions(e); Hello(TRUE, sid, e, msg);
  Check("changes nothing", ~TLS13Handshake.CheckHelloRetryRequest(msg, sid, X25519, g, cookie, why));
  TLSBytes.Init(e); Group(e, P256); Hello(TRUE, sid, e, msg);
  Check("no supported_versions", ~TLS13Handshake.CheckHelloRetryRequest(msg, sid, X25519, g, cookie, why));
  TLSBytes.Init(e); Versions(e); Group(e, P256); TLSBytes.PutBE16(e, 0); TLSBytes.PutBE16(e, 0); Hello(TRUE, sid, e, msg);
  Check("another extension", ~TLS13Handshake.CheckHelloRetryRequest(msg, sid, X25519, g, cookie, why));
  TLSBytes.Init(e); Versions(e); Group(e, P256); Group(e, P256); Hello(TRUE, sid, e, msg);
  Check("key_share twice", ~TLS13Handshake.CheckHelloRetryRequest(msg, sid, X25519, g, cookie, why));
  TLSBytes.Copy(sid, other); other.data[0] := 0X;
  TLSBytes.Init(e); Versions(e); Group(e, P256); Hello(TRUE, other, e, msg);
  Check("session id not echoed", ~TLS13Handshake.CheckHelloRetryRequest(msg, sid, X25519, g, cookie, why));
  (* a ServerHello with a P-256 share *)
  TLSBytes.Init(e); Versions(e);
  TLSBytes.PutBE16(e, 51); TLSBytes.PutBE16(e, 4 + 65); TLSBytes.PutBE16(e, P256); TLSBytes.PutBE16(e, 65); TLSBytes.Append(e, pub);
  Hello(FALSE, sid, e, msg);
  Check("not a HelloRetryRequest", ~TLS13Handshake.IsHelloRetryRequest(msg));
  Check("ServerHello with P-256", TLS13Handshake.CheckServerHelloGroup(msg, sid, P256, d, why) & TLSBytes.EqualConstTime(d, pub));
  Check("P-256 share when X25519 was sent", ~TLS13Handshake.CheckServerHelloGroup(msg, sid, X25519, d, why));
  Out.String("TLSTestHRR: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END Run;

BEGIN
  fails := 0; checks := 0; Run
END TLSTestHRR.
