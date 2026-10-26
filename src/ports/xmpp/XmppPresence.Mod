MODULE XmppPresence;

(* Constructing directed or broadcast presence stanzas. *)

IMPORT S := LongStrings, T := XmppTypes, Const := XmppConst,
  Items := XmppItems, Core := XmppCore;

PROCEDURE NewPresence*(to, status: ARRAY OF T.CodeUnit): Core.Stanza;
  VAR stanza: Core.Stanza; child: Items.Item;
BEGIN
  stanza := Core.NewStanza(Const.presence);
  IF S.Length(to) > 0 THEN stanza.item.SetParam(Const.to, to) END;
  IF S.Length(status) > 0 THEN
    child := Items.New("status", Const.jabberClient); child.AddText(status, 0, S.Length(status)); stanza.item.AddChild(child)
  END;
  RETURN Core.Wrap(stanza.item, NIL)
END NewPresence;

END XmppPresence.
