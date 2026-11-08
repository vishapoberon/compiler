MODULE TestXmppFileSender;

IMPORT SYSTEM, Out, Msg, Channel, S := LongStrings, T := XmppTypes,
  Items := XmppItems, Core := XmppCore, Wire := XmppWire, C := XmppClient,
  IQ := XmppIQ, Ibb := XmppIbbTransfer, I := XmppIbb, SI := XmppStreamInit, F := XmppFileSender;

TYPE
  Transport = POINTER TO TransportDesc;
  TransportDesc = RECORD (Wire.TransportDesc) script: Items.Bytes; position: LONGINT; fail: BOOLEAN END;
  Store = POINTER TO StoreDesc;
  StoreDesc = RECORD (Channel.ChannelDesc) data: ARRAY 2048 OF CHAR; length: LONGINT END;
  Reader = POINTER TO ReaderDesc;
  ReaderDesc = RECORD (Channel.ReaderDesc) position, reads, seeks: LONGINT; failSeek, short: BOOLEAN END;
  Application = POINTER TO ApplicationDesc;
  ApplicationDesc = RECORD (C.HookDesc) last: Core.Stanza; sent: LONGINT; stopSend: F.Sender END;
  EngineHook = POINTER TO EngineHookDesc;
  EngineHookDesc = RECORD (Ibb.HookDesc) finished, progress: LONGINT END;
  Hook = POINTER TO HookDesc;
  HookDesc = RECORD (F.HookDesc) finished, progress: LONGINT; cancel: BOOLEAN; last: F.Session END;
  Fixture = POINTER TO FixtureDesc;
  FixtureDesc = RECORD
    app: Application; wire: Transport; engine: Ibb.Manager; engineHook: EngineHook;
    sender: F.Sender; hook: Hook; c: C.Client
  END;

VAR checks: LONGINT; peer, sid, name: T.String; fault: Msg.Msg;

PROCEDURE Check(ok: BOOLEAN; label: ARRAY OF CHAR);
BEGIN
  IF ~ok THEN Out.String("file-sender check failed: "); Out.String(label); Out.Ln; HALT(1) END;
  INC(checks)
END Check;

PROCEDURE (r: Reader) Pos(): LONGINT;
BEGIN RETURN r.position END Pos;
PROCEDURE (r: Reader) SetPos(position: LONGINT);
BEGIN
  INC(r.seeks); IF r.failSeek THEN r.res := fault ELSE r.position := position; r.res := NIL END
END SetPos;
PROCEDURE (r: Reader) ReadBytes(VAR bytes: ARRAY OF SYSTEM.BYTE; start, count: LONGINT);
  VAR store: Store; i: LONGINT;
BEGIN
  store := r.base(Store); INC(r.reads); r.bytesRead := count;
  IF r.bytesRead > store.length-r.position THEN r.bytesRead := store.length-r.position END;
  IF r.short & (r.bytesRead > 0) THEN DEC(r.bytesRead) END;
  FOR i := 0 TO r.bytesRead-1 DO bytes[start+i] := SYSTEM.VAL(SYSTEM.BYTE, store.data[r.position+i]) END;
  INC(r.position, r.bytesRead); r.res := NIL
END ReadBytes;
PROCEDURE (wire: Transport) AuthenticatedFor(domain: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN domain = "example.org" END AuthenticatedFor;
PROCEDURE (wire: Transport) Read(VAR bytes: ARRAY OF CHAR; VAR count: LONGINT): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  count := S.Length8(wire.script^)-wire.position; IF count > LEN(bytes) THEN count := LEN(bytes) END;
  FOR i := 0 TO count-1 DO bytes[i] := wire.script[wire.position+i] END; INC(wire.position, count); RETURN TRUE
END Read;
PROCEDURE (wire: Transport) WriteBytes(VAR bytes: ARRAY OF SYSTEM.BYTE; start, count: LONGINT);
BEGIN
  IF wire.fail THEN wire.res := fault; wire.bytesWritten := 0 ELSE wire.res := NIL; wire.bytesWritten := count END
END WriteBytes;
PROCEDURE (wire: Transport) Close;
BEGIN END Close;
PROCEDURE (app: Application) Sent(client: C.Client; stanza: Core.Stanza);
BEGIN
  app.last := stanza; INC(app.sent); IF app.stopSend # NIL THEN app.stopSend.Stop END
END Sent;
PROCEDURE (h: EngineHook) Progress(manager: Ibb.Manager; transfer: Ibb.Transfer; VAR cancel: BOOLEAN);
BEGIN INC(h.progress) END Progress;
PROCEDURE (h: EngineHook) Done(manager: Ibb.Manager; transfer: Ibb.Transfer);
BEGIN INC(h.finished) END Done;
PROCEDURE (h: Hook) Progress(sender: F.Sender; session: F.Session; VAR cancel: BOOLEAN);
BEGIN INC(h.progress); cancel := h.cancel END Progress;
PROCEDURE (h: Hook) Done(sender: F.Sender; session: F.Session);
BEGIN INC(h.finished); h.last := session; ASSERT(sender.count < F.maxOffers) END Done;

PROCEDURE New(): Fixture;
  VAR f: Fixture; user: T.String; error: Msg.Msg; state: SHORTINT;
BEGIN
  NEW(f); NEW(f.app); NEW(f.wire); NEW(f.engineHook); NEW(f.hook);
  f.engine := Ibb.New(f.app, f.engineHook, 1024, 256, 100); f.sender := F.New(f.engine, f.hook, 100); ASSERT(f.sender # NIL);
  f.wire.script := Items.Copy8('<s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0"><s:features><mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><mechanism>PLAIN</mechanism></mechanisms></s:features><success xmlns="urn:ietf:params:xml:ns:xmpp-sasl"/><s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0"><s:features><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></s:features><iq id="voc-bind-1" type="result"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>user@example.org/r</jid></bind></iq>');
  user := Items.Latin1("user"); f.c := C.New(f.wire, f.engine.router, "example.org", user^, user^, user^, TRUE, error);
  ASSERT((f.c # NIL) & (error = NIL) & f.c.Start());
  REPEAT state := f.c.Step() UNTIL (state = C.online) OR (state = C.failed);
  ASSERT(state = C.online); f.app.last := NIL; f.app.sent := 0; RETURN f
END New;

PROCEDURE Dispose(f: Fixture);
BEGIN f.sender.Stop; f.engine.Stop; f.engine.router.Stop; f.c.Abort END Dispose;

PROCEDURE Source(size, prefix: LONGINT): Reader;
  VAR reader: Reader; store: Store; i: LONGINT;
BEGIN
  NEW(reader); NEW(store); store.open := TRUE; store.readable := TRUE; store.length := size+prefix;
  FOR i := 0 TO size-1 DO store.data[prefix+i] := CHR(i MOD 256) END;
  reader.base := store; reader.positionable := TRUE; reader.position := prefix; RETURN reader
END Source;

PROCEDURE Param(item: Items.Item; key, value: ARRAY OF CHAR);
  VAR text: T.String;
BEGIN text := Items.Latin1(value); item.SetParam(key, text^) END Param;

PROCEDURE Reply(f: Fixture; from: T.String; request: IQ.Request; kind: ARRAY OF CHAR; payload: Items.Item);
  VAR item: Items.Item;
BEGIN
  item := Items.New("iq", "jabber:client"); Param(item, "type", kind); item.SetParam("id", request.id^); item.SetParam("from", from^);
  IF payload # NIL THEN item.AddChild(payload) END;
  f.engine.router.Received(f.c, Core.Wrap(item, NIL))
END Reply;

PROCEDURE Offer(size: LONGINT; range: BOOLEAN): SI.Offer;
  VAR offer: SI.Offer;
BEGIN offer := SI.NewOffer(sid^, name^, size, {SI.ibb}); ASSERT(offer # NIL); offer.range := range; RETURN offer END Offer;

PROCEDURE Ranges;
  VAR f: Fixture; source: Reader; offer: SI.Offer; session: F.Session; error: Msg.Msg; event: I.Event;
    wrong: T.String; i: LONGINT;
BEGIN
  f := New(); source := Source(513, 10); offer := Offer(513, TRUE);
  session := f.sender.Offer(peer^, offer, source, 128, error);
  Check((session # NIL) & (error = NIL) & (source.reads = 0) & (source.seeks = 0), "not touching source before acceptance");
  wrong := Items.Latin1("peer@example.org/spoof");
  Reply(f, wrong, session.request, "result", SI.Accept(offer, SI.ibb, 123, 234));
  Check((session.status = F.negotiating) & (source.reads = 0), "not accepting another resource's selection");
  session.offer.size := 1000; session.offer.sid := Items.Latin1("mutated"); offer.size := 900;
  offer := Offer(513, TRUE); Reply(f, peer, session.request, "result", SI.Accept(offer, SI.ibb, 123, 234));
  Check((session.transfer # NIL) & (session.offset = 123) & (session.length = 234) & (source.position = 133) & (source.reads = 0), "positioning selected range relative to captured source origin");
  Reply(f, peer, session.transfer.request, "result", NIL);
  event := I.Read(session.transfer.request.payload, 128);
  Check((event # NIL) & (event.length = 128) & (source.position = 261), "reading first selected block after IBB open result");
  FOR i := 0 TO event.length-1 DO ASSERT(event.bytes[i] = CHR((123+i) MOD 256)) END;
  Reply(f, peer, session.transfer.request, "result", NIL);
  event := I.Read(session.transfer.request.payload, 128);
  Check((event # NIL) & (event.length = 106) & (session.bytes = 128), "sending bounded remainder of accepted range");
  Reply(f, peer, session.transfer.request, "result", NIL); Reply(f, peer, session.transfer.request, "result", NIL);
  Check((session.status = F.done) & (session.bytes = 234) & (source.position = 367) & (f.hook.finished = 1), "finishing exact source subrange");
  Check((f.hook.progress = 2) & (f.engineHook.progress = 0) & (f.engineHook.finished = 0) & (f.sender.count = 0), "routing callbacks only to per-transfer observer"); Dispose(f);
  f := New(); source := Source(0, 0); offer := Offer(0, FALSE); session := f.sender.Offer(peer^, offer, source, 1, error);
  Reply(f, peer, session.request, "result", SI.Accept(offer, SI.ibb, 0, 0));
  Reply(f, peer, session.transfer.request, "result", NIL); Reply(f, peer, session.transfer.request, "result", NIL);
  Check((session.status = F.done) & (source.reads = 0), "negotiating and completing empty file"); Dispose(f)
END Ranges;

PROCEDURE Failures;
  VAR f: Fixture; source: Reader; offer: SI.Offer; session: F.Session; error: Msg.Msg; mode: LONGINT; payload: Items.Item;
BEGIN
  FOR mode := 0 TO 5 DO
    f := New(); source := Source(7, 0); offer := Offer(7, TRUE); session := f.sender.Offer(peer^, offer, source, 7, error);
    CASE mode OF
    | 0: Reply(f, peer, session.request, "result", SI.Accept(offer, SI.ibb, 1, 6)); source.short := TRUE;
         Reply(f, peer, session.transfer.request, "result", NIL)
    | 1: source.failSeek := TRUE; Reply(f, peer, session.request, "result", SI.Accept(offer, SI.ibb, 1, 6))
    | 2: source.base.open := FALSE; Reply(f, peer, session.request, "result", SI.Accept(offer, SI.ibb, 0, 7))
    | 3: Reply(f, peer, session.request, "result", Items.New("unexpected", "urn:test"))
    | 4: payload := Items.New("error", "jabber:client"); Param(payload, "type", "cancel");
         payload.AddChild(Items.New("not-acceptable", "urn:ietf:params:xml:ns:xmpp-stanzas")); Reply(f, peer, session.request, "error", payload)
    | 5: f.engine.router.Tick(100)
    ELSE HALT(1)
    END;
    Check((session.status >= F.done) & (session.status # F.done) & (f.hook.finished = 1) & (f.sender.count = 0), "failing invalid results, source errors and deadlines");
    Check(f.engine.router.count = 0, "releasing pending IQ on failure"); Dispose(f)
  END
END Failures;

PROCEDURE LimitsAndCancellation;
  VAR f: Fixture; source: Reader; offer: SI.Offer; session, second: F.Session; error: Msg.Msg; i: LONGINT;
BEGIN
  f := New(); source := Source(7, 0); offer := Offer(7, TRUE); source.positionable := FALSE;
  Check(f.sender.Offer(peer^, offer, source, 7, error) = NIL, "requiring positioning for advertised resume support");
  source.positionable := TRUE; offer.methods := {SI.ibb, SI.socks5};
  Check(f.sender.Offer(peer^, offer, source, 7, error) = NIL, "advertising only implemented outgoing transport");
  offer.methods := {SI.ibb}; Check(f.sender.Offer(peer^, offer, source, 257, error) = NIL, "checking engine block policy before offering");
  offer.size := 1025; Check(f.sender.Offer(peer^, offer, source, 7, error) = NIL, "checking engine byte policy before offering");
  offer.size := 7; session := f.sender.Offer(peer^, offer, source, 7, error);
  Check(f.sender.Offer(peer^, offer, source, 7, error) = NIL, "not replacing pending peer/SID");
  Check(f.sender.Cancel(session) & ~f.sender.Cancel(session) & (source.reads = 0) & (f.engine.router.count = 0), "cancelling before remote acceptance"); Dispose(f);
  f := New(); source := Source(7, 0); offer := Offer(7, FALSE); session := f.sender.Offer(peer^, offer, source, 7, error);
  Reply(f, peer, session.request, "result", SI.Accept(offer, SI.ibb, 0, 7)); f.hook.cancel := TRUE;
  Reply(f, peer, session.transfer.request, "result", NIL); Reply(f, peer, session.transfer.request, "result", NIL);
  Check((session.status = F.cancelled) & (f.hook.finished = 1) & (f.engine.router.count = 0), "cancelling negotiated send from progress hook"); Dispose(f);
  f := New(); source := Source(7, 0); f.app.stopSend := f.sender; session := f.sender.Offer(peer^, Offer(7, FALSE), source, 7, error);
  Check((session.status = F.cancelled) & (f.engine.router.count = 0) & (f.hook.finished = 1), "stopping during synchronous offer output"); Dispose(f);
  f := New(); source := Source(7, 0); f.wire.fail := TRUE; session := f.sender.Offer(peer^, Offer(7, FALSE), source, 7, error);
  Check((session.status >= F.done) & (f.sender.count = 0) & (f.hook.finished = 1), "handling synchronous offer send failure"); Dispose(f);
  f := New(); source := Source(0, 0);
  FOR i := 0 TO F.maxOffers-1 DO
    offer := Offer(0, FALSE); offer.sid[0] := ORD("A")+i;
    session := f.sender.Offer(peer^, offer, source, 1, error); ASSERT(session # NIL)
  END;
  second := f.sender.Offer(peer^, Offer(0, FALSE), source, 1, error);
  Check((second = NIL) & (f.sender.count = F.maxOffers), "bounding outgoing negotiation table");
  f.sender.Stop; Check((f.hook.finished = F.maxOffers) & (f.engine.router.count = 0), "stopping every pending outgoing offer once"); Dispose(f)
END LimitsAndCancellation;

BEGIN
  fault := Wire.Error(); peer := Items.Latin1("peer@example.org/resource"); sid := Items.UTF8("հոսք😀"); name := Items.UTF8("ֆայլ😀.bin");
  Ranges; Failures; LimitsAndCancellation;
  Out.String("XMPP file-sender checks passed: "); Out.Int(checks, 0); Out.Ln
END TestXmppFileSender.
