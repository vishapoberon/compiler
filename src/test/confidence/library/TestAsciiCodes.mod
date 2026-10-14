MODULE TestAsciiCodes;
  IMPORT oocAscii, ooc2Ascii, Out;

  PROCEDURE Check(dle, soh, del, sp, xon, xoff: CHAR);
  BEGIN
    ASSERT(dle = 10X); ASSERT(soh = 01X); ASSERT(dle # soh);
    ASSERT((del = 7FX) & (sp = " "));
    ASSERT((xon = 11X) & (xoff = 13X))
  END Check;

BEGIN
  Check(oocAscii.dle, oocAscii.soh, oocAscii.del, oocAscii.sp,
    oocAscii.xon, oocAscii.xoff);
  Check(ooc2Ascii.dle, ooc2Ascii.soh, ooc2Ascii.del, ooc2Ascii.sp,
    ooc2Ascii.xon, ooc2Ascii.xoff);
  Out.String("ascii control code tests passed"); Out.Ln
END TestAsciiCodes.
