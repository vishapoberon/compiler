(* compile with voc -M testFiles.Mod *)
MODULE testFiles;

IMPORT Files, Texts, Console;

CONST file="testFiles.Mod";

VAR 
   T : Texts.Text;
   R : Texts.Reader;
   F : Files.File;
   ch : CHAR;
BEGIN

F := Files.Old (file);
IF F # NIL THEN
   NEW(T); 
   Texts.Open(T, file);
   Texts.OpenReader(R, T, 0);
   Texts.Read (R, ch);

   WHILE ~R.eot DO
      Texts.Read (R, ch);
      Console.Char(ch);
   END;

ELSE

   Console.String ("cannot open"); Console.Ln;

END;


END testFiles.
