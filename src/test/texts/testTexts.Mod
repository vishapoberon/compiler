(* compile with voc -M testTexts.Mod *)
MODULE testTexts;

IMPORT Texts, Console;

VAR W : Texts.Writer;
 T : Texts.Text;
 R : Texts.Reader;

 ch : CHAR;
 i : INTEGER;
 s : ARRAY 1024 OF CHAR;
BEGIN
Texts.OpenWriter (W);


Texts.WriteString(W, "aaa");
Texts.WriteLn(W);
Texts.WriteLn(W);
Texts.WriteLn(W);
NEW(T); Texts.Open(T, "test.txt");

Texts.Append (T, W.buf);
(*Texts.Store(W, T);*)

Texts.OpenReader(R, T, 0); Texts.Read(R, ch); i := 0;
      WHILE ~R.eot DO
        IF ch = 0DX THEN s[i] := 0X; i := 0; Console.String(s); Console.Ln
        ELSE s[i] := ch; INC(i)
        END ;
        Texts.Read(R, ch)
      END ;
      s[i] := 0X; (*Console.String(s)*)


END testTexts.
