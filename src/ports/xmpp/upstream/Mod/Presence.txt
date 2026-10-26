MODULE XmppPresence;
(**	project	= "XMPP"
	organization	= ""
	contributors	= ""
 	purpose	= "???????? ?????????? RFC 3921"
	changes	= "
	- , nn, ...
	"
	issues	= ""
**)

	IMPORT Bus:=AbfBus, Core := XmppCore, Items:=XmlcoreItems, Const:=XmppConst, Log, Stuff:=XmppStuff,  DS:=StringsDyn, Strings, Rand:=ypkMathRandom, Dialog;
	
	CONST
		sess_1 = 'sess_1';
		SHOW* = 'show';
		STATUS* = 'status';
		PRIORITY* = 'priority';
		AWAY* = 'away';
		DND* = 'dnd';
		CHAT* = 'chat';
		XA* = 'xa';
		UNAVAILABLE* = 'unavailable';
		SUBSCRIBE* = 'subscribe';
		UNSUBSCRIBE* = 'unsubscribe';
		SUBSCRIBED* = 'subscribed';
		UNSUBSCRIBED* = 'unsubscribed';
		PROBE* = 'probe';
		NORMAL* = '';
		none=-1000;
		empty* = -1;
		ok* = 0;
		
	TYPE
		DynString = DS.DynString;
		
		Directory* = POINTER TO RECORD(Core.ExtensionDir) END;
		
		Presence* = POINTER TO LIMITED RECORD (Core.Extension)
			valid- : BOOLEAN;
			hook : Hook
		END;
		
		Hook* = POINTER TO ABSTRACT RECORD END;
		
		MucOpts* = POINTER TO ABSTRACT RECORD END;
		
		ExtendMucMsg* = LIMITED RECORD(Bus.Message) 
			owner-: Presence;
			data-: Items.Item;
			mucOpts*: MucOpts;
			res*: INTEGER;
		END;
		
		SessionIq = POINTER TO RECORD(Core.Iq) END;
		
		Opts* = POINTER TO RECORD
			mucOpts-: MucOpts;
		END;
		
		PresenceStanza = POINTER TO RECORD(Core.Presence)
			show, status : POINTER TO ARRAY OF CHAR;
			priority : INTEGER;
			mo: MucOpts;
		END;
		
	VAR
		dir- : Directory;
		priority*: INTEGER;
	
	PROCEDURE (m: MucOpts) UserJid*(): POINTER TO ARRAY OF CHAR, NEW, ABSTRACT;
		
	PROCEDURE (h : Hook) Notify- (presence : Presence; type, from, show, status : ARRAY OF CHAR; priority : INTEGER; opts: Opts), NEW, ABSTRACT;
	
	PROCEDURE Notify(p : Presence; ps : PresenceStanza);
		VAR opts: Opts;
	BEGIN
		IF p.hook#NIL THEN
			NEW(opts); opts.mucOpts:=ps.mo;
			p.hook.Notify(p, ps.type, ps.from, ps.show, ps.status, ps.priority, opts);
		END;
	END Notify;
			
	PROCEDURE (s : SessionIq) Do() : Items.Item;
	VAR n, n1 : Items.Item;
	BEGIN
		n:=Items.New(Const.iq);
		n1:=Items.New(Const.session); 
		n1.SetParam(Const.xmlns, Const.uri_session);
		n.Add(n1);
		RETURN n;		
	END Do;
	
	PROCEDURE (p : PresenceStanza) Do() : Items.Item;
	VAR n, n1 : Items.Item; str : ARRAY 15 OF CHAR;
	BEGIN
		n:=Items.New(Const.presence);
		IF p.to$#'' THEN n.SetParam(Const.to, p.to$); END;
		IF p.from$#'' THEN n.SetParam(Const.from, p.from$); END;
		IF p.type$#'' THEN n.SetParam(Const.type, p.type$); END;
		IF p.id$#'' THEN n.SetParam(Const.id, p.id$); END;
		IF p.lang$#'' THEN n.SetParam(Const.xml_lang, p.lang$); END;
		n1:=Items.New(SHOW);
		IF p.show$#'' THEN n1.SetData(p.show$); n.Add(n1)  END;
		n1:=Items.New(STATUS);
		IF p.status$#'' THEN n1.SetData(p.status$); n.Add(n1)  END;
		IF p.priority>none THEN 
			n1:=Items.New(PRIORITY);
			Strings.IntToString(p.priority, str);
			n1.SetData(str);
			n.Add(n1);
		END;	
		RETURN n;		
	END Do;
	
	PROCEDURE (p : PresenceStanza) Use(data : Items.Item);
	VAR n: Items.Item; res : INTEGER;
	BEGIN
		NEW(p.show, 1); NEW(p.status, 1);
		n:=data.First();
		WHILE n#NIL DO
			IF n.GetName()$=SHOW THEN
				p.show:=n.GetData();
			ELSIF n.GetName()$=STATUS THEN
				p.status:=n.GetData();
			ELSIF n.GetName()$=PRIORITY THEN
				Strings.StringToInt(n.GetData()$, p.priority, res);
				IF res#0 THEN p.priority:=0 END;
			ELSE END;
			n:=data.Next(n);
		END;
	END Use;
	
	PROCEDURE (p : Presence) Set*(to, from, show, status : ARRAY OF CHAR; priority : INTEGER; type : ARRAY OF CHAR), NEW;
	VAR ps : PresenceStanza; str : ARRAY 24 OF CHAR;
	BEGIN
		IF p.valid THEN
			NEW(ps);
			Rand.UniRandStr(str, 4);
			ps.Set(to$, from$, '', Const.presence+'_'+str,type);
			ps.priority:=priority;
			ps.show:=DS.Create(show).String();
			ps.status:=DS.Create(status).String();
			p.owner.Send(ps);
		ELSE Log.Ln; Log.String('[XMPP] xmpp connection invalid') END
	END Set;
	
	PROCEDURE (p : Presence) Initial*, NEW;
	BEGIN
		IF p.valid THEN
			p.Set('',p.owner.Username()+'@'+p.owner.Server()+'/'+p.owner.Resource(),'chat','Hello, World!', priority, NORMAL);
		ELSE Log.Ln; Log.String('[XMPP] xmpp connection invalid') END
	END Initial;
	
	PROCEDURE (p : Presence) Unavailable*, NEW;
	BEGIN
		IF p.valid THEN
			p.Set('',p.owner.Username()+'@'+p.owner.Server()+'/'+p.owner.Resource(),'','',none,UNAVAILABLE);
		ELSE Log.Ln; Log.String('[XMPP] xmpp connection invalid') END
	END Unavailable;
	
	PROCEDURE (p : Presence) Subscribe* (to, action : ARRAY OF CHAR), NEW;
	BEGIN
		IF p.valid THEN
			ASSERT((action=SUBSCRIBE) OR (action=UNSUBSCRIBE));
			p.Set(to,'','','',none,action);
		ELSE Log.Ln; Log.String('[XMPP] xmpp connection invalid') END
	END Subscribe;
	
	PROCEDURE (p : Presence) Approve* (to, answer : ARRAY OF CHAR), NEW;
	BEGIN
		IF p.valid THEN
			ASSERT((answer=SUBSCRIBED) OR (answer=UNSUBSCRIBED));
			p.Set(to,'','','',none,answer);
		ELSE Log.Ln; Log.String('[XMPP] xmpp connection invalid') END
	END Approve;
	
	PROCEDURE (p : Presence) Iq-(data : Items.Item; VAR res : INTEGER);
	VAR n: Items.Item; siq : SessionIq;
	BEGIN
		n:=data.First();
		WHILE n#NIL DO
			IF n.GetName()$=Const.bind THEN
				ASSERT(p.owner.HasFeature(Const.session,'*'));
				NEW(siq); siq.Set(p.owner.Server(), '', '', sess_1, Const.set);
				p.owner.Send(siq);
			ELSIF n.GetName()$=Const.session THEN
				p.valid:=TRUE;
			END;
			n:=data.Next(n);
		END;
		res:=Core.continue;
	END Iq;
	
	PROCEDURE (p : Presence) Presence-(data : Items.Item; VAR res : INTEGER);
		VAR ps : PresenceStanza; em: ExtendMucMsg; 
	BEGIN
		NEW(ps); ps.Init(data); 
		em.owner:=p; em.data:=data; em.res:=empty;
		Bus.SendTo('XmppMuc', em, TRUE, res);
		ps.mo:=em.mucOpts;
		Notify(p, ps);
		res:=Core.continue;
	END Presence;
		
	PROCEDURE (p : Presence) Start-;
	BEGIN
		p.valid:=TRUE;
	END Start;	
	
	PROCEDURE (p : Presence) Stop-;
	BEGIN
		p.valid:=FALSE;
	END Stop;
	
	PROCEDURE (p : Presence) SetHook*(h : Hook), NEW;
	BEGIN
		p.hook:=h;
	END SetHook;
	
	PROCEDURE (d : Directory) Create-(session : Core.Session) : Core.Extension;
	VAR p : Presence;
	BEGIN
		NEW(p);
		p.valid:=FALSE;
		RETURN p;
	END Create;
	
	PROCEDURE HandleBusMsg* (VAR msg: Bus.Message);
	BEGIN
	
	END HandleBusMsg;
	
	PROCEDURE Init;
	VAR d : Directory; res: INTEGER;
	BEGIN
		NEW(d);
		dir:=d;
		priority:=-1;
		Dialog.Call('XmppMuc.Init', 'xmpp muc ex not loaded', res);
	END Init;

BEGIN
	Init
END XmppPresence.