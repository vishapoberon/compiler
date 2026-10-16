MODULE testList;
IMPORT Texts, StringList, Oberon;

VAR
    errCount   : LONGINT;
    L0         : StringList.TList;
    l          : LONGINT;
    n          : StringList.Node;
    passCount  : LONGINT;
    strs       : StringList.TStringList;
    str        : StringList.TString;
    success    : REAL;
    tres       : StringList.pstring;
    totalCount : LONGINT;
 b, successful : BOOLEAN;
    W          : Texts.Writer;

PROCEDURE list(VAR s : StringList.TStringList);
BEGIN
  StringList.list(s)
END list;

BEGIN
   errCount   := 0;
   passCount  := 0;
   successful := TRUE;
   totalCount := 0;
   NEW(tres, 4);

   Texts.OpenWriter(W);

   Texts.WriteString(W, "-- Creating the List --"); Texts.WriteLn(W);

   strs := StringList.Create();

   Texts.WriteString(W, "-- Populating the List --"); Texts.WriteLn(W);
   Texts.WriteLn(W);

   l := strs.AddString(strs, "000");
   strs.AppendString(strs, "001");
   strs.AppendString(strs, "002");
   NEW(str);
   NEW(str.str, 4);
   COPY("003", str.str^);
   NEW(L0);
   L0 := strs;
   strs.Append(L0, str);
   strs.AppendString(strs, "004");
   strs.AppendString(strs, "005");
   l := strs.AddString(strs, "006");

   Texts.WriteString(W, "[TEST #1] Number of elements in the list: Expected 7, Found ");
   Texts.WriteInt(W, strs.Count, 0);
   IF strs.Count = 7 THEN
      Texts.WriteString(W, " (passed)"); Texts.WriteLn(W);
      INC(passCount);
   ELSE
      Texts.WriteString(W, " (failed)"); Texts.WriteLn(W);
      INC(errCount);
   END;

   Texts.WriteLn(W);
   Texts.WriteString(W, "-- Inserting an Element at Index 6 --"); Texts.WriteLn(W);
   Texts.WriteLn(W);

   NEW(str);
   NEW(str.str, 10);
   COPY("SOMETHING", str.str^);
   strs.Insert(L0, 6, str);

   Texts.WriteString(W, "[TEST #2] Number of elements in the list: Expected 8, Found ");
   Texts.WriteInt(W, strs.Count, 0);
   IF strs.Count = 8 THEN
      Texts.WriteString(W, " (passed)"); Texts.WriteLn(W);
      INC(passCount);
   ELSE
      Texts.WriteString(W, " (failed)"); Texts.WriteLn(W);
      INC(errCount);
   END;

   l := strs.IndexOf(strs, "999");
   Texts.WriteString(W, '[TEST #3] Index of the element "999": Expected -1, Found ');
   Texts.WriteInt(W, l, 0);
   IF l = -1 THEN
      Texts.WriteString(W, " (passed)"); Texts.WriteLn(W);
      INC(passCount);
   ELSE
      Texts.WriteString(W, " (failed)"); Texts.WriteLn(W);
      INC(errCount);
   END;

   l := strs.IndexOf(strs, "002");
   Texts.WriteString(W, '[TEST #4] Index of the element "002": Expected 2, Found ');
   Texts.WriteInt(W, l, 0);
   IF l = 2 THEN
      Texts.WriteString(W, " (passed)"); Texts.WriteLn(W);
      INC(passCount);
   ELSE
      Texts.WriteString(W, " (failed)"); Texts.WriteLn(W);
      INC(errCount);
   END;

   l := strs.IndexOf(strs, "SOMETHING");
   Texts.WriteString(W, '[TEST #5] Index of the element "SOMETHING": Expected 6, Found ');
   Texts.WriteInt(W, l, 0);
   IF l = 6 THEN
      Texts.WriteString(W, " (passed)"); Texts.WriteLn(W);
      INC(passCount);
   ELSE
      Texts.WriteString(W, " (failed)"); Texts.WriteLn(W);
      INC(errCount);
   END;

   Texts.WriteLn(W);
   Texts.WriteString(W, "-- Removing the Element at Index 6 --"); Texts.WriteLn(W);
   strs.Delete(L0,6);
   Texts.WriteLn(W);

   tres := strs.GetString(strs, 6);
   Texts.WriteString(W, "[TEST #6] Get the Element at Index 6: Expected 006, Found "); Texts.WriteString(W, tres^);
   IF tres^ = "006" THEN
      Texts.WriteString(W, " (passed)"); Texts.WriteLn(W);
      INC(passCount);
   ELSE
      Texts.WriteString(W, " (failed)"); Texts.WriteLn(W);
      INC(errCount);
   END;





   Texts.WriteLn(W);
   Texts.WriteString(W, "-------------------------------"); Texts.WriteLn(W);
   list(strs);
   Texts.WriteString(W, "-- Removing the First Element  --"); Texts.WriteLn(W);
   n := strs.Get(L0, 0);
   b := strs.DeleteNode(L0,n);
    
   Texts.WriteLn(W);

   Texts.WriteString(W, "-------------------------------"); Texts.WriteLn(W);
   list(strs);
   Texts.WriteString(W, "-------------------------------"); Texts.WriteLn(W);
   tres := strs.GetString(strs, 0);
   (*Texts.WriteString(W, "[TEST #6] Get the Element at Index 0: Expected 006, Found "); Texts.WriteString(W, tres^);
   IF tres^ = "006" THEN
      Texts.WriteString(W, " (passed)"); Texts.WriteLn(W);
      INC(passCount);
   ELSE
      Texts.WriteString(W, " (failed)"); Texts.WriteLn(W);
      INC(errCount);
   END;
   *)




   Texts.WriteLn(W);
   totalCount := errCount + passCount;
   success    := (passCount / totalCount) * 100;
   Texts.WriteString(W, "Results:");
   IF success = 100.00 THEN
      Texts.WriteString(W, " 100");
   ELSE
      Texts.WriteRealFix(W, success, 0, 2);
   END;
   Texts.WriteString(W, "% tests passed, ");
   Texts.WriteInt(W, errCount, 0);
   IF errCount = 1 THEN
      Texts.WriteString(W, " test failed out of ");
   ELSE
      Texts.WriteString(W, " tests failed out of ");
   END;
   Texts.WriteInt(W, totalCount, 0); Texts.WriteLn(W);
   Texts.WriteLn(W);

   Texts.Append(Oberon.Log, W.buf);

   IF errCount > 0 THEN successful := FALSE END;
   ASSERT(successful);

END testList.
