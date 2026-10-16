MODULE TLSECDSA;
(* ECDSA signature verification over NIST P-256, P-384 and P-521 (FIPS 186-4, SEC 1), for certificates
   and CertificateVerify, and ECDH (SEC 1 3.3.1) for a TLS key share. Field arithmetic modulo p
   and n in Montgomery form with TLSNum (32 bit integers only); Jacobian coordinates with the
   a = -3 doubling (dbl-2001-b) and add-2007-bl; u1*G + u2*Q in one pass (Shamir).
   Verification uses only public values. ECDH uses a Montgomery ladder whose steps do not depend
   on the bits of the scalar (a swap by arithmetic, not a branch), but the field arithmetic is
   not constant time; the scalar is an ephemeral key used once, which timing attacks (they need
   many runs with one key) cannot exploit.
   Sign (P-256 with SHA-256, for the CertificateVerify of a server) takes k from the key and the
   hash (RFC 6979), so that no weak random number can reveal the key; k G is computed by the same
   ladder. The key of a server is used for many signatures, and the arithmetic (the final
   subtraction of MontMul) is not constant time: good for experimental servers, not hardened
   against an attacker who measures many handshakes. *)
IMPORT TLSBytes, TLSNum, TLSSHA256;

CONST
  P256* = 1; P384* = 2; P521* = 3;  (** curves *)

TYPE
  Num = TLSNum.Num;
  Curve = RECORD
    bytes: LONGINT;          (* 32, 48 or 66 *)
    p, n: TLSNum.Modulus;
    b, gx, gy, three: Num    (* Montgomery form modulo p *)
  END;
  Point = RECORD x, y, z: Num; inf: BOOLEAN END;

VAR
  curves: ARRAY 4 OF Curve;

PROCEDURE HexVal(ch: CHAR): LONGINT;
BEGIN
  IF ch <= "9" THEN RETURN ORD(ch) - ORD("0") ELSE RETURN ORD(ch) - ORD("a") + 10 END
END HexVal;

(* the big endian hex number h1 h2 in n (two halves: string constants are short on ARM) *)
PROCEDURE HexNum(h1, h2: ARRAY OF CHAR; VAR n: Num);
VAR b: TLSBytes.Buffer; i: LONGINT;
BEGIN
  TLSBytes.Init(b); i := 0;
  WHILE (i < LEN(h1) - 1) & (h1[i] # 0X) DO TLSBytes.AppendByte(b, HexVal(h1[i]) * 16 + HexVal(h1[i+1])); INC(i, 2) END;
  i := 0;
  WHILE (i < LEN(h2) - 1) & (h2[i] # 0X) DO TLSBytes.AppendByte(b, HexVal(h2[i]) * 16 + HexVal(h2[i+1])); INC(i, 2) END;
  TLSNum.FromBytes(b.data, 0, b.len, 0, n)
END HexNum;

(* p, n, b, gx, gy of the curve, each as two halves of its hex digits *)
PROCEDURE InitCurve(VAR c: Curve; bytes: LONGINT; p1, p2, n1, n2, b1, b2, gx1, gx2, gy1, gy2: ARRAY OF CHAR);
VAR t: Num;
BEGIN
  c.bytes := bytes;
  HexNum(p1, p2, t); TLSNum.InitModulus(t, c.p);
  HexNum(n1, n2, t); TLSNum.InitModulus(t, c.n);
  HexNum(b1, b2, t); t.len := c.p.m.len; TLSNum.ToMont(t, c.p, c.b);
  HexNum(gx1, gx2, t); t.len := c.p.m.len; TLSNum.ToMont(t, c.p, c.gx);
  HexNum(gy1, gy2, t); t.len := c.p.m.len; TLSNum.ToMont(t, c.p, c.gy);
  TLSNum.SetSmall(t, c.p.m.len, 3); TLSNum.ToMont(t, c.p, c.three)
END InitCurve;

(* ----- the field modulo p, in Montgomery form ----- *)

PROCEDURE Mul(VAR c: Curve; VAR a, b, out: Num);
BEGIN TLSNum.MontMul(a, b, c.p, out)
END Mul;

PROCEDURE Add(VAR c: Curve; VAR a, b, out: Num);
BEGIN TLSNum.ModAdd(a, b, c.p, out)
END Add;

PROCEDURE Sub(VAR c: Curve; VAR a, b, out: Num);
BEGIN TLSNum.ModSub(a, b, c.p, out)
END Sub;

(* ----- points ----- *)

(* r := 2 p *)
PROCEDURE Double(VAR c: Curve; VAR p, r: Point);
VAR delta, gamma, beta, alpha, t1, t2, t3, x3, y3, z3: Num;
BEGIN
  IF p.inf OR TLSNum.IsZero(p.y) THEN r.inf := TRUE; RETURN END;
  Mul(c, p.z, p.z, delta); Mul(c, p.y, p.y, gamma); Mul(c, p.x, gamma, beta);
  Sub(c, p.x, delta, t1); Add(c, p.x, delta, t2); Mul(c, t1, t2, t3);
  Add(c, t3, t3, alpha); Add(c, alpha, t3, alpha);                 (* alpha = 3 (x - delta)(x + delta) *)
  Mul(c, alpha, alpha, x3);
  Add(c, beta, beta, t1); Add(c, t1, t1, t1);                      (* 4 beta *)
  Add(c, t1, t1, t2); Sub(c, x3, t2, x3);                          (* x3 = alpha^2 - 8 beta *)
  Add(c, p.y, p.z, t2); Mul(c, t2, t2, z3); Sub(c, z3, gamma, z3); Sub(c, z3, delta, z3);
  Sub(c, t1, x3, t2); Mul(c, alpha, t2, y3);
  Mul(c, gamma, gamma, t3); Add(c, t3, t3, t3); Add(c, t3, t3, t3); Add(c, t3, t3, t3);  (* 8 gamma^2 *)
  Sub(c, y3, t3, y3);
  r.x := x3; r.y := y3; r.z := z3; r.inf := FALSE
END Double;

(* r := p + q *)
PROCEDURE AddPoints(VAR c: Curve; VAR p, q, r: Point);
VAR z1z1, z2z2, u1, u2, s1, s2, h, i, j, rr, v, t, x3, y3, z3: Num;
BEGIN
  IF p.inf THEN r := q; RETURN END;
  IF q.inf THEN r := p; RETURN END;
  Mul(c, p.z, p.z, z1z1); Mul(c, q.z, q.z, z2z2);
  Mul(c, p.x, z2z2, u1); Mul(c, q.x, z1z1, u2);
  Mul(c, p.y, q.z, t); Mul(c, t, z2z2, s1);
  Mul(c, q.y, p.z, t); Mul(c, t, z1z1, s2);
  Sub(c, u2, u1, h); Sub(c, s2, s1, rr);
  IF TLSNum.IsZero(h) THEN
    IF TLSNum.IsZero(rr) THEN Double(c, p, r) ELSE r.inf := TRUE END;
    RETURN
  END;
  Add(c, rr, rr, rr);                                              (* r = 2 (s2 - s1) *)
  Add(c, h, h, t); Mul(c, t, t, i);                                (* i = (2h)^2 *)
  Mul(c, h, i, j); Mul(c, u1, i, v);
  Mul(c, rr, rr, x3); Sub(c, x3, j, x3); Sub(c, x3, v, x3); Sub(c, x3, v, x3);
  Sub(c, v, x3, t); Mul(c, rr, t, y3);
  Mul(c, s1, j, t); Add(c, t, t, t); Sub(c, y3, t, y3);
  Add(c, p.z, q.z, t); Mul(c, t, t, z3); Sub(c, z3, z1z1, z3); Sub(c, z3, z2z2, z3); Mul(c, z3, h, z3);
  r.x := x3; r.y := y3; r.z := z3; r.inf := FALSE
END AddPoints;

PROCEDURE Bit(VAR a: Num; k: LONGINT): BOOLEAN;
VAR limb, s: LONGINT;
BEGIN
  IF k DIV TLSNum.Bits >= a.len THEN RETURN FALSE END;
  limb := a.d[k DIV TLSNum.Bits]; s := k MOD TLSNum.Bits;
  RETURN ODD(limb DIV ASH(1, s))
END Bit;

(* r := u1 G + u2 q (u1, u2 plain, below n) *)
PROCEDURE Shamir(VAR c: Curve; VAR u1, u2: Num; VAR q, r: Point);
VAR g, gq, acc: Point; k: LONGINT; b1, b2: BOOLEAN;
BEGIN
  g.x := c.gx; g.y := c.gy; TLSNum.MontOne(c.p, g.z); g.inf := FALSE;
  AddPoints(c, g, q, gq);
  acc.inf := TRUE;
  k := c.bytes * 8 - 1;
  WHILE k >= 0 DO
    Double(c, acc, acc);
    b1 := Bit(u1, k); b2 := Bit(u2, k);
    IF b1 & b2 THEN AddPoints(c, acc, gq, acc)
    ELSIF b1 THEN AddPoints(c, acc, g, acc)
    ELSIF b2 THEN AddPoints(c, acc, q, acc)
    END;
    DEC(k)
  END;
  r := acc
END Shamir;

(* x, y (plain, below p) on the curve: y^2 = x^3 - 3x + b *)
PROCEDURE OnCurve(VAR c: Curve; VAR x, y: Num): BOOLEAN;
VAR l, r, t: Num;
BEGIN
  Mul(c, y, y, l);
  Mul(c, x, x, t); Mul(c, t, x, r);
  Mul(c, c.three, x, t); Sub(c, r, t, r); Add(c, r, c.b, r);
  RETURN TLSNum.Compare(l, r) = 0
END OnCurve;

(* v := the big endian bytes b[0..len) as a number below m, FALSE if it is not *)
PROCEDURE Scalar(VAR b: TLSBytes.Buffer; VAR mod: TLSNum.Modulus; maxBytes: LONGINT; VAR v: Num): BOOLEAN;
VAR i: LONGINT;
BEGIN
  i := 0; WHILE (i < b.len) & (b.data[i] = 0X) DO INC(i) END;  (* leading zeros *)
  IF b.len - i > maxBytes THEN RETURN FALSE END;
  TLSNum.FromBytes(b.data, i, b.len - i, mod.m.len, v);
  RETURN TLSNum.Compare(v, mod.m) < 0
END Scalar;

(* q := the point pub (04 x y, uncompressed), FALSE unless it is a point of the curve (not the
   point at infinity; the cofactor is 1, so every such point has order n) *)
PROCEDURE ParsePoint(VAR c: Curve; VAR pub: TLSBytes.Buffer; VAR q: Point): BOOLEAN;
VAR x, y: Num; n: LONGINT;
BEGIN
  n := c.bytes;
  IF (pub.len # 1 + 2 * n) OR (pub.data[0] # 4X) THEN RETURN FALSE END;
  TLSNum.FromBytes(pub.data, 1, n, c.p.m.len, x);
  TLSNum.FromBytes(pub.data, 1 + n, n, c.p.m.len, y);
  IF (TLSNum.Compare(x, c.p.m) >= 0) OR (TLSNum.Compare(y, c.p.m) >= 0) THEN RETURN FALSE END;
  TLSNum.ToMont(x, c.p, q.x); TLSNum.ToMont(y, c.p, q.y);
  TLSNum.MontOne(c.p, q.z); q.inf := FALSE;
  RETURN OnCurve(c, q.x, q.y)
END ParsePoint;

(** the signature (r, s) of the hash by the public key pub (04 x y, uncompressed) on the curve *)
PROCEDURE Verify*(curve: LONGINT; VAR pub, hash, r, s: TLSBytes.Buffer): BOOLEAN;
VAR
  e, rn, sn, w, u1, u2, t, x, zinv, z2: Num; q, res: Point; eb: TLSBytes.Buffer; n: LONGINT;
BEGIN
  IF (curve # P256) & (curve # P384) & (curve # P521) THEN RETURN FALSE END;
  n := curves[curve].bytes;
  IF ~ParsePoint(curves[curve], pub, q) THEN RETURN FALSE END;
  (* 0 < r, s < n *)
  IF ~Scalar(r, curves[curve].n, n, rn) OR ~Scalar(s, curves[curve].n, n, sn) THEN RETURN FALSE END;
  IF TLSNum.IsZero(rn) OR TLSNum.IsZero(sn) THEN RETURN FALSE END;
  (* e: the leftmost bits of the hash, as many as n has (256 or 384: whole bytes) *)
  TLSBytes.Init(eb);
  IF hash.len > n THEN TLSBytes.AppendOpen(eb, hash.data, n) ELSE TLSBytes.Append(eb, hash) END;
  TLSNum.FromBytes(eb.data, 0, eb.len, 0, t);
  TLSNum.ModReduce(t, curves[curve].n, e);
  (* w = 1/s, u1 = e w, u2 = r w (mod n) *)
  TLSNum.ToMont(sn, curves[curve].n, t); TLSNum.MontInvPrime(t, curves[curve].n, w);
  TLSNum.ToMont(e, curves[curve].n, t); TLSNum.MontMul(t, w, curves[curve].n, t); TLSNum.FromMont(t, curves[curve].n, u1);
  TLSNum.ToMont(rn, curves[curve].n, t); TLSNum.MontMul(t, w, curves[curve].n, t); TLSNum.FromMont(t, curves[curve].n, u2);
  Shamir(curves[curve], u1, u2, q, res);
  IF res.inf THEN RETURN FALSE END;
  (* the affine x = X / Z^2, mod n, must be r *)
  TLSNum.MontInvPrime(res.z, curves[curve].p, zinv);
  Mul(curves[curve], zinv, zinv, z2); Mul(curves[curve], res.x, z2, t);
  TLSNum.FromMont(t, curves[curve].p, x);
  TLSNum.ModReduce(x, curves[curve].n, t);
  RETURN TLSNum.Compare(t, rn) = 0
END Verify;

(** r and s of a DER signature: SEQUENCE { INTEGER r, INTEGER s } *)
PROCEDURE ParseSignature*(VAR der: TLSBytes.Buffer; VAR r, s: TLSBytes.Buffer): BOOLEAN;
VAR pos, len: LONGINT;

  PROCEDURE Length(VAR len: LONGINT): BOOLEAN;
  VAR k: LONGINT;
  BEGIN
    IF pos >= der.len THEN RETURN FALSE END;
    len := ORD(der.data[pos]); INC(pos);
    IF len >= 128 THEN
      k := len - 128; len := 0;
      IF (k < 1) OR (k > 2) OR (pos + k > der.len) THEN RETURN FALSE END;
      WHILE k > 0 DO len := len * 256 + ORD(der.data[pos]); INC(pos); DEC(k) END
    END;
    RETURN pos + len <= der.len
  END Length;

  PROCEDURE Integer(VAR v: TLSBytes.Buffer): BOOLEAN;
  VAR l: LONGINT;
  BEGIN
    IF (pos >= der.len) OR (der.data[pos] # 2X) THEN RETURN FALSE END;
    INC(pos);
    IF ~Length(l) OR (l < 1) THEN RETURN FALSE END;
    TLSBytes.Slice(der, pos, l, v); INC(pos, l);
    RETURN TRUE
  END Integer;

BEGIN
  pos := 0;
  IF (der.len < 8) OR (der.data[0] # 30X) THEN RETURN FALSE END;
  pos := 1;
  IF ~Length(len) OR (pos + len # der.len) THEN RETURN FALSE END;
  RETURN Integer(r) & Integer(s) & (pos = der.len)
END ParseSignature;

(* ----- ECDH ----- *)

(* a, b := b, a if bit = 1 (0: unchanged), by arithmetic on the limbs; a.len = b.len *)
PROCEDURE SwapNum(VAR a, b: Num; bit: LONGINT);
VAR i, t: LONGINT;
BEGIN
  i := 0;
  WHILE i < a.len DO
    t := (b.d[i] - a.d[i]) * bit; a.d[i] := a.d[i] + t; b.d[i] := b.d[i] - t; INC(i)
  END
END SwapNum;

PROCEDURE Swap(VAR p, q: Point; bit: LONGINT);
VAR a, b, t: LONGINT;
BEGIN
  SwapNum(p.x, q.x, bit); SwapNum(p.y, q.y, bit); SwapNum(p.z, q.z, bit);
  a := 0; IF p.inf THEN a := 1 END;
  b := 0; IF q.inf THEN b := 1 END;
  t := (b - a) * bit; a := a + t; b := b - t;
  p.inf := a = 1; q.inf := b = 1
END Swap;

(* r := k q, k plain below n: a Montgomery ladder over all the bits of the curve size *)
PROCEDURE Ladder(VAR c: Curve; VAR k: Num; VAR q, r: Point);
VAR r0, r1: Point; i, bit, limb: LONGINT;
BEGIN
  TLSNum.MontOne(c.p, r0.x); r0.y := r0.x; r0.z := r0.x; r0.inf := TRUE;
  r1 := q;
  i := c.bytes * 8 - 1;
  WHILE i >= 0 DO
    limb := 0; IF i DIV TLSNum.Bits < k.len THEN limb := k.d[i DIV TLSNum.Bits] END;
    bit := limb DIV ASH(1, i MOD TLSNum.Bits) MOD 2;
    Swap(r0, r1, bit);
    AddPoints(c, r0, r1, r1); Double(c, r0, r0);  (* r1 - r0 = q stays *)
    Swap(r0, r1, bit);
    DEC(i)
  END;
  r := r0;
  TLSNum.SetZero(r1.x, r1.x.len); TLSNum.SetZero(r1.y, r1.y.len); TLSNum.SetZero(r1.z, r1.z.len)
END Ladder;

(* the affine x (and y) of p, n bytes each, big endian *)
PROCEDURE Affine(VAR c: Curve; VAR p: Point; VAR x, y: TLSBytes.Buffer);
VAR zinv, z2, z3, t, u: Num;
BEGIN
  TLSNum.MontInvPrime(p.z, c.p, zinv);
  Mul(c, zinv, zinv, z2); Mul(c, z2, zinv, z3);
  Mul(c, p.x, z2, t); TLSNum.FromMont(t, c.p, u); TLSNum.ToBytes(u, c.bytes, x);
  Mul(c, p.y, z3, t); TLSNum.FromMont(t, c.p, u); TLSNum.ToBytes(u, c.bytes, y)
END Affine;

(* k := priv (the curve size in bytes, big endian), FALSE unless 0 < k < n *)
PROCEDURE PrivateScalar(VAR c: Curve; VAR priv: TLSBytes.Buffer; VAR k: Num): BOOLEAN;
BEGIN
  IF priv.len # c.bytes THEN RETURN FALSE END;
  TLSNum.FromBytes(priv.data, 0, priv.len, c.n.m.len, k);
  RETURN ~TLSNum.IsZero(k) & (TLSNum.Compare(k, c.n.m) < 0)
END PrivateScalar;

(** pub := 04 x y of priv G; FALSE if priv (random bytes, the curve size) is not a scalar in
  [1, n-1]: then the caller takes new random bytes *)
PROCEDURE ECDHPublic*(curve: LONGINT; VAR priv, pub: TLSBytes.Buffer): BOOLEAN;
VAR k: Num; g, r: Point; x, y: TLSBytes.Buffer;
BEGIN
  IF (curve # P256) & (curve # P384) & (curve # P521) THEN RETURN FALSE END;
  IF ~PrivateScalar(curves[curve], priv, k) THEN RETURN FALSE END;
  g.x := curves[curve].gx; g.y := curves[curve].gy; TLSNum.MontOne(curves[curve].p, g.z); g.inf := FALSE;
  Ladder(curves[curve], k, g, r);
  TLSNum.SetZero(k, k.len);
  IF r.inf THEN RETURN FALSE END;
  Affine(curves[curve], r, x, y);
  TLSBytes.Init(pub); TLSBytes.AppendByte(pub, 4); TLSBytes.Append(pub, x); TLSBytes.Append(pub, y);
  RETURN TRUE
END ECDHPublic;

(** shared := the x coordinate of priv times the point peer (04 x y), FALSE if peer is not a
  point of the curve *)
PROCEDURE ECDH*(curve: LONGINT; VAR priv, peer, shared: TLSBytes.Buffer): BOOLEAN;
VAR k: Num; q, r: Point; y: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(shared);
  IF (curve # P256) & (curve # P384) & (curve # P521) THEN RETURN FALSE END;
  IF ~ParsePoint(curves[curve], peer, q) OR ~PrivateScalar(curves[curve], priv, k) THEN RETURN FALSE END;
  Ladder(curves[curve], k, q, r);
  TLSNum.SetZero(k, k.len);
  IF r.inf THEN RETURN FALSE END;
  Affine(curves[curve], r, shared, y);
  RETURN TRUE
END ECDH;

(* ----- signatures ----- *)

(* mac := HMAC-SHA-256 with key of v, then the byte sep (none if sep < 0), then x and h *)
PROCEDURE Mac(VAR key, v: TLSBytes.Buffer; sep: LONGINT; VAR x, h, mac: TLSBytes.Buffer);
VAR m: TLSBytes.Buffer; d: TLSSHA256.Digest;
BEGIN
  TLSBytes.Copy(v, m);
  IF sep >= 0 THEN TLSBytes.AppendByte(m, sep); TLSBytes.Append(m, x); TLSBytes.Append(m, h) END;
  TLSSHA256.HMAC(key, m, d); TLSSHA256.DigestToBuffer(d, mac);
  TLSBytes.SetLen(m, 0)
END Mac;

(** r and s (32 bytes each) of the ECDSA signature of hash (32 bytes, SHA-256) with the private
  key priv (32 bytes) on P-256, k by RFC 6979; FALSE if priv is not a key of the curve *)
PROCEDURE Sign*(curve: LONGINT; VAR priv, hash, r, s: TLSBytes.Buffer): BOOLEAN;
VAR
  d, e, k, t, u, rn, sn, kinv: Num; g, p: Point;
  x, y, h1, key, v, none: TLSBytes.Buffer; i: LONGINT; done: BOOLEAN;
BEGIN
  TLSBytes.Init(r); TLSBytes.Init(s);
  IF (curve # P256) OR (hash.len # 32) THEN RETURN FALSE END;
  IF ~PrivateScalar(curves[curve], priv, d) THEN RETURN FALSE END;
  (* e = the hash as a number mod n, also bits2octets of RFC 6979 *)
  TLSNum.FromBytes(hash.data, 0, 32, 0, t); TLSNum.ModReduce(t, curves[curve].n, e);
  TLSNum.ToBytes(e, 32, h1);
  (* RFC 6979 3.2 b to f *)
  TLSBytes.Init(v); TLSBytes.Init(key); i := 0;
  WHILE i < 32 DO TLSBytes.AppendByte(v, 1); TLSBytes.AppendByte(key, 0); INC(i) END;
  Mac(key, v, 0, priv, h1, key); Mac(key, v, -1, priv, h1, v);
  Mac(key, v, 1, priv, h1, key); Mac(key, v, -1, priv, h1, v);
  g.x := curves[curve].gx; g.y := curves[curve].gy; TLSNum.MontOne(curves[curve].p, g.z); g.inf := FALSE;
  done := FALSE;
  REPEAT
    Mac(key, v, -1, priv, h1, v);  (* h: the candidate k *)
    TLSNum.FromBytes(v.data, 0, 32, curves[curve].n.m.len, k);
    IF ~TLSNum.IsZero(k) & (TLSNum.Compare(k, curves[curve].n.m) < 0) THEN
      Ladder(curves[curve], k, g, p);
      IF ~p.inf THEN
        Affine(curves[curve], p, x, y);
        TLSNum.FromBytes(x.data, 0, 32, 0, t); TLSNum.ModReduce(t, curves[curve].n, rn);
        IF ~TLSNum.IsZero(rn) THEN
          (* s = (e + r d) / k mod n, in Montgomery form *)
          TLSNum.ToMont(k, curves[curve].n, t); TLSNum.MontInvPrime(t, curves[curve].n, kinv);
          TLSNum.ToMont(rn, curves[curve].n, t); TLSNum.ToMont(d, curves[curve].n, u);
          TLSNum.MontMul(t, u, curves[curve].n, t);
          TLSNum.ToMont(e, curves[curve].n, u); TLSNum.ModAdd(t, u, curves[curve].n, t);
          TLSNum.MontMul(t, kinv, curves[curve].n, t); TLSNum.FromMont(t, curves[curve].n, sn);
          done := ~TLSNum.IsZero(sn)
        END
      END
    END;
    IF ~done THEN TLSBytes.Init(none); Mac(key, v, 0, none, none, key); Mac(key, v, -1, none, none, v) END
  UNTIL done;
  TLSNum.ToBytes(rn, 32, r); TLSNum.ToBytes(sn, 32, s);
  TLSNum.SetZero(d, d.len); TLSNum.SetZero(k, k.len); TLSNum.SetZero(kinv, kinv.len); TLSNum.SetZero(u, u.len);
  i := 0; WHILE i < 32 DO key.data[i] := 0X; v.data[i] := 0X; INC(i) END;
  RETURN TRUE
END Sign;

(* the DER INTEGER of the unsigned big endian v *)
PROCEDURE DerInteger(VAR v, der: TLSBytes.Buffer);
VAR i: LONGINT;
BEGIN
  i := 0; WHILE (i < v.len - 1) & (v.data[i] = 0X) DO INC(i) END;
  TLSBytes.AppendByte(der, 2);
  IF ORD(v.data[i]) >= 128 THEN
    TLSBytes.AppendByte(der, v.len - i + 1); TLSBytes.AppendByte(der, 0)
  ELSE TLSBytes.AppendByte(der, v.len - i)
  END;
  WHILE i < v.len DO TLSBytes.AppendByte(der, ORD(v.data[i])); INC(i) END
END DerInteger;

(** der := SEQUENCE { INTEGER r, INTEGER s }, the signature as TLS sends it (r, s < 2^256) *)
PROCEDURE SignatureDER*(VAR r, s, der: TLSBytes.Buffer);
VAR body: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(body); DerInteger(r, body); DerInteger(s, body);
  TLSBytes.Init(der); TLSBytes.AppendByte(der, 30H); TLSBytes.AppendByte(der, body.len); TLSBytes.Append(der, body)
END SignatureDER;

BEGIN
  InitCurve(curves[P256], 32,
    "ffffffff000000010000000000000000", "00000000ffffffffffffffffffffffff",
    "ffffffff00000000ffffffffffffffff", "bce6faada7179e84f3b9cac2fc632551",
    "5ac635d8aa3a93e7b3ebbd55769886bc", "651d06b0cc53b0f63bce3c3e27d2604b",
    "6b17d1f2e12c4247f8bce6e563a440f2", "77037d812deb33a0f4a13945d898c296",
    "4fe342e2fe1a7f9b8ee7eb4a7c0f9e16", "2bce33576b315ececbb6406837bf51f5");
  InitCurve(curves[P384], 48,
    "ffffffffffffffffffffffffffffffffffffffffffffffff", "fffffffffffffffeffffffff0000000000000000ffffffff",
    "ffffffffffffffffffffffffffffffffffffffffffffffff", "c7634d81f4372ddf581a0db248b0a77aecec196accc52973",
    "b3312fa7e23ee7e4988e056be3f82d19181d9c6efe814112", "0314088f5013875ac656398d8a2ed19d2a85c8edd3ec2aef",
    "aa87ca22be8b05378eb1c71ef320ad746e1d3b628ba79b98", "59f741e082542a385502f25dbf55296c3a545e3872760ab7",
    "3617de4a96262c6f5d9e98bf9292dc29f8f41dbd289a147c", "e9da3113b5f0b8c00a60b1ce1d7e819d7a431d7c90ea0e5f");
  InitCurve(curves[P521], 66,
    "01ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
    "01ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", "fa51868783bf2f966b7fcc0148f709a5d03bb5c9b8899c47aebb6fb71e91386409",
    "0051953eb9618e1c9a1f929a21a0b68540eea2da725b99b315f3b8b489918ef109", "e156193951ec7e937b1652c0bd3bb1bf073573df883d2c34f1ef451fd46b503f00",
    "00c6858e06b70404e9cd9e3ecb662395b4429c648139053fb521f828af606b4d3d", "baa14b5e77efe75928fe1dc127a2ffa8de3348b3c1856a429bf97e7e31c2e5bd66",
    "011839296a789a3bc0045c8a5fb42c7d1bd998f54449579b446817afbd17273e66", "2c97ee72995ef42640c550b9013fad0761353c7086a272c24088be94769fd16650");
END TLSECDSA.
