MODULE TestOakNumbers;
IMPORT LowLReal, RealStr, LRealStr, Out;
VAR
  checks, failed: INTEGER;
  text: ARRAY 128 OF CHAR;

PROCEDURE Check(ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN
    INC(failed); Out.String("failed check "); Out.Int(checks, 0); Out.Ln
  END
END Check;

BEGIN
  checks := 0; failed := 0;
  Check(LowLReal.exponent(1.5D0) = 0);
  Check(LowLReal.exponent(-1.5D0) = 0);
  Check(LowLReal.exponent(8.0D0) = 3);
  Check(LowLReal.exponent(0.125D0) = -3);
  Check(LowLReal.fraction(12.0D0) = 1.5D0);
  Check(LowLReal.fraction(-12.0D0) = -1.5D0);
  Check(LowLReal.scale(1.5D0, 3) = 12.0D0);
  Check(LowLReal.scale(-0.5D0, -3) = -0.0625D0);
  Check(LowLReal.scale(0.0D0, 10) = 0.0D0);
  Check(LowLReal.exponent(1.0D100) = 332);
  RealStr.RealToFloat(1.5, 3, text); Check(text = "1.50");
  RealStr.RealToFloat(0.005, 3, text); Check(text = "5.00E-3");
  LRealStr.RealToFloat(1.5D0, 3, text); Check(text = "1.50");
  LRealStr.RealToFloat(0.005D0, 3, text); Check(text = "5.00E-3");
  LRealStr.RealToFloat(1.0D100, 3, text); Check(text = "1.00E+100");
  LRealStr.RealToFloat(0.0D0, 3, text); Check(text = "0.00");
  Out.String("TestOakNumbers: "); Out.Int(checks, 0);
  Out.String(" checks, "); Out.Int(failed, 0); Out.String(" failed"); Out.Ln;
  IF failed # 0 THEN HALT(100) END
END TestOakNumbers.
