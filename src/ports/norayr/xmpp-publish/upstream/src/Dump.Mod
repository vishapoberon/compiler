MODULE Dump;
(*  Offline verification: build the microblog publish stanza using the current
    configuration and print its serialised XML, without touching the network.
    Uses the same config resolution as Main (Config.Load).  *)

IMPORT Out, SYSTEM, C, Strophe, CStr, Config, Pep;

VAR
  cfg: Config.Config;
  ctx: Strophe.Context;
  iq: Strophe.Stanza;
  nilAddr: SYSTEM.ADDRESS;
  buf: C.string;
  itemId: C.string;
  len: HUGEINT;
  iqId: ARRAY 64 OF CHAR;
  text: ARRAY 8192 OF CHAR;
  from, to: ARRAY 256 OF CHAR;
  i: LONGINT;

BEGIN
  Config.Load(cfg);

  IF cfg.jid[0] # 0X THEN
    COPY (cfg.jid, from)
  ELSE
    COPY ("romeo@montague.lit/pda", from)
  END;
  i := 0;
  WHILE (from[i] # 0X) & (from[i] # "/") DO
    to[i] := from[i];
    INC(i)
  END;
  to[i] := 0X;

  Strophe.xmpp_initialize();
  ctx := Strophe.xmpp_ctx_new(nilAddr,
           Strophe.xmpp_get_default_logger(Strophe.levelError));

  iq := Pep.Build(ctx, from, to, cfg.message, iqId, itemId);

  IF Strophe.xmpp_stanza_to_text(iq, buf, len) = 0 THEN
    CStr.CopyOut(buf, text);
    Out.String(text); Out.Ln;
    Strophe.xmpp_free(ctx, buf)
  ELSE
    Out.String("xmpp_stanza_to_text failed"); Out.Ln
  END;

  Strophe.xmpp_stanza_release(iq);
  Strophe.xmpp_free(ctx, itemId);
  Strophe.xmpp_ctx_free(ctx);
  Strophe.xmpp_shutdown()
END Dump.
