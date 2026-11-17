MODULE TLSEd25519;

(* SPDX-License-Identifier: LGPL-3.0-or-later *)
(* Ed25519 (RFC 8032, pure mode). Field arithmetic follows the public-domain
   NaCl/TweetNaCl formulas, using 32 radix-256 limbs and bounded LONGINT sums.
   Verification requires canonical encodings and nonidentity prime-order points.
   Secret scalar multiplication has fixed loop bounds and no secret-indexed tables;
   generated machine-code timing and erasure have not been independently audited. *)

IMPORT TLSBytes, TLSSHA512;

CONST seedBytes* = 32; publicKeyBytes* = 32; signatureBytes* = 64;

TYPE
  Bytes32 = ARRAY 32 OF CHAR;
  Bytes64 = ARRAY 64 OF CHAR;
  Field = ARRAY 32 OF LONGINT;
  Point = RECORD x, y, z, t: Field END;

VAR
  zero, one, d, twiceD, sqrtMinusOne: Field;
  base: Point;
  inverseExponent, rootExponent, order: Bytes32;

PROCEDURE Add(VAR out, a, b: Field);
VAR i, carry: LONGINT;
BEGIN
  carry := 0; i := 0;
  WHILE i < 31 DO carry := carry+a[i]+b[i]; out[i] := carry MOD 256; carry := carry DIV 256; INC(i) END;
  out[31] := carry+a[31]+b[31]
END Add;

PROCEDURE Sub(VAR out, a, b: Field);
VAR i, carry: LONGINT;
BEGIN
  carry := 218; i := 0;
  WHILE i < 31 DO carry := carry+a[i]+65280-b[i]; out[i] := carry MOD 256; carry := carry DIV 256; INC(i) END;
  out[31] := carry+a[31]-b[31]
END Sub;

PROCEDURE Squeeze(VAR a: Field);
VAR i, carry: LONGINT;
BEGIN
  carry := 0; i := 0;
  WHILE i < 31 DO carry := carry+a[i]; a[i] := carry MOD 256; carry := carry DIV 256; INC(i) END;
  carry := carry+a[31]; a[31] := carry MOD 128;
  carry := 19*(carry DIV 128); i := 0;
  WHILE i < 31 DO carry := carry+a[i]; a[i] := carry MOD 256; carry := carry DIV 256; INC(i) END;
  INC(a[31], carry)
END Squeeze;

PROCEDURE Mul(VAR out, a, b: Field);
VAR result: Field; i, j, sum: LONGINT;
BEGIN
  i := 0;
  WHILE i < 32 DO
    sum := 0; j := 0;
    WHILE j <= i DO INC(sum, a[j]*b[i-j]); INC(j) END;
    j := i+1;
    WHILE j < 32 DO INC(sum, 38*a[j]*b[i+32-j]); INC(j) END;
    result[i] := sum; INC(i)
  END;
  Squeeze(result); out := result
END Mul;

PROCEDURE PackField(VAR a: Field; VAR bytes: Bytes32);
VAR value, saved, delta: Field; i, mask: LONGINT;
BEGIN
  value := a; Squeeze(value); Squeeze(value); saved := value;
  delta := zero; delta[0] := 19; delta[31] := 128; Add(value, value, delta);
  mask := -((value[31] DIV 128) MOD 2); i := 0;
  WHILE i < 32 DO
    bytes[i] := CHR(TLSBytes.Xor32(value[i], TLSBytes.And32(mask, TLSBytes.Xor32(saved[i], value[i]))) MOD 256);
    INC(i)
  END
END PackField;

PROCEDURE EqualBytes(VAR a, b: ARRAY OF CHAR; count: LONGINT): BOOLEAN;
VAR i, difference: LONGINT;
BEGIN
  difference := 0; i := 0;
  WHILE i < count DO INC(difference, TLSBytes.XorByte(ORD(a[i]), ORD(b[i]))); INC(i) END;
  RETURN difference = 0
END EqualBytes;

PROCEDURE EqualField(VAR a, b: Field): BOOLEAN;
VAR left, right: Bytes32;
BEGIN PackField(a, left); PackField(b, right); RETURN EqualBytes(left, right, 32)
END EqualField;

(* Exponents are fixed public constants. *)
PROCEDURE Power(VAR out, a: Field; VAR exponent: Bytes32);
VAR result: Field; bit: LONGINT;
BEGIN
  result := one; bit := 254;
  WHILE bit >= 0 DO
    Mul(result, result, result);
    IF ODD(ORD(exponent[bit DIV 8]) DIV ASH(1, bit MOD 8)) THEN Mul(result, result, a) END;
    DEC(bit)
  END;
  out := result
END Power;

PROCEDURE Identity(VAR p: Point);
BEGIN p.x := zero; p.y := one; p.z := one; p.t := zero END Identity;

(* Complete extended Edwards addition; inputs may alias the output. *)
PROCEDURE AddPoint(VAR out, p, q: Point);
VAR a, b, c, dd, e, f, g, h: Field;
BEGIN
  Sub(a, p.y, p.x); Sub(b, q.y, q.x); Mul(a, a, b);
  Add(b, p.y, p.x); Add(c, q.y, q.x); Mul(b, b, c);
  Mul(c, p.t, q.t); Mul(c, c, twiceD);
  Mul(dd, p.z, q.z); Add(dd, dd, dd);
  Sub(e, b, a); Sub(f, dd, c); Add(g, dd, c); Add(h, b, a);
  Mul(out.x, e, f); Mul(out.y, h, g); Mul(out.z, g, f); Mul(out.t, e, h)
END AddPoint;

PROCEDURE SwapField(VAR a, b: Field; bit: LONGINT);
VAR i, delta: LONGINT;
BEGIN
  i := 0;
  WHILE i < 32 DO delta := bit*(b[i]-a[i]); INC(a[i], delta); DEC(b[i], delta); INC(i) END
END SwapField;

PROCEDURE SwapPoint(VAR a, b: Point; bit: LONGINT);
BEGIN SwapField(a.x, b.x, bit); SwapField(a.y, b.y, bit); SwapField(a.z, b.z, bit); SwapField(a.t, b.t, bit)
END SwapPoint;

PROCEDURE Multiply(VAR out, p: Point; VAR scalar: ARRAY OF CHAR);
VAR result, other: Point; i, bit: LONGINT;
BEGIN
  Identity(result); other := p; i := 255;
  WHILE i >= 0 DO
    bit := ORD(scalar[i DIV 8]) DIV ASH(1, i MOD 8) MOD 2;
    SwapPoint(result, other, bit);
    AddPoint(other, other, result); AddPoint(result, result, result);
    SwapPoint(result, other, bit); DEC(i)
  END;
  out := result; Identity(result); Identity(other)
END Multiply;

PROCEDURE PackPoint(VAR p: Point; VAR bytes: Bytes32);
VAR inverse, x, y: Field; xBytes: Bytes32;
BEGIN
  Power(inverse, p.z, inverseExponent); Mul(x, p.x, inverse); Mul(y, p.y, inverse);
  PackField(y, bytes); PackField(x, xBytes);
  bytes[31] := CHR(ORD(bytes[31])+128*(ORD(xBytes[0]) MOD 2))
END PackPoint;

PROCEDURE UnpackPoint(VAR bytes: ARRAY OF CHAR; VAR p: Point): BOOLEAN;
VAR yBytes, xBytes, canonical: Bytes32; u, v, inverse, square, check: Field; i, sign: LONGINT;
BEGIN
  i := 0; WHILE i < 32 DO yBytes[i] := bytes[i]; p.y[i] := ORD(bytes[i]); INC(i) END;
  sign := ORD(yBytes[31]) DIV 128; yBytes[31] := CHR(ORD(yBytes[31]) MOD 128); p.y[31] := p.y[31] MOD 128;
  PackField(p.y, canonical); IF ~EqualBytes(yBytes, canonical, 32) THEN RETURN FALSE END;
  Mul(u, p.y, p.y); Mul(v, d, u); Sub(u, u, one); Add(v, v, one);
  Power(inverse, v, inverseExponent); Mul(square, u, inverse);
  Power(p.x, square, rootExponent); Mul(check, p.x, p.x);
  IF ~EqualField(check, square) THEN Mul(p.x, p.x, sqrtMinusOne); Mul(check, p.x, p.x) END;
  IF ~EqualField(check, square) THEN RETURN FALSE END;
  PackField(p.x, xBytes);
  IF EqualField(p.x, zero) & (sign # 0) THEN RETURN FALSE END;
  IF ORD(xBytes[0]) MOD 2 # sign THEN Sub(p.x, zero, p.x) END;
  p.z := one; Mul(p.t, p.x, p.y); RETURN TRUE
END UnpackPoint;

PROCEDURE IsIdentity(VAR p: Point): BOOLEAN;
BEGIN RETURN EqualField(p.x, zero) & EqualField(p.y, p.z)
END IsIdentity;

PROCEDURE PrimeOrder(VAR p: Point): BOOLEAN;
VAR multiplied: Point;
BEGIN
  IF IsIdentity(p) THEN RETURN FALSE END;
  Multiply(multiplied, p, order); RETURN IsIdentity(multiplied)
END PrimeOrder;

PROCEDURE LessThanOrder(VAR scalar: ARRAY OF CHAR): BOOLEAN;
VAR i, value, borrow: LONGINT;
BEGIN
  borrow := 0; i := 0;
  WHILE i < 32 DO value := ORD(scalar[i])-ORD(order[i])-borrow; borrow := -(value DIV 256); INC(i) END;
  RETURN borrow = 1
END LessThanOrder;

(* Fixed-width binary division modulo the group order. Intermediate limbs stay
   in [-256,511]; no wide multiplication or secret-dependent loop bounds. *)
PROCEDURE Reduce(VAR input: Bytes64; VAR scalar: Bytes32);
VAR remainder, difference: Field; i, j, carry, value, borrow, take: LONGINT;
BEGIN
  remainder := zero; i := 511;
  WHILE i >= 0 DO
    carry := ORD(input[i DIV 8]) DIV ASH(1, i MOD 8) MOD 2; j := 0;
    WHILE j < 32 DO value := remainder[j]*2+carry; remainder[j] := value MOD 256; carry := value DIV 256; INC(j) END;
    borrow := 0; j := 0;
    WHILE j < 32 DO
      value := remainder[j]-ORD(order[j])-borrow; difference[j] := value MOD 256;
      borrow := -(value DIV 256); INC(j)
    END;
    take := 1-borrow; j := 0;
    WHILE j < 32 DO INC(remainder[j], take*(difference[j]-remainder[j])); INC(j) END;
    DEC(i)
  END;
  j := 0; WHILE j < 32 DO scalar[j] := CHR(remainder[j]); INC(j) END
END Reduce;

PROCEDURE HashSeed(VAR seed: ARRAY OF CHAR; VAR expanded: Bytes64): BOOLEAN;
VAR context: TLSSHA512.Context;
BEGIN
  TLSSHA512.Init512(context);
  IF ~TLSSHA512.Update(context, seed, 0, 32) OR ~TLSSHA512.Final512(context, expanded) THEN RETURN FALSE END;
  expanded[0] := CHR(ORD(expanded[0]) DIV 8*8);
  expanded[31] := CHR(ORD(expanded[31]) MOD 64+64);
  RETURN TRUE
END HashSeed;

PROCEDURE Wipe(VAR bytes: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN i := 0; WHILE i < LEN(bytes) DO bytes[i] := 0X; INC(i) END END Wipe;

(** Derives 32 public-key bytes from an exactly 32-byte seed. Outputs are only
    written on success; input arrays are read-only unless aliased with output. *)
PROCEDURE PublicKey*(VAR seed, publicKey: ARRAY OF CHAR): BOOLEAN;
VAR expanded: Bytes64; encoded: Bytes32; p: Point; i: LONGINT;
BEGIN
  IF (LEN(seed) # seedBytes) OR (LEN(publicKey) < publicKeyBytes) THEN RETURN FALSE END;
  IF ~HashSeed(seed, expanded) THEN RETURN FALSE END;
  Multiply(p, base, expanded); PackPoint(p, encoded); Wipe(expanded); Identity(p);
  i := 0; WHILE i < 32 DO publicKey[i] := encoded[i]; INC(i) END;
  RETURN TRUE
END PublicKey;

(** Signs message[offset..offset+count) in pure Ed25519 mode. The seed has
    exactly 32 bytes; signature has room for 64. No message-sized allocation. *)
PROCEDURE Sign*(VAR seed, message: ARRAY OF CHAR; offset, count: LONGINT; VAR signature: ARRAY OF CHAR): BOOLEAN;
VAR expanded, digest, product: Bytes64; publicKey, nonce, challenge, encodedR, s: Bytes32;
  context: TLSSHA512.Context; p: Point; accum: ARRAY 64 OF LONGINT; i, j, carry: LONGINT; okay: BOOLEAN;
BEGIN
  IF (LEN(seed) # seedBytes) OR (LEN(signature) < signatureBytes) OR
     (offset < 0) OR (offset > LEN(message)) OR (count < 0) OR (count > LEN(message)-offset) THEN RETURN FALSE END;
  IF ~HashSeed(seed, expanded) THEN RETURN FALSE END;
  Multiply(p, base, expanded); PackPoint(p, publicKey);
  TLSSHA512.Init512(context);
  okay := TLSSHA512.Update(context, expanded, 32, 32) & TLSSHA512.Update(context, message, offset, count) &
    TLSSHA512.Final512(context, digest);
  IF okay THEN
    Reduce(digest, nonce); Multiply(p, base, nonce); PackPoint(p, encodedR);
    TLSSHA512.Init512(context);
    okay := TLSSHA512.Update(context, encodedR, 0, 32) & TLSSHA512.Update(context, publicKey, 0, 32) &
      TLSSHA512.Update(context, message, offset, count) & TLSSHA512.Final512(context, digest)
  END;
  IF okay THEN
    Reduce(digest, challenge); i := 0;
    WHILE i < 64 DO accum[i] := 0; INC(i) END;
    i := 0;
    WHILE i < 32 DO
      accum[i] := accum[i]+ORD(nonce[i]); j := 0;
      WHILE j < 32 DO INC(accum[i+j], LONG(ORD(challenge[i]))*LONG(ORD(expanded[j]))); INC(j) END;
      INC(i)
    END;
    carry := 0; i := 0;
    WHILE i < 64 DO INC(carry, accum[i]); product[i] := CHR(carry MOD 256); carry := carry DIV 256; accum[i] := 0; INC(i) END;
    Reduce(product, s); i := 0;
    WHILE i < 32 DO signature[i] := encodedR[i]; signature[32+i] := s[i]; INC(i) END
  END;
  Wipe(expanded); Wipe(digest); Wipe(product); Wipe(nonce); Wipe(s); Identity(p);
  RETURN okay
END Sign;

(** Verifies a 64-byte signature with an exactly 32-byte public key. Canonical
    A, R and S are required, with A and R nonidentity points of the prime subgroup. *)
PROCEDURE Verify*(VAR publicKey, message: ARRAY OF CHAR; offset, count: LONGINT; VAR signature: ARRAY OF CHAR): BOOLEAN;
VAR a, r, left, right: Point; encodedR, encodedLeft, encodedRight, s, challenge: Bytes32;
  digest: Bytes64; context: TLSSHA512.Context; i: LONGINT;
BEGIN
  IF (LEN(publicKey) # publicKeyBytes) OR (LEN(signature) # signatureBytes) OR
     (offset < 0) OR (offset > LEN(message)) OR (count < 0) OR (count > LEN(message)-offset) THEN RETURN FALSE END;
  i := 0; WHILE i < 32 DO encodedR[i] := signature[i]; s[i] := signature[32+i]; INC(i) END;
  IF ~LessThanOrder(s) OR ~UnpackPoint(publicKey, a) OR ~UnpackPoint(encodedR, r) THEN RETURN FALSE END;
  IF ~PrimeOrder(a) OR ~PrimeOrder(r) THEN RETURN FALSE END;
  TLSSHA512.Init512(context);
  IF ~TLSSHA512.Update(context, encodedR, 0, 32) OR ~TLSSHA512.Update(context, publicKey, 0, 32) OR
     ~TLSSHA512.Update(context, message, offset, count) OR ~TLSSHA512.Final512(context, digest) THEN RETURN FALSE END;
  Reduce(digest, challenge); Multiply(left, base, s); Multiply(right, a, challenge); AddPoint(right, right, r);
  PackPoint(left, encodedLeft); PackPoint(right, encodedRight);
  RETURN EqualBytes(encodedLeft, encodedRight, 32)
END Verify;

PROCEDURE Hex(ch: CHAR): LONGINT;
BEGIN
  IF ch <= "9" THEN RETURN ORD(ch)-ORD("0") END;
  RETURN ORD(ch)-ORD("a")+10
END Hex;

PROCEDURE ReadHex(text: ARRAY OF CHAR; VAR bytes: Bytes32);
VAR i: LONGINT;
BEGIN i := 0; WHILE i < 32 DO bytes[i] := CHR(Hex(text[i*2])*16+Hex(text[i*2+1])); INC(i) END END ReadHex;

PROCEDURE ReadField(text: ARRAY OF CHAR; VAR field: Field);
VAR bytes: Bytes32; i: LONGINT;
BEGIN ReadHex(text, bytes); i := 0; WHILE i < 32 DO field[i] := ORD(bytes[i]); INC(i) END END ReadField;

BEGIN
  zero[0] := 0; one := zero; one[0] := 1;
  ReadHex("ebffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f", inverseExponent);
  ReadHex("feffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0f", rootExponent);
  ReadHex("edd3f55c1a631258d69cf7a2def9de1400000000000000000000000000000010", order);
  ReadField("a3785913ca4deb75abd841414d0a700098e879777940c78c73fe6f2bee6c0352", d);
  ReadField("59f1b226949bd6eb56b183829a14e00030d1f3eef2808e19e7fcdf56dcd90624", twiceD);
  ReadField("b0a00e4a271beec478e42fad0618432fa7d7fb3d99004d2b0bdfc14f8024832b", sqrtMinusOne);
  ReadField("1ad5258f602d56c9b2a7259560c72c695cdcd6fd31e2a4c0fe536ecdd3366921", base.x);
  ReadField("5866666666666666666666666666666666666666666666666666666666666666", base.y);
  base.z := one; Mul(base.t, base.x, base.y)
END TLSEd25519.
