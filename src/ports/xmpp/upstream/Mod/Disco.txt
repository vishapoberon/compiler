MODULE XmppDisco;
(**	project	= "XMPP"
	organization	= ""
	contributors	= ""
 	purpose	= "???????? ?????????? XEP-0030: Service Discovery"
	changes	= ""
	issues	= "
	- ...
	"
**)

	IMPORT Core := XmppCore, Items:=XmlcoreItems, Const:=XmppConst, Log, Stuff:=XmppStuff,  DS:=StringsDyn, Strings, Rand:=ypkMathRandom;
	
	CONST 
		query = 'query';
		urn_disco_info = 'http://jabber.org/protocol/disco#info';
		urn_disco_items = 'http://jabber.org/protocol/disco#items';
		info* = 1;
		items* = 2;
		error*=-1;
		varAttr = 'var';
		categoryAttr = 'category';
		nameAttr = 'name';
		typeAttr = 'type';
		jidAttr = 'jid';
		identityElem = 'identity';
		featureElem = 'feature';
		itemElem = 'item';
		nodeAttr = 'node';
				
	TYPE
		DynString = DS.DynString;
		
		Action* = POINTER TO ABSTRACT RECORD 
			id- : ARRAY 15 OF CHAR;
			identities-, features-, items- : Stuff.List;
			type- : INTEGER;
		END;
		
		Hook* = POINTER TO ABSTRACT RECORD END;
		
		Queue = POINTER TO RECORD
			list- : Stuff.List;
		END;
		
		Disco* = POINTER TO LIMITED RECORD (Core.Extension)
			valid- : BOOLEAN;
			queue : Queue;
			hook : Hook;
		END;	
		
		Directory* = POINTER TO RECORD(Core.ExtensionDir) END;
		
		QueryIq = POINTER TO RECORD(Core.Iq)
			urn : ARRAY 127 OF CHAR;
			node : ARRAY 1024 OF CHAR;
			identities, features, items : Stuff.List;
		END;
		
		AnswerIq = POINTER TO RECORD(Core.Iq)
			urn : ARRAY 127 OF CHAR;
			node : ARRAY 1024 OF CHAR;
			identities, features, items : Stuff.List;
		END;

		Feature* = POINTER TO RECORD
			var- : POINTER TO ARRAY OF CHAR;
		END;
		
		Identity* = POINTER TO RECORD
			category-, type-, name- : POINTER TO ARRAY OF CHAR;
		END;
		
		Item* = POINTER TO RECORD
			jid-, name-, node- : POINTER TO ARRAY OF CHAR;
		END;
		
		Query* = POINTER TO LIMITED RECORD 
			identities, features, items : Stuff.List;
		END;
				
	VAR
		dir- : Directory;
	
	PROCEDURE (a : Action) Result*, NEW, ABSTRACT;
	PROCEDURE (a : Action) Error*, NEW, ABSTRACT;
	PROCEDURE (h : Hook) Request*(from : ARRAY OF CHAR; type : INTEGER; VAR query : Query), NEW, ABSTRACT;
	
	PROCEDURE NewFeature(e : Items.Item) : Feature;
	VAR f : Feature;
	BEGIN
		NEW(f); f.var:=DS.Create(e.GetParam(varAttr)).String(); RETURN(f)
	END NewFeature;
	
	PROCEDURE NewIdentity(e : Items.Item) : Identity;
	VAR i : Identity;
	BEGIN
		NEW(i); i.name:=DS.Create(e.GetParam(nameAttr)).String(); i.type:=DS.Create(e.GetParam(typeAttr)).String(); i.category:=DS.Create(e.GetParam(categoryAttr)).String(); RETURN(i)
	END NewIdentity;
	
	PROCEDURE NewItem(e : Items.Item) : Item;
	VAR i : Item;
	BEGIN
		NEW(i); i.jid:=DS.Create(e.GetParam(jidAttr)).String(); i.name:=DS.Create(e.GetParam(nameAttr)).String(); i.node:=DS.Create(e.GetParam(nodeAttr)).String(); RETURN(i)
	END NewItem;
	
	PROCEDURE (q : QueryIq) Do() : Items.Item;
		VAR n, n1 : Items.Item;
	BEGIN
		n:=Items.New(Const.iq);
		n1:=Items.New(query); n1.SetParam(Const.xmlns,q.urn);
		IF q.node#'' THEN n1.SetParam(nodeAttr, q.node$) END;
		n.Add(n1);
		RETURN n;				
		END Do;
	
	PROCEDURE (q : QueryIq) Use(data : Items.Item);
	VAR x, n : Items.Item; 
	BEGIN
		n:=data.First();
		ASSERT(n#NIL); ASSERT(n.GetName()$=query);
		q.node:=n.GetParam(nodeAttr)$;
		IF q.urn=urn_disco_info THEN
			q.identities:=Stuff.CreateList();
			q.features:=Stuff.CreateList();	
		ELSIF q.urn=urn_disco_items THEN
			q.items:=Stuff.CreateList();
		END;
		x:=n.First();
		WHILE x#NIL DO
			IF x.GetName()$ = identityElem THEN
				q.identities.Add(NewIdentity(x));
			ELSIF x.GetName()$ = featureElem THEN
				q.features.Add(NewFeature(x));
			ELSIF x.GetName()$ = itemElem THEN
				q.items.Add(NewItem(x));
			END;
			x:=n.Next(x);
		END;
	END Use;
	
	PROCEDURE (a : AnswerIq) Do() : Items.Item;
	VAR n, n1, n2 : Items.Item; i : INTEGER;
	BEGIN
		n:=Items.New(Const.iq);
		n1:=Items.New(query); n1.SetParam(Const.xmlns, a.urn);
		IF a.node#'' THEN n1.SetParam(nodeAttr, a.node$) END;
		IF a.identities#NIL THEN
			FOR i:=0 TO a.identities.Length()-1 DO
				n2:=Items.New(identityElem); 
				n2.SetParam(categoryAttr, a.identities.Item(i)(Identity).category$); 
				n2.SetParam(typeAttr, a.identities.Item(i)(Identity).type$); 
				IF a.identities.Item(i)(Identity).name$#'' THEN n2.SetParam(nameAttr, a.identities.Item(i)(Identity).name$) END;
				n1.Add(n2);
			END;
		END;
		IF a.features#NIL THEN
			FOR i:=0 TO a.features.Length()-1 DO
				n2:=Items.New(featureElem); n2.SetParam(varAttr, a.features.Item(i)(Feature).var$);
				n1.Add(n2);
			END;
		END;
		IF (a.items#NIL) & (a.urn=urn_disco_items) THEN
			FOR i:=0 TO a.items.Length()-1 DO
				n2:=Items.New(itemElem); 
				n2.SetParam(jidAttr, a.items.Item(i)(Item).jid$); 
				IF a.items.Item(i)(Item).node$#'' THEN n2.SetParam(nodeAttr, a.items.Item(i)(Item).node$); END;
				IF a.items.Item(i)(Item).name$#'' THEN n2.SetParam(nameAttr, a.items.Item(i)(Item).name$); END;
				n1.Add(n2);
			END;
		END;
		n.Add(n1);
		RETURN n;				
	END Do;
	
	PROCEDURE (a : AnswerIq) Use(data : Items.Item);
	VAR n : Items.Item; 
	(** to <=> from, type = result **)
	BEGIN
		a.Set(data.GetParam(Const.from)$, data.GetParam(Const.to)$, data.GetParam(Const.xml_lang)$, data.GetParam(Const.id)$, Const.result);
		n:=data.First();
		ASSERT(n#NIL); ASSERT(n.GetName()$=query);
		a.node:=n.GetParam(nodeAttr)$;
		a.urn:=n.GetParam(Const.xmlns)$;
		a.identities:=Stuff.CreateList();
		a.features:=Stuff.CreateList();
		a.items:=Stuff.CreateList();
	END Use;
	
	PROCEDURE (q: Queue) Add(a : Action), NEW; 
	BEGIN
		IF q.list=NIL THEN q.list:=Stuff.CreateList() END;
		q.list.Add(a);
	END Add;	
	
	PROCEDURE (q: Queue) Find(id : ARRAY OF CHAR): Action, NEW; 
	VAR i : INTEGER; ok : BOOLEAN;
	BEGIN
		i:=0; ok:=FALSE;
		WHILE (i<q.list.Length()) & ~ok DO
			ok:=(q.list.Item(i)(Action).id=id);
			INC(i);
		END;
		IF ok THEN DEC(i); RETURN q.list.Item(i)(Action)
		ELSE HALT(100) END;
	END Find;	
	
	PROCEDURE (q: Queue) Remove(a : Action), NEW;
	BEGIN
		q.list.Remove(a);
	END Remove;
	
	PROCEDURE HandleAnswer(ds: Disco; id : ARRAY OF CHAR; qiq : QueryIq);
	VAR a : Action;
	BEGIN
		a:=ds.queue.Find(id);
		ASSERT(a#NIL);
		a.identities:=qiq.identities;
		a.features:=qiq.features;
		a.items:=qiq.items;
		IF qiq.urn=urn_disco_info THEN a.type:=info ELSE a.type:=items END;
		a.Result;
		ds.queue.Remove(a);
	END HandleAnswer;
	
	PROCEDURE HandleError(ds: Disco; id : ARRAY OF CHAR);
	VAR a : Action;
	BEGIN
		a:=ds.queue.Find(id);
		ASSERT(a#NIL);
		a.identities:=NIL;
		a.features:=NIL;
		a.items:=NIL;
		a.type:=error;
		a.Error;
		ds.queue.Remove(a);
	END HandleError;
	
	PROCEDURE (q: Query) AddFeature*(var : ARRAY OF CHAR), NEW;
	VAR f : Feature;
	BEGIN
		NEW(f); f.var:=DS.Create(var).String(); 
		q.features.Add(f);
	END AddFeature;
	
	PROCEDURE (q: Query) AddIdentity*(category, type, name : ARRAY OF CHAR), NEW;
	VAR i : Identity;
	BEGIN
		NEW(i); i.name:=DS.Create(name).String(); i.type:=DS.Create(type).String(); i.category:=DS.Create(category).String(); 
		q.identities.Add(i);
	END AddIdentity;
	
	PROCEDURE (q: Query) AddItem*(jid, node, name : ARRAY OF CHAR), NEW;
	VAR i : Item;
	BEGIN
		NEW(i); i.jid:=DS.Create(jid).String(); i.name:=DS.Create(name).String(); i.node:=DS.Create(node).String(); 
		q.items.Add(i);
	END AddItem;
	
	PROCEDURE HandleGet(ds: Disco; aiq : AnswerIq);
	VAR type : INTEGER; q : Query;
	BEGIN
		IF ds.hook#NIL THEN
			IF aiq.urn=urn_disco_info THEN type:=info 
			ELSIF aiq.urn=urn_disco_items THEN type:=items END;
			NEW(q); q.identities:=aiq.identities; q.features:=aiq.features; q.items:=aiq.items;
			ds.hook.Request(aiq.to, type, q);
		ELSE END;
	END HandleGet;
	
	PROCEDURE (ds: Disco) Query* (from, to : ARRAY OF CHAR; type : INTEGER; node : ARRAY OF CHAR; action : Action), NEW;
	VAR qiq : QueryIq;
	BEGIN
		ASSERT(action#NIL, 20);
		ASSERT(from#'', 21);
		ASSERT(to#'', 22);
		ASSERT(type IN {items,info}, 23);
		NEW(qiq);
		Rand.UniRandStr(action.id, 5); action.id:='disco-'+action.id$;
		qiq.Set(to, from, '',action.id,Const.get);
		CASE type OF
			info : qiq.urn:=urn_disco_info
			|items : qiq.urn:=urn_disco_items
		END;
		ds.queue.Add(action);
		ds.owner.Send(qiq);
	END Query;	
	
	PROCEDURE (ds : Disco) Iq-(data : Items.Item; VAR res : INTEGER);
	VAR n : Items.Item; qiq : QueryIq; aiq : AnswerIq;
	BEGIN
		IF (data.First()#NIL) THEN
			n:=data.First();
			IF ((n.GetParam(Const.xmlns)$ = urn_disco_info) OR (n.GetParam(Const.xmlns)$ = urn_disco_items)) THEN
				IF (data.GetParam(Const.type)$=Const.result) THEN
					NEW(qiq); qiq.urn:=n.GetParam(Const.xmlns)$; qiq.Init(data); HandleAnswer(ds, data.GetParam(Const.id)$, qiq);
				ELSIF (data.GetParam(Const.type)$=Const.error) THEN
					HandleError(ds, data.GetParam(Const.id)$);
				ELSIF (data.GetParam(Const.type)$=Const.get) THEN
					NEW(aiq); aiq.Init(data); HandleGet(ds, aiq);
					ds.owner.Send(aiq);
				END;
			ELSE END;
		END;
		res:=Core.continue;
	END Iq;
		
	PROCEDURE (ds : Disco) Start-;
	BEGIN
		ds.valid:=TRUE;
	END Start;
	
	PROCEDURE (ds : Disco) Stop-;
	BEGIN
		ds.valid:=FALSE;
	END Stop;
		
	PROCEDURE (ds : Disco) SetHook*(hook : Hook), NEW;
	BEGIN
		ds.hook:=hook;
	END SetHook;
		
	PROCEDURE (d : Directory) Create-(session : Core.Session) : Core.Extension;
	VAR ds : Disco;
	BEGIN
		NEW(ds);
		NEW(ds.queue);
		ds.valid:=FALSE;
		RETURN ds;
	END Create;
	
	PROCEDURE Init;
	VAR d : Directory;
	BEGIN
		NEW(d);
		dir:=d;
	END Init;

BEGIN
	Init	
END XmppDisco.