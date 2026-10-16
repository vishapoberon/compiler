MODULE TLSTestHKDF;  (* HKDF (RFC 5869) test vectors;
  the values come in short hex pieces (the ARM compiler of polpo takes only short strings, and not many) *)

IMPORT TLSBytes, TLSSHA256, TLSHKDF, Out;

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

PROCEDURE Same(what: ARRAY OF CHAR; VAR got, want: TLSBytes.Buffer);
BEGIN
  INC(checks);
  IF ~TLSBytes.EqualConstTime(got, want) THEN
    INC(fails); Out.String("FAIL "); Out.String(what); Out.String(" (message of "); Out.Int(m.len, 0); Out.String(" bytes)"); Out.Ln
  END
END Same;

PROCEDURE Hkdf(len: LONGINT);
VAR p, o: TLSBytes.Buffer; prk: TLSSHA256.Digest;
BEGIN
  IF s.len = 0 THEN WHILE s.len < 32 DO TLSBytes.AppendByte(s, 0) END END;  (* RFC 5869: no salt is HashLen zeros *)
  TLSHKDF.Extract(s, k, prk); TLSSHA256.DigestToBuffer(prk, p); Same("hkdf prk", p, w);
  TLSHKDF.Expand(p, m, len, o); Same("hkdf okm", o, w2)
END Hkdf;

PROCEDURE Vectors;
BEGIN
  Clear(k);
  Add(k, "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b");
  Clear(s);
  Add(s, "000102030405060708090a0b0c");
  Clear(m);
  Add(m, "f0f1f2f3f4f5f6f7f8f9");
  Clear(w);
  Add(w, "077709362c2e32df0ddc3f0dc47bba6390b6c73bb50f9c3122ec844ad7c2b3e5");
  Clear(w2);
  Add(w2, "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf");
  Add(w2, "34007208d5b887185865");
  Hkdf(42);
  Clear(k);
  Add(k, "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f");
  Add(k, "202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f");
  Add(k, "404142434445464748494a4b4c4d4e4f");
  Clear(s);
  Add(s, "606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f");
  Add(s, "808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f");
  Add(s, "a0a1a2a3a4a5a6a7a8a9aaabacadaeaf");
  Clear(m);
  Add(m, "b0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecf");
  Add(m, "d0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeef");
  Add(m, "f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff");
  Clear(w);
  Add(w, "06a6b88c5853361a06104c9ceb35b45cef760014904671014a193f40c15fc244");
  Clear(w2);
  Add(w2, "b11e398dc80327a1c8e7f78c596a49344f012eda2d4efad8a050cc4c19afa97c");
  Add(w2, "59045a99cac7827271cb41c65e590e09da3275600c2f09b8367793a9aca3db71");
  Add(w2, "cc30c58179ec3e87c14c01d5c1f3434f1d87");
  Hkdf(82);
  Clear(k);
  Add(k, "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b");
  Clear(s);
  Clear(m);
  Clear(w);
  Add(w, "19ef24a32c717b167f33a91d6f648bdf96596776afdb6377ac434c1c293ccb04");
  Clear(w2);
  Add(w2, "8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d");
  Add(w2, "9d201395faa4b61a96c8");
  Hkdf(42);
END Vectors;

BEGIN
  fails := 0; checks := 0;
  Vectors;
  Out.String("TLSTestHKDF: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END TLSTestHKDF.
