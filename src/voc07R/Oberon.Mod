MODULE Oberon;

(* this module emulates Oberon.Log and Oberon.Par in order to pass agruments to Oberon programs, as it's in Oberon environment;
   it creates Oberon.Par from command line arguments;
   procedure Dump dumps Oberon.Log to standard output.
   
   -- noch *)

(* Files are commented out, because it's not necessary for work, but can be very useful for debug. See WriteTextToFile procedure; -- noch *)
IMPORT Args, Strings, Texts := CompatTexts, (*Files := CompatFiles,*) Out := Console;

VAR Log*: Texts.Text;

    Par*: RECORD
       text*: Texts.Text;
       pos* : LONGINT;
    END;

arguments : ARRAY 2048 OF CHAR;

PROCEDURE GetSelection* (VAR text: Texts.Text; VAR beg, end, time: LONGINT);
    (*VAR M: SelectionMsg;*)
  BEGIN
    (*M.time := -1; Viewers.Broadcast(M); time := M.time;
    IF time >= 0 THEN text := M.text; beg := M.beg; end := M.end END*)
  END GetSelection;

PROCEDURE Collect*( count : LONGINT);
BEGIN

END Collect;

PROCEDURE ArgsToString(VAR opts : ARRAY OF CHAR);
VAR i : INTEGER;
    opt : ARRAY 256 OF CHAR;
BEGIN
    
    i := 1;
    opt := ""; COPY ("", opts);

    WHILE i < Args.argc DO
       Args.Get(i, opt);
       Strings.Append(opt, opts);(* Strings.Append (" ", opts);*)
       (* ORP calls Texts.Scan, which returns filename, and nextCh would be set to " " if we append here " ". However after that ORP will check nextCh, and if it finds that nextCh is not "/" it's not gonna parse options. That's why Strings.Append is commented out; -- noch *)
       INC(i)
    END;

END ArgsToString;

PROCEDURE StringToText(VAR arguments : ARRAY OF CHAR; VAR T : Texts.Text);
VAR 
    W : Texts.Writer;
BEGIN
   Texts.OpenWriter(W);
   Texts.WriteString(W, arguments);
   Texts.Append (T, W.buf);
END StringToText;
(*
PROCEDURE WriteTextToFile(VAR T : Texts.Text; filename : ARRAY OF CHAR);
   VAR f : Files.File; r : Files.Rider;
BEGIN
   f := Files.New(filename);
   Files.Set(r, f, 0);
   Texts.Store(r, T);
   Files.Register(f);
END WriteTextToFile;
*)
PROCEDURE TextToString(VAR T : Texts.Text; VAR string : ARRAY OF CHAR);
   VAR R : Texts.Reader;
   ch : CHAR;
   i : LONGINT;
BEGIN
   COPY("", string);
   Texts.OpenReader(R, T, 0);
   i := 0;
   WHILE Texts.Pos(R) < T.len DO
      Texts.Read(R, ch);
      string[i] := ch;
      INC(i);
   END;
   (*string[i] := 0X;*)
END TextToString;

PROCEDURE DumpLog*;
VAR s : POINTER TO ARRAY OF CHAR;
BEGIN
   NEW(s, Log.len + 1);
   COPY("", s^);
   TextToString(Log, s^);
   Out.String(s^); Out.Ln;

   NEW(Log);
   Texts.Open(Log, "");
END DumpLog;


BEGIN
   NEW(Log);
   Texts.Open(Log, "");

   NEW(Par.text);
   Texts.Open(Par.text, "");
   Par.pos := 0;

   COPY("", arguments);
   ArgsToString(arguments);
   StringToText(arguments, Par.text);
   (*WriteTextToFile(Par.text, "params.txt");*)
   (*WriteTextToFile(Log, "log.txt");*)
   (*DumpLog;*)
END Oberon.
