MODULE TestStream;

IMPORT Out, S := LongStrings, D := XMLDTD, B := XMLBuilder, St := XMLStream;

TYPE
  Capture = POINTER TO CaptureDesc;
  CaptureDesc = RECORD (B.BuilderDesc)
    starts, ends, depth, units: LONGINT;
    childName: D.String;
    childURI: D.StringURI;
    text: ARRAY 128 OF D.Char;
  END;

PROCEDURE (b: Capture) StartDocument(document: D.ExternalEntity);
BEGIN b.starts := 0; b.ends := 0; b.depth := 0; b.units := 0 END StartDocument;

PROCEDURE (b: Capture) StartElement(ns: D.NamespaceDeclaration; name: D.String);
BEGIN
  INC(b.starts); INC(b.depth);
  IF b.depth = 2 THEN
    b.childName := name;
    IF ns # NIL THEN b.childURI := ns.uri ELSE b.childURI := NIL END
  END
END StartElement;

PROCEDURE (b: Capture) EndElement(ns: D.NamespaceDeclaration; name: D.String);
BEGIN INC(b.ends); DEC(b.depth) END EndElement;

PROCEDURE (b: Capture) Characters(VAR chars: D.StringVar; start, end: D.CharPos;
                                whitespace: D.ElementWhitespaceType);
  VAR i: LONGINT;
BEGIN
  FOR i := start TO end-1 DO
    ASSERT(b.units < LEN(b.text)-1); b.text[b.units] := chars[i]; INC(b.units)
  END;
  b.text[b.units] := 0
END Characters;

PROCEDURE NewCapture(): Capture;
  VAR b: Capture;
BEGIN NEW(b); B.Init(b); RETURN b END NewCapture;

PROCEDURE Feed(s: St.Stream; text: ARRAY OF CHAR; b: Capture): SHORTINT;
  VAR n: LONGINT;
BEGIN RETURN s.Feed(text, 0, S.Length8(text), b, n) END Feed;

PROCEDURE Checks;
  VAR s: St.Stream; b: Capture; bytes: ARRAY 1024 OF CHAR;
    split, pos, stop, n, event, length, events: LONGINT;
BEGIN
  ASSERT((SIZE(CHAR) = 1) & (SIZE(INTEGER) = 2) &
    (SIZE(LONGINT) = 4) & (SIZE(HUGEINT) = 8) & (SIZE(D.Char) = 4));
  bytes := '<?xml version="1.0" encoding="UTF-8"?><s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" xmlns:p="urn:test"><message id="a&gt;b"><body>hi &amp; <![CDATA[<there>]]></body></message><p:x/><presence/></s:stream>';
  length := S.Length8(bytes);
  FOR split := 1 TO length DO
    s := St.New(512, 512, 16); b := NewCapture(); pos := 0; events := 0;
    WHILE pos < length DO
      stop := pos+split; IF stop > length THEN stop := length END;
      event := s.Feed(bytes, pos, stop-pos, b, n); ASSERT(n > 0); INC(pos, n);
      ASSERT(event # St.failed);
      IF event # St.needInput THEN
        INC(events);
        CASE events OF
        | 1: ASSERT((event = St.opened) & (b.starts = 1) & (b.ends = 1))
        | 2: ASSERT((event = St.stanza) & (b.starts = 3) & S.Equal8(b.text, "hi & <there>"));
             ASSERT(S.Equal8(b.childName^, "message") & (b.childURI^ = "jabber:client"))
        | 3: ASSERT((event = St.stanza) & S.Equal8(b.childName^, "x") & (b.childURI^ = "urn:test"))
        | 4: ASSERT((event = St.stanza) & (b.childURI^ = "jabber:client"))
        | 5: ASSERT(event = St.closed)
        ELSE HALT(99)
        END
      END
    END;
    ASSERT((events = 5) & s.Finish())
  END;
  s := St.New(128, 128, 4); b := NewCapture();
  ASSERT(Feed(s, '<r xmlns="urn:first">', b) = St.opened);
  ASSERT(Feed(s, '<x xmlns="urn:second"/>', b) = St.stanza); ASSERT(b.childURI^ = "urn:second");
  ASSERT(Feed(s, '<x/>', b) = St.stanza); ASSERT(b.childURI^ = "urn:first");
  ASSERT(Feed(s, '   ', b) = St.needInput);
  ASSERT(Feed(s, '<success/>TLS-BYTES', b) = St.stanza);
  ASSERT(s.Restart());
  ASSERT(Feed(s, '<r xmlns="urn:third">', b) = St.opened);
  ASSERT(Feed(s, '<x/>', b) = St.stanza); ASSERT(b.childURI^ = "urn:third");
  ASSERT(Feed(s, '<x', b) = St.needInput); ASSERT(~s.Restart());
  ASSERT(~s.Finish()); ASSERT(s.error # NIL);
  Out.String("XML element stream split checks passed: "); Out.Int(length, 0); Out.Ln
END Checks;

PROCEDURE Bad(text: ARRAY OF CHAR; header, stanza, nesting: LONGINT);
  VAR s: St.Stream; b: Capture; pos, n, length: LONGINT; event: SHORTINT;
BEGIN
  s := St.New(header, stanza, nesting); b := NewCapture(); pos := 0; length := S.Length8(text);
  REPEAT
    event := s.Feed(text, pos, length-pos, b, n); INC(pos, n)
  UNTIL (event = St.failed) OR (event = St.closed) OR (pos = length);
  IF event # St.failed THEN ASSERT(~s.Finish()) END;
  ASSERT(s.error # NIL); ASSERT(~s.Restart())
END Bad;

PROCEDURE Exercise(VAR bytes: ARRAY OF CHAR; length, chunk: LONGINT);
  VAR s: St.Stream; builder: B.Builder; pos, stop, n: LONGINT; event: SHORTINT; finished: BOOLEAN;
BEGIN
  s := St.New(512, 1024, 16); builder := B.New(); pos := 0; event := St.needInput;
  WHILE (pos < length) & (event # St.failed) & (event # St.closed) DO
    stop := pos+chunk; IF stop > length THEN stop := length END;
    event := s.Feed(bytes, pos, stop-pos, builder, n); ASSERT(n > 0); INC(pos, n)
  END;
  finished := s.Finish(); ASSERT(finished = (event = St.closed));
  IF ~finished THEN ASSERT(s.error # NIL) END
END Exercise;

PROCEDURE MutationChecks;
  VAR original, bytes: ARRAY 256 OF CHAR; length, pos, i, n: LONGINT;
BEGIN
  original := '<?xml version="1.0"?><r xmlns="urn:test"><x a="&gt;">&#x1F600;<![CDATA[<x>]]></x><y/></r>';
  length := S.Length8(original); n := 0;
  FOR i := 0 TO length DO
    Exercise(original, i, 1); INC(n);
    Exercise(original, i, 7); INC(n)
  END;
  FOR pos := 0 TO length-1 DO
    bytes := original; bytes[pos] := CHR(255-ORD(bytes[pos]));
    Exercise(bytes, length, 1); INC(n);
    bytes[pos] := 0X; Exercise(bytes, length, 7); INC(n)
  END;
  FOR i := 0 TO 127 DO
    FOR pos := 0 TO i-1 DO bytes[pos] := CHR((i*71+pos*113) MOD 256) END;
    Exercise(bytes, i, 3); INC(n)
  END;
  Out.String("XML element stream mutation checks passed: "); Out.Int(n, 0); Out.Ln
END MutationChecks;

PROCEDURE LifetimeChecks;
  VAR s: St.Stream; builder: B.Builder; bytes: ARRAY 1024 OF CHAR;
    i, n, length: LONGINT;
BEGIN
  s := St.New(64, 8, 1); builder := B.New();
  bytes := '<r a="1234567890123456">'; length := S.Length8(bytes);
  ASSERT(s.Feed(bytes, 0, length, builder, n) = St.opened); ASSERT(n = length);
  FOR i := 0 TO LEN(bytes)-1 DO bytes[i] := " " END;
  FOR i := 1 TO 256 DO
    ASSERT(s.Feed(bytes, 0, LEN(bytes), builder, n) = St.needInput); ASSERT(n = LEN(bytes))
  END;
  FOR i := 1 TO 256 DO
    bytes := '<x/>';
    ASSERT(s.Feed(bytes, 0, 4, builder, n) = St.stanza); ASSERT(n = 4)
  END;
  bytes := '</r>remaining'; ASSERT(s.Feed(bytes, 0, 13, builder, n) = St.closed); ASSERT(n = 4);
  ASSERT(s.Finish()); ASSERT(s.Feed(bytes, 4, 9, builder, n) = St.closed); ASSERT(n = 0);
  ASSERT(s.Restart()); bytes := '<r><x';
  ASSERT(s.Feed(bytes, 0, 6, builder, n) = St.opened); ASSERT(n = 3);
  ASSERT(s.Feed(bytes, 3, 2, builder, n) = St.needInput);
  ASSERT(~s.Finish()); ASSERT(s.Feed(bytes, 0, 6, builder, n) = St.failed); ASSERT(n = 0);
  Out.String("XML element stream lifetime and exact-limit checks passed"); Out.Ln
END LifetimeChecks;

BEGIN
  Checks;
  Bad('<r><x></y></r>', 128, 128, 8);
  Bad('<r><p:x/></r>', 128, 128, 8);
  Bad('<r a="1" a="2">', 128, 128, 8);
  Bad('<r xmlns:xml="wrong">', 128, 128, 8);
  Bad('<!DOCTYPE r [<!ENTITY x "x">]><r>', 128, 128, 8);
  Bad('<r><!DOCTYPE x><x/>', 128, 128, 8);
  Bad('<r><!--comment-->', 128, 128, 8);
  Bad('<r><x><!--comment--></x>', 128, 128, 8);
  Bad('<r><?pi x?>', 128, 128, 8);
  Bad('<r>non-whitespace', 128, 128, 8);
  Bad('<r/>', 128, 128, 8);
  Bad('<r></s>', 128, 128, 8);
  Bad('<r><x a="<"/>', 128, 128, 8);
  Bad('<r><x>&missing;</x>', 128, 128, 8);
  Bad('<?xml version="1.1"?><r>', 128, 128, 8);
  Bad('<?xml version="1.0" encoding="ISO-8859-1"?><r>', 128, 128, 8);
  Bad('<?xml version="1.0" standalone="no"?><r>', 128, 128, 8);
  Bad('<r attribute="too long">', 8, 128, 8);
  Bad('<r><x>too long</x>', 128, 8, 8);
  Bad('<r><a><b><c/></b></a>', 128, 128, 1);
  Out.String("XML element stream rejection checks passed"); Out.Ln;
  MutationChecks; LifetimeChecks
END TestStream.
