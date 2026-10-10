MODULE LongModuleRegistryNames;
  IMPORT Out, ooc2LRealConv;
  PROCEDURE LongCommandRegistryNamesAreNotTruncated*;
  BEGIN
    ASSERT(ABS(ooc2LRealConv.ValueReal("12.5") - 12.5D0) < 0.001D0);
    ASSERT(ooc2LRealConv.LengthFixedReal(12.5D0, 1) > 0);
    Out.String("long module/command registry names passed"); Out.Ln
  END LongCommandRegistryNamesAreNotTruncated;
END LongModuleRegistryNames.
