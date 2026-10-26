MODULE XmppExtended;

	

	IMPORT CommStreams, Dialog, Files, Services, StdCmds, XmlcoreItems, XmppByteStreams, XmppConsole, Log := StdLog, XmppCore, XmppDisco, XmppIbb, XmppMessenger, XmppPresence, XmppRegister, XmppRoster;

	TYPE Action = POINTER TO RECORD (Services.Action) END;
		PresenceHook = POINTER TO RECORD (XmppPresence.Hook) END;
		MessengerHook = POINTER TO RECORD (XmppMessenger.Hook) END;
		IbbHook = POINTER TO RECORD (XmppIbb.Hook) END;
		RegHook = POINTER TO RECORD (XmppRegister.RegisterHook) END;
		RsHook = POINTER TO RECORD (XmppRoster.Hook) END;
		DiscoAction = POINTER TO RECORD(XmppDisco.Action) END;
		Stream = POINTER TO RECORD(XmppByteStreams.Stream) END;
		StreamHook = POINTER TO RECORD (XmppByteStreams.Hook) END;
		RosterAction = POINTER TO RECORD (XmppRoster.Action) END;
	VAR
		s: XmppCore.Session;
		pr: XmppPresence.Presence;
		rs: XmppRoster.Roster;
		msg: XmppMessenger.Messenger;
		ibb: XmppIbb.Ibb;
		ds: XmppDisco.Disco;
		to*, user*, password*, remoteAdr*: Dialog.String;
		bs: XmppByteStreams.ByteStreams;
		bytestream: Stream;

	PROCEDURE (h: PresenceHook) Notify (p: XmppPresence.Presence; type, from, show, status: ARRAY OF CHAR; priority: INTEGER; opts: XmppPresence.Opts);
	BEGIN
		Log.String(type + ' ' + from + ' ' + show + ' ' + status + ' '); Log.Int(priority); Log.Ln;
	END Notify;

	PROCEDURE (h: MessengerHook) Notify (m: XmppMessenger.Messenger; to, from, type, subject, body, thread: ARRAY OF CHAR; delay: XmppMessenger.Delay);
	BEGIN
		Log.Ln;
		Log.String(body);
		Log.Ln;
	END Notify;

	PROCEDURE (h: IbbHook) Incoming (ibb: XmppIbb.Ibb; sid, from: ARRAY OF CHAR; VAR wr: Files.Writer; VAR verify: BOOLEAN): BOOLEAN;
		VAR file: Files.File;
	BEGIN
		Log.String('Incoming');
		file := Files.dir.New(Files.dir.This('Xmpp/Rsrc/'), Files.dontAsk);
		wr := file.NewWriter(NIL); wr.SetPos(0);
		verify := TRUE;
		RETURN TRUE;
	END Incoming;

	PROCEDURE (h: IbbHook) Receiving (ibb: XmppIbb.Ibb; sid, from: ARRAY OF CHAR; file: Files.File; VAR cancel: BOOLEAN);
	BEGIN
		Log.String('Receiving');
	END Receiving;

	PROCEDURE (h: IbbHook) Transmitting- (ibb: XmppIbb.Ibb; sid, to: ARRAY OF CHAR; pos: INTEGER; VAR cancel: BOOLEAN);
	BEGIN
		Log.String('Transmitting');
	END Transmitting;

	PROCEDURE (h: IbbHook) Transmitted- (ibb: XmppIbb.Ibb; sid, to: ARRAY OF CHAR);
	BEGIN
		Log.String('Transmitted');
	END Transmitted;

	PROCEDURE (h: IbbHook) Received- (ibb: XmppIbb.Ibb; sid, from: ARRAY OF CHAR; file: Files.File);
		VAR res: INTEGER;
	BEGIN
		file.Register('test', 'odc', Files.dontAsk, res);
		file.Close;
		Log.String('Received');
	END Received;

	PROCEDURE (h: RegHook) Registered- (IN username, password: ARRAY OF CHAR);
	BEGIN
		Log.String('registered');
	END Registered;

	PROCEDURE (h: RegHook) NeedField- (IN name: ARRAY OF CHAR; OUT value: ARRAY OF CHAR);
	BEGIN
		Log.String('need field');
		value := 'value';
	END NeedField;

	PROCEDURE (h: RegHook) Failed- (IN error: ARRAY OF CHAR);
	BEGIN
		Log.String(error);
	END Failed;

	PROCEDURE (h: RsHook) Push (r: XmppRoster.Roster; item: XmppRoster.Item);
	BEGIN
		Log.String('push');
	END Push;

	PROCEDURE (a: DiscoAction) Result;
		VAR i: INTEGER;
	BEGIN
		Log.String('Disco ');
		IF a.type = XmppDisco.info THEN
			Log.Int(a.identities.Length()); Log.String(' '); Log.Int(a.features.Length());
		ELSE
			Log.Int(a.items.Length());
		END;
		Log.Ln;
	END Result;

	PROCEDURE (a: DiscoAction) Error;
	BEGIN

	END Error;

	PROCEDURE (a: RosterAction) Result;
		VAR i: INTEGER;
	BEGIN
		Log.String('Roster ');
		Log.Int(a.items.Length());
	END Result;

	PROCEDURE (a: RosterAction) Error;
	BEGIN

	END Error;

	PROCEDURE (s: Stream) Init (OUT hostJid: ARRAY OF CHAR);
	BEGIN
		s.GetHost(0, hostJid);
		Log.String('init-stream')
	END Init;

	PROCEDURE (s: Stream) Accepted;
	BEGIN
		Log.String('accepted')
	END Accepted;

	PROCEDURE (s: Stream) Connected;
	BEGIN
		Log.String('connected')
	END Connected;

	PROCEDURE (s: Stream) WriterClosed;
	BEGIN
		Log.String('closed')
	END WriterClosed;

	PROCEDURE (s: Stream) Ready;
	BEGIN
		Log.String('ready')
	END Ready;

	PROCEDURE (s: Stream) Failed;
	BEGIN
		Log.String('failed')
	END Failed;

	PROCEDURE (s: Stream) Done;
	BEGIN
		Log.String('done');
	END Done;

	PROCEDURE (s: Stream) WroteBytes (pos: INTEGER);
	BEGIN
		Log.String('wrote');
	END WroteBytes;

	PROCEDURE (s: Stream) ReadBytes ();
	BEGIN
		Log.String('read');
	END ReadBytes;

	PROCEDURE (s: Stream) Incoming (VAR file: Files.File; OUT pos: INTEGER);
	BEGIN
		file := Files.dir.New(Files.dir.This(''), Files.dontAsk);
		pos := 0;
	END Incoming;

	PROCEDURE (s: Stream) ReaderClosed (file: Files.File);
		VAR res: INTEGER;
	BEGIN
		file.Register('~test', 'file', Files.dontAsk, res);
	END ReaderClosed;

	PROCEDURE (h: StreamHook) NewStream (bs: XmppByteStreams.ByteStreams; from: ARRAY OF CHAR; VAR stream: XmppByteStreams.Stream);
		VAR s: Stream;
	BEGIN
		NEW(s);
		stream := s;
	END NewStream;

	PROCEDURE (h: StreamHook) Connect (bs: XmppByteStreams.ByteStreams; host: XmppByteStreams.Host; OUT s: CommStreams.Stream; OUT res: INTEGER);
	BEGIN
		CommStreams.NewStream('CommTCP', '0.0.0.0:0', host.host$ + ':' + host.port$, s, res);
	END Connect;

	PROCEDURE (h: StreamHook) Bind (bs: XmppByteStreams.ByteStreams; host: XmppByteStreams.Host; VAR l: CommStreams.Listener; OUT res: INTEGER);
	BEGIN
		CommStreams.NewListener('CommTCP', '0.0.0.0:' + host.port$, l, res);
	END Bind;

	PROCEDURE (a: Action) Do;
		VAR res: INTEGER; ph: PresenceHook; mh: MessengerHook; ibh: IbbHook; bsh: StreamHook; ra: RosterAction; rh: RsHook;
	BEGIN
		IF ~s.Authorized() & (pr = NIL) THEN
			s.StartStream;
			pr := s.LoadExtension('XmppPresence', res)(XmppPresence.Presence);
			ASSERT(res = XmppCore.loaded);
			rs := s.LoadExtension('XmppRoster', res)(XmppRoster.Roster);
			ASSERT(res = XmppCore.loaded);
			msg := s.LoadExtension('XmppMessenger', res)(XmppMessenger.Messenger);
			ASSERT(res = XmppCore.loaded);
			ibb := s.LoadExtension('XmppIbb', res)(XmppIbb.Ibb);
			ASSERT(res = XmppCore.loaded);
			ds := s.LoadExtension('XmppDisco', res)(XmppDisco.Disco);
			ASSERT(res = XmppCore.loaded);
			bs := s.LoadExtension('XmppByteStreams', res)(XmppByteStreams.ByteStreams);
			ASSERT(res = XmppCore.loaded);
			Services.DoLater(a, Services.Ticks() + Services.resolution);
			NEW(ph); pr.SetHook(ph);
			NEW(rh); rs.SetHook(rh);
			NEW(mh); msg.SetHook(mh);
			NEW(ibh); ibb.SetHook(ibh);
			NEW(bsh); bs.SetHook(bsh);
		ELSIF s.Authorized() & pr.valid THEN
			pr.Initial;
			NEW(ra);
			rs.Request(ra);
			NEW(rh); rs.SetHook(rh);
			NEW(ph); pr.SetHook(ph);
			NEW(mh); msg.SetHook(mh);
			NEW(ibh); ibb.SetHook(ibh);
		ELSIF s.Authorized() THEN
			Services.DoLater(a, Services.now);
		END;
	END Do;

	PROCEDURE Disconnect*;
	BEGIN
		IF s.Authorized() THEN pr.Unavailable; END;
		s.CloseStream;
	END Disconnect;

	PROCEDURE DisconnectGuard* (VAR par: Dialog.Par);
	BEGIN
		par.disabled := (s = NIL);
	END DisconnectGuard;

	PROCEDURE Connect*;
		VAR a: Action;
	BEGIN
		IF s # NIL THEN Disconnect; END;
		s := XmppCore.dir.NewSession(remoteAdr, user, password, XmppCore.normalOpts);
		pr := NIL; rs := NIL;
		NEW(a); Services.DoLater(a, Services.Ticks() + Services.resolution DIV 3);
		XmppConsole.Open(s);
	END Connect;

	PROCEDURE ConnectGuard* (VAR par: Dialog.Par);
	BEGIN
		par.disabled := (password$ = '') OR (user$ = '') OR (remoteAdr$ = '');
	END ConnectGuard;

	PROCEDURE Console*;
	BEGIN
		XmppConsole.Open(s);
	END Console;

	PROCEDURE ConsoleGuard* (VAR par: Dialog.Par);
	BEGIN
		par.disabled := (s = NIL);
	END ConsoleGuard;

	PROCEDURE Start*;
	BEGIN
		StdCmds.OpenAuxDialog('Xmpp/Rsrc/Extended', 'Extended XMPP session');
	END Start;

	PROCEDURE Init*;
	BEGIN
		user := 'bb@peter/blackbox';
		password := '00018152';
		remoteAdr := '127.0.0.1:5222';
		to := 'psi@peter/blackbox'
	END Init;

	PROCEDURE Close*;
	BEGIN
		IF s # NIL THEN Disconnect; END;
	END Close;

	PROCEDURE Do0*;
		VAR ra: RosterAction;
	BEGIN
		NEW(ra);
		pr.Initial;
		rs.Request(ra);
	END Do0;

	PROCEDURE Do1*;
		VAR ra: RosterAction;
	BEGIN
		NEW(ra);
		rs.Add('test3@peter', 'test3noname', '????', ra);
	END Do1;

	PROCEDURE Do2*;
	BEGIN
		pr.Subscribe('test3@peter', XmppPresence.SUBSCRIBE);
	END Do2;

	PROCEDURE Do3*;
	BEGIN
		pr.Approve('test3@peter', XmppPresence.SUBSCRIBED);
	END Do3;

	PROCEDURE Do4*;
	BEGIN
		msg.Send(user, to, XmppMessenger.CHAT, '', 'Hello, World!', '');
	END Do4;

	PROCEDURE Do5*;
		VAR f: Files.File; rd: Files.Reader; sid: ARRAY 20 OF CHAR;
	BEGIN
		f := Files.dir.Old(Files.dir.This('Xmpp/Rsrc/'), 'old.zip', Files.shared);
		rd := f.NewReader(NIL); rd.SetPos(0);
		ibb.Send(user, 'psi@peter/blackbox', rd, f.Length(), XmppIbb.defaultBlockSize, XmppIbb.withVerify, sid);
	END Do5;

	PROCEDURE Do6*;
		VAR rh: RegHook;
	BEGIN
		NEW(rh);
		XmppRegister.Register(remoteAdr, user, 'peter', password, rh);
		XmppConsole.Open(XmppRegister.reg.s);
	END Do6;

	PROCEDURE Do7*;
		VAR a: DiscoAction;
	BEGIN
		NEW(a);
		ASSERT(to # '');
		ds.Query(user, to, XmppDisco.info, '', a);
	END Do7;

	PROCEDURE Send*;
		VAR loc: Files.Locator; filename: Files.Name; file: Files.File; res: INTEGER;
	BEGIN
		loc := Files.dir.This(''); filename := '';
		Dialog.GetIntSpec('*', loc, filename);
		IF (loc # NIL) THEN
			file := Files.dir.Old(loc, filename, Files.dontAsk);
			ASSERT(file # NIL);
			bytestream.Write(file, 0, file.Length(), res);
		ELSE
			Log.String("client: no file"); Log.Ln
		END
	END Send;

	PROCEDURE Do8*;
	BEGIN
		NEW(bytestream);
		ASSERT(to # '');
		bytestream.AddHost(user, '127.0.0.1', '8888');
		bs.NewStream(user, to, bytestream, XmppByteStreams.tcpMode);
	END Do8;


BEGIN
	Init;
CLOSE
	Close;
END XmppExtended.




