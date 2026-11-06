MODULE TestXmppRegisterNetwork;

IMPORT Args, Out, Msg, S := LongStrings, T := XmppTypes, Core := XmppCore, Items := XmppItems,
  TCP := XmppTCP, C := XmppClient, IQ := XmppIQ, Reg := XmppRegister;

TYPE
  Hook = POINTER TO HookDesc;
  HookDesc = RECORD (C.HookDesc) ready, registrationReady, received, sent, errors, closed: LONGINT END;
  Action = POINTER TO ActionDesc;
  ActionDesc = RECORD (IQ.ActionDesc) calls: LONGINT END;

VAR transport: TCP.Transport; client: C.Client; router: IQ.Router; hook: Hook; action: Action;
  form: Reg.Form; request: IQ.Request; error: Msg.Msg; state: SHORTINT;
  port, mode, direct: ARRAY 64 OF CHAR; domain: ARRAY 256 OF CHAR; empty, value: T.String; success: BOOLEAN;

PROCEDURE (h: Hook) Ready(client: C.Client; jid: T.String);
BEGIN INC(h.ready) END Ready;
PROCEDURE (h: Hook) RegistrationReady(client: C.Client);
BEGIN ASSERT((client.state = C.registering) & ~client.authenticated & (client.jid = NIL)); INC(h.registrationReady) END RegistrationReady;
PROCEDURE (h: Hook) Received(client: C.Client; stanza: Core.Stanza);
BEGIN ASSERT(stanza.kind = Core.iq); INC(h.received) END Received;
PROCEDURE (h: Hook) Sent(client: C.Client; stanza: Core.Stanza);
BEGIN INC(h.sent) END Sent;
PROCEDURE (h: Hook) Error(client: C.Client; error: Msg.Msg);
BEGIN INC(h.errors) END Error;
PROCEDURE (h: Hook) Closed(client: C.Client);
BEGIN INC(h.closed) END Closed;
PROCEDURE (a: Action) Done(router: IQ.Router; request: IQ.Request);
BEGIN ASSERT(request.status = IQ.result); INC(a.calls) END Done;

PROCEDURE Wait;
BEGIN
  ASSERT((request # NIL) & (error = NIL));
  REPEAT state := client.Step() UNTIL (request.status # IQ.pending) OR (state = C.failed);
  ASSERT(request.status = IQ.result)
END Wait;

BEGIN
  Args.Get(1, port); Args.Get(2, mode); Args.Get(3, direct); Args.Get(4, domain);
  IF domain = "" THEN domain := "localhost" END; success := mode = "register";
  NEW(hook); router := IQ.New(hook);
  transport := TCP.Open("127.0.0.1", port, domain, direct = "yes", 2000, error);
  IF transport = NIL THEN ASSERT(~success & (error # NIL))
  ELSE
    client := C.NewRegistration(transport, router, domain, error); ASSERT((client # NIL) & (error = NIL) & client.Start());
    REPEAT state := client.Step() UNTIL (state = C.registering) OR (state = C.failed) OR (state = C.closed);
    IF ~success THEN
      ASSERT((state = C.failed) & (hook.ready = 0) & (hook.registrationReady = 0));
      IF mode = "no-register" THEN ASSERT(client.error.code = C.registrationUnavailable) END;
      router.Stop; client.Abort
    ELSE
      ASSERT((state = C.registering) & (hook.registrationReady = 1) & (hook.ready = 0) & ~client.authenticated);
      empty := Items.Latin1(""); NEW(action); request := Reg.Query(router, empty^, 2000, action, error); Wait;
      form := Reg.Read(request); ASSERT((form # NIL) & form.legacy & (form.count = 4));
      value := form.Get("key"); ASSERT(S.Equal8(value^, "challenge"));
      value := Items.UTF8("Անի😀"); ASSERT(form.Set("username", value^));
      value := Items.UTF8("գաղտնի<&😀"); ASSERT(form.Set("password", value^));
      value := Items.Latin1("ani@example.net"); ASSERT(form.Set("email", value^));
      request := Reg.Submit(router, form, 2000, action, error); Wait;
      ASSERT(IQ.EmptyResult(request) & (action.calls = 2) & (hook.received = 2) & (hook.sent = 2));
      ASSERT(~client.authenticated & (client.jid = NIL) & (hook.ready = 0)); form.Clear;
      client.Close(error); ASSERT(error = NIL);
      REPEAT state := client.Step() UNTIL (state = C.closed) OR (state = C.failed);
      ASSERT((state = C.closed) & (hook.closed = 1) & (hook.errors = 0) & (router.count = 0))
    END
  END;
  Out.String("XMPP registration loopback passed"); Out.Ln
END TestXmppRegisterNetwork.
