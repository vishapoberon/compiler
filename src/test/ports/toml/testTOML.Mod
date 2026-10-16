MODULE testTOML;  (* testTOML: checks on a sample document; testTOML file: the sections and fields
  read from file, one per line (section | key | kind | <value>) *)

IMPORT TOML, Files, Args, Out, Platform;

CONST LF = 0AX; Q = 22X;

VAR checks, fails: LONGINT; doc: TOML.Doc; arg: ARRAY 256 OF CHAR;
  text: ARRAY 2048 OF CHAR; tlen: LONGINT;

PROCEDURE Check(name: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ok THEN Out.String("ok   ") ELSE INC(fails); Out.String("FAIL ") END;
  Out.String(name); Out.Ln
END Check;

(* appends line to text, with a line end; ' stands for " *)
PROCEDURE L(line: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE line[i] # 0X DO
    IF line[i] = "'" THEN text[tlen] := Q ELSE text[tlen] := line[i] END;
    INC(tlen); INC(i)
  END;
  text[tlen] := LF; INC(tlen); text[tlen] := 0X
END L;

PROCEDURE Field(sec, key: ARRAY OF CHAR; VAR value: ARRAY OF CHAR): BOOLEAN;
VAR s: TOML.Section;
BEGIN
  s := TOML.GetSection(doc, sec);
  RETURN (s # NIL) & TOML.GetField(s, key, value)
END Field;

PROCEDURE Is(sec, key, want: ARRAY OF CHAR);
VAR v: ARRAY 4096 OF CHAR; name: ARRAY 256 OF CHAR; i, j: LONGINT;
BEGIN
  COPY(sec, name); i := 0; WHILE name[i] # 0X DO INC(i) END;
  name[i] := " "; INC(i); j := 0; WHILE key[j] # 0X DO name[i] := key[j]; INC(i); INC(j) END; name[i] := 0X;
  Check(name, Field(sec, key, v) & (v = want))
END Is;

PROCEDURE Sample;
VAR s: TOML.Section; f: TOML.Field; it: TOML.Item; name, key: ARRAY 64 OF CHAR; n: LONGINT;
BEGIN
  tlen := 0; text[0] := 0X;
  L("title = 'TOML test'  # a comment");
  L("[package]");
  L("name = 'coco'");
  L("version = '0.1.0'");
  L("count = 42");
  L("ratio = 0.5");
  L("ok = true");
  L("esc = 'a\'bé'");
  L("plain = 'x'");
  L("deps = [ 'a', 'b',");
  L("  'c',  # the third");
  L("]");
  L("point = { x = 1, y = 'two' }");
  L("a.b.c = 'dotted'");
  L("[[test]]");
  L("cmd = 'first'");
  L("[[test]]");
  L("cmd = 'second'");
  L("[old]");
  L("src/x.Mod = bare value up to the end");
  doc := TOML.Parse(text);
  Check("no errors", doc.errors = 0);
  Is("", "title", "TOML test");
  Is("package", "name", "coco");
  Is("package", "version", "0.1.0");
  Is("package", "count", "42");
  Is("package", "plain", "x");
  Is("package", "point.x", "1");
  Is("package", "point.y", "two");
  Is("package", "a.b.c", "dotted");
  Is("old", "src/x.Mod", "bare value up to the end");
  name := "package"; s := TOML.GetSection(doc, name);
  key := "count"; f := TOML.Find(s, key); Check("count is an Integer", (f # NIL) & (f.kind = TOML.Integer));
  key := "ratio"; f := TOML.Find(s, key); Check("ratio is a Float", (f # NIL) & (f.kind = TOML.Float));
  key := "ok"; f := TOML.Find(s, key); Check("ok is a Boolean", (f # NIL) & (f.kind = TOML.Boolean) & (f.value = "true"));
  key := "esc"; f := TOML.Find(s, key);
  Check("escapes: a, quote, b, e acute in UTF-8", (f # NIL) & (f.value[0] = "a") & (f.value[1] = Q) & (f.value[2] = "b")
    & (f.value[3] = 0C3X) & (f.value[4] = 0A9X) & (f.value[5] = 0X));
  key := "deps"; f := TOML.Find(s, key);
  n := 0; IF f # NIL THEN it := f.items; WHILE it # NIL DO INC(n); it := it.next END END;
  Check("deps: an Array of 3 over 3 lines", (f # NIL) & (f.kind = TOML.Array) & (n = 3) & (f.items.value = "a"));
  Is("package", "deps", "a b c");
  name := "test"; s := TOML.GetSection(doc, name); key := "cmd";
  Check("first [[test]]", (s # NIL) & TOML.GetField(s, key, arg) & (arg = "first"));
  s := TOML.GetNextSection(s, name);
  Check("second [[test]]", (s # NIL) & TOML.GetField(s, key, arg) & (arg = "second"));
  tlen := 0; text[0] := 0X;
  L("ok = 1");
  L("bad = 'not closed");
  L("fine = 2");
  doc := TOML.Parse(text);
  Check("an error, at line 2, the rest read", (doc.errors = 1) & (doc.errorLine = 2) & Field("", "fine", arg) & (arg = "2"))
END Sample;

PROCEDURE Dump(name: ARRAY OF CHAR);
VAR f: Files.File; R: Files.Rider; buf: POINTER TO ARRAY OF CHAR; n, i: LONGINT;
  s: TOML.Section; fl: TOML.Field; it: TOML.Item;
BEGIN
  f := Files.Old(name); IF f = NIL THEN Out.String("no file "); Out.String(name); Out.Ln; Platform.Exit(1) END;
  n := Files.Length(f); NEW(buf, n + 1); Files.Set(R, f, 0);
  i := 0; WHILE i < n DO Files.Read(R, buf[i]); INC(i) END; buf[n] := 0X;
  doc := TOML.Parse(buf^);
  s := doc.first;
  WHILE s # NIL DO
    fl := s.first;
    WHILE fl # NIL DO
      Out.String(s.name); Out.String(" | "); Out.String(fl.key); Out.String(" | "); Out.Int(fl.kind, 0); Out.String(" | ");
      IF fl.kind = TOML.Array THEN
        it := fl.items; WHILE it # NIL DO Out.Char("<"); Out.String(it.value); Out.Char(">"); it := it.next END
      ELSE Out.Char("<"); Out.String(fl.value); Out.Char(">")
      END;
      Out.Ln; fl := fl.next
    END;
    s := s.next
  END;
  Out.String("errors "); Out.Int(doc.errors, 0);
  IF doc.errors > 0 THEN Out.String(" line "); Out.Int(doc.errorLine, 0); Out.String(": "); Out.String(doc.error) END;
  Out.Ln
END Dump;

BEGIN
  Args.Get(1, arg);
  IF arg # "" THEN Dump(arg)
  ELSE
    checks := 0; fails := 0; Sample;
    Out.String("testTOML: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln;
    IF fails # 0 THEN Platform.Exit(1) END
  END
END testTOML.
