MODULE XmppBus;
(**	project	= "Xmpp"
	organization	= ""
	contributors	= ""
 	purpose	= ""
	changes	= "
	- , nn, ...
	"
	issues	= ""
	selectors	= ????
**)

	IMPORT SYSTEM, Kernel, Meta, Core := XmppCore, Items:=XmlcoreItems, Const:=XmppConst, Log, Stuff:=XmppStuff,  DS:=StringsDyn, Strings, AbfBus, Str:=XmppStrings, Map:=ListsMap, Dialog;
	
	CONST 
		query = 'bus';
		urn = 'bbcb:components:xmpp:bus';
		message* = 'msg';
		special* = 'specific';
		md5summ* = 'md5-summ';
		recTyp* = 'struct';
		fTyp* = 'field';
		arrTyp* = 'list';
		fprint* = 'type-fingerprint';
		ping* = 'ping';
		pingUrn = 'urn:xmpp:ping';
		ok = 'ok';
		error = 'error';
		len* = 'length';
		approve* = 1;
		normal* = 0;
		alien* = -1;
		stream* = -2;
		
	TYPE
		DynString = DS.DynString;
		
		MsgPtr* = POINTER TO Message;
		
		Message* = ABSTRACT RECORD (AbfBus.Message) END;
		
		Alien* = POINTER TO RECORD (Message)
			data* : Items.Item;
		END;
		
		Special* = POINTER TO LIMITED RECORD (Message)
			data* : Items.Item;
		END;
		(* Action* = POINTER TO ABSTRACT RECORD 
			id- : ARRAY 15 OF CHAR;
			
			END; *)
		
		(* Queue = POINTER TO RECORD
			list- : Stuff.List;
		END; *)
		
		Hook* = POINTER TO ABSTRACT RECORD END;
		
		Bus* = POINTER TO LIMITED RECORD (Core.Extension)
			valid- : BOOLEAN;
			hook : Hook;
			map: Map.StrMap;
			opts: SET;
		END;	
		
		Directory* = POINTER TO RECORD(Core.ExtensionDir) END;
		
		SendIq = POINTER TO RECORD(Core.Iq) 
			this : Items.Item;
		END;
		
		RecvIq = POINTER TO RECORD(Core.Iq) 
			msg : MsgPtr;
			res : INTEGER;
		END;
		
		PingIq = POINTER TO RECORD(Core.Iq) END;
		
		OkIq = POINTER TO RECORD(Core.Iq) END;
		
		ErrorIq = POINTER TO RECORD(Core.Iq) 
			code: INTEGER;
		END;
		
		Converter* = POINTER TO ABSTRACT RECORD END;
		(* #Iq = POINTER TO RECORD(Core.Iq)
		END;
		#Msg = POINTER TO RECORD(Core.Message)
		END;
		#Pr = POINTER TO RECORD(Core.Presence)
		END; *)
	
	VAR 
		dir- : Directory;
		conv- : Converter;
		
	PROCEDURE (VAR m : Message) Fill*(VAR data : Items.Item), NEW, EMPTY;
	
	PROCEDURE (h: Hook) Recv-(b : Bus; to, from : ARRAY OF CHAR; VAR msg : Message), NEW, ABSTRACT;
	PROCEDURE (h: Hook) Ok-(b: Bus; IN from, id: ARRAY OF CHAR), NEW, ABSTRACT;
	PROCEDURE (h: Hook) Error-(b: Bus; IN from, id: ARRAY OF CHAR; code: INTEGER), NEW, ABSTRACT;
	PROCEDURE (c : Converter) ItemToMsg*(item : Items.Item; VAR msg : MsgPtr; res : INTEGER), NEW, ABSTRACT;
	PROCEDURE (c : Converter) MsgToItem*(VAR msg : Message; OUT item : Items.Item), NEW, ABSTRACT;
	
	PROCEDURE (siq : SendIq) Do() : Items.Item;
	VAR n, n1, n2, n3 : Items.Item; 
	BEGIN
		n:=Items.New(Const.iq); 
		n1:=Items.New(query);
		n1.SetParam(Const.xmlns, urn);
		n1.Add(siq.this);
		n.Add(n1);
		RETURN n;		
	END Do;
	
	PROCEDURE (riq : RecvIq) Do() : Items.Item;
	BEGIN
		RETURN NIL
	END Do;
	
	PROCEDURE (riq : RecvIq) Use(item : Items.Item);
	VAR n, n1 : Items.Item; sp: Special;
	BEGIN
		n:=item.First();
		IF n#NIL THEN
			n1:=n.First();
			IF (n1#NIL) & (n1.GetName()$=message) & (n1.GetParam(Const.type)$#'') THEN 
				IF (n1.GetParam(Const.type)$#special) THEN conv.ItemToMsg(n1, riq.msg, riq.res)
				ELSE
					NEW(sp);
					sp.data:=item.First();
					riq.msg:=sp;
				END; 
			END;
		END;
	END Use;
	
	PROCEDURE (piq : PingIq) Do() : Items.Item;
	VAR n, n1, n2, n3 : Items.Item; 
	BEGIN
		n:=Items.New(Const.iq); 
		n1:=Items.New(ping);
		n1.SetParam(Const.xmlns, pingUrn);
		n.Add(n1);
		RETURN n;		
	END Do;
	
	PROCEDURE (oiq : OkIq) Do() : Items.Item;
	VAR n, n1, n2, n3 : Items.Item; 
	BEGIN
		n:=Items.New(Const.iq); 
		n1:=Items.New(ok);
		n1.SetParam(Const.xmlns, urn);
		n.Add(n1);
		RETURN n;		
	END Do;
	
	PROCEDURE (eiq : ErrorIq) Do() : Items.Item;
	VAR n, n1, n2, n3 : Items.Item; 
	BEGIN
		n:=Items.New(Const.iq); 
		n1:=Items.New(error); n1.SetIntParam('type', eiq.code);
		n1.SetParam(Const.xmlns, urn);
		n.Add(n1);
		RETURN n;		
	END Do;
	
	PROCEDURE Pong(b: Bus; piq: PingIq);
	BEGIN
		piq.Set(piq.from, piq.to, '', piq.id, Const.result);
		b.owner.Send(piq);
	END Pong;
	
	PROCEDURE Recv(b : Bus; riq : RecvIq);
		VAR oiq: OkIq; eiq: ErrorIq;
	BEGIN
		IF b.hook#NIL THEN
			IF riq.res = normal THEN
				NEW(oiq); oiq.Set(riq.from, riq.to, '', riq.id, Const.result);
				b.owner.Send(oiq);
			ELSIF riq.res = alien THEN
				NEW(eiq); eiq.Set(riq.from, riq.to, '', riq.id, Const.result); eiq.code := alien;
				b.owner.Send(eiq); 
			END;
			b.hook.Recv(b, riq.to, riq.from, riq.msg);
		END;
	END Recv;
	
	PROCEDURE ItemIq(b: Bus; IN from, to, id: ARRAY OF CHAR);
		VAR siq: SendIq;
	BEGIN
		ASSERT(id#'', 20);
		IF b.map.Item(id)#NIL THEN
			NEW(siq);
			siq.Set(from, to, '', id, Const.set);
			siq.this:=b.map.Item(id)(Items.Item);
			b.owner.Send(siq);
		END;
	END ItemIq;
	
	PROCEDURE Ok(b: Bus; IN from, id: ARRAY OF CHAR);
	BEGIN
		b.hook.Ok(b, from, id);
		b.map.Remove(id);
	END Ok;
	
	PROCEDURE RemoteError(b: Bus; IN from, id: ARRAY OF CHAR; code: INTEGER);
	BEGIN
		b.hook.Error(b, from, id, code);
		b.map.Remove(id);
	END RemoteError;
	
	PROCEDURE Error(b: Bus; IN from, id: ARRAY OF CHAR);
	BEGIN
		b.hook.Error(b, from, id, stream);
		b.map.Remove(id);
	END Error;	
	
	PROCEDURE (b : Bus)Send*(VAR msg : Message; from, to : ARRAY OF CHAR; OUT id: ARRAY OF CHAR), NEW;
	VAR piq: PingIq; it: Items.Item;
	BEGIN
		ASSERT(from#'', 21);
		ASSERT(to#'', 22);		
		NEW(piq);
		Str.NewId('bus', id);
		conv.MsgToItem(msg, it);
		b.map.Add(id, it);
		IF (approve IN b.opts) THEN
			piq.Set(to, from, '', id, Const.get);
			b.owner.Send(piq);
		ELSE
			ItemIq(b, to, from, id);
		END
	END Send;
	
	PROCEDURE (b : Bus) Iq-(data : Items.Item; VAR res : INTEGER);
	VAR n: Items.Item; val: INTEGER; riq : RecvIq; err : BOOLEAN; piq: PingIq;
	BEGIN
		n:=data.First();
		res:=Core.continue;
		err:=(n#NIL) & (data.Next(n)#NIL) & ((data.Next(n).GetName()$=Const.error) OR (data.GetParam(Const.type)$=Const.error));
		IF (n#NIL) & ~err THEN
			IF (n.GetName()$ = query) & (n.GetParam(Const.xmlns)$=urn) THEN
				NEW(riq); riq.Init(data); Recv(b, riq);
			ELSIF (n.GetName()$ = ok) & (n.GetParam(Const.xmlns)$=urn) THEN
				Ok(b, data.GetParam(Const.from)$, data.GetParam(Const.id)$)
			ELSIF (n.GetName()$ = error) & (n.GetParam(Const.xmlns)$=urn) THEN
				err:=n.GetIntParam('type', val);
				IF err THEN
					val:=alien;
				END;
				RemoteError(b, data.GetParam(Const.from)$, data.GetParam(Const.id)$, val);
			ELSIF (n.GetParam(Const.xmlns)$=pingUrn) & (data.GetParam(Const.type)$=Const.get) THEN
				NEW(piq); piq.Init(data); Pong(b, piq); res:=Core.finish;
			ELSIF (n.GetParam(Const.xmlns)$=pingUrn) & (data.GetParam(Const.type)$=Const.result) THEN
				ItemIq(b, data.GetParam(Const.from), data.GetParam(Const.to), data.GetParam(Const.id));
			END;
		ELSIF (n#NIL) & err THEN
			IF (n.GetName()$ = query) & (n.GetParam(Const.xmlns)$=urn) THEN
				Error(b, data.GetParam(Const.from)$, data.GetParam(Const.id)$);
				b.map.Remove(data.GetParam(Const.id)$);
			ELSIF (n.GetParam(Const.xmlns)$=pingUrn) THEN
				Error(b, data.GetParam(Const.from)$, data.GetParam(Const.id)$);
				b.map.Remove(data.GetParam(Const.id)$);
			END;
		END;
	END Iq;
	
	PROCEDURE (b : Bus) Message-(data : Items.Item; VAR res : INTEGER);
	VAR n: Items.Item; 
	BEGIN
		n:=data.First();
		IF n#NIL THEN
			
		END;
		res:=Core.continue;
	END Message;
	
	PROCEDURE (b : Bus) Presence-(data : Items.Item; VAR res : INTEGER);
	VAR n: Items.Item; 
	BEGIN
		n:=data.First();
		IF n#NIL THEN
			
		END;
		res:=Core.continue;
	END Presence;
	
	PROCEDURE (b : Bus) Start-;
	BEGIN
		b.valid:=TRUE;
	END Start;
	
	PROCEDURE (b : Bus) Stop-;
	BEGIN
		b.valid:=FALSE;
	END Stop;
	
	PROCEDURE (b : Bus) SetHook*(hook : Hook), NEW;
	BEGIN
		b.hook:=hook;
	END SetHook;
	
	PROCEDURE (b : Bus) SetOpts*(opts: SET), NEW;
	BEGIN
		b.opts:=opts;
	END SetOpts;
		
	PROCEDURE (d : Directory) Create-(session : Core.Session) : Core.Extension;
	VAR b : Bus;
	BEGIN
		NEW(b);
		b.valid:=FALSE;
		b.map:=Map.NewStrMap();
		b.opts:={approve};
		RETURN b;
	END Create;
	
	PROCEDURE SetConv*(c : Converter);
	BEGIN
		conv:=c;
	END SetConv;
	
	PROCEDURE Init;
	VAR d : Directory; res : INTEGER;
	BEGIN
		NEW(d);
		dir:=d;
		Dialog.Call('XmppStdBus.InstallConv', 'xmpp bus convertor load error', res);
	END Init;

BEGIN
	Init	
CLOSE

END XmppBus.