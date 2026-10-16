MODULE TLSTestNumBig;  (* moduli of 521, 1024 and 2048 bits: TLSNum against Python: byte conversion, ModAdd, ModSub, Montgomery
  products, powers, inverses modulo primes, reduction of wider numbers; results of moduli over 64
  bytes compared by their SHA-256 *)

IMPORT TLSBytes, TLSNum, TLSSHA256, Out;

VAR
  fails, checks: LONGINT;
  m, a, b, e, w: TLSBytes.Buffer;

PROCEDURE Hex(c: CHAR): LONGINT;
BEGIN
  IF c <= "9" THEN RETURN ORD(c) - ORD("0") ELSE RETURN ORD(c) - ORD("a") + 10 END
END Hex;

PROCEDURE Clear(VAR x: TLSBytes.Buffer);
BEGIN TLSBytes.Init(x)
END Clear;

PROCEDURE Add(VAR x: TLSBytes.Buffer; h: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(h) - 1) & (h[i] # 0X) DO TLSBytes.AppendByte(x, Hex(h[i]) * 16 + Hex(h[i+1])); INC(i, 2) END
END Add;

PROCEDURE Check(what: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN INC(fails); Out.String("FAIL "); Out.String(what); Out.String(" ("); Out.Int(m.len, 0); Out.String(" bytes)"); Out.Ln END
END Check;

(* the results in order, as bytes of n each: a+b, a-b, a*b, a^e, (1/a if prime) *)
PROCEDURE Ops(n: LONGINT; prime, hashed: BOOLEAN);
VAR mn, an, bn, am, bm, r, t: TLSNum.Num; mod: TLSNum.Modulus; got, x, h: TLSBytes.Buffer; d: TLSSHA256.Digest;
BEGIN
  TLSNum.FromBytes(m.data, 0, m.len, 0, mn);
  TLSNum.FromBytes(a.data, 0, a.len, mn.len, an); TLSNum.FromBytes(b.data, 0, b.len, mn.len, bn);
  TLSNum.ToBytes(an, n, x); Check("round trip", TLSBytes.EqualConstTime(x, a));
  TLSNum.InitModulus(mn, mod);
  TLSBytes.Init(got);
  TLSNum.ModAdd(an, bn, mod, r); TLSNum.ToBytes(r, n, x); TLSBytes.Append(got, x);
  TLSNum.ModSub(an, bn, mod, r); TLSNum.ToBytes(r, n, x); TLSBytes.Append(got, x);
  TLSNum.ToMont(an, mod, am); TLSNum.ToMont(bn, mod, bm);
  TLSNum.MontMul(am, bm, mod, t); TLSNum.FromMont(t, mod, r); TLSNum.ToBytes(r, n, x); TLSBytes.Append(got, x);
  TLSNum.MontPow(am, e.data, 0, e.len, mod, t); TLSNum.FromMont(t, mod, r); TLSNum.ToBytes(r, n, x); TLSBytes.Append(got, x);
  IF prime THEN TLSNum.MontInvPrime(am, mod, t); TLSNum.FromMont(t, mod, r); TLSNum.ToBytes(r, n, x); TLSBytes.Append(got, x) END;
  IF hashed THEN TLSSHA256.DigestBuffer(got, d); TLSSHA256.DigestToBuffer(d, h); got := h END;
  Check("add, sub, mul, pow, inv", TLSBytes.EqualConstTime(got, w))
END Ops;

PROCEDURE Reduce(n: LONGINT);
VAR mn, an, r: TLSNum.Num; mod: TLSNum.Modulus; x: TLSBytes.Buffer;
BEGIN
  TLSNum.FromBytes(m.data, 0, m.len, 0, mn); TLSNum.InitModulus(mn, mod);
  TLSNum.FromBytes(a.data, 0, a.len, 0, an);
  TLSNum.ModReduce(an, mod, r); TLSNum.ToBytes(r, n, x); Check("reduce", TLSBytes.EqualConstTime(x, w))
END Reduce;

PROCEDURE Vectors;
BEGIN
  Clear(m);
  Add(m, "01985aec4989dfe15e7834d474c0db9b3642ef5e7d7a3a862aac5826a9974368");
  Add(m, "903d646c2d6447d433985b11bb37b54c395077616364568c43961dfc388c3d5d");
  Add(m, "f973");
  Clear(a);
  Add(a, "01482c16bf90daf331a70f1e8eeaecf3b2fe570c950939a08333b3bb79465af9");
  Add(a, "27049ad8243c00a6af4251968f0a7def22f65097cce9963ee154af3580393e6b");
  Add(a, "deb6");
  Clear(b);
  Add(b, "003255ec82e020f61881db89c976e4da22a5dfe20db955b60820662d1fbc936b");
  Add(b, "c51cb9492ca5d5ca0143fcb778b01bb7ad5ef23570d9ba969966816be8e9dc55");
  Add(b, "2bb9");
  Clear(e);
  Add(e, "a15b");
  Clear(w);
  Add(w, "8e17e5f2144537cfd2f4f26d5eb28fd06ccceb3899b04c4fe06658c5b4d2c26c");
  Ops(66, FALSE, TRUE);
  Clear(m);
  Add(m, "fd81739b10dad339fec3a6f6cf439961dd132f51c6e22ec667b4a9487359c053");
  Add(m, "a5442840b1abac56ee22b9b550ae014491d255c0707620135c26a157cc8dd3f2");
  Add(m, "908fa0bb760b19461436ad1a7d57d3926b7cf30cd7369de5749e0f7793c012aa");
  Add(m, "3b3c1aa16ba3be7682e92419ba03fc6fecc233984e3e52d639302a9050391193");
  Clear(a);
  Add(a, "527b2b6dc05cb0f79e0225c78cce1b568b5b4e43942db6fe322ab89da7df62c1");
  Add(a, "28e8618dd6a7b06a76410803a7db1792b555a37a27cd7777d8d22445c86f23ab");
  Add(a, "19a984fc012c2ab494c225fdc9c33e0fed794d4164d8d6441f1ba5f3e8207ee2");
  Add(a, "926a73237bf5463a9e1279698c3a29259d1b4545bcdc28197559c47557f67eee");
  Clear(b);
  Add(b, "5647d35645bd4d4607500ef668679c0ff645484aa985641d9110581bfcbd4c16");
  Add(b, "9ac06515dd8bc85d75a41e3956b8ed0deb6e485ec74bfe4daf7f516fb5232ea1");
  Add(b, "d49bfd11280d72899650edbe77855134b937d93c87b3673ffedbffb91dc1f228");
  Add(b, "a0f2431e8535b2fba582dd2c8e9db63ffaec407b3bc97e8b67ddfbe55e6872e9");
  Clear(e);
  Add(e, "4284");
  Clear(w);
  Add(w, "31b07c25363e207fa9f3866d490e52afcfa09dd15af90a4f283f592c50e945cd");
  Ops(128, FALSE, TRUE);
  Clear(m);
  Add(m, "f975589f45bf1e0ccbd0951bd672b96fe85008d5c1da023712fed568c825f342");
  Add(m, "71095291dec3f215560fb97979fef3c0e7a16644630b55b75179fba1a04bb173");
  Add(m, "d32eca482a1fa7bd4facf6e94f63c0fd3c39fecb140c1f555a92baad8004aba8");
  Add(m, "f2b8d77e8b2f76e82de0cd6a3b7c80968086c746ec31bec766c609b24bbaf549");
  Add(m, "8e13db3aebe7b475d729d75db9bdfa0e77fa34b412d6afd60c2377526537307d");
  Add(m, "1dc0b5d4e44f2a3119917326db05ece1e316ac9526d522e87eb7578787ad23ff");
  Add(m, "495fbdb104731888b815c7c5d8169727b0c39f25c8f40e9df02503929d324628");
  Add(m, "2c14f06488b020b723ebe36e321a16f504cccda3d6bc8874f1ed255ff58ed9f9");
  Clear(a);
  Add(a, "b20657231bdd6482a89d9dea663866c98184f4f38d315152c2b30f1c2b80bf81");
  Add(a, "385429e8d912814336ae547f15af2d278516544d77ecb69a923612e2b5b6dc59");
  Add(a, "f8fc109c5494768c7ac1dbe1e9535804733ad4a750243229f41921a7ab3e2589");
  Add(a, "2a838e321fec2287c23d59498085c578a2a562eab253723a67bbc7c97129ac1d");
  Add(a, "ce44f9167454d75563ee529a430b0f98c9edff6c98baf55576c18e6be2fa273d");
  Add(a, "737784a056016bd207ce54fa71eb99c675a349b3ad75c8049cabe2d700f69b83");
  Add(a, "fe7cee54958498ecab441a8d08b99d3b2b48059aa6e68452e629d218679bb848");
  Add(a, "551e32be73b106c60618a224fa3d2c9af27f71dbaa43eaeb3f403c56bdec0c2b");
  Clear(b);
  Add(b, "c610f39f7868caf4de7588c4f36acb49cf6665b9be241dd26716a5dead20266e");
  Add(b, "a0adea51a631382678412e15a535d3bdb36a73e96854595ed058c1584968e341");
  Add(b, "9d7202733888596c6dab6f93faf62e89652016fe3774e384cad7606d3e01dfe9");
  Add(b, "a7b621401ed36fbcfec5d3bb8494f943f34f7a5d7b477f43263c8001f4a4f369");
  Add(b, "3d8d8c4f82be3009a8f8425f72ff01b526e07ad04a57f1f8ec07b4e5429528db");
  Add(b, "933ca35c29dc9ceb451a0362382fdedbb036b6a7b07e190ae299b5284dd1aa8b");
  Add(b, "1ed953ad6a0020c1e6c44bf84560974bde02110aef02f7e52d0995a8410ac48e");
  Add(b, "732531dcddfed077dce8ec0ae6f6fdae52c933f954dbc66faeae72c466230f44");
  Clear(e);
  Add(e, "739a");
  Clear(w);
  Add(w, "6efc9f8da37ad8078c820e2139aa68c41c3eaa9a9dc6f082c8f67952d0c34a2c");
  Ops(256, FALSE, TRUE);
END Vectors;

BEGIN
  fails := 0; checks := 0;
  Vectors;
  Out.String("TLSTestNumBig: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END TLSTestNumBig.
