MODULE TestDESLegacy;
IMPORT DES, TwoComplement, Out;
VAR key, plain, cipher, decoded: ARRAY 8 OF CHAR;
    i, j, b, reversed: INTEGER;
BEGIN
  ASSERT(TwoComplement.FromHugeIntToSigned(0AAAAAAAAH) = -1431655766);
  ASSERT(TwoComplement.FromHugeIntToSigned(100000001H) = 1);
  key[0] := 13X; key[1] := 34X; key[2] := 57X; key[3] := 79X;
  key[4] := 9BX; key[5] := 0BCX; key[6] := 0DFX; key[7] := 0F1X;
  plain[0] := 01X; plain[1] := 23X; plain[2] := 45X; plain[3] := 67X;
  plain[4] := 89X; plain[5] := 0ABX; plain[6] := 0CDX; plain[7] := 0EFX;
  (* The upstream VNC convention reverses bits within each key byte. *)
  DES.SetKey(key); DES.encrypt(plain, 0, cipher, 0);
  ASSERT(cipher[0] = 0CEX); ASSERT(cipher[1] = 0E5X);
  ASSERT(cipher[2] = 5AX); ASSERT(cipher[3] = 0CDX);
  ASSERT(cipher[4] = 23X); ASSERT(cipher[5] = 86X);
  ASSERT(cipher[6] = 0B2X); ASSERT(cipher[7] = 3FX);
  DES.decrypt(cipher, 0, decoded, 0);
  FOR i := 0 TO 7 DO ASSERT(decoded[i] = plain[i]) END;
  (* Convert the published DES key to the upstream convention. *)
  FOR i := 0 TO 7 DO
    b := ORD(key[i]); reversed := 0;
    FOR j := 0 TO 7 DO reversed := 2 * reversed + b MOD 2; b := b DIV 2 END;
    key[i] := CHR(reversed)
  END;
  DES.SetKey(key); DES.encrypt(plain, 0, cipher, 0);
  ASSERT(cipher[0] = 85X); ASSERT(cipher[1] = 0E8X);
  ASSERT(cipher[2] = 13X); ASSERT(cipher[3] = 54X);
  ASSERT(cipher[4] = 0FX); ASSERT(cipher[5] = 0AX);
  ASSERT(cipher[6] = 0B4X); ASSERT(cipher[7] = 05X);
  DES.decrypt(cipher, 0, decoded, 0);
  FOR i := 0 TO 7 DO ASSERT(decoded[i] = plain[i]) END;
  Out.String('DES legacy key and standard vector tests passed'); Out.Ln
END TestDESLegacy.
