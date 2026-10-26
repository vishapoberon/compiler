MODULE TestXmppStream;

IMPORT Out, SYSTEM, S := LongStrings, Msg, Channel, Mem := IOMemory,
  T := XmppTypes, Items := XmppItems, X := XmppXmlStream,
  Gen := XmppXmlGen, C := XmppConnections;

TYPE
  Owner = POINTER TO OwnerDesc;
  OwnerDesc = RECORD (C.OwnerDesc)
    opened, received, written, closed, errors: LONGINT;
    last: Items.Item;
  END;
  PartialWriter = POINTER TO PartialWriterDesc;
  PartialWriterDesc = RECORD (Channel.WriterDesc)
    inner: Channel.Writer;
    remaining: LONGINT;
    failure: Msg.Msg;
  END;

PROCEDURE (w: PartialWriter) WriteBytes(VAR bytes: ARRAY OF SYSTEM.BYTE; start, count: LONGINT);
BEGIN
  w.bytesWritten := 0;
  IF w.res # NIL THEN RETURN END;
  IF count > 3 THEN count := 3 END;
  IF (w.remaining >= 0) & (count > w.remaining) THEN count := w.remaining END;
  IF count > 0 THEN
    w.inner.WriteBytes(bytes, start, count); w.bytesWritten := w.inner.bytesWritten;
    w.res := w.inner.res;
    IF w.remaining >= 0 THEN DEC(w.remaining, w.bytesWritten) END
  END;
  IF w.remaining = 0 THEN w.res := w.failure END
END WriteBytes;

PROCEDURE (o: Owner) Opened(header: Items.Item);
BEGIN INC(o.opened) END Opened;
PROCEDURE (o: Owner) UpdateRead(item: Items.Item);
BEGIN INC(o.received); o.last := item END UpdateRead;
PROCEDURE (o: Owner) UpdateWrite(item: Items.Item);
BEGIN INC(o.written) END UpdateWrite;
PROCEDURE (o: Owner) UpdateError(error: Msg.Msg);
BEGIN INC(o.errors) END UpdateError;
PROCEDURE (o: Owner) Closed;
BEGIN INC(o.closed) END Closed;

PROCEDURE Feed(s: X.Stream; text: ARRAY OF CHAR): SHORTINT;
  VAR n: LONGINT;
BEGIN RETURN s.Feed(text, 0, S.Length8(text), n) END Feed;

PROCEDURE BodyChecks(item: Items.Item);
  VAR body: Items.Item; text, expected: T.String;
BEGIN
  ASSERT(item # NIL); ASSERT(S.Equal8(item.name^, "message"));
  ASSERT(item.namespaceURI^ = "jabber:client");
  text := item.GetAttribute("", "id"); ASSERT(S.Equal8(text^, "a>b"));
  body := item.First("jabber:client", "body"); ASSERT(body # NIL);
  text := body.Text(); expected := Items.UTF8("Հայերեն 😀 & <there>");
  ASSERT(S.Equal(text^, expected^));
  ASSERT((text[8] = 0D83DH) & (text[9] = 0DE00H));
  ASSERT((item.content.text # NIL) & (item.content.next.element = body) &
    (item.content.next.next.text # NIL));
  text := item.Text(); ASSERT(S.Equal8(text^, "beforeafter"))
END BodyChecks;

PROCEDURE SplitChecks;
  VAR wire: ARRAY 1024 OF CHAR; length, chunk, pos, stop, n, events: LONGINT;
    event: SHORTINT; s: X.Stream;
BEGIN
  wire := '<?xml version="1.0"?><s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" xml:lang="hy"><message id="a&gt;b">before<body>Հայերեն 😀 &amp; <![CDATA[<there>]]></body>after</message><presence/></s:stream>';
  length := S.Length8(wire);
  FOR chunk := 1 TO length DO
    s := X.New(); pos := 0; events := 0;
    WHILE pos < length DO
      stop := pos+chunk; IF stop > length THEN stop := length END;
      event := s.Feed(wire, pos, stop-pos, n); ASSERT(n > 0); INC(pos, n);
      ASSERT(event # X.failed);
      IF event # X.needInput THEN
        INC(events);
        IF events = 1 THEN ASSERT(event = X.opened)
        ELSIF events = 2 THEN ASSERT(event = X.stanza); BodyChecks(s.item)
        ELSIF events = 3 THEN ASSERT((event = X.stanza) & S.Equal8(s.item.name^, "presence"))
        ELSE ASSERT(event = X.closed)
        END
      END
    END;
    ASSERT((events = 4) & s.Finish())
  END;
  Out.String("XMPP Unicode split checks passed: "); Out.Int(length, 0); Out.Ln
END SplitChecks;

PROCEDURE RestartChecks;
  VAR s: X.Stream; wire: ARRAY 256 OF CHAR; n: LONGINT;
BEGIN
  s := X.New(); ASSERT(Feed(s, '<s:stream xmlns:s="http://etherx.jabber.org/streams">') = X.opened);
  wire := '<proceed xmlns="urn:ietf:params:xml:ns:xmpp-tls"/>TLS-RECORD';
  ASSERT(s.Feed(wire, 0, S.Length8(wire), n) = X.stanza);
  ASSERT((wire[n] = "T") & (n = S.Length8(wire)-10));
  ASSERT(s.Restart()); ASSERT(s.header = NIL);
  ASSERT(Feed(s, '<stream:stream xmlns:stream="http://etherx.jabber.org/streams">') = X.opened);
  ASSERT(Feed(s, '<success xmlns="urn:ietf:params:xml:ns:xmpp-sasl"/>') = X.stanza);
  ASSERT(s.Restart());
  ASSERT(Feed(s, '<t:stream xmlns:t="http://etherx.jabber.org/streams">') = X.opened);
  ASSERT(Feed(s, '<t:features/>') = X.stanza);
  ASSERT(Feed(s, '</t:stream>') = X.closed); ASSERT(s.Finish())
END RestartChecks;

PROCEDURE RejectionChecks;
  VAR s: X.Stream;
BEGIN
  s := X.New(); ASSERT(Feed(s, '<stream>') = X.failed); ASSERT(s.item = NIL);
  s := X.New(); ASSERT(Feed(s, '<s:stream xmlns:s="urn:wrong">') = X.failed);
  s := X.New(); ASSERT(Feed(s, '<s:stream xmlns:s="http://etherx.jabber.org/streams">') = X.opened);
  ASSERT(Feed(s, '<message><x></message></x>') = X.failed); ASSERT(s.item = NIL); ASSERT(~s.Restart());
  s := X.NewLimited(128, 128, 4, 2);
  ASSERT(Feed(s, '<s:stream xmlns:s="http://etherx.jabber.org/streams">') = X.opened);
  ASSERT(Feed(s, '<x><y/></x>') = X.failed); ASSERT(s.item = NIL);
  s := X.New(); ASSERT(Feed(s, '<s:stream xmlns:s="http://etherx.jabber.org/streams">') = X.opened);
  ASSERT(~s.Finish()); ASSERT(s.error # NIL)
END RejectionChecks;

PROCEDURE WriterChecks;
  VAR item, child: Items.Item; text, name, value: T.String; bytes: Items.Bytes;
    length: LONGINT; error: Msg.Msg; s: X.Stream; n: LONGINT;
BEGIN
  item := Items.New("message", "jabber:client"); text := Items.UTF8("person@example.org/Հայերեն");
  item.SetParam("to", text^); value := Items.Latin1("a>b"); item.SetParam("id", value^);
  child := Items.New("body", "jabber:client"); text := Items.UTF8("Հայերեն 😀 & <there>");
  child.AddText(text^, 0, S.Length(text^)); item.AddChild(child);
  name := Items.Latin1("lang"); value := Items.Latin1("hy");
  item.SetAttribute(name^, "http://www.w3.org/XML/1998/namespace", value^);
  name := Items.Latin1("key"); item.SetAttribute(name^, "urn:test", text^);
  Gen.Encode(item, 4096, bytes, length, error); ASSERT((error = NIL) & (length > 0));
  s := X.New(); ASSERT(Feed(s, '<s:stream xmlns:s="http://etherx.jabber.org/streams">') = X.opened);
  ASSERT(s.Feed(bytes^, 0, length, n) = X.stanza); ASSERT(n = length);
  value := s.item.GetAttribute("urn:test", "key"); ASSERT(S.Equal(value^, text^));
  child := s.item.First("jabber:client", "body"); value := child.Text(); ASSERT(S.Equal(value^, text^));
  Gen.Encode(item, 8, bytes, length, error); ASSERT((error # NIL) & (bytes = NIL) & (length = 0));
  item := Items.New("bad name", "jabber:client");
  Gen.Encode(item, 4096, bytes, length, error); ASSERT((error # NIL) & (bytes = NIL));
  item := Items.New("x", "jabber:client"); text := Items.Latin1("x"); text[0] := 1;
  item.AddText(text^, 0, 1); Gen.Encode(item, 4096, bytes, length, error); ASSERT(error # NIL)
END WriterChecks;

PROCEDURE BadName(name: ARRAY OF CHAR; attribute: BOOLEAN);
  VAR item: Items.Item; units, value: T.String; bytes: Items.Bytes; length: LONGINT; error: Msg.Msg;
BEGIN
  IF attribute THEN
    item := Items.New("x", "jabber:client"); units := Items.Latin1(name); value := Items.Latin1("v");
    item.SetAttribute(units^, "", value^)
  ELSE item := Items.New(name, "jabber:client")
  END;
  Gen.Encode(item, 4096, bytes, length, error); ASSERT((error # NIL) & (bytes = NIL) & (length = 0))
END BadName;

PROCEDURE OutputChecks;
  VAR o: Owner; c: C.Connection; ch, denied: Mem.Channel; error, expectedError: Msg.Msg;
    writer: PartialWriter; s: X.Stream; bytes: Items.Bytes; to, empty, lang: T.String;
    pos, n, length, events: LONGINT; event: SHORTINT; item: Items.Item;
BEGIN
  NEW(o); ch := Mem.Tmp("", {Mem.read, Mem.write}, error); ASSERT(error = NIL);
  NEW(writer); writer.inner := ch.NewWriter(); writer.remaining := -1;
  c := C.New(o, writer); to := Items.UTF8("example.org"); empty := Items.Latin1(""); lang := Items.Latin1("hy");
  c.OpenStream(to^, empty^, empty^, lang^, error); ASSERT(error = NIL);
  item := Items.New("presence", "jabber:client"); c.WriteData(item, error); ASSERT(error = NIL);
  c.CloseStream(error); ASSERT((error = NIL) & (o.written = 1) & (c.wroteBytes = ch.Length()));
  s := X.New(); pos := 0; events := 0; length := ch.Length();
  REPEAT
    event := s.Feed(ch.file.data^, pos, length-pos, n); INC(pos, n); INC(events);
    ASSERT((event # X.failed) & (n > 0))
  UNTIL event = X.closed;
  ASSERT((events = 3) & (pos = length) & s.Finish()); ch.Close;
  denied := Mem.Tmp("", {}, expectedError); ASSERT(expectedError # NIL);
  ch := Mem.Tmp("", {Mem.read, Mem.write}, error); ASSERT(error = NIL);
  NEW(writer); writer.inner := ch.NewWriter(); writer.remaining := 3; writer.failure := expectedError;
  NEW(o); c := C.New(o, writer); c.WriteData(item, error);
  ASSERT((error = expectedError) & (c.writeError = error) & (c.wroteBytes = 3) & (o.written = 0));
  c.WriteData(item, error); ASSERT((error = expectedError) & (ch.Length() = 3));
  c.WriteData(NIL, error); ASSERT((error = expectedError) & (ch.Length() = 3)); ch.Close;
  ch := Mem.Tmp("", {Mem.read, Mem.write}, error); ASSERT(error = NIL);
  NEW(writer); writer.inner := ch.NewWriter(); writer.remaining := 0;
  NEW(o); c := C.New(o, writer); c.WriteData(item, error);
  ASSERT((error # NIL) & (c.writeError = error) & (c.wroteBytes = 0) & (o.written = 0)); ch.Close;
  to[0] := 1; Gen.OpenStream(to^, empty^, empty^, lang^, bytes, length, error);
  ASSERT((error # NIL) & (bytes = NIL) & (length = 0));
  ASSERT(Items.UTF8(0F0X) = NIL); ASSERT(Items.UTF8(80X) = NIL);
  BadName("x injected='yes'", FALSE); BadName("x injected='yes'", TRUE);
  BadName("p:x", FALSE); BadName("p:x", TRUE); BadName("xmlns", TRUE);
  BadName("", FALSE); BadName("1x", FALSE)
END OutputChecks;

PROCEDURE UTF8Checks;
  VAR text, decoded: T.String; bytes: Items.Bytes;
BEGIN
  text := Items.UTF8("Հայերեն 😀"); bytes := Items.UTF8Bytes(text^);
  ASSERT((bytes # NIL) & (bytes^ = "Հայերեն 😀"));
  decoded := Items.UTF8(bytes^); ASSERT(S.Equal(text^, decoded^));
  text := Items.Latin1(""); bytes := Items.UTF8Bytes(text^); ASSERT((bytes # NIL) & (bytes^ = ""));
  NEW(text, 4); text[0] := 0D800H; text[1] := 0; ASSERT(Items.UTF8Bytes(text^) = NIL);
  text[0] := 0DC00H; ASSERT(Items.UTF8Bytes(text^) = NIL);
  text[0] := 110000H; ASSERT(Items.UTF8Bytes(text^) = NIL);
  text[0] := -1; ASSERT(Items.UTF8Bytes(text^) = NIL)
END UTF8Checks;

PROCEDURE LongChecks;
  VAR s: X.Stream; wire: Items.Bytes; expected, actual: T.String; item, body: Items.Item;
    pos, length, n, count: LONGINT; event: SHORTINT; error: Msg.Msg;
BEGIN
  item := Items.New("message", "jabber:client"); body := Items.New("body", "jabber:client");
  NEW(expected, 40003);
  FOR pos := 0 TO 39999 DO expected[pos] := 531H END;
  expected[40000] := 0D83DH; expected[40001] := 0DE00H; expected[40002] := 0;
  body.AddText(expected^, 0, 40002); item.AddChild(body);
  Gen.Encode(item, 200000, wire, length, error); ASSERT(error = NIL);
  s := X.New(); ASSERT(Feed(s, '<s:stream xmlns:s="http://etherx.jabber.org/streams">') = X.opened);
  pos := 0;
  WHILE pos < length DO
    count := length-pos; IF count > 7 THEN count := 7 END;
    event := s.Feed(wire^, pos, count, n); ASSERT(n = count); INC(pos, n);
    IF pos < length THEN ASSERT(event = X.needInput) ELSE ASSERT(event = X.stanza) END
  END;
  body := s.item.First("jabber:client", "body"); actual := body.Text();
  ASSERT(S.Equal(actual^, expected^)); ASSERT(S.Length(actual^) = 40002)
END LongChecks;

PROCEDURE ConnectionChecks;
  VAR o: Owner; c: C.Connection; ch: Mem.Channel; error: Msg.Msg; bytes: ARRAY 256 OF CHAR;
    pos, n, length: LONGINT; event: SHORTINT; item: Items.Item;
BEGIN
  NEW(o); ch := Mem.Tmp("", {Mem.read, Mem.write}, error); ASSERT(error = NIL);
  c := C.New(o, ch.NewWriter());
  bytes := '<s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client"><presence/></s:stream>';
  pos := 0; length := S.Length8(bytes);
  REPEAT event := c.Feed(bytes, pos, length-pos, n); INC(pos, n) UNTIL event = X.closed;
  ASSERT((o.opened = 1) & (o.received = 1) & (o.closed = 1) & (o.errors = 0));
  ASSERT(c.readBytes = length); ASSERT(c.Finish());
  item := Items.New("presence", "jabber:client"); c.WriteData(item, error);
  ASSERT((error = NIL) & (o.written = 1) & (c.wroteBytes = ch.Length())); ch.Close
END ConnectionChecks;

BEGIN
  ASSERT((SIZE(T.SignedByte) = 1) & (MIN(T.SignedByte) = -128));
  ASSERT((SIZE(T.Int16) = 2) & (MIN(T.Int16) = -32768));
  ASSERT((SIZE(T.Int32) = 4) & (MAX(T.Int32) = 2147483647));
  ASSERT((SIZE(T.Int64) = 8) & (MAX(T.Int64) > MAX(T.Int32)));
  ASSERT((SIZE(T.WireByte) = 1) & (ORD(MAX(T.WireByte)) = 255));
  ASSERT((SIZE(T.CodeUnit) = 4) & (MAX(T.CodeUnit) >= 65535));
  SplitChecks; RestartChecks; RejectionChecks; WriterChecks; ConnectionChecks; OutputChecks; UTF8Checks; LongChecks;
  Out.String("XMPP stream, writer, connection and CP-width checks passed"); Out.Ln
END TestXmppStream.
