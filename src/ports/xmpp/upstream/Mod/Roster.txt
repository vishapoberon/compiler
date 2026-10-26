MODULE XmppRoster;
(**	project	= "XMPP"
	organization	= ""
	contributors	= ""
 	purpose	= "???????? ?????????? RFC 3921"
	changes	= "
	- , nn, ...
	- 20120507, pk, ???? ????????? ?????????? ?????? ? ?????????
	"
	issues	= ""
**)

	IMPORT Core:= XmppCore, Items:=XmlcoreItems, Const:=XmppConst, Log, Stuff:=XmppStuff,  DS:=StringsDyn, Strings, XmppStrings, Rand:=ypkMathRandom, ypkEncPunycode;
	
	CONST 
		QUERY* = 'query';
		URI_ROSTER* = 'jabber:iq:roster';
		ROSTER* = 'roster';
		ITEM* = 'item';
		JID* = 'jid';
		NAME* = 'name';
		GROUP* = 'group';
		SUBSCRIPTION* = 'subscription';
		REMOVE* = 'remove';
		NONE* = 'none';
		BOTH* = 'both';
		PUSH*='push';
		ASK*='ask';
				
	TYPE
		DynString = DS.DynString;
		
		Action* = POINTER TO ABSTRACT RECORD 
			owner-: Roster;
			id-: ARRAY 15 OF CHAR;
			items-: Stuff.List;
		END;
		
		Queue = POINTER TO RECORD
			list-: Stuff.List;
		END;
		
		Hook* = POINTER TO ABSTRACT RECORD END;
		
		Roster* = POINTER TO LIMITED RECORD (Core.Extension)
			valid-: BOOLEAN;
			queue: Queue;
			riq: RosterIq;
			hook: Hook;
		END;	
		
		Directory* = POINTER TO RECORD(Core.ExtensionDir) END;
		
		Item* = POINTER TO RECORD
			jid2, name-, group-,  subscription-, ask-: POINTER TO ARRAY OF CHAR;
		END;
		
		RosterIq = POINTER TO RECORD(Core.Iq)
			items: Stuff.List;
		END;
		
	VAR
		dir-: Directory;
	
	PROCEDURE (a: Action) Result*, NEW, ABSTRACT;
	PROCEDURE (a: Action) Error*, NEW, ABSTRACT;
	PROCEDURE (h: Hook) Push*(r: Roster; item: Item), NEW, ABSTRACT;
	
	PROCEDURE (i: Item) Jid*(): POINTER TO ARRAY OF CHAR, NEW;
		VAR rs: DynString; u, s: ARRAY 512 OF CHAR; res: INTEGER;
	BEGIN
		rs:=DS.Create('');
		XmppStrings.UsernameFromJid(i.jid2$, u, res);
		XmppStrings.ServerFromJid(i.jid2$, s, res);
		ypkEncPunycode.Decode(s, s);
		IF u$#'' THEN rs.AddString(u+'@') END;
		rs.AddString(s$);	
		RETURN rs.String()
	END Jid;
	
	PROCEDURE (i: Item) SetJid(IN x: ARRAY OF CHAR), NEW;
		VAR rs: DynString; u, s: ARRAY 512 OF CHAR; res: INTEGER;
	BEGIN
		rs:=DS.Create('');
		XmppStrings.UsernameFromJid(x$, u, res);
		XmppStrings.ServerFromJid(x$, s, res);
		ypkEncPunycode.Encode(s, s);
		IF u$#'' THEN rs.AddString(u+'@') END;
		rs.AddString(s$);
		i.jid2:=rs.String();	
	END SetJid;
	
	PROCEDURE (q: Queue) Add(a: Action), NEW; 
	BEGIN
		IF q.list=NIL THEN q.list:=Stuff.CreateList() END;
		q.list.Add(a);
	END Add;	
	
	PROCEDURE (q: Queue) Find(id: ARRAY OF CHAR): Action, NEW; 
	VAR i: INTEGER; ok: BOOLEAN;
	BEGIN
		i:=0; ok:=FALSE;
		IF q.list#NIL THEN
			WHILE (i<q.list.Length()) & ~ok DO
				ok:=(q.list.Item(i)(Action).id=id);
				INC(i);
			END;
			IF ok THEN DEC(i); RETURN q.list.Item(i)(Action)
			ELSE RETURN NIL END;
		ELSE RETURN NIL END
	END Find;	
	
	PROCEDURE (q: Queue) Remove(a: Action), NEW;
	BEGIN
		q.list.Remove(a);
	END Remove;
			
	PROCEDURE NewItem(jid, name, group, subscription, ask: ARRAY OF CHAR): Item;
		VAR i: Item;
	BEGIN
		NEW(i);
		i.SetJid(jid$);
		i.name:=DS.Create(name$).String();
		i.group:=DS.Create(group$).String();
		i.subscription:=DS.Create(subscription$).String();
		i.ask:=DS.Create(ask$).String();
		RETURN i;
	END NewItem;
	
	PROCEDURE NotifyResult(r: Roster; riq: RosterIq);
	VAR a: Action;
	BEGIN
		a:=r.queue.Find(riq.id);
		IF a#NIL THEN
			a.items:=riq.items;
			a.Result;
			r.queue.Remove(a);
		END;
	END NotifyResult;
	
	PROCEDURE NotifyError(r: Roster; id: ARRAY OF CHAR);
	VAR a: Action;
	BEGIN
		a:=r.queue.Find(id);
		IF a#NIL THEN
			a.Error;
			r.queue.Remove(a);
		END;
	END NotifyError;
	
	PROCEDURE NotifyPush(r: Roster; riq: RosterIq);
	BEGIN
		IF r.hook#NIL THEN
			r.hook.Push(r, riq.items.Item(0)(Item));
		END;
	END NotifyPush;
	
	PROCEDURE (r: RosterIq) Do(): Items.Item;
		VAR n, n1, n2, n3: Items.Item; 
	BEGIN
		n:=Items.New(Const.iq);
		n1:=Items.New(QUERY); n1.SetParam(Const.xmlns,URI_ROSTER);
		IF r.type=Const.set THEN
			ASSERT(r.items#NIL);
			n2:=Items.New(ITEM);
			n2.SetParam(JID, r.items.Item(0)(Item).jid2);
			IF r.items.Item(0)(Item).name$#'' THEN n2.SetParam(NAME, r.items.Item(0)(Item).name); END;
			IF r.items.Item(0)(Item).subscription$#'' THEN n2.SetParam(SUBSCRIPTION, r.items.Item(0)(Item).subscription); END;
			IF r.items.Item(0)(Item).group$#'' THEN 
				n3:=Items.New(GROUP);
				n3.SetData(r.items.Item(0)(Item).group);
				n2.Add(n3);
			END;
			n1.Add(n2);
		END;
		n.Add(n1);
		RETURN n;		
	END Do;
	
	PROCEDURE (r: RosterIq) Use(item: Items.Item);
		VAR n, n1: Items.Item; group: ARRAY 512 OF CHAR;
	BEGIN
		n:=item.First();
		IF (n#NIL) & (n.GetName()$=QUERY) THEN;
			n:=n.First();
			r.items:=Stuff.CreateList();
			WHILE n#NIL DO
				group:='';
				IF n.GetName()$ = ITEM THEN
					IF (n.First()#NIL) & (n.First()#NIL) THEN
						group:=n.First().GetData()$;
					END;
					r.items.Add(NewItem(n.GetParam(JID)$, n.GetParam(NAME)$, group$, n.GetParam(SUBSCRIPTION)$, n.GetParam(ASK)$))
				END;
				n:=item.Next(n);
			END;
		END;
	END Use;
	
	PROCEDURE (r: Roster) Request*(a: Action), NEW;
	VAR riq: RosterIq; str: ARRAY 24 OF CHAR;
	BEGIN
		ASSERT(r.valid);
		ASSERT(a#NIL);
		a.owner:=r;
		NEW(riq);
		Rand.UniRandStr(str, 4); str:=ROSTER+'_'+str;
		riq.Set('', r.owner.Username()+'@'+r.owner.Server()+'/'+r.owner.Resource(), '', str ,Const.get);
		a.id:=str$;
		r.queue.Add(a);
		r.owner.Send(riq);
	END Request;
	
	PROCEDURE (r: Roster) Add*(jid, name, group: ARRAY OF CHAR; a: Action), NEW;
	VAR riq: RosterIq; str: ARRAY 24 OF CHAR; item: Item;	
	BEGIN
		ASSERT(r.valid);
		ASSERT(jid#'');
		NEW(riq);
		Rand.UniRandStr(str, 4); str:=ROSTER+'_'+str;
		riq.Set('', r.owner.Username()+'@'+r.owner.Server()+'/'+r.owner.Resource(), '', str ,Const.set);
		riq.items:=Stuff.CreateList();
		riq.items.Add(NewItem(jid, name, group, '',''));
		IF a#NIL THEN
			a.id:=str$;
			r.queue.Add(a);
			a.owner:=r;
		END;
		r.owner.Send(riq);
	END Add;
	
	PROCEDURE (r: Roster) Update*(jid, newName, newGroup: ARRAY OF CHAR; a: Action), NEW;
	VAR riq: RosterIq; str: ARRAY 24 OF CHAR;	
	BEGIN
		ASSERT(r.valid);
		ASSERT(jid#'');
		NEW(riq);
		Rand.UniRandStr(str, 4); str:=ROSTER+'_'+str;
		riq.Set('', r.owner.Username()+'@'+r.owner.Server()+'/'+r.owner.Resource(), '', str ,Const.set);
		riq.items:=Stuff.CreateList();
		riq.items.Add(NewItem(jid, newName, newGroup, '',''));
		IF a#NIL THEN
			a.id:=str$;
			r.queue.Add(a);
			a.owner:=r;
		END;
		r.owner.Send(riq);
	END Update;
	
	PROCEDURE (r: Roster) Remove* (jid: ARRAY OF CHAR; a: Action), NEW;
	VAR riq: RosterIq; str: ARRAY 24 OF CHAR;	
	BEGIN
		ASSERT(r.valid);
		ASSERT(jid#'');
		NEW(riq);
		Rand.UniRandStr(str, 4); str:=ROSTER+'_'+str;
		riq.Set('', r.owner.Username()+'@'+r.owner.Server()+'/'+r.owner.Resource(), '', str,Const.set);
		riq.items:=Stuff.CreateList();
		riq.items.Add(NewItem(jid, '', '', REMOVE,''));
		IF a#NIL THEN
			a.id:=str$;
			r.queue.Add(a);
			a.owner:=r;
		END;
		r.owner.Send(riq);
	END Remove;
		
	PROCEDURE (r: Roster) Iq-(data: Items.Item; VAR res: INTEGER);
	VAR n: Items.Item; a: Action; riq: RosterIq;
	BEGIN
		n:=data.First();
		IF n#NIL THEN
			IF (n.GetParam(Const.xmlns)$ = URI_ROSTER) & (data.GetParam(Const.id)$#PUSH) THEN
				IF (data.GetParam(Const.type)$=Const.result) THEN
					NEW(riq); riq.Init(data); NotifyResult(r, riq)
				ELSIF (data.GetParam(Const.type)$=Const.error) THEN
					NotifyError(r, n.GetParam(Const.id)$);
				END;
			ELSIF (n.GetParam(Const.xmlns)$ = URI_ROSTER) & (data.GetParam(Const.id)$=PUSH) THEN
				NEW(r.riq); r.riq.Init(data);
				NotifyPush(r, r.riq);
			ELSIF n.GetName()$=Const.session THEN
				r.valid:=TRUE; 
			END;
		ELSE 
			a:=r.queue.Find(data.GetParam(Const.id));
			IF a#NIL THEN
				NEW(r.riq); r.riq.Init(data);
				NotifyResult(r, r.riq);
				r.riq:=NIL;
			END;
		END;
		res:=Core.continue;
	END Iq;
	
	PROCEDURE (r: Roster) Start-;
	BEGIN
		r.valid:=TRUE;
	END Start;
	
	PROCEDURE (r: Roster) Stop-;
	BEGIN
		r.valid:=FALSE;
	END Stop;
	
	PROCEDURE (r: Roster) SetHook*(hook: Hook), NEW;
	BEGIN
		r.hook:=hook;
	END SetHook;
		
	PROCEDURE (d: Directory) Create-(session: Core.Session): Core.Extension;
	VAR r: Roster;
	BEGIN
		NEW(r);
		r.valid:=FALSE;
		NEW(r.queue);
		RETURN r;
	END Create;
	
	PROCEDURE Init;
	VAR d: Directory;
	BEGIN
		NEW(d);
		dir:=d;
	END Init;

BEGIN
	Init	
END XmppRoster.