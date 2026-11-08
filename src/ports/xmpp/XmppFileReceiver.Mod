MODULE XmppFileReceiver;

(* Deferred file-offer consent and exact-peer IBB receive authorization. *)

IMPORT Msg, Channel, S := LongStrings, T := XmppTypes, Items := XmppItems,
  Core := XmppCore, C := XmppClient, IQ := XmppIQ, SI := XmppStreamInit,
  I := XmppIbb, Ibb := XmppIbbTransfer;

CONST
  maxOffers* = 16;
  offered* = 0; waiting* = 1; receiving* = 2;
  done* = 3; rejected* = 4; cancelled* = 5; timedOut* = 6;
  protocolError* = 7; ioError* = 8; disconnected* = 9; sendFailed* = 10;

TYPE
  Receiver* = POINTER TO ReceiverDesc;
  Session* = POINTER TO SessionDesc;
  Hook* = POINTER TO HookDesc;
  HookDesc* = RECORD END;
  SessionDesc* = RECORD
    peer-, sid-: T.String;
    offer-: SI.Offer;
    status-: SHORTINT;
    offset-, length-, bytes-: LONGINT;
    transfer-: Ibb.Transfer;
    owner: Receiver;
    target: T.String;
    original: SI.Offer;
    request: Core.Stanza;
    writer: Channel.Writer;
    remaining, generation: LONGINT;
  END;
  ReceiverDesc* = RECORD (C.HookDesc)
    router-: IQ.Router;
    active-: BOOLEAN;
    count-: LONGINT;
    application: C.Hook;
    hook: Hook;
    ibb: Ibb.Manager;
    maximum, timeout: LONGINT;
    stopping: SHORTINT;
    sessions: ARRAY maxOffers OF Session;
  END;
  Handler = POINTER TO HandlerDesc;
  HandlerDesc = RECORD (IQ.HandlerDesc) owner: Receiver END;
  Adapter = POINTER TO AdapterDesc;
  AdapterDesc = RECORD (Ibb.HookDesc) owner: Receiver END;

PROCEDURE (h: Hook) Offered*(receiver: Receiver; session: Session);
BEGIN END Offered;
PROCEDURE (h: Hook) Progress*(receiver: Receiver; session: Session; VAR cancel: BOOLEAN);
BEGIN END Progress;
PROCEDURE (h: Hook) Done*(receiver: Receiver; session: Session);
BEGIN END Done;

PROCEDURE Live(session: Session): BOOLEAN;
BEGIN RETURN (session # NIL) & (session.status < done) END Live;

PROCEDURE Slot(receiver: Receiver): LONGINT;
  VAR i: LONGINT;
BEGIN
  i := 0; WHILE (i < maxOffers) & (receiver.sessions[i] # NIL) DO INC(i) END;
  RETURN i
END Slot;

PROCEDURE Find(receiver: Receiver; peer, sid: T.String): Session;
  VAR i: LONGINT; session: Session;
BEGIN
  FOR i := 0 TO maxOffers-1 DO
    session := receiver.sessions[i];
    IF (session # NIL) & S.Equal(session.target^, peer^) & S.Equal(session.original.sid^, sid^) THEN RETURN session END
  END;
  RETURN NIL
END Find;

PROCEDURE ByTransfer(receiver: Receiver; transfer: Ibb.Transfer): Session;
  VAR i: LONGINT;
BEGIN
  FOR i := 0 TO maxOffers-1 DO
    IF (receiver.sessions[i] # NIL) & (receiver.sessions[i].transfer = transfer) THEN RETURN receiver.sessions[i] END
  END;
  RETURN NIL
END ByTransfer;

PROCEDURE Send(receiver: Receiver; response: Core.Stanza): BOOLEAN;
  VAR error: Msg.Msg;
BEGIN
  IF ~receiver.active OR (receiver.router.client.state # C.online) THEN RETURN FALSE END;
  receiver.router.client.Send(response, error); RETURN error = NIL
END Send;

PROCEDURE Close(session: Session);
  VAR request: IQ.Request; action: IQ.Action; error: Msg.Msg; ignored: BOOLEAN; receiver: Receiver;
BEGIN
  receiver := session.owner;
  IF ~receiver.active OR (receiver.router.client.state # C.online) THEN RETURN END;
  NEW(action); request := receiver.router.QueryExact(session.target^, I.Close(session.original.sid^), TRUE, receiver.timeout, action, error);
  IF request # NIL THEN ignored := receiver.router.Cancel(request) END
END Close;

PROCEDURE Finish(session: Session; status: SHORTINT; notify: BOOLEAN);
  VAR receiver: Receiver; transfer: Ibb.Transfer; prior: SHORTINT; i: LONGINT; ignored: BOOLEAN;
BEGIN
  IF ~Live(session) THEN RETURN END;
  receiver := session.owner; prior := session.status; session.status := status;
  FOR i := 0 TO maxOffers-1 DO
    IF receiver.sessions[i] = session THEN receiver.sessions[i] := NIL; DEC(receiver.count) END
  END;
  session.writer := NIL; transfer := session.transfer;
  IF (transfer # NIL) & (transfer.status < Ibb.done) THEN ignored := receiver.ibb.Cancel(transfer)
  ELSIF notify & (prior = offered) THEN ignored := Send(receiver, IQ.ErrorReply(session.request, "cancel", "not-acceptable"))
  ELSIF notify & (prior = waiting) THEN Close(session)
  END;
  session.request := NIL; receiver.hook.Done(receiver, session)
END Finish;

PROCEDURE Stop(receiver: Receiver; status: SHORTINT);
  VAR sessions: ARRAY maxOffers OF Session; i: LONGINT;
BEGIN
  IF receiver.stopping >= done THEN RETURN END;
  receiver.active := FALSE; receiver.stopping := status; sessions := receiver.sessions; receiver.ibb.Stop;
  FOR i := 0 TO maxOffers-1 DO
    IF sessions[i] # NIL THEN Finish(sessions[i], status, FALSE) END
  END
END Stop;

PROCEDURE (receiver: Receiver) Stop*;
BEGIN Stop(receiver, cancelled) END Stop;

PROCEDURE (receiver: Receiver) Reject*(session: Session): BOOLEAN;
BEGIN
  IF (session = NIL) OR (session.owner # receiver) OR (session.status # offered) THEN RETURN FALSE END;
  Finish(session, rejected, TRUE); RETURN TRUE
END Reject;

PROCEDURE (receiver: Receiver) Cancel*(session: Session): BOOLEAN;
BEGIN
  IF (session = NIL) OR (session.owner # receiver) OR ~Live(session) THEN RETURN FALSE END;
  Finish(session, cancelled, TRUE); RETURN TRUE
END Cancel;

PROCEDURE (receiver: Receiver) Accept*(session: Session; writer: Channel.Writer; offset, length: LONGINT): BOOLEAN;
  VAR payload: Items.Item; response: Core.Stanza; sent: BOOLEAN;
BEGIN
  IF (session = NIL) OR (session.owner # receiver) OR (session.status # offered) OR ~receiver.active OR
    (writer = NIL) OR (writer.base = NIL) OR ~writer.base.open OR (writer.res # NIL) THEN RETURN FALSE END;
  payload := SI.Accept(session.original, SI.ibb, offset, length); IF payload = NIL THEN RETURN FALSE END;
  response := IQ.Response(session.request, payload);
  session.offset := offset; session.length := length; session.writer := writer;
  session.status := waiting; session.remaining := receiver.timeout; INC(session.generation);
  sent := Send(receiver, response);
  IF ~sent & Live(session) THEN Finish(session, sendFailed, FALSE) END;
  RETURN sent & ((session.status = waiting) OR (session.status = receiving) OR (session.status = done))
END Accept;

PROCEDURE Remember(request: Core.Stanza): Core.Stanza;
  VAR item: Items.Item;
BEGIN
  item := Items.New("iq", "jabber:client"); item.SetParam("id", request.id^); item.SetParam("from", request.from^);
  IF request.to[0] # 0 THEN item.SetParam("to", request.to^) END;
  RETURN Core.Wrap(item, NIL)
END Remember;

PROCEDURE (handler: Handler) Accept(router: IQ.Router; request: Core.Stanza): BOOLEAN;
BEGIN RETURN handler.owner.active & (request.from[0] # 0) END Accept;

PROCEDURE (handler: Handler) Handle(router: IQ.Router; request: Core.Stanza; payload: Items.Item): Core.Stanza;
  VAR receiver: Receiver; session: Session; offer: SI.Offer; peer: T.String; slot, i: LONGINT;
BEGIN
  receiver := handler.owner;
  IF ~S.Equal8(request.type^, "set") THEN RETURN IQ.ErrorReply(request, "modify", "bad-request") END;
  offer := SI.ReadOffer(payload); peer := IQ.CanonicalJID(request.from^);
  IF (offer = NIL) OR (peer = NIL) THEN RETURN IQ.ErrorReply(request, "modify", "bad-request") END;
  IF ~(SI.ibb IN offer.methods) THEN RETURN IQ.ErrorReply(request, "cancel", "feature-not-implemented") END;
  slot := Slot(receiver);
  IF (slot = maxOffers) OR (offer.size > receiver.maximum) THEN RETURN IQ.ErrorReply(request, "wait", "resource-constraint") END;
  IF Find(receiver, peer, offer.sid) # NIL THEN RETURN IQ.ErrorReply(request, "cancel", "unexpected-request") END;
  FOR i := 0 TO maxOffers-1 DO
    session := receiver.sessions[i];
    IF (session # NIL) & (session.request # NIL) & S.Equal(session.target^, peer^) & S.Equal(session.request.id^, request.id^) THEN
      RETURN IQ.ErrorReply(request, "cancel", "unexpected-request")
    END
  END;
  NEW(session); session.owner := receiver; session.target := peer; session.peer := Items.Copy16(peer^);
  session.sid := Items.Copy16(offer.sid^); session.original := offer; session.offer := SI.ReadOffer(SI.Build(offer));
  session.request := Remember(request); session.length := offer.size; session.remaining := receiver.timeout;
  receiver.sessions[slot] := session; INC(receiver.count); receiver.hook.Offered(receiver, session);
  RETURN IQ.Deferred()
END Handle;

PROCEDURE (adapter: Adapter) Incoming(manager: Ibb.Manager; transfer: Ibb.Transfer;
  VAR writer: Channel.Writer; VAR maximum: LONGINT): BOOLEAN;
  VAR session: Session;
BEGIN
  session := Find(adapter.owner, transfer.peer, transfer.sid);
  IF (session = NIL) OR (session.status # waiting) OR ~adapter.owner.active THEN RETURN FALSE END;
  session.status := receiving; session.transfer := transfer; INC(session.generation);
  writer := session.writer; maximum := session.length; RETURN TRUE
END Incoming;

PROCEDURE (adapter: Adapter) Progress(manager: Ibb.Manager; transfer: Ibb.Transfer; VAR cancel: BOOLEAN);
  VAR session: Session;
BEGIN
  session := ByTransfer(adapter.owner, transfer);
  IF session = NIL THEN cancel := TRUE; RETURN END;
  session.bytes := transfer.bytes; adapter.owner.hook.Progress(adapter.owner, session, cancel)
END Progress;

PROCEDURE (adapter: Adapter) Complete(manager: Ibb.Manager; transfer: Ibb.Transfer): BOOLEAN;
  VAR session: Session;
BEGIN
  session := ByTransfer(adapter.owner, transfer);
  RETURN (session # NIL) & (transfer.bytes = session.length)
END Complete;

PROCEDURE (adapter: Adapter) Done(manager: Ibb.Manager; transfer: Ibb.Transfer);
  VAR session: Session; status: SHORTINT;
BEGIN
  session := ByTransfer(adapter.owner, transfer); IF session = NIL THEN RETURN END;
  session.bytes := transfer.bytes;
  CASE transfer.status OF
  | Ibb.done: status := done
  | Ibb.cancelled: status := cancelled
  | Ibb.timedOut: status := timedOut
  | Ibb.ioError: status := ioError
  | Ibb.disconnected: status := disconnected
  | Ibb.sendFailed: status := sendFailed
  ELSE status := protocolError
  END;
  IF ~adapter.owner.active & (adapter.owner.stopping >= done) THEN status := adapter.owner.stopping END;
  Finish(session, status, FALSE)
END Done;

PROCEDURE (receiver: Receiver) Tick*(elapsedMS: LONGINT);
  VAR sessions: ARRAY maxOffers OF Session; generations: ARRAY maxOffers OF LONGINT; session: Session; i: LONGINT;
BEGIN
  ASSERT(elapsedMS >= 0); IF ~receiver.active THEN RETURN END;
  sessions := receiver.sessions;
  FOR i := 0 TO maxOffers-1 DO IF sessions[i] # NIL THEN generations[i] := sessions[i].generation END END;
  receiver.ibb.Tick(elapsedMS);
  FOR i := 0 TO maxOffers-1 DO
    session := sessions[i];
    IF Live(session) & (session.generation = generations[i]) & (session.status # receiving) THEN
      IF elapsedMS >= session.remaining THEN Finish(session, timedOut, TRUE) ELSE DEC(session.remaining, elapsedMS) END
    END
  END
END Tick;

PROCEDURE (receiver: Receiver) Ready*(client: C.Client; jid: T.String);
BEGIN
  IF receiver.stopping < done THEN receiver.active := TRUE ELSE receiver.ibb.Stop END;
  receiver.application.Ready(client, jid)
END Ready;
PROCEDURE (receiver: Receiver) RegistrationReady*(client: C.Client);
BEGIN receiver.application.RegistrationReady(client) END RegistrationReady;
PROCEDURE (receiver: Receiver) Received*(client: C.Client; stanza: Core.Stanza);
BEGIN receiver.application.Received(client, stanza) END Received;
PROCEDURE (receiver: Receiver) Sent*(client: C.Client; stanza: Core.Stanza);
BEGIN receiver.application.Sent(client, stanza) END Sent;
PROCEDURE (receiver: Receiver) Error*(client: C.Client; error: Msg.Msg);
BEGIN Stop(receiver, disconnected); receiver.application.Error(client, error) END Error;
PROCEDURE (receiver: Receiver) Closed*(client: C.Client);
BEGIN Stop(receiver, disconnected); receiver.application.Closed(client) END Closed;

PROCEDURE New*(application: C.Hook; hook: Hook; maximum, maximumBlock, timeoutMS: LONGINT): Receiver;
  VAR receiver: Receiver; adapter: Adapter; handler: Handler;
BEGIN
  IF (application = NIL) OR (hook = NIL) THEN RETURN NIL END;
  NEW(receiver); NEW(adapter); adapter.owner := receiver;
  receiver.ibb := Ibb.New(receiver, adapter, maximum, maximumBlock, timeoutMS); IF receiver.ibb = NIL THEN RETURN NIL END;
  receiver.router := receiver.ibb.router; receiver.application := application; receiver.hook := hook;
  receiver.maximum := maximum; receiver.timeout := timeoutMS;
  NEW(handler); handler.owner := receiver; ASSERT(receiver.router.Register(SI.namespaceURI, "si", handler));
  RETURN receiver
END New;

END XmppFileReceiver.
