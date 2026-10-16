MODULE TLSTestSign;  (* ECDSA signatures on secp256r1: the vectors of RFC 6979 A.2.5 (SHA-256, messages
  "sample" and "test"), each signature verifies, survives DER and back, and a changed hash does not verify *)

IMPORT TLSBytes, TLSECDSA, TLSSHA256, Out;

VAR
  fails, checks: LONGINT;
  priv, pub: TLSBytes.Buffer;

PROCEDURE Hex(c: CHAR): LONGINT;
BEGIN
  IF c <= "9" THEN RETURN ORD(c) - ORD("0") ELSE RETURN ORD(c) - ORD("A") + 10 END
END Hex;

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

PROCEDURE Equal(VAR a, b: TLSBytes.Buffer): BOOLEAN;
VAR i: LONGINT;
BEGIN
  IF a.len # b.len THEN RETURN FALSE END;
  i := 0; WHILE (i < a.len) & (a.data[i] = b.data[i]) DO INC(i) END;
  RETURN i = a.len
END Equal;

(* the signature of msg must be r1 r2, s1 s2 (hex, two halves) *)
PROCEDURE Case(msg, r1, r2, s1, s2: ARRAY OF CHAR);
VAR m, h, r, s, wr, ws, der, pr, ps: TLSBytes.Buffer; d: TLSSHA256.Digest;
BEGIN
  TLSBytes.Init(m); TLSBytes.AppendString(m, msg);
  TLSSHA256.DigestBuffer(m, d); TLSSHA256.DigestToBuffer(d, h);
  TLSBytes.Init(wr); Add(wr, r1); Add(wr, r2);
  TLSBytes.Init(ws); Add(ws, s1); Add(ws, s2);
  Check("sign", TLSECDSA.Sign(TLSECDSA.P256, priv, h, r, s));
  Check("r", Equal(r, wr));
  Check("s", Equal(s, ws));
  Check("verifies", TLSECDSA.Verify(TLSECDSA.P256, pub, h, r, s));
  TLSECDSA.SignatureDER(r, s, der);
  Check("DER", TLSECDSA.ParseSignature(der, pr, ps) & TLSECDSA.Verify(TLSECDSA.P256, pub, h, pr, ps));
  h.data[5] := CHR((ORD(h.data[5]) + 1) MOD 256);
  Check("changed hash", ~TLSECDSA.Verify(TLSECDSA.P256, pub, h, r, s))
END Case;

(* signatures with the hashes of "0", "1", ... verify, and come out the same twice *)
PROCEDURE Many(n: LONGINT);
VAR m, h, r, s, r2, s2: TLSBytes.Buffer; d: TLSSHA256.Digest; i: LONGINT; ok: BOOLEAN;
BEGIN
  i := 0; ok := TRUE;
  WHILE i < n DO
    TLSBytes.Init(m); TLSBytes.AppendByte(m, ORD("0") + i MOD 10); TLSBytes.AppendByte(m, i DIV 10);
    TLSSHA256.DigestBuffer(m, d); TLSSHA256.DigestToBuffer(d, h);
    ok := ok & TLSECDSA.Sign(TLSECDSA.P256, priv, h, r, s) & TLSECDSA.Verify(TLSECDSA.P256, pub, h, r, s) &
      TLSECDSA.Sign(TLSECDSA.P256, priv, h, r2, s2) & Equal(r, r2) & Equal(s, s2);
    INC(i)
  END;
  Check("many", ok)
END Many;

PROCEDURE Run*;
VAR bad, r, s, h: TLSBytes.Buffer; i: LONGINT;
BEGIN
  fails := 0; checks := 0;
  TLSBytes.Init(priv); Add(priv, "C9AFA9D845BA75166B5C215767B1D6934E50C3DB36E89B127B8A622B120F6721");
  TLSBytes.Init(pub); TLSBytes.AppendByte(pub, 4);
  Add(pub, "60FED4BA255A9D31C961EB74C6356D68C049B8923B61FA6CE669622E60F29FB6");
  Add(pub, "7903FE1008B8BC99A41AE9E95628BC64F2F1B20C2D7E9F5177A3C294D4462299");
  Case("sample", "EFD48B2AACB6A8FD1140DD9CD45E81D6", "9D2C877B56AAF991C34D0EA84EAF3716",
    "F7CB1C942D657C41D436C7A1B6E29F65", "F3E900DBB9AFF4064DC4AB2F843ACDA8");
  Case("test", "F1ABB023518351CD71D881567B1EA663", "ED3EFCF6C5132B354F28D3B0B7D38367",
    "019F4113742A2B14BD25926B49C64915", "5F267E60D3814B4C0CC84250E46F0083");
  Many(12);
  (* no key: zero, and n itself *)
  TLSBytes.Init(h); i := 0; WHILE i < 32 DO TLSBytes.AppendByte(h, i); INC(i) END;
  TLSBytes.Init(bad); i := 0; WHILE i < 32 DO TLSBytes.AppendByte(bad, 0); INC(i) END;
  Check("zero key", ~TLSECDSA.Sign(TLSECDSA.P256, bad, h, r, s));
  TLSBytes.Init(bad); Add(bad, "FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551");
  Check("key n", ~TLSECDSA.Sign(TLSECDSA.P256, bad, h, r, s));
  Check("P-384", ~TLSECDSA.Sign(TLSECDSA.P384, priv, h, r, s));
  Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln
END Run;

BEGIN
  Run
END TLSTestSign.
