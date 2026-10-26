MODULE XmppMuc;
(**
	project	= "Xmpp"
	subproject	= "Multi user chat support"
	organization	= ""
	contributors	= ""
	version	= "System/Rsrc/About"
	copyright	= "System/Rsrc/About"
	license	= "Docu/BB-License"
	purpose	= ""
	changes	= ""
	issues	= ""
**)
	

	IMPORT Bus := AbfBus, Pr := XmppPresence, It := XmlcoreItems, Const := XmppConst, DS := StringsDyn, Log;

	CONST
		userUrn = 'http://jabber.org/protocol/muc#user';

	TYPE
		MucOpts = POINTER TO RECORD(Pr.MucOpts)
			user: RECORD
				jid: DS.DynString
			END
		END;

	PROCEDURE (m: MucOpts) UserJid(): POINTER TO ARRAY OF CHAR;
	BEGIN
		RETURN m.user.jid.String();
	END UserJid;
	
	PROCEDURE NewOpts (): MucOpts;
		VAR m: MucOpts;
	BEGIN
		NEW(m); m.user.jid := DS.Create('');
		RETURN m
	END NewOpts;

	PROCEDURE ScanPresence (p: It.Item; OUT res: INTEGER): MucOpts;
		VAR m: MucOpts; x, i: It.Item; urn: ARRAY 127 OF CHAR;
	BEGIN
		res := Pr.empty;
		x := p.First();
		WHILE x # NIL DO
			urn := x.GetParam(Const.xmlns)$;
			IF (urn$ = userUrn) THEN
				res := Pr.ok;
				m := NewOpts();
				x.Find('item', i, res);
				IF i # NIL THEN
					m.user.jid := DS.Create(i.GetParam('jid')$)
				END
			ELSE END;
			x := p.Next(x)
		END;
		RETURN m
	END ScanPresence;

	PROCEDURE HandleBusMsg* (VAR msg: Bus.Message);
	BEGIN
		WITH msg: Pr.ExtendMucMsg DO
			msg.mucOpts := ScanPresence(msg.data, msg.res)
		ELSE END
	END HandleBusMsg;

	PROCEDURE Init*;
	BEGIN

	END Init;

BEGIN

END XmppMuc.
