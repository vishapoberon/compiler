MODULE TestGPU;
IMPORT Out;
CONST n = 257;
VAR a, b: ARRAY n OF REAL;
  integers: ARRAY n OF LONGINT;
  positive: ARRAY n OF BOOLEAN;
  wide: ARRAY 1 OF HUGEINT;
  i, calls, lo, hi: LONGINT;
  factor: REAL;

PROCEDURE Step(label: ARRAY OF CHAR);
BEGIN
  Out.String("GPU test: "); Out.String(label); Out.Ln; Out.Flush
END Step;

PROCEDURE Bound(value: LONGINT): LONGINT;
BEGIN INC(calls); RETURN value END Bound;

PROCEDURE Scale(VAR values: ARRAY OF REAL; scale: REAL);
BEGIN
  ALL r = 0 .. LEN(values)-1 WITH t: REAL DO t := values[r] * scale; values[r] := t END
END Scale;

PROCEDURE Enclosing;
VAR local: ARRAY 8 OF REAL; amount: REAL; k: LONGINT;
  PROCEDURE Inner;
  BEGIN
    ALL r = 0 .. 7 DO local[LONG(r)] := local[LONG(r)] + amount END
  END Inner;
BEGIN
  amount := 5;
  FOR k := 0 TO 7 DO local[k] := k END;
  Inner;
  FOR k := 0 TO 7 DO ASSERT(local[k] = k+5) END
END Enclosing;

BEGIN
  factor := 3;
  FOR i := 0 TO n-1 DO a[i] := i; b[i] := i*2; integers[i] := -99 END;
  calls := 0;
  Step("mapped arrays and private variables: begin");
  ALL r = Bound(1) .. Bound(n-2) WITH t: REAL; v: LONGINT DO
    t := a[r] + b[r] * factor; v := r * 4;
    a[r] := t; integers[r] := v
  END;
  Step("mapped arrays and private variables: complete");
  ASSERT(calls = 2); ASSERT(a[0] = 0); ASSERT(a[n-1] = n-1);
  ASSERT(integers[0] = -99); ASSERT(integers[n-1] = -99);
  FOR i := 1 TO n-2 DO ASSERT(a[i] = i*7); ASSERT(integers[i] = i*4) END;
  FOR i := 0 TO n-1 DO ASSERT(b[i] = i*2) END;
  Step("open array: begin");
  Scale(a, 2);
  Step("open array: complete");
  ASSERT(a[n-1] = (n-1)*2);
  FOR i := 1 TO n-2 DO ASSERT(a[i] = i*14) END;
  lo := 0; hi := n-1;
  Step("runtime bounds: begin");
  ALL r = lo .. hi DO b[r] := a[r] + factor END;
  Step("runtime bounds: complete");
  FOR i := 0 TO n-1 DO ASSERT(b[i] = a[i]+factor) END;
  lo := 0; hi := 0;
  Step("singleton: begin");
  ALL r = lo .. hi DO integers[r] := 17 END;
  Step("singleton: complete");
  ASSERT(integers[0] = 17);
  lo := 4; hi := 3; calls := 0;
  Step("empty ranges: begin");
  ALL r = Bound(lo) .. Bound(hi) DO a[r] := b[r] END;
  ASSERT(calls = 2); ASSERT(a[0] = 0);
  ALL r = -1 .. -2 DO a[r] := b[r] END;
  Step("empty ranges: complete");
  Step("broadcast and booleans: begin");
  ALL r = 0 .. n-1 DO a[r] := b[0] + r; positive[r] := a[r] > 0 END;
  Step("broadcast and booleans: complete");
  FOR i := 0 TO n-1 DO ASSERT(a[i] = b[0]+i); ASSERT(positive[i]) END;
  Step("maximum integer endpoint: begin");
  ALL r = MAX(HUGEINT) .. MAX(HUGEINT) DO wide[0] := r END;
  Step("maximum integer endpoint: complete");
  ASSERT(wide[0] = MAX(HUGEINT));
  Step("minimum integer endpoint: begin");
  ALL r = MIN(HUGEINT) .. MIN(HUGEINT) DO wide[0] := r END;
  Step("minimum integer endpoint: complete");
  ASSERT(wide[0] = MIN(HUGEINT));
  Step("private-only iteration: begin");
  ALL r = 5 .. 5 WITH t: LONGINT DO t := r END;
  Step("private-only iteration: complete");
  Step("enclosing scope: begin");
  Enclosing;
  Step("enclosing scope: complete");
  Out.String("GPU ALL numerical tests passed"); Out.Ln
END TestGPU.
