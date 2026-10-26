MODULE XmppStreamInit;
(**	project	= "XMPP"
	organization	= ""
	contributors	= ""
 	purpose	= "???????? ?????????? RFC 0095, 0096"
	changes	= "
	- , nn, ...
	"
	issues	= ""
**)

	IMPORT Core := XmppCore, Items:=XmlcoreItems, Const:=XmppConst, XmppDateTime, Log, Stuff:=XmppStuff,  DS:=StringsDyn, Strings, Rand:=ypkMathRandom, Map:=ListsMap;
	
	CONST 
		urn* = 'http://jabber.org/protocol/si';
		fileurn* = 'http://jabber.org/protocol/si/profile/file-transfer';
		featureurn* = 'http://jabber.org/protocol/feature-neg';
		xdataurn* = 'jabber:x:data';
		bytestreamsurn* = 'http://jabber.org/protocol/bytestreams';
		ibburn* = 'http://jabber.org/protocol/ibb';
		
		file = 'file';
		name = 'name';
		hash = 'hash';
		date = 'date';
		size = 'size';
		descr = 'descr';
		range = 'range';
		offset = 'offset';
		length = 'length';
		feature = 'feature';
		field = 'field';
		var = 'var';
		option = 'option';
		value = 'value';
		si = 'si';
		mimetype = 'mime-type';
		text = 'text/plain';
		profile = 'profile';
		list = 'list-single';
		form = 'form';
		method = 'stream-method';
		xdata = 'x';
		submit = 'submit';
		
		ibb* = 0;
		bs* = 1;
		
		
	TYPE
		DynString = DS.DynString;
		
		StreamInit* = POINTER TO LIMITED RECORD (Core.Extension)
			valid- : BOOLEAN;
			queue: Map.StrMap;
			hook: Hook;
		END;	
		
		Hook* = POINTER TO ABSTRACT RECORD END;
		
		Directory* = POINTER TO RECORD(Core.ExtensionDir) 
	
		END;
		
		Action* = POINTER TO ABSTRACT RECORD 
			sid-, id: ARRAY 127 OF CHAR;
			name-, descr-, hash-, date-: ARRAY 256 OF CHAR; 
			range-: BOOLEAN; 
			offset-, length-: INTEGER; 
			methods-: SET
		END;
		
		OfferIq = POINTER TO RECORD(Core.Iq)
			sid, name, descr, date, hash: ARRAY 256 OF CHAR;
			range: BOOLEAN; offset, length: INTEGER;
			method: SET;
		END;
		
		AcceptIq = POINTER TO RECORD(Core.Iq)
			method: INTEGER;
		END;
		
	VAR
		dir- : Directory;
	
	PROCEDURE (h: Hook) Offered-(si: StreamInit; from: ARRAY OF CHAR; VAR a: Action), NEW, ABSTRACT;
	PROCEDURE (h: Hook) Accepted-(si: StreamInit; from: ARRAY OF CHAR; a: Action; method: INTEGER), NEW, ABSTRACT;
	PROCEDURE (h: Hook) Ready-(si: StreamInit; from: ARRAY OF CHAR; a: Action), NEW, ABSTRACT;
	
	PROCEDURE (oi : OfferIq) Do() : Items.Item;
	VAR i, n, n1, n2, n3, n4, n5 : Items.Item;
	BEGIN
		i:=Items.New(Const.iq);
		n:=Items.New(si);
		n.SetParam(Const.xmlns, urn);  n.SetParam(Const.id, oi.sid$); n.SetParam(mimetype, text); n.SetParam(profile, fileurn);
		n1:=Items.New(file);
		n1.SetParam(Const.xmlns, fileurn); n1.SetParam(name, oi.name$); n1.SetParam(hash, oi.hash$); 
		IF oi.date#'' THEN n1.SetParam(date, oi.date) END;
		IF oi.descr#'' THEN n2:=Items.New(descr); n2.SetData(oi.descr$); n1.Add(n2) END;
		IF oi.range THEN n2:=Items.New(range); n2.SetIntParam(offset, oi.offset); n2.SetIntParam(length, oi.length); n1.Add(n2) ELSE n1.SetIntParam(size, oi.length) END;
		n.Add(n1);
		n1:=Items.New(feature); n1.SetParam(Const.xmlns, featureurn); 
		n2:=Items.New(xdata); n2.SetParam(Const.xmlns, xdataurn); n2.SetParam(Const.type, form); n1.Add(n2);
		n3:=Items.New(field); n3.SetParam(var, method); n3.SetParam(Const.type, list); n2.Add(n3);
		IF bs IN oi.method THEN n4:=Items.New(option); n5:=Items.New(value); n5.SetData(bytestreamsurn); n4.Add(n5); n3.Add(n4) END;
		IF ibb IN oi.method THEN n4:=Items.New(option); n5:=Items.New(value); n5.SetData(ibburn); n4.Add(n5); n3.Add(n4); END;
		n.Add(n1);
		i.Add(n);
		RETURN i;		
	END Do;
	
	PROCEDURE (oi : OfferIq) Use(item : Items.Item);
	VAR n, n1, n2, n3, n4 : Items.Item; ok: BOOLEAN; res: INTEGER;
	BEGIN
		oi.Set(item.GetParam(Const.to)$, item.GetParam(Const.from)$, item.GetParam(Const.xml_lang)$, item.GetParam(Const.id)$, item.GetParam(Const.type)$);
		item.Find(si, n, res); oi.sid:=n.GetParam(Const.id)$;
		IF res=0 THEN
			n.Find(file, n1, res);
			IF res=0 THEN
				oi.name:=n1.GetParam(name)$;
				oi.hash:=n1.GetParam(hash)$;
				oi.date:=n1.GetParam(date)$;
				ok:=n1.GetIntParam(size, oi.length);
				n1.Find(descr, n2, res);
				IF res=0 THEN oi.descr:=n2.GetData()$ END;
				n1.Find(range, n2, res);
				IF res=0 THEN 
					oi.range:=TRUE;
					ok:=n2.GetIntParam(offset, oi.offset);
					ok:=n2.GetIntParam(length, oi.length);
				END;
			END;
			n.Find(feature, n1, res);
			IF res=0 THEN
				n1.Find(xdata, n2, res);
				IF res=0 THEN
					n2.Find(field, n2, res);
					IF res=0 THEN
						n3:=n2.First();
						WHILE n3#NIL DO
							n4:=n3.First();
							IF n4#NIL THEN
								IF n4.GetData()$ = ibburn THEN INCL(oi.method, ibb)
								ELSIF n4.GetData()$ = bytestreamsurn THEN INCL(oi.method, bs) END
							END;
							n3:=n2.Next(n3);
						END;
					END;
				END;
			END;
		END;
	END Use;
	
	PROCEDURE (ai : AcceptIq) Do() : Items.Item;
	VAR i, n, n1, n2, n3, n4, n5 : Items.Item; id: ARRAY 127 OF CHAR;
	BEGIN
		i:=Items.New(Const.iq);
		n:=Items.New(si);  n.SetParam(Const.xmlns, urn);
		n1:=Items.New(feature); n1.SetParam(Const.xmlns, featureurn); 
		n2:=Items.New(xdata); n2.SetParam(Const.xmlns, xdataurn); n2.SetParam(Const.type, submit); n1.Add(n2);
		n3:=Items.New(field); n3.SetParam(var, method); n2.Add(n3);
		n4:=Items.New(value); 
		CASE ai.method OF
			|bs: n4.SetData(bytestreamsurn); 
			|ibb: n4.SetData(ibburn); 
		ELSE END;
		n3.Add(n4); n.Add(n1);
		i.Add(n);
		RETURN i;		
	END Do;
	
	PROCEDURE (ai : AcceptIq) Use(item : Items.Item);
	VAR n, n1, n2, n3, n4 : Items.Item; ok: BOOLEAN; res: INTEGER;
	BEGIN
		ai.Set(item.GetParam(Const.to)$, item.GetParam(Const.from)$, item.GetParam(Const.xml_lang)$, item.GetParam(Const.id)$, item.GetParam(Const.type)$);
		item.Find(si, n, res);
		IF res=0 THEN
			n.Find(feature, n1, res);
			IF res=0 THEN
				n1.Find(xdata, n2, res);
				IF res=0 THEN
					n2.Find(field, n2, res);
					IF res=0 THEN
						n3:=n2.First();
						WHILE n3#NIL DO
							n4:=n3.First();
							IF n4#NIL THEN
								IF n4.GetData()$ = ibburn THEN ai.method:=ibb;
								ELSIF n4.GetData()$ = bytestreamsurn THEN ai.method:=bs END
							END;
							n3:=n2.Next(n3);
						END;
					END;
				END;
			END; 
		END;
	END Use;
	
	PROCEDURE HandleOffer(s: StreamInit; id: ARRAY OF CHAR; oi: OfferIq);
	VAR a: Action; 
	BEGIN
		ASSERT(s.hook#NIL, 20);
		s.hook.Offered(s, oi.from, a);
		IF a#NIL THEN 
			s.queue.Add(id, a);
			a.name:=oi.name$; a.descr:=oi.descr$; a.hash:=oi.hash$; a.date:=oi.date$;
			a.range:=oi.range; a.offset:=oi.offset; a.length:=oi.length; 
			a.methods:=oi.method;
			a.id:=oi.id$; a.sid:=oi.sid$;
			s.hook.Ready(s, oi.from, a);
		ELSE
			(* ???????? ?????? ???????? ??????... ??? ?????????? ???????? *)
		END; 
	END HandleOffer;
	
	PROCEDURE HandleAccept(s: StreamInit; id: ARRAY OF CHAR; ai: AcceptIq);
	VAR a: ANYPTR;
	BEGIN
		ASSERT(s.hook#NIL, 20);
		a:=s.queue.Item(id);
		IF a#NIL THEN
			WITH a: Action DO
				s.hook.Accepted(s, ai.from, a, ai.method);
				s.queue.Remove(id); 
			ELSE END;
		END;
	END HandleAccept;	
	
	PROCEDURE (s : StreamInit) Iq-(data : Items.Item; VAR res : INTEGER);
	VAR n: Items.Item; oi: OfferIq; ai: AcceptIq;
	BEGIN
		n:=data.First();
		IF n#NIL THEN
			IF (n.GetParam(Const.xmlns)$=urn) THEN
				IF (data.GetParam(Const.type)$=Const.set) THEN
					NEW(oi); oi.Init(data); HandleOffer(s, data.GetParam(Const.id)$, oi);
				ELSIF (data.GetParam(Const.type)$=Const.result) THEN
					NEW(ai); ai.Init(data); HandleAccept(s, data.GetParam(Const.id)$, ai);
				END;
			END;
		END;
		res:=Core.continue;
	END Iq;
	
	PROCEDURE (s : StreamInit) Start-;
	BEGIN
		s.valid:=TRUE;
	END Start;
	
	PROCEDURE (s : StreamInit) Stop-;
	BEGIN
		s.valid:=FALSE;
	END Stop;
	
	PROCEDURE (s : StreamInit) SetHook*(hook : Hook), NEW;
	BEGIN
		s.hook:=hook;
	END SetHook;
			
	PROCEDURE (d : Directory) Create-(session : Core.Session) : Core.Extension;
	VAR s : StreamInit;
	BEGIN
		NEW(s);
		s.valid:=FALSE;
		s.queue:=Map.NewStrMap();
		RETURN s;
	END Create;
	
	PROCEDURE OfferStream*(si: StreamInit; to, from, name, descr, date: ARRAY OF CHAR; range: BOOLEAN; offset, length: INTEGER; hash: ARRAY OF CHAR; method: SET; a: Action);
		VAR oi: OfferIq;
	BEGIN
		ASSERT(a#NIL, 20);
		NEW(oi);
		Rand.UniRandStr(a.id, 5); a.id:='offer-'+a.id$;
		oi.Set(to, from, '', a.id, Const.set);
		oi.name:=name$; oi.descr:=descr$; oi.range:=range;
		IF range THEN oi.offset:=offset END; oi.length:=length;
		oi.hash:=hash$; oi.date:=date$; oi.method:=method;
		
		si.queue.Add(oi.id, a);
		a.name:=oi.name$; a.descr:=oi.descr$; a.hash:=oi.hash$; a.date:=oi.date$;
		a.range:=oi.range; a.offset:=oi.offset; a.length:=oi.length; 
		a.methods:=oi.method;
		Rand.UniRandStr(a.sid, 5); a.sid:='stream-'+a.sid$; oi.sid:=a.sid$;
		
		si.owner.Send(oi);
	END OfferStream;
	
	PROCEDURE AcceptStream*(si: StreamInit; to, from: ARRAY OF CHAR; a: Action; method: INTEGER);
		VAR ai: AcceptIq;
	BEGIN
		ASSERT(a#NIL, 20);
		ASSERT(method IN a.methods, 21);
		NEW(ai);
		ai.Set(to, from, '', a.id, Const.result);
		ai.method:=method;
		si.owner.Send(ai);
		si.queue.Remove(a.id);
	END AcceptStream;
	
	PROCEDURE Init;
	VAR d : Directory;
	BEGIN
		NEW(d);
		dir:=d;
	END Init;

BEGIN
	Init	
END XmppStreamInit.

(*  *)