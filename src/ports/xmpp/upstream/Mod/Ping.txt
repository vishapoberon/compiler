MODULE XmppPing;
(**	project	= "Xmpp"
	organization	= ""
	contributors	= ""
 	purpose	= "???????? ?????????? XEP Ping"
	changes	= "
	- , nn, ...
	"
	issues	= ""
**)

	IMPORT Bus:=AbfBus, Core := XmppCore, It:=XmlcoreItems, Const:=XmppConst, Log, Stuff:=XmppStuff,  DS:=StringsDyn, Strings, Str:=XmppStrings, Map:=ListsMap, Iterable:=ListsIterable;
	
	CONST 
		ping* = 'ping';
		pingUrn = 'urn:xmpp:ping';
			
	TYPE
		DynString = DS.DynString;
		
		Pinger* = POINTER TO LIMITED RECORD (Core.Extension)
			valid- : BOOLEAN;
			map: Map.StrMap;
		END;	
			
		Directory* = POINTER TO RECORD(Core.ExtensionDir) END;
		
		PingRequestMsg* = RECORD (Bus.Message)
			p*: Pinger;
			data*: ANYPTR;
			to*, from*: ARRAY 512 OF CHAR;
		END;
		
		PingAnswerMsg* = RECORD (Bus.Message)
			p-: Pinger;
			data-: ANYPTR;
			to-, from-: ARRAY 512 OF CHAR;
		END;
		
		PingErrorMsg* = RECORD (Bus.Message)
			p-: Pinger;
			data-: ANYPTR;
			to-, from-: ARRAY 512 OF CHAR;
		END;
		
		Action = POINTER TO RECORD 
			id: ARRAY 127 OF CHAR;
			data: ANYPTR;
		END;
		
		PingIq = POINTER TO RECORD(Core.Iq) END;
			
	VAR
		dir- : Directory;
	
	PROCEDURE (piq : PingIq) Do() : It.Item;
	VAR n, n1, n2, n3 : It.Item; 
	BEGIN
		n:=It.New(Const.iq); 
		n1:=It.New(ping);
		n1.SetParam(Const.xmlns, pingUrn);
		n.Add(n1);
		RETURN n;		
	END Do;
	
	PROCEDURE Pong(p: Pinger; piq: PingIq);
	BEGIN
		piq.Set(piq.from, piq.to, '', piq.id, Const.result);
		p.owner.Send(piq);
	END Pong;
	
	PROCEDURE Error(p: Pinger; IN from, id: ARRAY OF CHAR);
		VAR em: PingErrorMsg; res: INTEGER;
	BEGIN
		IF p.map.Item(id)#NIL THEN
			em.p:=p; em.from:=from$; em.data:=p.map.Item(id)(Action).data;
			Bus.Broadcast(em, res);
			p.map.Remove(id);
		END;
	END Error;	
	
	PROCEDURE Ping(p: Pinger; IN from, to, id: ARRAY OF CHAR);
		VAR pm: PingAnswerMsg; res: INTEGER;
	BEGIN
		IF p.map.Item(id)#NIL THEN
			pm.p:=p; pm.from:=from$; pm.to:=to$; pm.data:=p.map.Item(id)(Action).data;
			Bus.Broadcast(pm, res);
			p.map.Remove(id);
		END;
	END Ping;
	
	PROCEDURE DoPing(p: Pinger; IN from, to: ARRAY OF CHAR; data: ANYPTR);
	VAR piq: PingIq; a: Action;
	BEGIN
		ASSERT(to#'', 22);		
		NEW(piq); NEW(a); a.data:=data;
		Str.NewId('ping', a.id);
		piq.Set(to, from, '', a.id, Const.get);
		p.owner.Send(piq);
		p.map.Add(a.id, a);
	END DoPing;
	
	PROCEDURE (p: Pinger) Iq-(data : It.Item; VAR res : INTEGER);
		VAR n: It.Item; piq: PingIq; error: BOOLEAN; a: ANYPTR;
	BEGIN
		n:=data.First();
		error:=(n#NIL) & (data.Next(n)#NIL) & ((data.Next(n).GetName()$=Const.error) OR (data.GetParam(Const.type)$=Const.error));
		IF (n#NIL) & ~error THEN
			IF (n.GetParam(Const.xmlns)$=pingUrn) & (data.GetParam(Const.type)$=Const.get) THEN
				NEW(piq); piq.Init(data); Pong(p, piq);
			ELSIF (n.GetParam(Const.xmlns)$=pingUrn) & (data.GetParam(Const.type)$=Const.result) THEN
				Ping(p, data.GetParam(Const.from), data.GetParam(Const.to), data.GetParam(Const.id));
			END;
		ELSIF (n=NIL) THEN
			IF p.map.Item(data.GetParam(Const.id))#NIL THEN
				Ping(p, data.GetParam(Const.from), data.GetParam(Const.to), data.GetParam(Const.id));
			END;
		ELSIF (n#NIL) & error THEN
			IF (n.GetParam(Const.xmlns)$=pingUrn) THEN
				Error(p, data.GetParam(Const.from)$, data.GetParam(Const.id)$);
			END;
		END;
		res:=Core.continue;
	END Iq;

	PROCEDURE (p: Pinger) Start-;
	BEGIN
		p.valid:=TRUE;
	END Start;
	
	PROCEDURE (p: Pinger) Stop-;
	BEGIN
		p.valid:=FALSE;
	END Stop;
				
	PROCEDURE (d : Directory) Create-(session : Core.Session) : Core.Extension;
	VAR p: Pinger;
	BEGIN
		NEW(p);
		p.valid:=FALSE;
		p.map:=Map.NewStrMap();
		RETURN p;
	END Create;
	
	PROCEDURE HandleBusMsg* (VAR msg: Bus.Message);
	VAR name: ARRAY 127 OF CHAR; res: INTEGER; a: Action;
	BEGIN	
		WITH 
			|msg: PingRequestMsg DO 
				IF msg.p#NIL THEN DoPing(msg.p, msg.from, msg.to, msg.data) END;
		ELSE END;
	END HandleBusMsg;
	
	PROCEDURE Init;
	VAR d : Directory;
	BEGIN
		NEW(d);
		dir:=d;
	END Init;

BEGIN
	Init	
END XmppPing.

(*  *)