MODULE TestXmppByteStreams;

IMPORT SYSTEM, Out, Msg, S := LongStrings, T := XmppTypes, Items := XmppItems,
  B := XmppByteStreams, XML := XmppXmlStream, Gen := XmppXmlGen,
  Core := XmppCore, Wire := XmppWire, C := XmppClient, IQ := XmppIQ;

TYPE
  Transport = POINTER TO TransportDesc;
  TransportDesc = RECORD (Wire.TransportDesc) script: Items.Bytes; position: LONGINT END;

VAR checks: LONGINT; sid, jid: T.String;

PROCEDURE (wire: Transport) AuthenticatedFor(domain: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN domain = "example.org" END AuthenticatedFor;
PROCEDURE (wire: Transport) Read(VAR bytes: ARRAY OF CHAR; VAR count: LONGINT): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  count := S.Length8(wire.script^)-wire.position; IF count > LEN(bytes) THEN count := LEN(bytes) END;
  FOR i := 0 TO count-1 DO bytes[i] := wire.script[wire.position+i] END; INC(wire.position, count); RETURN TRUE
END Read;
PROCEDURE (wire: Transport) WriteBytes(VAR bytes: ARRAY OF SYSTEM.BYTE; start, count: LONGINT);
BEGIN wire.res := NIL; wire.bytesWritten := count END WriteBytes;
PROCEDURE (wire: Transport) Close;
BEGIN END Close;

PROCEDURE Check(ok: BOOLEAN; label: ARRAY OF CHAR);
BEGIN
  IF ~ok THEN Out.String("bytestream check failed: "); Out.String(label); Out.Ln; HALT(1) END;
  INC(checks)
END Check;

PROCEDURE Param(item: Items.Item; key, value: ARRAY OF CHAR);
  VAR text: T.String;
BEGIN text := Items.Latin1(value); item.SetParam(key, text^) END Param;

PROCEDURE Offer(): B.Offer;
  VAR offer: B.Offer;
BEGIN
  offer := B.NewOffer(sid^); ASSERT(offer.Add(B.NewHost(jid^, "ծոց.հայ", 7777))); RETURN offer
END Offer;

PROCEDURE Feed(stream: XML.Stream; text: ARRAY OF CHAR; chunk: LONGINT): Items.Item;
  VAR pos, count, consumed: LONGINT; event: SHORTINT; item: Items.Item;
BEGIN
  pos := 0; item := NIL;
  WHILE pos < S.Length8(text) DO
    count := S.Length8(text)-pos; IF count > chunk THEN count := chunk END;
    event := stream.Feed(text, pos, count, consumed); ASSERT((event # XML.failed) & (consumed > 0)); INC(pos, consumed);
    IF event = XML.stanza THEN ASSERT(item = NIL); item := stream.item END
  END;
  RETURN item
END Feed;

PROCEDURE RoundTrip(payload: Items.Item; chunk: LONGINT): Items.Item;
  VAR iq, item: Items.Item; bytes: Items.Bytes; length: LONGINT; error: Msg.Msg; stream: XML.Stream;
BEGIN
  iq := Items.New("iq", "jabber:client"); iq.AddChild(payload); Gen.Encode(iq, 32768, bytes, length, error); ASSERT(error = NIL);
  stream := XML.New(); item := Feed(stream, '<s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client">', chunk);
  item := Feed(stream, bytes^, chunk); ASSERT(item # NIL); RETURN item.First(B.namespaceURI, "query")
END RoundTrip;

PROCEDURE Builders;
  VAR offer, read: B.Offer; host: B.Host; item: Items.Item; i: LONGINT; other, text: T.String; address: ARRAY 16 OF CHAR;
BEGIN
  offer := Offer();
  FOR i := 1 TO 64 DO
    read := B.ReadOffer(RoundTrip(B.Build(offer), i));
    Check((read # NIL) & (read.count = 1) & S.Equal(read.sid^, sid^) & S.Equal(read.hosts[0].jid^, jid^) &
      (read.hosts[0].address^ = "xn--cbbu1a.xn--y9a3aq") & (read.hosts[0].port = 7777), "fragmented Unicode host offer");
    host := B.ReadUsed(RoundTrip(B.Select(offer, jid^), i), offer);
    Check(host = offer.hosts[0], "fragmented selected host binding")
  END;
  other := Items.Latin1("other@example.org/r");
  Check(~offer.Add(B.NewHost(jid^, "127.0.0.1", 1)), "rejecting duplicate host JID");
  Check(~offer.Add(B.NewHost(other^, "ծոց.հայ", 7777)), "rejecting duplicate canonical endpoint");
  Check(B.Select(offer, other^) = NIL, "requiring offered host selection");
  Check((B.NewHost(jid^, "127.0.0.1", 0) = NIL) & (B.NewHost(jid^, "127.0.0.1", 65536) = NIL), "bounding ports");
  Check((B.NewHost(jid^, "host/path", 1) = NIL) & (B.NewHost(jid^, "user@host", 1) = NIL) &
    (B.NewHost(jid^, "::1%lo", 1) = NIL), "rejecting address syntax outside host policy");
  Check(B.NewHost(jid^, "[::1]", 65535) # NIL, "accepting bracketed IPv6 for adapter validation");
  text := Items.Latin1(""); Check(B.NewOffer(text^) = NIL, "requiring SID");
  offer := B.NewOffer(sid^); Check(B.Build(offer) = NIL, "requiring hosts");
  FOR i := 0 TO B.maxHosts-1 DO
    other := Items.Latin1("host@example.org/0"); other[S.Length(other^)-1] := ORD("0")+i;
    address := "127.0.0.1"; address[8] := CHR(ORD("1")+i);
    ASSERT(offer.Add(B.NewHost(other^, address, 1080)))
  END;
  read := B.ReadOffer(B.Build(offer)); Check((read # NIL) & (read.count = B.maxHosts), "supporting bounded host list");
  Check(~offer.Add(B.NewHost(jid^, "example.org", 1080)), "rejecting excess hosts");
  Check((B.ReadOffer(NIL) = NIL) & (B.ReadUsed(NIL, offer) = NIL) & (B.Selected(NIL) = NIL), "handling absent payloads")
END Builders;

PROCEDURE Malformed;
  VAR offer: B.Offer; item, host, used: Items.Item; other: T.String;
BEGIN
  offer := Offer(); item := B.Build(offer); Param(item, "mode", "udp"); Check(B.ReadOffer(item) = NIL, "requiring TCP");
  item := B.Build(offer); Param(item, "dstaddr", "alternate"); Check(B.ReadOffer(item) = NIL, "rejecting alternate destination policy");
  item := B.Build(offer); Param(item, "sid", ""); Check(B.ReadOffer(item) = NIL, "rejecting empty SID");
  item := B.Build(offer); item.AddChild(Items.New("streamhost", "urn:wrong")); Check(B.ReadOffer(item) = NIL, "checking child namespace");
  item := B.Build(offer); host := item.First(B.namespaceURI, "streamhost"); host.AddChild(Items.New("extra", B.namespaceURI));
  Check(B.ReadOffer(item) = NIL, "requiring empty host element");
  item := B.Build(offer); host := item.First(B.namespaceURI, "streamhost"); Param(host, "port", "999999999999999999999999");
  Check(B.ReadOffer(item) = NIL, "rejecting overflowing port");
  Param(host, "port", "-1"); Check(B.ReadOffer(item) = NIL, "rejecting negative port");
  Param(host, "port", "65536"); Check(B.ReadOffer(item) = NIL, "rejecting excessive port");
  Param(host, "port", "1x"); Check(B.ReadOffer(item) = NIL, "rejecting malformed port");
  item := B.Build(offer); host := Items.New("streamhost", B.namespaceURI); host.SetParam("jid", jid^);
  Param(host, "host", "example.org"); item.AddChild(host); Check(B.ReadOffer(item) = NIL, "rejecting repeated host");
  item := B.Build(offer); other := Items.Latin1("payload"); item.AddText(other^, 0, S.Length(other^));
  Check(B.ReadOffer(item) = NIL, "rejecting unexpected text");
  item := B.Select(offer, jid^); Param(item, "sid", "other"); Check(B.ReadUsed(item, offer) = NIL, "binding optional result SID");
  item := B.Select(offer, jid^); used := Items.New("streamhost-used", B.namespaceURI); used.SetParam("jid", jid^); item.AddChild(used);
  Check(B.ReadUsed(item, offer) = NIL, "requiring one selected host");
  item := B.Select(offer, jid^); Param(item.First(B.namespaceURI, "streamhost-used"), "jid", "other@example.org/r");
  Check(B.ReadUsed(item, offer) = NIL, "rejecting unoffered host");
  offer.hosts[0].address[0] := "/"; Check(B.Build(offer) = NIL, "rechecking exposed host strings")
END Malformed;

PROCEDURE Reply(router: IQ.Router; client: C.Client; request: IQ.Request; from: T.String; payload: Items.Item);
  VAR item: Items.Item;
BEGIN
  item := Items.New("iq", "jabber:client"); Param(item, "type", "result"); item.SetParam("id", request.id^); item.SetParam("from", from^);
  item.AddChild(payload); router.Received(client, Core.Wrap(item, NIL))
END Reply;

PROCEDURE Correlation;
  VAR wire: Transport; router: IQ.Router; client: C.Client; hook: C.Hook; user, peer, wrong: T.String;
    request: IQ.Request; action: IQ.Action; offer: B.Offer; error: Msg.Msg; state: SHORTINT;
BEGIN
  NEW(wire); NEW(hook); router := IQ.New(hook);
  wire.script := Items.Copy8('<s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0"><s:features><mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><mechanism>PLAIN</mechanism></mechanisms></s:features><success xmlns="urn:ietf:params:xml:ns:xmpp-sasl"/><s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0"><s:features><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></s:features><iq id="voc-bind-1" type="result"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>user@example.org/r</jid></bind></iq>');
  user := Items.Latin1("user"); client := C.New(wire, router, "example.org", user^, user^, user^, TRUE, error);
  ASSERT((client # NIL) & (error = NIL) & client.Start());
  REPEAT state := client.Step() UNTIL (state = C.online) OR (state = C.failed); ASSERT(state = C.online);
  offer := Offer(); peer := Items.Latin1("peer@example.org/r"); wrong := Items.Latin1("peer@example.org/other");
  NEW(action); request := B.Query(router, peer^, offer, 100, action, error); ASSERT((request # NIL) & (error = NIL));
  Check(B.Selected(request) = NIL, "requiring completed result");
  Reply(router, client, request, wrong, B.Select(offer, jid^));
  Check((request.status = IQ.pending) & (B.Selected(request) = NIL), "ignoring another resource selection");
  wrong := Items.Latin1("peer@example.org"); Reply(router, client, request, wrong, B.Select(offer, jid^));
  Check(request.status = IQ.pending, "ignoring bare reply to full peer request");
  Reply(router, client, request, peer, B.Select(offer, jid^));
  Check((request.status = IQ.result) & (B.Selected(request) # NIL), "accepting exact-peer offered host");
  request := B.Query(router, peer^, offer, 100, action, error); router.Tick(100);
  Check((request.status = IQ.timedOut) & (B.Selected(request) = NIL), "rejecting timed-out selection");
  router.Stop; client.Abort
END Correlation;

BEGIN
  sid := Items.UTF8("հոսք😀"); jid := Items.UTF8("Անի@ծոց.հայ/մուտք😀"); Builders; Malformed; Correlation;
  Out.String("XMPP bytestream checks passed: "); Out.Int(checks, 0); Out.Ln
END TestXmppByteStreams.
