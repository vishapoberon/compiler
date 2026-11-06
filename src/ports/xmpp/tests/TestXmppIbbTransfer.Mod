MODULE TestXmppIbbTransfer;

IMPORT SYSTEM, Out, Msg, Channel, S := LongStrings, T := XmppTypes,
  Items := XmppItems, Core := XmppCore, Wire := XmppWire, C := XmppClient,
  IQ := XmppIQ, I := XmppIbb, X := XmppIbbTransfer, Gen := XmppXmlGen,
  Strings := oocStrings;

TYPE
  Transport = POINTER TO TransportDesc;
  TransportDesc = RECORD (Wire.TransportDesc) script: Items.Bytes; position, chunk: LONGINT; fail: BOOLEAN END;
  Store = POINTER TO StoreDesc;
  StoreDesc = RECORD (Channel.ChannelDesc)
    bytes: ARRAY 131072 OF CHAR; length: LONGINT; badFlush: BOOLEAN; stopFlush: X.Manager
  END;
  Reader = POINTER TO ReaderDesc;
  ReaderDesc = RECORD (Channel.ReaderDesc) position: LONGINT; short: BOOLEAN; stopRead: X.Manager END;
  Writer = POINTER TO WriterDesc;
  WriterDesc = RECORD (Channel.WriterDesc) short, fail: BOOLEAN; stopWrite: X.Manager END;
  Application = POINTER TO ApplicationDesc;
  ApplicationDesc = RECORD (C.HookDesc)
    last: Core.Stanza; sent, ready, closed, errors: LONGINT; stopSend: X.Manager
  END;
  Hook = POINTER TO HookDesc;
  HookDesc = RECORD (X.HookDesc)
    writer: Writer; accept, cancel, stopIncoming: BOOLEAN; maximum: LONGINT;
    incoming, progress, finished: LONGINT; last: X.Transfer;
    restart: Reader; restarted: X.Transfer
  END;
  Fixture = POINTER TO FixtureDesc;
  FixtureDesc = RECORD c: C.Client; m: X.Manager; h: Hook; app: Application; wire: Transport; store: Store END;

VAR checks, serial: LONGINT; peer, sid: T.String; fault: Msg.Msg;

PROCEDURE Check(ok: BOOLEAN; name: ARRAY OF CHAR);
BEGIN
  IF ~ok THEN Out.String("IBB transfer check failed: "); Out.String(name); Out.Ln; HALT(1) END;
  INC(checks)
END Check;

PROCEDURE (s: Store) Flush;
BEGIN
  IF s.stopFlush # NIL THEN s.stopFlush.Stop END;
  IF s.badFlush THEN s.res := fault ELSE s.res := NIL END
END Flush;
PROCEDURE (r: Reader) ReadBytes(VAR bytes: ARRAY OF SYSTEM.BYTE; start, count: LONGINT);
  VAR s: Store; i: LONGINT;
BEGIN
  s := r.base(Store); r.bytesRead := count;
  IF r.short & (count > 0) THEN DEC(r.bytesRead) END;
  IF r.bytesRead > s.length-r.position THEN r.bytesRead := s.length-r.position END;
  FOR i := 0 TO r.bytesRead-1 DO bytes[start+i] := SYSTEM.VAL(SYSTEM.BYTE, s.bytes[r.position+i]) END;
  INC(r.position, r.bytesRead); r.res := NIL;
  IF r.stopRead # NIL THEN r.stopRead.Stop END
END ReadBytes;
PROCEDURE (w: Writer) WriteBytes(VAR bytes: ARRAY OF SYSTEM.BYTE; start, count: LONGINT);
  VAR s: Store; i: LONGINT;
BEGIN
  s := w.base(Store); w.bytesWritten := count; w.res := NIL;
  IF w.short & (count > 0) THEN DEC(w.bytesWritten) END;
  IF w.fail THEN w.res := fault; w.bytesWritten := 0 END;
  ASSERT(s.length+w.bytesWritten <= LEN(s.bytes));
  FOR i := 0 TO w.bytesWritten-1 DO s.bytes[s.length+i] := SYSTEM.VAL(CHAR, bytes[start+i]) END;
  INC(s.length, w.bytesWritten);
  IF w.stopWrite # NIL THEN w.stopWrite.Stop END
END WriteBytes;
PROCEDURE (w: Transport) AuthenticatedFor(domain: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN domain = "example.org" END AuthenticatedFor;
PROCEDURE (w: Transport) Read(VAR bytes: ARRAY OF CHAR; VAR count: LONGINT): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  count := S.Length8(w.script^)-w.position; IF count > LEN(bytes) THEN count := LEN(bytes) END;
  IF count > w.chunk THEN count := w.chunk END;
  FOR i := 0 TO count-1 DO bytes[i] := w.script[w.position+i] END; INC(w.position, count); RETURN TRUE
END Read;
PROCEDURE (w: Transport) WriteBytes(VAR bytes: ARRAY OF SYSTEM.BYTE; start, count: LONGINT);
BEGIN IF w.fail THEN w.bytesWritten := 0; w.res := fault ELSE w.bytesWritten := count; w.res := NIL END END WriteBytes;
PROCEDURE (w: Transport) Close;
BEGIN END Close;
PROCEDURE (a: Application) Ready(client: C.Client; jid: T.String);
BEGIN INC(a.ready) END Ready;
PROCEDURE (a: Application) Sent(client: C.Client; stanza: Core.Stanza);
BEGIN
  a.last := stanza; INC(a.sent);
  IF (a.stopSend # NIL) & (stanza.item.First(I.namespaceURI, "open") # NIL) THEN a.stopSend.Stop END
END Sent;
PROCEDURE (a: Application) Closed(client: C.Client);
BEGIN INC(a.closed) END Closed;
PROCEDURE (a: Application) Error(client: C.Client; error: Msg.Msg);
BEGIN INC(a.errors) END Error;
PROCEDURE (h: Hook) Incoming(manager: X.Manager; transfer: X.Transfer;
  VAR writer: Channel.Writer; VAR maximum: LONGINT): BOOLEAN;
BEGIN
  INC(h.incoming); h.last := transfer; writer := h.writer; maximum := h.maximum;
  IF h.stopIncoming THEN manager.Stop END;
  RETURN h.accept
END Incoming;
PROCEDURE (h: Hook) Progress(manager: X.Manager; transfer: X.Transfer; VAR cancel: BOOLEAN);
BEGIN INC(h.progress); cancel := h.cancel END Progress;
PROCEDURE (h: Hook) Done(manager: X.Manager; transfer: X.Transfer);
  VAR reader: Reader; error: Msg.Msg;
BEGIN
  INC(h.finished); h.last := transfer; ASSERT(manager.count < X.maxTransfers);
  IF h.restart # NIL THEN
    reader := h.restart; h.restart := NIL;
    h.restarted := manager.Send(transfer.peer^, transfer.sid^, reader, 0, 1, error); ASSERT(error = NIL)
  END
END Done;

PROCEDURE NewNamed(name: ARRAY OF CHAR): Fixture;
  VAR f: Fixture; text: T.String; error: Msg.Msg; state: SHORTINT;
BEGIN
  NEW(f); NEW(f.h); NEW(f.app); NEW(f.wire); NEW(f.store); NEW(f.h.writer);
  f.store.open := TRUE; f.store.writable := TRUE; f.store.readable := TRUE;
  f.h.writer.base := f.store; f.h.accept := TRUE; f.h.maximum := 131072;
  f.m := X.New(f.app, f.h, 131072, 1024, 100); ASSERT(f.m # NIL);
  f.wire.chunk := 8192; NEW(f.wire.script, 2048);
  COPY('<s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0"><s:features><mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><mechanism>PLAIN</mechanism></mechanisms></s:features><success xmlns="urn:ietf:params:xml:ns:xmpp-sasl"/><s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client" version="1.0"><s:features><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></s:features><iq id="voc-bind-1" type="result"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>', f.wire.script^);
  Strings.Append(name, f.wire.script^); Strings.Append('@example.org/r</jid></bind></iq>', f.wire.script^);
  text := Items.Latin1("user"); f.c := C.New(f.wire, f.m.router, "example.org", text^, text^, text^, TRUE, error);
  ASSERT((error = NIL) & (f.c # NIL) & f.c.Start());
  REPEAT state := f.c.Step() UNTIL (state = C.online) OR (state = C.failed);
  ASSERT((state = C.online) & f.m.active & (f.app.ready = 1)); f.app.last := NIL; RETURN f
END NewNamed;

PROCEDURE New(): Fixture;
BEGIN RETURN NewNamed("user") END New;

PROCEDURE Dispose(f: Fixture);
BEGIN f.m.Stop; f.m.router.Stop; f.c.Abort END Dispose;

PROCEDURE Param(item: Items.Item; name, value: ARRAY OF CHAR);
  VAR text: T.String;
BEGIN text := Items.Latin1(value); item.SetParam(name, text^) END Param;

PROCEDURE Incoming(f: Fixture; from: T.String; item: Items.Item);
  VAR iq: Items.Item;
BEGIN
  iq := Items.New("iq", "jabber:client"); Param(iq, "type", "set"); Param(iq, "id", "peer-request");
  iq.SetParam("from", from^); iq.AddChild(item); f.m.router.Received(f.c, Core.Wrap(iq, NIL))
END Incoming;

PROCEDURE Reply(f: Fixture; from: T.String; request: IQ.Request; kind: ARRAY OF CHAR; content: Items.Item);
  VAR iq: Items.Item;
BEGIN
  iq := Items.New("iq", "jabber:client"); Param(iq, "type", kind); iq.SetParam("id", request.id^);
  iq.SetParam("from", from^); IF content # NIL THEN iq.AddChild(content) END;
  f.m.router.Received(f.c, Core.Wrap(iq, NIL))
END Reply;

PROCEDURE Source(length: LONGINT): Reader;
  VAR r: Reader; s: Store; i: LONGINT;
BEGIN
  NEW(s); s.open := TRUE; s.readable := TRUE; s.length := length;
  FOR i := 0 TO length-1 DO s.bytes[i] := CHR(i MOD 256) END;
  NEW(r); r.base := s; RETURN r
END Source;

PROCEDURE IsError(f: Fixture; condition: ARRAY OF CHAR): BOOLEAN;
  VAR error: Items.Item;
BEGIN
  IF ~S.Equal8(f.app.last.type^, "error") THEN RETURN FALSE END;
  error := f.app.last.item.First("jabber:client", "error");
  RETURN (error # NIL) & (error.First("urn:ietf:params:xml:ns:xmpp-stanzas", condition) # NIL)
END IsError;

PROCEDURE Receive;
  VAR f: Fixture; t: X.Transfer; raw: ARRAY 256 OF CHAR; other: T.String; i: LONGINT;
BEGIN
  f := New(); Incoming(f, peer, I.Open(sid^, 256)); t := f.h.last;
  Check((t.status = X.transferring) & (f.m.count = 1) & (f.h.incoming = 1), "explicitly accepting receive stream");
  FOR i := 0 TO 255 DO raw[i] := CHR(i) END;
  other := Items.Latin1("peer@example.org/other"); Incoming(f, other, I.Data(sid^, 0, raw, 0, 256));
  Check(IsError(f, "item-not-found") & (f.store.length = 0) & (t.status = X.transferring), "rejecting another resource with the same SID");
  other := Items.Latin1("different"); Incoming(f, peer, I.Data(other^, 0, raw, 0, 256));
  Check(IsError(f, "item-not-found") & (f.store.length = 0), "rejecting unknown SID");
  Incoming(f, peer, I.Data(sid^, 0, raw, 0, 256));
  Check((t.bytes = 256) & (t.sequence = 1) & (f.store.length = 256) & (f.h.progress = 1), "writing binary data once");
  FOR i := 0 TO 255 DO ASSERT(f.store.bytes[i] = raw[i]) END;
  Incoming(f, peer, I.Open(sid^, 256));
  Check(IsError(f, "unexpected-request") & (f.h.incoming = 1), "not replacing an active stream");
  Incoming(f, peer, I.Close(sid^));
  Check((t.status = X.done) & (f.m.count = 0) & (f.h.finished = 1) & (f.m.router.count = 0), "flushing and acknowledging close");
  Incoming(f, peer, I.Data(sid^, 1, raw, 0, 1));
  Check(IsError(f, "item-not-found") & (f.store.length = 256), "not writing after closure"); Dispose(f);
  f := New(); f.h.accept := FALSE; Incoming(f, peer, I.Open(sid^, 1));
  Check(IsError(f, "not-acceptable") & (f.m.count = 0) & (f.store.length = 0), "requiring receive consent"); Dispose(f);
  f := New(); f.h.stopIncoming := TRUE; Incoming(f, peer, I.Open(sid^, 1));
  Check(~f.m.active & (f.m.count = 0) & (f.h.finished = 1), "stopping during consent callback"); Dispose(f)
END Receive;

PROCEDURE InvalidBlocks;
  VAR f: Fixture; t: X.Transfer; raw: ARRAY 4 OF CHAR; item: Items.Item; text: T.String; mode: LONGINT;
BEGIN
  raw := "abc";
  FOR mode := 0 TO 5 DO
    f := New(); Incoming(f, peer, I.Open(sid^, 2)); t := f.h.last;
    CASE mode OF
    | 0: item := I.Data(sid^, 1, raw, 0, 1)
    | 1: item := I.Data(sid^, 0, raw, 0, 3)
    | 2: item := Items.New("data", I.namespaceURI); item.SetParam("sid", sid^); Param(item, "seq", "0");
         text := Items.Latin1("Zh=="); item.AddText(text^, 0, 4)
    | 3: f.h.maximum := 1; Dispose(f); f := New(); f.h.maximum := 1;
         Incoming(f, peer, I.Open(sid^, 2)); t := f.h.last; item := I.Data(sid^, 0, raw, 0, 2)
    | 4: f.h.writer.short := TRUE; item := I.Data(sid^, 0, raw, 0, 2)
    | 5: f.h.writer.fail := TRUE; item := I.Data(sid^, 0, raw, 0, 2)
    ELSE HALT(1)
    END;
    Incoming(f, peer, item);
    Check((t.status >= X.done) & (t.status # X.done) & (f.m.count = 0) & (f.h.finished = 1), "failing an invalid block or I/O failure");
    IF mode < 4 THEN Check(f.store.length = 0, "not writing invalid data") END;
    Incoming(f, peer, I.Data(sid^, 0, raw, 0, 1)); Check(IsError(f, "item-not-found"), "discarding following blocks after failure"); Dispose(f)
  END;
  f := New(); Incoming(f, peer, I.Open(sid^, 2)); t := f.h.last;
  Incoming(f, peer, I.Data(sid^, 0, raw, 0, 1)); Incoming(f, peer, I.Data(sid^, 0, raw, 0, 1));
  Check((t.status = X.protocolError) & (f.store.length = 1), "rejecting duplicate sequence without writing twice"); Dispose(f);
  f := New(); Incoming(f, peer, I.Open(sid^, 2)); t := f.h.last; f.store.badFlush := TRUE; Incoming(f, peer, I.Close(sid^));
  Check((t.status = X.ioError) & IsError(f, "internal-server-error"), "checking final flush result"); Dispose(f)
END InvalidBlocks;

PROCEDURE Send;
  VAR f: Fixture; t: X.Transfer; r: Reader; error: Msg.Msg; previous: IQ.Request; wrong: T.String; i: LONGINT;
BEGIN
  f := New(); r := Source(513); t := f.m.Send(peer^, sid^, r, 513, 256, error);
  Check((t # NIL) & (error = NIL) & (t.status = X.opening) & (r.position = 0), "waiting for open acknowledgement before reading");
  previous := t.request; wrong := Items.Latin1("peer@example.org/spoof"); Reply(f, wrong, previous, "result", NIL);
  Check((t.request = previous) & (t.status = X.opening), "matching exact sender for acknowledgements");
  Reply(f, peer, previous, "result", NIL);
  Check((t.status = X.transferring) & (r.position = 256) & (t.bytes = 0), "sending one bounded block");
  FOR i := 0 TO 2 DO
    previous := t.request; Reply(f, peer, previous, "result", NIL);
    Check((t.bytes > 0) & (f.m.router.count = 1), "retaining one pending acknowledgement")
  END;
  Check((t.status = X.closing) & (t.bytes = 513) & (r.position = 513), "closing only the explicit source range");
  previous := t.request; Reply(f, peer, previous, "result", NIL);
  Check((t.status = X.done) & (f.m.count = 0) & (f.m.router.count = 0) & (f.h.finished = 1), "waiting for close acknowledgement"); Dispose(f);
  f := New(); r := Source(0); t := f.m.Send(peer^, sid^, r, 0, 1, error);
  Reply(f, peer, t.request, "result", NIL); Check(t.status = X.closing, "sending an empty transfer without data");
  Reply(f, peer, t.request, "result", NIL); Check(t.status = X.done, "completing empty transfer"); Dispose(f);
  f := New(); r := Source(3); r.short := TRUE; t := f.m.Send(peer^, sid^, r, 3, 3, error);
  Reply(f, peer, t.request, "result", NIL);
  Check((t.status = X.ioError) & (f.m.router.count = 0), "failing short source reads"); Dispose(f)
END Send;

PROCEDURE Lifecycle;
  VAR f: Fixture; t, second: X.Transfer; r: Reader; error: Msg.Msg; raw: ARRAY 1 OF CHAR;
    streams: ARRAY X.maxTransfers OF X.Transfer; id: T.String; i: LONGINT;
BEGIN
  raw[0] := 0X;
  f := New(); Incoming(f, peer, I.Open(sid^, 1)); t := f.h.last; f.m.Tick(99);
  Check(t.status = X.transferring, "retaining receive before idle deadline"); f.m.Tick(1);
  Check((t.status = X.timedOut) & (f.m.count = 0), "expiring idle receive"); Dispose(f);
  f := New(); r := Source(1); t := f.m.Send(peer^, sid^, r, 1, 1, error); f.m.router.Tick(100);
  Check((t.status = X.timedOut) & (f.m.router.count = 0), "expiring outgoing IQ"); Dispose(f);
  f := New(); r := Source(1); t := f.m.Send(peer^, sid^, r, 1, 1, error);
  Check(f.m.Cancel(t) & (t.status = X.cancelled) & (f.m.router.count = 0) & ~f.m.Cancel(t), "cancelling once and releasing pending IQ"); Dispose(f);
  f := New(); Incoming(f, peer, I.Open(sid^, 1)); t := f.h.last; f.h.cancel := TRUE;
  Incoming(f, peer, I.Data(sid^, 0, raw, 0, 1));
  Check((t.status = X.cancelled) & (f.h.finished = 1) & (f.store.length = 1), "cancelling through progress callback"); Dispose(f);
  f := New(); r := Source(1); f.wire.fail := TRUE; t := f.m.Send(peer^, sid^, r, 1, 1, error);
  Check((t # NIL) & (t.status >= X.done) & (f.m.count = 0) & (f.h.finished = 1), "handling synchronous transport failure"); Dispose(f);
  f := New(); Incoming(f, peer, I.Open(sid^, 1)); t := f.h.last;
  f.m.router.Closed(f.c);
  Check((t.status = X.disconnected) & ~f.m.active & (f.h.finished = 1) & (f.app.closed = 1), "cleaning incoming stream on disconnect"); Dispose(f);
  f := New(); r := Source(0);
  FOR i := 0 TO X.maxTransfers-1 DO
    NEW(id, 3); id[0] := ORD("s"); id[1] := ORD("A")+i; id[2] := 0;
    streams[i] := f.m.Send(peer^, id^, r, 0, 1, error); ASSERT(streams[i] # NIL)
  END;
  second := f.m.Send(peer^, sid^, r, 0, 1, error);
  Check((second = NIL) & (error # NIL) & (f.m.count = X.maxTransfers), "bounding simultaneous transfers");
  f.m.Stop; Check((f.m.count = 0) & (f.m.router.count = 0) & (f.h.finished = X.maxTransfers), "stopping every transfer once"); Dispose(f);
  f := New(); Incoming(f, peer, I.Open(sid^, 1)); t := f.h.last;
  FOR i := 0 TO 65535 DO Incoming(f, peer, I.Data(sid^, i, raw, 0, 1)) END;
  Check((t.sequence = 0) & (t.bytes = 65536) & (t.status = X.transferring), "wrapping received sequence after 65535");
  Incoming(f, peer, I.Data(sid^, 0, raw, 0, 1));
  Check((t.sequence = 1) & (t.bytes = 65537), "accepting first block after sequence wrap"); Dispose(f)
END Lifecycle;

PROCEDURE Relay(from, to: Fixture);
  VAR stanza: Core.Stanza; bytes: Items.Bytes; count: LONGINT; error: Msg.Msg; state: SHORTINT;
BEGIN
  stanza := from.app.last; ASSERT(stanza # NIL); from.app.last := NIL;
  stanza.item.SetParam("from", from.c.jid^);
  Gen.Encode(stanza.item, 262144, bytes, count, error); ASSERT(error = NIL);
  to.wire.script := bytes; to.wire.position := 0;
  REPEAT state := to.c.Step(); ASSERT(state = C.online) UNTIL to.wire.position = count
END Relay;

PROCEDURE Paired;
  VAR a, b: Fixture; r: Reader; t: X.Transfer; error: Msg.Msg; mode, length, steps, i: LONGINT;
BEGIN
  FOR mode := 0 TO 3 DO
    CASE mode OF 0: length := 0 | 1: length := 1 | 2: length := 513 | 3: length := 65537 ELSE HALT(1) END;
    a := NewNamed("alice"); b := NewNamed("bob"); a.wire.chunk := 17; b.wire.chunk := 13;
    r := Source(length); t := a.m.Send(b.c.jid^, sid^, r, length, 256, error); ASSERT((t # NIL) & (error = NIL));
    steps := 0;
    REPEAT
      Relay(a, b); Relay(b, a); INC(steps); ASSERT(steps < 1000)
    UNTIL t.status >= X.done;
    Check((t.status = X.done) & (b.h.last.status = X.done) & (b.store.length = length), "paired client binary transfer over fragmented XML");
    FOR i := 0 TO length-1 DO ASSERT(b.store.bytes[i] = CHR(i MOD 256)) END;
    Check((a.m.count = 0) & (b.m.count = 0) & (a.m.router.count = 0) & (b.m.router.count = 0) &
      (a.h.finished = 1) & (b.h.finished = 1), "paired completion and cleanup exactly once");
    Dispose(a); Dispose(b)
  END
END Paired;

PROCEDURE ReentryAndErrors;
  VAR f: Fixture; r: Reader; t: X.Transfer; error: Msg.Msg; raw: ARRAY 2 OF CHAR;
    item: Items.Item; mode: LONGINT;
BEGIN
  raw := "x";
  f := New(); r := Source(1); f.app.stopSend := f.m; t := f.m.Send(peer^, sid^, r, 1, 1, error);
  Check((t.status = X.cancelled) & (f.m.router.count = 0) & (f.h.finished = 1), "stopping during synchronous output hook"); Dispose(f);
  f := New(); r := Source(1); r.stopRead := f.m; t := f.m.Send(peer^, sid^, r, 1, 1, error);
  Reply(f, peer, t.request, "result", NIL);
  Check((t.status = X.cancelled) & (f.m.router.count = 0) & (f.h.finished = 1), "stopping from source adapter"); Dispose(f);
  f := New(); Incoming(f, peer, I.Open(sid^, 1)); t := f.h.last; f.h.writer.stopWrite := f.m;
  Incoming(f, peer, I.Data(sid^, 0, raw, 0, 1));
  Check((t.status = X.cancelled) & (f.h.finished = 1), "stopping from output adapter"); Dispose(f);
  f := New(); Incoming(f, peer, I.Open(sid^, 1)); t := f.h.last; f.store.stopFlush := f.m;
  Incoming(f, peer, I.Close(sid^)); Check((t.status = X.cancelled) & (f.h.finished = 1), "stopping from flush adapter"); Dispose(f);
  f := New(); r := Source(0); t := f.m.Send(peer^, sid^, r, 0, 1, error); f.h.restart := Source(0);
  Reply(f, peer, t.request, "result", NIL); Reply(f, peer, t.request, "result", NIL);
  Check((t.status = X.done) & (f.h.restarted # NIL) & (f.m.count = 1), "reentering after releasing completed transfer slot"); Dispose(f);
  FOR mode := 0 TO 2 DO
    f := New(); r := Source(1); t := f.m.Send(peer^, sid^, r, 1, 1, error);
    CASE mode OF
    | 0: item := Items.New("unexpected", "urn:test"); Reply(f, peer, t.request, "result", item)
    | 1: item := Items.New("error", "jabber:client"); Param(item, "type", "cancel");
         item.AddChild(Items.New("not-acceptable", "urn:ietf:params:xml:ns:xmpp-stanzas")); Reply(f, peer, t.request, "error", item)
    | 2: Incoming(f, peer, I.Close(sid^))
    ELSE HALT(1)
    END;
    Check((t.status >= X.done) & (t.status # X.done) & (f.m.count = 0) & (f.m.router.count = 0), "failing malformed results and peer refusal or close"); Dispose(f)
  END;
  f := New(); f.h.maximum := 131073; Incoming(f, peer, I.Open(sid^, 1));
  Check(IsError(f, "not-acceptable") & (f.m.count = 0), "refusing consent beyond configured byte limit"); Dispose(f);
  f := New(); Incoming(f, peer, I.Open(sid^, 1025));
  Check(IsError(f, "resource-constraint") & (f.h.incoming = 0), "applying local block limit before consent"); Dispose(f);
  f := New(); Incoming(f, peer, I.Open(sid^, 1)); t := f.h.last;
  f.m.Tick(99); Incoming(f, peer, I.Data(sid^, 0, raw, 0, 1)); f.m.Tick(99);
  Check(t.status = X.transferring, "resetting idle deadline after valid block");
  f.m.Tick(1); Check(t.status = X.timedOut, "expiring refreshed idle deadline"); Dispose(f)
END ReentryAndErrors;

BEGIN
  fault := Wire.Error(); peer := Items.Latin1("peer@example.org/resource"); sid := Items.UTF8("հոսք😀");
  Receive; InvalidBlocks; Send; Lifecycle; Paired; ReentryAndErrors;
  Out.String("XMPP IBB transfer checks passed: "); Out.Int(checks, 0); Out.Ln
END TestXmppIbbTransfer.
