MODULE TestWriter;

IMPORT Out, SYSTEM, S := LongStrings, Str := oocStrings, M := Msg, Ch := Channel, Mem := IOMemory,
  URI, URIParser, D := XMLDTD, B := XMLBuilder, P := XMLParser,
  W := XMLWriter, Canon := XMLBuilderCanonical, C := XMLUnicodeCodec,
  XMLUnicodeCodecImportAll;

TYPE
  Units = POINTER TO ARRAY OF W.Char;
  Bytes = POINTER TO ARRAY OF CHAR;
  Capture = POINTER TO CaptureDesc;
  CaptureDesc = RECORD (B.BuilderDesc)
    starts, ends, documents, attributes, length: LONGINT;
    name, value: D.String;
    text: ARRAY 100000 OF D.Char;
  END;
  PartialWriter = POINTER TO PartialWriterDesc;
  PartialWriterDesc = RECORD (Ch.WriterDesc)
    inner: Ch.Writer; fail: BOOLEAN;
  END;

VAR base: URI.URI; result: M.Msg; context: M.Context;

PROCEDURE (b: Capture) StartElement(namespaceDecl: D.NamespaceDeclaration; localName: D.String);
BEGIN b.name := localName; INC(b.starts) END StartElement;

PROCEDURE (b: Capture) EndElement(namespaceDecl: D.NamespaceDeclaration; localName: D.String);
BEGIN INC(b.ends) END EndElement;

PROCEDURE (b: Capture) EndDocument;
BEGIN INC(b.documents) END EndDocument;

PROCEDURE (b: Capture) Attribute(namespaceDecl: D.NamespaceDeclaration; localName: D.String;
  attrDecl: D.AttrDecl; value: D.AttValue; specified: BOOLEAN);
BEGIN b.value := value.Flatten(attrDecl); INC(b.attributes) END Attribute;

PROCEDURE (b: Capture) Characters(VAR chars: D.StringVar; charsStart, charsEnd: D.CharPos;
  elementWhitespace: D.ElementWhitespaceType);
  VAR i: LONGINT;
BEGIN
  ASSERT(b.length+charsEnd-charsStart < LEN(b.text), 1);
  FOR i := charsStart TO charsEnd-1 DO b.text[b.length] := chars[i]; INC(b.length) END;
  b.text[b.length] := 0
END Characters;

PROCEDURE (w: PartialWriter) WriteBytes(VAR bytes: ARRAY OF SYSTEM.BYTE; start, n: LONGINT);
BEGIN
  w.bytesWritten := 0;
  IF w.res # NIL THEN RETURN END;
  IF n > 3 THEN n := 3 END;
  w.inner.WriteBytes(bytes, start, n);
  w.bytesWritten := w.inner.bytesWritten; w.res := w.inner.res;
  IF w.fail THEN w.res := M.New(context, Ch.writeError); w.fail := FALSE END
END WriteBytes;

PROCEDURE Memory(): Mem.Channel;
  VAR ch: Mem.Channel; res: M.Msg;
BEGIN
  ch := Mem.Tmp("", {Mem.read, Mem.write}, res); ASSERT(res = NIL, 2); RETURN ch
END Memory;

PROCEDURE Good(p: P.Parser);
  VAR msg: M.Msg; error: ARRAY 1024 OF CHAR;
BEGIN
  msg := p.errList.msgList;
  WHILE msg # NIL DO msg.GetText(error); Out.String(error); Out.Ln; msg := msg.nextMsg END;
  ASSERT(p.errList.msgCount = 0, 3)
END Good;

PROCEDURE Parse(ch: Mem.Channel): Capture;
  VAR b: Capture; p: P.Parser;
BEGIN
  NEW(b); B.Init(b); b.starts := 0; b.ends := 0; b.documents := 0;
  b.attributes := 0; b.length := 0; b.text[0] := 0; b.name := NIL; b.value := NIL;
  p := P.NewChannel(ch, base, NIL, NIL, b); p.followExternalRef := FALSE;
  p.ParseDocument; Good(p);
  ASSERT((b.documents = 1) & (b.starts = b.ends), 4); RETURN b
END Parse;

PROCEDURE Expect(ch: Mem.Channel; expected: ARRAY OF CHAR);
  VAR i, length: LONGINT;
BEGIN
  length := S.Length8(expected);
  IF ch.Length() # length THEN Out.String("Output length: "); Out.Int(ch.Length(), 0); Out.Ln END;
  ASSERT(ch.Length() = length, 5);
  FOR i := 0 TO length-1 DO ASSERT(ch.file.data[i] = expected[i], 6) END
END Expect;

PROCEDURE BasicChecks;
  VAR ch: Mem.Channel; w: W.Writer; name: ARRAY 32 OF W.Char; b: Capture;
BEGIN
  ch := Memory(); w := W.New(ch.NewWriter(), C.GetFactory("UTF-8"), FALSE, -1);
  w.WriteTextDecl("1.0", "yes"); w.StartTagLatin1("r", TRUE);
  S.Long("a", name); w.AttrStringLatin1(name, "<&>'");
  S.Long("flag", name); w.AttrBool(name, TRUE);
  w.WriteLatin1("x<&>"); w.EmptyTagLatin1("e"); w.EndTag; w.EndOfText;
  Expect(ch, "<?xml version='1.0' encoding='UTF-8' standalone='yes'?><r a='&lt;&amp;&gt;&apos;' flag='yes'>x&lt;&amp;&gt;<e/></r>");
  b := Parse(ch); ASSERT((b.starts = 2) & (b.attributes = 2) & S.Equal8(b.text, "x<&>"), 7);
  ch.Close;
  ch := Memory(); w := W.New(ch.NewWriter(), C.GetFactory("UTF-8"), FALSE, -1);
  w.StartTagLatin1("r", TRUE); S.Long("n", name); w.AttrInt(name, MIN(LONGINT));
  S.Long("no", name); w.AttrBool(name, FALSE);
  w.WriteLInt(MAX(LONGINT)); w.WriteLatin1(" "); w.WriteRealFix(1.25, 2); w.EndTag; w.EndOfText;
  Expect(ch, "<r n='-2147483648' no='no'>2147483647 1.25</r>"); ch.Close
END BasicChecks;

PROCEDURE IndentChecks;
  VAR ch: Mem.Channel; w: W.Writer; expected: ARRAY 128 OF CHAR;
BEGIN
  ch := Memory(); w := W.New(ch.NewWriter(), C.GetFactory("UTF-8"), FALSE, 2);
  w.StartTagLatin1("r", FALSE); w.EmptyTagLatin1("a");
  w.StartTagLatin1("b", TRUE); w.WriteLatin1("text"); w.EndTag; w.EndTag; w.EndOfText;
  expected := "<r>"; expected[3] := 0AX; expected[4] := 0X;
  Str.Append("  <a/>", expected); Str.Append(0AX, expected);
  Str.Append("  <b>text</b>", expected); Str.Append(0AX, expected);
  Str.Append("</r>", expected); Str.Append(0AX, expected);
  Expect(ch, expected); ch.Close;
  ch := Memory(); w := W.New(ch.NewWriter(), C.GetFactory("UTF-8"), FALSE, -1);
  w.SetEmptyElementHTML(TRUE); w.EmptyTagLatin1("br"); w.EndOfText;
  Expect(ch, "<br />"); ch.Close
END IndentChecks;

PROCEDURE UnicodeChecks;
  VAR ch: Mem.Channel; w: W.Writer; name, value: ARRAY 16 OF W.Char;
    b: Capture; variant, i: LONGINT; latin: ARRAY 5 OF CHAR;
BEGIN
  name[0] := 531H; name[1] := 0;
  value[0] := 531H; value[1] := 0D83DH; value[2] := 0DE42H;
  value[3] := 38; value[4] := 60; value[5] := 62; value[6] := 39;
  value[7] := 9; value[8] := 10; value[9] := 13; value[10] := 0;
  FOR variant := 0 TO 1 DO
    ch := Memory();
    IF variant = 0 THEN w := W.New(ch.NewWriter(), C.GetFactory("UTF-8"), FALSE, -1)
    ELSE w := W.New(ch.NewWriter(), C.GetFactory("UTF-16"), TRUE, -1)
    END;
    w.WriteTextDecl("1.0", ""); w.StartTag(name, TRUE); w.AttrString(name, value);
    w.WriteI(value, 0, 2); w.WriteI(value, 2, 10); w.EndTag; w.EndOfText;
    ASSERT((w.writer.res = NIL) & (w.codec.invalidChars = 0), 8);
    b := Parse(ch);
    ASSERT((b.name[0] = 531H) & (b.attributes = 1) & (b.length = 10), 9);
    FOR i := 0 TO 9 DO ASSERT((b.value[i] = value[i]) & (b.text[i] = value[i]), 10) END;
    ch.Close
  END;
  ch := Memory(); w := W.New(ch.NewWriter(), C.GetFactory("UTF-8"), FALSE, -1);
  latin[0] := 0E9X; latin[1] := 09X; latin[2] := 0AX; latin[3] := 0DX; latin[4] := 0X;
  w.StartTagLatin1("r", TRUE); w.AttrStringLatin1(name, latin);
  latin[1] := 0DX; latin[2] := 0X;
  w.WriteLatin1(latin); w.EndTag; w.EndOfText;
  b := Parse(ch);
  ASSERT((b.value[0] = 0E9H) & (b.value[1] = 9) & (b.value[2] = 10) &
    (b.value[3] = 13) & (b.length = 2) & (b.text[0] = 0E9H) & (b.text[1] = 13), 11);
  ch.Close
END UnicodeChecks;

PROCEDURE GrowthChecks;
  VAR ch: Mem.Channel; w: W.Writer; b: Capture; name, text: Bytes; units: Units;
    i, n: LONGINT;
BEGIN
  n := 40000; NEW(name, n+1); NEW(text, n+1);
  FOR i := 0 TO n-1 DO name[i] := "a"; text[i] := "x" END;
  name[n] := 0X; text[n] := 0X;
  ch := Memory(); w := W.New(ch.NewWriter(), C.GetFactory("UTF-8"), FALSE, -1);
  w.StartTagLatin1(name^, TRUE); w.WriteLatin1(text^); w.EndTag; w.EndOfText;
  b := Parse(ch); ASSERT((S.Length(b.name^) = n) & (b.length = n), 12); ch.Close;
  NEW(units, 70001);
  FOR i := 0 TO 69999 DO units[i] := 531H END;
  units[8191] := 0D83DH; units[8192] := 0DE42H; units[70000] := 0;
  ch := Memory(); w := W.New(ch.NewWriter(), C.GetFactory("UTF-8"), FALSE, -1);
  w.StartTagLatin1("r", TRUE); w.Write(units^); w.EndTag; w.EndOfText;
  b := Parse(ch); ASSERT(b.length = 70000, 13);
  FOR i := 0 TO 69999 DO ASSERT(b.text[i] = units[i], 14) END;
  ch.Close;
  ch := Memory(); w := W.New(ch.NewWriter(), C.GetFactory("UTF-8"), FALSE, -1);
  FOR i := 0 TO 63 DO w.StartTagLatin1("r", TRUE) END;
  FOR i := 0 TO 63 DO w.EndTag END;
  w.EndOfText; b := Parse(ch); ASSERT(b.starts = 64, 15); ch.Close
END GrowthChecks;

PROCEDURE URIChecks;
  VAR ch: Mem.Channel; w: W.Writer; uri: URI.URI; name: ARRAY 8 OF W.Char;
    b: Capture; text: Bytes; i: LONGINT;
BEGIN
  uri := URIParser.NewURI("file:/xml-tests/a&b", NIL, result); ASSERT(result = NIL, 16);
  ch := Memory(); w := W.New(ch.NewWriter(), C.GetFactory("UTF-8"), FALSE, -1);
  w.SetBaseURI(base(URI.HierarchicalURI)); w.StartTagLatin1("r", TRUE);
  S.Long("href", name); w.AttrURI(name, uri, FALSE); w.WriteURI(uri, FALSE);
  w.EndTag; w.EndOfText; Expect(ch, "<r href='a&amp;b'>a&amp;b</r>"); ch.Close;
  NEW(text, 40007); COPY("file:/", text^);
  FOR i := 6 TO 40005 DO text[i] := "a" END; text[40006] := 0X;
  uri := URIParser.NewURI(text^, NIL, result); ASSERT(result = NIL, 17);
  ch := Memory(); w := W.New(ch.NewWriter(), C.GetFactory("UTF-8"), FALSE, -1);
  w.StartTagLatin1("r", TRUE); w.AttrURI(name, uri, TRUE); w.WriteURI(uri, TRUE);
  w.EndTag; w.EndOfText; b := Parse(ch);
  ASSERT(S.Equal8(b.value^, text^) & S.Equal8(b.text, text^), 18); ch.Close
END URIChecks;

PROCEDURE PartialChecks;
  VAR ch: Mem.Channel; w: W.Writer; partial: PartialWriter; fail: LONGINT;
BEGIN
  FOR fail := 0 TO 1 DO
    ch := Memory(); NEW(partial); partial.inner := ch.NewWriter(); partial.base := ch;
    partial.res := NIL; partial.bytesWritten := 0; partial.fail := fail = 1;
    w := W.New(partial, C.GetFactory("UTF-8"), FALSE, -1);
    w.StartTagLatin1("r", TRUE); w.WriteLatin1("<&>"); w.EndTag; w.EndOfText;
    IF fail = 1 THEN ASSERT(partial.res # NIL, 19); partial.res := NIL; w.Flush END;
    ASSERT(partial.res = NIL, 20); Expect(ch, "<r>&lt;&amp;&gt;</r>"); ch.Close
  END
END PartialChecks;

PROCEDURE Canonical(text: ARRAY OF CHAR; format: SHORTINT): Mem.Channel;
  VAR input, output: Mem.Channel; writer: Ch.Writer; p: P.Parser; builder: Canon.Builder;
BEGIN
  input := Memory(); writer := input.NewWriter(); writer.WriteBytes(text, 0, S.Length8(text));
  output := Memory(); builder := Canon.New(output, C.GetFactory("UTF-8"), format);
  p := P.NewChannel(input, base, NIL, NIL, builder); p.followExternalRef := FALSE;
  p.ParseDocument; Good(p);
  ASSERT((builder.out.writer.res = NIL) & (builder.out.codec.invalidChars = 0), 21);
  input.Close; RETURN output
END Canonical;

PROCEDURE CanonicalChecks;
  VAR ch: Mem.Channel; text: ARRAY 1024 OF CHAR; b: Capture;
BEGIN
  ch := Canonical('<!DOCTYPE r [<!ATTLIST r b CDATA "B">]><r z="3" a="1">&lt;&amp;&#13;<![CDATA[>]]><!--comment--><?pi data?></r>', Canon.firstCanonicalForm);
  Expect(ch, '<r a="1" b="B" z="3">&lt;&amp;&#13;&gt;<?pi data?></r>'); ch.Close;
  ch := Canonical('<r z="1" y="2" x="3" w="4" v="5" u="6" t="7" s="8" r="9"/>', Canon.firstCanonicalForm);
  Expect(ch, '<r r="9" s="8" t="7" u="6" v="5" w="4" x="3" y="2" z="1"></r>'); ch.Close;
  text := '<!DOCTYPE r [<!NOTATION z SYSTEM "z"><!NOTATION a PUBLIC "a">]><r/>';
  ch := Canonical(text, Canon.firstCanonicalForm); Expect(ch, '<r></r>'); ch.Close;
  ch := Canonical(text, Canon.secondCanonicalForm);
  text := "<!DOCTYPE r ["; Str.Append(0AX, text);
  Str.Append("<!NOTATION a PUBLIC 'a'>", text); Str.Append(0AX, text);
  Str.Append("<!NOTATION z SYSTEM 'z'>", text); Str.Append(0AX, text);
  Str.Append("]>", text); Str.Append(0AX, text); Str.Append("<r></r>", text);
  Expect(ch, text); ch.Close;
  text := '<!DOCTYPE r [<!NOTATION a SYSTEM "a'; Str.Append("'b", text); Str.Append('">]><r/>', text);
  ch := Canonical(text, Canon.secondCanonicalForm); b := Parse(ch); ASSERT(b.starts = 1, 22); ch.Close
END CanonicalChecks;

BEGIN
  base := URIParser.NewURI("file:/xml-tests/document.xml", NIL, result); ASSERT(result = NIL, 23);
  NEW(context); M.InitContext(context, "TestWriter");
  BasicChecks; IndentChecks; UnicodeChecks; GrowthChecks; URIChecks; PartialChecks; CanonicalChecks;
  Out.String("XML writer and canonical output checks passed"); Out.Ln
END TestWriter.
