MODULE TestAsciiCodes;
  IMPORT Ascii, Out;

  PROCEDURE Check(dle, soh, del, sp, xon, xoff: CHAR);
  BEGIN
    ASSERT(dle = 10X); ASSERT(soh = 01X); ASSERT(dle # soh);
    ASSERT((del = 7FX) & (sp = " "));
    ASSERT((xon = 11X) & (xoff = 13X))
  END Check;

BEGIN
  Check(Ascii.dle, Ascii.soh, Ascii.del, Ascii.sp,
    Ascii.xon, Ascii.xoff);
  Out.String("ascii control code tests passed"); Out.Ln
END TestAsciiCodes.
