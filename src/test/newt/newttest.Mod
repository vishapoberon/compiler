MODULE newttest;

IMPORT newt, oocIntStr, Unix;
VAR i, j, k : newt.Int32;
str : ARRAY 32 OF CHAR;
fo, co : newt.Component;
BEGIN
i := newt.Init();
newt.Cls();
str := "hello world!";
newt.DrawRootText(5, 7, str);
newt.GetScreenSize(i, j);
oocIntStr.IntToStr(i, str);
newt.DrawRootText(5, 9, str);
str := "x";
newt.DrawRootText(7, 9, "x");
oocIntStr.IntToStr(j, str);
newt.DrawRootText(9, 9, str);

newt.PushHelpLine("");
newt.Refresh();
i := Unix.Sleep(1);

newt.PushHelpLine("A help line");
newt.Refresh();
i := Unix.Sleep(1);

newt.PopHelpLine();
newt.Refresh();
i := Unix.Sleep(1);

fo := newt.Form(NIL, "aaa", 0);
co := newt.Button(15, 15, "OK");
newt.FormAddComponent(fo, co);
newt.WaitForKey();
newt.Delay(30);
i := newt.Finished();
END newttest.
