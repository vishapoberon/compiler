MODULE TLSTestSHA512;  (* SHA-512 and SHA-384 against Python (FIPS 180 examples, block boundaries);
  values in short hex pieces *)

IMPORT TLSBytes, TLSSHA512, Out;

VAR
  fails, checks: LONGINT;
  m, w: TLSBytes.Buffer;

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

PROCEDURE Check(what: ARRAY OF CHAR; VAR g: TLSBytes.Buffer);
BEGIN
  INC(checks);
  IF ~TLSBytes.EqualConstTime(g, w) THEN INC(fails); Out.String("FAIL "); Out.String(what); Out.String(" ("); Out.Int(m.len, 0); Out.String(" bytes)"); Out.Ln END
END Check;

PROCEDURE Sha512;
VAR g: TLSBytes.Buffer;
BEGIN TLSSHA512.Digest512(m, g); Check("sha512", g)
END Sha512;

PROCEDURE Sha384;
VAR g: TLSBytes.Buffer;
BEGIN TLSSHA512.Digest384(m, g); Check("sha384", g)
END Sha384;

PROCEDURE Vectors;
BEGIN
  Clear(m);
  Clear(w);
  Add(w, "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce");
  Add(w, "47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e");
  Sha512;
  Clear(w);
  Add(w, "38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da");
  Add(w, "274edebfe76f65fbd51ad2f14898b95b");
  Sha384;
  Clear(m);
  Add(m, "616263");
  Clear(w);
  Add(w, "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a");
  Add(w, "2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f");
  Sha512;
  Clear(w);
  Add(w, "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed");
  Add(w, "8086072ba1e7cc2358baeca134c825a7");
  Sha384;
  Clear(m);
  Add(m, "61626364656667686263646566676869636465666768696a6465666768696a6b");
  Add(m, "65666768696a6b6c666768696a6b6c6d6768696a6b6c6d6e68696a6b6c6d6e6f");
  Add(m, "696a6b6c6d6e6f706a6b6c6d6e6f70716b6c6d6e6f7071726c6d6e6f70717273");
  Add(m, "6d6e6f70717273746e6f707172737475");
  Clear(w);
  Add(w, "8e959b75dae313da8cf4f72814fc143f8f7779c6eb9f7fa17299aeadb6889018");
  Add(w, "501d289e4900f7e4331b99dec4b5433ac7d329eeb6dd26545e96e55b874be909");
  Sha512;
  Clear(w);
  Add(w, "09330c33f71147e83d192fc782cd1b4753111b173b3b05d22fa08086e3b0f712");
  Add(w, "fcc7c71a557e2db966c3e9fa91746039");
  Sha384;
  Pattern(111, m);
  Clear(w);
  Add(w, "da780d8338a8a920ceb6892cb4ecbb0cc0c66956269aadd5dd0f48790a00857b");
  Add(w, "d975890f3b2955a317738cc7a770820c29f922ffbc22020f1909d594cc987d1b");
  Sha512;
  Clear(w);
  Add(w, "5922d169e553267e1846ae2128a026407faf487dab98dfb383e751d3846f82f6");
  Add(w, "edbe70b48b6202327516159d340c56a9");
  Sha384;
  Pattern(112, m);
  Clear(w);
  Add(w, "053182f7fa4e59f8636e415a77ed4fdc650f0a43834c9d35adf899599c3ab9c4");
  Add(w, "153f02ff50bd01888060cd36a6fa12d9db242fc35164c80135613514186d5843");
  Sha512;
  Clear(w);
  Add(w, "b42aff1d6d298152801480cb2b5851c32afe5e5fbae583b0a9b52fe955440c3f");
  Add(w, "276fd812c0f4439cf94c3f9e03068a21");
  Sha384;
  Pattern(127, m);
  Clear(w);
  Add(w, "a7a75593826fd37d4e60f6101eabb9f8ab1cf4d5319ebc805266d5da8deb5097");
  Add(w, "de1a235fc5d9d3d73c50ac100ffc75089fb454674ab61232091bd19cbdc67396");
  Sha512;
  Clear(w);
  Add(w, "e0cc0da38b3a32572851d199e9e485afe1e62f5c24ac1c7f0b6680a1ea9febbe");
  Add(w, "49d02923617d02074dd2ad70b5671389");
  Sha384;
  Pattern(128, m);
  Clear(w);
  Add(w, "df007a08f3aaae47e0c92ef840ecd43645ae6098c819f2a4a66174ef1cd49e5c");
  Add(w, "6dfccf0616895e570b7564af641de5863dff9f89c752913d30cf0ecf678e1635");
  Sha512;
  Clear(w);
  Add(w, "95ab88109cbf117548a8ad35909ffefa175d06a9c42614b9d359548cff5d550b");
  Add(w, "30affb36ff638cd32aa5f5409066c68a");
  Sha384;
  Pattern(129, m);
  Clear(w);
  Add(w, "a10ea769b79831bca33e9efb29fc501ded6e9c88885d079acb76eecaa8ac58d6");
  Add(w, "8bdc7e00103053e1519352c0d064c87accc3d553a6039decc2c4f1e7667eef79");
  Sha512;
  Clear(w);
  Add(w, "1d0599fa8c2d4e8d626778051da62b78a0ecc76cbfdc5687302048373d1f8a5e");
  Add(w, "772f19aeaf7be25f68e0ccf4f0b7f8a8");
  Sha384;
  Pattern(239, m);
  Clear(w);
  Add(w, "38980139aa28f1ccec548e21fd73d927488c4aa749a4b304fe0c5f7797fb80a0");
  Add(w, "3bc0557584ef42f47e0d3ff4eee0011084ac8421cf08dd2cea6a132bcd075c90");
  Sha512;
  Clear(w);
  Add(w, "b0e8d8a1df31886ebb4707fbfce9ae5873f3dabcf6e7563f3352c1d837a5923a");
  Add(w, "d7eedfe6b8c6d4a813095a30c352eb30");
  Sha384;
  Pattern(240, m);
  Clear(w);
  Add(w, "eb5690f4b1753298de6626f031576ca2b93cec042d597a7a1f9e47534af610f4");
  Add(w, "09acb608d88fdaeade8b36fd09a6cd81f2ff8ec10962e79cd791eebc26d569f5");
  Sha512;
  Clear(w);
  Add(w, "62f145f55197394c113cdf35478b33900a179a2d2f7559f0584f914cc77dc49d");
  Add(w, "631746abddd484e489ce7ab478a69d20");
  Sha384;
  Pattern(1000, m);
  Clear(w);
  Add(w, "b41d42e106eca6bf57123566b7ed1550c37d33af23afbfa8e302dfd44c988b30");
  Add(w, "03a26b4140ef42f535e66ea424e7c4a31616307269e6d520a6508f726da23d0a");
  Sha512;
  Clear(w);
  Add(w, "4f33e6bdc22d2129245d832f3b149770b799aa9e63b4c79bd3073aca7e5afc83");
  Add(w, "32c83cace1f5d81c22a256f09dcb3f98");
  Sha384;
  Pattern(32767, m);
  Clear(w);
  Add(w, "fb35fdfb948ac4c91e069566df1884e329ec687ba107e2e95f0e8698347b51ab");
  Add(w, "c30dec8a038066afaacb241db22cc678660f84940070aeecaa1a2fff756c2a2b");
  Sha512;
  Clear(w);
  Add(w, "048f80261249ceb2d0acb3a007d4b20712c15294c061050a423c07cc79c381bd");
  Add(w, "fef861c1f59dc4ddd0be1fd6dfa2545a");
  Sha384;
END Vectors;

BEGIN
  fails := 0; checks := 0;
  Vectors;
  Out.String("TLSTestSHA512: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END TLSTestSHA512.
