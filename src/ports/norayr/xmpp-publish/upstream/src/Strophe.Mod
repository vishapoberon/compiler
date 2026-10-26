MODULE Strophe [INTERFACE "C"; LINK LIB "strophe"; END];
(*  Binding of the subset of the libstrophe C API that is needed to publish
    a microblog entry on an XMPP PEP node.  This is the oolng/Oberon
    counterpart of the Modula-2 `Strophe.def' module.

    libstrophe does the whole XMPP client stack: DNS, TCP (IPv4/IPv6),
    STARTTLS (OpenSSL/GnuTLS), SASL, resource binding and the event loop.
*)

IMPORT SYSTEM, C;

TYPE
  ADDRESS* = SYSTEM.ADDRESS;

  Context* = ADDRESS;          (* xmpp_ctx_t *)
  Connection* = ADDRESS;       (* xmpp_conn_t *)
  Stanza* = ADDRESS;           (* xmpp_stanza_t *)
  StreamError* = ADDRESS;      (* xmpp_stream_error_t *)
  Log* = ADDRESS;              (* xmpp_log_t *)
  Memory* = ADDRESS;           (* xmpp_mem_t *)

  ConnectionHandler* = PROCEDURE (conn: Connection;
                                  event, error: C.int;
                                  stream_error: StreamError;
                                  userdata: ADDRESS);
  Handler* = PROCEDURE (conn: Connection;
                        stanza: Stanza;
                        userdata: ADDRESS): C.int;
  TimedHandler* = PROCEDURE (conn: Connection;
                             userdata: ADDRESS): C.int;

CONST
  (* xmpp_conn_event_t *)
  connConnect* = 0;
  connRawConnect* = 1;
  connDisconnect* = 2;
  connFail* = 3;

  (* xmpp_log_level_t *)
  levelDebug* = 0;
  levelInfo* = 1;
  levelWarn* = 2;
  levelError* = 3;

  (* connection flags *)
  flagDisableTLS* = 01H;
  flagMandatoryTLS* = 02H;
  flagLegacySSL* = 04H;
  flagTrustTLS* = 08H;
  flagLegacyAuth* = 10H;

(* runtime *)
PROCEDURE xmpp_initialize* ();
PROCEDURE xmpp_shutdown* ();
PROCEDURE xmpp_ctx_new* (mem: Memory; log: Log): Context;
PROCEDURE xmpp_ctx_free* (ctx: Context);
PROCEDURE xmpp_get_default_logger* (level: C.int): Log;
PROCEDURE xmpp_free* (ctx: Context; p: C.string);

(* connection *)
PROCEDURE xmpp_conn_new* (ctx: Context): Connection;
PROCEDURE xmpp_conn_release* (conn: Connection);
PROCEDURE xmpp_conn_set_flags* (conn: Connection; flags: C.longint);
PROCEDURE xmpp_conn_set_jid* (conn: Connection; jid: C.string);
PROCEDURE xmpp_conn_set_pass* (conn: Connection; pass: C.string);
PROCEDURE xmpp_connect_client* (conn: Connection;
                                altdomain: C.string;
                                altport: C.int;
                                callback: ConnectionHandler;
                                userdata: ADDRESS);
PROCEDURE xmpp_disconnect* (conn: Connection);
PROCEDURE xmpp_conn_get_bound_jid* (conn: Connection): C.string;
PROCEDURE xmpp_conn_get_context* (conn: Connection): Context;

(* event loop *)
PROCEDURE xmpp_run* (ctx: Context);
PROCEDURE xmpp_run_once* (ctx: Context; timeout: C.longint);
PROCEDURE xmpp_stop* (ctx: Context);

(* handlers *)
PROCEDURE xmpp_handler_add* (conn: Connection;
                             handler: Handler;
                             ns, name, typ: C.string;
                             userdata: ADDRESS);
PROCEDURE xmpp_id_handler_add* (conn: Connection;
                                handler: Handler;
                                id: C.string;
                                userdata: ADDRESS);
PROCEDURE xmpp_timed_handler_add* (conn: Connection;
                                   handler: TimedHandler;
                                   period: C.longint;
                                   userdata: ADDRESS);

(* stanzas *)
PROCEDURE xmpp_iq_new* (ctx: Context; typ, id: C.string): Stanza;
PROCEDURE xmpp_presence_new* (ctx: Context): Stanza;
PROCEDURE xmpp_stanza_new* (ctx: Context): Stanza;
PROCEDURE xmpp_stanza_release* (stanza: Stanza);
PROCEDURE xmpp_stanza_set_name* (stanza: Stanza; name: C.string);
PROCEDURE xmpp_stanza_set_ns* (stanza: Stanza; ns: C.string);
PROCEDURE xmpp_stanza_set_id* (stanza: Stanza; id: C.string);
PROCEDURE xmpp_stanza_set_type* (stanza: Stanza; typ: C.string);
PROCEDURE xmpp_stanza_set_to* (stanza: Stanza; to: C.string);
PROCEDURE xmpp_stanza_set_from* (stanza: Stanza; from: C.string);
PROCEDURE xmpp_stanza_set_attribute* (stanza: Stanza;
                                      key, value: C.string);
PROCEDURE xmpp_stanza_set_text* (stanza: Stanza; text: C.string);
PROCEDURE xmpp_stanza_add_child* (stanza, child: Stanza);
PROCEDURE xmpp_stanza_to_text* (stanza: Stanza;
                                VAR buf: C.string;
                                VAR len: HUGEINT): C.int;
PROCEDURE xmpp_send* (conn: Connection; stanza: Stanza);

(* misc *)
PROCEDURE xmpp_uuid_gen* (ctx: Context): C.string;

END Strophe.
