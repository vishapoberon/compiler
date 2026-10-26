MODULE XmppMessenger;

(* Constructing and reading client message stanzas with UTF-16 text. *)

IMPORT S := LongStrings, T := XmppTypes, Const := XmppConst,
  Items := XmppItems, Core := XmppCore;

PROCEDURE NewMessage*(to, body: ARRAY OF T.CodeUnit): Core.Stanza;
  VAR stanza: Core.Stanza; child: Items.Item; type: T.String;
BEGIN
  stanza := Core.NewStanza(Const.message);
  stanza.item.SetParam(Const.to, to); type := Items.Latin1("chat"); stanza.item.SetParam(Const.type, type^);
  child := Items.New("body", Const.jabberClient); child.AddText(body, 0, S.Length(body));
  stanza.item.AddChild(child); RETURN Core.Wrap(stanza.item, NIL)
END NewMessage;

PROCEDURE Body*(stanza: Core.Stanza): T.String;
  VAR child: Items.Item;
BEGIN
  child := stanza.item.First(Const.jabberClient, "body");
  IF child = NIL THEN RETURN Items.Latin1("") ELSE RETURN child.Text() END
END Body;

END XmppMessenger.
