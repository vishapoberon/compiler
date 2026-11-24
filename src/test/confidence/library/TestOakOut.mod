MODULE TestOakOut;
IMPORT OakOut, IntStr;
VAR text: ARRAY 32 OF CHAR;
BEGIN
  OakOut.Char("!"); OakOut.String("before Open"); OakOut.Int(42, 0);
  OakOut.Real(1.5, 0); OakOut.LongReal(1.5D0, 0); OakOut.Ln;
  OakOut.Open;
  OakOut.Char("["); OakOut.String("OakOut"); OakOut.Char("]"); OakOut.Ln;
  OakOut.Int(-3, 5); OakOut.Char("|"); OakOut.Int(3, 0);
  OakOut.Char("|"); OakOut.Int(42, -1); OakOut.Ln;
  OakOut.Int(MIN(LONGINT), 0); OakOut.Char("|");
  IntStr.IntToStr(MIN(LONGINT), text); OakOut.String(text); OakOut.Ln;
  OakOut.Int(MAX(LONGINT), 0); OakOut.Char("|");
  IntStr.IntToStr(MAX(LONGINT), text); OakOut.String(text); OakOut.Ln;
  OakOut.Real(1.5, 10); OakOut.Char("|"); OakOut.Real(-0.005, 0); OakOut.Ln;
  OakOut.Real(0.0, 0); OakOut.Char("|"); OakOut.Real(100.0, 0); OakOut.Ln;
  OakOut.LongReal(1.5D0, 11); OakOut.Char("|");
  OakOut.LongReal(-0.005D0, 0); OakOut.Ln;
  OakOut.LongReal(0.0D0, 0); OakOut.Char("|");
  OakOut.LongReal(10.0D0, 0); OakOut.Char("|");
  OakOut.LongReal(1.0D100, 0); OakOut.Ln;
  OakOut.Open; OakOut.String("reopened"); OakOut.Ln
END TestOakOut.
