MODULE TLSTestRSA1;  (* TLSRSA against OpenSSL, PKCS#1 v1.5, 2048 bits: valid signatures verify; a changed hash, a
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
  Add(spki, "00ac1e894414e5f396de6ee3a4734430f7c7acf1b97100f899ae12cc6586a2c7");
  Add(spki, "ec201f19a4fa54b92bad4fe9ad46f96ea2e6c742e19ce4183886031b33d8f76c");
  Add(spki, "176c1913e83f5a327776476eb207f9e48d239261335cd0be55e2b97f50390d32");
  Add(spki, "cb35c851c20929f6c63e074bab5714fcc89a8a2bb34707b4cdbb5ed065a444a1");
  Add(spki, "f657782038d3027d32eead1cd665dbdb129f695273537aeb67419085ffc2c152");
  Add(spki, "8e9f80ab8f0d5b0dada7a5b6cbd857760501b2b29ca4e3183025a8e6f7ce7164");
  Add(spki, "518031e57a1603f7880c111030b2eada595931f76956aaba13d3e092f19cdae4");
  Add(spki, "d38532d8e7bf0054cfa095c6f9ffeb44021e4cde5b575d946fc2a88f599bc6f8");
  Add(spki, "930203010001");
  Key;
  Clear(h);
  Add(h, "74f2bab0f7b496db35967b365a4bedc0f6378888dea671ec307ee99e677fe21d");
  Clear(sig);
  Add(sig, "7729a2c15e292f09f928cd1f8ed33cd7b1906822d4159fef0545aca10f4c5175");
  Add(sig, "fe78a3543489177b0512f733fae4cc9a2b9d33b02a7b197bd629024518069b20");
  Add(sig, "c2e6095e1d473094dc47609cb0359ab3962f57e878acd29aee8c3d2103875ebc");
  Add(sig, "78ecdc54045ba622e453ea2a4d0648ab1ee04c5ed0aa74b351052cc4d1562d68");
  Add(sig, "aeea7f050ee90348c7b87bb4ef88b14d07527988b8cf9dbda7111bafeb359bb5");
  Add(sig, "eddec399d2030632c281867ea29cc847bed497ce5ccf4dd79deb8c4b65087c81");
  Add(sig, "007875528de8662d3c21993a1b2d122ff0286df6c2999ee4fde6e8a7dc6b4bb4");
  Add(sig, "cf7837674d6d77ac3e06ccf9f699cebd0b129e7819dd9e9d0b8f8f0bb236fbbd");
  Pkcs1(1);
  Clear(h);
  Add(h, "4e6120cfd0861f00c2b713b50c7b53af53de22f601a1e2a48c4787ef299d4b54");
  Add(h, "394f51601b0dbd366b42a3d521bca993");
  Clear(sig);
  Add(sig, "3840f5d4df187cad211ad52fa703f6ad81f8634c99ca45174d6c7af13607dc48");
  Add(sig, "938eab3def3159c4362ebd39f55cfc96162877c0692ffc9ed625979643751881");
  Add(sig, "943e2f5bdc37e62f1aa6bbf7988690ab03dd26164f4fbec909a0cf059540f2e1");
  Add(sig, "febe2e2ab630a82fdb4eff0b4c362946d2d02925219d26bb0beca5188c1b44e0");
  Add(sig, "06d478986750347b95d2d49df63cabe7d892e84bf01ee7bcd5c610c75df9b114");
  Add(sig, "fe36090f38c71f1038a46ff148a56d79779877955b4c6d47db612135479c3f4a");
  Add(sig, "c452bb01a15c324ca74b9f7f013bcb4501c53ee45ec3efba8a2a733cde16883b");
  Add(sig, "a88d87bd88374becb0d5277e43c5a9ac6c65f4a6f777030b021ec1bb2e2eca01");
  Pkcs1(2);
  Clear(h);
  Add(h, "0ee62dc20b9cfff7c616735cee99ff1d73a111dd99cbe294a59c7024addb9a50");
  Add(h, "dd6009e0e66c48b399302f49334eefe004f39700bf9a281054c0b57f54323b4b");
  Clear(sig);
  Add(sig, "33f5211f64e4641a25c9374db80066d6ba1f61d4fcf592d6968b04a58deec1dd");
  Add(sig, "05ff06c30e2b140f4e09f5ab5fe2b5462a465876795e3dad0043a7bebefedb0a");
  Add(sig, "ea65212343e2c56729cd249ddd4cde19d00274e963a66fb2e3d107d2e4b79853");
  Add(sig, "406ab83e16daa6de77291627f058adcfbf97a2b4a3206220bbd6ca7e10876244");
  Add(sig, "85d7a405805f24a78ccd7f27dc6c87a1467f55ccb05d32b6e8f778ee708f8749");
  Add(sig, "4fa2f82c33a511af4191fce871842c17b379e75789efb7f347081245f9b0680e");
  Add(sig, "e05c180da9a9fbaf78381e5316ad89b759e26b93b1c9cd5bd8142c9bbc408c5c");
  Add(sig, "3ca3b6399da0bc46422d128f88818a46ba316486d3ca7804834b2d50f59c089e");
  Pkcs1(3);
END Vectors;

BEGIN
  fails := 0; checks := 0;
  Vectors;
  Out.String("TLSTestRSA1: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END TLSTestRSA1.
