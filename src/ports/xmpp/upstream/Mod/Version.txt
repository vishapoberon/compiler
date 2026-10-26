MODULE XmppVersion;
(**	project	= "XMPP"
	organization	= ""
	contributors	= ""
 	purpose	= "???????? ?????????? RFC 3921"
	changes	= "
	- , nn, ...
	"
	issues	= ""
**)

	IMPORT Core := XmppCore, Items:=XmlcoreItems, Const:=XmppConst, Log, Map:=ListsMap, Stuff:=XmppStuff,  DS:=StringsDyn, Strings, Rand:=ypkMathRandom;
	
	CONST 
		urn = 'jabber:iq:version';
		version = 'version';
		query = 'query';
		name = 'name';
		os = 'os';
				
	TYPE
		DynString = DS.DynString;
		
		Action* = POINTER TO ABSTRACT RECORD 
			id- : ARRAY 15 OF CHAR;	
		END;
		
		Hook* = POINTER TO ABSTRACT RECORD END;
		
		Version* = POINTER TO LIMITED RECORD (Core.Extension)
			valid- : BOOLEAN;
			queue : Map.StrMap;
			hook : Hook;
		END;	
		
		Directory* = POINTER TO RECORD(Core.ExtensionDir) END;
		
		VerIq = POINTER TO RECORD(Core.Iq) 
			name, ver, os: ARRAY 256 OF CHAR;
		END;
		
	VAR
		dir- : Directory;
	
	PROCEDURE (a : Action) Result*, NEW, ABSTRACT;
	PROCEDURE (a : Action) Error*, NEW, ABSTRACT;
	
	PROCEDURE (h: Hook) Request-(v: Version; OUT name, version, os: ARRAY OF CHAR), NEW, ABSTRACT;

	PROCEDURE (vi : VerIq) Do() : Items.Item;
	VAR n, n1, n2, n3 : Items.Item; 
	BEGIN
		n:=Items.New(Const.iq);
		n1:=Items.New(query);
		n1.SetParam(Const.xmlns, urn);
		IF vi.name$#'' THEN
			n2:=Items.New(name);
			n2.SetData(vi.name$);
			n1.Add(n2);
		END;
		IF vi.ver$#'' THEN
			n2:=Items.New(version);
			n2.SetData(vi.ver$);
			n1.Add(n2);
		END;
		IF vi.os$#'' THEN
			n2:=Items.New(os);
			n2.SetData(vi.os$);
			n1.Add(n2);
		END;
		n.Add(n1);
		RETURN n;		
	END Do;
	
	PROCEDURE (vi : VerIq) Use(item : Items.Item);
	VAR n, n1 : Items.Item;
	BEGIN
	
	END Use;
	
	PROCEDURE Answer(v: Version; IN from, to, id: ARRAY OF CHAR);
		VAR vi: VerIq;
	BEGIN
		NEW(vi); 
		vi.Set(from$, to$, '', id, Const.result);
		v.hook.Request(v, vi.name, vi.ver, vi.os);
		v.owner.Send(vi);
	END Answer;
	
	PROCEDURE (v : Version) Iq-(data : Items.Item; VAR res : INTEGER);
	VAR n: Items.Item; a : Action; vi : VerIq;
	BEGIN
		n:=data.First();
		IF n#NIL THEN
			IF (n.GetParam(Const.xmlns)$=urn) THEN
				IF data.GetParam(Const.type)$ = Const.get THEN
					Answer(v, data.GetParam(Const.from)$, data.GetParam(Const.to)$, data.GetParam(Const.id)$);
				END;
			END;
		END;
		res:=Core.continue;
	END Iq;
	
	PROCEDURE (v : Version) Start-;
	BEGIN
		v.valid:=TRUE;
	END Start;
	
	PROCEDURE (v : Version) Stop-;
	BEGIN
		v.valid:=FALSE;
	END Stop;
	
	PROCEDURE (v : Version) SetHook*(hook : Hook), NEW;
	BEGIN
		v.hook:=hook;
	END SetHook;
		
	PROCEDURE (d : Directory) Create-(session : Core.Session) : Core.Extension;
	VAR v : Version;
	BEGIN
		NEW(v);
		v.valid:=FALSE;
		v.queue:=Map.NewStrMap();
		RETURN v;
	END Create;
	
	PROCEDURE Init;
	VAR d : Directory;
	BEGIN
		NEW(d);
		dir:=d;
	END Init;

BEGIN
	Init	
END XmppVersion.