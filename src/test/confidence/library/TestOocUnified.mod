MODULE TestOocUnified;
  IMPORT ConvTypes, IntConv, IntStr, CharClass, oocStrings,
    LRealConv, oo2c2LRealConv, Real0, Out;
  VAR state: ConvTypes.ScanState; cl: ConvTypes.ScanClass;
    text: ARRAY 32 OF CHAR; n: LONGINT; res: ConvTypes.ConvResults;
BEGIN
  IntConv.ScanInt("1", cl, state); ASSERT(cl = ConvTypes.valid);
  state.p(0X, cl, state); ASSERT(cl = ConvTypes.terminator);
  ASSERT(IntConv.FormatInt("123") = IntConv.strAllRight);
  ASSERT(IntConv.FormatInt("") = IntConv.strEmpty);
  ASSERT(IntConv.FormatInt("x") = IntConv.strWrongFormat);
  ASSERT(IntConv.ValueInt("-123") = -123);
  IntStr.IntToStr(42, text); ASSERT(text = "42");
  IntStr.StrToInt(text, n, res); ASSERT((n = 42) & (res = 0));
  ASSERT(CharClass.IsNumeric("1") & CharClass.IsLetter("a") & CharClass.IsUpper("A"));
  text := "abc"; oocStrings.Capitalize(text); ASSERT(text = "ABC");
  oocStrings.Append("def", text); ASSERT(oocStrings.Length(text) = 6);
  ASSERT(ABS(LRealConv.ValueReal("12.5") - 12.5D0) < 0.001D0);
  ASSERT(ABS(oo2c2LRealConv.ValueReal("12.5") - 12.5D0) < 0.001D0);
  ASSERT(oo2c2LRealConv.FormatReal("1E2") = oo2c2LRealConv.strAllRight);
  ASSERT(oo2c2LRealConv.FormatReal("1D2") = oo2c2LRealConv.strWrongFormat);
  state := Real0.SR; state.p("1", cl, state);
  ASSERT((cl = ConvTypes.valid) & (state = Real0.P));
  Out.String("unified oo2c library tests passed"); Out.Ln
END TestOocUnified.
