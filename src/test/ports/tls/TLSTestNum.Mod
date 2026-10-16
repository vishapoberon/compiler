MODULE TLSTestNum;  (* moduli up to 384 bits: TLSNum against Python: byte conversion, ModAdd, ModSub, Montgomery
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
  Add(m, "e9bb466a287385820942dc06bc69f2658575062102fbcd4f357fbc5af71a1bfd");
  Clear(a);
  Add(a, "d70a6aec03f12d35604b415a63c915037e135e2fad27fddb1d8ae4422463eba4");
  Clear(b);
  Add(b, "0a97cdae107019ca4986bc5817a3b742bdb92263f7be690ced904db842910ef4");
  Clear(e);
  Add(e, "7ffb2d79d2a22f49288b41c8414b564af1cab80f0f358f6ce4d94090735f7c49");
  Clear(w);
  Add(w, "e1a2389a146146ffa9d1fdb27b6ccc463bcc8093a4e666e80b1b31fa66f4fa98");
  Add(w, "cc729d3df381136b16c485024c255dc0c05a3bcbb56994ce2ffa9689e1d2dcb0");
  Add(w, "ae0782238b276014a1d9bd1957514909f530d7211cc249e09912438acfcda50a");
  Add(w, "a050e1a64d1f2d2c90f6f617157dc34bfff5727d81c9fe22db64c3e567e7f810");
  Ops(32, FALSE, FALSE);
  Clear(m);
  Add(m, "de06e22dfff3f4ecb1dcec40db7aca5825b2116aae6cff55ce0c3f08e12656f1");
  Add(m, "0e11160004524a7c3d2bd371fc80be13");
  Clear(a);
  Add(a, "91d00e8b14ebc6c4d7ffe6c9797670940fcbffd7801446ec0b053fc57f9a0875");
  Add(a, "f9f73beedf5b93b37b20e67290a4e300");
  Clear(b);
  Add(b, "15bdfe00ada265af4170a47ab88dc979b142ec2a72f9726297e5293bc14e2624");
  Add(b, "c71a8dab3b55a8c776589091f5d556e1");
  Clear(e);
  Add(e, "9e599a840e53ab3258ea7c5b6f01f40f6139d7f1d5d56adda60419b5c0f2f8d3");
  Add(e, "554666ca0e70d97e0248ebe79c5d9e30");
  Clear(w);
  Add(w, "a78e0c8bc28e2c7419708b4432043a0dc10eec01f30db94ea2ea690140e82e9a");
  Add(w, "c111c99a1ab13c7af1797704867a39e17c12108a67496115968f424ec0e8a71a");
  Add(w, "5e8913ad0d1ad48973201689be4be25132dcae43a405eaec04c855e09acf8c1f");
  Add(w, "dd191e5d1c049f68a255858483f8a6013a26c727924b82c2bfaa82c1eb419df7");
  Add(w, "a7243d234b22ed391844fc4aa73682770f20ffcf3869787867259afa17adf74f");
  Add(w, "dcff3239bed6dfa1849500002cbc239b9633f52518d0d86e44c9d88682f806a6");
  Ops(48, FALSE, FALSE);
  Clear(m);
  Add(m, "ffffffff00000001000000000000000000000000ffffffffffffffffffffffff");
  Clear(a);
  Add(a, "542298af60d1b64557b40284fadb20585a518540618aabe8cdb31b6a5252d301");
  Clear(b);
  Add(b, "f5910a4c39c0d2c77f0f7d1e21b8ac48c62e2cc318b17a035599153eaa29bc93");
  Clear(e);
  Add(e, "2dcc92e212a0a3d5d3c5d8cca82a4f48920757683a54ebd2bc3fdc08ac42bda5");
  Clear(w);
  Add(w, "49b3a2fc9a92890bd6c37fa31c93cca1207fb2027a3c25ec234c30a8fc7c8f95");
  Add(w, "5e918e622710e37ed8a48566d922740f9423587e48d931e5781a062ba829166d");
  Add(w, "36cf5c5e43e678d15c7f5259976b7c00ce3c988d5f3931d46bd8523569d7b149");
  Add(w, "cc0fb9ae2c04b89b76d0ef9ac7b8b0398e43cd8f73be96f183ed63805f89f1a8");
  Add(w, "34de9fa700b93f8006731e605eaab4ac3f0f54bc965b9ce08400e72c1e1ead19");
  Ops(32, TRUE, FALSE);
  Clear(m);
  Add(m, "fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe");
  Add(m, "ffffffff0000000000000000ffffffff");
  Clear(a);
  Add(a, "da613c537e6ca767fb5cd722403e16e37f630e583d230c46371afd9741b10ccb");
  Add(a, "4e665bb3b3bc6d9587801b2eb10322b0");
  Clear(b);
  Add(b, "a5e5c4c384fceda2e00c063b292de7685efc2767efb8c4f07c55e8abcdebee42");
  Add(b, "d77e50483c03106cd69bc7fb2f5ab22f");
  Clear(e);
  Add(e, "f8565c25c9e585a1a279fa12c5899c799ac2a4288802480ad9d0cecd8f42afa4");
  Add(e, "ee31b938f304380b36f88e3da8a89c4c");
  Clear(w);
  Add(w, "804701170369950adb68dd5d696bfe4bde5f35c02cdbd136b370e6430f9cfb0f");
  Add(w, "25e4abfcefbf7e025e1be328e05dd4e0347b778ff96fb9c51b50d0e717102f7b");
  Add(w, "2066e6f04d6a4755bac514eb73c51e8876e80b6b77b95d28b0e4533381a87081");
  Add(w, "5e0419c1a04083f9f7a225e993b5a02de1325d27350f410c33ff3b10556ae964");
  Add(w, "f5c1dbc5216e95c4879b8af4ea161b0eeb93771817ee80d53ad7203b4cca6bf3");
  Add(w, "10af2a00d6419781c092cda8afec7fbeadf8f39b6a5c8bcf84eab69730b6e1c3");
  Add(w, "9fc4ebfdecb6b169fdb5abaaa9576a93eb2dad7300e2b5e8a1587158dd470f88");
  Add(w, "2ce04fab7c9688ba452c2bd2985f6df4");
  Ops(48, TRUE, FALSE);
  Clear(m);
  Add(m, "c2ebf2510ac58dfe990eb05fcfb1aa951cdd8f6c9f5f397b542aec71b653036d");
  Clear(a);
  Add(a, "0a970f0fc24bd6d50b851a38145468787e64c8ad6ad8f194795a7c107c09f9cb");
  Add(a, "7b38ea5ddb0f65b45bc4776e6e");
  Clear(w);
  Add(w, "aa766ea82b54ebdd486da47d593521715334d651d1a5c51633c6ccf7acfc77f3");
  Reduce(32);
  Clear(m);
  Add(m, "c0204cf0619671cea0e2c7f7ee6ab4658ddb6f05a7ee929f6bfbfa325c6ceb5c");
  Add(m, "5285b439510d7457e8cf60959637dd25");
  Clear(a);
  Add(a, "02ebb380b5abf5b7bc10b7a7c5b25990a96ad31f363a47af41a2d2251e91e01e");
  Add(a, "f8d73e0ef4be60916ee31fb13679a8e271da8c97e9ebbbff96020d5b9a");
  Clear(w);
  Add(w, "b14253350f7dbc83151c8fd8ed9b0c09f3bc3b80e8fc09ad6b6ae8bd623d6449");
  Add(w, "bbc4808bc3d0b0a94a4816905c50ef54");
  Reduce(48);
END Vectors;

BEGIN
  fails := 0; checks := 0;
  Vectors;
  Out.String("TLSTestNum: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END TLSTestNum.
