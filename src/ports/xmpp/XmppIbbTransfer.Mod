MODULE XmppIbbTransfer;

(* Bounded, consent-driven IQ IBB transfers over checked binary channels. *)

IMPORT Msg, Channel, S := LongStrings, T := XmppTypes, Items := XmppItems,
  Core := XmppCore, C := XmppClient, IQ := XmppIQ, I := XmppIbb;

CONST
  maxTransfers* = 16; maxTransferBytes* = 1024*1024*1024;
  offered* = 0; opening* = 1; transferring* = 2; closing* = 3;
  done* = 4; cancelled* = 5; timedOut* = 6; ioError* = 7;
  protocolError* = 8; peerError* = 9; disconnected* = 10; sendFailed* = 11;
  invalidRequest* = 1; offline* = 2; queueFull* = 3;

TYPE
  Manager* = POINTER TO ManagerDesc;
  Transfer* = POINTER TO TransferDesc;
  Pending = POINTER TO PendingDesc;
  Hook* = POINTER TO HookDesc;
  HookDesc* = RECORD END;
  TransferDesc* = RECORD
    peer-, sid-: T.String;
    sending-: BOOLEAN;
    status-: SHORTINT;
    bytes-, length-, blockSize-, sequence-: LONGINT;
    request-: IQ.Request;
    owner: Manager;
    reader: Channel.Reader;
    writer: Channel.Writer;
    buffer: Items.Bytes;
    remaining, block: LONGINT;
    action: Pending;
  END;
  ManagerDesc* = RECORD (C.HookDesc)
    router-: IQ.Router;
    active-: BOOLEAN;
    count-: LONGINT;
    application: C.Hook;
    hook: Hook;
    maximum, maximumBlock, timeout: LONGINT;
    transfers: ARRAY maxTransfers OF Transfer;
  END;
  Handler = POINTER TO HandlerDesc;
  HandlerDesc = RECORD (IQ.HandlerDesc) owner: Manager END;
  PendingDesc = RECORD (IQ.ActionDesc) transfer: Transfer END;
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (c: Context) GetTemplate(message: Msg.Msg; VAR text: Msg.LString);
BEGIN
  CASE message.code OF
  | offline: S.Long("The IBB client is not online", text)
  | queueFull: S.Long("The bounded IBB transfer table is full or the peer/SID is already active", text)
  ELSE S.Long("Invalid bounded IBB transfer configuration or source", text)
  END
END GetTemplate;

PROCEDURE (h: Hook) Incoming*(manager: Manager; transfer: Transfer;
                             VAR writer: Channel.Writer; VAR maximum: LONGINT): BOOLEAN;
BEGIN RETURN FALSE END Incoming;
PROCEDURE (h: Hook) Progress*(manager: Manager; transfer: Transfer; VAR cancel: BOOLEAN);
BEGIN END Progress;
PROCEDURE (h: Hook) Complete*(manager: Manager; transfer: Transfer): BOOLEAN;
BEGIN RETURN TRUE END Complete;
PROCEDURE (h: Hook) Done*(manager: Manager; transfer: Transfer);
BEGIN END Done;

PROCEDURE Live(t: Transfer): BOOLEAN;
BEGIN RETURN (t # NIL) & (t.status < done) END Live;

PROCEDURE Slot(m: Manager): LONGINT;
  VAR i: LONGINT;
BEGIN
  i := 0; WHILE (i < maxTransfers) & (m.transfers[i] # NIL) DO INC(i) END;
  RETURN i
END Slot;

PROCEDURE Find(m: Manager; peer, sid: T.String): Transfer;
  VAR i: LONGINT; t: Transfer;
BEGIN
  IF (peer = NIL) OR (sid = NIL) THEN RETURN NIL END;
  FOR i := 0 TO maxTransfers-1 DO
    t := m.transfers[i];
    IF (t # NIL) & S.Equal(t.peer^, peer^) & S.Equal(t.sid^, sid^) THEN RETURN t END
  END;
  RETURN NIL
END Find;

PROCEDURE BestEffortClose(t: Transfer);
  VAR request: IQ.Request; action: IQ.Action; error: Msg.Msg; ignored: BOOLEAN; m: Manager;
BEGIN
  m := t.owner;
  IF ~m.active OR (m.router.client.state # C.online) THEN RETURN END;
  NEW(action); request := m.router.QueryExact(t.peer^, I.Close(t.sid^), TRUE, m.timeout, action, error);
  IF request # NIL THEN ignored := m.router.Cancel(request) END
END BestEffortClose;

PROCEDURE Finish(t: Transfer; status: SHORTINT; close: BOOLEAN);
  VAR m: Manager; request: IQ.Request; i: LONGINT; ignored: BOOLEAN;
BEGIN
  IF ~Live(t) THEN RETURN END;
  m := t.owner; t.status := status; request := t.request; t.request := NIL; t.action := NIL;
  FOR i := 0 TO maxTransfers-1 DO
    IF m.transfers[i] = t THEN m.transfers[i] := NIL; DEC(m.count) END
  END;
  t.reader := NIL; t.writer := NIL; t.buffer := NIL;
  IF request # NIL THEN ignored := m.router.Cancel(request) END;
  IF close THEN BestEffortClose(t) END;
  m.hook.Done(m, t)
END Finish;

PROCEDURE Progress(t: Transfer);
  VAR cancel: BOOLEAN;
BEGIN
  cancel := FALSE; t.owner.hook.Progress(t.owner, t, cancel);
  IF cancel THEN Finish(t, cancelled, TRUE) END
END Progress;

PROCEDURE (m: Manager) Cancel*(t: Transfer): BOOLEAN;
BEGIN
  IF (t = NIL) OR (t.owner # m) OR ~Live(t) THEN RETURN FALSE END;
  Finish(t, cancelled, TRUE); RETURN TRUE
END Cancel;

PROCEDURE Stop(m: Manager; status: SHORTINT);
  VAR transfers: ARRAY maxTransfers OF Transfer; i: LONGINT;
BEGIN
  m.active := FALSE; transfers := m.transfers;
  FOR i := 0 TO maxTransfers-1 DO
    IF transfers[i] # NIL THEN Finish(transfers[i], status, FALSE) END
  END
END Stop;

PROCEDURE (m: Manager) Stop*;
BEGIN Stop(m, cancelled) END Stop;

PROCEDURE Queue(t: Transfer; item: Items.Item);
  VAR action: Pending; request: IQ.Request; error: Msg.Msg; ignored: BOOLEAN;
BEGIN
  IF ~Live(t) THEN RETURN END;
  NEW(action); action.transfer := t; t.action := action; t.request := NIL;
  request := t.owner.router.QueryExact(t.peer^, item, TRUE, t.owner.timeout, action, error);
  (* Sending can synchronously fail or call application hooks. *)
  IF Live(t) & (t.action = action) THEN
    IF request = NIL THEN Finish(t, sendFailed, TRUE)
    ELSIF request.status = IQ.pending THEN t.request := request
    END
  ELSIF (request # NIL) & (request.status = IQ.pending) THEN
    ignored := t.owner.router.Cancel(request)
  END
END Queue;

PROCEDURE Pump(t: Transfer);
  VAR count: LONGINT; item: Items.Item; reader: Channel.Reader; buffer: Items.Bytes;
BEGIN
  IF ~Live(t) THEN RETURN END;
  IF t.bytes = t.length THEN t.status := closing; Queue(t, I.Close(t.sid^)); RETURN END;
  count := t.length-t.bytes; IF count > t.blockSize THEN count := t.blockSize END;
  IF (t.reader.res # NIL) OR (t.reader.base = NIL) OR ~t.reader.base.open THEN
    Finish(t, ioError, TRUE); RETURN
  END;
  reader := t.reader; buffer := t.buffer; reader.ReadBytes(buffer^, 0, count);
  IF ~Live(t) THEN RETURN END;
  IF (reader.res # NIL) OR (reader.bytesRead # count) THEN Finish(t, ioError, TRUE); RETURN END;
  item := I.Data(t.sid^, t.sequence, t.buffer^, 0, count); t.block := count;
  Queue(t, item)
END Pump;

PROCEDURE (a: Pending) Done(router: IQ.Router; request: IQ.Request);
  VAR t: Transfer; status: SHORTINT; from: T.String;
BEGIN
  t := a.transfer;
  IF ~Live(t) OR (t.action # a) THEN RETURN END;
  t.request := NIL; t.action := NIL;
  IF (request.status = IQ.result) OR (request.status = IQ.stanzaError) THEN
    from := IQ.CanonicalJID(request.reply.from^);
    IF (from = NIL) OR ~S.Equal(from^, t.peer^) THEN Finish(t, protocolError, TRUE); RETURN END
  END;
  IF ~IQ.EmptyResult(request) THEN
    CASE request.status OF
    | IQ.timedOut: status := timedOut
    | IQ.stanzaError: status := peerError
    | IQ.cancelled: status := cancelled
    | IQ.sendFailed: status := sendFailed
    ELSE status := protocolError
    END;
    Finish(t, status, TRUE); RETURN
  END;
  IF t.status = closing THEN Finish(t, done, FALSE)
  ELSE
    IF t.status = transferring THEN
      INC(t.bytes, t.block); t.sequence := I.NextSequence(t.sequence); Progress(t)
    ELSE t.status := transferring
    END;
    IF Live(t) THEN Pump(t) END
  END
END Done;

PROCEDURE (m: Manager) Send*(peer, sid: ARRAY OF T.CodeUnit; reader: Channel.Reader;
                           length, blockSize: LONGINT; VAR error: Msg.Msg): Transfer;
  VAR t: Transfer; target: T.String; slot: LONGINT;
BEGIN
  error := NIL;
  IF ~m.active OR (m.router.client.state # C.online) THEN
    error := Msg.New(context, offline); RETURN NIL
  END;
  target := IQ.CanonicalJID(peer);
  IF (target = NIL) OR ~I.SID(sid) OR (reader = NIL) OR (reader.base = NIL) OR
     ~reader.base.open OR (reader.res # NIL) OR (length < 0) OR (length > m.maximum) OR
     (blockSize < 1) OR (blockSize > m.maximumBlock) THEN error := Msg.New(context, invalidRequest); RETURN NIL END;
  slot := Slot(m);
  IF (slot = maxTransfers) OR (Find(m, target, Items.Copy16(sid)) # NIL) THEN
    error := Msg.New(context, queueFull); RETURN NIL
  END;
  NEW(t); t.owner := m; t.peer := target; t.sid := Items.Copy16(sid); t.sending := TRUE;
  t.status := opening; t.reader := reader; t.length := length; t.blockSize := blockSize;
  NEW(t.buffer, blockSize); m.transfers[slot] := t; INC(m.count);
  Queue(t, I.Open(t.sid^, blockSize)); RETURN t
END Send;

PROCEDURE (handler: Handler) Accept(router: IQ.Router; request: Core.Stanza): BOOLEAN;
BEGIN RETURN handler.owner.active & (request.from[0] # 0) END Accept;

PROCEDURE (handler: Handler) Handle(router: IQ.Router; request: Core.Stanza; payload: Items.Item): Core.Stanza;
  VAR m: Manager; t: Transfer; peer, sid: T.String; event: I.Event;
    writer: Channel.Writer; maximum, slot, limit: LONGINT; accept: BOOLEAN;
BEGIN
  m := handler.owner;
  IF ~m.active OR ~S.Equal8(request.type^, "set") THEN RETURN IQ.ErrorReply(request, "modify", "bad-request") END;
  peer := IQ.CanonicalJID(request.from^); sid := payload.GetAttribute("", "sid"); t := Find(m, peer, sid);
  limit := m.maximumBlock; IF t # NIL THEN limit := t.blockSize END;
  event := I.Read(payload, limit);
  IF event = NIL THEN
    IF t # NIL THEN Finish(t, protocolError, TRUE) END;
    RETURN IQ.ErrorReply(request, "cancel", "bad-request")
  END;
  IF event.kind = I.opening THEN
    IF t # NIL THEN RETURN IQ.ErrorReply(request, "cancel", "unexpected-request") END;
    slot := Slot(m);
    IF (slot = maxTransfers) OR (event.blockSize > m.maximumBlock) THEN
      RETURN IQ.ErrorReply(request, "modify", "resource-constraint")
    END;
    NEW(t); t.owner := m; t.peer := peer; t.sid := event.sid; t.blockSize := event.blockSize;
    t.status := offered; t.remaining := m.timeout; m.transfers[slot] := t; INC(m.count);
    writer := NIL; maximum := m.maximum; accept := m.hook.Incoming(m, t, writer, maximum);
    IF ~Live(t) THEN RETURN IQ.ErrorReply(request, "cancel", "not-acceptable") END;
    IF ~accept OR (writer = NIL) OR (writer.base = NIL) OR ~writer.base.open OR (writer.res # NIL) OR
       (maximum < 0) OR (maximum > m.maximum) THEN
      Finish(t, cancelled, FALSE); RETURN IQ.ErrorReply(request, "cancel", "not-acceptable")
    END;
    t.writer := writer; t.length := maximum; t.status := transferring;
    RETURN IQ.Response(request, NIL)
  END;
  IF t = NIL THEN RETURN IQ.ErrorReply(request, "cancel", "item-not-found") END;
  IF event.kind = I.closing THEN
    IF t.sending THEN Finish(t, peerError, FALSE)
    ELSE
      writer := t.writer;
      IF (writer = NIL) OR (writer.res # NIL) OR ~writer.base.open THEN Finish(t, ioError, FALSE); RETURN IQ.ErrorReply(request, "wait", "internal-server-error") END;
      writer.base.Flush;
      IF ~Live(t) THEN RETURN IQ.ErrorReply(request, "cancel", "not-acceptable") END;
      IF writer.base.res # NIL THEN Finish(t, ioError, FALSE); RETURN IQ.ErrorReply(request, "wait", "internal-server-error") END;
      accept := m.hook.Complete(m, t);
      IF ~Live(t) THEN RETURN IQ.ErrorReply(request, "cancel", "not-acceptable") END;
      IF ~accept THEN Finish(t, protocolError, FALSE); RETURN IQ.ErrorReply(request, "cancel", "not-acceptable") END;
      Finish(t, done, FALSE)
    END;
    RETURN IQ.Response(request, NIL)
  END;
  IF t.sending OR (t.status # transferring) THEN RETURN IQ.ErrorReply(request, "cancel", "unexpected-request") END;
  IF (event.sequence # t.sequence) OR (event.length > t.length-t.bytes) THEN
    Finish(t, protocolError, TRUE); RETURN IQ.ErrorReply(request, "cancel", "unexpected-request")
  END;
  IF (t.writer.res # NIL) OR ~t.writer.base.open THEN
    Finish(t, ioError, TRUE); RETURN IQ.ErrorReply(request, "wait", "internal-server-error")
  END;
  writer := t.writer; writer.WriteBytes(event.bytes^, 0, event.length);
  IF ~Live(t) THEN RETURN IQ.ErrorReply(request, "cancel", "not-acceptable") END;
  IF (writer.res # NIL) OR (writer.bytesWritten # event.length) THEN
    Finish(t, ioError, TRUE); RETURN IQ.ErrorReply(request, "wait", "internal-server-error")
  END;
  INC(t.bytes, event.length); t.sequence := I.NextSequence(t.sequence); t.remaining := m.timeout; Progress(t);
  IF ~Live(t) THEN RETURN IQ.ErrorReply(request, "cancel", "not-acceptable") END;
  RETURN IQ.Response(request, NIL)
END Handle;

PROCEDURE (m: Manager) Tick*(elapsedMS: LONGINT);
  VAR transfers: ARRAY maxTransfers OF Transfer; i: LONGINT; t: Transfer;
BEGIN
  ASSERT(elapsedMS >= 0); transfers := m.transfers;
  FOR i := 0 TO maxTransfers-1 DO
    t := transfers[i];
    IF Live(t) & ~t.sending THEN
      IF elapsedMS >= t.remaining THEN Finish(t, timedOut, TRUE) ELSE DEC(t.remaining, elapsedMS) END
    END
  END
END Tick;

PROCEDURE (m: Manager) Ready*(client: C.Client; jid: T.String);
BEGIN m.active := TRUE; m.application.Ready(client, jid) END Ready;
PROCEDURE (m: Manager) RegistrationReady*(client: C.Client);
BEGIN m.application.RegistrationReady(client) END RegistrationReady;
PROCEDURE (m: Manager) Received*(client: C.Client; stanza: Core.Stanza);
BEGIN m.application.Received(client, stanza) END Received;
PROCEDURE (m: Manager) Sent*(client: C.Client; stanza: Core.Stanza);
BEGIN m.application.Sent(client, stanza) END Sent;
PROCEDURE (m: Manager) Error*(client: C.Client; error: Msg.Msg);
BEGIN Stop(m, disconnected); m.application.Error(client, error) END Error;
PROCEDURE (m: Manager) Closed*(client: C.Client);
BEGIN Stop(m, disconnected); m.application.Closed(client) END Closed;

PROCEDURE New*(application: C.Hook; hook: Hook; maximum, maximumBlock, timeoutMS: LONGINT): Manager;
  VAR m: Manager; handler: Handler;
BEGIN
  IF (application = NIL) OR (hook = NIL) OR (maximum < 0) OR (maximum > maxTransferBytes) OR
     (maximumBlock < 1) OR (maximumBlock > I.maxBlockSize) OR (timeoutMS < 1) OR
     (timeoutMS > IQ.maxTimeoutMS) THEN RETURN NIL END;
  NEW(m); m.application := application; m.hook := hook; m.maximum := maximum;
  m.maximumBlock := maximumBlock; m.timeout := timeoutMS; m.router := IQ.New(m);
  NEW(handler); handler.owner := m;
  ASSERT(m.router.Register(I.namespaceURI, "open", handler));
  ASSERT(m.router.Register(I.namespaceURI, "data", handler));
  ASSERT(m.router.Register(I.namespaceURI, "close", handler));
  RETURN m
END New;

BEGIN NEW(context); Msg.InitContext(context, "XmppIbbTransfer")
END XmppIbbTransfer.
