MODULE TLSTestSHA256;  (* SHA-256 (FIPS 180) and HMAC (RFC 4231) test vectors;
  the values come in short hex pieces (the ARM compiler of polpo takes only short strings, and not many) *)

IMPORT TLSBytes, TLSSHA256, Out;

VAR
  fails, checks: LONGINT;
  m, k, s, w, w2: TLSBytes.Buffer;  (* message, key, salt, wanted results *)

PROCEDURE Hex(c: CHAR): LONGINT;
BEGIN
  IF c <= "9" THEN RETURN ORD(c) - ORD("0") ELSE RETURN ORD(c) - ORD("a") + 10 END
END Hex;

PROCEDURE Clear(VAR b: TLSBytes.Buffer);
BEGIN TLSBytes.Init(b)
END Clear;

PROCEDURE Add(VAR b: TLSBytes.Buffer; h: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(h) - 1) & (h[i] # 0X) DO TLSBytes.AppendByte(b, Hex(h[i]) * 16 + Hex(h[i+1])); INC(i, 2) END
END Add;

PROCEDURE Pattern(n: LONGINT; VAR b: TLSBytes.Buffer);
VAR i: LONGINT;
BEGIN
  TLSBytes.Init(b); i := 0;
  WHILE i < n DO TLSBytes.AppendByte(b, (i * 31 + 7) MOD 256); INC(i) END
END Pattern;

PROCEDURE Same(what: ARRAY OF CHAR; VAR got, want: TLSBytes.Buffer);
BEGIN
  INC(checks);
  IF ~TLSBytes.EqualConstTime(got, want) THEN
    INC(fails); Out.String("FAIL "); Out.String(what); Out.String(" (message of "); Out.Int(m.len, 0); Out.String(" bytes)"); Out.Ln
  END
END Same;

PROCEDURE Sha;
VAR g: TLSBytes.Buffer; d: TLSSHA256.Digest;
BEGIN
  TLSSHA256.DigestBuffer(m, d); TLSSHA256.DigestToBuffer(d, g); Same("sha256", g, w)
END Sha;

PROCEDURE Hmac;
VAR g: TLSBytes.Buffer; d: TLSSHA256.Digest;
BEGIN
  TLSSHA256.HMAC(k, m, d); TLSSHA256.DigestToBuffer(d, g); Same("hmac", g, w)
END Hmac;

PROCEDURE Vectors;
BEGIN
  Clear(m);
  Clear(w);
  Add(w, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
  Sha;
  Clear(m);
  Add(m, "616263");
  Clear(w);
  Add(w, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
  Sha;
  Clear(m);
  Add(m, "6162636462636465636465666465666765666768666768696768696a68696a6b");
  Add(m, "696a6b6c6a6b6c6d6b6c6d6e6c6d6e6f6d6e6f706e6f7071");
  Clear(w);
  Add(w, "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1");
  Sha;
  Clear(m);
  Add(m, "61626364656667686263646566676869636465666768696a6465666768696a6b");
  Add(m, "65666768696a6b6c666768696a6b6c6d6768696a6b6c6d6e68696a6b6c6d6e6f");
  Add(m, "696a6b6c6d6e6f706a6b6c6d6e6f70716b6c6d6e6f7071726c6d6e6f70717273");
  Add(m, "6d6e6f70717273746e6f707172737475");
  Clear(w);
  Add(w, "cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1");
  Sha;
  Pattern(55, m);
  Clear(w);
  Add(w, "8aa994584139d128848eeebc4e815639ba5ab6e6e39574195a63ac4f14f7c43b");
  Sha;
  Pattern(56, m);
  Clear(w);
  Add(w, "ad574708f75c044c9b85de64cb568ee7711ff4f36448c6242f053ba8f6cc2b63");
  Sha;
  Pattern(63, m);
  Clear(w);
  Add(w, "280ed3e8ff1df845b2e7dfe6ac6cee817bef20e783cc65abc41b818b4d2fe076");
  Sha;
  Pattern(64, m);
  Clear(w);
  Add(w, "c6ab9724ade5b6a7a1edfffb12f3aa9181351355af8fd08c919952ad211339dd");
  Sha;
  Pattern(65, m);
  Clear(w);
  Add(w, "788367c73c7ddf4c53f65e68cc0d943e6227ab55b0e78ba63ace822b1c6301c0");
  Sha;
  Pattern(119, m);
  Clear(w);
  Add(w, "3d610547d68216dedf7435a4fb6260353911f6b3fd3f18805ddb8be285d726fe");
  Sha;
  Pattern(120, m);
  Clear(w);
  Add(w, "1f80156a804cb7862ad113e8200e9d74499723e7c7854d5f48776d3148e09656");
  Sha;
  Pattern(1000, m);
  Clear(w);
  Add(w, "5097e7d587352f5097062ae679f37bda5802d9f875aba14c8cb4d1a188ada179");
  Sha;
  Pattern(32767, m);
  Clear(w);
  Add(w, "60cdeba64ff8750b011d7253d9363a54bd21645f142b72540102bcfd69bf88eb");
  Sha;
  Clear(k);
  Add(k, "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b");
  Clear(m);
  Add(m, "4869205468657265");
  Clear(w);
  Add(w, "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7");
  Hmac;
  Clear(k);
  Add(k, "4a656665");
  Clear(m);
  Add(m, "7768617420646f2079612077616e7420666f72206e6f7468696e673f");
  Clear(w);
  Add(w, "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843");
  Hmac;
  Clear(k);
  Add(k, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
  Clear(m);
  Add(m, "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd");
  Add(m, "dddddddddddddddddddddddddddddddddddd");
  Clear(w);
  Add(w, "773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe");
  Hmac;
  Clear(k);
  Add(k, "0102030405060708090a0b0c0d0e0f10111213141516171819");
  Clear(m);
  Add(m, "cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd");
  Add(m, "cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd");
  Clear(w);
  Add(w, "82558a389a443c0ea4cc819899f2083a85f0faa3e578f8077a2e3ff46729665b");
  Hmac;
  Clear(k);
  Add(k, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
  Add(k, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
  Add(k, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
  Add(k, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
  Add(k, "aaaaaa");
  Clear(m);
  Add(m, "54657374205573696e67204c6172676572205468616e20426c6f636b2d53697a");
  Add(m, "65204b6579202d2048617368204b6579204669727374");
  Clear(w);
  Add(w, "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54");
  Hmac;
  Clear(k);
  Add(k, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
  Add(k, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
  Add(k, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
  Add(k, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
  Add(k, "aaaaaa");
  Clear(m);
  Add(m, "5468697320697320612074657374207573696e672061206c6172676572207468");
  Add(m, "616e20626c6f636b2d73697a65206b657920616e642061206c61726765722074");
  Add(m, "68616e20626c6f636b2d73697a6520646174612e20546865206b6579206e6565");
  Add(m, "647320746f20626520686173686564206265666f7265206265696e6720757365");
  Add(m, "642062792074686520484d414320616c676f726974686d2e");
  Clear(w);
  Add(w, "9b09ffa71b942fcb27635fbcd5b0e944bfdc63644f0713938a7f51535c3a35e2");
  Hmac;
END Vectors;

BEGIN
  fails := 0; checks := 0;
  Vectors;
  Out.String("TLSTestSHA256: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END TLSTestSHA256.
