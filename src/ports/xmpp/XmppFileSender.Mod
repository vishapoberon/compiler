MODULE XmppFileSender;

(* Exact-peer file-offer negotiation followed by a checked selected IBB range. *)

IMPORT Msg, Channel, S := LongStrings, T := XmppTypes, Items := XmppItems,
  IQ := XmppIQ, SI := XmppStreamInit, Ibb := XmppIbbTransfer, C := XmppClient;

CONST
  maxOffers* = 16;
  negotiating* = 0; starting* = 1; transmitting* = 2;
  done* = 3; cancelled* = 4; timedOut* = 5; peerError* = 6;
  protocolError* = 7; ioError* = 8; disconnected* = 9; sendFailed* = 10;
  invalidRequest* = 1; offline* = 2; queueFull* = 3;

TYPE
  Sender* = POINTER TO SenderDesc;
  Session* = POINTER TO SessionDesc;
  Hook* = POINTER TO HookDesc;
  HookDesc* = RECORD END;
  SessionDesc* = RECORD
    peer-, sid-: T.String;
    offer-: SI.Offer;
    status-: SHORTINT;
    offset-, length-, bytes-: LONGINT;
    request-: IQ.Request;
    transfer-: Ibb.Transfer;
    owner: Sender;
    original: SI.Offer;
    target: T.String;
    reader: Channel.Reader;
    position, blockSize: LONGINT;
  END;
  SenderDesc* = RECORD
    router-: IQ.Router;
    engine-: Ibb.Manager;
    count-: LONGINT;
    active-: BOOLEAN;
    hook: Hook;
    timeout: LONGINT;
    sessions: ARRAY maxOffers OF Session;
  END;
  OfferAction = POINTER TO OfferActionDesc;
  OfferActionDesc = RECORD (IQ.ActionDesc) session: Session END;
  TransferHook = POINTER TO TransferHookDesc;
  TransferHookDesc = RECORD (Ibb.HookDesc) session: Session END;
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (c: Context) GetTemplate(message: Msg.Msg; VAR text: Msg.LString);
BEGIN
  CASE message.code OF
  | offline: S.Long("The file sender or IBB client is not active", text)
  | queueFull: S.Long("The file-offer table is full or this peer/SID is already pending", text)
  ELSE S.Long("Invalid bounded IBB file offer, source or block size", text)
  END
END GetTemplate;

PROCEDURE (h: Hook) Progress*(sender: Sender; session: Session; VAR cancel: BOOLEAN);
BEGIN END Progress;
PROCEDURE (h: Hook) Done*(sender: Sender; session: Session);
BEGIN END Done;

PROCEDURE Live(session: Session): BOOLEAN;
BEGIN RETURN (session # NIL) & (session.status < done) END Live;

PROCEDURE Finish(session: Session; status: SHORTINT);
  VAR sender: Sender; request: IQ.Request; transfer: Ibb.Transfer; i: LONGINT; ignored: BOOLEAN;
BEGIN
  IF ~Live(session) THEN RETURN END;
  sender := session.owner; session.status := status; request := session.request;
  session.request := NIL; session.reader := NIL; transfer := session.transfer;
  FOR i := 0 TO maxOffers-1 DO
    IF sender.sessions[i] = session THEN sender.sessions[i] := NIL; DEC(sender.count) END
  END;
  IF request # NIL THEN ignored := sender.router.Cancel(request) END;
  IF (transfer # NIL) & (transfer.status < Ibb.done) THEN ignored := sender.engine.Cancel(transfer) END;
  sender.hook.Done(sender, session)
END Finish;

PROCEDURE (sender: Sender) Cancel*(session: Session): BOOLEAN;
BEGIN
  IF (session = NIL) OR (session.owner # sender) OR ~Live(session) THEN RETURN FALSE END;
  Finish(session, cancelled); RETURN TRUE
END Cancel;

PROCEDURE (sender: Sender) Stop*;
  VAR sessions: ARRAY maxOffers OF Session; i: LONGINT;
BEGIN
  sender.active := FALSE; sessions := sender.sessions;
  FOR i := 0 TO maxOffers-1 DO IF sessions[i] # NIL THEN Finish(sessions[i], cancelled) END END
END Stop;

PROCEDURE (hook: TransferHook) Progress(manager: Ibb.Manager; transfer: Ibb.Transfer; VAR cancel: BOOLEAN);
  VAR session: Session;
BEGIN
  session := hook.session;
  IF ~Live(session) THEN cancel := TRUE; RETURN END;
  session.transfer := transfer; session.status := transmitting; session.bytes := transfer.bytes;
  session.owner.hook.Progress(session.owner, session, cancel)
END Progress;

PROCEDURE (hook: TransferHook) Done(manager: Ibb.Manager; transfer: Ibb.Transfer);
  VAR session: Session; status: SHORTINT;
BEGIN
  session := hook.session; IF ~Live(session) THEN RETURN END;
  session.transfer := transfer; session.bytes := transfer.bytes;
  CASE transfer.status OF
  | Ibb.done: status := done
  | Ibb.cancelled: IF manager.router.client.state = C.online THEN status := cancelled ELSE status := disconnected END
  | Ibb.timedOut: status := timedOut
  | Ibb.peerError: status := peerError
  | Ibb.ioError: status := ioError
  | Ibb.disconnected: status := disconnected
  | Ibb.sendFailed: status := sendFailed
  ELSE status := protocolError
  END;
  Finish(session, status)
END Done;

PROCEDURE Start(session: Session; selection: SI.Selection);
  VAR reader: Channel.Reader; hook: TransferHook; transfer: Ibb.Transfer; error: Msg.Msg; ignored: BOOLEAN;
BEGIN
  reader := session.reader;
  IF (reader.res # NIL) OR (reader.base = NIL) OR ~reader.base.open THEN Finish(session, ioError); RETURN END;
  session.offset := selection.offset; session.length := selection.length; session.status := starting;
  IF reader.positionable THEN
    reader.SetPos(session.position+selection.offset);
    IF ~Live(session) THEN RETURN END;
    IF reader.res # NIL THEN Finish(session, ioError); RETURN END
  ELSIF selection.offset # 0 THEN Finish(session, ioError); RETURN
  END;
  NEW(hook); hook.session := session;
  transfer := session.owner.engine.SendWithHook(session.target^, session.original.sid^, reader,
    selection.length, session.blockSize, hook, error);
  IF Live(session) THEN
    IF transfer = NIL THEN Finish(session, sendFailed)
    ELSE session.transfer := transfer; session.status := transmitting
    END
  ELSIF (transfer # NIL) & (transfer.status < Ibb.done) THEN ignored := session.owner.engine.Cancel(transfer)
  END
END Start;

PROCEDURE (action: OfferAction) Done(router: IQ.Router; request: IQ.Request);
  VAR session: Session; selection: SI.Selection; status: SHORTINT;
BEGIN
  session := action.session; IF ~Live(session) THEN RETURN END;
  session.request := NIL;
  IF request.status = IQ.result THEN
    selection := SI.ReadSelection(request);
    IF selection = NIL THEN Finish(session, protocolError) ELSE Start(session, selection) END
  ELSE
    CASE request.status OF
    | IQ.timedOut: status := timedOut
    | IQ.stanzaError: status := peerError
    | IQ.cancelled: IF router.client.state = C.online THEN status := cancelled ELSE status := disconnected END
    | IQ.sendFailed: status := sendFailed
    ELSE status := protocolError
    END;
    Finish(session, status)
  END
END Done;

PROCEDURE (sender: Sender) Offer*(peer: ARRAY OF T.CodeUnit; offer: SI.Offer; reader: Channel.Reader;
                                 blockSize: LONGINT; VAR error: Msg.Msg): Session;
  VAR original: SI.Offer; target: T.String; payload: Items.Item; session: Session;
    action: OfferAction; request: IQ.Request; position, slot, i: LONGINT; ignored: BOOLEAN;
BEGIN
  error := NIL;
  IF ~sender.active OR ~sender.engine.active THEN error := Msg.New(context, offline); RETURN NIL END;
  target := IQ.CanonicalJID(peer); payload := SI.Build(offer); original := SI.ReadOffer(payload);
  IF (target = NIL) OR (original = NIL) OR (reader = NIL) OR (reader.base = NIL) OR ~reader.base.open OR
    (reader.res # NIL) OR (original.methods # {SI.ibb}) OR (original.size > sender.engine.maximum) OR
    (blockSize < 1) OR (blockSize > sender.engine.maximumBlock) OR (original.range & ~reader.positionable) THEN
    error := Msg.New(context, invalidRequest); RETURN NIL
  END;
  position := 0;
  IF reader.positionable THEN
    position := reader.Pos();
    IF (position < 0) OR (position > MAX(LONGINT)-original.size) OR (reader.res # NIL) THEN
      error := Msg.New(context, invalidRequest); RETURN NIL
    END
  END;
  IF ~sender.active OR ~sender.engine.active THEN error := Msg.New(context, offline); RETURN NIL END;
  slot := maxOffers;
  FOR i := 0 TO maxOffers-1 DO
    session := sender.sessions[i];
    IF session = NIL THEN IF slot = maxOffers THEN slot := i END
    ELSIF S.Equal(session.target^, target^) & S.Equal(session.original.sid^, original.sid^) THEN
      error := Msg.New(context, queueFull); RETURN NIL
    END
  END;
  IF slot = maxOffers THEN error := Msg.New(context, queueFull); RETURN NIL END;
  NEW(session); session.owner := sender; session.original := original; session.target := target;
  session.peer := Items.Copy16(target^); session.sid := Items.Copy16(original.sid^);
  session.offer := SI.ReadOffer(SI.Build(original)); session.reader := reader; session.position := position;
  session.length := original.size; session.blockSize := blockSize; sender.sessions[slot] := session; INC(sender.count);
  NEW(action); action.session := session;
  request := SI.Query(sender.router, target^, original, sender.timeout, action, error);
  IF Live(session) THEN
    IF request = NIL THEN Finish(session, sendFailed)
    ELSIF request.status = IQ.pending THEN session.request := request
    END
  ELSIF (request # NIL) & (request.status = IQ.pending) THEN ignored := sender.router.Cancel(request)
  END;
  RETURN session
END Offer;

PROCEDURE New*(engine: Ibb.Manager; hook: Hook; timeoutMS: LONGINT): Sender;
  VAR sender: Sender;
BEGIN
  IF (engine = NIL) OR (hook = NIL) OR (timeoutMS < 1) OR (timeoutMS > IQ.maxTimeoutMS) THEN RETURN NIL END;
  NEW(sender); sender.engine := engine; sender.router := engine.router; sender.hook := hook;
  sender.timeout := timeoutMS; sender.active := TRUE; RETURN sender
END New;

BEGIN NEW(context); Msg.InitContext(context, "XmppFileSender")
END XmppFileSender.
