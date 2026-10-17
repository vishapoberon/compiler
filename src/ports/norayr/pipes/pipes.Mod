MODULE pipes;

  IMPORT SYSTEM, Platform, Strings := oocStrings, Ascii, strUtils, Out;

  CONST
    EOF* = -1;

  TYPE
  File = SYSTEM.ADDRESS;
  Files = ARRAY 64 OF File; (* should be more than enough to hold FILE struct *)
  PtrFile = POINTER [1] TO Files;
  (*PtrFile = POINTER TO PtrFileDesc;
  PtrFileDesc = RECORD
          f : Files;
  END;*)
  Pchar = POINTER TO ARRAY OF CHAR;

  Text* = POINTER TO TextDesc;

  TextDesc* = RECORD;
     text- : PtrFile;
     eof-  : BOOLEAN;
   END;


PROCEDURE -Astdio '#include <stdio.h>';

PROCEDURE NewText*(): Text;
VAR
  t: Text;
BEGIN
  NEW(t);
  NEW(t.text);
  RETURN t;
END NewText;

PROCEDURE OberonStringtoPchar( VAR s : ARRAY OF CHAR) : Pchar;
VAR l, i : LONGINT;
p : Pchar;
BEGIN
   l := Strings.Length(s);
   INC(l);
   INC(l);
   NEW(p, l);
   i := 0;
   REPEAT
     p[i] := s[i];
     INC(i)
   UNTIL i = l-2;
   INC(i);
   p[i] := Ascii.nul;
   RETURN p;
END OberonStringtoPchar;

PROCEDURE dumpChars(VAR s : ARRAY OF CHAR);
VAR
  i : INTEGER;
BEGIN
  i := 0;
  WHILE s[i] # Ascii.nul DO
    Out.Int(i, 0); Out.Char(" "); Out.Char(s[i]); Out.Ln; INC(i)
  END
END dumpChars;

PROCEDURE -popen (VAR command, modes : ARRAY OF CHAR) : PtrFile "(pipes_PtrFile)popen((char*)command, (char*)modes)";

PROCEDURE Popen*(VAR command: ARRAY OF CHAR; mode: CHAR): Text;
VAR
  cmd : ARRAY 256 OF CHAR;
  md  : ARRAY 2 OF CHAR;
  t   : Text;
BEGIN
  (*NEW(md, 2);
  md^[0] := mode; md^[1] := Ascii.nul;
  cmd := OberonStringtoPchar(command);*)

  t := NewText();
  strUtils.Assign(command, cmd);
  strUtils.Assign("r", md);
  (*dumpChars(md); dumpChars(cmd);*)
  t.text := popen(cmd, md);
  t.eof := FALSE;
  RETURN t
END Popen;

PROCEDURE -pclose* (stream : PtrFile) : LONGINT
  "(LONGINT)pclose((FILE*)stream)";

PROCEDURE Pclose* (t: Text): LONGINT;
VAR
  result: LONGINT;
BEGIN
  result := pclose(t.text);
  RETURN result
END Pclose;

PROCEDURE -getc(f: PtrFile): LONGINT "(LONGINT)getc((FILE*)f)";

PROCEDURE Read*(VAR(*CONST*) f  : Text; VAR ch : CHAR);
VAR
  l, e : LONGINT;
  s : ARRAY 5 OF CHAR;
BEGIN
   l := getc(f.text);
   IF l < 0 THEN
     f.eof := TRUE
   ELSE
     f.eof := FALSE;
     ch := CHR((SHORT(SHORT(l))))
   END
END Read;

PROCEDURE ReadLine*(VAR(*CONST*) f : Text; VAR s : ARRAY OF CHAR);
VAR
  i: INTEGER;
  ch: CHAR;
  eol: BOOLEAN;
BEGIN
  eol := FALSE;
  i := 0;
  REPEAT
    Read(f, ch);
    IF (f.eof) OR (i >= LEN(s) - 1) OR (ch = Ascii.cr) OR (ch = Ascii.lf) OR f.eof THEN eol := TRUE END;
    IF eol THEN
      s[i] := Ascii.nul
    ELSE
      s[i] := ch
    END;
    INC(i)
  UNTIL eol;
END ReadLine;

PROCEDURE isEOF*(VAR(*CONST*) f: Text): BOOLEAN;
BEGIN
  RETURN f.eof;
END isEOF;


BEGIN


END pipes.
