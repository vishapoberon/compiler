MODULE XmppPing;

(* XEP-0199 ping requests and empty IQ result replies. *)

IMPORT Msg, S := LongStrings, T := XmppTypes, Items := XmppItems, Core := XmppCore, IQ := XmppIQ;

CONST namespaceURI* = "urn:xmpp:ping";
TYPE Pinger* = POINTER TO PingerDesc;
  PingerDesc* = RECORD (IQ.HandlerDesc) END;

PROCEDURE (p: Pinger) Handle*(router: IQ.Router; request: Core.Stanza; payload: Items.Item): Core.Stanza;
BEGIN
  IF ~S.Equal8(request.type^, "get") OR ~IQ.Empty(payload) THEN RETURN IQ.ErrorReply(request, "modify", "bad-request") END;
  RETURN IQ.Response(request, NIL)
END Handle;

PROCEDURE Query*(router: IQ.Router; to: ARRAY OF T.CodeUnit; timeoutMS: LONGINT;
                  action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
BEGIN RETURN router.Query(to, Items.New("ping", namespaceURI), FALSE, timeoutMS, action, error) END Query;

PROCEDURE New*(router: IQ.Router): Pinger;
  VAR p: Pinger;
BEGIN NEW(p); IF ~router.Register(namespaceURI, "ping", p) THEN RETURN NIL END; RETURN p END New;

END XmppPing.
