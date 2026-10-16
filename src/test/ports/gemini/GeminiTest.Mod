MODULE GeminiTest;  (* GeminiTest.Run: the core of the Gemini clients without a network: links made
  absolute, file names for URLs, input encoding, status names, gemtext lines, and identities made,
  listed and found (in the directory zq_idents, made here) *)

IMPORT Files, Gemini0, Gemtext0, out := Out;

VAR fails, checks: LONGINT;

PROCEDURE Check(what: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN INC(fails); out.String("FAIL "); out.String(what); out.String(" (case "); out.Int(checks, 0); out.String(")"); out.Ln END
END Check;

PROCEDURE Res(base, target, want: ARRAY OF CHAR);
VAR u: ARRAY Gemini0.MaxURL OF CHAR;
BEGIN
  IF ~Gemini0.Resolve(base, target, u) THEN u := "-" END;
  IF u # want THEN out.String("  resolve "); out.String(target); out.String(" -> "); out.String(u); out.Ln END;
  Check("resolve", u = want)
END Res;

PROCEDURE Name(url, want: ARRAY OF CHAR);
VAR n: ARRAY 256 OF CHAR;
BEGIN
  Gemini0.NameForURL(url, n);
  IF n # want THEN out.String("  name "); out.String(url); out.String(" -> "); out.String(n); out.Ln END;
  Check("name", n = want)
END Name;

PROCEDURE URLs;
VAR e, s: ARRAY 256 OF CHAR;
BEGIN
  Res("gemini://h.example/a/b.gmi", "c.gmi", "gemini://h.example/a/c.gmi");
  Res("gemini://h.example/a/b.gmi", "/x", "gemini://h.example/x");
  Res("gemini://h.example/a/b/c.gmi", "../d.gmi", "gemini://h.example/a/d.gmi");
  Res("gemini://h.example/a/b/c.gmi", "./", "gemini://h.example/a/b/");
  Res("gemini://h.example/a/b.gmi?q", "?r", "gemini://h.example/a/b.gmi?r");
  Res("gemini://h.example:1966/a/", "b", "gemini://h.example:1966/a/b");
  Res("gemini://h.example/a/", "//o.example/p", "gemini://o.example/p");
  Res("gemini://h.example/a/", "https://w.example/", "https://w.example/");
  Res("spartan://s.example/a/b", "c", "spartan://s.example/a/c");
  Res("gemini://[::1]:1966/a", "b", "gemini://[::1]:1966/b");
  Res("gemini://h.example", "a", "gemini://h.example/a");
  Name("gemini://geminiprotocol.net/", "geminiprotocol.net");
  Name("gemini://h.example/docs/about.gmi?x=1", "about.gmi");
  Name("gemini://h.example/a b/c:d", "c-d");
  Name("gemini://h.example/.hidden", "hidden");
  s := "a b&c/é"; Gemini0.Encode(s, e); Check("encode", e = "a%20b%26c%2F%C3%A9");
  Gemini0.StatusName(Gemini0.Gemini, 60, e); Check("status name", e = "60 certificate required");
  Gemini0.StatusName(Gemini0.Spartan, 3, e); Check("spartan status name", e = "3 redirect")
END URLs;

PROCEDURE Lines;
VAR c: Gemini0.Chunk; S: Gemtext0.Scanner; L: Gemtext0.Line; text: ARRAY 600 OF CHAR; i, n: LONGINT; kinds: ARRAY 20 OF LONGINT;
  long: BOOLEAN;

  PROCEDURE Add(t: ARRAY OF CHAR);
  VAR j: LONGINT;
  BEGIN j := 0; WHILE t[j] # 0X DO c.data[c.len] := t[j]; INC(c.len); INC(j) END
  END Add;

BEGIN
  NEW(c); c.len := 0; c.next := NIL;
  Add("# Title"); c.data[c.len] := 0DX; INC(c.len); c.data[c.len] := 0AX; INC(c.len);
  Add("text line"); c.data[c.len] := 0AX; INC(c.len);
  Add("=> gemini://x.example/ the label"); c.data[c.len] := 0AX; INC(c.len);
  Add("=>/bare"); c.data[c.len] := 0AX; INC(c.len);
  Add("* item"); c.data[c.len] := 0AX; INC(c.len);
  Add("> quote"); c.data[c.len] := 0AX; INC(c.len);
  Add("```alt"); c.data[c.len] := 0AX; INC(c.len);
  Add("# not a heading"); c.data[c.len] := 0AX; INC(c.len);
  Add("```"); c.data[c.len] := 0AX; INC(c.len);
  Add("### third"); c.data[c.len] := 0AX; INC(c.len);
  Add("=: /in ask"); c.data[c.len] := 0AX; INC(c.len);
  i := 0; WHILE i < 5000 DO c.data[c.len] := "x"; INC(c.len); INC(i) END;
  c.data[c.len] := 0AX; INC(c.len);
  Add("last");
  Gemtext0.Open(S, c); n := 0; long := FALSE;
  WHILE Gemtext0.Next(S, L) & (n < 20) DO
    kinds[n] := L.kind;
    IF n = 0 THEN Check("heading text", L.text = "Title") END;
    IF n = 2 THEN Check("link url", L.url = "gemini://x.example/"); Check("link label", L.text = "the label") END;
    IF n = 3 THEN Check("bare link", (L.url = "/bare") & (L.text = "/bare")) END;
    IF n = 6 THEN Check("alt text", L.text = "alt") END;
    IF n = 7 THEN Check("pre text", L.text = "# not a heading") END;
    IF n = 10 THEN Check("prompt", (L.url = "/in") & (L.text = "ask")) END;
    IF n = 11 THEN long := L.more END;
    INC(n)
  END;
  Check("lines", n = 14);
  Check("kinds", (kinds[0] = Gemtext0.Heading1) & (kinds[1] = Gemtext0.Text) & (kinds[2] = Gemtext0.Link) &
    (kinds[4] = Gemtext0.Item) & (kinds[5] = Gemtext0.Quote) & (kinds[6] = Gemtext0.PreStart) & (kinds[7] = Gemtext0.Pre) &
    (kinds[8] = Gemtext0.PreEnd) & (kinds[9] = Gemtext0.Heading3) & (kinds[10] = Gemtext0.Prompt) & (kinds[12] = Gemtext0.Text));
  Check("a long line in pieces", long);
  text := "text/gemini; charset=utf-8"; Check("gemtext type", Gemtext0.IsGemtext(text));
  text := "text/plain"; Check("not gemtext", ~Gemtext0.IsGemtext(text))
END Lines;

PROCEDURE Idents;
VAR dir: ARRAY 64 OF CHAR; a, b, list, id: Gemini0.Ident; ok: BOOLEAN; q: ARRAY 20 OF CHAR; result: INTEGER;
BEGIN
  dir := "zq_idents";
  list := Gemini0.LoadIdents(dir);  (* those of an earlier run go *)
  WHILE list # NIL DO
    Files.Delete(list.cert, result); Files.Delete(list.key, result);
    list := list.next
  END;
  ok := Gemini0.NewIdent(dir, "ada", "ada@example.org", 10, a) & Gemini0.NewIdent(dir, "adam", "", 10, b);
  Check("made", ok);
  IF ok THEN
    Check("details", (a.cn = "ada") & (a.mail = "ada@example.org") & (a.notAfter[0] = "2") & (a.fingerprint[63] # 0X));
    list := Gemini0.LoadIdents(dir);
    Check("two listed", (list # NIL) & (list.next # NIL) & (list.next.next = NIL));
    id := Gemini0.FindIdent(list, "ada"); Check("by name", id # NIL);
    IF id # NIL THEN Check("the right one", id.fingerprint = a.fingerprint) END;
    id := Gemini0.FindIdent(list, "ADA@example.org"); Check("by mail", (id # NIL) & (id.fingerprint = a.fingerprint));
    COPY(b.fingerprint, q); q[10] := 0X;
    id := Gemini0.FindIdent(list, q); Check("by fingerprint", (id # NIL) & (id.fingerprint = b.fingerprint));
    id := Gemini0.FindIdent(list, "da"); Check("ambiguous", (id = NIL) & (Gemini0.nCandidates = 2));
    id := Gemini0.FindIdent(list, "nobody"); Check("none", (id = NIL) & (Gemini0.nCandidates = 0));
    Check("loads", Gemini0.LoadIdentity(a.cert, a.key) # NIL)
  END
END Idents;

PROCEDURE Run*;
BEGIN
  fails := 0; checks := 0;
  URLs; Lines; Idents;
  out.String("GeminiTest: "); out.Int(checks, 0); out.String(" checks, "); out.Int(fails, 0); out.String(" failed"); out.Ln;
  ASSERT(fails = 0)
END Run;

END GeminiTest.
