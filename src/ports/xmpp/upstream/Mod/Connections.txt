MODULE XmppConnections;
(**	project	= "XMPP"
	organization	= ""
	contributors	= ""
	purpose	= "???????? ?????????? ????????? XMPP http://xmpp.org/"
	changes	= "
	- , nn, ...
	-20120913, ??????? ????????? ??? ????????????? ?????? ??????
	"
	issues	= ""
**)
	IMPORT XmlStream :=XmppXmlStream, Gen:=XmppXmlGen, XmppConst, Dom:=XmlcoreDom, Parser:=XmlcoreParser, Formatters := XmlcoreFormatters, DS:=StringsDyn, Items:=XmlcoreItems, Services, Log;
	
	CONST
		maxFails = 1;
		split* = TRUE;
		dontSplit* = FALSE;
		LOG = FALSE;
		disconnected* = 1;
		
	TYPE
		DynString* = DS.String;
		String* = ARRAY OF CHAR;
		Directory* = POINTER TO ABSTRACT RECORD END; (* ??????? *)
		StdDirectory = POINTER TO RECORD(Directory) END; (* ?????????? ??????? *)
		
		Entity* = POINTER TO ABSTRACT RECORD END;
		
		Owner* = POINTER TO ABSTRACT RECORD END;
				
		Connection* = POINTER TO ABSTRACT RECORD(XmlStream.Owner) END;
		
		StdConnection = POINTER TO RECORD(Connection)
			owner : Owner;
			lastRead, lastWrote : ANYPTR;
			stream : XmlStream.Stream;
			remoteAdr, localAdr : ARRAY 256 OF CHAR;
			p : Parser.Parser;
			g : Gen.Generator;
			closed : BOOLEAN;
			wroteBytes, readBytes: LONGINT;
		END;
		
	VAR
		dir-, stdDir- : Directory;
		doc- : Dom.XmlDocument;
		protocol, localAdr : ARRAY 128 OF CHAR;
(********************************************************************************)
	PROCEDURE XmlReportError(pos, line, row: INTEGER; IN msg: ARRAY OF CHAR);
	BEGIN
		IF LOG THEN Log.Ln; Log.String('Unrecoverable stream error'); Log.Ln; END;
	END XmlReportError;
	
	PROCEDURE (e : Entity) Data*() : ANYPTR, NEW, ABSTRACT;
	
	PROCEDURE (o : Owner) UpdateRead-(data : ANYPTR), NEW, ABSTRACT;
	PROCEDURE (o : Owner) UpdateWrite-(data : ANYPTR), NEW, ABSTRACT;
	PROCEDURE (o : Owner) UpdateError-(code : INTEGER), NEW, ABSTRACT;

	PROCEDURE (d : Directory) NewConnection*(owner : Owner; remoteAdr : ARRAY OF CHAR) : Connection, NEW, ABSTRACT;

	PROCEDURE (c : Connection) ReadBuffer*() : POINTER TO ARRAY OF CHAR, NEW, ABSTRACT;
	PROCEDURE (c : Connection) WriteBuffer*() : POINTER TO ARRAY OF CHAR, NEW, ABSTRACT;
	PROCEDURE (c : Connection) Raw*(in : ARRAY OF CHAR), NEW, ABSTRACT;
	PROCEDURE (c : Connection) Open*(OUT res: INTEGER), NEW, ABSTRACT;
	PROCEDURE (c : Connection) Connected*() : BOOLEAN, NEW, ABSTRACT;
	PROCEDURE (c : Connection) Close*, NEW, ABSTRACT;
	PROCEDURE (c : Connection) WriteData*(fragment : Entity; split : BOOLEAN), NEW, ABSTRACT;
	PROCEDURE (c: Connection) LimitData*(max: INTEGER), NEW, ABSTRACT;
	
	PROCEDURE (c : StdConnection) ReadBuffer() : POINTER TO ARRAY OF CHAR;
	BEGIN
		RETURN c.stream.ReadBuffer();
	END ReadBuffer;
	
	PROCEDURE (c : StdConnection) WriteBuffer() : POINTER TO ARRAY OF CHAR;
	BEGIN
		RETURN c.stream.WriteBuffer();
	END WriteBuffer;
	
	PROCEDURE (c : StdConnection) Raw(in : ARRAY OF CHAR);
	BEGIN
		c.stream.Raw(in);
	END Raw;
	
	PROCEDURE (c : StdConnection) Open(OUT res: INTEGER);
	VAR num: INTEGER;
	BEGIN
		XmlStream.InstallDir;
		c.stream:=XmlStream.dir.NewStream(c); res:=-1; num:=0;
		REPEAT
			INC(num);
			c.stream.Init(protocol, c.remoteAdr, c.localAdr, res);
		UNTIL (res=0) OR (num=maxFails);
		IF res=0 THEN
			c.p:=Parser.NewParser(c.stream); c.p.reportError:=XmlReportError;
			c.p.SetOpts({Parser.skipElementNotClosedError, Parser.allowManyRoots});
			c.g:=Gen.NewGenerator(c.stream);
			c.closed:=FALSE;
		ELSE 
			c.closed:=TRUE;
			c.owner.UpdateError(disconnected);
		END;
		XmlStream.ResetDir;
	END Open;
	
	PROCEDURE (c: StdConnection) LimitData (max: INTEGER);
	BEGIN
		c.stream.Limit(max);
	END LimitData;
	
	PROCEDURE (c : StdConnection) Connected() : BOOLEAN;
	BEGIN
		RETURN ~c.closed; 
	END Connected;
		
	PROCEDURE (c : StdConnection) Close;
	VAR res : INTEGER;
	BEGIN
		c.stream.Close;
		c.closed:=TRUE;
	END Close;
	
	PROCEDURE (c : StdConnection) WriteData(fragment : Entity; split : BOOLEAN);
	VAR x, data : ANYPTR; f : Dom.DocumentFragment;
	BEGIN
		ASSERT(fragment#NIL);
		data:=fragment.Data();
		WITH data : Items.Item DO
			XmlStream.InstallDir;
			c.g.fm:=Formatters.dir.NewFormatter(c.g.fm.wr);
			f:=doc.CreateDocumentFragment();
			x:=f.AppendChild(doc.ImportNode(data.Data()(Dom.Element), Dom.deep));
			c.g.Element(f, split);
			c.lastWrote:=f;
			XmlStream.ResetDir;
		ELSE HALT(100) END;
	END WriteData;
	
	PROCEDURE (c : StdConnection) Read;
	VAR n,n0 : Dom.Node;
	BEGIN
		IF LOG THEN Log.String(c.stream.ReadBuffer()); Log.Ln; Log.Ln; END;
		INC(c.readBytes, LEN(c.stream.ReadBuffer()$));
		c.p.scanner.ConnectTo(c.p.scanner.r);
		c.p.Parse;
		c.lastRead:=c.p.doc.CreateDocumentFragment();
		n:=c.p.doc.documentElement.firstChild;
		WHILE n#NIL DO
			n0:=c.lastRead(Dom.Node).AppendChild(n);
			n:=n.nextSibling;
		END;
		c.owner.UpdateRead(c.lastRead);
		Dom.Finalize(c.lastRead(Dom.Node));
		Services.Collect;
	END Read;
	
	PROCEDURE (c : StdConnection) Write();
	BEGIN
		IF LOG THEN Log.String(c.stream.WriteBuffer()); Log.Ln; Log.Ln; END;
		INC(c.wroteBytes, LEN(c.stream.WriteBuffer()$));
		c.owner.UpdateWrite(c.lastWrote);
		Dom.Finalize(c.lastWrote(Dom.Node));
		Services.Collect;
	END Write;
	
	PROCEDURE (c : StdConnection) Alert(error : INTEGER);
	BEGIN
		IF ~c.closed THEN
			CASE error OF
				XmlStream.disconnected  : c.owner.UpdateError(disconnected);
			ELSE END;
		END;
	END Alert;
		
	PROCEDURE (c : StdConnection) Init(owner : Owner; remoteAdr : ARRAY OF CHAR), NEW;
	BEGIN
		c.owner:=owner;
		c.localAdr:=localAdr$;
		c.remoteAdr:=remoteAdr$;
		c.readBytes:=0; c.wroteBytes:=0;
	END Init;
	
	PROCEDURE (d : StdDirectory) NewConnection(owner : Owner; remoteAdr : ARRAY OF CHAR) : Connection;
	VAR c : StdConnection;
	BEGIN
		NEW(c);
		c.Init(owner, remoteAdr);
		RETURN c;
	END NewConnection;
	
	PROCEDURE SetDir*(d : Directory);
	BEGIN
		dir:=d
	END SetDir;
	
	PROCEDURE InitDriver*(proto, locAdr : ARRAY OF CHAR);
	BEGIN
		protocol:=proto$;
		localAdr:=locAdr$;
	END InitDriver;
	
	PROCEDURE GetDataLength*(c: Connection; OUT in, out: LONGINT);
	BEGIN
		WITH c: StdConnection DO
			in:=c.readBytes; out:=c.wroteBytes;
		ELSE in:=0; out:=0; END;
	END GetDataLength;
	
	PROCEDURE Init;
	VAR d : StdDirectory;
	BEGIN
		NEW(d);
		dir:=d; stdDir:=d;
		doc:=Dom.impl.CreateXmlDocument('','',NIL);
		InitDriver('CommTCP', '0.0.0.0:0');
	END Init;
		
BEGIN
	Init	
END XmppConnections.