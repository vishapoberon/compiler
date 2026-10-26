MODULE TestXmppPublish;

IMPORT Args, Out, Msg, S := LongStrings, T := XmppTypes, Items := XmppItems,
  XML := XmppXmlGen, PEP := XmppPEP, Config := XmppPublishConfig;

VAR cfg: Config.Config; mode: ARRAY 16 OF CHAR; text, value: T.String;
  payload, publish, item, entry, child: Items.Item; bytes: Items.Bytes; error: Msg.Msg;
  length, i, checks: LONGINT; long: ARRAY PEP.maxTextUnits+2 OF T.CodeUnit;

PROCEDURE Run;
BEGIN
  Args.Get(1, mode);
  IF mode = "load" THEN
    IF ~Config.Load(cfg) THEN HALT(2) END;
    Out.String(cfg.jid); Out.Ln; Out.String(cfg.message); Out.Ln; Out.String(cfg.port); Out.Ln;
    Out.Int(cfg.timeoutMS, 0); Out.Ln; Out.Int(S.Length8(cfg.password), 0); Out.Ln;
    IF cfg.allowPlain THEN Out.String("plain") END; Out.Ln;
    IF cfg.directTLS THEN Out.String("direct") END; Out.Ln;
    Config.Wipe(cfg); RETURN
  END;
  text := Items.UTF8("Բարեւ 😀 <tag> & text");
  payload := PEP.Build("ծոց.հայ", text^, "test-item", "2026-10-26T14:05:09Z"); ASSERT(payload # NIL);
  publish := payload.First(PEP.pubsubURI, "publish"); item := publish.First(PEP.pubsubURI, "item");
  entry := item.First(PEP.atomURI, "entry"); ASSERT(entry # NIL);
  child := entry.First(PEP.atomURI, "content"); value := child.Text(); ASSERT(S.Equal(value^, text^));
  child := entry.First(PEP.atomURI, "id"); value := child.Text();
  ASSERT(S.Equal8(value^, "tag:xn--cbbu1a.xn--y9a3aq,2026-10-26:posts-test-item")); checks := 3;
  XML.Encode(payload, 65536, bytes, length, error); ASSERT(error = NIL); INC(checks);
  IF mode = "dump" THEN Out.String(bytes^); Out.Ln; RETURN END;
  ASSERT(PEP.Timestamp("2024-02-29T00:00:00Z")); INC(checks);
  ASSERT(~PEP.Timestamp("2025-02-29T00:00:00Z")); INC(checks);
  ASSERT(~PEP.Timestamp("2026-04-31T00:00:00Z")); INC(checks);
  ASSERT(~PEP.Timestamp("2026-10-26T24:00:00Z")); INC(checks);
  ASSERT(~PEP.Timestamp("2026-10-26T00:00:60Z")); INC(checks);
  ASSERT(PEP.Build("bad..domain", text^, "id", "2026-10-26T00:00:00Z") = NIL); INC(checks);
  ASSERT(PEP.Build("example.org", text^, "bad<id", "2026-10-26T00:00:00Z") = NIL); INC(checks);
  ASSERT(PEP.Build("example.org", text^, "", "2026-10-26T00:00:00Z") = NIL); INC(checks);
  FOR i := 0 TO PEP.maxTextUnits DO long[i] := ORD("a") END; long[PEP.maxTextUnits+1] := 0;
  ASSERT(PEP.Build("example.org", long, "id", "2026-10-26T00:00:00Z") = NIL); INC(checks);
  long[PEP.maxTextUnits] := 0; ASSERT(PEP.Build("example.org", long, "id", "2026-10-26T00:00:00Z") # NIL); INC(checks);
  long[0] := 1; long[1] := 0; ASSERT(PEP.Build("example.org", long, "id", "2026-10-26T00:00:00Z") = NIL); INC(checks);
  long[0] := 0D800H; ASSERT(PEP.Build("example.org", long, "id", "2026-10-26T00:00:00Z") = NIL); INC(checks);
  Config.Init(cfg); ASSERT(~cfg.allowPlain & ~cfg.directTLS & (cfg.timeoutMS = 10000)); INC(checks);
  ASSERT(Config.Setting(cfg, "port", "65535")); ASSERT(~Config.Setting(cfg, "port", "65536")); INC(checks);
  ASSERT(~Config.Setting(cfg, "port", "0")); ASSERT(~Config.Setting(cfg, "timeout_ms", "9999999999999999999")); INC(checks);
  ASSERT(~Config.Setting(cfg, "tls", "disabled")); ASSERT(~Config.Setting(cfg, "allow_plain", "maybe")); INC(checks);
  ASSERT(Config.Setting(cfg, "password", "dummy")); Config.Wipe(cfg);
  FOR i := 0 TO LEN(cfg.password)-1 DO ASSERT(cfg.password[i] = 0X) END; INC(checks);
  Out.String("XMPP publisher payload and configuration checks passed: "); Out.Int(checks, 0); Out.Ln
END Run;

BEGIN Run
END TestXmppPublish.
