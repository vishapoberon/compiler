MODULE TLSTestECDSA256;  (* ECDSA on secp256r1 against OpenSSL: valid signatures verify; a changed hash,
  r and s swapped, r = 0, r = n and a public key off the curve do not *)

IMPORT TLSBytes, TLSECDSA, Out;

VAR
  fails, checks: LONGINT;
  pub, h, der: TLSBytes.Buffer;

PROCEDURE Hex(c: CHAR): LONGINT;
BEGIN
  IF c <= "9" THEN RETURN ORD(c) - ORD("0") ELSE RETURN ORD(c) - ORD("a") + 10 END
END Hex;

PROCEDURE Clear(VAR b: TLSBytes.Buffer);
BEGIN TLSBytes.Init(b)
END Clear;

PROCEDURE Add(VAR b: TLSBytes.Buffer; x: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(x) - 1) & (x[i] # 0X) DO TLSBytes.AppendByte(b, Hex(x[i]) * 16 + Hex(x[i+1])); INC(i, 2) END
END Add;

PROCEDURE Check(what: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN INC(fails); Out.String("FAIL "); Out.String(what); Out.String(" (case "); Out.Int(checks, 0); Out.String(")"); Out.Ln END
END Check;

PROCEDURE Case(curve, n: LONGINT);
VAR r, s, t, bad: TLSBytes.Buffer; i: LONGINT;
BEGIN
  Check("parse", TLSECDSA.ParseSignature(der, r, s));
  Check("valid", TLSECDSA.Verify(curve, pub, h, r, s));
  TLSBytes.Copy(h, t); t.data[0] := CHR((ORD(t.data[0]) + 1) MOD 256);
  Check("changed hash", ~TLSECDSA.Verify(curve, pub, t, r, s));
  Check("r and s swapped", ~TLSECDSA.Verify(curve, pub, h, s, r));
  TLSBytes.Init(t); TLSBytes.AppendByte(t, 0);
  Check("r = 0", ~TLSECDSA.Verify(curve, pub, h, t, s));
  TLSBytes.Init(t); i := 0; WHILE i < n DO TLSBytes.AppendByte(t, 255); INC(i) END;
  Check("r too big", ~TLSECDSA.Verify(curve, pub, h, t, s));
  TLSBytes.Copy(pub, bad); bad.data[n] := CHR((ORD(bad.data[n]) + 1) MOD 256);
  Check("off the curve", ~TLSECDSA.Verify(curve, bad, h, r, s))
END Case;

PROCEDURE Vectors;
BEGIN
  Clear(pub);
  Add(pub, "04a9755650c2d6ce69f5910050d8f3b1ae6eaf2396f6e4fce0c514c932ca3218");
  Add(pub, "94c8c39f3331586feba500bedde7ba270e9c00e6b0672f23a51bfbcc94068c6c");
  Add(pub, "3a");
  Clear(h);
  Add(h, "069f02655d00d2c8ac59b9def1a361c244aa1cb31d31e186336e3c0967106882");
  Clear(der);
  Add(der, "304402201fe760ad5c70075726f37b362c85121c380ec7c68be8fed60083e3a7");
  Add(der, "d739ddec0220201cc5327773f63ae69c2ac6639b37a0fdb2f17882c118540676");
  Add(der, "54ff0fa30638");
  Case(1, 32);
  Clear(pub);
  Add(pub, "04a9755650c2d6ce69f5910050d8f3b1ae6eaf2396f6e4fce0c514c932ca3218");
  Add(pub, "94c8c39f3331586feba500bedde7ba270e9c00e6b0672f23a51bfbcc94068c6c");
  Add(pub, "3a");
  Clear(h);
  Add(h, "60d1116a0d3780b2ae09c8aa54c821774ec57e3e1a66b1b372ecb4c1ae4d81aa");
  Add(h, "ca67d8eae91c97973d731878faee641b");
  Clear(der);
  Add(der, "304402204aa1bdb96e6409dbc7297094aa5f65ddfbe5bba02062e6fb3fa626f1");
  Add(der, "08bb85a802206162722d77d714dc003de3bb696f548e7370f4f861174e4eba94");
  Add(der, "dd7cd0430cd2");
  Case(1, 32);
  Clear(pub);
  Add(pub, "0456ce9ed355a128cc35dacf8d999200cc730911ba1fae483d2a7a9edceab141");
  Add(pub, "63453310112cb1f8d9d02a128ce76ed50c9cad75b5cb20758a2f8ba60bb5173c");
  Add(pub, "c4");
  Clear(h);
  Add(h, "c13acf7d9bed5c9a24316672142c4def39f71a8f8fbab53ee26edb55d07fb229");
  Clear(der);
  Add(der, "3045022100da4da23fbc3e6db04f56b51669f95e05a78135524ba945f257e68c");
  Add(der, "64792920900220154ca92c3b575ff76029e2af3a953a17e283c157ce10fa1673");
  Add(der, "bbbbeb5e9c4f29");
  Case(1, 32);
  Clear(pub);
  Add(pub, "0456ce9ed355a128cc35dacf8d999200cc730911ba1fae483d2a7a9edceab141");
  Add(pub, "63453310112cb1f8d9d02a128ce76ed50c9cad75b5cb20758a2f8ba60bb5173c");
  Add(pub, "c4");
  Clear(h);
  Add(h, "32609e092bd961f37e0ac9299df2dd15e69dfdc78c4f6fb06c7e20437dc1d1fc");
  Add(h, "1db71a5f626a90c6f7d4db40d9534756");
  Clear(der);
  Add(der, "3045022100c31b096575304c8ee02d05819257b6d57e6972817d0ae373ae5eea");
  Add(der, "c4e98565ee0220220786cce9f36f81b1ec7158a52ac4dfeedefaf7d6c87408f2");
  Add(der, "508680018e1a9a");
  Case(1, 32);
  Clear(pub);
  Add(pub, "04c5e671cb257c05dc8b7f8b54b6155b891f718185322c8fb9de55dd64cb8c3f");
  Add(pub, "03da70037578c661ebf7c01652f7d99b15bfb7e4e4d87ce44acd057cd6b16b64");
  Add(pub, "1b");
  Clear(h);
  Add(h, "24a2df6bfcfd94cbbda8c3d24db47470b23f2a0d1b786384aceeee2975eb867c");
  Clear(der);
  Add(der, "3046022100b4ea19bd333e4a4c501084662f8ecf4878253a3e741b6fa88518ea");
  Add(der, "85ebf037da02210099ece1e11263b9b933f76e5f950241f42bf71c6ba4d7701f");
  Add(der, "5fd854d98bfdcb79");
  Case(1, 32);
  Clear(pub);
  Add(pub, "04c5e671cb257c05dc8b7f8b54b6155b891f718185322c8fb9de55dd64cb8c3f");
  Add(pub, "03da70037578c661ebf7c01652f7d99b15bfb7e4e4d87ce44acd057cd6b16b64");
  Add(pub, "1b");
  Clear(h);
  Add(h, "036c16ddc90315e5d988a3edf3077f6a7d2a1f477a7e2d205f5d4f266c0d0b65");
  Add(h, "faee434fb6f7a63fb63b3e60f3e210f3");
  Clear(der);
  Add(der, "3045022052168dad946f5d9afcf90bb31705683ad0b69c9e863ab15c315fedda");
  Add(der, "164319b7022100a4857f904ea1a0b5b87efc89a1db2dcc37bcdf3ac61343d2e1");
  Add(der, "bc09577bcdd6e9");
  Case(1, 32);
END Vectors;

BEGIN
  fails := 0; checks := 0;
  Vectors;
  Out.String("TLSTestECDSA256: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END TLSTestECDSA256.
