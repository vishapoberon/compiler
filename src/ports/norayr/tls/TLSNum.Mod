MODULE TLSNum;
(* Unsigned big numbers for RSA and elliptic curves, with 32 bit signed integers only (the same
   file serves voc and polpo): little endian limbs of 15 bits in LONGINT, so that a product of
   two limbs is below 2^30 and a sum with carries stays below 2^31 (as in BearSSL's "i15").
   Modular multiplication is Montgomery's (CIOS), for odd moduli. *)
IMPORT TLSBytes;

CONST
  Bits* = 15; Base = 8000H; Mask = 7FFFH;
  MaxLimbs* = 280;  (** 4200 bits: RSA up to 4096 *)

TYPE
  Num* = RECORD
    len*: LONGINT;  (** limbs used; the number is sum d[i] * 2^(15 i) *)
    d*: ARRAY MaxLimbs OF LONGINT
  END;

  Modulus* = RECORD
    m*: Num;         (** odd *)
    minv: LONGINT;   (* -1/m mod 2^15 *)
    r2: Num;         (* R^2 mod m, R = 2^(15 m.len) *)
    one: Num         (* R mod m: 1 in Montgomery form *)
  END;

PROCEDURE SetZero*(VAR a: Num; len: LONGINT);
VAR i: LONGINT;
BEGIN
  a.len := len; i := 0; WHILE i < MaxLimbs DO a.d[i] := 0; INC(i) END
END SetZero;

PROCEDURE SetSmall*(VAR a: Num; len, v: LONGINT);
BEGIN
  SetZero(a, len); a.d[0] := v MOD Base; IF len > 1 THEN a.d[1] := v DIV Base END
END SetSmall;

(** a := the big endian bytes b[pos..pos+n), in len limbs (0: as many as needed) *)
PROCEDURE FromBytes*(VAR b: ARRAY OF CHAR; pos, n, len: LONGINT; VAR a: Num);
VAR i, bit, v, s: LONGINT;
BEGIN
  IF len = 0 THEN len := (n * 8 + Bits - 1) DIV Bits; IF len = 0 THEN len := 1 END END;
  SetZero(a, len);
  i := 0; bit := 0;
  WHILE i < n DO  (* from the last byte, 8 bits at a time *)
    v := LONG(ORD(b[pos + n - 1 - i]));
    s := bit MOD Bits;
    IF bit DIV Bits < MaxLimbs THEN
      a.d[bit DIV Bits] := a.d[bit DIV Bits] + (v * ASH(1, s)) MOD Base
    END;
    IF (s > Bits - 8) & (bit DIV Bits + 1 < MaxLimbs) THEN
      a.d[bit DIV Bits + 1] := a.d[bit DIV Bits + 1] + v DIV ASH(1, Bits - s)
    END;
    INC(bit, 8); INC(i)
  END
END FromBytes;

(** out := a as n big endian bytes (the high part dropped) *)
PROCEDURE ToBytes*(VAR a: Num; n: LONGINT; VAR out: TLSBytes.Buffer);
VAR i, bit, v, s: LONGINT;
BEGIN
  TLSBytes.Init(out);
  i := 0; WHILE i < n DO TLSBytes.AppendByte(out, 0); INC(i) END;
  i := 0; bit := 0;
  WHILE i < n DO
    v := 0; s := bit MOD Bits;
    IF bit DIV Bits < a.len THEN v := a.d[bit DIV Bits] DIV ASH(1, s) END;
    IF (s > Bits - 8) & (bit DIV Bits + 1 < a.len) THEN
      v := v + a.d[bit DIV Bits + 1] * ASH(1, Bits - s)
    END;
    out.data[n - 1 - i] := CHR(v MOD 256);
    INC(bit, 8); INC(i)
  END
END ToBytes;

PROCEDURE IsZero*(VAR a: Num): BOOLEAN;
VAR i: LONGINT;
BEGIN
  i := 0; WHILE i < a.len DO IF a.d[i] # 0 THEN RETURN FALSE END; INC(i) END;
  RETURN TRUE
END IsZero;

(** -1, 0, 1 as a <, =, > b (limbs beyond len are zero) *)
PROCEDURE Compare*(VAR a, b: Num): LONGINT;
VAR i, n: LONGINT;
BEGIN
  n := a.len; IF b.len > n THEN n := b.len END;
  i := n - 1;
  WHILE i >= 0 DO
    IF a.d[i] < b.d[i] THEN RETURN -1 ELSIF a.d[i] > b.d[i] THEN RETURN 1 END;
    DEC(i)
  END;
  RETURN 0
END Compare;

(** a := a - b (a >= b), over a.len limbs *)
PROCEDURE SubInPlace*(VAR a, b: Num);
VAR i, v, borrow: LONGINT;
BEGIN
  borrow := 0; i := 0;
  WHILE i < a.len DO
    v := a.d[i] - b.d[i] - borrow;
    IF v < 0 THEN v := v + Base; borrow := 1 ELSE borrow := 0 END;
    a.d[i] := v; INC(i)
  END
END SubInPlace;

(** a := a + b, over a.len limbs; the carry out *)
PROCEDURE AddInPlace*(VAR a, b: Num): LONGINT;
VAR i, v, carry: LONGINT;
BEGIN
  carry := 0; i := 0;
  WHILE i < a.len DO
    v := a.d[i] + b.d[i] + carry; a.d[i] := v MOD Base; carry := v DIV Base; INC(i)
  END;
  RETURN carry
END AddInPlace;

(** out := a mod m for a < 2m (one subtraction at most); a.len = m.len *)
PROCEDURE Reduce1(VAR a: Num; VAR m: Num);
BEGIN
  IF Compare(a, m) >= 0 THEN SubInPlace(a, m) END
END Reduce1;

(** out := (a + b) mod m; a, b < m *)
PROCEDURE ModAdd*(VAR a, b: Num; VAR mod: Modulus; VAR out: Num);
VAR carry: LONGINT;
BEGIN
  out := a; out.len := mod.m.len;
  carry := AddInPlace(out, b);
  IF (carry # 0) OR (Compare(out, mod.m) >= 0) THEN SubInPlace(out, mod.m) END
END ModAdd;

(** out := (a - b) mod m; a, b < m *)
PROCEDURE ModSub*(VAR a, b: Num; VAR mod: Modulus; VAR out: Num);
VAR carry: LONGINT;
BEGIN
  IF Compare(a, b) >= 0 THEN out := a; out.len := mod.m.len; SubInPlace(out, b)
  ELSE out := a; out.len := mod.m.len; carry := AddInPlace(out, mod.m); SubInPlace(out, b)
  END
END ModSub;

(** out := a * b / R mod m (Montgomery); a, b < m; out may be a or b *)
PROCEDURE MontMul*(VAR a, b: Num; VAR mod: Modulus; VAR out: Num);
VAR t: ARRAY MaxLimbs + 2 OF LONGINT; i, j, n, bi, u, v, carry: LONGINT;
BEGIN
  n := mod.m.len;
  i := 0; WHILE i < n + 2 DO t[i] := 0; INC(i) END;
  i := 0;
  WHILE i < n DO
    bi := b.d[i];
    carry := 0; j := 0;  (* t := t + a * b[i] *)
    WHILE j < n DO
      v := t[j] + a.d[j] * bi + carry; t[j] := v MOD Base; carry := v DIV Base; INC(j)
    END;
    v := t[n] + carry; t[n] := v MOD Base; t[n+1] := t[n+1] + v DIV Base;
    u := t[0] * mod.minv MOD Base;  (* t := (t + u * m) / 2^15 *)
    v := t[0] + u * mod.m.d[0]; carry := v DIV Base;
    j := 1;
    WHILE j < n DO
      v := t[j] + u * mod.m.d[j] + carry; t[j-1] := v MOD Base; carry := v DIV Base; INC(j)
    END;
    v := t[n] + carry; t[n-1] := v MOD Base; v := t[n+1] + v DIV Base;
    t[n] := v; t[n+1] := 0;
    INC(i)
  END;
  out.len := n;
  i := 0; WHILE i < n DO out.d[i] := t[i]; INC(i) END;
  WHILE i < MaxLimbs DO out.d[i] := 0; INC(i) END;
  IF (t[n] # 0) OR (Compare(out, mod.m) >= 0) THEN SubInPlace(out, mod.m) END
END MontMul;

(** mod prepared for m (odd, m.len limbs, the top limb not zero) *)
PROCEDURE InitModulus*(VAR m: Num; VAR mod: Modulus);
VAR x, i, n: LONGINT; t: Num;
BEGIN
  mod.m := m; n := m.len;
  x := 1; i := 0;  (* 1/m[0] mod 2^15 by Newton: x := x * (2 - m0 * x) *)
  WHILE i < 4 DO x := x * (2 - m.d[0] * x MOD Base) MOD Base; INC(i) END;
  mod.minv := (Base - x) MOD Base;
  (* R mod m and R^2 mod m by doubling 1 *)
  SetSmall(t, n, 1); i := 0;
  WHILE i < Bits * n DO
    IF AddInPlace(t, t) # 0 THEN SubInPlace(t, mod.m) ELSE Reduce1(t, mod.m) END; INC(i)
  END;
  mod.one := t;
  WHILE i < 2 * Bits * n DO
    IF AddInPlace(t, t) # 0 THEN SubInPlace(t, mod.m) ELSE Reduce1(t, mod.m) END; INC(i)
  END;
  mod.r2 := t
END InitModulus;

(** a in Montgomery form: a * R mod m (a < m) *)
PROCEDURE ToMont*(VAR a: Num; VAR mod: Modulus; VAR out: Num);
BEGIN MontMul(a, mod.r2, mod, out)
END ToMont;

(** a out of Montgomery form *)
PROCEDURE FromMont*(VAR a: Num; VAR mod: Modulus; VAR out: Num);
VAR one: Num;
BEGIN SetSmall(one, mod.m.len, 1); MontMul(a, one, mod, out)
END FromMont;

(** 1 in Montgomery form *)
PROCEDURE MontOne*(VAR mod: Modulus; VAR out: Num);
BEGIN out := mod.one
END MontOne;

(** out := a mod m for any a (subtractions after shifting; for hashes and bytes wider than m) *)
PROCEDURE ModReduce*(VAR a: Num; VAR mod: Modulus; VAR out: Num);
VAR i, bit, j: LONGINT; t: Num;
BEGIN
  SetZero(t, mod.m.len);
  i := a.len - 1;
  WHILE i >= 0 DO
    bit := Bits - 1;
    WHILE bit >= 0 DO
      IF AddInPlace(t, t) # 0 THEN SubInPlace(t, mod.m) ELSE Reduce1(t, mod.m) END;
      IF ODD(a.d[i] DIV ASH(1, bit)) THEN
        j := 0; INC(t.d[0]);
        WHILE (j < t.len - 1) & (t.d[j] >= Base) DO t.d[j] := t.d[j] - Base; INC(t.d[j+1]); INC(j) END;
        Reduce1(t, mod.m)
      END;
      DEC(bit)
    END;
    DEC(i)
  END;
  out := t
END ModReduce;

(** out := a^e mod m; a < m in Montgomery form, out in Montgomery form; e big endian bytes *)
PROCEDURE MontPow*(VAR a: Num; VAR e: ARRAY OF CHAR; epos, elen: LONGINT; VAR mod: Modulus; VAR out: Num);
VAR r: Num; i, bit: LONGINT;
BEGIN
  r := mod.one; i := 0;
  WHILE i < elen DO
    bit := 7;
    WHILE bit >= 0 DO
      MontMul(r, r, mod, r);
      IF ODD(ORD(e[epos + i]) DIV ASH(1, bit)) THEN MontMul(r, a, mod, r) END;
      DEC(bit)
    END;
    INC(i)
  END;
  out := r
END MontPow;

(** out := 1/a mod m for a prime m (a^(m-2)); a in Montgomery form, out in Montgomery form *)
PROCEDURE MontInvPrime*(VAR a: Num; VAR mod: Modulus; VAR out: Num);
VAR e: Num; two: Num; b: TLSBytes.Buffer; n: LONGINT;
BEGIN
  e := mod.m; SetSmall(two, mod.m.len, 2); SubInPlace(e, two);
  n := (mod.m.len * Bits + 7) DIV 8;
  ToBytes(e, n, b);
  MontPow(a, b.data, 0, n, mod, out)
END MontInvPrime;

END TLSNum.
