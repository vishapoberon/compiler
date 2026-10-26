MODULE XmppPublish;

(* Publishing a single configured XMPP microblog entry. *)

IMPORT Out, Msg, Config := XmppPublishConfig, Publisher := XmppPublisher;

VAR cfg: Config.Config; error: Msg.Msg; text: ARRAY 256 OF CHAR;

BEGIN
  IF ~Config.Load(cfg) THEN Out.String("Invalid XMPP publisher configuration"); Out.Ln; HALT(2) END;
  IF ~Publisher.Run(cfg, error) THEN
    error.GetText(text); Out.String(text); Out.Ln; HALT(1)
  END;
  Out.String("Microblog entry published"); Out.Ln
END XmppPublish.
