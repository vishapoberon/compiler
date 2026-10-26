MODULE XmppCore;
(**	project	= "XMPP"
	organization	= ""
	contributors	= ""
	purpose	= "???????? ?????????? ????????? XMPP http://xmpp.org/"
	changes	= "
	- 20120224, pk, ????????? ????????? ??????? ? ?????????, ?????????, ????? ?? ??? ??????, ??? ?? ??????? ??????????? ??????? PLAIN
	"
	issues	= ""
**)
	IMPORT Const:=XmppConst, XmppStrings, Base64:=ypkEncBase64, Sasl := XmppSasl, Connections:=XmppConnections, AbfBus, Dom:=XmlcoreDom, DS:=StringsDyn, Stuff:=XmppStuff, Log, Strings, Math, Services, TextViews, TextModels, TextMappers,  Views, Ports, Kernel, Meta, Rand:=ypkMathRandom, Items:=XmlcoreItems, ypkEncPunycode, StringsUtf;
	
	CONST
		sasl0 = 0;
		sasl1 = 1;
		sasl2 = 2;
		
		noAuth* = 0;
		normalOpts* = {};
		plain* = 10;	
		bind1='bind_1';
		
		in* = 1; out*=2;
		
		finish* = 1; continue*=2; (* 11.08.2008 21:34:19 ?????????? ??????????, ????? ?? ?????????? ?????????? ?????? ?????? ???????????, ???? ??????? ??????? *)
		
		unloaded*=-1; loaded* = 0; notFound*=1; incorrectExtension*=2; (* 11.08.2008 21:41:13 ????????? ?????????? ????????/???????? ?????????? *)
		
	TYPE
		DynString* = DS.DynString;
		String* = ARRAY OF CHAR;
		Directory* = POINTER TO ABSTRACT RECORD END; (* ??????? *)
		StdDirectory = POINTER TO RECORD(Directory) END; (* ?????????? ??????? *)
		
		StartAction = POINTER TO RECORD(Services.Action) 
			s: StdSession;
		END;
		
		ResponseAction = POINTER TO RECORD(Services.Action) 
			s: StdSession;
			c: Challenge;
		END;
		
		Stanza* = POINTER TO ABSTRACT RECORD(Connections.Entity) 
			to*, from* : ARRAY 512 OF CHAR;
			lang* : ARRAY 15 OF CHAR;
			id* : ARRAY 127 OF CHAR;
			type* : ARRAY 127 OF CHAR;
			item* : Items.Item;
			owner-: Session
		END;
		
		(* StanzaDirectory* = POINTER TO ABSTRACT RECORD END; *)
		
		StdStanza* = POINTER TO RECORD (Stanza) 
			content : ANYPTR;
		END;
		
		Stream = POINTER TO RECORD(Stanza)
			version : ARRAY 127 OF CHAR;
			features : List;
			full : BOOLEAN;
		END;
		
		Auth = POINTER TO RECORD(Stanza)
			mechanism : ARRAY 127 OF CHAR;
		END;
		
		Challenge = POINTER TO RECORD(Stanza)
			data : Sasl.Data;
		END;
			
		Response = POINTER TO RECORD(Stanza)
			data : Sasl.Data;
			step : INTEGER;
		END;
		
		Success = POINTER TO ABSTRACT RECORD(Stanza) END; 
		
		Failure = POINTER TO RECORD(Error) END;
		
		Iq* = POINTER TO ABSTRACT RECORD(Stanza) END;
		Message* = POINTER TO ABSTRACT RECORD(Stanza) END;
		Presence* = POINTER TO ABSTRACT RECORD(Stanza) END;
		
		BindIq = POINTER TO RECORD(Iq) 
			resource : ARRAY 512 OF CHAR;
		END;
		
		Error* = POINTER TO EXTENSIBLE RECORD(Stanza)
			text- : ARRAY 512 OF CHAR;
			specific- : ANYPTR;
			close- : BOOLEAN;
		END; 
		
		Session* = POINTER TO ABSTRACT RECORD(Connections.Owner) END;
		StdSession = POINTER TO RECORD(Session)
			c : Connections.Connection;
			stream : Stream;
			jid : ARRAY 3096 OF CHAR;
			password : ARRAY 512 OF CHAR;
			saslStep : INTEGER;
			rspauth : ARRAY 127 OF CHAR;
			authorized : BOOLEAN;
			hook : Hook;
			errorHook : ErrorHook;
			extensions : Stuff.List;
			opts : SET;
			puny: BOOLEAN;
		END;
		
		List* =  Stuff.List;
		
		Feature* = POINTER TO RECORD
			name-, value- : DynString;
			level- : INTEGER;
		END;
		
		ConsoleMsg* = RECORD(AbfBus.Message)
			session- : Session;
			in-, out- : POINTER TO ARRAY OF CHAR;
			code- : INTEGER;
		END;
		
		UpdateMsg* = RECORD(AbfBus.Message)
			session- : Session;
			type- : INTEGER;
			item- : Items.Item;
		END;
		
		Hook* = POINTER TO ABSTRACT RECORD END;
		
		ErrorHook* = POINTER TO ABSTRACT RECORD END;
		
		Extension* = POINTER TO ABSTRACT RECORD 
			owner- : Session
		END;
		
		ExtensionDir* = POINTER TO ABSTRACT RECORD END;
		
		ConnectionError = POINTER TO RECORD code : INTEGER; END;
		
	VAR
		dir-, stdDir- : Directory;  (* stanzaDir- : StanzaDirectory; *)
	
	PROCEDURE (s : Stanza) Use-(item : Items.Item), NEW, EMPTY;
	PROCEDURE (s : Stanza) Do- () : Items.Item, NEW, ABSTRACT;
	PROCEDURE (d : Directory) NewSession*(remoteAdr, jid : ARRAY OF CHAR; password : ARRAY OF CHAR; opts : SET) : Session, NEW, ABSTRACT;
	PROCEDURE (d : Directory) Start*(s: Session; OUT res: INTEGER), NEW, ABSTRACT;
	PROCEDURE (d : Directory) Stop*(s: Session), NEW, ABSTRACT;
	PROCEDURE (d : Directory) Connected*(s: Session): BOOLEAN, NEW, ABSTRACT;
	
	PROCEDURE (s : Session) HasFeature*(name, value : ARRAY OF CHAR) : BOOLEAN, NEW, ABSTRACT;
	PROCEDURE (s : Session) Authorized*() : BOOLEAN, NEW, ABSTRACT;
	PROCEDURE (s : Session) Error*(data : Error), NEW, ABSTRACT;
	PROCEDURE (s : Session) Server*() : POINTER TO ARRAY OF CHAR, NEW, ABSTRACT;
	PROCEDURE (s : Session) Username*() : POINTER TO ARRAY OF CHAR, NEW, ABSTRACT;
	PROCEDURE (s : Session) Resource*() : POINTER TO ARRAY OF CHAR, NEW, ABSTRACT;
	PROCEDURE (s : Session) StreamFeatures*() : List, NEW, ABSTRACT;
	PROCEDURE (s : Session) StartStream*, NEW, ABSTRACT;
	PROCEDURE (s : Session) CloseStream*, NEW, ABSTRACT;
	PROCEDURE (s : Session) SetHook*(hook : Hook), NEW, ABSTRACT;	
	PROCEDURE (s : Session) SetErrorHook*(errorHook : ErrorHook), NEW, ABSTRACT;
	PROCEDURE (s : Session) Send*(stanza : Stanza), NEW, ABSTRACT;
	PROCEDURE (s : Session) LoadExtension*(extensionModule : ARRAY OF CHAR; OUT res : INTEGER) : Extension, NEW, ABSTRACT;
	PROCEDURE (s : Session) ExtensionsList*() : ANYPTR, NEW, ABSTRACT;
PROCEDURE (s : Session) Raw*(in : ARRAY OF CHAR), NEW, ABSTRACT;
	PROCEDURE (s : Session) UnloadExtension*(extension : Extension; OUT res : INTEGER), NEW, ABSTRACT;
	PROCEDURE (s : Session) Notify*(VAR msg : ANYREC; OUT res : INTEGER), NEW, ABSTRACT;
	
(** Hook **)	
	PROCEDURE (h : Hook) In-(session : Session; data : Items.Item), NEW, ABSTRACT;
	PROCEDURE (h : Hook) Out-(session : Session; data : Items.Item), NEW, ABSTRACT;

(** ErrorHook **)	
	PROCEDURE (h : ErrorHook) Error*(session : Session; data : Error), NEW, ABSTRACT;

(** Extension **)
	PROCEDURE (e : Extension) Iq-(item : Items.Item; VAR res : INTEGER), NEW, EMPTY;	
	PROCEDURE (e : Extension) Message-(item : Items.Item; VAR res : INTEGER), NEW, EMPTY;
	PROCEDURE (e : Extension) Presence-(item : Items.Item; VAR res : INTEGER), NEW, EMPTY;
	PROCEDURE (e : Extension) Other-(item : Items.Item; VAR res : INTEGER), NEW, EMPTY;
	PROCEDURE (e : Extension) Wrote-(item : Items.Item), NEW, EMPTY;
	PROCEDURE (e : Extension) Start-, NEW, ABSTRACT;
	PROCEDURE (e : Extension) Stop-, NEW, ABSTRACT;

	PROCEDURE (d : ExtensionDir) Create-(owner : Session) : Extension, NEW, ABSTRACT;

(** Auxulary **)
	PROCEDURE AddFeature(l : List; name, value : ARRAY OF CHAR; level : INTEGER);
	VAR i, res : INTEGER; items : POINTER TO ARRAY OF ANYPTR; item : Feature;
	BEGIN 
		NEW(item);
		item.name:=DS.Create(name); item.value:=DS.Create(value); item.level:=level;
		l.Add(item);
	END AddFeature;
	
	PROCEDURE FindStanza(l : List; data : ANYPTR) : StdStanza;	
	VAR i : INTEGER; ok : BOOLEAN;
	BEGIN
		IF l.Length()>0 THEN
			ok:=FALSE; i:=0;
			WHILE (i<l.Length())&~ok DO
				ASSERT(l.Item(i) IS StdStanza);
				ok:=l.Item(i)(StdStanza).content=data;
				INC(i);
			END;
			DEC(i);
			RETURN l.Item(i)(StdStanza);
		ELSE HALT(99); END;
	END FindStanza;
	
(** Stanza **)
	PROCEDURE (s: Stanza) SetOwner (session: Session), NEW;
	BEGIN
		s.owner:=session;
	END SetOwner;
	
	PROCEDURE (s : Stanza) Data*() : ANYPTR;
		VAR x : Items.Item; usr, srv, psrv, rsrc, to, from: ARRAY 512 OF CHAR; res: INTEGER;
	BEGIN
		x:=s.Do();
		ASSERT(x#NIL, 60);
		IF s.from$#'' THEN
			from:=s.from$;
			IF (s.owner#NIL) & (s.owner IS StdSession) & (s.owner(StdSession).puny) THEN
				srv:=s.owner(StdSession).Server()$;
				Strings.Find(from$, srv$, 0, res);
				IF res>-1 THEN
					ypkEncPunycode.Encode(srv$, psrv);
					Strings.Replace(from, res, LEN(srv$), psrv$);
				END;
			END;
			x.SetParam(Const.from, from$); 
		END;
		
		IF s.to$#'' THEN 
			
			XmppStrings.UsernameFromJid(s.to$, usr, res);
			XmppStrings.ServerFromJid(s.to$, srv, res);
			XmppStrings.ResourceFromJid(s.to$, rsrc);
			ypkEncPunycode.Encode(srv, srv);
			IF usr$#'' THEN to:=usr$+'@'+srv$ ELSE to:=srv$ END;
			IF rsrc$#'' THEN to:=to$+'/'+rsrc$ END;
			
			x.SetParam(Const.to, to$); 
		END;
		
		IF s.type$#'' THEN x.SetParam(Const.type, s.type$); END;
		IF s.id$#'' THEN x.SetParam(Const.id, s.id$); END;
		IF s.lang$#'' THEN x.SetParam(Const.xml_lang, s.lang$); END;
		RETURN x;
	END Data;
	
	PROCEDURE (s : Stanza) Set*(to, from, lang, id, type : ARRAY  OF CHAR), NEW;
	BEGIN
		s.to:=to$; s.from:=from$; s.lang:=lang$; s.id:=id$; s.type:=type$;
	END Set;
	
	PROCEDURE (s : Stanza) Init*(item : ANYPTR), NEW;
		VAR psrv, srv: ARRAY 512 OF CHAR; res: INTEGER;
	BEGIN
		WITH item : Items.Item DO
			s.to:=item.GetParam(Const.to)$;
			IF s.to$#'' THEN
				XmppStrings.ServerFromJid(s.to$, psrv, res);
				ypkEncPunycode.Decode(psrv, srv);
				Strings.Find(s.to$, psrv, 0, res);
				Strings.Replace(s.to, res, LEN(psrv$), srv);
			END;
			
			s.from:=item.GetParam(Const.from)$;
			IF s.from$#'' THEN
				XmppStrings.ServerFromJid(s.from$, psrv, res);
				ypkEncPunycode.Decode(psrv, srv);
				Strings.Find(s.from$, psrv, 0, res);
				Strings.Replace(s.from, res, LEN(psrv$), srv);
			END;
			s.type:=item.GetParam(Const.type)$;
			s.lang:=item.GetParam(Const.xml_lang)$;
			s.id:=item.GetParam(Const.id)$;
			s.item:=item;
			s.Use(s.item)
			|item : ConnectionError DO s(Error).specific:=item;
		ELSE END;
	END Init;
	
(** StdStanza **)
	PROCEDURE (s : StdStanza) Do-() : Items.Item;
	BEGIN
		RETURN s.item;
	END Do;
	
	PROCEDURE (s : StdStanza) Use-(item : Items.Item);
	VAR e : Dom.Element; n, n1, n2, n3 : Dom.Node;
	BEGIN
		(* e:=data(Dom.Element);
		s.Set(e.GetAttribute(Const.to)$, e.GetAttribute(Const.from)$, e.GetAttribute(Const.xml_lang)$, e.GetAttribute(Const.id)$, e.GetAttribute(Const.type)$);
		s.content:=e.firstChild; *)
	END Use;
	
(** Stream **)
	PROCEDURE (s : Stream) Do-() : Items.Item;
	VAR x : Items.Item;
	BEGIN
		x:=Items.New(Const.stream_stream);
		x.SetParam(Const.xmlns, Const.jabber_client);
		x.SetParam(Const.xmlns_stream, Const.uri_stream);
		x.SetParam(Const.version, s.version); 
		RETURN x;
	END Do;
	
	PROCEDURE Features(s : Stream; root : Items.Item; level : INTEGER);
	VAR x : Items.Item; str : POINTER TO ARRAY OF CHAR;
	BEGIN
		IF s.features=NIL THEN s.features:=Stuff.CreateList() END;
		x:=root.First();
		WHILE x#NIL DO
			AddFeature(s.features, x.GetName(), x.GetParam(Const.xmlns)$, level); Features(s, x, level+1);
			str:=x.GetData();
			IF (str#NIL) & (str$#'') THEN AddFeature(s.features, root.GetName(), str, level) END;
			x:=root.Next(x);
		END;
		s.full:=TRUE;
	END Features;

	PROCEDURE (s : Stream) Use(item : Items.Item);
	VAR i : Items.Item; 	
	BEGIN
		s.version:=item.GetParam(Const.version)$;
		i:=item.First();
		s.full:=(i#NIL);
		WHILE i#NIL DO
			IF i.GetName()$=Const.stream_features THEN
				Features(s, i, 0);
			ELSIF i.GetName()$=Const.stream_error THEN
				AddFeature(s.features, Const.stream_error,'',0);
			END;
			i:=item.Next(i);
		END;
	END Use;
	
(** Auth **)	
	PROCEDURE (a : Auth) Do() : Items.Item;
	VAR x: Items.Item; i: INTEGER; ds: DS.DynString; u, p: POINTER TO ARRAY OF SHORTCHAR; res: POINTER TO ARRAY OF BYTE;
	BEGIN
		x:=Items.New(Const.auth);
		x.SetParam(Const.xmlns, Const.uri_sasl); 
		x.SetParam(Const.mechanism, a.mechanism);
		IF a.mechanism$=Const.PLAIN THEN
			NEW(u, StringsUtf.Utf8Size(a.owner(StdSession).Username()$));
			StringsUtf.ToUtf8(a.owner(StdSession).Username()$, u);
			
			NEW(p, StringsUtf.Utf8Size(a.owner(StdSession).password$));
			StringsUtf.ToUtf8(a.owner(StdSession).password$, p);
			
			NEW(res, LEN(u)+LEN(p));
			res[0]:=0;
			FOR i:=1 TO LEN(u) DO res[i]:=SHORT(ORD(u[i-1])) END;
			res[LEN(u)]:=0;
			FOR i:=LEN(u)+1 TO LEN(res)-1 DO res[i]:=SHORT(ORD(p[i-LEN(u)-1])) END;
			Base64.Encode(res, ds);
			x.SetData(ds.String()$);
		END;
		RETURN x;
	END Do;

(** Challenge **)	
	PROCEDURE (c : Challenge) Use(x : Items.Item);
	VAR s : POINTER TO ARRAY OF CHAR; in, out : DynString; sd : Sasl.Data;
	BEGIN
		s:=x.GetData();
		in:=DS.Create(s);
		(**)
		Base64.DecodeText(in, out);
		sd.Fill(out); c.data:=sd;
	(**)
	END Use;

	PROCEDURE (c : Challenge) Do-() : Items.Item;
	BEGIN
		RETURN NIL;
	END Do;

(** Responce **)	
	PROCEDURE (r : Response) Do() : Items.Item;
	VAR x : Items.Item; in, out : DynString;
	BEGIN
		x:=Items.New(Const.response);
		x.SetParam(Const.xmlns, Const.uri_sasl);
		CASE r.step OF
			sasl1:
				r.data.Make(in); 
				Base64.EncodeText(in,out);
				x.SetData(out.String());
			|sasl2:
		ELSE HALT(100); END;
		RETURN x;
	END Do;
	
(** BindIq **)
	PROCEDURE (b : BindIq) Do() : Items.Item;
		VAR n, n1, n2 : Items.Item;
	BEGIN
		n:=Items.New(Const.iq);
		n1:=Items.New(Const.bind); n1.SetParam(Const.xmlns,Const.uri_bind);
		n.Add(n1);
		IF b.resource$#'' THEN
			n2:=Items.New(Const.resource);
			n2.SetData(b.resource$);
			n1.Add(n2);
		END;
		RETURN n;		
	END Do;
	
	PROCEDURE (b : BindIq) Use(x : Items.Item);
	VAR x1 : Items.Item;
	BEGIN
		x1:=x.First();
		IF x1.GetName()$=Const.bind THEN
			x1:=x1.First();
			b.resource:=x1.GetData()$;
		END;
	END Use;

(** Error **)	
	PROCEDURE (e : Error) Do-() : Items.Item;
	BEGIN
		RETURN NIL;
	END Do;

	PROCEDURE (e : Error) Use-(n : Items.Item), EXTENSIBLE;
	VAR n1, n2, n3 : Items.Item;
	BEGIN
		n1:=n.First();
		WHILE n1#NIL DO
			IF n1.GetParam(Const.xmlns)$=Const.uri_streams THEN
				IF n1.GetName()$=Const.text THEN e.text:=n1.GetData()$
				ELSE 
					e.type:=n1.GetName()$; 
					e.close:=TRUE
				END;
			ELSIF n1.GetParam(Const.xmlns)$=Const.uri_stanzas THEN
				IF n1.GetName()$=Const.text THEN e.text:=n1.GetData()$
				ELSE e.type:='Stanza '+n1.GetName()$+'[' +n.GetParam(Const.error)$+']'; END;
				e.close:=FALSE; 
			ELSIF (n1.GetName()$=Const.error)&(n1.First()#NIL) THEN
				e.type:=n1.First().GetName()$+' ' +n.GetParam(Const.code)$;
				e.close:=FALSE;
			ELSE
				e.specific:=n1;
			END;
			n1:=n.Next(n1);
		END;
		IF (e.specific#NIL) & (e.specific IS ConnectionError) THEN
			e.text:='Server unavailable or server closed down connection.';
			e.type:='Connection error'; e.close:=TRUE;
		END;
	END Use;


(** Failure **)
	PROCEDURE (f : Failure) Use(n : Items.Item);
	VAR n1, n2, n3 : Items.Item;
	BEGIN
		n1:=n.First();
		IF n1#NIL THEN f.type:='SASL '+n1.GetName()$ END;
		f.close:=FALSE; 
	END Use;
		
(** Session **)
	PROCEDURE ^ DefaultErrorReport(s : StdSession; error : Error);
	
	PROCEDURE UpdateExtensions(s : StdSession; data : Items.Item);
	VAR i : INTEGER; res : INTEGER; name : ARRAY 127 OF CHAR;
	BEGIN
		i:=0; res:=continue;
		WHILE (i<s.extensions.Length())&(res=continue) DO
			name:=data.GetName()$;
			IF name = Const.iq THEN s.extensions.Item(i)(Extension).Iq(data, res)
			ELSIF name = Const.message THEN s.extensions.Item(i)(Extension).Message(data, res)
			ELSIF name = Const.presence THEN s.extensions.Item(i)(Extension).Presence(data, res)
			ELSE s.extensions.Item(i)(Extension).Other(data, res) END;
			
			INC(i)
		END;
	END UpdateExtensions;
	
	PROCEDURE NotifyExtensions(s : StdSession; data : Items.Item);
	VAR i : INTEGER;
	BEGIN
		i:=0;
		WHILE (i<s.extensions.Length()) DO
			s.extensions.Item(i)(Extension).Wrote(data);
			INC(i)
		END;
	END NotifyExtensions;
	
	PROCEDURE StartExtensions(s : StdSession);
	VAR i : INTEGER;
	BEGIN
		i:=0;
		WHILE (i<s.extensions.Length()) DO
			s.extensions.Item(i)(Extension).Start;
			INC(i)
		END;
	END StartExtensions;
	
	PROCEDURE Out(s : StdSession; item : Items.Item);
	VAR msg : UpdateMsg; res : INTEGER;
	BEGIN
		msg.session:=s;
		msg.item:=item;
		msg.type:=out;
		IF s.hook#NIL THEN s.hook.In(s, msg.item) END;
		NotifyExtensions(s, item);
		s.Notify(msg, res)
	END Out;
	
	PROCEDURE In(s : StdSession; item : Items.Item);
	VAR msg : UpdateMsg; res : INTEGER;
	BEGIN
		msg.session:=s;
		msg.item:=item;
		msg.type:=in;
		IF s.hook#NIL THEN s.hook.In(s, msg.item) END;
		UpdateExtensions(s, item);
		s.Notify(msg, res)
	END In;
	
	PROCEDURE (s : StdSession) HasFeature(name, value : ARRAY OF CHAR) : BOOLEAN;
	VAR i : INTEGER; ok : BOOLEAN;		
	BEGIN
		IF (s.stream#NIL) & (s.stream.features#NIL) & (s.stream.features.Length()>0) THEN
			ok:=FALSE; i:=0;
			WHILE (i<s.stream.features.Length())&~ok DO
				ASSERT(s.stream.features.Item(i) IS Feature);
				IF (name$#'*') & (value$#'*') THEN
					ok:=(s.stream.features.Item(i)(Feature).name.String()$=name$) & (s.stream.features.Item(i)(Feature).value.String()$=value$)
				ELSIF (name$='*') THEN
					ok:=(s.stream.features.Item(i)(Feature).value.String()$=value$)
				ELSE ok:=(s.stream.features.Item(i)(Feature).name.String()$=name$) END;
				INC(i);
			END;
			RETURN ok;
		ELSE RETURN FALSE; END;
	END HasFeature;
	
	PROCEDURE (s : StdSession) Authorized() : BOOLEAN;
	BEGIN
		RETURN s.authorized; 
	END Authorized;
	
	PROCEDURE (s : StdSession) Error(data : Error);
	BEGIN
		IF s.errorHook#NIL THEN s.errorHook.Error(s, data) ELSE DefaultErrorReport(s, data); END;
	END Error;

	PROCEDURE (s : StdSession) Server() : POINTER TO ARRAY OF CHAR;
	VAR start, end, len : INTEGER; str :  ARRAY 3096 OF CHAR; pstr : POINTER TO ARRAY OF CHAR;
	BEGIN
		Strings.Find(s.jid, '@',0,start); 
		ASSERT(start#-1, 21);
		Strings.Find(s.jid, '/',start, end);
		IF end>-1 THEN Strings.Extract(s.jid$, start+1,LEN(s.jid$)-start-(LEN(s.jid$)-end+1), str);
		ELSE Strings.Extract(s.jid$, start+1,LEN(s.jid$)-start, str); END;
		NEW(pstr, LEN(str$)+1); pstr^:=str$+0X;
		RETURN pstr;  
	END Server;
 
	PROCEDURE (s : StdSession) Username() : POINTER TO ARRAY OF CHAR;
	VAR start, end, len : INTEGER; str :  ARRAY 3096 OF CHAR; pstr : POINTER TO ARRAY OF CHAR;
	BEGIN
		Strings.Find(s.jid, '@',0,start); 
		ASSERT(start#-1, 21);
		Strings.Extract(s.jid$, 0,start, str);
		NEW(pstr, LEN(str$)+1); pstr^:=str$+0X;
		RETURN pstr;  
	END Username;
	
	PROCEDURE (s : StdSession) Resource() : POINTER TO ARRAY OF CHAR;
	VAR start, end, len : INTEGER; str :  ARRAY 3096 OF CHAR; pstr : POINTER TO ARRAY OF CHAR;
	BEGIN
		Strings.Find(s.jid, '/',0,start);
		IF start>-1 THEN 
			INC(start);
			Strings.Extract(s.jid$,start, LEN(s.jid$)-start, str);
		ELSE str:=''; END;
		NEW(pstr, LEN(str$)+1); pstr^:=str$+0X;
		RETURN pstr;  
	END Resource;
	
	PROCEDURE (s : StdSession) StreamFeatures() : List;
	BEGIN
		IF s.stream#NIL THEN RETURN s.stream.features ELSE RETURN NIL END;  
	END StreamFeatures;
		
	PROCEDURE (s : StdSession) StartStream;
	VAR stream : Stream;
	BEGIN
		NEW(stream);
		stream.to:=s.Server()$; stream.version:='1.0'; stream.lang:='en';
		s.c.WriteData(stream, TRUE);
	END StartStream;
	
	PROCEDURE (s : StdSession) CloseStream;
	BEGIN
		s.c.Raw('</stream:stream>');
		s.c.Close;
		s.authorized:=FALSE;
	END CloseStream;
		
	PROCEDURE (s : StdSession) Auth(mechanism: ARRAY OF CHAR), NEW;
	VAR a : Auth;
	BEGIN
		NEW(a);
		a.mechanism:=mechanism$; 
		a.SetOwner(s);
		s.c.WriteData(a, FALSE);
	END Auth;
	
	PROCEDURE (s : StdSession) Response(VAR data : Sasl.Data), NEW;
	VAR r : Response; ds1, ds2: DS.DynString; psrv: ARRAY 256 OF CHAR;
	BEGIN
		NEW(r);
		CASE s.saslStep OF
			sasl0:
				data.username:=s.Username()$+0X;
				Rand.UniRandStr(data.cnonce, 32);
			(*	ds1:=DS.Create(data.cnonce);
				Base64.EncodeText(ds1, ds2);
				data.cnonce:=ds2.String()$; *)
				Strings.IntToStringForm(s.saslStep+1, 10,8,"0",FALSE,data.nc);
				IF s.puny THEN 
					ypkEncPunycode.Encode(s.Server()$, psrv)
				ELSE psrv:=s.Server()$ END;
				data.digestUri:=Const.xmpp+'/'+psrv+0X;
				data.password:=s.password$+0X;
				data.charset:='utf-8';
				data.qop:='auth';
				
				(* data.realm:=''; *)
				data.Gen;
				s.saslStep:=sasl1;
				r.data:=data;
				r.step:=s.saslStep;
				s.c.WriteData(r, FALSE);
			|sasl1:
				s.rspauth:=data.rspauth$;
				s.saslStep:=sasl2;
				r.step:=s.saslStep;
				s.c.WriteData(r, FALSE);
			ELSE END;
	END Response;
	
	PROCEDURE (s : StdSession) Send*(stanza : Stanza);
	BEGIN
		ASSERT(stanza#NIL, 21);
		stanza.SetOwner(s);
		s.c.WriteData(stanza, FALSE);
	END Send;
	
	PROCEDURE (s : StdSession) Fetch(VAR item : Items.Item), NEW;
	VAR b : BindIq; err : Error;
	BEGIN
		IF item.GetParam(Const.id)$=bind1 THEN 
			NEW(b); b.Init(item); s.jid:=b.resource$; 
			StartExtensions(s);
		END;
		IF item.GetParam(Const.type)$=Const.error THEN NEW(err); err.Init(item); s.Error(err); END;
	END Fetch;
	
	PROCEDURE (s : Session) BindResource, NEW;
	VAR b : BindIq;
	BEGIN
		NEW(b);
		b.Set('','','',bind1, Const.set);
		b.resource:=s.Resource()$;
		s.Send(b);
	END BindResource;
	
	PROCEDURE (a: StartAction) Do;
	BEGIN
		a.s.StartStream;
	END Do;
	
	PROCEDURE (a: ResponseAction) Do;
	BEGIN
		a.s.Response(a.c.data);
	END Do;
	
	PROCEDURE (s : StdSession) SetHook(hook : Hook);
	BEGIN
		s.hook:=hook;
	END SetHook;
	
	PROCEDURE (s : StdSession) SetErrorHook(errorHook : ErrorHook);
	BEGIN
		s.errorHook:=errorHook;
	END SetErrorHook;
	
	PROCEDURE (s : StdSession) SendConsoleMsg(code : INTEGER), NEW;
	VAR msg : ConsoleMsg; res : INTEGER;
	BEGIN
		msg.session:=s;
		msg.in:=s.c.ReadBuffer();
		msg.out:=s.c.WriteBuffer();
		msg.code:=code;
		AbfBus.Send(msg, res);
	END SendConsoleMsg;

	PROCEDURE (s : StdSession) Notify(VAR msg : ANYREC; OUT res : INTEGER);
	BEGIN
		WITH msg : AbfBus.Message DO AbfBus.Send(msg, res)
		ELSE END;
	END Notify;
	
	PROCEDURE (s : StdSession) UpdateError-(code : INTEGER);
	VAR ce : ConnectionError; e : Error;
	BEGIN
		NEW(ce);
		ce.code:=code;
		NEW(e); e.Init(ce);
		s.Error(e);
	END UpdateError;
	
	PROCEDURE (s : StdSession) UpdateWrite-(data : ANYPTR);
	VAR el : Dom.Node; item : Items.Item;
	BEGIN
		WITH data : Dom.DocumentFragment DO
			el:=data.firstChild;
			WHILE el#NIL DO
				item:=Items.New(''); item.Fill(el);
				Out(s, item);
				el:=el.nextSibling;
			END;
		ELSE HALT(100) END;
		s.SendConsoleMsg(out);
	END UpdateWrite;
		
	PROCEDURE (s : StdSession) UpdateRead-(data : ANYPTR);
	VAR e : Dom.Node; stream : Stream; challenge : Challenge; error : Error; fail : Failure; item : Items.Item; sa: StartAction; ra: ResponseAction;
		
		PROCEDURE TryActivate;
		BEGIN
			IF s.stream.full & s.authorized THEN
				IF s.HasFeature(Const.bind,'*') THEN
					s.BindResource;
				END;
			ELSIF s.stream.full THEN
				IF s.HasFeature(Const.stream_error, '*') THEN NEW(error); error.Init(data); s.Error(error); END; 
				IF s.HasFeature('*', Const.PLAIN) & ~(noAuth IN s.opts) & (plain IN s.opts) THEN
					s.Auth(Const.PLAIN); 
				ELSIF s.HasFeature('*', Const.DIGEST_MD5) & ~(noAuth IN s.opts) THEN 
					s.Auth(Const.DIGEST_MD5); 
				END; 
			END;
		END TryActivate;
		
	BEGIN
		WITH data : Dom.DocumentFragment DO
			e:=data.firstChild;
			WHILE e#NIL DO
				WITH e : Dom.Element DO 
					item:=Items.New(''); item.Fill(e);
					
					IF item.GetName()$=Const.stream_stream THEN
						NEW(stream); stream.Init(item);
						s.stream:=stream; 
						TryActivate;
					 ELSIF (item.GetName()$=Const.stream_features) & ~s.stream.full THEN (* ??????????? *)
						s.stream.features:=Stuff.CreateList();
						Features(s.stream, item, 0);
						TryActivate;
					ELSIF item.GetName()$=Const.challenge THEN
						NEW(challenge); challenge.Init(item);
						NEW(ra); ra.c:=challenge; ra.s:=s; Services.DoLater(ra, Services.Ticks()+50);
					ELSIF item.GetName()$=Const.success THEN
						s.authorized:=TRUE; NEW(sa); sa.s:=s; Services.DoLater(sa, Services.Ticks()+50);
					ELSIF item.GetName()$=Const.failure THEN
						NEW(fail); fail.Init(item); s.Error(fail);
					ELSIF (item.GetName()$=Const.iq) OR (item.GetName()$=Const.message) OR (item.GetName()$=Const.presence) THEN
						s.Fetch(item);
					ELSIF item.GetName()$=Const.stream_error THEN
						NEW(error); error.Init(item); s.Error(error);
					ELSE END; 
					In(s, item);
				ELSE END; 
				e:=e.nextSibling;
			END;
		ELSE Log.String('[XMPP] strange xml element') END;	
		s.SendConsoleMsg(in);
	END UpdateRead;
	
	PROCEDURE (s : StdSession) Raw(in : ARRAY OF CHAR);
	BEGIN
		s.c.Raw(in);
	END Raw;
	
	PROCEDURE (s : StdSession) LoadExtension(extensionModule : ARRAY OF CHAR; OUT res : INTEGER) : Extension;
	VAR e : Extension; item : Meta.Item; ed : ANYPTR; ok : BOOLEAN;
		
		PROCEDURE Exists(VAR x : Extension) : BOOLEAN;
		VAR i,j : INTEGER; z : BOOLEAN; str : ARRAY 127 OF CHAR;
		BEGIN
			z:=FALSE; i:=0;
			WHILE (i<s.extensions.Length()) & ~z DO
				Services.GetTypeName(s.extensions.Item(i), str);
				Strings.Find(str$,extensionModule,0,j);
				z:=j>-1; IF z THEN x:=s.extensions.Item(i)(Extension); END;
				INC(i);
			END;
			RETURN z;
		END Exists; 
		
	BEGIN
		ASSERT(extensionModule$#'',21);
		Kernel.LoadMod(extensionModule);
		Meta.Lookup(extensionModule, item);
		IF item.Valid() THEN
			item.Lookup('dir', item);
			IF item.Valid() THEN
				ed:=item.PtrVal();
				WITH ed : ExtensionDir DO
					e:=ed(ExtensionDir).Create(s);
					IF ~Exists(e) THEN
						s.extensions.Add(e);
						e.owner:=s;
					END;
					res:=loaded;
				ELSE res:=incorrectExtension; END;
			ELSE res:=incorrectExtension; END;	
		ELSE res:=notFound; END;
		RETURN e;
	END LoadExtension;
	
	PROCEDURE (s : StdSession) UnloadExtension(extension : Extension; OUT res : INTEGER);
	VAR i : INTEGER; ok : BOOLEAN;
	BEGIN
		i:=0; ok:=FALSE;
		WHILE (i<s.extensions.Length()) & ~ok DO
			ok:=s.extensions.Item(i)=extension;
			INC(i);
		END;
		IF ~ok THEN res:=notFound 
		ELSE extension.Stop; s.extensions.Remove(extension); res:=unloaded; END;
	END UnloadExtension;
	
	PROCEDURE (s : StdSession) ExtensionsList() : ANYPTR;
	BEGIN
		RETURN s.extensions;
	END ExtensionsList;
	
	PROCEDURE DefaultErrorReport(s : StdSession; error : Error);
	VAR m : TextModels.Model; f : TextMappers.Formatter; a : TextModels.Attributes;
	BEGIN
		m:=TextModels.dir.New();
		NEW(a); a.InitFromProp(NIL); 
		a:=TextModels.NewSize(a, 16*Ports.point); 
		f.ConnectTo(m); f.rider.SetAttr(a);
		f.WriteString('XMPP session '); 
		IF s.stream#NIL THEN f.WriteString(s.stream.id+' '); END; f.WriteString('<'+s.jid+'> error');
		a:=TextModels.NewSize(a, 14*Ports.point); f.rider.SetAttr(a);
		f.WriteLn; f.WriteString('Error "'+error.type$+'" occurred');
		f.WriteLn; f.WriteString('Details provided by server: '+error.text$); IF error.text$="" THEN f.WriteString('<none>')END;
		Views.OpenAux(TextViews.dir.New(m), 'XMPP Core : error message');
		IF error.close THEN s.CloseStream; END;
	END DefaultErrorReport;
	
	PROCEDURE (d : StdDirectory) NewSession(remoteAdr, jid : ARRAY OF CHAR; password : ARRAY OF CHAR; opts : SET) : Session;
	VAR s : StdSession; ss, ps: ARRAY 256 OF CHAR;
	BEGIN
		NEW(s);
		s.saslStep:=0;
		s.authorized :=FALSE;
		s.jid:=jid$;
		
		ss:=s.Server()$;
		ypkEncPunycode.Encode(ss, ps);
		s.puny:=ss$#ps$;
		
		s.opts:=opts;
		s.password:=password$;
		s.extensions:=Stuff.CreateList();
		s.c:=Connections.dir.NewConnection(s, remoteAdr);
		RETURN s; 
	END NewSession;
	
	PROCEDURE (d : StdDirectory) Start(s: Session; OUT res: INTEGER);
	BEGIN
		ASSERT(s#NIL, 20);
		WITH s: StdSession DO
			s.c.Open(res);
		ELSE END;
	END Start;
	
	PROCEDURE (d : StdDirectory) Stop(s: Session);
	BEGIN
		ASSERT(s#NIL, 20);
		WITH s: StdSession DO
			s.c.Close;
		END;
	END Stop;
	
	PROCEDURE (d : StdDirectory) Connected(s: Session): BOOLEAN;
		VAR ok: BOOLEAN;
	BEGIN
		ok:=FALSE;
		ASSERT(s#NIL, 20);
		WITH s: StdSession DO
			ok:=s.c.Connected();
		END;
		RETURN ok;
	END Connected;
	
	PROCEDURE SetDir*(d : Directory);
	BEGIN
		dir:=d
	END SetDir;
	
	PROCEDURE GetDataLength*(s: Session; OUT in, out: LONGINT);
	BEGIN
		WITH s: StdSession DO
			Connections.GetDataLength(s.c, in, out);
		ELSE in:=0; out:=0; END;
	END GetDataLength;
	
(*	PROCEDURE SetStanzaDir*(d : StanzaDirectory);
	BEGIN
		stanzaDir:=d;
	END SetStanzaDir;
*)	
	
	PROCEDURE SetLimit*(s: Session; max: INTEGER);
	BEGIN
		WITH s: StdSession DO
			s.c.LimitData(max);
		ELSE END;
	END SetLimit;
	
	PROCEDURE Init;
	VAR d : StdDirectory;
	BEGIN
		NEW(d);
		dir:=d; stdDir:=d;
	END Init;

BEGIN
	Init	
END XmppCore.