MODULE TLSTestRSA2;  (* TLSRSA against OpenSSL, PSS, 2048 bits: valid signatures verify; a changed hash, a
  changed signature, another hash algorithm, the other scheme, zero and n do not *)

IMPORT TLSBytes, TLSRSA, Out;

VAR
  fails, checks: LONGINT;
  spki, n, e, h, sig: TLSBytes.Buffer;

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
  IF ~ok THEN INC(fails); Out.String("FAIL "); Out.String(what); Out.String(" (check "); Out.Int(checks, 0); Out.String(")"); Out.Ln END
END Check;

PROCEDURE Key;
BEGIN Check("public key", TLSRSA.PublicKey(spki, n, e))
END Key;

(* the checks every signature must pass or fail *)
PROCEDURE Common(alg: LONGINT; pss: BOOLEAN);
VAR t, s: TLSBytes.Buffer; other: LONGINT;

  PROCEDURE V(VAR hh, ss: TLSBytes.Buffer; a: LONGINT; p: BOOLEAN): BOOLEAN;
  BEGIN
    IF p THEN RETURN TLSRSA.VerifyPSS(n, e, a, hh, ss) ELSE RETURN TLSRSA.VerifyPKCS1(n, e, a, hh, ss) END
  END V;

BEGIN
  Check("valid", V(h, sig, alg, pss));
  TLSBytes.Copy(h, t); t.data[3] := CHR((ORD(t.data[3]) + 1) MOD 256);
  Check("changed hash", ~V(t, sig, alg, pss));
  TLSBytes.Copy(sig, s); s.data[s.len DIV 2] := CHR((ORD(s.data[s.len DIV 2]) + 1) MOD 256);
  Check("changed signature", ~V(h, s, alg, pss));
  IF alg = TLSRSA.SHA256 THEN other := TLSRSA.SHA384 ELSE other := TLSRSA.SHA256 END;
  Check("other hash algorithm", ~V(h, sig, other, pss));
  Check("other scheme", ~V(h, sig, alg, ~pss));
  TLSBytes.Copy(sig, s); s.len := 0; WHILE s.len < sig.len DO TLSBytes.AppendByte(s, 0) END;
  Check("zero", ~V(h, s, alg, pss));
  Check("n", ~V(h, n, alg, pss))
END Common;

PROCEDURE Pkcs1(alg: LONGINT);
BEGIN Common(alg, FALSE)
END Pkcs1;

PROCEDURE Pss(alg: LONGINT);
BEGIN Common(alg, TRUE)
END Pss;

PROCEDURE Vectors;
BEGIN
  Clear(spki);
  Add(spki, "30820122300d06092a864886f70d01010105000382010f003082010a02820101");
  Add(spki, "00894ac5f16f04de905f76ba69f8b4789928295b5958b9756d9699f0f91dcc3e");
  Add(spki, "60e9a1ec00384a661bd5ed101c9afd47a33e4d2234b314094881af538f46b435");
  Add(spki, "513275843e0eccc075431bd96358af0cce9e32e03ebdb28144882fa8f6a224df");
  Add(spki, "01ca4de4e7879a00735ce2347cefe8b2bdd2ff219aa22e3587a5d204725e0a98");
  Add(spki, "4c0b5469bb04f5dec29bca66c813bfee02031426bf4ec25def1b81642c704967");
  Add(spki, "5e25944bf49dc8539c7102c9699f7b694c40f41efc79b75f7db3841a6a165ff0");
  Add(spki, "a7c83f83e8ee14158fbbdaf48c22d4d93159e804c2054433d3ba222d65692cf8");
  Add(spki, "db49ed6d6acb43cd62c35945229aa25611d603a9f189395a897e296dd4f834f2");
  Add(spki, "e70203010001");
  Key;
  Clear(h);
  Add(h, "74f2bab0f7b496db35967b365a4bedc0f6378888dea671ec307ee99e677fe21d");
  Clear(sig);
  Add(sig, "5fce2e0172d838428c20b8d4a8b64779751e687dfdbb87a60577ae9012507900");
  Add(sig, "2aa97e9153c5d71d8fcd259ae6691a92c10ccf95c4a6a128fe00da5398efaafc");
  Add(sig, "404a2e63acc42d2acc4f635ca71da2750267722108e20684c2e8955130de44d7");
  Add(sig, "4e843d3f17a4a9df37b6faae3af8983becda658cc050f64ceb594233a56edadc");
  Add(sig, "e4853d497bbab9f77b0ac1305f46f1ae341061f101f7a2997b8c1255cbc53133");
  Add(sig, "483ebcbce2e5774687ea7d652b6654b6ef185ed99dae6361b6ab67e87148995d");
  Add(sig, "80b5b5eb6c9e89c86159d08070b9756e27c378f04686997c05dc56f79cd54a52");
  Add(sig, "fd266c0ecee0a6ddbc9e4a50841fc9ebadddbc437b22788b95c110456d63a082");
  Pss(1);
  Clear(h);
  Add(h, "4e6120cfd0861f00c2b713b50c7b53af53de22f601a1e2a48c4787ef299d4b54");
  Add(h, "394f51601b0dbd366b42a3d521bca993");
  Clear(sig);
  Add(sig, "3fa7a46f3d608fbb2aa20c6335766b79a2b83b37afec12c314986f1e42a63e37");
  Add(sig, "c959eefac3bbf040dbba85db4553c49dc5b3a74cc12039e5072f7e14e6867a6f");
  Add(sig, "d1bef4588aad32062de034bd1f414e5c49145e2275818ac5796d03c320c2818a");
  Add(sig, "1dfb861d4999a4b8d23fdbd9d1f25a87cb7170c3265e452a4a29b2960aa1c02d");
  Add(sig, "51923dc02a2c06975559809577e9c306b2c85dcb879e281337cf6c68f0729df8");
  Add(sig, "3a62a07f1b5178c8295c25205714cb94d0cdc017cc1e02a0866db90cb5a51546");
  Add(sig, "940c43f761847a35792a08c310039bb8a867c192c4d2928718c058fb6996e48c");
  Add(sig, "a332c3f033e116a04b3b5ba64c56696dcc2b9bdbd9cd0eb82972fccbbff406c1");
  Pss(2);
  Clear(spki);
  Add(spki, "30819f300d06092a864886f70d010101050003818d0030818902818100cfbb2f");
  Add(spki, "c6a9c62210680bc3455fc3ac4ad5c41c4f98c54c1a90e0e26da676416a3af134");
  Add(spki, "67bba82b8efe005852a569a0c3753aa1a6579a6fdcaad8fb04af2c46cb96fed6");
  Add(spki, "119ca2e93c2c58b1e014bf232b8fd682d360049cff7a48a881ece4c78e8034d6");
  Add(spki, "324abec33c9dbafac8af74007678dcbe9da44d16009aac52acc2f2fe6b020301");
  Add(spki, "0001");
  Key;
  Clear(h);
  Add(h, "81db8ebbbbc69c6c6ad4a6aa92b76e0c08af547da236b9e2c9dbe1d8285a8130");
  Clear(sig);
  Add(sig, "763df6db73f852afde7e96cd496e12ca5adf61e8855f4a0d31412aa12296e751");
  Add(sig, "bef2de9f1ce6baefd15523af176c37692e2f05bcb436a0a80250340f7400aa2f");
  Add(sig, "60893582ed3ea186ab9211ea8d8feae06e4b8523a567495feb938826c53892b1");
  Add(sig, "8ebb4a0a7e0cad3dd4f5e9b6312e8dfa52d5ea22b29a19176146c7388a7d2c75");
  Check("1024 bits refused", ~TLSRSA.VerifyPKCS1(n, e, TLSRSA.SHA256, h, sig));
END Vectors;

BEGIN
  fails := 0; checks := 0;
  Vectors;
  Out.String("TLSTestRSA2: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END TLSTestRSA2.
