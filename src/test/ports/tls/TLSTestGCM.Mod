MODULE TLSTestGCM;  (* AES-128 (FIPS 197) and AES-128-GCM (the GCM specification, cases 1-4, and
  generated cases compared by the SHA-256 of ciphertext and tag); decryption restores the plain
  text and rejects a changed tag. Values in short hex pieces for the ARM compiler of polpo. *)

IMPORT TLSBytes, TLSSHA256, TLSAESGCM, Out;

VAR
  fails, checks: LONGINT;
  k, n, m, a, w: TLSBytes.Buffer;  (* key, nonce, message, additional data, wanted result *)

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

PROCEDURE Pattern(len, mul, add: LONGINT; VAR b: TLSBytes.Buffer);
VAR i: LONGINT;
BEGIN
  TLSBytes.Init(b); i := 0;
  WHILE i < len DO TLSBytes.AppendByte(b, (i * mul + add) MOD 256); INC(i) END
END Pattern;

PROCEDURE Check(what: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN INC(fails); Out.String("FAIL "); Out.String(what); Out.String(" ("); Out.Int(m.len, 0); Out.String(" bytes)"); Out.Ln END
END Check;

PROCEDURE Block;
VAR c: TLSBytes.Buffer;
BEGIN
  TLSAESGCM.AES128EncryptBlockBuffer(k, m, c); Check("aes block", TLSBytes.EqualConstTime(c, w))
END Block;

(* encrypt m, compare with ct; decrypt it back; a changed tag must fail *)
PROCEDURE Both(VAR ct: TLSBytes.Buffer);
VAR p: TLSBytes.Buffer;
BEGIN
  Check("gcm decrypt", TLSAESGCM.AES128GCMDecrypt(k, ct, n, a, p) & TLSBytes.EqualConstTime(p, m));
  ct.data[ct.len - 1] := CHR((ORD(ct.data[ct.len - 1]) + 1) MOD 256);
  Check("gcm changed tag", ~TLSAESGCM.AES128GCMDecrypt(k, ct, n, a, p))
END Both;

PROCEDURE Gcm;
VAR c: TLSBytes.Buffer;
BEGIN
  TLSAESGCM.AES128GCMEncrypt(k, m, n, a, c); Check("gcm encrypt", TLSBytes.EqualConstTime(c, w));
  Both(c)
END Gcm;

PROCEDURE Generated(j, plen, alen: LONGINT);
BEGIN
  Pattern(16, 7 + j, 3, k); Pattern(12, 11, j, n); Pattern(plen, 13, j + 1, m); Pattern(alen, 17, j + 2, a)
END Generated;

PROCEDURE GcmHashed;
VAR c, h: TLSBytes.Buffer; d: TLSSHA256.Digest;
BEGIN
  TLSAESGCM.AES128GCMEncrypt(k, m, n, a, c);
  TLSSHA256.DigestBuffer(c, d); TLSSHA256.DigestToBuffer(d, h); Check("gcm encrypt", TLSBytes.EqualConstTime(h, w));
  Both(c)
END GcmHashed;

PROCEDURE Vectors;
BEGIN
  Clear(k);
  Add(k, "000102030405060708090a0b0c0d0e0f");
  Clear(m);
  Add(m, "00112233445566778899aabbccddeeff");
  Clear(w);
  Add(w, "69c4e0d86a7b0430d8cdb78070b4c55a");
  Block;
  Clear(k);
  Add(k, "00000000000000000000000000000000");
  Clear(n);
  Add(n, "000000000000000000000000");
  Clear(m);
  Clear(a);
  Clear(w);
  Add(w, "58e2fccefa7e3061367f1d57a4e7455a");
  Gcm;
  Clear(k);
  Add(k, "00000000000000000000000000000000");
  Clear(n);
  Add(n, "000000000000000000000000");
  Clear(m);
  Add(m, "00000000000000000000000000000000");
  Clear(a);
  Clear(w);
  Add(w, "0388dace60b6a392f328c2b971b2fe78ab6e47d42cec13bdf53a67b21257bddf");
  Gcm;
  Clear(k);
  Add(k, "feffe9928665731c6d6a8f9467308308");
  Clear(n);
  Add(n, "cafebabefacedbaddecaf888");
  Clear(m);
  Add(m, "d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a72");
  Add(m, "1c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b391aafd255");
  Clear(a);
  Clear(w);
  Add(w, "42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e");
  Add(w, "21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e091473f5985");
  Add(w, "4d5c2af327cd64a62cf35abd2ba6fab4");
  Gcm;
  Clear(k);
  Add(k, "feffe9928665731c6d6a8f9467308308");
  Clear(n);
  Add(n, "cafebabefacedbaddecaf888");
  Clear(m);
  Add(m, "d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a72");
  Add(m, "1c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39");
  Clear(a);
  Add(a, "feedfacedeadbeeffeedfacedeadbeefabaddad2");
  Clear(w);
  Add(w, "42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e");
  Add(w, "21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e0915bc94fbc");
  Add(w, "3221a5db94fae95ae7121a47");
  Gcm;
  Generated(0, 1, 0);
  Clear(w);
  Add(w, "6ff6f4251008ed89558d13fd4080123a051789c4ac6b26f153904fc3ccce1b7b");
  GcmHashed;
  Generated(1, 1, 13);
  Clear(w);
  Add(w, "8ede9037e5d56c800c7d34b51e167d370b8571aaa7e3eba8c71ee90d9508141c");
  GcmHashed;
  Generated(2, 15, 0);
  Clear(w);
  Add(w, "a42aaf9978488dcc38993c53286a701544928fe532607cc8a4a3e0f938c2b100");
  GcmHashed;
  Generated(3, 15, 13);
  Clear(w);
  Add(w, "a2a1bbaf580134075f186795c3a7c95955c770fcb68aaf933fe5c3bf12b14b04");
  GcmHashed;
  Generated(4, 16, 0);
  Clear(w);
  Add(w, "38a97ff188c8fd49b66923ea9fe06a85f77b07fa1b3db83b895f71a3131e7764");
  GcmHashed;
  Generated(5, 16, 13);
  Clear(w);
  Add(w, "9b0717bdd5ff2acfa964361d2b18433f7ca94bfa490f89fcc8f8f9816b370d14");
  GcmHashed;
  Generated(6, 17, 0);
  Clear(w);
  Add(w, "03631df9548edb190bc7c75b3fbb3d16ebb2029e47d9a9b3e46adf0e6b71a449");
  GcmHashed;
  Generated(7, 17, 13);
  Clear(w);
  Add(w, "e93f801fbd35ba1dd4e8fbda97041aa1ed9b8a65c836d125ed137d7710f43645");
  GcmHashed;
  Generated(8, 31, 0);
  Clear(w);
  Add(w, "e9412e38dcb525363c196d01d39b548d8ed284d65c4c437bd0cd237fb9003b88");
  GcmHashed;
  Generated(9, 31, 13);
  Clear(w);
  Add(w, "d0822567d76acbf4267886b4fc405e02bfa3232a7ab965042790099678dc271f");
  GcmHashed;
  Generated(10, 32, 0);
  Clear(w);
  Add(w, "e9300f3fae2f74f1e2a14b049fbe88cd9cb95aeaa1aa23912030e98fa0a82741");
  GcmHashed;
  Generated(11, 32, 13);
  Clear(w);
  Add(w, "5df8ad649f5a848e1b955e9c7d30905d8f40c9a245d7b589c00d9355d304fb07");
  GcmHashed;
  Generated(12, 33, 0);
  Clear(w);
  Add(w, "d230b40ea3ebf626551ce8cd43f09bf3984eacafb11ad5bc94b1ea49cbed4ea3");
  GcmHashed;
  Generated(13, 33, 13);
  Clear(w);
  Add(w, "5e44b41f9deed1f8753fa765cfa96979845ab41e7b43605bd0d6329d86b93418");
  GcmHashed;
  Generated(14, 64, 0);
  Clear(w);
  Add(w, "139f126f27b94df45988f0de71619404c5e2e2d80e8caf28bd4267deb4a32022");
  GcmHashed;
  Generated(15, 64, 13);
  Clear(w);
  Add(w, "523e5241c532a69e3370ae348b2853f0653dcfb40cc7c883c468dc556e6bf08c");
  GcmHashed;
  Generated(16, 100, 0);
  Clear(w);
  Add(w, "33ee6c8a895b5debad7e423b9b125d9b59cddd853dfef441cc0bf926c3bc2609");
  GcmHashed;
  Generated(17, 100, 13);
  Clear(w);
  Add(w, "740d1ecd73bda711583d3357364369a53f7368d5373e6a1efd501ace6ca46c2b");
  GcmHashed;
  Generated(18, 1000, 5);
  Clear(w);
  Add(w, "53f7962fc6c89c64c867df617952b3e1e390bb41b66cb30f6ea7eb3bed71e583");
  GcmHashed;
  Generated(19, 5000, 29);
  Clear(w);
  Add(w, "66e129776bf1caa38d049117da009fd1329060304976eb5fb5bdba047e0ffc49");
  GcmHashed;
  Generated(20, 16384, 0);
  Clear(w);
  Add(w, "d62aecb98790a742ad60aa8b2939a6877d49ce58aded686d6f8af02ed941fc22");
  GcmHashed;
END Vectors;

BEGIN
  fails := 0; checks := 0;
  Vectors;
  Out.String("TLSTestGCM: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END TLSTestGCM.
