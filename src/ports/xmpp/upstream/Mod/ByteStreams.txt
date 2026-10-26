MODULE XmppByteStreams;
(**	project	= "XMPP"
	organization	= ""
	contributors	= ""
 	purpose	= "???????? ?????????? XEP-0065: SOCKS5 Bytestreams !!! ???? ??? ??????? !!!"
	changes	= "
	- , nn, ...
	"
	issues	= ""
**)

	IMPORT Core := XmppCore, Items:=XmlcoreItems, Const:=XmppConst, Log, Stuff:=XmppStuff,  DS:=StringsDyn, Strings, Files, CommStreams, Services, Rand:=ypkMathRandom;
	
	CONST
		urn = 'http://jabber.org/protocol/bytestreams';
		tcpMode* = 'tcp';
		query = 'query';
		modeAttr = 'mode';
		sidAttr = 'sid';
		jidAttr = 'jid';
		hostAttr = 'host';
		portAttr = 'port';
		streamhostElem = 'streamhost';
		streamhostUsedElem = 'streamhost-used';
	
		maxFails = 50;
		
	TYPE
		DynString = DS.DynString;
		
		Directory* = POINTER TO RECORD(Core.ExtensionDir) END;
		
		Host* = POINTER TO RECORD
			jid-, host-, port- : POINTER TO ARRAY OF CHAR;
			server : Server;
		END;
		
		ListenAction = POINTER TO RECORD(Services.Action)
			host : Host;
			failed : INTEGER;
			iq : QueryIq;
		END;
				
		Stream* = POINTER TO ABSTRACT RECORD 
			id-, sid, mode : ARRAY 127 OF CHAR;
			connected- : BOOLEAN;
			hosts : Stuff.List;
			rd : Reader;
			wr : Writer;
			owner : ByteStreams
		END;
		
		Queue = POINTER TO RECORD
			list- : Stuff.List;
		END;
		
		ByteStreams* = POINTER TO LIMITED RECORD (Core.Extension)
			valid- : BOOLEAN;
			queue : Queue;
			hook : Hook;
		END;	
		
		Hook* = POINTER TO ABSTRACT RECORD END;
		
		Server = POINTER TO RECORD (Services.Action)
			listener: CommStreams.Listener;
			owner : Stream;	
		END; 
		
		Reader = POINTER TO RECORD (Services.Action)
			stream: CommStreams.Stream;
			owner : Stream;
			wr : Files.Writer;	
		END;
		
		Writer =  POINTER TO RECORD
			stream: CommStreams.Stream;
			owner : Stream;
			busy : BOOLEAN;
		END; 
		
		WriteAction = POINTER TO RECORD(Services.Action)
			rd : Files.Reader;
			owner : Writer;
			last : INTEGER;
		END;
		
		QueryIq = POINTER TO RECORD(Core.Iq)
			mode, sid : ARRAY 127 OF CHAR; 
			hosts : Stuff.List;
		END;
		
		AcceptIq = POINTER TO RECORD(Core.Iq)
			jid : ARRAY 512 OF CHAR;
		END;
		
		ErrorIq = POINTER TO RECORD(Core.Iq) END;
		
	VAR
		dir- : Directory;	
	
	PROCEDURE (s : Stream) Init-(OUT hostJid : ARRAY OF CHAR), NEW, ABSTRACT;
	PROCEDURE (s : Stream) Accepted-, NEW, ABSTRACT; 
	PROCEDURE (s : Stream) Connected-, NEW, ABSTRACT;
	PROCEDURE (s : Stream) ReaderClosed-(file : Files.File), NEW, ABSTRACT;
	PROCEDURE (s : Stream) WriterClosed-, NEW, ABSTRACT;
	PROCEDURE (s : Stream) Done-, NEW, ABSTRACT;
	PROCEDURE (s : Stream) Incoming-(VAR file : Files.File; OUT pos : INTEGER), NEW, ABSTRACT;
	PROCEDURE (s : Stream) ReadBytes-(), NEW, ABSTRACT;
	PROCEDURE (s : Stream) WroteBytes-(pos : INTEGER), NEW, ABSTRACT;
	PROCEDURE (s : Stream) Ready-, NEW, ABSTRACT;
	PROCEDURE (s : Stream) Failed-, NEW, ABSTRACT;
	PROCEDURE (h : Hook) NewStream-(bs : ByteStreams; from : ARRAY OF CHAR; VAR s : Stream), NEW, ABSTRACT;
	PROCEDURE (h : Hook) Connect-(bs : ByteStreams; host : Host; OUT s : CommStreams.Stream; OUT res : INTEGER), NEW, ABSTRACT;
	PROCEDURE (h : Hook) Bind-(bs : ByteStreams; host : Host; VAR l : CommStreams.Listener; OUT res : INTEGER), NEW, ABSTRACT;
	
	PROCEDURE (q: Queue) Add(s : Stream), NEW; 
	BEGIN
		IF q.list=NIL THEN q.list:=Stuff.CreateList() END;
		q.list.Add(s);
	END Add;	
	
	PROCEDURE (q: Queue) Find(id : ARRAY OF CHAR): Stream, NEW; 
	VAR i : INTEGER; ok : BOOLEAN;
	BEGIN
		i:=0; ok:=FALSE;
		WHILE (i<q.list.Length()) & ~ok DO
			ok:=(q.list.Item(i)(Stream).id=id);
			INC(i);
		END;
		IF ok THEN DEC(i); RETURN q.list.Item(i)(Stream)
		ELSE RETURN NIL END;
	END Find;	
	
	PROCEDURE (q: Queue) Remove(s : Stream), NEW;
	BEGIN
		q.list.Remove(s);
	END Remove;
	
	PROCEDURE CreateWriter(owner : Stream; stream : CommStreams.Stream) : Writer;
	VAR wr : Writer;
	BEGIN
		NEW(wr); 
		wr.owner:=owner;
		wr.stream := stream;
		wr.busy:=FALSE;
		RETURN wr
	END CreateWriter;
	
	PROCEDURE CreateReader(owner : Stream; stream : CommStreams.Stream) : Reader;
	VAR rd : Reader;
	BEGIN
		NEW(rd);
		rd.owner:=owner;
		rd.stream := stream; 
		Services.DoLater(rd, Services.now);
		RETURN rd;
	END CreateReader;
	
	PROCEDURE (server: Server) Do;
	VAR s: CommStreams.Stream; 
	BEGIN
		server.listener.Accept(s);
		IF s#NIL THEN 
			server.owner.rd:=CreateReader(server.owner, s);
			server.owner.wr:=CreateWriter(server.owner, s);
			server.listener.Close;
			server.owner.connected:=TRUE;
			server.owner.Ready;
		ELSE
			Services.DoLater(server, Services.now)
		END;
	END Do;
	
	PROCEDURE (a : ListenAction) Do;
	VAR  l: CommStreams.Listener; res : INTEGER;
	BEGIN
		a.host.server.owner.owner.hook.Bind(a.host.server.owner.owner, a.host, l, res);
		IF l#NIL THEN
			a.host.server.listener := l; Services.DoLater(a.host.server, Services.now);
			a.host.server.owner.owner.owner.Send(a.iq);
			Log.Ln; Log.String('[xmpp p2p] ?????? ???????');
		ELSIF (res=CommStreams.localAdrInUse) & (a.failed<=maxFails) THEN
			Services.DoLater(a, Services.Ticks()+100);
			INC(a.failed);
			Log.Ln; Log.String('[xmpp p2p] ????????? ??????? ??????? ???????');
		ELSE a.host.server.owner.connected:=FALSE; a.host.server.owner.Failed; Log.String('tcp-stream error: '); Log.Int(res); Log.Ln END;
	END Do;
	
	PROCEDURE Incoming(s : Stream);
	VAR file : Files.File; pos : INTEGER;
	BEGIN
		pos:=0;
		s.Incoming(file, pos);
		ASSERT(file#NIL);
		s.rd.wr:=file.NewWriter(NIL); s.rd.wr.SetPos(pos);
	END Incoming;
	
	PROCEDURE ReadBytes(s : Stream);
	BEGIN
		s.ReadBytes;
	END ReadBytes;
	
	PROCEDURE (rd: Reader) Do;
	VAR buf: ARRAY 65535 OF BYTE; read, res: INTEGER;
	BEGIN
		IF rd.stream.IsConnected() THEN
			rd.stream.ReadBytes(buf, 0, LEN(buf), read);
			IF (read>0)&(rd.wr=NIL)  THEN
				Incoming(rd.owner);
				ASSERT(rd.wr#NIL);
				rd.wr.WriteBytes(buf, 0, read);
				ReadBytes(rd.owner);
			ELSIF (read>0)&(rd.wr#NIL) THEN
				rd.wr.WriteBytes(buf, 0, read);
				ReadBytes(rd.owner);
			END;
			Services.DoLater(rd, Services.now);
		ELSE
			rd.owner.connected:=FALSE;
			IF rd.wr#NIL THEN 
				rd.owner.ReaderClosed(rd.wr.Base());
			END;
			rd.owner.owner.queue.Remove(rd.owner);
		END;
	END Do;
	
	PROCEDURE (wr: Writer) Closed, NEW;
	BEGIN
		wr.owner.connected:=FALSE;
		wr.owner.WriterClosed;
		wr.owner.owner.queue.Remove(wr.owner);
	END Closed;
	
	PROCEDURE (wr: Writer) Done, NEW;
	BEGIN
		wr.busy:=FALSE;
		wr.owner.Done;
	END Done;
	
	PROCEDURE (wr : Writer) WroteBytes(pos : INTEGER), NEW;
	BEGIN
		wr.owner.WroteBytes(pos);
	END WroteBytes;
	
	PROCEDURE (wr: Writer) Write(file : Files.File; pos, len : INTEGER; OUT res : INTEGER), NEW;
	VAR a : WriteAction; 
	BEGIN
		IF ~wr.busy THEN
			NEW(a);
			a.rd:=file.NewReader(NIL);
			a.rd.SetPos(pos);
			a.last:=pos+len;
			a.owner:=wr;
			Services.DoLater(a, Services.now);
			wr.busy:=TRUE;
			res:=0
		ELSE res:=-1 END;
	END Write;
	
	PROCEDURE (a : WriteAction) Do;
	VAR buf : ARRAY 65535 OF BYTE; lastPos, len, written : INTEGER;
	BEGIN
		IF a.owner.stream.IsConnected() THEN
			IF a.rd.Pos()<a.last THEN
				lastPos:=a.rd.Pos(); len:=0;
				WHILE (len<LEN(buf)) & ~a.rd.eof DO
					a.rd.ReadByte(buf[len]);
					INC(len);
				END;
				DEC(len);
				a.owner.stream.WriteBytes(buf, 0, len, written);
				a.rd.SetPos(lastPos+written);				
				a.owner.WroteBytes(a.rd.Pos());
				Services.DoLater(a, Services.Ticks());
			ELSE a.owner.Done END
		ELSE
			a.owner.Closed;
		END;
	END Do;
	
	PROCEDURE NewHost(jid, host, port : ARRAY OF CHAR) : Host;
	VAR h : Host;
	BEGIN
		NEW(h); h.jid:=DS.Create(jid).String(); h.host:=DS.Create(host).String(); h.port:=DS.Create(port).String();
		RETURN h;
	END NewHost;
	
	PROCEDURE (q : QueryIq) Do() : Items.Item;
		VAR n, n1, n2: Items.Item; i : INTEGER;
	BEGIN
		n:=Items.New(Const.iq);
		n1:=Items.New(query); n1.SetParam(Const.xmlns,urn);
		IF q.mode#'' THEN n1.SetParam(modeAttr, q.mode$) END;
		IF q.sid#'' THEN n1.SetParam(sidAttr, q.sid$) END;
		IF q.hosts#NIL THEN
			FOR i:=0 TO q.hosts.Length()-1 DO
				n2:=Items.New(streamhostElem); 
				n2.SetParam(jidAttr, q.hosts.Item(i)(Host).jid$); 
				n2.SetParam(hostAttr, q.hosts.Item(i)(Host).host$);
				IF q.hosts.Item(i)(Host).port$#'' THEN n2.SetParam(portAttr, q.hosts.Item(i)(Host).port$) END;
				n1.Add(n2);
			END;
		END;
		n.Add(n1);
		RETURN n;				
	END Do;
	
	PROCEDURE (q : QueryIq) Use(data : Items.Item);
		VAR n, x : Items.Item; 
	BEGIN
		n:=data.First();
		ASSERT(n#NIL); ASSERT(n.GetName()$=query);
		q.mode:=n.GetParam(modeAttr)$;
		q.sid:=n.GetParam(sidAttr)$;
		q.hosts:=Stuff.CreateList();
		x:=n.First();
		WHILE x#NIL DO
			IF x.GetName()$ = streamhostElem THEN
				q.hosts.Add(NewHost(x.GetParam(jidAttr)$, x.GetParam(hostAttr)$, x.GetParam(portAttr)$));
			END;
			x:=n.Next(x);
		END;
	END Use;
	
	PROCEDURE (a : AcceptIq) Do() : Items.Item;
		VAR n, n1, n2 : Items.Item;
	BEGIN
		n:=Items.New(Const.iq);
		IF a.from$#'' THEN n.SetParam(Const.from, a.from$); END;
		IF a.to$#'' THEN n.SetParam(Const.to, a.to$); END;
		IF a.type$#'' THEN n.SetParam(Const.type, a.type$); END;
		IF a.id$#'' THEN n.SetParam(Const.id, a.id$); END;
		IF a.lang$#'' THEN n.SetParam(Const.xml_lang, a.lang$); END;
		n1:=Items.New(query); n1.SetParam(Const.xmlns,urn);
			n2:=Items.New(streamhostUsedElem); 
			n2.SetParam(jidAttr, a.jid$); 
			n1.Add(n2);
		n.Add(n1);
		RETURN n;				
	END Do;
	
	PROCEDURE (a : AcceptIq) Use(data : Items.Item);
	VAR x, n : Items.Item; 
	BEGIN
		n:=data.First();
		ASSERT(n#NIL); ASSERT(n.GetName()$=query);
		n:=n.First();
		IF n.GetName()$ = streamhostElem THEN
			a.jid:=x.GetParam(jidAttr)$;
		END;
	END Use;
	
	PROCEDURE (e : ErrorIq) Do() : Items.Item;
		VAR n, n1 : Items.Item;
	BEGIN
		n:=Items.New(Const.iq);
		IF e.from$#'' THEN n.SetParam(Const.from, e.from$); END;
		IF e.to$#'' THEN n.SetParam(Const.to, e.to$); END;
		IF e.type$#'' THEN n.SetParam(Const.type, e.type$); END;
		IF e.id$#'' THEN n.SetParam(Const.id, e.id$); END;
		IF e.lang$#'' THEN n.SetParam(Const.xml_lang, e.lang$); END;
		n1:=Items.New(Const.error); n1.SetParam(Const.xmlns,urn);
		n.Add(n1);
		RETURN n;				
	END Do;
	
	PROCEDURE (s : Stream) AddHost*(jid : ARRAY OF CHAR; host, port : ARRAY OF CHAR), NEW;
	BEGIN
		IF s.hosts=NIL THEN s.hosts:=Stuff.CreateList() END;
		s.hosts.Add(NewHost(jid, host, port));
	END AddHost;
	
	PROCEDURE (s : Stream) GetHost*(index : INTEGER; OUT jid : ARRAY OF CHAR), NEW;
	BEGIN
		ASSERT(s.hosts#NIL, 20);
		ASSERT((index<s.hosts.Length()) & (index>=0), 21);
		jid:=s.hosts.Item(index)(Host).jid$;
	END GetHost;
	
	PROCEDURE (s : Stream) NofHosts*():INTEGER, NEW;
	BEGIN
		ASSERT(s.hosts#NIL, 20);
		RETURN s.hosts.Length();
	END NofHosts;

	PROCEDURE (s : Stream) Write*(file : Files.File; start, len : INTEGER; OUT res : INTEGER), NEW;
	BEGIN
		ASSERT(file#NIL, 20);
		ASSERT((start>=0) & (start<file.Length()), 21);
		ASSERT(len-start<=file.Length(), 22);
		IF s.wr#NIL THEN s.wr.Write(file, start, len, res) ELSE s.Failed END;
	END Write;
	
	PROCEDURE CreateClient(to : ARRAY OF CHAR; s : Stream; OUT res : INTEGER);
	VAR i : INTEGER; h : Host; str : CommStreams.Stream;
	BEGIN
		FOR i:=0 TO s.hosts.Length()-1 DO
			h:=s.hosts.Item(i)(Host);
			IF h.jid$=to THEN
				s.owner.hook.Connect(s.owner, h, str, res);
				IF str#NIL THEN
					s.rd:=CreateReader(s, str);
					s.wr:=CreateWriter(s, str);
				ELSE s.connected:=FALSE; END;
			END;
		END;
	END CreateClient;
	
	PROCEDURE NewStream(bs : ByteStreams; qiq : QueryIq);
	VAR s : Stream; hostJid : ARRAY 512 OF CHAR; res : INTEGER; aiq : AcceptIq; eiq : ErrorIq;
	BEGIN
		ASSERT(bs.hook#NIL);
		bs.hook.NewStream(bs, qiq.from, s);
		ASSERT(s#NIL);
		s.mode:=qiq.mode$;
		s.sid:=qiq.sid$;
		s.hosts:=qiq.hosts;
		s.owner:=bs;
		s.Init(hostJid);
		ASSERT(hostJid#'');
		CreateClient(hostJid, s, res);
		bs.queue.Add(s);
		IF res=0 THEN
			NEW(aiq);
			aiq.Set(qiq.from, qiq.to,'', qiq.id,Const.result);
			aiq.jid:=hostJid$;
			bs.owner.Send(aiq);
			s.Connected;
		ELSE 
			NEW(eiq);
			eiq.Set(qiq.from, qiq.to,'', qiq.id,Const.error);
			bs.owner.Send(eiq);
			s.Failed;
		END;
	END NewStream;
	
	PROCEDURE CreateListeners(from : ARRAY OF CHAR; s : Stream; qiq: QueryIq; res : INTEGER);
	VAR i : INTEGER; h : Host; srv : Server; la : ListenAction;
	BEGIN
		FOR i:=0 TO s.hosts.Length()-1 DO
			h:=s.hosts.Item(i)(Host);
			IF h.jid$=from THEN
				NEW(h.server); h.server.owner:=s;
				NEW(la); la.host:=h; la.iq:=qiq; la.failed:=0;
				Services.DoLater(la, Services.now);
			END;
		END;
	END CreateListeners;
	
	PROCEDURE (bs : ByteStreams) CloseStream* (s : Stream), NEW;
	VAR i : INTEGER;
	BEGIN
		ASSERT(s#NIL, 20);
		IF (s.rd#NIL) & (s.rd.stream#NIL) THEN s.rd.stream.Close END;
		IF (s.wr#NIL) & (s.wr.stream#NIL) THEN 
			s.wr.stream.Close; 
			FOR i:=0 TO s.hosts.Length()-1 DO
				IF ( s.hosts.Item(i)(Host).server#NIL) & (s.hosts.Item(i)(Host).server.listener#NIL) THEN
					s.hosts.Item(i)(Host).server.listener.Close;
				END;
			END;
		END;
		s.hosts:=Stuff.CreateList();
		s.connected:=FALSE;
		bs.queue.Remove(s);
	END CloseStream;
	
	PROCEDURE (bs : ByteStreams) NewStream*(from, to : ARRAY OF CHAR; stream : Stream; mode : ARRAY OF CHAR) , NEW;
	VAR qiq : QueryIq; res : INTEGER;
	BEGIN
		ASSERT(stream#NIL, 20);
		ASSERT(from#'', 21);
		ASSERT(to#'', 22);
		ASSERT(mode = tcpMode, 23);
		ASSERT(stream.hosts#NIL, 24);
		NEW(qiq);
		Rand.UniRandStr(stream.id, 5); stream.id:='bytestream-'+stream.id$;
		qiq.Set(to, from, '',stream.id,Const.set);
		Rand.UniRandStr(stream.sid, 10); stream.sid:='stream-'+stream.sid$;
		qiq.sid:=stream.sid$; stream.mode:=mode$; qiq.mode:=mode$;
		qiq.hosts:=stream.hosts;
		bs.queue.Add(stream);
		stream.owner:=bs;
		CreateListeners(from, stream, qiq, res);
	END NewStream;
	
	PROCEDURE StreamAccepted(bs : ByteStreams; aiq : AcceptIq);
	VAR s : Stream;
	BEGIN
		s:=bs.queue.Find(aiq.id);
		IF s#NIL THEN s.Accepted ELSE Log.Ln; Log.String('[XMPP] invalid bytestream') END
	END StreamAccepted;
	
	PROCEDURE StreamFailed(bs : ByteStreams; eiq : ErrorIq);
	VAR s : Stream;
	BEGIN
		s:=bs.queue.Find(eiq.id);
		IF s#NIL THEN s.Failed ELSE Log.Ln; Log.String('[XMPP] invalid bytestream') END
	END StreamFailed;
	
	PROCEDURE (bs : ByteStreams) Iq-(data : Items.Item; VAR res : INTEGER);
	VAR n : Items.Item; qiq : QueryIq; aiq : AcceptIq; eiq : ErrorIq;
	BEGIN
		IF (data.First()#NIL) THEN
			n:=data.First();
			IF ((n.GetParam(Const.xmlns)$ = urn)) THEN
				IF (data.GetParam(Const.type)$=Const.result) THEN
					NEW(aiq); aiq.Init(data); StreamAccepted(bs, aiq);
				ELSIF (data.GetParam(Const.type)$=Const.error) THEN
					NEW(eiq); eiq.Init(data); StreamFailed(bs, eiq);
				ELSIF (data.GetParam(Const.type)$=Const.set) THEN
					NEW(qiq); qiq.Init(data); NewStream(bs, qiq);
				END;
			ELSE END;
		END;
		res:=Core.continue;
	END Iq;
	
	PROCEDURE (bs : ByteStreams) SetHook*(h : Hook), NEW;
	BEGIN
		bs.hook:=h;
	END SetHook;
	
	PROCEDURE (bs : ByteStreams) Start-;
	BEGIN
		bs.valid:=TRUE;
	END Start;
	
	PROCEDURE (bs : ByteStreams) Stop-;
	BEGIN
		bs.valid:=FALSE;
	END Stop;
	
	PROCEDURE (d : Directory)Create-(session : Core.Session) : Core.Extension;
	VAR bs : ByteStreams;
	BEGIN
		NEW(bs);
		NEW(bs.queue);
		bs.valid:=FALSE;
		RETURN bs;
	END Create;
	
	PROCEDURE Init;
	VAR d : Directory;
	BEGIN
		NEW(d);
		dir:=d;
	END Init;

BEGIN
	Init	
END XmppByteStreams.