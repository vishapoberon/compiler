MODULE TestXmppFileReceiver;

IMPORT SYSTEM, Out, Msg, Channel, IntStr, S := LongStrings, T := XmppTypes,
  Items := XmppItems, Core := XmppCore, Wire := XmppWire, C := XmppClient,
  IQ := XmppIQ, I := XmppIbb, SI := XmppStreamInit, F := XmppFileReceiver;

TYPE
  Transport = POINTER TO TransportDesc;
  TransportDesc = RECORD (Wire.TransportDesc) script: Items.Bytes; position: LONGINT; fail: BOOLEAN END;
  Store = POINTER TO StoreDesc;
  StoreDesc = RECORD (Channel.ChannelDesc) data: ARRAY 2048 OF CHAR; length: LONGINT; badFlush: BOOLEAN END;
  Writer = POINTER TO WriterDesc;
  WriterDesc = RECORD (Channel.WriterDesc) short: BOOLEAN END;
  Application = POINTER TO ApplicationDesc;
  ApplicationDesc = RECORD (C.HookDesc)
    last: Core.Stanza; sent, errors, closed: LONGINT; stopSend: F.Receiver
  END;
  Hook = POINTER TO HookDesc;
  HookDesc = RECORD (F.HookDesc)
    session: F.Session; offered, finished, progress: LONGINT;
    stop, reject, auto, cancelProgress: BOOLEAN; writer: Writer;
    acceptNext: F.Session
  END;
  Fixture = POINTER TO FixtureDesc;
  FixtureDesc = RECORD
    receiver: F.Receiver; c: C.Client; wire: Transport; app: Application; hook: Hook; store: Store
  END;

VAR checks, serial: LONGINT; peer, sid, name: T.String; fault: Msg.Msg;

PROCEDURE Check(ok: BOOLEAN; text: ARRAY OF CHAR);
BEGIN
  IF ~ok THEN Out.String("file-receiver check failed: "); Out.String(text); Out.Ln; HALT(1) END;
  INC(checks)
END Check;

PROCEDURE (s: Store) Flush;
BEGIN IF s.badFlush THEN s.res := fault ELSE s.res := NIL END END Flush;
PROCEDURE (w: Writer) WriteBytes(VAR bytes: ARRAY OF SYSTEM.BYTE; start, count: LONGINT);
  VAR store: Store; i: LONGINT;
BEGIN
  store := w.base(Store); w.bytesWritten := count; w.res := NIL;
  IF w.short & (count > 0) THEN DEC(w.bytesWritten) END;
  ASSERT(store.length+w.bytesWritten <= LEN(store.data));
  FOR i := 0 TO w.bytesWritten-1 DO store.data[store.length+i] := SYSTEM.VAL(CHAR, bytes[start+i]) END;
  INC(store.length, w.bytesWritten)
END WriteBytes;
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
  app.last := stanza; INC(app.sent);
  IF app.stopSend # NIL THEN app.stopSend.Stop END
END Sent;
PROCEDURE (app: Application) Error(client: C.Client; error: Msg.Msg);
BEGIN INC(app.errors) END Error;
PROCEDURE (app: Application) Closed(client: C.Client);
BEGIN INC(app.closed) END Closed;
PROCEDURE (hook: Hook) Offered(receiver: F.Receiver; session: F.Session);
  VAR ignored: BOOLEAN;
BEGIN
  INC(hook.offered); hook.session := session;
  IF hook.stop THEN receiver.Stop
  ELSIF hook.reject THEN ignored := receiver.Reject(session)
  ELSIF hook.auto THEN ignored := receiver.Accept(session, hook.writer, 0, session.length)
  END
END Offered;
PROCEDURE (hook: Hook) Progress(receiver: F.Receiver; session: F.Session; VAR cancel: BOOLEAN);
BEGIN INC(hook.progress); cancel := hook.cancelProgress END Progress;
PROCEDURE (hook: Hook) Done(receiver: F.Receiver; session: F.Session);
  VAR next: F.Session; ignored: BOOLEAN;
BEGIN
  INC(hook.finished); hook.session := session; ASSERT(receiver.count < F.maxOffers);
  IF hook.acceptNext # NIL THEN
    next := hook.acceptNext; hook.acceptNext := NIL; ignored := receiver.Accept(next, hook.writer, 0, next.length); ASSERT(ignored)
  END
END Done;

PROCEDURE New(): Fixture;
  VAR f: Fixture; user: T.String; error: Msg.Msg; state: SHORTINT;
BEGIN
  NEW(f); NEW(f.wire); NEW(f.app); NEW(f.hook); NEW(f.hook.writer); NEW(f.store);
  f.store.open := TRUE; f.store.writable := TRUE; f.hook.writer.base := f.store;
  f.receiver := F.New(f.app, f.hook, 1024, 256, 100); ASSERT(f.receiver # NIL);
  f.wire.script := Items.Copy8('<s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0"><s:features><mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><mechanism>PLAIN</mechanism></mechanisms></s:features><success xmlns="urn:ietf:params:xml:ns:xmpp-sasl"/><s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0"><s:features><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></s:features><iq id="voc-bind-1" type="result"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>user@example.org/r</jid></bind></iq>');
  user := Items.Latin1("user"); f.c := C.New(f.wire, f.receiver.router, "example.org", user^, user^, user^, TRUE, error);
  ASSERT((f.c # NIL) & (error = NIL) & f.c.Start());
  REPEAT state := f.c.Step() UNTIL (state = C.online) OR (state = C.failed);
  ASSERT((state = C.online) & f.receiver.active); f.app.last := NIL; f.app.sent := 0; RETURN f
END New;

PROCEDURE Dispose(f: Fixture);
BEGIN f.receiver.Stop; f.receiver.router.Stop; f.c.Abort END Dispose;

PROCEDURE Param(item: Items.Item; key, value: ARRAY OF CHAR);
  VAR text: T.String;
BEGIN text := Items.Latin1(value); item.SetParam(key, text^) END Param;

PROCEDURE Input(f: Fixture; from: T.String; payload: Items.Item);
  VAR item: Items.Item; id: ARRAY 32 OF CHAR;
BEGIN
  INC(serial); IntStr.IntToStr(serial, id); item := Items.New("iq", "jabber:client");
  Param(item, "id", id); Param(item, "type", "set"); item.SetParam("from", from^); item.AddChild(payload);
  f.receiver.router.Received(f.c, Core.Wrap(item, NIL))
END Input;

PROCEDURE Offer(f: Fixture; id: T.String; size: LONGINT; resume: BOOLEAN): F.Session;
  VAR offer: SI.Offer;
BEGIN
  offer := SI.NewOffer(id^, name^, size, {SI.ibb, SI.socks5}); ASSERT(offer # NIL); offer.range := resume;
  Input(f, peer, SI.Build(offer)); RETURN f.hook.session
END Offer;

PROCEDURE Error(f: Fixture; condition: ARRAY OF CHAR): BOOLEAN;
  VAR item: Items.Item;
BEGIN
  IF (f.app.last = NIL) OR ~S.Equal8(f.app.last.type^, "error") THEN RETURN FALSE END;
  item := f.app.last.item.First("jabber:client", "error");
  RETURN (item # NIL) & (item.First("urn:ietf:params:xml:ns:xmpp-stanzas", condition) # NIL)
END Error;

PROCEDURE Success;
  VAR f: Fixture; session: F.Session; raw: ARRAY 256 OF CHAR; i: LONGINT; other: T.String; selection: SI.Selection;
BEGIN
  f := New(); session := Offer(f, sid, 513, FALSE);
  Check((session # NIL) & (session.status = F.offered) & (f.app.sent = 0) & (f.receiver.count = 1), "deferring result until application consent");
  Input(f, peer, I.Open(sid^, 256));
  Check(Error(f, "not-acceptable") & (session.status = F.offered) & (f.store.length = 0), "not authorizing an unaccepted offer");
  Check(f.receiver.Accept(session, f.hook.writer, 0, 513), "accepting a validated offer explicitly");
  selection := SI.ReadAccept(f.app.last.item.First(SI.namespaceURI, "si"), session.offer);
  Check((selection # NIL) & (selection.method = SI.ibb) & (selection.length = 513), "sending negotiated IBB selection");
  other := Items.Latin1("peer@example.org/spoof"); Input(f, other, I.Open(sid^, 256));
  Check(Error(f, "not-acceptable") & (session.status = F.waiting), "not consuming authorization for another resource");
  other := Items.Latin1("wrong-sid"); Input(f, peer, I.Open(other^, 256));
  Check(Error(f, "not-acceptable") & (session.status = F.waiting), "not consuming authorization for another SID");
  Input(f, peer, I.Open(sid^, 256));
  Check((session.status = F.receiving) & (session.transfer # NIL), "binding exactly one IBB open");
  FOR i := 0 TO 255 DO raw[i] := CHR(i) END;
  Input(f, peer, I.Data(sid^, 0, raw, 0, 256)); Input(f, peer, I.Data(sid^, 1, raw, 0, 256));
  Input(f, peer, I.Data(sid^, 2, raw, 0, 1)); Input(f, peer, I.Close(sid^));
  Check((session.status = F.done) & (session.bytes = 513) & (f.hook.finished = 1) & (f.receiver.count = 0), "completing exact negotiated byte count");
  FOR i := 0 TO 512 DO ASSERT(f.store.data[i] = CHR(i MOD 256)) END;
  Input(f, peer, I.Open(sid^, 256)); Check(Error(f, "not-acceptable"), "not reusing completed consent"); Dispose(f)
END Success;

PROCEDURE RangesAndFailures;
  VAR f: Fixture; session: F.Session; raw: ARRAY 8 OF CHAR; mode: LONGINT; ignored: BOOLEAN;
BEGIN
  raw := "abcdefg";
  f := New(); session := Offer(f, sid, 7, TRUE); f.store.length := 3;
  Check(f.receiver.Accept(session, f.hook.writer, 3, 4), "accepting selected resume range");
  Input(f, peer, I.Open(sid^, 4)); Input(f, peer, I.Data(sid^, 0, raw, 3, 4)); Input(f, peer, I.Close(sid^));
  Check((session.status = F.done) & (session.offset = 3) & (session.bytes = 4) & (f.store.length = 7), "receiving only selected range into positioned output"); Dispose(f);
  FOR mode := 0 TO 3 DO
    f := New(); session := Offer(f, sid, 7, FALSE); ignored := f.receiver.Accept(session, f.hook.writer, 0, 7);
    Input(f, peer, I.Open(sid^, 8));
    CASE mode OF
    | 0: Input(f, peer, I.Data(sid^, 0, raw, 0, 3)); Input(f, peer, I.Close(sid^))
    | 1: Input(f, peer, I.Data(sid^, 0, raw, 0, 8))
    | 2: f.hook.writer.short := TRUE; Input(f, peer, I.Data(sid^, 0, raw, 0, 7))
    | 3: f.store.badFlush := TRUE; Input(f, peer, I.Data(sid^, 0, raw, 0, 7)); Input(f, peer, I.Close(sid^))
    ELSE HALT(1)
    END;
    Check((session.status >= F.done) & (session.status # F.done) & (f.hook.finished = 1) & (f.receiver.count = 0), "failing truncated, excessive or failed output");
    IF mode = 0 THEN Check(Error(f, "not-acceptable"), "rejecting premature close before acknowledging success") END;
    IF mode = 1 THEN Check(f.store.length = 0, "not writing beyond accepted size") END;
    Dispose(f)
  END;
  f := New(); session := Offer(f, sid, 0, FALSE); ignored := f.receiver.Accept(session, f.hook.writer, 0, 0);
  Input(f, peer, I.Open(sid^, 1)); Input(f, peer, I.Close(sid^));
  Check((session.status = F.done) & (session.bytes = 0), "accepting empty file without data"); Dispose(f)
END RangesAndFailures;

PROCEDURE ConsentAndLimits;
  VAR f: Fixture; session: F.Session; id: T.String; i, sent: LONGINT; offer: SI.Offer;
BEGIN
  f := New(); session := Offer(f, sid, 7, FALSE);
  Check(~f.receiver.Accept(session, f.hook.writer, 1, 6) & (session.status = F.offered), "rejecting unsolicited resume without consuming offer");
  Check(~f.receiver.Accept(session, NIL, 0, 7), "requiring usable output writer");
  session.offer.size := 1000; session.offer.sid := Items.Latin1("mutated");
  Check(~f.receiver.Accept(session, f.hook.writer, 0, 1000), "using private negotiated metadata despite public edits");
  Check(f.receiver.Accept(session, f.hook.writer, 0, 7), "retaining authoritative original offer");
  Input(f, peer, I.Open(sid^, 7)); Check(session.status = F.receiving, "retaining original private SID after metadata edits"); Dispose(f);
  f := New(); f.hook.reject := TRUE; session := Offer(f, sid, 7, FALSE);
  Check((session.status = F.rejected) & Error(f, "not-acceptable") & (f.hook.finished = 1), "rejecting synchronously with one reply"); Dispose(f);
  f := New(); f.hook.auto := TRUE; session := Offer(f, sid, 7, FALSE);
  Check((session.status = F.waiting) & (f.app.sent = 1), "accepting synchronously without router fallback response"); Dispose(f);
  f := New(); f.hook.stop := TRUE; session := Offer(f, sid, 7, FALSE);
  Check((session.status = F.cancelled) & (f.receiver.count = 0) & (f.hook.finished = 1), "stopping during offer callback"); Dispose(f);
  f := New(); session := Offer(f, sid, 7, FALSE); sent := f.hook.offered;
  Input(f, peer, SI.Build(SI.NewOffer(sid^, name^, 7, {SI.ibb})));
  Check(Error(f, "unexpected-request") & (f.hook.offered = sent) & (f.receiver.count = 1), "preserving original consent request on duplicate SID"); Dispose(f);
  f := New();
  FOR i := 0 TO F.maxOffers-1 DO
    NEW(id, 3); id[0] := ORD("s"); id[1] := ORD("A")+i; id[2] := 0; session := Offer(f, id, 1, FALSE)
  END;
  Input(f, peer, SI.Build(SI.NewOffer(sid^, name^, 7, {SI.ibb})));
  Check(Error(f, "resource-constraint") & (f.receiver.count = F.maxOffers), "bounding pending consent table");
  f.receiver.Stop; Check((f.receiver.count = 0) & (f.hook.finished = F.maxOffers), "cleaning every queued offer once"); Dispose(f);
  f := New(); offer := SI.NewOffer(sid^, name^, 1025, {SI.ibb}); Input(f, peer, SI.Build(offer));
  Check(Error(f, "resource-constraint") & (f.hook.offered = 0), "applying total-size limit before consent");
  offer := SI.NewOffer(sid^, name^, 7, {SI.socks5}); Input(f, peer, SI.Build(offer));
  Check(Error(f, "feature-not-implemented") & (f.hook.offered = 0), "not selecting unimplemented SOCKS5 adapter"); Dispose(f)
END ConsentAndLimits;

PROCEDURE Lifecycle;
  VAR f: Fixture; session: F.Session; ignored: BOOLEAN; raw: ARRAY 1 OF CHAR;
BEGIN
  raw[0] := 0X;
  f := New(); session := Offer(f, sid, 1, FALSE); f.receiver.Tick(99);
  Check(session.status = F.offered, "waiting for asynchronous decision"); f.receiver.Tick(1);
  Check((session.status = F.timedOut) & Error(f, "not-acceptable") & (f.hook.finished = 1), "expiring unanswered consent");
  Check(~f.receiver.Accept(session, f.hook.writer, 0, 1), "rejecting stale approval"); Dispose(f);
  f := New(); session := Offer(f, sid, 1, FALSE); ignored := f.receiver.Accept(session, f.hook.writer, 0, 1); f.receiver.Tick(100);
  Check((session.status = F.timedOut) & (f.receiver.router.count = 0), "expiring unused IBB authorization");
  Input(f, peer, I.Open(sid^, 1)); Check(Error(f, "not-acceptable"), "not accepting an expired authorization"); Dispose(f);
  f := New(); session := Offer(f, sid, 1, FALSE); ignored := f.receiver.Accept(session, f.hook.writer, 0, 1);
  Input(f, peer, I.Open(sid^, 1)); f.receiver.Tick(100);
  Check((session.status = F.timedOut) & (f.receiver.count = 0) & (f.hook.finished = 1), "expiring receiving stream through integrated clock"); Dispose(f);
  f := New(); session := Offer(f, sid, 1, FALSE);
  Check(f.receiver.Cancel(session) & ~f.receiver.Cancel(session) & (f.hook.finished = 1), "cancelling offered session once"); Dispose(f);
  f := New(); session := Offer(f, sid, 1, FALSE); ignored := f.receiver.Accept(session, f.hook.writer, 0, 1);
  Input(f, peer, I.Open(sid^, 1)); f.hook.cancelProgress := TRUE; Input(f, peer, I.Data(sid^, 0, raw, 0, 1));
  Check((session.status = F.cancelled) & (f.hook.finished = 1), "cancelling after checked progress"); Dispose(f);
  f := New(); session := Offer(f, sid, 1, FALSE); f.app.stopSend := f.receiver;
  Check(~f.receiver.Accept(session, f.hook.writer, 0, 1) & (session.status = F.cancelled) & (f.hook.finished = 1), "stopping from acceptance output hook"); Dispose(f);
  f := New(); session := Offer(f, sid, 1, FALSE); f.wire.fail := TRUE; ignored := f.receiver.Accept(session, f.hook.writer, 0, 1);
  Check((session.status >= F.done) & (f.receiver.count = 0) & (f.hook.finished = 1), "handling synchronous acceptance send failure"); Dispose(f);
  f := New(); session := Offer(f, sid, 1, FALSE); ignored := f.receiver.Accept(session, f.hook.writer, 0, 1);
  Input(f, peer, I.Open(sid^, 1)); f.receiver.router.Closed(f.c);
  Check((session.status = F.disconnected) & ~f.receiver.active & (f.hook.finished = 1) & (f.app.closed = 1), "cleaning bound receive on disconnect"); Dispose(f)
END Lifecycle;

PROCEDURE ReentryAndRouting;
  VAR f, other: Fixture; first, next: F.Session; secondSID: T.String; request, payload: Items.Item;
    originalID: T.String; ignored: BOOLEAN;
BEGIN
  f := New(); first := Offer(f, sid, 1, FALSE);
  originalID := Items.Latin1("same-request"); request := Items.New("iq", "jabber:client");
  request.SetParam("id", originalID^); request.SetParam("from", peer^); Param(request, "type", "set");
  secondSID := Items.Latin1("second"); request.AddChild(SI.Build(SI.NewOffer(secondSID^, name^, 1, {SI.ibb})));
  f.receiver.router.Received(f.c, Core.Wrap(request, NIL)); next := f.hook.session;
  request := Items.New("iq", "jabber:client"); request.SetParam("id", originalID^); request.SetParam("from", peer^); Param(request, "type", "set");
  secondSID := Items.Latin1("third"); request.AddChild(SI.Build(SI.NewOffer(secondSID^, name^, 1, {SI.ibb})));
  f.receiver.router.Received(f.c, Core.Wrap(request, NIL));
  Check(Error(f, "unexpected-request") & (f.receiver.count = 2), "not reusing a pending IQ ID with another SID");
  f.hook.acceptNext := next; f.receiver.Tick(100);
  Check((first.status = F.timedOut) & (next.status = F.waiting), "not aging reentrantly approved authorization in same tick");
  f.receiver.Tick(99); Check(next.status = F.waiting, "keeping refreshed authorization before new deadline");
  f.receiver.Tick(1); Check(next.status = F.timedOut, "expiring refreshed authorization at new deadline"); Dispose(f);
  f := New(); other := New(); first := Offer(f, sid, 1, FALSE);
  Check(~other.receiver.Accept(first, other.hook.writer, 0, 1) & ~other.receiver.Cancel(first), "binding consent to originating client");
  ignored := f.receiver.Reject(first); Check(~f.receiver.Accept(first, f.hook.writer, 0, 1), "not accepting previously rejected session"); Dispose(f); Dispose(other);
  f := New(); payload := SI.Build(SI.NewOffer(sid^, name^, 1, {SI.ibb}));
  request := Items.New("iq", "jabber:client"); Param(request, "id", "get-offer"); Param(request, "type", "get"); request.SetParam("from", peer^); request.AddChild(payload);
  f.receiver.router.Received(f.c, Core.Wrap(request, NIL)); Check(Error(f, "bad-request") & (f.hook.offered = 0), "requiring IQ-set for incoming offer"); Dispose(f)
END ReentryAndRouting;

BEGIN
  fault := Wire.Error(); peer := Items.Latin1("peer@example.org/resource"); sid := Items.UTF8("հոսք😀"); name := Items.UTF8("ֆայլ😀.bin");
  Success; RangesAndFailures; ConsentAndLimits; Lifecycle; ReentryAndRouting;
  Out.String("XMPP file-receiver checks passed: "); Out.Int(checks, 0); Out.Ln
END TestXmppFileReceiver.
