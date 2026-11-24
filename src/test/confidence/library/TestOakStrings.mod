MODULE TestOakStrings;
IMPORT OakStrings, Strings := oocStrings, Out;

VAR
  checks, failed: INTEGER;
  text: ARRAY 32 OF CHAR;
  small: ARRAY 4 OF CHAR;
  single: ARRAY 1 OF CHAR;

PROCEDURE Check(ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN
    INC(failed); Out.String("failed check "); Out.Int(checks, 0); Out.Ln
  END
END Check;

BEGIN
  checks := 0; failed := 0;
  Check(OakStrings.Length("") = 0);
  Check(OakStrings.Length("abc") = 3);
  text := "abcd"; OakStrings.Insert("XY", 2, text); Check(text = "abXYcd");
  OakStrings.Insert("!", 6, text); Check(text = "abXYcd!");
  small := "ac"; OakStrings.Insert("b", 1, small); Check(small = "abc");
  small := "abc"; OakStrings.Insert("XY", 1, small); Check(small = "aXY");
  text := "ab"; OakStrings.Append("cd", text); Check(text = "abcd");
  small := "ab"; OakStrings.Append("cd", small); Check(small = "abc");
  OakStrings.Append("", small); Check(small = "abc");
  text := "abcdef"; OakStrings.Delete(text, 2, 2); Check(text = "abef");
  OakStrings.Delete(text, 2, 30); Check(text = "ab");
  OakStrings.Delete(text, 2, 0); Check(text = "ab");
  text := "abcdef"; OakStrings.Replace("XY", 2, text); Check(text = "abXYef");
  OakStrings.Replace("12345", 4, text); Check(text = "abXY12345");
  small := "abc"; OakStrings.Replace("XYZ", 1, small); Check(small = "aXY");
  OakStrings.Extract("abcdef", 1, 2, text); Check(text = "bc");
  OakStrings.Extract("abcdef", 4, 30, text); Check(text = "ef");
  OakStrings.Extract("abcdef", 6, 1, text); Check(text = "");
  OakStrings.Extract("abcdef", 0, 0, text); Check(text = "");
  OakStrings.Extract("abcdef", 0, 3, small); Check(small = "abc");
  OakStrings.Extract("abcdef", 0, 4, small); Check(small = "abc");
  OakStrings.Extract("abcdef", 0, 5, small); Check(small = "abc");
  OakStrings.Extract("abc", 0, 1, single); Check(single[0] = 0X);
  Check(OakStrings.Pos("aba", "aababa", 0) = 1);
  Check(OakStrings.Pos("aba", "aababa", 2) = 3);
  Check(OakStrings.Pos("x", "abc", 0) = -1);
  Check(OakStrings.Pos("", "abc", 2) = 2);
  text := "Abc-xyz09"; OakStrings.Cap(text); Check(text = "ABC-XYZ09");
  text := "utf-8"; Strings.Capitalize(text); Check(text = "UTF-8");
  text[0] := 0E9X; text[1] := "a"; text[2] := 0X;
  Strings.Capitalize(text); Check((text[0] = 0E9X) & (text[1] = "A"));
  Out.String("TestOakStrings: "); Out.Int(checks, 0);
  Out.String(" checks, "); Out.Int(failed, 0); Out.String(" failed"); Out.Ln;
  IF failed # 0 THEN HALT(100) END
END TestOakStrings.
