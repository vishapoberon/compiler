MODULE TestParser;

IMPORT Out, SYSTEM, S := LongStrings, M := Msg, Ch := Channel, Mem := IOMemory,
  URI, URIParser, D := XMLDTD, B := XMLBuilder, L := XMLLocator,
  P := XMLParser, UB := XMLUnicodeBuffer, C := XMLUnicodeCodec,
  XMLUnicodeCodecImportAll;

TYPE
  Capture = POINTER TO CaptureDesc;
  CaptureDesc = RECORD (B.BuilderDesc)
    locator: L.Locator;
    starts, ends, attributes, defaults, documents, dtos, comments, pis, cdatas: LONGINT;
    text: ARRAY 100000 OF D.Char;
    length: LONGINT;
    firstName, lastAttribute, lastValue: D.String;
    firstPos: L.Position;
    dtd: D.Builder;
    complete: BOOLEAN;
  END;
  ShortReader = POINTER TO ShortReaderDesc;
  ShortReaderDesc = RECORD (Ch.ReaderDesc)
    inner: Ch.Reader; chunk: LONGINT;
  END;

VAR base: URI.URI; result: M.Msg;

PROCEDURE (r: ShortReader) ReadBytes(VAR bytes: ARRAY OF SYSTEM.BYTE; start, n: LONGINT);
BEGIN
  r.bytesRead := 0;
  IF r.res # NIL THEN RETURN END;
  IF n > r.chunk THEN n := r.chunk END;
  r.inner.ReadBytes(bytes, start, n);
  r.bytesRead := r.inner.bytesRead; r.res := r.inner.res
END ReadBytes;

PROCEDURE (b: Capture) SetLocator(locator: L.Locator);
BEGIN b.locator := locator END SetLocator;

PROCEDURE (b: Capture) StartElement(namespaceDecl: D.NamespaceDeclaration; localName: D.String);
BEGIN
  IF b.starts = 0 THEN b.firstName := localName; b.firstPos := b.locator^ END;
  INC(b.starts)
END StartElement;

PROCEDURE (b: Capture) EndElement(namespaceDecl: D.NamespaceDeclaration; localName: D.String);
BEGIN INC(b.ends) END EndElement;

PROCEDURE (b: Capture) EndDocument;
BEGIN INC(b.documents) END EndDocument;

PROCEDURE (b: Capture) StartDTD(dtdBuilder: D.Builder);
BEGIN b.dtd := dtdBuilder; INC(b.dtos) END StartDTD;

PROCEDURE (b: Capture) EndDTD(externalDTD: D.ExternalEntity; allDeclarationsProcessed: BOOLEAN);
BEGIN b.complete := allDeclarationsProcessed END EndDTD;

PROCEDURE (b: Capture) Attribute(namespaceDecl: D.NamespaceDeclaration; localName: D.String;
  attrDecl: D.AttrDecl; value: D.AttValue; specified: BOOLEAN);
  VAR normalized, collapse: BOOLEAN;
BEGIN
  INC(b.attributes); IF ~specified THEN INC(b.defaults) END;
  b.lastAttribute := localName;
  collapse := (attrDecl # NIL) & (attrDecl.type # D.attrCDATA);
  b.lastValue := value.FlattenValue(collapse, normalized)
END Attribute;

PROCEDURE (b: Capture) Characters(VAR chars: D.StringVar; charsStart, charsEnd: D.CharPos;
  elementWhitespace: D.ElementWhitespaceType);
  VAR i: LONGINT;
BEGIN
  ASSERT(b.length+charsEnd-charsStart < LEN(b.text), 1);
  FOR i := charsStart TO charsEnd-1 DO
    b.text[b.length] := chars[i]; INC(b.length)
  END;
  b.text[b.length] := 0
END Characters;

PROCEDURE (b: Capture) Comment(VAR chars: D.StringVar; charsStart, charsEnd: D.CharPos);
BEGIN INC(b.comments) END Comment;

PROCEDURE (b: Capture) ProcessingInstruction(target: D.String; VAR content: D.StringVar;
  contentStart, contentEnd: D.CharPos; baseURI: URI.URI);
BEGIN INC(b.pis) END ProcessingInstruction;

PROCEDURE (b: Capture) StartCDATA;
BEGIN INC(b.cdatas) END StartCDATA;

PROCEDURE NewCapture(): Capture;
  VAR b: Capture;
BEGIN
  NEW(b); B.Init(b); b.locator := NIL;
  b.starts := 0; b.ends := 0; b.attributes := 0; b.defaults := 0;
  b.documents := 0; b.dtos := 0; b.comments := 0; b.pis := 0; b.cdatas := 0;
  b.length := 0; b.text[0] := 0; b.dtd := NIL; b.complete := FALSE;
  RETURN b
END NewCapture;

PROCEDURE File(VAR bytes: ARRAY OF CHAR; length: LONGINT): Mem.Channel;
  VAR ch: Mem.Channel; res: M.Msg; writer: Ch.Writer;
BEGIN
  ch := Mem.Tmp("", {Mem.read, Mem.write}, res); ASSERT(res = NIL, 2);
  writer := ch.NewWriter(); writer.WriteBytes(bytes, 0, length);
  ASSERT(writer.res = NIL, 3); RETURN ch
END File;

PROCEDURE Parse(VAR bytes: ARRAY OF CHAR; length, chunk: LONGINT;
                factory: C.Factory; b: Capture): P.Parser;
  VAR ch: Mem.Channel; reader: Ch.Reader; short: ShortReader; p: P.Parser;
BEGIN
  ch := File(bytes, length); reader := ch.NewReader();
  IF chunk > 0 THEN
    NEW(short); short.inner := reader; short.base := ch; short.chunk := chunk;
    short.res := NIL; short.bytesRead := 0; reader := short
  END;
  p := P.NewReader(reader, base, factory, NIL, b);
  p.followExternalRef := FALSE; p.ParseDocument; ch.Close;
  ASSERT(b.documents = 1, 4); RETURN p
END Parse;

PROCEDURE Document(text: ARRAY OF CHAR; b: Capture): P.Parser;
BEGIN RETURN Parse(text, S.Length8(text), 0, NIL, b) END Document;

PROCEDURE Good(p: P.Parser);
  VAR msg: M.Msg; text: ARRAY 1024 OF CHAR;
BEGIN
  msg := p.errList.msgList;
  WHILE msg # NIL DO msg.GetText(text); Out.String(text); Out.Ln; msg := msg.nextMsg END;
  ASSERT(p.errList.msgCount = 0, 5)
END Good;

PROCEDURE BasicChecks;
  VAR b: Capture; p: P.Parser;
BEGIN
  b := NewCapture(); p := Document("<root/>", b); Good(p);
  ASSERT((b.starts = 1) & (b.ends = 1) & S.Equal8(b.firstName^, "root"), 6);
  ASSERT((b.firstPos.charIndex = 1) & (b.firstPos.line = 0) & (b.firstPos.column = 1), 7);
  b := NewCapture();
  p := Document('<?xml version="1.0"?><root a="x &amp; y">hi<child/>there<![CDATA[<&>]]><!--note--><?pi data?></root>', b);
  Good(p);
  ASSERT((b.starts = 2) & (b.ends = 2) & (b.attributes = 1), 8);
  ASSERT(S.Equal8(b.lastAttribute^, "a") & S.Equal8(b.lastValue^, "x & y"), 9);
  ASSERT(S.Equal8(b.text, "hithere<&>") & (b.comments = 1) & (b.pis = 1) & (b.cdatas = 1), 10);
  b := NewCapture(); p := Document('<r>&lt;&gt;&amp;&quot;&apos;&#65;&#x531;&#x1F642;</r>', b); Good(p);
  ASSERT((b.length = 9) & (b.text[0] = ORD("<")) & (b.text[5] = ORD("A")) &
    (b.text[6] = 531H) & (b.text[7] = 0D83DH) & (b.text[8] = 0DE42H), 11)
END BasicChecks;

PROCEDURE CharacterClassChecks;
(* Fingerprint of the XML 1.0 Second Edition tables in the preserved release. *)
  VAR ch, starts, names, fingerprint, flags: LONGINT;
BEGIN
  starts := 0; names := 0; fingerprint := 0;
  FOR ch := 0 TO 65535 DO
    flags := 0;
    IF P.IsNameChar0(ch) THEN INC(starts); INC(flags) END;
    IF P.IsNameChar(ch) THEN INC(names); INC(flags, 2) END;
    fingerprint := (fingerprint*33+flags) MOD 65521
  END;
  ASSERT((starts = 34516) & (names = 35122) & (fingerprint = 6038), 25)
END CharacterClassChecks;

PROCEDURE DTDChecks;
  VAR b: Capture; p: P.Parser;
BEGIN
  b := NewCapture();
  p := Document('<!DOCTYPE r [<!ELEMENT r (#PCDATA)><!ENTITY word "hello"><!ATTLIST r a NMTOKENS " a   b ">]><r>&word;</r>', b);
  Good(p);
  ASSERT((b.dtos = 1) & b.complete & (b.dtd # NIL) & S.Equal8(b.dtd.rootName^, "r"), 12);
  ASSERT(S.Equal8(b.text, "hello") & (b.defaults = 1) & S.Equal8(b.lastValue^, "a b"), 13);
  b := NewCapture();
  p := Document('<!DOCTYPE r [<!ENTITY a "A"><!ENTITY b "&a;B">]><r a="&b;">&b;</r>', b); Good(p);
  ASSERT(S.Equal8(b.text, "AB") & S.Equal8(b.lastValue^, "AB"), 14);
  b := NewCapture(); p := Document('<!DOCTYPE r [<!ENTITY e "">]><r a="&e;">&e;</r>', b); Good(p);
  ASSERT((b.length = 0) & S.Equal8(b.lastValue^, ""), 24);
  b := NewCapture(); p := Document('<!DOCTYPE r [<!ENTITY e "&#9;&#10;&#13;">]><r a="&e;"/>', b); Good(p);
  ASSERT(S.Equal8(b.lastValue^, "   "), 26);
  b := NewCapture();
  p := Document('<!DOCTYPE r [<!ENTITY % decl "<!ELEMENT r EMPTY>">%decl;]><r/>', b); Good(p);
  ASSERT((b.dtd.elementNamespace.Get(b.dtd.rootName) # NIL) & b.complete, 15);
  b := NewCapture(); p := Document('<!DOCTYPE r SYSTEM "missing.dtd"><r/>', b); Good(p);
  ASSERT(~b.complete, 16);
  b := NewCapture(); p := Document('<!DOCTYPE r [<!ATTLIST r a NMTOKENS " a  b ">]><r/>', b); Good(p);
  ASSERT((b.defaults = 1) & S.Equal8(b.lastValue^, "a b"), 29);
  b := NewCapture(); p := Document('<!DOCTYPE r [<!ATTLIST r a NMTOKENS #IMPLIED>]><r a=" a  b "/>', b); Good(p);
  ASSERT((b.attributes = 1) & S.Equal8(b.lastValue^, "a b"), 30)
END DTDChecks;

PROCEDURE UnicodeChecks;
  VAR b: Capture; p: P.Parser; bytes: ARRAY 128 OF CHAR;
    units: ARRAY 64 OF D.Char; ch: Mem.Channel; res: M.Msg;
    output: UB.Output; writer: Ch.Writer; i, endian: LONGINT;
BEGIN
  bytes := "<"; bytes[1] := 0D4X; bytes[2] := 0B1X; bytes[3] := ">";
  bytes[4] := 0F0X; bytes[5] := 9FX; bytes[6] := 99X; bytes[7] := 82X;
  bytes[8] := "<"; bytes[9] := "/"; bytes[10] := 0D4X; bytes[11] := 0B1X; bytes[12] := ">";
  FOR i := 1 TO 13 DO
    b := NewCapture(); p := Parse(bytes, 13, i, NIL, b); Good(p);
    ASSERT((b.firstName[0] = 531H) & (b.firstName[1] = 0) &
      (b.length = 2) & (b.text[0] = 0D83DH) & (b.text[1] = 0DE42H), 17)
  END;
  S.Long("<r>", units); units[3] := 531H; units[4] := 0D83DH; units[5] := 0DE42H;
  units[6] := ORD("<"); units[7] := ORD("/"); units[8] := ORD("r"); units[9] := ORD(">"); units[10] := 0;
  FOR endian := 0 TO 1 DO
    ch := Mem.Tmp("", {Mem.read, Mem.write}, res);
    writer := ch.NewWriter();
    IF endian = 0 THEN
      writer.WriteByte(0FFX); writer.WriteByte(0FEX);
      output := UB.NewOutput(writer, C.GetFactory("UTF-16LE"), FALSE)
    ELSE
      output := UB.NewOutput(writer, C.GetFactory("UTF-16"), TRUE)
    END;
    output.Write16(units); output.Flush;
    b := NewCapture(); p := P.NewChannel(ch, base, NIL, NIL, b); p.ParseDocument; Good(p);
    ASSERT((b.length = 3) & (b.text[0] = 531H) & (b.text[1] = 0D83DH) & (b.text[2] = 0DE42H), 18);
    ch.Close
  END
END UnicodeChecks;

PROCEDURE StreamingChecks;
  VAR bytes: POINTER TO ARRAY OF CHAR; b: Capture; p: P.Parser; i, n: LONGINT;
BEGIN
  n := 70000; NEW(bytes, n+8);
  bytes[0] := "<"; bytes[1] := "r"; bytes[2] := ">";
  FOR i := 3 TO n+2 DO bytes[i] := "x" END;
  bytes[n+3] := "<"; bytes[n+4] := "/"; bytes[n+5] := "r"; bytes[n+6] := ">";
  b := NewCapture(); p := Parse(bytes^, n+7, 7, NIL, b); Good(p);
  ASSERT((b.length = n) & (b.starts = 1) & (b.ends = 1), 19);
  FOR i := 0 TO n-1 DO ASSERT(b.text[i] = ORD("x"), 20) END
END StreamingChecks;

PROCEDURE Bad(text: ARRAY OF CHAR);
  VAR b: Capture; p: P.Parser; output: Mem.Channel; res: M.Msg;
BEGIN
  b := NewCapture(); p := Document(text, b);
  IF p.errList.msgCount = 0 THEN Out.String("Accepted: "); Out.String(text); Out.Ln END;
  ASSERT(p.errList.msgCount > 0, 21);
  output := Mem.Tmp("", {Mem.read, Mem.write}, res); p.errList.Write(output);
  ASSERT(output.Length() > 0, 22); output.Close
END Bad;

PROCEDURE MissingBaseChecks;
  VAR bytes: ARRAY 8 OF CHAR; b: Capture; p: P.Parser; ch, output: Mem.Channel; res: M.Msg;
BEGIN
  bytes := "<r>"; bytes[3] := 0FFX; bytes[4] := "<"; bytes[5] := "/"; bytes[6] := "r"; bytes[7] := ">";
  ch := File(bytes, 8); b := NewCapture(); p := P.NewChannel(ch, NIL, NIL, NIL, b);
  p.ParseDocument; ASSERT(p.errList.msgCount > 0, 27);
  output := Mem.Tmp("", {Mem.read, Mem.write}, res); p.errList.Write(output);
  ASSERT(output.Length() > 0, 28); output.Close; ch.Close
END MissingBaseChecks;

BEGIN
  base := URIParser.NewURI("file:/xml-tests/document.xml", NIL, result); ASSERT(result = NIL, 23);
  CharacterClassChecks; BasicChecks; DTDChecks; UnicodeChecks; StreamingChecks; MissingBaseChecks;
  Bad(""); Bad("<r>"); Bad("<r></s>"); Bad("<r/><s/>"); Bad('<r a="1" a="2"/>');
  Bad("<r>&missing;</r>"); Bad("<r>&#0;</r>"); Bad("<r>&#xD800;</r>"); Bad("<r>&#x110000;</r>");
  Bad("<r><!--a--b--></r>"); Bad("<r><![CDATA[open</r>"); Bad('<r a="<"/>');
  Bad('<!DOCTYPE r [<!ENTITY a "&a;">]><r>&a;</r>');
  Out.String("XML parser checks passed"); Out.Ln
END TestParser.
