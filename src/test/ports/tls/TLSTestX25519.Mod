MODULE TLSTestX25519;  (* X25519: RFC 7748 (5.2, the first iteration, 6.1), generated cases with
  the top bit of u set and with u at or above p; values from the RFC 7748 algorithm in Python,
  checked against OpenSSL where it answers (it refuses all-zero results); in short hex pieces *)

IMPORT TLSBytes, TLSX25519, Out;

VAR
  fails, checks: LONGINT;
  k, u, w: TLSBytes.Buffer;  (* scalar, u-coordinate, wanted result *)

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

PROCEDURE Check(VAR q: ARRAY OF CHAR);
VAR g: TLSBytes.Buffer;
BEGIN
  INC(checks); TLSBytes.Init(g); TLSBytes.AppendOpen(g, q, 32);
  IF ~TLSBytes.EqualConstTime(g, w) THEN INC(fails); Out.String("FAIL case "); Out.Int(checks, 0); Out.Ln END
END Check;

PROCEDURE Mult;
VAR q: ARRAY 32 OF CHAR;
BEGIN
  TLSX25519.ScalarMult(q, k.data, u.data); Check(q)
END Mult;

PROCEDURE Base;
VAR q: ARRAY 32 OF CHAR;
BEGIN
  TLSX25519.ScalarMultBase(q, k.data); Check(q)
END Base;

PROCEDURE Vectors;
BEGIN
  Clear(k);
  Add(k, "a546e36bf0527c9d3b16154b82465edd62144c0ac1fc5a18506a2244ba449ac4");
  Clear(u);
  Add(u, "e6db6867583030db3594c1a424b15f7c726624ec26b3353b10a903a6d0ab1c4c");
  Clear(w);
  Add(w, "c3da55379de9c6908e94ea4df28d084f32eccf03491c71f754b4075577a28552");
  Mult;
  Clear(k);
  Add(k, "4b66e9d4d1b4673c5ad22691957d6af5c11b6421e0ea01d42ca4169e7918ba0d");
  Clear(u);
  Add(u, "e5210f12786811d3f4b7959d0538ae2c31dbe7106fc03c3efc4cd549c715a493");
  Clear(w);
  Add(w, "95cbde9476e8907d7aade45cb4b873f88b595a68799fa152e6f8f7647aac7957");
  Mult;
  Clear(k);
  Add(k, "0900000000000000000000000000000000000000000000000000000000000000");
  Clear(u);
  Add(u, "0900000000000000000000000000000000000000000000000000000000000000");
  Clear(w);
  Add(w, "422c8e7a6227d7bca1350b3e2bb7279f7897b87bb6854b783c60e80311ae3079");
  Mult;
  Clear(k);
  Add(k, "f41a344243b47421489b4c33aa72b531605526b8a6915edce4a06f365a34054a");
  Clear(u);
  Add(u, "6c9f0397648e74567078b9ebf5a5509077153df2a34f4286f7344c9a4a1e9694");
  Clear(w);
  Add(w, "d11ea2691d83e99f64695e7dda6a6994ff312db9dd30c8ae4d960eb70d291e65");
  Mult;
  Clear(k);
  Add(k, "b982a9e66b89d0836034e534f2065e879ab5bd3c64570a983f8a424ea145bdb5");
  Clear(u);
  Add(u, "15c3541ec00bb3d200f606f897c0507a8537f20cbd4b356acc9e9d2293120a8a");
  Clear(w);
  Add(w, "8cb86b20428306512ad19c26355c621377f07384f769ad0a0e1df9774ca96112");
  Mult;
  Clear(k);
  Add(k, "cbcf591fd126e217a702f5bf6bfb8b8702104292473db8a675aca1b7be7f553f");
  Clear(u);
  Add(u, "fdc886d69d88af2df64e4b26d9ce96910e3dfb7bbc2eebd1ce3fc6cfaed5bb04");
  Clear(w);
  Add(w, "1cc7480ba083fa2dc38d855a6b3f4ca8708c0dc86795b7a7378d5210d7b62743");
  Mult;
  Clear(k);
  Add(k, "3a0e4c429b7712a09e2b7569d16168919ecf0cdbb1d0df5b138de8023b109c6c");
  Clear(u);
  Add(u, "2800e27c9657fa0a59ff6c619bcfccb1fb5a96a4c87a8a49ee511c398079e491");
  Clear(w);
  Add(w, "cdb0b45147e812be322f9463dc630098461327b39f3825798ce2b776f8b05534");
  Mult;
  Clear(k);
  Add(k, "76d15d3c975b9c04640c5baba5e9ad208fee7068f8044b850f2d2360a857bf95");
  Clear(u);
  Add(u, "a10bb6c1d1102344aab38015eafa89f2a677273ae19ef092d273a09b52b53d39");
  Clear(w);
  Add(w, "2fbf7170984fdfb12b3b09912674ce07bebf9607c72ef5ac77a6075e817af962");
  Mult;
  Clear(k);
  Add(k, "d41504b257b95b3bc1be2ab27fdd8ae4066cd16393d3fa25491c273f5040ac3c");
  Clear(u);
  Add(u, "d6a4364972981bf1ec13f5d0a15c0466dd073ed99be454f7fc4def11c7fc7cb5");
  Clear(w);
  Add(w, "1b9d09008b2d30a1591bd0eeb02bc705357a0201c78dba4f19f356ce0371e332");
  Mult;
  Clear(k);
  Add(k, "b8485d1dc9df9af87ae4f6b664da752b97a62ca3ab5b4ad9455d518b01b365c6");
  Clear(u);
  Add(u, "edffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f");
  Clear(w);
  Add(w, "0000000000000000000000000000000000000000000000000000000000000000");
  Mult;
  Clear(k);
  Add(k, "6e836f6ea211bf1d36264089f5e83270a39e564ab8f91d3dd0c233dcaf959f75");
  Clear(u);
  Add(u, "eeffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f");
  Clear(w);
  Add(w, "0000000000000000000000000000000000000000000000000000000000000000");
  Mult;
  Clear(k);
  Add(k, "59c00b7c09d5d927ca759ffd977ee77cfca6a77d6d0337cdf676877372f8419e");
  Clear(u);
  Add(u, "f7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f");
  Clear(w);
  Add(w, "87d649dbbfe83dea9c301d3bf0b03dcc264f310b9f8b69c64bf8eedbafd1324b");
  Mult;
  Clear(k);
  Add(k, "52bb7c6b24472e560d706686eb9006100374b405aa08e73a65b507a87283eae1");
  Clear(u);
  Add(u, "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f");
  Clear(w);
  Add(w, "355375ab0ede0cf7a94905770a140d7c998db50e2962cff387af49ec065a9315");
  Mult;
  Clear(k);
  Add(k, "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a");
  Clear(w);
  Add(w, "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a");
  Base;
  Clear(k);
  Add(k, "5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb");
  Clear(w);
  Add(w, "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f");
  Base;
  Clear(k);
  Add(k, "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a");
  Clear(u);
  Add(u, "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f");
  Clear(w);
  Add(w, "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742");
  Mult;
  Clear(k);
  Add(k, "5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb");
  Clear(u);
  Add(u, "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a");
  Clear(w);
  Add(w, "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742");
  Mult;
END Vectors;

BEGIN
  fails := 0; checks := 0;
  Vectors;
  Out.String("TLSTestX25519: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END TLSTestX25519.
