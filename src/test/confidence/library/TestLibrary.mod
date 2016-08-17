MODULE TestLibrary;

IMPORT SYSTEM, Console, Reals;

PROCEDURE TestConvert(lr: LONGREAL);
  VAR str: ARRAY 20 OF CHAR; i: INTEGER;
BEGIN
  Reals.ConvertL(lr, 6, str);
  i := 6; WHILE i > 0 DO DEC(i); Console.Char(str[i]) END;
  Console.Ln;
END TestConvert;

PROCEDURE TestHex(r: REAL);
  VAR str: ARRAY 20 OF CHAR;
BEGIN
  Reals.ConvertH(r, str); str[8] := 0X; Console.String(str); Console.Ln;
END TestHex;

PROCEDURE RealTests;
  VAR
    str: ARRAY 20 OF CHAR;
(*
    r:   REAL;
    lr:  LONGREAL;
*)
BEGIN
  TestConvert(1.0);
  TestConvert(1.5);
  TestConvert(2.0);
  TestConvert(2.99);
  TestConvert(3.0);

  TestHex(1.0);
  TestHex(1.5);
  TestHex(2.0);
  TestHex(2.99);
  TestHex(3.0);

  Console.Int(Reals.Expo(0.5),1); Console.Ln; (* 126 *)
  Console.Int(Reals.Expo(1.0),1); Console.Ln; (* 128 *)
  Console.Int(Reals.Expo(2.0),1); Console.Ln; (* 129 *)
  Console.Int(Reals.Expo(3.0),1); Console.Ln; (* 129 *)
  Console.Int(Reals.Expo(4.0),1); Console.Ln; (* 130 *)
END RealTests;


BEGIN
  RealTests;
  Console.String("Library tests successful."); Console.Ln;
END TestLibrary.