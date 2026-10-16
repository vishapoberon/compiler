MODULE TLSX25519;
(* X25519 (RFC 7748), after the reference implementation of curve25519 in NaCl
   (D. J. Bernstein, crypto_scalarmult/curve25519/ref, public domain): field elements in
   32 limbs of 8 bits. Every intermediate value stays below 2^27, so signed 32 bit LONGINT
   is enough (the same file serves voc and polpo, whose compilers have no HUGEINT). *)
IMPORT TLSBytes;

TYPE
  GF* = ARRAY 32 OF LONGINT;  (** limb i holds bits 8i..8i+7, carries pending *)

(* out := a + b, with the carries, the top limb unreduced *)
PROCEDURE Add(VAR out, a, b: GF);
VAR j, u: LONGINT;
BEGIN
  u := 0; j := 0;
  WHILE j < 31 DO u := u + a[j] + b[j]; out[j] := u MOD 256; u := u DIV 256; INC(j) END;
  out[31] := u + a[31] + b[31]
END Add;

(* out := a - b + 2p, which keeps every limb positive *)
PROCEDURE Sub(VAR out, a, b: GF);
VAR j, u: LONGINT;
BEGIN
  u := 218; j := 0;
  WHILE j < 31 DO u := u + a[j] + 65280 - b[j]; out[j] := u MOD 256; u := u DIV 256; INC(j) END;
  out[31] := u + a[31] - b[31]
END Sub;

(* carries, and 2^255 = 19 (mod p) *)
PROCEDURE Squeeze(VAR a: GF);
VAR j, u: LONGINT;
BEGIN
  u := 0; j := 0;
  WHILE j < 31 DO u := u + a[j]; a[j] := u MOD 256; u := u DIV 256; INC(j) END;
  u := u + a[31]; a[31] := u MOD 128;
  u := 19 * (u DIV 128); j := 0;
  WHILE j < 31 DO u := u + a[j]; a[j] := u MOD 256; u := u DIV 256; INC(j) END;
  a[31] := u + a[31]
END Squeeze;

(* the canonical value, below p *)
PROCEDURE Freeze(VAR a: GF);
VAR orig, minusp: GF; j, negative: LONGINT;
BEGIN
  j := 0; WHILE j < 32 DO orig[j] := a[j]; minusp[j] := 0; INC(j) END;
  minusp[0] := 19; minusp[31] := 128;
  Add(a, a, minusp);
  negative := -((a[31] DIV 128) MOD 2);  (* all ones if a - p was negative *)
  j := 0;
  WHILE j < 32 DO
    a[j] := TLSBytes.Xor32(a[j], TLSBytes.And32(negative, TLSBytes.Xor32(orig[j], a[j]))); INC(j)
  END
END Freeze;

PROCEDURE Mult(VAR out, a, b: GF);
VAR i, j, u: LONGINT;
BEGIN
  i := 0;
  WHILE i < 32 DO
    u := 0;
    j := 0; WHILE j <= i DO u := u + a[j] * b[i - j]; INC(j) END;
    j := i + 1; WHILE j < 32 DO u := u + 38 * a[j] * b[i + 32 - j]; INC(j) END;
    out[i] := u; INC(i)
  END;
  Squeeze(out)
END Mult;

PROCEDURE Mult121665(VAR out, a: GF);
VAR j, u: LONGINT;
BEGIN
  u := 0; j := 0;
  WHILE j < 31 DO u := u + 121665 * a[j]; out[j] := u MOD 256; u := u DIV 256; INC(j) END;
  u := u + 121665 * a[31]; out[31] := u MOD 128;
  u := 19 * (u DIV 128); j := 0;
  WHILE j < 31 DO u := u + out[j]; out[j] := u MOD 256; u := u DIV 256; INC(j) END;
  out[31] := u + out[31]
END Mult121665;

PROCEDURE Square(VAR out, a: GF);
VAR i, j, u: LONGINT;
BEGIN
  i := 0;
  WHILE i < 32 DO
    u := 0;
    j := 0; WHILE j < i - j DO u := u + a[j] * a[i - j]; INC(j) END;
    j := i + 1; WHILE j < i + 32 - j DO u := u + 38 * a[j] * a[i + 32 - j]; INC(j) END;
    u := u * 2;
    IF ~ODD(i) THEN
      u := u + a[i DIV 2] * a[i DIV 2];
      u := u + 38 * a[i DIV 2 + 16] * a[i DIV 2 + 16]
    END;
    out[i] := u; INC(i)
  END;
  Squeeze(out)
END Square;

(* b = 1: p := s, q := r; b = 0: p := r, q := s *)
PROCEDURE Select(VAR p, q, r, s: GF; b: LONGINT);
VAR j, t, bminus1: LONGINT;
BEGIN
  bminus1 := b - 1; j := 0;
  WHILE j < 32 DO
    t := TLSBytes.And32(bminus1, TLSBytes.Xor32(r[j], s[j]));
    p[j] := TLSBytes.Xor32(s[j], t); q[j] := TLSBytes.Xor32(r[j], t); INC(j)
  END
END Select;

(* out := z^(p-2) = 1/z *)
PROCEDURE Recip(VAR out, z: GF);
VAR z2, z9, z11, z2p5, z2p10, z2p20, z2p50, z2p100, t0, t1: GF; i: LONGINT;
BEGIN
  Square(z2, z);                         (* 2 *)
  Square(t1, z2);                        (* 4 *)
  Square(t0, t1);                        (* 8 *)
  Mult(z9, t0, z);                       (* 9 *)
  Mult(z11, z9, z2);                     (* 11 *)
  Square(t0, z11);                       (* 22 *)
  Mult(z2p5, t0, z9);                    (* 2^5 - 2^0 *)
  Square(t0, z2p5); Square(t1, t0); Square(t0, t1); Square(t1, t0); Square(t0, t1);
  Mult(z2p10, t0, z2p5);                 (* 2^10 - 2^0 *)
  Square(t0, z2p10); Square(t1, t0);
  i := 2; WHILE i < 10 DO Square(t0, t1); Square(t1, t0); INC(i, 2) END;
  Mult(z2p20, t1, z2p10);                (* 2^20 - 2^0 *)
  Square(t0, z2p20); Square(t1, t0);
  i := 2; WHILE i < 20 DO Square(t0, t1); Square(t1, t0); INC(i, 2) END;
  Mult(t0, t1, z2p20);                   (* 2^40 - 2^0 *)
  Square(t1, t0); Square(t0, t1);
  i := 2; WHILE i < 10 DO Square(t1, t0); Square(t0, t1); INC(i, 2) END;
  Mult(z2p50, t0, z2p10);                (* 2^50 - 2^0 *)
  Square(t0, z2p50); Square(t1, t0);
  i := 2; WHILE i < 50 DO Square(t0, t1); Square(t1, t0); INC(i, 2) END;
  Mult(z2p100, t1, z2p50);               (* 2^100 - 2^0 *)
  Square(t1, z2p100); Square(t0, t1);
  i := 2; WHILE i < 100 DO Square(t1, t0); Square(t0, t1); INC(i, 2) END;
  Mult(t1, t0, z2p100);                  (* 2^200 - 2^0 *)
  Square(t0, t1); Square(t1, t0);
  i := 2; WHILE i < 50 DO Square(t0, t1); Square(t1, t0); INC(i, 2) END;
  Mult(t0, t1, z2p50);                   (* 2^250 - 2^0 *)
  Square(t1, t0); Square(t0, t1); Square(t1, t0); Square(t0, t1); Square(t1, t0);
  Mult(out, t1, z11)                     (* 2^255 - 21 *)
END Recip;

(** q := n * p on Curve25519; n (the scalar), p and q (u-coordinates) have 32 bytes, little endian *)
PROCEDURE ScalarMult*(VAR q, n, p: ARRAY OF CHAR);
VAR
  e: ARRAY 32 OF CHAR;
  x1, xm, zm, xm1, zm1, xmb, zmb, xm1b, zm1b, a0, a0z, a1, a1z, b0, b0z, b1, b1z, c1, c1z,
  r, s, t, u, xnb, znb, xn1b, zn1b, res: GF;
  i, b, pos: LONGINT;
BEGIN
  i := 0; WHILE i < 32 DO e[i] := n[i]; x1[i] := ORD(p[i]); INC(i) END;
  e[0] := CHR(ORD(e[0]) DIV 8 * 8);            (* clamping *)
  e[31] := CHR(ORD(e[31]) MOD 64 + 64);       (* bit 7 cleared, bit 6 set (MOD 128 + 64 carried into bit 7) *)
  x1[31] := x1[31] MOD 128;                    (* RFC 7748: the top bit of u is ignored *)
  i := 0;
  WHILE i < 32 DO xm1[i] := x1[i]; zm1[i] := 0; xm[i] := 0; zm[i] := 0; INC(i) END;
  zm1[0] := 1; xm[0] := 1;
  pos := 254;
  WHILE pos >= 0 DO  (* the Montgomery ladder *)
    b := (ORD(e[pos DIV 8]) DIV ASH(1, pos MOD 8)) MOD 2;
    Select(xmb, xm1b, xm, xm1, b); Select(zmb, zm1b, zm, zm1, b);
    Add(a0, xmb, zmb); Sub(a0z, xmb, zmb);
    Add(a1, xm1b, zm1b); Sub(a1z, xm1b, zm1b);
    Square(b0, a0); Square(b0z, a0z);
    Mult(b1, a1, a0z); Mult(b1z, a1z, a0);
    Add(c1, b1, b1z); Sub(c1z, b1, b1z);
    Square(r, c1z);
    Sub(s, b0, b0z);
    Mult121665(t, s);
    Add(u, t, b0);
    Mult(xnb, b0, b0z); Mult(znb, s, u);
    Square(xn1b, c1); Mult(zn1b, r, x1);
    Select(xm, xm1, xnb, xn1b, b); Select(zm, zm1, znb, zn1b, b);
    DEC(pos)
  END;
  Recip(zm1, zm); Mult(res, xm, zm1); Freeze(res);
  i := 0; WHILE i < 32 DO q[i] := CHR(res[i]); INC(i) END
END ScalarMult;

(** q := n * 9, the public key of the private key n *)
PROCEDURE ScalarMultBase*(VAR q, n: ARRAY OF CHAR);
VAR base: ARRAY 32 OF CHAR; i: INTEGER;
BEGIN
  i := 0; WHILE i < 32 DO base[i] := 0X; INC(i) END;
  base[0] := 9X;
  ScalarMult(q, n, base)
END ScalarMultBase;

END TLSX25519.
