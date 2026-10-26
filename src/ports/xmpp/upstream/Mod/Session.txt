MODULE XmppSession;
(**	project	= "Xmpp"
	organization	= ""
	contributors	= ""
 	purpose	= ""
	changes	= "
	- , nn, ...
	"
	issues	= "
	-20111110, pk, ?????????? ????????? ????????????? ???????? ????????? ????????? SendConfirmableMsg/ConfirmedMsg
	-20111113, pk, ??????? ???????????? ???????? ????????, TimeOutMsg
	"
	selectors	= 
**)

	IMPORT Core:=XmppCore, Pr:=XmppPresence, Rs:=XmppRoster, Ms:=XmppMessenger, Ibb:=XmppIbb, Bs:=XmppByteStreams, Ds:=XmppDisco, Bus:=XmppBus, Si:=XmppStreamInit, Ver:=XmppVersion, Pi:=XmppPing, Str:=XmppStrings, Conn:=XmppConnections, XmppFiles, Console:=XmppConsole, AbfBus, Map:=ListsMap, Linear:=ListsLinear,Rand:=ypkMathRandom, Log, Files, Actions:=ypkSysActions, Cs:=CommStreams, Services, DS:=StringsDyn, Dialog;
	
	CONST
		maxDelay = 150000;
		maxBlockSize = 4096;
		timeout = 60000;
		
		chatMsg* = Ms.CHAT;
		groupchatMsg* = Ms.GROUPCHAT;
		headlineMsg* = Ms.HEADLINE;
		normalMsg* = Ms.NORMAL;
		
		ibbMethod* = Si.ibb;
		bsMethod* = Si.bs;
		
		ok* = 0; wait=1; error*=2;
		conflict* = 'conflict';
		
		msgSendError* = Bus.stream;
		msgAlienError* = Bus.alien;

	TYPE
		DynString = DS.DynString;
		
		Directory* = POINTER TO RECORD
			list: Map.PtrMap;
		END;
		
		Session* = POINTER TO LIMITED RECORD			
			s-: Core.Session;
			pr-: Pr.Presence;
			rs-: Rs.Roster;
			ms-: Ms.Messenger;
			ibb-: Ibb.Ibb;
			bs-: Bs.ByteStreams;
			ds-: Ds.Disco;
			bus-: Bus.Bus;
			si-: Si.StreamInit;
			v-: Ver.Version;
			pi-: Pi.Pinger;
			alive: AliveAction;
			connected, testOnly: BOOLEAN;
			connectPos: INTEGER;
			streams: Map.StrMap;
		END;
			
		ConnectAction = POINTER TO RECORD (Actions.Action) 
			s: Session;
		END;
		
		Ping = POINTER TO RECORD(Ds.Action)
			s: Core.Session;
		END;
		
		AliveAction = POINTER TO RECORD (Actions.Action) 
			s: Core.Session;
			last: Ping;
			res: INTEGER;
		END;
		
		DisconnectAction = POINTER TO RECORD (Actions.Action) 
			s: Session;
		END;
			
		ErrorHook = POINTER TO RECORD (Core.ErrorHook); END;
		PrHook = POINTER TO RECORD (Pr.Hook) END;
		RsHook = POINTER TO RECORD (Rs.Hook) END;
		MsHook = POINTER TO RECORD (Ms.Hook) END;
		IbbHook = POINTER TO RECORD (Ibb.Hook) END;
		BsHook = POINTER TO RECORD(Bs.Hook) END;
		DsHook = POINTER TO RECORD (Ds.Hook) END;
		BusHook = POINTER TO RECORD (Bus.Hook) END;
		SiHook = POINTER TO RECORD (Si.Hook) END;
		VerHook = POINTER TO RECORD(Ver.Hook) END;
		DsAction = POINTER TO RECORD(Ds.Action) END;
		RsAction = POINTER TO RECORD (Rs.Action) END;
		RsAddAction = POINTER TO RECORD (Rs.Action) jid: ARRAY 512 OF CHAR; END;
		StreamId* = POINTER TO LIMITED RECORD (Si.Action) 
			file: Files.File;
		END;
		VerAction = POINTER TO LIMITED RECORD(Ver.Action) END;
		RecAction = POINTER TO RECORD (Ms.ReceiptsAction) END;
		
		Msg* = ABSTRACT RECORD (Bus.Message) 
			owner: Session;
			res: INTEGER;
			to, from: ARRAY 256 OF CHAR;
		END;
		
		BusMsg* = ABSTRACT RECORD (Msg) 
			id: POINTER TO ARRAY OF CHAR;
		END;
		
		ErrorMsg* = LIMITED RECORD (Msg) 
			type-, description-: ARRAY 256 OF CHAR;
			fatal-: BOOLEAN;
			data-: ANYPTR;
		END;
		
		ConnectedMsg* = LIMITED RECORD (Msg) 
			resource-: ARRAY 256 OF CHAR;
		END;
		
		ConnectingMsg* = LIMITED RECORD (Msg) 
			pos-, len-: INTEGER;
			op-: ARRAY 256 OF CHAR;
		END;
		
		DisconnectedMsg* = LIMITED RECORD (Msg) 
			cause-: ARRAY 512 OF CHAR;
		END;
		
		StdMsg* = LIMITED RECORD (Msg)
			type-: ARRAY 127 OF CHAR;
			subject-, body-, thread-: POINTER TO ARRAY OF CHAR;
			delay-: Delay;
		END;
		
		Delay* = Ms.Delay;
		
		SendStdMsg* = RECORD (Msg)
			type*: ARRAY 127 OF CHAR;
			subject*, body*, thread*: POINTER TO ARRAY OF CHAR;
		END;
		
		SendConfirmableMsg* = RECORD (Msg)
			type*: ARRAY 127 OF CHAR;
			subject*, body*, thread*: POINTER TO ARRAY OF CHAR;
			id-: ARRAY 127 OF CHAR;
		END;
		
		ConfirmedMsg* = LIMITED RECORD(Msg)
			id-: ARRAY 127 OF CHAR;
		END;
		
		TimeOutMsg* = LIMITED RECORD (Msg)
			id-: ARRAY 127 OF CHAR;
		END;
		
		RosterList* = Linear.List;
		RosterItem* = POINTER TO RECORD (Linear.ListItem)
			jid-, name-, group-,  subscription-, ask-: ARRAY 256 OF CHAR;
		END;
		
		GetRosterMsg* = RECORD (Msg) END;
		
		RosterMsg* = LIMITED RECORD (Msg)
			list-: RosterList;
			length-: INTEGER;
		END;
		
		RosterAddMsg* = RECORD (Msg)
			jid*, group*, name*: ARRAY 512 OF CHAR;
		END;
		
		RosterUpdateMsg* = RECORD (Msg)
			jid*: ARRAY 512 OF CHAR;
			newGroup*, newName*: ARRAY 512 OF CHAR;
		END;
		
		RosterResMsg* = LIMITED RECORD (Msg)
			jid-: ARRAY 512 OF CHAR;
			result-: INTEGER;
		END;
		
		SubscribedMsg* = LIMITED RECORD (Msg) 
			name*, group*: ARRAY 512 OF CHAR;
		END;
		
		SendFileMsg* = RECORD(Msg) 
			file*: Files.File;
			name*, descr*, date*: ARRAY 256 OF CHAR;
			range*: BOOLEAN;
			offset*, length*: INTEGER;
			sid*: StreamId;
			methods*: SET;
		END;
		
		IncomingFileMsg* = LIMITED RECORD(Msg)
			name-, descr-: ARRAY 256 OF CHAR;
			length-: INTEGER;
			methods-: SET;
			id-: StreamId;
		END;
		
		AcceptFileMsg* = RECORD(Msg)
			file*: Files.File;
			id*: StreamId;
			method*: INTEGER;
		END;
		
		AcceptedFileMsg* = LIMITED RECORD(Msg)
			sid-: StreamId;
		END;
		
		ReceivedFileMsg* = LIMITED RECORD (Msg)
			sid-: StreamId;
			file-: Files.File;
		END;
		
		ReceivingMsg* = LIMITED RECORD (Msg)
			sid-: StreamId;
			file-: Files.File;
		END;
		
		SentFileMsg* = LIMITED RECORD(Msg)
			sid-: StreamId;
		END;
		
		PresenceMsg* = RECORD(Msg)
			type*: ARRAY 127 OF CHAR;
			show*, status*: ARRAY 1024 OF CHAR;
			priority*: INTEGER;
		END;
		
		PresenceOpts* = Pr.Opts;
		
		PresenceInfoMsg* = LIMITED RECORD(Msg)
			type-: ARRAY 127 OF CHAR;
			show-, status-: ARRAY 1024 OF CHAR;
			priority-: INTEGER;
			opts-: PresenceOpts;
		END;
		
		BusResultMsg* = LIMITED RECORD(Msg)
			id-: ARRAY 33 OF CHAR;
			code-: INTEGER;
		END;
		
	VAR
		dir-: Directory;
	
	PROCEDURE (VAR m: Msg) MetaInf*(OUT to, from: ARRAY OF CHAR; OUT owner: Session; OUT res: INTEGER), NEW;
	BEGIN
		to:=m.to$;
		from:=m.from$;
		res:=m.res;
		owner:=m.owner;
	END MetaInf;
	
	PROCEDURE (VAR m: Msg) MetaInit*(IN to, from: ARRAY OF CHAR; owner: Session), NEW;
	BEGIN
		m.to:=to$;
		m.from:=from$;
		m.res:=0;
		m.owner:=owner;
	END MetaInit;
	
	PROCEDURE (VAR m: BusMsg) Id*(): POINTER TO ARRAY OF CHAR, NEW;
		VAR res: POINTER TO ARRAY OF CHAR;
	BEGIN
		IF m.id#NIL THEN res:=m.id ELSE NEW(res, 1); res[0]:=0X END;
		RETURN res;
	END Id;
	
	PROCEDURE (d: Directory) Jid*(s: Session): POINTER TO ARRAY OF CHAR, NEW;
		VAR jid: DynString;
	BEGIN
		jid:=DS.Create('');
		IF (s#NIL) & (s.s#NIL) THEN jid:=DS.Create(s.s.Username()$+'@'+s.s.Server()$+'/'+s.s.Resource()$) END;
		RETURN jid.String()
	END Jid;
	
	PROCEDURE (d: Directory) Broadcast(s: Session; VAR msg: AbfBus.Message), NEW;
	VAR res: INTEGER;
	BEGIN
		WITH msg: Msg DO 
			msg.owner:=s;
			AbfBus.Broadcast(msg, msg.res);
		ELSE AbfBus.Broadcast(msg, res) END
	END Broadcast;
	
	PROCEDURE (d: Directory) Connected(s: Session), NEW;
	VAR m: ConnectedMsg;
	BEGIN
		s.pr.Initial;
		s.connected:=TRUE;
		m.owner:=s;
		m.from:=s.s.Server()$;
		m.to:=d.Jid(s)$;
		m.resource:=s.s.Resource()$;
		d.Broadcast(s, m);
	END Connected;
	
	PROCEDURE (d: Directory) ConnectionError(s: Session), NEW;
	VAR m: ErrorMsg;
	BEGIN
		s.s.CloseStream;
		m.type:='stream error';
		m.description:='stream not connected';
		m.fatal:=TRUE;
		m.to:=dir.Jid(s)$;
		m.from:='';
		m.owner:=s;
		d.Broadcast(s, m);
		d.list.Remove(s.s);
	END ConnectionError;
	
	PROCEDURE (d: Directory) Disconnected(s: Session; type: ARRAY OF CHAR), NEW;
	VAR m: DisconnectedMsg;
	BEGIN
		s.connected:=FALSE;
		m.owner:=s;
		m.from:=s.s.Server()$;
		m.to:=d.Jid(s)$;
		m.cause:=type$;
		d.Broadcast(s, m);
		d.list.Remove(s.s);
	END Disconnected; 
	
	PROCEDURE (d: Directory) This(s: Core.Session): Session, NEW;
	VAR x: ANYPTR; s0: Session;
	BEGIN
		x:=d.list.Item(s);
		IF x#NIL THEN s0:=x(Session) END;
		RETURN s0; 
	END This;
		
	PROCEDURE (h: ErrorHook) Error(s: Core.Session; data: Core.Error);
	VAR e: ErrorMsg;
	BEGIN
		e.fatal:=data.close; e.type:=data.type$; e.description:=data.text$; e.data:=data; e.to:=dir.Jid(dir.This(s))$;
		e.from:='';
		dir.Broadcast(dir.This(s), e);
		IF e.fatal THEN dir.Disconnected(e.owner, e.type$) END;
	END Error;
	
	PROCEDURE (a: DsAction) Result;
	VAR i: INTEGER;
	BEGIN
		Log.String('Disco ');
		IF a.type=Ds.info THEN
			Log.Int(a.identities.Length()); Log.String(' '); Log.Int(a.features.Length());
		ELSE
			Log.Int(a.items.Length());
		END;
		Log.Ln; 
	END Result;
	
	PROCEDURE (a: DsAction) Error;
	BEGIN
	
	END Error;
	
	PROCEDURE (a: Ping) Result;
	BEGIN
		IF a=dir.This(a.s).alive.last THEN dir.This(a.s).alive.res:=ok ELSE Log.Ln; Log.String('ping late'); END;
	END Result;
	
	PROCEDURE (a: Ping) Error;
	BEGIN
		IF a=dir.This(a.s).alive.last THEN dir.This(a.s).alive.res:=error ELSE Log.Ln; Log.String('ping late'); END;
	END Error;
	
	PROCEDURE (h: DsHook) Request(from: ARRAY OF CHAR; type: INTEGER; VAR query: Ds.Query);
	BEGIN
		query.AddFeature('http://jabber.org/protocol/si');
		query.AddFeature('http://jabber.org/protocol/si/profile/file-transfer');
		query.AddFeature('jabber:iq:version');
		query.AddFeature('urn:xmpp:ping');
		query.AddFeature('urn:xmpp:receipts');
	END Request;
	
	PROCEDURE (a: RsAction) Result;
	VAR i: INTEGER; rm: RosterMsg; ri: RosterItem;
	BEGIN
		i:=0; rm.list:=Linear.NewList(); 
		IF a.items#NIL THEN rm.list.SetLength(a.items.Length()) END;
		WHILE i<rm.list.len DO
			NEW(ri); 
			ri.jid:=a.items.Item(i)(Rs.Item).Jid()$;
			ri.name:=a.items.Item(i)(Rs.Item).name$;
			ri.group:=a.items.Item(i)(Rs.Item).group$;
			ri.subscription:=a.items.Item(i)(Rs.Item).subscription$;
			ri.ask:=a.items.Item(i)(Rs.Item).ask$;
			rm.list.SetItem(i, ri);
			INC(i);
		END;
		rm.length:=rm.list.len;
		dir.Broadcast(dir.This(a.owner.owner), rm);
	END Result;
	
	PROCEDURE (a: RsAction) Error;
	BEGIN
	
	END Error;
	
	PROCEDURE (a: RsAddAction) Result;
		VAR rm: RosterResMsg;
	BEGIN
		rm.jid:=a.jid$; rm.to:=''; rm.from:=a.owner.owner.Server()$; 
		rm.result:=ok;
		dir.Broadcast(dir.This(a.owner.owner), rm);
	END Result;
	
	PROCEDURE (a: RsAddAction) Error;
		VAR rm: RosterResMsg;
	BEGIN
		rm.jid:=a.jid$;
		rm.result:=error;
		dir.Broadcast(dir.This(a.owner.owner), rm);
	END Error;
	
	PROCEDURE (h: PrHook) Notify(p: Pr.Presence; type, from, show, status: ARRAY OF CHAR; priority: INTEGER; opts: Pr.Opts);
		VAR str: ARRAY 16 OF CHAR; pm: PresenceInfoMsg; sm: SubscribedMsg;
	BEGIN
		IF type=Pr.SUBSCRIBE THEN 
			p.Approve(from, Pr.SUBSCRIBED);
			p.Subscribe(from, Pr.SUBSCRIBE);			
		ELSIF type=Pr.SUBSCRIBED THEN
			sm.from:=from$; sm.to:=dir.Jid(dir.This(p.owner))$; sm.group:=''; sm.name:=''; 
			dir.Broadcast(dir.This(p.owner), sm);
			IF (sm.group$#'') OR (sm.name$#'') THEN dir.This(p.owner).rs.Update(from, sm.name$, sm.group$, NIL) END;
		ELSIF type=Pr.UNSUBSCRIBED THEN
			
		ELSE
			pm.from:=from$;
			pm.to:=dir.Jid(dir.This(p.owner))$;
			pm.type:=type$;
			pm.show:=show$;
			pm.status:=status$;
			pm.priority:=priority;
			pm.opts:=opts;
			dir.Broadcast(dir.This(p.owner), pm)
		END;	
	END Notify;
	
	PROCEDURE (h: RsHook) Push(r: Rs.Roster; item: Rs.Item);
	VAR i: INTEGER; from: ARRAY 1024 OF CHAR;
	BEGIN
		
	END Push;
	
	PROCEDURE (h: MsHook) Notify(m: Ms.Messenger; to, from, type, subject, body, thread: ARRAY OF CHAR; delay: Delay);
	VAR msg: StdMsg;
	BEGIN
		msg.to:=to$;
		msg.from:=from$;
		msg.type:=type$;
		msg.subject:=DS.Create(subject).String();
		msg.body:=DS.Create(body).String();
		msg.thread:=DS.Create(thread).String();
		msg.delay:=delay;
		dir.Broadcast(dir.This(m.owner), msg);
	END Notify;
	
	PROCEDURE (h: IbbHook) Incoming (ibb: Ibb.Ibb; sid, from: ARRAY OF CHAR; VAR wr: Files.Writer; VAR verify: BOOLEAN): BOOLEAN;
		VAR x: ANYPTR; accept: BOOLEAN;
	BEGIN
		accept:=FALSE; verify:=TRUE;
		x:=dir.This(ibb.owner).streams.Item(sid);
		IF x#NIL THEN
			WITH x: StreamId DO
				wr:=x.file.NewWriter(NIL); wr.SetPos(0);
				accept:=TRUE;
			END;
		END;
		RETURN accept;
	END Incoming;
	
	PROCEDURE (h: IbbHook) Receiving (ibb: Ibb.Ibb; sid, from: ARRAY OF CHAR; file: Files.File; VAR stop: BOOLEAN);
		VAR si: StreamId; rm: ReceivingMsg;
	BEGIN
		si:=dir.This(ibb.owner).streams.Item(sid)(StreamId);
		rm.from:=from$; rm.to:=dir.Jid(dir.This(ibb.owner))$;
		rm.file:=file; rm.sid:=si; dir.Broadcast(dir.This(ibb.owner), rm);
		stop:=file.Length()=si.length;
	END Receiving;
	
	PROCEDURE (h: IbbHook) Received (ibb: Ibb.Ibb; sid, from: ARRAY OF CHAR; file: Files.File);
		VAR x: ANYPTR;  s: Session; rm: ReceivedFileMsg;
	BEGIN
		x:=dir.This(ibb.owner).streams.Item(sid);
		IF x#NIL THEN
			WITH x: StreamId DO
				rm.sid:=x;
				rm.file:=file;
				rm.from:=from$;
				s:=dir.This(ibb.owner);
				dir.Broadcast(s, rm)
			ELSE END;
		END;
	END Received;
	
	PROCEDURE (h: IbbHook) Transmitting (ibb: Ibb.Ibb; sid, to: ARRAY OF CHAR; pos: INTEGER; VAR stop: BOOLEAN);
	BEGIN
		stop:=FALSE;
	END Transmitting;
	
	PROCEDURE (h: IbbHook) Transmitted (ibb: Ibb.Ibb; sid, to: ARRAY OF CHAR);
		VAR x: ANYPTR;  s: Session; sm: SentFileMsg;
	BEGIN
		x:=dir.This(ibb.owner).streams.Item(sid);
		IF x#NIL THEN
			WITH x: StreamId DO
				sm.sid:=x;
				sm.from:=to$;
				s:=dir.This(ibb.owner);
				dir.Broadcast(s, sm)
			ELSE END;
		END;
	END Transmitted;
	
	PROCEDURE (h: BsHook) NewStream(bs: Bs.ByteStreams; from: ARRAY OF CHAR; VAR stream: Bs.Stream);
	BEGIN
	
	END NewStream;
	
	PROCEDURE (h: BsHook) Connect(bs: Bs.ByteStreams; host: Bs.Host; OUT s: Cs.Stream; OUT res: INTEGER);
	BEGIN
	
	END Connect;
	
	PROCEDURE (h: BsHook) Bind(bs: Bs.ByteStreams; host: Bs.Host; VAR l: Cs.Listener; OUT res: INTEGER);
	VAR proxyType, proxyAdr, proxyPort, protocol, adr, lAdr: ARRAY 128 OF CHAR;
	BEGIN
		(* IF Cfg.dir.ProxyEnabled() THEN
			Cfg.dir.GetProxyType(proxyType); Cfg.dir.GetProxyHostPort(proxyAdr, proxyPort);
			SternProxyCmds.PrepareAdr(proxyType, '', '0.0.0.0:'+host.port$, proxyAdr+':'+proxyPort, '', '', adr, lAdr, protocol, res);
			ASSERT(res=SternProxyCmds.ok, 60);
		ELSE 
		lAdr:='0.0.0.0:'+host.port$; protocol:='CommTCP'; (* END; *)
		S.NewListener(protocol, lAdr, l, res);*) 
	END Bind;
	
	PROCEDURE (h: BusHook) Recv(b: Bus.Bus; to, from: ARRAY OF CHAR; VAR msg: Bus.Message);
	BEGIN
		WITH msg: Msg DO
			msg.to:=to$; msg.from:=from$;
		ELSE END;
		dir.Broadcast(dir.This(b.owner), msg)
	END Recv;
	
	PROCEDURE (h: BusHook) Ok(b: Bus.Bus; IN from, id: ARRAY OF CHAR);
		VAR rm: BusResultMsg;
	BEGIN
		rm.code:=0; rm.id:=id$; rm.from:=from$; rm.owner:=dir.This(b.owner); rm.to:=dir.Jid(dir.This(b.owner))$;
		dir.Broadcast(dir.This(b.owner), rm);
	END Ok;

	PROCEDURE (h: BusHook) Error(b: Bus.Bus; IN from, id: ARRAY OF CHAR; code: INTEGER);
		VAR rm: BusResultMsg;
	BEGIN
		rm.code:=code; rm.id:=id$; rm.from:=from$; rm.owner:=dir.This(b.owner); rm.to:=dir.Jid(dir.This(b.owner))$;
		dir.Broadcast(dir.This(b.owner), rm);
	END Error;
	
	PROCEDURE (h: SiHook) Offered(si: Si.StreamInit; from: ARRAY OF CHAR; VAR a: Si.Action);
	VAR sa: StreamId;
	BEGIN
		NEW(sa);
		a:=sa;
	END Offered;
	
	PROCEDURE (h: SiHook) Ready(si: Si.StreamInit; from: ARRAY OF CHAR; a: Si.Action);
	VAR m: IncomingFileMsg;
	BEGIN
		WITH a: StreamId DO
			m.id:=a;
			m.name:=a.name$;
			m.descr:=a.descr$;
			m.length:=a.length;
			m.methods:=a.methods;
			m.from:=from$;
			dir.Broadcast(dir.This(si.owner), m);
		ELSE END;
	END Ready;
	
	PROCEDURE (h: SiHook) Accepted(si: Si.StreamInit; by: ARRAY OF CHAR; a: Si.Action; method: INTEGER);
	VAR m: AcceptedFileMsg; from, sid: ARRAY 256 OF CHAR; s: Session; rd: Files.Reader; 
	BEGIN
		s:=dir.This(si.owner);
		s.streams.Add(a.sid, a);
		WITH a: StreamId DO
			m.sid:=a; 
			m.from:=by$;
			from:=dir.Jid(s)$;
			dir.Broadcast(s, m);
			CASE method OF
				|ibbMethod: 
					rd:=a.file.NewReader(NIL); rd.SetPos(0); sid:=a.sid$;
					s.ibb.Send(from$, by$, rd, a.file.Length(), maxBlockSize, TRUE, sid);
				|bsMethod:
			ELSE END;
		ELSE END;
	END Accepted;
	
	PROCEDURE (a: VerAction) Result;
	BEGIN
	END Result;
	
	PROCEDURE (a: VerAction) Error;
	BEGIN
	END Error;
	
	PROCEDURE (h: VerHook) Request-(v: Ver.Version; OUT name, version, os: ARRAY OF CHAR);
	BEGIN
		name:='Unio';
		Dialog.MapString('#Xmpp:version', version);
		os:='Ominc BBCB Runtime Environment';
	END Request;
	
	PROCEDURE OfferFile(s: Session; file: Files.File; to, from, name, descr, date: ARRAY OF CHAR; range: BOOLEAN; offset, length: INTEGER; methods: SET; OUT sid: StreamId);
	VAR hash: ARRAY 33 OF CHAR;
	BEGIN
		NEW(sid); sid.file:=file;
		IF range THEN XmppFiles.GetFileChecksum(file, hash, offset, length) ELSE XmppFiles.GetFileChecksum(file, hash, 0, file.Length()) END;
		Si.OfferStream(s.si, to, from, name$, descr$, date$, range, offset, length, hash, methods, sid);
	END OfferFile;
	
	PROCEDURE (a: RecAction) Confirmed(m: Ms.Messenger;  IN from, id: ARRAY OF CHAR);
		VAR s: Session; msg: ConfirmedMsg;
	BEGIN
		s:=dir.This(m.owner);
		msg.to:=dir.Jid(s)$;
		msg.from:=from$;
		msg.id:=id$;
		msg.res:=0;
		dir.Broadcast(s, msg);
	END Confirmed;
	
	PROCEDURE (a: RecAction) TimeOut(m: Ms.Messenger;  IN to, id: ARRAY OF CHAR);
		VAR s: Session; msg: TimeOutMsg;
	BEGIN
		s:=dir.This(m.owner);
		msg.to:=dir.Jid(s)$;
		msg.from:=to$;
		msg.id:=id$;
		msg.res:=0;
		dir.Broadcast(s, msg);
	END TimeOut;
	
	PROCEDURE (a: AliveAction) Do(VAR after: LONGINT; VAR stop: BOOLEAN; OUT data: ANYPTR);
		VAR res: INTEGER; s: Session;
	BEGIN
		s:=dir.This(a.s);
		IF (s#NIL) & (a.s#NIL) & a.s.Authorized()&(s.pr#NIL) THEN
			IF a.last = NIL THEN
				NEW(a.last); a.last.s:=a.s;
				a.res:=wait; 
				after:=timeout;
				s.ds.Query(dir.Jid(s)$, a.s.Server()$, Ds.items, '', a.last);
			ELSE
				IF a.res IN {wait, error} THEN
					Log.Ln; Log.String('ping error');
					stop:=TRUE;
					dir.ConnectionError(s);
				ELSIF a.res=ok THEN
					stop:=FALSE; after:=5000;
					a.res:=-1;
				END;
				a.last:=NIL;
			END;	
		END;
	END Do; 
	
	PROCEDURE (a: AliveAction) Stop(OUT data: ANYPTR);
	BEGIN
	
	END Stop;
	
	PROCEDURE (a: AliveAction) Start(OUT data: ANYPTR);
	BEGIN
		a.res:=-1;
	END Start;
	
	PROCEDURE StartAliveAction(s: Session);
	BEGIN
		NEW(s.alive); s.alive.s:=s.s; 
		Actions.Start(s.alive, timeout, FALSE);
	END StartAliveAction;	
	
	PROCEDURE (a: ConnectAction) Do(VAR after: LONGINT; VAR stop: BOOLEAN; OUT data: ANYPTR);
	VAR res: INTEGER; ph: PrHook; mh: MsHook; ibh: IbbHook; bsh: BsHook; rh: RsHook; dh: DsHook; bh: BusHook; sih: SiHook; vh: VerHook;
	BEGIN
		IF ~a.s.s.Authorized()&(a.s.pr=NIL) THEN
			a.s.s.StartStream;
			a.s.pr:=a.s.s.LoadExtension('XmppPresence', res)(Pr.Presence);
			ASSERT(res=Core.loaded, 0);
			a.s.rs:=a.s.s.LoadExtension('XmppRoster', res)(Rs.Roster);
			ASSERT(res=Core.loaded, 0);
			a.s.ms:=a.s.s.LoadExtension('XmppMessenger', res)(Ms.Messenger);
			ASSERT(res=Core.loaded, 0);
			a.s.ibb:=a.s.s.LoadExtension('XmppIbb', res)(Ibb.Ibb);
			ASSERT(res=Core.loaded, 0);
			a.s.bs:=a.s.s.LoadExtension('XmppByteStreams', res)(Bs.ByteStreams);
			ASSERT(res=Core.loaded, 0);
			a.s.si:=a.s.s.LoadExtension('XmppStreamInit', res)(Si.StreamInit);
			ASSERT(res=Core.loaded, 0);
			a.s.ds:=a.s.s.LoadExtension('XmppDisco', res)(Ds.Disco);
			ASSERT(res=Core.loaded);
			a.s.bus:=a.s.s.LoadExtension('XmppBus', res)(Bus.Bus);
			ASSERT(res=Core.loaded);
			a.s.v:=a.s.s.LoadExtension('XmppVersion', res)(Ver.Version);
			ASSERT(res=Core.loaded);
			a.s.pi:=a.s.s.LoadExtension('XmppPing', res)(Pi.Pinger);
			ASSERT(res=Core.loaded);
			NEW(ph); a.s.pr.SetHook(ph);
			NEW(rh); a.s.rs.SetHook(rh);
			NEW(mh); a.s.ms.SetHook(mh);
			NEW(ibh); a.s.ibb.SetHook(ibh);
			NEW(bsh); a.s.bs.SetHook(bsh);
			NEW(dh); a.s.ds.SetHook(dh);
			NEW(bh); a.s.bus.SetHook(bh);
			NEW(sih); a.s.si.SetHook(sih);
			NEW(vh); a.s.v.SetHook(vh);
		ELSIF ~a.s.s.Authorized()&(a.s.pr#NIL) THEN
			stop:=((Services.Ticks()-a.started)>maxDelay);
		ELSIF a.s.s.Authorized() & a.s.pr.valid THEN
			stop:=TRUE;
			dir.Connected(a.s);
			StartAliveAction(a.s);
			Core.SetLimit(a.s.s, 3000)
		END;
	END Do;
	
	PROCEDURE (a: ConnectAction) Stop(OUT data: ANYPTR);
	BEGIN
		IF (~a.s.s.Authorized() OR ((Services.Ticks()-a.started)>maxDelay)) THEN dir.ConnectionError(a.s) END;
	END Stop;
	
	PROCEDURE (a: ConnectAction) Start(OUT data: ANYPTR);
	BEGIN
	
	END Start;
	
	PROCEDURE (a: DisconnectAction) Do(VAR after: LONGINT; VAR stop: BOOLEAN; OUT data: ANYPTR);
	VAR res: INTEGER; 
	BEGIN
		IF a.s.s.Authorized()&(a.s.pr#NIL) THEN
			Core.dir.Stop(a.s.s);
			Actions.Stop(a.s.alive);
			IF a.s.testOnly THEN 
				
			ELSE
				dir.Disconnected(a.s, '');
			END;
		END;
	END Do; 
	
	PROCEDURE (a: DisconnectAction) Stop(OUT data: ANYPTR);
	BEGIN
	
	END Stop;
	
	PROCEDURE (a: DisconnectAction) Start(OUT data: ANYPTR);
	BEGIN
	
	END Start;	
	
	PROCEDURE Stop*(s: Session);
	VAR da: DisconnectAction; res: INTEGER; 
	BEGIN	
		NEW(da); da.s:=s;
		s.pr.Unavailable;
		s.s.UnloadExtension(da.s.pr, res);
		s.s.UnloadExtension(da.s.rs, res);
		s.s.UnloadExtension(da.s.ms, res);
		s.s.UnloadExtension(da.s.ibb, res);
		s.s.UnloadExtension(da.s.bs, res);
		s.s.UnloadExtension(da.s.ds, res);
		Actions.Start(da, 200, TRUE);
	END Stop;

	PROCEDURE Start*(s: Session; OUT res: INTEGER);
	VAR ca: ConnectAction; 
	BEGIN
		Core.dir.Start(s.s, res);
		IF res=0 THEN
			NEW(ca); ca.s:=s; Actions.Start(ca, 100, FALSE);
			dir.list.Add(s.s, s);
		END;
	END Start;
	
	PROCEDURE New*(proto, localAdr, remoteAdr, user, password, server, resource: ARRAY OF CHAR; OUT s: Session);
	VAR jid: ARRAY 512 OF CHAR; eh: ErrorHook; 
	BEGIN
		NEW(s); 
		s.testOnly:=FALSE;
		Str.Jid(user, server, resource, jid);
		ASSERT(jid#'', 101);
		Conn.InitDriver(proto, localAdr);
		s.s:=Core.dir.NewSession(remoteAdr, jid, password, Core.normalOpts+{Core.plain});
		s.connected:=FALSE;
		s.streams:=Map.NewStrMap();
		NEW(eh); s.s.SetErrorHook(eh);
		ASSERT(s.s#NIL, 102);
	END New;
	
	PROCEDURE Send* (s: Session; VAR msg: Msg; OUT res: INTEGER);
	VAR ra: RsAction; aa: RsAddAction;
	BEGIN
		ASSERT(s#NIL, 20);
		IF s.connected THEN
			WITH 
				|msg: BusMsg DO
				|msg: GetRosterMsg DO NEW(ra); s.rs.Request(ra);
				|msg: RosterAddMsg DO NEW(aa); aa.jid:=msg.jid$; s.rs.Add(msg.jid$, msg.name$, msg.group$, aa);
				|msg: RosterUpdateMsg DO NEW(ra); s.rs.Update(msg.jid$, msg.newName$, msg.newGroup$, ra)
			ELSE res:=-1 END;
		ELSE res:=-2 END;	
	END Send;
	
	PROCEDURE SendTo* (s: Session; IN to: ARRAY OF CHAR; VAR msg: Bus.Message; OUT res: INTEGER);
		VAR from, id: ARRAY 256 OF CHAR; a: RecAction;
	BEGIN
		from:=s.s.Username()$+'@'+s.s.Server()$+'/'+s.s.Resource()$;
		WITH 
			|msg: BusMsg DO 
				NEW(msg.id, 33); msg.id[0]:=0X;
				s.bus.Send(msg, s.s.Username()$+'@'+s.s.Server()$+'/'+s.s.Resource()$, to, msg.id); res:=0;
			|msg: SendStdMsg DO
				ASSERT((msg.subject#NIL) & (msg.body#NIL) & (msg.thread#NIL), 20); 
				s.ms.Send(from, to, msg.type$, msg.subject$, msg.body$, msg.thread$);
			|msg: SendConfirmableMsg DO
				ASSERT((msg.subject#NIL) & (msg.body#NIL) & (msg.thread#NIL), 20); msg.id:=''; NEW(a);
				Ms.dir.SendWithReceipts(s.ms, from$, to$, msg.type$, msg.subject$, msg.body$, msg.thread$, a, msg.id);
			|msg: SendFileMsg DO OfferFile(s, msg.file, to, from, msg.name, msg.descr, msg.date, msg.range, msg.offset, msg.length, msg.methods, msg.sid);
			|msg: AcceptFileMsg DO msg.id.file:=msg.file; s.streams.Add(msg.id.sid, msg.id); Si.AcceptStream(s.si, to, from, msg.id, msg.method);
			|msg: PresenceMsg DO s.pr.Set(to$, from$, msg.show$, msg.status$, msg.priority, msg.type$);
		ELSE res:=-1 END;
	END SendTo;
	
	PROCEDURE HandleBusMsg* (VAR msg: AbfBus.Message);
	VAR m: ConnectingMsg; s: Session;
	BEGIN
		WITH 
			msg: Core.ConsoleMsg DO
			(* msg.session *)
			|msg: Core.UpdateMsg DO
				IF ~msg.session.Authorized() & (dir.This(msg.session) # NIL) THEN
					s:=dir.This(msg.session); INC(s.connectPos);
					m.pos:=s.connectPos; m.len:=14; m.op:=msg.session.Server()$+': '+msg.session.Resource()$+': '+msg.item.GetName()$+': '+msg.item.GetParam('type')$+': '+msg.item.GetParam('id')$;
					dir.Broadcast(s, m);
				END;
		ELSE END;
	END HandleBusMsg;
	
	PROCEDURE GetDataLength*(s: Session; OUT in, out: LONGINT);
	BEGIN
		IF s#NIL THEN Core.GetDataLength(s.s, in, out) END;
	END GetDataLength;
	
	PROCEDURE Init;
	BEGIN
		NEW(dir);
		dir.list:=Map.NewPtrMap();
		AbfBus.Subscribe("XmppSession", "XmppCore", "ConsoleMsg", FALSE);
		AbfBus.Subscribe("XmppSession", "XmppCore", "UpdateMsg", FALSE);
	END Init;

BEGIN
	Init		
CLOSE

END XmppSession.