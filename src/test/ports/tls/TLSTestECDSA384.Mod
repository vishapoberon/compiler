MODULE TLSTestECDSA384;  (* ECDSA on secp384r1 against OpenSSL: valid signatures verify; a changed hash,
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
  Add(pub, "0437cf182af8a8a479ec01de5747402459ac91a984f9f2d8f45bad68e2ceafe0");
  Add(pub, "29bc0077401d2543f5b236f56a10e985b0aa0210265fd22f7e546768bac0fa10");
  Add(pub, "6de890e75d1e1c4ffb6891a2dd7759719259b5eeaeb23c324948851978abcb46");
  Add(pub, "14");
  Clear(h);
  Add(h, "53e1e8f8debcb44819d35f1bb8056b142cb280800b1c2613779a22843f023d02");
  Add(h, "113539540046e3ef601b80ec6236dbb9");
  Clear(der);
  Add(der, "30650231009d78b9a4c2f7fead4c8db7dc6ea392e2af26a7ba5e60106f4a0789");
  Add(der, "4895bd40da1bfac104cdf265eb589273c6f1291f0402303ca506116901c4bc77");
  Add(der, "a7d2d6e8f45d9d3863dac2f342ed0e2dfde274a6eaa89071e1f322293cb65097");
  Add(der, "00105f9f6c2f1e");
  Case(2, 48);
  Clear(pub);
  Add(pub, "0437cf182af8a8a479ec01de5747402459ac91a984f9f2d8f45bad68e2ceafe0");
  Add(pub, "29bc0077401d2543f5b236f56a10e985b0aa0210265fd22f7e546768bac0fa10");
  Add(pub, "6de890e75d1e1c4ffb6891a2dd7759719259b5eeaeb23c324948851978abcb46");
  Add(pub, "14");
  Clear(h);
  Add(h, "4711e1dd5e23860301d40619b121e40cf137b2fad753b7cc6bf4bdb3ad503004");
  Clear(der);
  Add(der, "3065023041ad7940d383df0b8426778d6f6d34d3b871a56794ea73dfbd124f33");
  Add(der, "284a65a966ee6ea46fe3a928a54643d77000c0e9023100c28a46e5f666091a69");
  Add(der, "f30c3532c2ba6cf908b323b1e5ffca9beca04b1b91dae25c1f38f6621a591430");
  Add(der, "b78a9e83fdc26c");
  Case(2, 48);
  Clear(pub);
  Add(pub, "04068b772d5beab2e75bbb31dc44828a1555166abcfcb551dbfcc71f52dc4ba9");
  Add(pub, "70e35b5a821d756c6a353a19bfaa2bd6dd990879cc91f2389ee03dfc2421678f");
  Add(pub, "64d7bc99a2a7c5749e51970360a118024cdc774c54842b7ae7ce49b15f33cd3d");
  Add(pub, "2c");
  Clear(h);
  Add(h, "06e5e5146496290b77d85334c45aa74aa31f7e4f8545f4bc03b1536f55590191");
  Add(h, "e3e8a32061c6f9e7307a7ab3fe4cabb3");
  Clear(der);
  Add(der, "306402300caf3aedcb5ccc54d2b7e5558b07ee1abfc9a767f3baf01fea028422");
  Add(der, "2d3d2edcc2ad71600f5b6511b433610f5b1a80e502304182dcacf8df111193f5");
  Add(der, "455a237dd8e8a147ee378b81b96b5c5805a37a97c75532c1622a48b9f7eb465e");
  Add(der, "36f19acdba70");
  Case(2, 48);
  Clear(pub);
  Add(pub, "04068b772d5beab2e75bbb31dc44828a1555166abcfcb551dbfcc71f52dc4ba9");
  Add(pub, "70e35b5a821d756c6a353a19bfaa2bd6dd990879cc91f2389ee03dfc2421678f");
  Add(pub, "64d7bc99a2a7c5749e51970360a118024cdc774c54842b7ae7ce49b15f33cd3d");
  Add(pub, "2c");
  Clear(h);
  Add(h, "a444d2312167f9b6b0ca2d12445af3f4fee56f8175c1199cb5a8080145d4280c");
  Clear(der);
  Add(der, "306402300ce21251a7d20f02d47d62dd3063b70e54ce779ff07885e84c6d279b");
  Add(der, "5186462c728b5862290d2c524d17fd9018842d1102307f7f52e8258077107000");
  Add(der, "536fb7e91bde576b40e3642a8d810c763276056188ed54447f6f9cc92b629e93");
  Add(der, "b908142496a1");
  Case(2, 48);
  Clear(pub);
  Add(pub, "042ec10de96a43f9f22f9366f172904ec0a16b6d634bf190e8d70703da40b601");
  Add(pub, "ccec951d90cb8ef347bbffd225b2100c1d0a244570dbda2cd78a1a00cd443e47");
  Add(pub, "b63648074b8772752e191e6634b9ded4e0edc599af6b7637353b66acbda46e5b");
  Add(pub, "94");
  Clear(h);
  Add(h, "39a532e2c58d1e7a6785301629890508d7cc1c3d9a7a131a49d70a3e011cf7c1");
  Add(h, "b2ace30ea8e048f55c3b2e326c979493");
  Clear(der);
  Add(der, "30650231008f2d277d253825626534d4f690e8c8466b79f38ed81bf9fbf4133a");
  Add(der, "be04ec9c2ddb31bbe258737c2ee9425ebd47b73b360230166b351ec4d4338d8d");
  Add(der, "6979ff06896630e7f16acaa07ae997a54300f94f8dc0f7958ce67506c2fef7b6");
  Add(der, "b4d12bda75cc13");
  Case(2, 48);
  Clear(pub);
  Add(pub, "042ec10de96a43f9f22f9366f172904ec0a16b6d634bf190e8d70703da40b601");
  Add(pub, "ccec951d90cb8ef347bbffd225b2100c1d0a244570dbda2cd78a1a00cd443e47");
  Add(pub, "b63648074b8772752e191e6634b9ded4e0edc599af6b7637353b66acbda46e5b");
  Add(pub, "94");
  Clear(h);
  Add(h, "064c48d2c50b707b28ce1342318382d88cf8da268f42a14dd884e9684fad22c7");
  Clear(der);
  Add(der, "3066023100a1a032715770daffd8ac3175fdf952a2ee3296c1825d35cb5b3c00");
  Add(der, "b2cac8430c0ce3380da7e0af980e5fb37dc7ec6245023100867adf4bd3950a88");
  Add(der, "da3995ba3a93c1e7b676ed8d12dc2b5d7642a42767033315ccaf77ab4617354f");
  Add(der, "91c2b410db61d1fb");
  Case(2, 48);
END Vectors;

BEGIN
  fails := 0; checks := 0;
  Vectors;
  Out.String("TLSTestECDSA384: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END TLSTestECDSA384.
