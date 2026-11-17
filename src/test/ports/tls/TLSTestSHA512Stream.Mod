MODULE TLSTestSHA512Stream;

IMPORT TLSBytes, TLSSHA512, Out;

VAR checks, failures: LONGINT;
  context: TLSSHA512.Context;
  digest, wanted, empty: ARRAY 64 OF CHAR;
  small: ARRAY 63 OF CHAR;
  message: ARRAY 1025 OF CHAR;
  input, reference: TLSBytes.Buffer;

PROCEDURE Check(okay: BOOLEAN);
BEGIN INC(checks); IF ~okay THEN INC(failures); Out.String("FAIL SHA-512 stream case "); Out.Int(checks, 0); Out.Ln END END Check;

PROCEDURE Hex(ch: CHAR): LONGINT;
BEGIN IF ch <= "9" THEN RETURN ORD(ch)-ORD("0") END; RETURN ORD(ch)-ORD("a")+10 END Hex;

PROCEDURE Vector(text, hash: ARRAY OF CHAR; length: LONGINT);
VAR i: LONGINT;
BEGIN
  i := 0; WHILE i < length DO message[i] := text[i]; INC(i) END;
  i := 0; WHILE i < 64 DO wanted[i] := CHR(Hex(hash[i*2])*16+Hex(hash[i*2+1])); INC(i) END;
  TLSSHA512.Init512(context); Check(TLSSHA512.Update(context, message, 0, length));
  Check(TLSSHA512.Final512(context, digest));
  i := 0; WHILE (i < 64) & (digest[i] = wanted[i]) DO INC(i) END; Check(i = 64)
END Vector;

PROCEDURE Partitions;
VAR length, step, pos, n, i: LONGINT;
BEGIN
  i := 0; WHILE i < LEN(message) DO message[i] := CHR((i*137+91) MOD 256); INC(i) END;
  length := 0;
  WHILE length <= 1025 DO
    TLSBytes.Init(input); TLSBytes.AppendOpen(input, message, length); TLSSHA512.Digest512(input, reference);
    step := 1;
    WHILE step <= 257 DO
      TLSSHA512.Init512(context); pos := 0;
      WHILE pos < length DO
        n := step; IF n > length-pos THEN n := length-pos END;
        Check(TLSSHA512.Update(context, message, pos, n)); INC(pos, n)
      END;
      Check(TLSSHA512.Final512(context, digest));
      i := 0; WHILE (i < 64) & (digest[i] = reference.data[i]) DO INC(i) END; Check(i = 64);
      step := step*4+1
    END;
    IF length < 130 THEN INC(length) ELSE INC(length, 127) END
  END
END Partitions;

PROCEDURE Lifecycle;
VAR i: LONGINT;
BEGIN
  TLSSHA512.Init512(context);
  i := 0; WHILE i < LEN(small) DO small[i] := 0A5X; INC(i) END;
  Check(~TLSSHA512.Update(context, message, -1, 1));
  Check(~TLSSHA512.Update(context, message, 1, MAX(LONGINT)));
  Check(~TLSSHA512.Update(context, message, 0, -1));
  Check(~TLSSHA512.Update(context, message, LEN(message)+1, 0));
  Check(~TLSSHA512.Final512(context, small));
  i := 0; WHILE (i < LEN(small)) & (small[i] = 0A5X) DO INC(i) END; Check(i = LEN(small));
  Check(TLSSHA512.Update(context, message, LEN(message), 0));
  Check(TLSSHA512.Final512(context, digest));
  i := 0; WHILE (i < 64) & (digest[i] = empty[i]) DO INC(i) END; Check(i = 64);
  Check(~TLSSHA512.Final512(context, digest));
  Check(~TLSSHA512.Update(context, message, 0, 0));
  TLSSHA512.Init512(context); Check(TLSSHA512.Update(context, message, 0, 1));
  TLSSHA512.Init512(context); Check(TLSSHA512.Final512(context, digest));
  i := 0; WHILE (i < 64) & (digest[i] = empty[i]) DO INC(i) END; Check(i = 64)
END Lifecycle;

BEGIN
  Vector("", "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e", 0);
  empty := digest;
  Vector("abc", "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f", 3);
  Lifecycle; Partitions;
  Out.String("TLSTestSHA512Stream: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(failures, 0); Out.String(" failed"); Out.Ln;
  IF failures # 0 THEN HALT(1) END
END TLSTestSHA512Stream.
