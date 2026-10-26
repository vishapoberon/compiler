MODULE XmppIbb;
(**	project	= "XMPP"
	organization	= ""
	contributors	= ""
 	purpose	= "???????? ?????????? XEP 0047"
	changes	= "
	- , nn, ...
	"
	issues	= ""
**)

	IMPORT Core := XmppCore, Items:=XmlcoreItems, Const:=XmppConst, Log, Stuff:=XmppStuff,  DS:=StringsDyn, Strings, Base64:=ypkEncBase64, Files, Rand:=ypkMathRandom;
	
	CONST
		defaultBlockSize*=1024;
		INITIAL = -1;
		INBAND = 'inband';
		URI_IBB = 'http://jabber.org/protocol/ibb';
		OPEN = 'open';
		SID = 'sid';
		BLOCKSIZE = 'block-size';
		DATA = 'data';
		SEQ = 'seq';
		CLOSE_IQ = 'close';
		streamError* = -1;	
		withVerify* = TRUE;
		noVerify* = FALSE;
		
	TYPE
		DynString = DS.DynString;
		
		Directory* = POINTER TO RECORD(Core.ExtensionDir) END;
		
		Ibb* = POINTER TO LIMITED RECORD (Core.Extension)
			valid- : BOOLEAN;
			hook : Hook;
			list : Stuff.List;
		END;	
		
		Hook* = POINTER TO ABSTRACT RECORD END;
		
		Rider = POINTER TO ABSTRACT RECORD 
			to, from : POINTER TO ARRAY OF CHAR;
			owner : Ibb;
			id, sid : ARRAY 24 OF CHAR;
			blockSize : INTEGER;
			seq : INTEGER;
			buf : DynString;
			wait : BOOLEAN;
		END;
		
		Reader = POINTER TO RECORD (Rider)
			len, pos : INTEGER;
			rd : Files.Reader;
			eof : BOOLEAN;
		END;
		
		Writer = POINTER TO RECORD (Rider)
			wr : Files.Writer;
		END;
		
		OpenIq = POINTER TO RECORD(Core.Iq)
			this : Rider;
		END;
		
		AcceptIq = POINTER TO RECORD(Core.Iq) END;
		
		DataIq = POINTER TO RECORD(Core.Iq) this : Rider END;
		
		CloseIq = POINTER TO RECORD(Core.Iq) this : Rider END;
		
	VAR
		dir- : Directory;
		
	PROCEDURE (h : Hook) Incoming- (ibb : Ibb; sid, from : ARRAY OF CHAR; VAR wr : Files.Writer; VAR verify : BOOLEAN) : BOOLEAN, NEW, ABSTRACT;
	PROCEDURE (h : Hook) Receiving- (ibb : Ibb; sid, from : ARRAY OF CHAR; file : Files.File; VAR cancel : BOOLEAN), NEW, ABSTRACT;
	PROCEDURE (h : Hook) Transmitting- (ibb : Ibb; sid, to : ARRAY OF CHAR; pos : INTEGER; VAR cancel : BOOLEAN), NEW, ABSTRACT;
	PROCEDURE (h : Hook) Transmitted- (ibb : Ibb; sid, to : ARRAY OF CHAR), NEW, ABSTRACT;
	PROCEDURE (h : Hook) Received- (ibb : Ibb; sid, from : ARRAY OF CHAR; file : Files.File), NEW, ABSTRACT;
	
	PROCEDURE Incoming (ibb : Ibb; sid, from : ARRAY OF CHAR; VAR wr : Files.Writer; VAR confirm : BOOLEAN) : BOOLEAN;
	BEGIN
		IF ibb.hook#NIL THEN
				RETURN ibb.hook.Incoming(ibb, sid, from, wr, confirm);
		END;
		RETURN FALSE;
	END Incoming;
	
	PROCEDURE Receiving (ibb : Ibb; sid, from : ARRAY OF CHAR; file : Files.File; VAR cancel : BOOLEAN);
	BEGIN
		IF ibb.hook#NIL THEN
			ibb.hook.Receiving(ibb, sid, from, file, cancel);
		END;
	END Receiving;
	
	PROCEDURE Transmitting (ibb : Ibb; sid, to : ARRAY OF CHAR; pos : INTEGER; VAR cancel : BOOLEAN);
	BEGIN
		IF ibb.hook#NIL THEN
			ibb.hook.Transmitting(ibb, sid, to, pos, cancel);
		END;
	END Transmitting;
	
	PROCEDURE Transmitted (ibb : Ibb; sid, to : ARRAY OF CHAR);
	BEGIN
		IF ibb.hook#NIL THEN
			ibb.hook.Transmitted(ibb, sid, to);
		END;
	END Transmitted;
	
	PROCEDURE Received (ibb : Ibb; sid, from : ARRAY OF CHAR; file : Files.File);
	BEGIN
		IF ibb.hook#NIL THEN
			ibb.hook.Received(ibb, sid, from, file);
		END;
	END Received;
	
	PROCEDURE (r : Reader) Read, NEW;
	VAR read : INTEGER;
	BEGIN
		IF ~r.eof THEN
			Base64.EncodeFile(r.rd, r.blockSize, r.buf, read);
			r.eof:=(r.rd.Pos()-r.pos)>=r.len;
			INC(r.seq);
		END;
	END Read;
	
	PROCEDURE (w : Writer) Write, NEW;
	VAR written : INTEGER;
	BEGIN
		Base64.DecodeFile(w.buf, w.wr, written);
	END Write;
	
	PROCEDURE FindBySID(ibb : Ibb; sid : ARRAY OF CHAR; VAR s : Rider) : BOOLEAN;
	VAR i : INTEGER; ok : BOOLEAN;
	BEGIN
		i:=0; ok:=FALSE;
		WHILE (i<ibb.list.Length()) & ~ok DO
			ok:=ibb.list.Item(i)(Rider).sid$=sid$;
			IF ok THEN s:=ibb.list.Item(i)(Rider) END;
			INC(i);
		END;
		RETURN ok;
	END FindBySID;
	
	PROCEDURE FindByID(ibb : Ibb; id : ARRAY OF CHAR; VAR s : Rider) : BOOLEAN;
	VAR i : INTEGER; ok : BOOLEAN;
	BEGIN
		i:=0; ok:=FALSE;
		WHILE (i<ibb.list.Length()) & ~ok DO
			ok:=ibb.list.Item(i)(Rider).id$=id$;
			IF ok THEN s:=ibb.list.Item(i)(Rider) END;
			INC(i);
		END;
		RETURN ok;
	END FindByID;
	
	PROCEDURE AcceptStream(ibb : Ibb; rider : Rider);
	VAR ai : AcceptIq;
	BEGIN
		ibb.list.Add(rider);
		NEW(ai);
		ai.Set(rider.from, rider.to, '', rider.id, Const.result);
		ibb.owner.Send(ai);
	END AcceptStream;
	
	PROCEDURE FillStream(ibb : Ibb; rd : Reader);
	VAR di : DataIq;
	BEGIN
		NEW(di);
		di.Set(rd.to, rd.from, '', rd.id, Const.set);
		di.this:=rd;
		ibb.owner.Send(di);
	END FillStream;
	
	PROCEDURE CloseStream (ibb : Ibb; rider : Rider);
	VAR ciq : CloseIq;
	BEGIN
		NEW(ciq);
		ciq.this:=rider;
		ciq.Set(rider.to, rider.from, '', rider.id, Const.set);
		ibb.owner.Send(ciq);
		IF ~rider.wait THEN ibb.list.Remove(rider) END;
	END CloseStream;
	
	PROCEDURE (ai : AcceptIq) Do() : Items.Item;
	VAR n: Items.Item;
	BEGIN
		n:=Items.New(Const.iq);
		RETURN n;		
	END Do;
	
	PROCEDURE (di : DataIq) Do() : Items.Item;
	VAR n, n1 : Items.Item;
	BEGIN
		n:=Items.New(Const.iq);
		n1:=Items.New(DATA);
		di.this(Reader).Read;
		n1.SetParam(Const.xmlns, URI_IBB); n1.SetParam(SID, di.this.sid);
		n1.SetIntParam(SEQ, di.this.seq);
		n1.SetData(di.this.buf.String());
		n.Add(n1);
		RETURN n;		
	END Do;
	
	PROCEDURE (di : DataIq) Use(data : Items.Item);
	VAR n, n1: Items.Item; wr : Writer;
	BEGIN
		di.this.to:=DS.Create(di.to).String();
		di.this.from:=DS.Create(di.from).String();
		di.this.id:=di.id$;
		n:=data.First();
		ASSERT(n#NIL); ASSERT(n.GetName()$=DATA);
		di.this.sid:=n.GetParam(SID)$;
		ASSERT(n.GetIntParam(SEQ, di.this.seq));
		di.this.buf:=DS.Create(n.GetData());
		di.this(Writer).Write;
	END Use;
	
	PROCEDURE (oi : OpenIq) Do() : Items.Item;
	VAR n, n1: Items.Item;
	BEGIN
		n:=Items.New(Const.iq);
		n1:=Items.New(OPEN);
		n1.SetParam(Const.xmlns, URI_IBB);
		n1.SetParam(SID, oi.this.sid);
		n1.SetIntParam(BLOCKSIZE, oi.this.blockSize);
		n.Add(n1);
		RETURN n;		
	END Do;
	
	PROCEDURE (oi : OpenIq) Use(data : Items.Item);
	VAR n: Items.Item; wr : Writer;
	BEGIN
		NEW(wr);
		oi.this:=wr;
		oi.this.to:=DS.Create(oi.to).String();
		oi.this.from:=DS.Create(oi.from).String();
		oi.this.id:=oi.id$;
		n:=data.First();
		ASSERT(n#NIL); ASSERT(n.GetName()$=OPEN);
		oi.this.sid:=n.GetParam(SID)$;
		ASSERT(n.GetIntParam(BLOCKSIZE, oi.this.blockSize));
		wr.seq:=0;
	END Use; 
	
	PROCEDURE (ci : CloseIq) Do() : Items.Item;
	VAR n, n1 :Items.Item;
	BEGIN
		n:=Items.New(Const.iq);
		n1:=Items.New(CLOSE_IQ);
		n1.SetParam(Const.xmlns, URI_IBB);
		n1.SetParam(SID, ci.this.sid);
		n.Add(n1);
		RETURN n;		
	END Do;
	
	PROCEDURE (ci : CloseIq) Use(data : Items.Item);
	VAR n : Items.Item; res : INTEGER; 
	BEGIN
		ci.this.to:=DS.Create(ci.to).String();
		ci.this.from:=DS.Create(ci.from).String();
		ci.this.id:=ci.id$;
		n:=data.First();
		ASSERT(n#NIL); ASSERT(n.GetName()$=OPEN);
		ci.this.sid:=n.GetParam(SID)$;
	END Use;
	
	PROCEDURE (ibb : Ibb) Iq-(data : Items.Item; VAR res : INTEGER);
	VAR n : Items.Item; oiq : OpenIq; diq : DataIq; ciq : CloseIq; s : Rider; accept, cancel : BOOLEAN;
	BEGIN
		n:=data.First();
		WHILE n#NIL DO
			IF n.GetName()$=Const.session THEN
				ibb.valid:=TRUE;						
			ELSIF (n.GetParam(Const.xmlns)$=URI_IBB) & (data.NofItems() = 1) THEN
				IF (n.GetName()$=OPEN) THEN
					NEW(oiq); 
					oiq.Init(data);
					accept := Incoming(ibb, oiq.this.sid, oiq.from, oiq.this(Writer).wr , oiq.this.wait);
					IF accept THEN
						ASSERT(oiq.this(Writer).wr#NIL);
						AcceptStream(ibb, oiq.this);
					END;
				ELSIF (n.GetName()$=DATA) THEN
					IF FindBySID(ibb, n.GetParam(SID)$, s) THEN
						NEW(diq); diq.this:=s;
						ASSERT(diq.this(Writer).wr#NIL);
						diq.Init(data);
						Receiving(ibb, diq.this.sid, diq.from, diq.this(Writer).wr.Base(), cancel);
						IF s.wait THEN
							AcceptStream(ibb, diq.this);
						END;
						IF cancel THEN
							CloseStream(ibb, diq.this);
							Received(ibb, diq.this.sid, data.GetParam(Const.from)$, diq.this(Writer).wr.Base());		
						END;
					END;
					
				ELSE END;
			END;
			n:=data.Next(n);
		END;
		IF (data.GetParam(Const.type)$=Const.result) THEN
			IF FindByID(ibb, data.GetParam(Const.id)$, s) & s.wait THEN
				IF ~s(Reader).eof THEN 
					FillStream(ibb, s(Reader));
					Transmitting(ibb, s.sid, data.GetParam(Const.from)$, s(Reader).rd.Pos(), cancel);
				ELSE 
					Transmitted(ibb, s.sid, data.GetParam(Const.from)$);
					ibb.list.Remove(s);
				END;
			END;
		END;
	res:=Core.continue;
	END Iq;
	
	PROCEDURE (ibb : Ibb) Wrote-(data : Items.Item);
	VAR n: Items.Item; s : Rider; accept, cancel, verify : BOOLEAN; wr : Files.Writer;
	BEGIN 
		IF (data.GetName()$=Const.iq) & (data.GetParam(Const.type)$=Const.set) THEN
			n:=data.First(); 
			IF (n#NIL) & (FindBySID(ibb, n.GetParam(SID)$, s)) & ~s.wait THEN
				IF ~s(Reader).eof  THEN FillStream(ibb, s(Reader));
					Transmitting(ibb, s.sid, data.GetParam(Const.to)$, s(Reader).rd.Pos(), cancel);
				ELSE
					Transmitted(ibb, s.sid, data.GetParam(Const.to)$);
					ibb.list.Remove(s);
				END;
			END;
	ELSE END; 
	END Wrote;
	
	PROCEDURE OpenStream(ibb : Ibb; reader : Reader);
	VAR oiq : OpenIq;
	BEGIN
		NEW(oiq);
		oiq.this:=reader;
		oiq.Set(oiq.this.to, oiq.this.from, '', oiq.this.id, Const.set);
		ibb.owner.Send(oiq);
	END OpenStream;
	
	PROCEDURE (ibb : Ibb) Send*(from, to : ARRAY OF CHAR; rd : Files.Reader; len, blockSize : INTEGER; verify : BOOLEAN; VAR sid : ARRAY OF CHAR), NEW;
	VAR r : Reader;
	BEGIN
		ASSERT(ibb.valid);
		ASSERT(rd#NIL);
		ASSERT(~rd.eof);
		ASSERT(to#'');
		ASSERT(from#'');
		ASSERT(rd.Pos()+len<=rd.Base().Length());
		NEW(r);
		r.owner:=ibb;
		r.wait:=verify;
		r.to:=DS.Create(to$).String();
		r.from:=DS.Create(from$).String();
		IF sid$='' THEN 
			Rand.UniRandStr(r.sid,10);
			r.sid:=INBAND+'_'+r.sid$;
			sid:=r.sid$;
		ELSE r.sid:=sid$ END;	
		Rand.UniRandStr(r.id,10);
		r.id:=INBAND+'_'+r.id$;
		r.blockSize:=blockSize;
		r.rd:=rd;
		r.pos:=r.rd.Pos();
		r.len:=len;
		r.seq:=-1;
		ibb.list.Add(r);
		OpenStream(ibb, r);
	END Send;
	
	PROCEDURE (ibb : Ibb) SetHook*(h : Hook), NEW;
	BEGIN
		ibb.hook:=h;
	END SetHook;
	
	PROCEDURE (ibb : Ibb) Start-;
	BEGIN
		ibb.valid:=TRUE;
	END Start;
	
	PROCEDURE (ibb : Ibb) Stop-;
	BEGIN
		ibb.valid:=FALSE;
	END Stop;

	PROCEDURE (d : Directory)Create-(session : Core.Session) : Core.Extension;
	VAR ibb : Ibb;
	BEGIN
		NEW(ibb);
		ibb.valid:=FALSE;
		ibb.list:=Stuff.CreateList();
		RETURN ibb;
	END Create;

	PROCEDURE Init;
	VAR d : Directory;
	BEGIN
		NEW(d);
		dir:=d;
	END Init;

BEGIN
	Init	
END XmppIbb.