MODULE TLSTestRSA3;  (* TLSRSA against OpenSSL, PKCS#1 v1.5 and PSS, 3072 bits: valid signatures verify; a changed hash, a
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
  Add(spki, "308201a2300d06092a864886f70d01010105000382018f003082018a02820181");
  Add(spki, "00c4d8539231b439f6932bc5986c31540f05506f1e792ba50a1712639755f206");
  Add(spki, "0693c59837bf965219128cca049447c19b3f6bca3fc32a7c43f0897ca1e2dfb1");
  Add(spki, "afb2ef2dd148cd2f69250712edb4b6a2332a4830ecde8a7116c1efc3f3c1e2c6");
  Add(spki, "8a1b7643cb7ba00f09d1e99a5554d0703f0890352c4c91060dfd5442b4a40f7d");
  Add(spki, "4a2d008088a7e5f2b449ca1052858d322a7ac617cd6c2cc036d04dc777713577");
  Add(spki, "c84177172673e6f28c6b3243005964fc3e828d5bea53d16f2180ae8f8f19ef32");
  Add(spki, "1f7eeaa5173e169af55adad3241d357de892daa1ab6e18ef1ade27a1c20daba3");
  Add(spki, "ac46286d0daa7a80ddeecc08a62745953e43561a211c1b62044b1ab68affbc0b");
  Add(spki, "0d057a70502d0163d4775aff9b0c2538b01817c19f3c64521dcbab1d5d5174a9");
  Add(spki, "c2d64677ce2f6f34ee78f9aedb1b0be8651e69500055a786621d55b737b8eaef");
  Add(spki, "5167f81d038fad9bea3a3b36850fe36b12e89d02da8217c7b88b2512d52894d6");
  Add(spki, "4aab43788a3bb1040cb1e8308643ce19f2592d1914ebd584ab333ffe65bd7566");
  Add(spki, "810203010001");
  Key;
  Clear(h);
  Add(h, "74f2bab0f7b496db35967b365a4bedc0f6378888dea671ec307ee99e677fe21d");
  Clear(sig);
  Add(sig, "4aefd2b4f05f5e98014621675a0d65ce244fb81d6b4da115cfea2e0eca028f1b");
  Add(sig, "4cf821250705f5fc9d3632163361e9a874ed118f24f66a5e08601b2b79f22706");
  Add(sig, "2adfb688a5dc060ff1e7be50caadd131283786cec67186107ebc7ddf58081eaf");
  Add(sig, "9d332a0eff1ee34e44506c3a7d1d70be26d64fd2059fb265f43f4b621187f914");
  Add(sig, "9ab393a7651f2ebb0adaed3aa4363d4569346ce828974e2d8fa686ea6d4ee049");
  Add(sig, "deaf5f6b4a8a674c7d7f841194507547a1c645b659b122a924b626e20300715b");
  Add(sig, "94a84491300d32f7af288b5e50888802c5cc4b173e4d0dc3f214230cdaa109cb");
  Add(sig, "91b19eb97d001a445152db4eb2f4632f92e6aa6bcef5fd0c4b9697af8a735b79");
  Add(sig, "829ee56de9ab0071f733666d1966d0a0ba5e87d823c25f930f67fdc1309c0978");
  Add(sig, "99089e7d2d8d0405cec69ded46a841c69aeecc5f96f82b636edf6258962044f2");
  Add(sig, "e528d46f600038af9f2bd1c38ba3027b0bda2470d1eccf4dd62d0b476b980c4c");
  Add(sig, "85956733472b620de3569bfe8d0bb11a9a38d51c84b9098a4b463b7001771afc");
  Pkcs1(1);
  Clear(h);
  Add(h, "b526aef1a341cfe6e5c377ed4c222888eeb81f913a107110a867e009c1758f24");
  Clear(sig);
  Add(sig, "b4e74333a72a31a803499d8184f8a1b3d20453d4169d7bfa1a314c4d70b9df08");
  Add(sig, "21d5e1a6fdfae9a556637cf25f1a22ca6c26ed9d85cba10623431430a3da9266");
  Add(sig, "a5e4cdbd4eaf321dcc4014a7b601fd7dc8afe063156fb3bf74110afb6019b75d");
  Add(sig, "156570371c24c36be7d3dee1ddd111c1217d1e10fa00b01f35dacebf091dfc90");
  Add(sig, "cd114a994ad14fcf8822b272b349881dbe64d8d308fa5939a1ada79b450fc7d2");
  Add(sig, "0b65d74729c6195570e81a8bc230f87c1d725180f69ad8f9a6962deeb836c543");
  Add(sig, "bbc8e7b65c362e61e5a36b76e56994699af29303ce873c1902b95cc9c85968cd");
  Add(sig, "0aa5bb55c159bca5017bbb8fbc212e96cd142fae250192e664c50eb413e40d66");
  Add(sig, "90e9df70392b40a0d22bd23e582cd27809aef3bd068d6633bf318cce27290682");
  Add(sig, "4d13dab60edcf7daad144aba68bb70e2e30261dc5051d411b24af69d8c64b478");
  Add(sig, "e0ef1b00cad6b25712de47bb5b159d6a2b56db046103498edd5d84992f1d5b0f");
  Add(sig, "1d78ea9532747a0a97c9fc6505d5730490b3cfb809e222000cb2309b76e7571a");
  Pss(1);
END Vectors;

BEGIN
  fails := 0; checks := 0;
  Vectors;
  Out.String("TLSTestRSA3: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END TLSTestRSA3.
