MODULE TwoComplement;

CONST
  MaxPositive = 2147483647;  (* Maximum signed 32-bit integer *)
  Modulo = 100000000H;      (* 2^32, evaluated in HUGEINT, not a narrow shift *)

PROCEDURE FromHugeIntToSigned*(value: HUGEINT): LONGINT;
VAR low: HUGEINT;
BEGIN
  low := value MOD Modulo;
  IF low > MaxPositive THEN DEC(low, Modulo) END;
  RETURN SHORT(low)
END FromHugeIntToSigned;

PROCEDURE ToSigned*(value: LONGINT): LONGINT;
BEGIN
  RETURN FromHugeIntToSigned(value)
END ToSigned;

END TwoComplement.




(*

The two’s complement signed interpretation for a 32-bit value xx is defined as:

    If x < 2^31, it is interpreted as a positive integer.
    If x ≥ 2^31, it is interpreted as:
    SignedValue = x − 2^32

    2^32 is 4294967296

    it is 1 00000000 00000000 00000000 00000000

    while 2^32 − 1 is
          11111111 11111111 11111111 11111111

For 0AAAAAAAAH:

    0AAAAAAAAH is 2863311530 in decimal
    Determine if it's negative:
        2863311530 is ≥ 2^31 (which is 2147483648), so it's negative.
    Compute the signed value:
    2863311530 − 4294967296 = −1431655766


*)


(* Other note

  2^8 represents the smallest number that requires 9 bits to represent in binary.
  For an 8-bit number, the range of representable values is:

    Unsigned: 0 to 2^8 −1 (0 to 255).
    Signed (Two's Complement): −2^7 − 2^7 (−128 to 127).


*)
