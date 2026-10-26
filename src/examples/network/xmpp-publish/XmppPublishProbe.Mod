MODULE XmppPublishProbe;

(* Publishing a caller-selected item once and verifying its stored Atom text. *)

IMPORT Args, Out, Msg, Config := XmppPublishConfig, Publisher := XmppPublisher;

VAR cfg: Config.Config; id: ARRAY 66 OF CHAR; error: Msg.Msg; text: ARRAY 256 OF CHAR;

BEGIN
  IF Args.argc # 2 THEN
    Out.String("Usage: XmppPublishProbe item-id; configuration through XMPP_CONFIG"); Out.Ln; HALT(2)
  END;
  Args.Get(1, id);
  IF ~Config.Load(cfg) THEN Config.Wipe(cfg); Out.String("Invalid publisher configuration"); Out.Ln; HALT(2) END;
  IF ~Publisher.RunItem(cfg, id, TRUE, error) THEN
    IF error # NIL THEN error.GetText(text); Out.String(text) ELSE Out.String("Publication or verification failed") END;
    Out.Ln; HALT(1)
  END;
  Out.String("Microblog entry published and retrieved with matching text"); Out.Ln
END XmppPublishProbe.
