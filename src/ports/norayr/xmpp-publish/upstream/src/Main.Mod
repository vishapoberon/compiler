MODULE Main;
(*  Proof of concept: publish a microblog entry on an XMPP PEP node
    (XEP-0060 + Atom, "urn:xmpp:microblog:0").

    This is the oolng/Oberon counterpart of m2-xmpp.  It binds libstrophe
    through Strophe.Mod, so TLS/STARTTLS, DNS, SASL and resource binding are
    all handled by libstrophe (linked against OpenSSL or GnuTLS).

    Configuration is read from an INI-like file (see Config.Mod).  The default
    path is $HOME/.config/oolng-xmpp.conf and can be overridden with XMPP_CONFIG:

        [name]
        jid=user@example.com
        password=secret
        message=Hello world
        host=example.com     # optional: bypass SRV lookup
        port=5222            # optional

    Every setting can also be given (or overridden) through the environment:
        XMPP_JID  XMPP_PASSWORD  XMPP_MESSAGE  XMPP_HOST  XMPP_PORT
*)

IMPORT Out, SYSTEM, Strings,
       C, Strophe, Runtime, Pep, Config;

TYPE
  State = RECORD
    ctx: Strophe.Context;
    conn: Strophe.Connection;
    jid: ARRAY 256 OF CHAR;
    password: ARRAY 256 OF CHAR;
    message: ARRAY 2048 OF CHAR;
    bare: ARRAY 256 OF CHAR;
    host: ARRAY 256 OF CHAR;
    port: ARRAY 16 OF CHAR;
    iqId: ARRAY 64 OF CHAR;
  END;
  StatePtr = POINTER TO State;

VAR
  st: StatePtr;
  nilAddr: SYSTEM.ADDRESS;   (* zero initialised -> C NULL *)
  nilStr: C.string;          (* zero initialised -> C NULL *)
  cfg: Config.Config;

PROCEDURE MakeBare (jid: ARRAY OF CHAR; VAR bare: ARRAY OF CHAR);
(*  Strip the resource part (`/...') from a JID.  *)
VAR
  i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(jid) - 1) & (jid[i] # 0X) & (jid[i] # "/") DO
    bare[i] := jid[i];
    INC(i)
  END;
  bare[i] := 0X
END MakeBare;

PROCEDURE OnResult (conn: Strophe.Connection;
                    stanza: Strophe.Stanza;
                    userdata: SYSTEM.ADDRESS): C.int;
(*  Called when the server answers the pubsub <iq>.  *)
BEGIN
  Out.String("Publish result received."); Out.Ln;
  Strophe.xmpp_disconnect(st.conn);
  RETURN 0
END OnResult;

PROCEDURE Publish (s: StatePtr);
VAR
  iq: Strophe.Stanza;
  itemId: C.string;
BEGIN
  iq := Pep.Build(s.ctx, Strophe.xmpp_conn_get_bound_jid(s.conn),
                  s.bare, s.message, s.iqId, itemId);
  Strophe.xmpp_id_handler_add(s.conn, OnResult, s.iqId, nilAddr);
  Strophe.xmpp_send(s.conn, iq);
  Strophe.xmpp_stanza_release(iq);
  Strophe.xmpp_free(s.ctx, itemId)
END Publish;

PROCEDURE OnConnect (conn: Strophe.Connection;
                     event, error: C.int;
                     stream_error: Strophe.StreamError;
                     userdata: SYSTEM.ADDRESS);
VAR
  s: StatePtr;
BEGIN
  s := st;
  IF event = Strophe.connConnect THEN
    Out.String("Connected, publishing ..."); Out.Ln;
    Publish(s)
  ELSIF event = Strophe.connDisconnect THEN
    Out.String("Disconnected."); Out.Ln;
    Strophe.xmpp_stop(s.ctx)
  ELSE
    Out.String("Connection failed, error="); Out.Int(error, 0); Out.Ln;
    Strophe.xmpp_stop(s.ctx)
  END
END OnConnect;

BEGIN
  NEW(st);

  Config.Load(cfg);
  IF cfg.loaded THEN
    Out.String("Read config "); Out.String(cfg.path); Out.Ln
  ELSE
    Out.String("No config file "); Out.String(cfg.path);
    Out.String(", using environment"); Out.Ln
  END;

  Strings.Assign(cfg.jid, st.jid);
  Strings.Assign(cfg.password, st.password);
  Strings.Assign(cfg.message, st.message);
  Strings.Assign(cfg.host, st.host);
  Strings.Assign(cfg.port, st.port);

  IF (st.jid[0] = 0X) OR (st.password[0] = 0X) THEN
    Out.String("Set jid/password in "); Out.String(cfg.path);
    Out.String(" or via XMPP_JID/XMPP_PASSWORD."); Out.Ln;
    HALT(1)
  END;

  MakeBare(st.jid, st.bare);

  Out.String("Message: "); Out.String(st.message); Out.Ln;
  Strophe.xmpp_initialize();
  st.ctx := Strophe.xmpp_ctx_new(nilAddr,
              Strophe.xmpp_get_default_logger(Strophe.levelWarn));
  st.conn := Strophe.xmpp_conn_new(st.ctx);
  Strophe.xmpp_conn_set_flags(st.conn, 0);
  Strophe.xmpp_conn_set_jid(st.conn, st.jid);
  Strophe.xmpp_conn_set_pass(st.conn, st.password);

  Out.String("Connecting as "); Out.String(st.jid); Out.String(" ..."); Out.Ln;
  IF st.host[0] # 0X THEN
    Strophe.xmpp_connect_client(st.conn, st.host, Runtime.atoi(st.port),
                                OnConnect, nilAddr)
  ELSE
    Strophe.xmpp_connect_client(st.conn, nilStr, 0, OnConnect, nilAddr)
  END;
  Strophe.xmpp_run(st.ctx);

  Strophe.xmpp_conn_release(st.conn);
  Strophe.xmpp_ctx_free(st.ctx);
  Strophe.xmpp_shutdown();

  Out.String("Done."); Out.Ln
END Main.
