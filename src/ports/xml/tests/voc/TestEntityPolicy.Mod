MODULE TestEntityPolicy;

IMPORT Out, S := LongStrings, M := Msg, Mem := IOMemory, Ch := Channel,
  URI, URIParser, D := XMLDTD, B := XMLBuilder, P := XMLParser,
  R := XMLEntityResolver, L := XMLLimits, XMLUnicodeCodecImportAll;

TYPE
  Resource = POINTER TO ResourceDesc;
  ResourceDesc = RECORD (URI.URIDesc)
    text: POINTER TO ARRAY OF CHAR;
  END;
  Resolver = POINTER TO ResolverDesc;
  ResolverDesc = RECORD (R.ResolverDesc)
    resource, externalDTD: Resource;
  END;
  Capture = POINTER TO CaptureDesc;
  CaptureDesc = RECORD (B.BuilderDesc)
    text: ARRAY 1024 OF D.Char; length, skipped, ends: LONGINT;
  END;

VAR base: URI.URI; result: M.Msg; opens: LONGINT;

PROCEDURE (resource: Resource) GetString(VAR text: ARRAY OF CHAR);
BEGIN COPY("memory:external-test", text) END GetString;

PROCEDURE (resource: Resource) GetChannel(mode: URI.ChannelMode; VAR res: M.Msg): Ch.Channel;
  VAR channel: Mem.Channel; writer: Ch.Writer;
BEGIN
  ASSERT(mode = URI.channelOld, 1); INC(opens);
  channel := Mem.Tmp("", {Mem.read, Mem.write}, res); ASSERT(res = NIL, 2);
  writer := channel.NewWriter(); writer.WriteBytes(resource.text^, 0, S.Length8(resource.text^));
  RETURN channel
END GetChannel;

PROCEDURE (resolver: Resolver) GetURI(public, system: D.String; base: URI.URI;
  VAR uri: URI.URI; VAR res: M.Msg);
BEGIN
  IF (resolver.externalDTD # NIL) & (system # NIL) & S.Equal8(system^, "external.dtd") THEN
    uri := resolver.externalDTD
  ELSE uri := resolver.resource
  END;
  res := NIL
END GetURI;

PROCEDURE (capture: Capture) Characters(VAR text: D.StringVar; start, end: D.CharPos;
  elementWhitespace: D.ElementWhitespaceType);
  VAR i: LONGINT;
BEGIN
  FOR i := start TO end-1 DO
    ASSERT(capture.length < LEN(capture.text)-1, 3);
    capture.text[capture.length] := text[i]; INC(capture.length)
  END;
  capture.text[capture.length] := 0
END Characters;

PROCEDURE (capture: Capture) SkippedEntity(name: D.String; referent: D.Entity);
BEGIN INC(capture.skipped) END SkippedEntity;

PROCEDURE (capture: Capture) EndDocument;
BEGIN INC(capture.ends) END EndDocument;

PROCEDURE Check(text, replacement: ARRAY OF CHAR; follow, valid: BOOLEAN;
  expectedOpens: LONGINT; expectedText: ARRAY OF CHAR): Capture;
  VAR resolver: Resolver; input: Mem.Channel; writer: Ch.Writer;
    parser: P.Parser; capture: Capture; msg: M.Msg; error: ARRAY 1024 OF CHAR;
BEGIN
  NEW(resolver); NEW(resolver.resource);
  resolver.externalDTD := NIL;
  URI.InitURI(resolver.resource, NIL);
  NEW(resolver.resource.text, S.Length8(replacement)+1); COPY(replacement, resolver.resource.text^);
  NEW(capture); B.Init(capture); capture.length := 0; capture.text[0] := 0;
  capture.skipped := 0; capture.ends := 0;
  input := Mem.Tmp("", {Mem.read, Mem.write}, result); ASSERT(result = NIL, 4);
  writer := input.NewWriter(); writer.WriteBytes(text, 0, S.Length8(text));
  parser := P.NewChannel(input, base, NIL, resolver, capture); parser.followExternalRef := follow;
  opens := 0; parser.ParseDocument; input.Close;
  IF (opens # expectedOpens) OR ((parser.errList.msgCount = 0) # valid) THEN
    Out.String(text); Out.Ln; Out.String("External opens: "); Out.Int(opens, 0); Out.Ln;
    msg := parser.errList.msgList;
    WHILE msg # NIL DO msg.GetText(error); Out.String(error); Out.Ln; msg := msg.nextMsg END
  END;
  ASSERT(opens = expectedOpens, 5); ASSERT((parser.errList.msgCount = 0) = valid, 6);
  ASSERT((capture.ends = 1) & S.Equal8(capture.text, expectedText), 7);
  RETURN capture
END Check;

PROCEDURE InternalizedEncoding;
  VAR resolver: Resolver; input: Mem.Channel; writer: Ch.Writer; parser: P.Parser;
    msg: M.Msg; found: BOOLEAN; text: ARRAY 64 OF CHAR;
BEGIN
  NEW(resolver); NEW(resolver.resource); NEW(resolver.externalDTD);
  URI.InitURI(resolver.resource, NIL); URI.InitURI(resolver.externalDTD, NIL);
  NEW(resolver.resource.text, 2); resolver.resource.text[0] := 0FFX;
  resolver.resource.text[1] := 0X;
  NEW(resolver.externalDTD.text, 128);
  COPY('<!ENTITY % e SYSTEM "external.ent"><!ENTITY x "%e;">', resolver.externalDTD.text^);
  input := Mem.Tmp("", {Mem.read, Mem.write}, result); ASSERT(result = NIL, 10);
  writer := input.NewWriter();
  text := '<!DOCTYPE r SYSTEM "external.dtd"><r/>';
  writer.WriteBytes(text, 0, S.Length8(text));
  parser := P.NewChannel(input, base, NIL, resolver, B.New()); parser.followExternalRef := TRUE;
  opens := 0; parser.ParseDocument;
  ASSERT(opens = 2, 11);
  found := FALSE; msg := parser.errList.msgList;
  WHILE msg # NIL DO IF msg.code = 27 THEN found := TRUE END; msg := msg.nextMsg END;
  ASSERT(found, 12); input.Close
END InternalizedEncoding;

PROCEDURE BudgetedExternal(text, dtd, replacement: ARRAY OF CHAR; repeats: LONGINT);
  VAR resolver: Resolver; input: Mem.Channel; writer: Ch.Writer; parser: P.Parser;
    budget: L.Budget; msg: M.Msg; i, size, matches: LONGINT;
BEGIN
  NEW(resolver); NEW(resolver.resource); NEW(resolver.externalDTD);
  URI.InitURI(resolver.resource, NIL); URI.InitURI(resolver.externalDTD, NIL);
  NEW(resolver.resource.text, S.Length8(replacement)+1); COPY(replacement, resolver.resource.text^);
  NEW(resolver.externalDTD.text, S.Length8(dtd)+1); COPY(dtd, resolver.externalDTD.text^);
  size := S.Length8(text)+S.Length8(dtd)+repeats*S.Length8(replacement);
  FOR i := 0 TO size+1 DO
    input := Mem.Tmp("", {Mem.read, Mem.write}, result); ASSERT(result = NIL, 20);
    writer := input.NewWriter(); writer.WriteBytes(text, 0, S.Length8(text));
    budget := L.New(); budget.maxInputBytes := i;
    parser := P.NewReaderLimited(input.NewReader(), base, NIL, resolver, B.New(), budget);
    parser.followExternalRef := TRUE; opens := 0; parser.ParseDocument;
    ASSERT((budget.error # NIL) = (i < size), 21);
    ASSERT(parser.aborted = (i < size), 22); ASSERT(budget.depth = 0, 23);
    IF budget.error # NIL THEN
      ASSERT(budget.error.code = L.codeBase+L.inputBytes, 24);
      matches := 0; msg := parser.errList.msgList;
      WHILE msg # NIL DO
        IF msg = budget.error THEN INC(matches) END;
        msg := msg.nextMsg
      END;
      ASSERT(matches = 1, 25)
    ELSE ASSERT(parser.errList.msgCount = 0, 26)
    END;
    input.Close
  END
END BudgetedExternal;

PROCEDURE ExpansionBeforeOpen;
  VAR resolver: Resolver; input: Mem.Channel; writer: Ch.Writer; parser: P.Parser;
    budget: L.Budget; text: ARRAY 128 OF CHAR;
BEGIN
  NEW(resolver); NEW(resolver.resource); NEW(resolver.externalDTD);
  URI.InitURI(resolver.resource, NIL); URI.InitURI(resolver.externalDTD, NIL);
  NEW(resolver.resource.text, 16); COPY('external text', resolver.resource.text^);
  NEW(resolver.externalDTD.text, 128);
  COPY('<!ENTITY % p SYSTEM "external.ent"><!ENTITY e "%p;">', resolver.externalDTD.text^);
  input := Mem.Tmp("", {Mem.read, Mem.write}, result); ASSERT(result = NIL, 30);
  writer := input.NewWriter(); text := '<!DOCTYPE r SYSTEM "external.dtd"><r/>';
  writer.WriteBytes(text, 0, S.Length8(text));
  budget := L.New(); budget.maxEntityExpansions := 1;
  parser := P.NewReaderLimited(input.NewReader(), base, NIL, resolver, B.New(), budget);
  opens := 0; parser.ParseDocument;
  ASSERT(parser.aborted & (opens = 1), 31); ASSERT(budget.depth = 0, 32);
  ASSERT(budget.error.code = L.codeBase+L.entityExpansions, 33); input.Close
END ExpansionBeforeOpen;

PROCEDURE Checks;
  VAR capture: Capture;
BEGIN
  capture := Check('<!DOCTYPE r SYSTEM "external.dtd"><r/>', '<!ELEMENT r EMPTY>', FALSE, TRUE, 0, "");
  capture := Check('<!DOCTYPE r SYSTEM "external.dtd"><r/>', '<!ELEMENT r EMPTY>', TRUE, TRUE, 1, "");
  capture := Check('<!DOCTYPE r [<!ENTITY e SYSTEM "external.ent">]><r>&e;</r>', "external text", FALSE, TRUE, 0, "");
  ASSERT(capture.skipped = 1, 8);
  capture := Check('<!DOCTYPE r [<!ENTITY e SYSTEM "external.ent">]><r>&e;</r>', "external text", TRUE, TRUE, 1, "external text");
  capture := Check('<!DOCTYPE r [<!ENTITY % e SYSTEM "external.ent">%e;]><r/>', '<!ELEMENT r EMPTY>', FALSE, TRUE, 0, "");
  capture := Check('<!DOCTYPE r [<!ENTITY % e SYSTEM "external.ent">%e;]><r/>', '<!ELEMENT r EMPTY>', TRUE, TRUE, 1, "");
  capture := Check('<!DOCTYPE r [<!ENTITY % e SYSTEM "external.ent"><!ENTITY x "%e;">]><r/>', "private text", FALSE, FALSE, 0, "");
  capture := Check('<!DOCTYPE r [<!ENTITY e SYSTEM "external.ent"><!ENTITY x "&e;">]><r a="&x;"/>', "private text", FALSE, FALSE, 0, "");
  capture := Check('<!DOCTYPE r [<!ENTITY e SYSTEM "external.ent" NDATA n><!NOTATION n SYSTEM "n">]><r/>', "private text", FALSE, TRUE, 0, "");
  capture := Check('<!DOCTYPE r [<!ENTITY a "&b;"><!ENTITY b "&a;">]><r/>', "", FALSE, FALSE, 0, "");
  capture := Check('<!DOCTYPE r [<!ENTITY a "&a;">]><r a="&a;"/>', "", FALSE, FALSE, 0, "");
  capture := Check('<!DOCTYPE r [<!ENTITY % e SYSTEM "external.ent">%e;]><r/>', "%e;", TRUE, FALSE, 1, "");
  capture := Check('<!DOCTYPE r [<!ENTITY % e SYSTEM "external.ent">%e;]><r/>', '<!ENTITY % b "%e;">%b;', TRUE, FALSE, 1, "")
END Checks;

BEGIN
  base := URIParser.NewURI("file:/xml-tests/document.xml", NIL, result); ASSERT(result = NIL, 9);
  Checks; InternalizedEncoding; ExpansionBeforeOpen;
  BudgetedExternal('<!DOCTYPE r SYSTEM "external.dtd"><r>&e;&e;</r>',
    '<!ENTITY e SYSTEM "external.ent">', 'external text', 2);
  BudgetedExternal('<!DOCTYPE r SYSTEM "external.dtd"><r a="&e;">&e;</r>',
    '<!ENTITY % p SYSTEM "external.ent"><!ENTITY e "%p;">', 'external text', 1);
  BudgetedExternal('<!DOCTYPE r SYSTEM "external.dtd"><r/>',
    '<![INCLUDE[<![INCLUDE[<!ELEMENT r EMPTY>]]>]]>', '', 0);
  Out.String("XML external entity policy checks passed"); Out.Ln
END TestEntityPolicy.
