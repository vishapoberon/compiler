MODULE TLSTestECDSA521;  (* ECDSA on secp521r1 against the Python cryptography package
  (two SHA-512 and one SHA-256 hash; three vectors: the ARM compiler takes 4 KB of strings): valid
  signatures verify; a changed hash, r and s swapped, r = 0, r too big and a public key off the curve
  do not *)

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
  Add(pub, "0401b4666f860edd952664371522194fcc2eb7bb0fd655e8b39113d3bbea0bbb");
  Add(pub, "a888a6c9729315d41b39ab65f01e3f4ecb931e7356818bb5fb083d06aed2c66b");
  Add(pub, "01526200846291d1325d12b800390fdbb897ba1653aee43e643655219d2d1da9");
  Add(pub, "651d1fd140b3065addf0586acc697c1da80aa7d4a073df19f427cd739451a9f9");
  Add(pub, "e24875aeba");
  Clear(h);
  Add(h, "644a208be8e510945826d3084d1f3133eefffcae4259346ca88227f6e814d752");
  Add(h, "050fde2caef63b55b54351f0a97fd42e862b1eb395def3aac340922f5bbdf8d1");
  Clear(der);
  Add(der, "308188024200c3e88c79b3418016183f7ea396bc6b9665047eb21bca3d1cec11");
  Add(der, "6c648315a961ed4547221a06ae3ad88fe78fbb1cc343d31a84156e3c40e6670b");
  Add(der, "586c3765441a4d0242012d5d037d88ad865a7412d3cb9b7489a83fadcce9042e");
  Add(der, "4b593cbdf87350ba6c43543f848319a51507e2d4674b2c5af28492975e4f13d0");
  Add(der, "e465f75dbd8495970020eb");
  Case(TLSECDSA.P521, 66);
  Clear(pub);
  Add(pub, "04010a6fdf570dd0f30d6a6fc011dc11b39a05718bdbdc1f4d824713e1808768");
  Add(pub, "e6a559803ce475cd6c4d0ed19a237f18d68263e41428f69b19ebb5d4d2cec33f");
  Add(pub, "396eec00d1a0b82c55d240e5897ce305122acfe8d32cc33c4df2605ab709c61e");
  Add(pub, "919d940d9dd806380c2970be9b67995cb201b940417edfea7bd9099b458be73f");
  Add(pub, "d27b2ca51c");
  Clear(h);
  Add(h, "ca7992ff95c177d2550dd6ad2742c9335f141b56ba0a72412a00154389661d01");
  Clear(der);
  Add(der, "30818802420105ce0fa6aa70f7f0b46e1683350b098e01968081550615c41437");
  Add(der, "707d21b26407e74ba01f851ad509b05b2d2d58c95cebd3d3c1c73db1925136f4");
  Add(der, "ecd3be73b13d500242010b7dd7d868f4769a9b146ca37383fabbdbfca018111f");
  Add(der, "dee64badc59d486a2a92a87bf3879ba3a3f7ff4c207b0f27339642fd9d7739f1");
  Add(der, "7d3b5ddd69e552d0d033f5");
  Case(TLSECDSA.P521, 66);
  Clear(pub);
  Add(pub, "0400729e14913df78e7ba2f5850c1402fd5f4fb5f2930926bce734f07d5220e4");
  Add(pub, "8b00fb0485e61d66dd9691809ec913e04b5017f4181b79b615ddf0ff0ef9e968");
  Add(pub, "f72dc800ef2dbfb06fe807f6eef7b521e219d468e788d1e7a394597735d54864");
  Add(pub, "7c91ac345098fe5ba3d85ca11c3cfe45c06452e7cf33f830744c606ab578b83a");
  Add(pub, "e0a12df2e7");
  Clear(h);
  Add(h, "d3f56447194601a2755150a5d74ac9fdadf14dded20fe5778193ade66d2bb628");
  Add(h, "36fc1b53fd5f1a592419d1ed0063237c61583d7b5ae57b2319e63776036381fc");
  Clear(der);
  Add(der, "3081870241408211f67dc6c62ae93a66ad9f7931f0516d08e2ce7795e8c229c7");
  Add(der, "a8e989cf87589c8d1fffde88c89d867a40403a30923307a893e71337eb54c4c2");
  Add(der, "385711b1d6f1024200db1b34e696dd98d223de7523527893038cc432bb3d6f40");
  Add(der, "93d255714306616585695f537d13ec0ff7b7556c80f7ee0d3d456e7e954acae1");
  Add(der, "5f6ff594dd9eb52fa2ff");
  Case(TLSECDSA.P521, 66);
END Vectors;

BEGIN
  fails := 0; checks := 0;
  Vectors;
  Out.String("TLSTestECDSA521: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END TLSTestECDSA521.
