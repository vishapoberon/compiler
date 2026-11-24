MODULE TestProtocol;

IMPORT Out, S := LongStrings, M := Msg, Mem := IOMemory, Ch := Channel,
  URI, URIParser, D := XMLDTD, B := XMLBuilder, N := XMLBuilderNamespaces,
  V := XMLBuilderValidation, P := XMLParser, Protocol := XMLBuilderParserProtocol,
  C := XMLUnicodeCodec, XMLUnicodeCodecImportAll;

TYPE
  Capture = POINTER TO CaptureDesc;
  CaptureDesc = RECORD (B.BuilderDesc)
    starts, ends, elements, attributes, characters, comments, instructions,
    cdataStarts, cdataEnds, entityStarts, entityEnds, entities, notations,
    namespaces, dtdStarts, dtdEnds, locators, positions, skipped, armenian, high, low: LONGINT;
  END;

VAR base: URI.URI; result: M.Msg;

PROCEDURE (b: Capture) StartElement(namespaceDecl: D.NamespaceDeclaration; name: D.String);
BEGIN
  IF S.Equal8(name^, "start-document") THEN INC(b.starts)
  ELSIF S.Equal8(name^, "end-document") THEN INC(b.ends)
  ELSIF S.Equal8(name^, "start-element") THEN INC(b.elements)
  ELSIF S.Equal8(name^, "attribute") THEN INC(b.attributes)
  ELSIF S.Equal8(name^, "characters") THEN INC(b.characters)
  ELSIF S.Equal8(name^, "comment") THEN INC(b.comments)
  ELSIF S.Equal8(name^, "processing-instruction") THEN INC(b.instructions)
  ELSIF S.Equal8(name^, "start-cdata") THEN INC(b.cdataStarts)
  ELSIF S.Equal8(name^, "end-cdata") THEN INC(b.cdataEnds)
  ELSIF S.Equal8(name^, "start-entity") THEN INC(b.entityStarts)
  ELSIF S.Equal8(name^, "end-entity") THEN INC(b.entityEnds)
  ELSIF S.Equal8(name^, "entity") THEN INC(b.entities)
  ELSIF S.Equal8(name^, "notation") THEN INC(b.notations)
  ELSIF S.Equal8(name^, "namespace-declaration") THEN INC(b.namespaces)
  ELSIF S.Equal8(name^, "start-dtd") THEN INC(b.dtdStarts)
  ELSIF S.Equal8(name^, "end-dtd") THEN INC(b.dtdEnds)
  ELSIF S.Equal8(name^, "locator") THEN INC(b.locators)
  ELSIF S.Equal8(name^, "char-index") THEN INC(b.positions)
  ELSIF S.Equal8(name^, "skipped-entity") THEN INC(b.skipped)
  END
END StartElement;

PROCEDURE (b: Capture) Characters(VAR chars: D.StringVar; start, end: D.CharPos;
  elementWhitespace: D.ElementWhitespaceType);
  VAR i: LONGINT;
BEGIN
  FOR i := start TO end-1 DO
    IF chars[i] = 531H THEN INC(b.armenian)
    ELSIF chars[i] = 0D83DH THEN INC(b.high)
    ELSIF chars[i] = 0DE42H THEN INC(b.low)
    END
  END
END Characters;

PROCEDURE Memory(): Mem.Channel;
  VAR ch: Mem.Channel; res: M.Msg;
BEGIN
  ch := Mem.Tmp("", {Mem.read, Mem.write}, res); ASSERT(res = NIL, 201); RETURN ch
END Memory;

PROCEDURE Trace(text: ARRAY OF CHAR; uri: URI.URI; namespaces, validating, valid: BOOLEAN): Capture;
  VAR input, output: Mem.Channel; writer: Ch.Writer; protocol: Protocol.Builder;
    builder: B.Builder; p: P.Parser; capture: Capture;
    msg: M.Msg; error: ARRAY 1024 OF CHAR;
BEGIN
  input := Memory(); writer := input.NewWriter(); writer.WriteBytes(text, 0, S.Length8(text));
  output := Memory(); protocol := Protocol.New(output, C.GetFactory("UTF-8"));
  builder := protocol;
  IF namespaces THEN builder := N.New(builder) END;
  IF validating THEN builder := V.New(builder) END;
  p := P.NewChannel(input, uri, NIL, NIL, builder);
  p.followExternalRef := FALSE; p.enforceQNames := namespaces; p.validating := validating;
  p.ParseDocument;
  IF (p.errList.msgCount = 0) # valid THEN
    Out.String(text); Out.Ln; msg := p.errList.msgList;
    WHILE msg # NIL DO msg.GetText(error); Out.String(error); Out.Ln; msg := msg.nextMsg END
  END;
  ASSERT((p.errList.msgCount = 0) = valid, 202);
  ASSERT((protocol.locator # NIL) & (protocol.w.writer.res = NIL) &
    (protocol.w.codec.invalidChars = 0), 203);
  NEW(capture); B.Init(capture);
  capture.starts := 0; capture.ends := 0; capture.elements := 0; capture.attributes := 0;
  capture.characters := 0; capture.comments := 0; capture.instructions := 0;
  capture.cdataStarts := 0; capture.cdataEnds := 0; capture.entityStarts := 0; capture.entityEnds := 0;
  capture.entities := 0; capture.notations := 0; capture.namespaces := 0;
  capture.dtdStarts := 0; capture.dtdEnds := 0; capture.locators := 0; capture.positions := 0;
  capture.skipped := 0; capture.armenian := 0; capture.high := 0; capture.low := 0;
  p := P.NewChannel(output, base, NIL, NIL, capture); p.followExternalRef := FALSE;
  p.ParseDocument;
  ASSERT(p.errList.msgCount = 0, 204);
  ASSERT((capture.starts = 1) & (capture.ends = 1), 205);
  ASSERT(capture.locators > 0, 206);
  IF uri = NIL THEN ASSERT(capture.positions = 0, 207)
  ELSE ASSERT(capture.positions = capture.locators, 208)
  END;
  input.Close; output.Close; RETURN capture
END Trace;

PROCEDURE Checks;
  VAR b: Capture; text: ARRAY 100000 OF CHAR; pos, i: LONGINT;

  PROCEDURE Append(part: ARRAY OF CHAR);
    VAR j: LONGINT;
  BEGIN
    j := 0;
    WHILE part[j] # 0X DO text[pos] := part[j]; INC(pos); INC(j) END;
    text[pos] := 0X
  END Append;

BEGIN
  b := Trace('<!DOCTYPE r [<!ELEMENT r (#PCDATA)><!ATTLIST r a CDATA "A"><!ENTITY e "x"><!NOTATION n SYSTEM "n">]><r><!--comment--><?pi data?><![CDATA[y]]>&e;</r>', base, FALSE, TRUE, TRUE);
  ASSERT((b.elements = 1) & (b.attributes = 1) & (b.comments = 1) & (b.instructions = 1), 209);
  ASSERT((b.dtdStarts = 1) & (b.dtdEnds = 1) & (b.notations = 1), 210);
  ASSERT((b.cdataStarts = 1) & (b.cdataEnds = 1) & (b.entityStarts = 1) & (b.entityEnds = 1), 211);
  b := Trace('<r/>', NIL, FALSE, FALSE, TRUE); ASSERT(b.elements = 1, 212);
  b := Trace('<r><a></r>', base, FALSE, FALSE, FALSE); ASSERT(b.elements = 2, 213);
  b := Trace('<!DOCTYPE r [<!ENTITY e SYSTEM "unopened.ent">]><r>&e;</r>', base, FALSE, FALSE, TRUE);
  ASSERT((b.skipped > 0) & (b.dtdEnds = 1), 214);
  pos := 0; Append('<p:'); Append(0D4X); Append(0B1X);
  Append(' xmlns:p="urn:'); Append(0D4X); Append(0B1X);
  Append('" a="&#x531;&#x1F642;&#13;&#10;&#9;">&#x531;&#x1F642;</p:');
  Append(0D4X); Append(0B1X); Append('>');
  b := Trace(text, base, TRUE, FALSE, TRUE);
  ASSERT((b.namespaces >= 2) & (b.armenian >= 3) & (b.high = 2) & (b.low = 2), 215);
  pos := 0; Append('<r>');
  FOR i := 0 TO 39999 DO Append('x') END;
  Append('&#x531;&#x1F642;');
  FOR i := 0 TO 39999 DO Append('y') END;
  Append('</r>');
  b := Trace(text, base, FALSE, FALSE, TRUE);
  ASSERT((b.characters >= 1) & (b.armenian = 1) & (b.high = 1) & (b.low = 1), 216)
END Checks;

BEGIN
  base := URIParser.NewURI("file:/xml-tests/document.xml", NIL, result); ASSERT(result = NIL, 217);
  Checks; Out.String("XML parser protocol checks passed"); Out.Ln
END TestProtocol.
