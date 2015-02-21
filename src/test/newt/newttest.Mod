MODULE newttest;

IMPORT newt;
VAR i : newt.Int32;
str : ARRAY 32 OF CHAR;
BEGIN
i := newt.Init();
newt.Cls();
str := "hello world!";
newt.DrawRootText(5, 7, str);
newt.WaitForKey();
newt.Delay(30);
i := newt.Finished();
END newttest.
