MODULE XmppMessenger;
(**	project	= "XMPP"
	organization	= ""
	contributors	= ""
 	purpose	= "???????? ?????????? RFC 3921"
	changes	= "
	- , nn, ...
	"
	issues	= "
	-20111110, pk, ????????? ????????? urn:xmpp:receipts 
	-20111113, pk, ??????? ???????????? ???????? ????????
	"
**)

	IMPORT Core := XmppCore, Items:=XmlcoreItems, Const:=XmppConst, Log, Stuff:=XmppStuff,  DS:=StringsDyn, Strings, Rand:=ypkMathRandom, Dates, DT:=XmppDateTime, Services, Map:=ListsMap;
	
	CONST
		SUBJECT* = 'subject';
		BODY* = 'body';
		THREAD* = 'thread';
		
		delay = 'delay';
		delayUrn = 'urn:xmpp:delay'; 
		stamp = 'stamp';
		
		CHAT* = 'chat';
		GROUPCHAT* = 'groupchat';
		HEADLINE* = 'headline';
		NORMAL* = 'normal';
		
		request = 'request';
		received = 'received';
		receiptsUrn = 'urn:xmpp:receipts';
			
	TYPE
		DynString = DS.DynString;
		
		Directory* = POINTER TO RECORD(Core.ExtensionDir) 
			cl: Map.StrMap;
		END;
		
		Messenger* = POINTER TO LIMITED RECORD (Core.Extension)
			valid- : BOOLEAN;
			hook : Hook;
		END;	
		
		Hook* = POINTER TO ABSTRACT RECORD END;
		
		Message = POINTER TO RECORD(Core.Message)
			subject, body, thread : POINTER TO ARRAY OF CHAR;
			d: Delay;
			confirm: RECORD
				valid: BOOLEAN;
				id: POINTER TO ARRAY OF CHAR;
			END;
		END;
		
		Delay* = RECORD
			d-: DT.Date;
			t-: DT.Time;
			ts-: ARRAY 127 OF CHAR;
		END;
		
		ConfirmAction = POINTER TO RECORD (Services.Action)
			to: ARRAY 512 OF CHAR; 
			id: ARRAY 127 OF CHAR;
			owner: Messenger;
		END;
		
		ReceiptsAction* = POINTER TO ABSTRACT RECORD (Services.Action) 
			done: INTEGER;
			id: ARRAY 127 OF CHAR;
			owner: Messenger;
			to: ARRAY 512 OF CHAR; 
		END;
		
	VAR
		dir- : Directory;
		timeOut*: INTEGER;
		
	PROCEDURE ^ (d: Directory) Confirmed(m: Messenger; IN from, id: ARRAY OF CHAR), NEW;
	PROCEDURE ^ (d: Directory) TimeOut(a: ReceiptsAction), NEW;
	PROCEDURE (a: ReceiptsAction) Confirmed- (owner: Messenger; IN from, id: ARRAY OF CHAR), NEW, ABSTRACT;
	PROCEDURE (a: ReceiptsAction) TimeOut- (owner: Messenger; IN to, id: ARRAY OF CHAR), NEW, ABSTRACT;
	PROCEDURE (h : Hook) Notify- (messenger : Messenger; to, from, type, subject, body, thread : ARRAY OF CHAR; delay: Delay), NEW, ABSTRACT;
	
	PROCEDURE (a: ReceiptsAction) Do-;
	BEGIN
		IF dir#NIL THEN dir.TimeOut(a) END;
	END Do;
	
	PROCEDURE (a: ConfirmAction) Do;
		VAR m: Message;
	BEGIN
		NEW(m);
		m.Set(a.to$, '', '', a.id$, '');
		m.confirm.id:=DS.Create(a.id$).String();
		m.subject:=DS.Create('').String(); 
		m.body:=DS.Create('').String(); 
		m.thread:=DS.Create('').String();
		a.owner.owner.Send(m);
	END Do;
	
	PROCEDURE ConfirmLater(owner: Messenger; IN to, id: ARRAY OF CHAR);
		VAR a: ConfirmAction;
	BEGIN
		NEW(a); a.id:=id$; a.to:=to$; a.owner:=owner;
		Services.DoLater(a, Services.now);
	END ConfirmLater;	
	
	PROCEDURE Notify(m : Messenger; msg : Message);
	BEGIN
		IF m.hook#NIL THEN
			IF msg.body$#'' THEN 
				m.hook.Notify(m, msg.to, msg.from, msg.type, msg.subject, msg.body, msg.thread, msg.d); 
				IF msg.confirm.id#NIL THEN
					ConfirmLater(m, msg.from$, msg.confirm.id$);
				END;
			ELSIF msg.confirm.id#NIL THEN
				dir.Confirmed(m, msg.from$, msg.confirm.id$)
			END;
		END;
	END Notify;
	
	PROCEDURE (m : Message) Do() : Items.Item;
	VAR n, n1 : Items.Item;
	BEGIN
		n:=Items.New(Const.message);
		IF m.subject$#'' THEN
			n1:=Items.New(SUBJECT);
			n1.SetData(m.subject$);
			n.Add(n1);
		END;
		IF m.body$#'' THEN
			n1:=Items.New(BODY);
			n1.SetData(m.body$);
			n.Add(n1);
		END;	
		IF m.thread$#'' THEN
			n1:=Items.New(THREAD);
			n1.SetData(m.thread$);
			n.Add(n1);
		END;
		IF m.confirm.id#NIL THEN
			n1:=Items.New(received);
			n1.SetParam(Const.xmlns, receiptsUrn);
			n1.SetParam(Const.id, m.confirm.id$);
			n.Add(n1);
		ELSIF m.confirm.valid THEN
			n1:=Items.New(request);
			n1.SetParam(Const.xmlns, receiptsUrn);
			n.Add(n1);
		END;
		RETURN n;		
	END Do;
	
	PROCEDURE (m : Message) Use(data : Items.Item);
	VAR n : Items.Item;
	BEGIN
		NEW(m.subject, 1); NEW(m.body, 1); NEW(m.thread, 1); m.d.ts:='';
		n:=data.First();
		WHILE n#NIL DO
			IF n.GetName()$=SUBJECT THEN
				m.subject:=DS.Create(n.GetData()$).String()
			ELSIF n.GetName()$=BODY THEN
				m.body:=DS.Create(n.GetData()$).String()
			ELSIF n.GetName()$=THREAD THEN
				m.thread:=DS.Create(n.GetData()$).String()
			ELSIF (n.GetName()$=delay) & (n.GetParam(Const.xmlns)$=delayUrn) THEN 
				m.d.ts:=n.GetParam(stamp)$;
			ELSIF (n.GetName()$ = request) & (data.GetParam(Const.id)$#'') & (n.GetParam(Const.xmlns)$=receiptsUrn) THEN
				m.confirm.id:=data.GetParam(Const.id);
			ELSIF (n.GetName()$ = received) THEN
				IF n.GetParam(Const.id)$#'' THEN m.confirm.id:=n.GetParam(Const.id);
				ELSE m.confirm.id:=data.GetParam(Const.id) END;
			ELSE END;
			n:=data.Next(n);
		END;
		IF m.d.ts#'' THEN
			DT.StringToDateTime(m.d.ts, m.d.d, m.d.t);
		ELSE
			DT.GetDate(m.d.d, TRUE);
			DT.GetTime(m.d.t);
		END;
	END Use;
	
	PROCEDURE (m : Messenger) Message-(data : Items.Item; VAR res : INTEGER);
	VAR n : Items.Item; msg : Message;
	BEGIN
		NEW(msg); msg.Init(data);
		Notify(m, msg);
		res:=Core.continue;
	END Message;
	
	PROCEDURE (m : Messenger) Send*(from, to, type, subject, body, thread : ARRAY OF CHAR), NEW;
	VAR msg : Message; str : ARRAY 10 OF CHAR;
	BEGIN
		ASSERT(to$#'');
		ASSERT(from#'');
		ASSERT(body#'');
		NEW(msg); msg.confirm.valid:=FALSE;
		Rand.UniRandStr(str, 6);
		msg.Set(to, from, '', str$, type); 
		msg.subject:=DS.Create(subject$).String(); 
		msg.body:=DS.Create(body$).String(); 
		msg.thread:=DS.Create(thread$).String();
		m.owner.Send(msg);
	END Send;
	
	PROCEDURE (d: Directory) SendWithReceipts*(m: Messenger; IN from, to, type, subject, body, thread : ARRAY OF CHAR; a: ReceiptsAction; OUT id: ARRAY OF CHAR), NEW;
		VAR msg : Message;
	BEGIN
		ASSERT(to$#'');
		ASSERT(from#'');
		ASSERT(body#'');
		NEW(msg); msg.confirm.valid:=TRUE;
		Rand.UniRandStr(id, 6); id:='msg-'+id$;
		msg.Set(to, from, '', id$, type); 
		msg.subject:=DS.Create(subject$).String(); 
		msg.body:=DS.Create(body$).String(); 
		msg.thread:=DS.Create(thread$).String();
		IF a#NIL THEN 
			d.cl.Add(id$, a); a.done:=0; a.owner:=m; a.id:=id$; a.to:=to$;
			Services.DoLater(a, Services.Ticks() + timeOut); 
		END;
		m.owner.Send(msg);
	END SendWithReceipts;
	
	PROCEDURE (d: Directory) Confirmed(m: Messenger; IN from, id: ARRAY OF CHAR), NEW;
		VAR x: ANYPTR;
	BEGIN
		x:=d.cl.Item(id$);
		IF x#NIL THEN
			WITH x: ReceiptsAction DO
				x.Confirmed(m, from$, id$);
				INC(x.done);
			END;
		END;
	END Confirmed;
	
	PROCEDURE (d: Directory) TimeOut(a: ReceiptsAction), NEW;
	BEGIN
		IF (a#NIL) & (a.done = 0) THEN
			a.TimeOut(a.owner, a.to$, a.id$);
			d.cl.RemoveThis(a)
		END;
	END TimeOut;
	
	PROCEDURE (m : Messenger) Start-;
	BEGIN
		m.valid:=TRUE;
	END Start;	
	
	PROCEDURE (m : Messenger) Stop-;
	BEGIN
		m.valid:=FALSE;
	END Stop;
	
	PROCEDURE (m : Messenger) SetHook*(h : Hook), NEW;
	BEGIN
		m.hook:=h;
	END SetHook;
	
	PROCEDURE (d : Directory) Create-(session : Core.Session) : Core.Extension;
	VAR m : Messenger;
	BEGIN
		NEW(m);
		m.valid:=FALSE;
		RETURN m;
	END Create;

	PROCEDURE Init;
	VAR d : Directory;
	BEGIN
		NEW(d); d.cl:=Map.NewStrMap();
		dir:=d;
		timeOut:=30000;
	END Init;

BEGIN
	Init
END XmppMessenger.