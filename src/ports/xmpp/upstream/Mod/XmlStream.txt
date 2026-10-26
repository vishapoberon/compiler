MODULE XmppXmlStream;
(**	project	= "XMPP"
	organization	= ""
	contributors	= ""
	purpose	= "???????? ?????????? ????????? XMPP http://xmpp.org/"
	changes	= "
	- , nn, ...
	-20120531, ?????? ?????????????? ????? ?????? ??? ???????????? ???????? ?? ?????
	"
	issues	= ""
**)
	IMPORT XmlcoreScanner, XmlcoreFormatters, Services, DS:=StringsDyn, CommStreams, ListsIterable, Log;

	CONST
		disconnected*=-1;
		
	TYPE
		DynString = DS.DynString;
		String = ARRAY OF CHAR;
		
		BufferItem = POINTER TO RECORD (ListsIterable.IteratorItem)
			s: DynString;
		END;
		
		Buffer = RECORD
			queue: ListsIterable.Iterator;
			this: BufferItem;
			prev_ts, next_ts: LONGINT;
			max, count: INTEGER;
		END;
		
		Owner* = POINTER TO ABSTRACT RECORD END;
		
		Stream* = POINTER TO ABSTRACT RECORD END;
		
		StdStream = POINTER TO RECORD (Stream)
			owner : Owner;
			base : CommStreams.Stream;
			readBuf, writeBuf : DynString;
			limit: INTEGER;
		END;
		
		Directory* = POINTER TO ABSTRACT RECORD END;
		StdDirectory = POINTER TO RECORD(Directory) END;
		
		StreamSDirectory = POINTER TO RECORD(XmlcoreScanner.Directory) END; (* ?????????? ??????? *)
		StreamFDirectory = POINTER TO RECORD(XmlcoreFormatters.Directory) END; (* ?????????? ??????? *)
		
		StreamReader = POINTER TO RECORD (XmlcoreScanner.Reader) 
			stream : Stream;
			pos : INTEGER;
			buf : DynString;
			action : ReadAction;
		END;
		
		StreamWriter = POINTER TO RECORD (XmlcoreFormatters.Writer) 
			stream : Stream;
			buf : Buffer;
			action : WriteAction;
		END;
		
		ReadAction = POINTER TO RECORD(Services.Action) 
			rd : StreamReader;
			reading : BOOLEAN;
		END;
		
		WriteAction = POINTER TO RECORD(Services.Action) 
			wr : StreamWriter;
		END;
		
		AlertAction = POINTER TO RECORD(Services.Action) 
			stream : Stream;
		END;
		
		RawAction = POINTER TO RECORD(Services.Action) 
			stream : Stream;
			buf : DynString;
		END;
		
		ABYTE = ARRAY 256000 OF BYTE;
		
	VAR	
		dir-, stdDir : Directory;
		dummy: DynString;
(********************************************************************************)
	PROCEDURE (o : Owner) Read-, NEW, ABSTRACT;
	PROCEDURE (o : Owner) Write-, NEW, ABSTRACT;
	PROCEDURE (o : Owner) Alert-(error : INTEGER), NEW, ABSTRACT;

	PROCEDURE (d : Directory) NewStream*(owner : Owner) : Stream, NEW, ABSTRACT;

	PROCEDURE (s : Stream) SetReadBuffer-(buffer : ARRAY OF CHAR), NEW, ABSTRACT;
	PROCEDURE (s : Stream) SetWriteBuffer-(buffer : ARRAY OF CHAR), NEW, ABSTRACT;
	PROCEDURE (s : Stream) ReadBuffer*() : POINTER TO ARRAY OF CHAR, NEW, ABSTRACT;
	PROCEDURE (s : Stream) WriteBuffer*() : POINTER TO ARRAY OF CHAR, NEW, ABSTRACT;
	PROCEDURE (s : Stream) Base*() : ANYPTR, NEW, ABSTRACT;
	PROCEDURE (s : Stream) Owner*() : Owner, NEW, ABSTRACT;
	PROCEDURE (s : Stream) Init* (protocol, remoteAdr, localAdr : ARRAY OF CHAR; OUT res : INTEGER), NEW, ABSTRACT;
	PROCEDURE (s : Stream) Close*, NEW, ABSTRACT;
	PROCEDURE (s : Stream) Raw*(raw : ARRAY OF CHAR), NEW, ABSTRACT;
	PROCEDURE (s : Stream) Limit* (max: INTEGER), NEW, ABSTRACT;
	
	PROCEDURE (s : StdStream) SetReadBuffer-(buffer : ARRAY OF CHAR);
	BEGIN
		s.readBuf:=DS.Create(buffer);
	END SetReadBuffer;
	
	PROCEDURE (s : StdStream) SetWriteBuffer(buffer : ARRAY OF CHAR);
	BEGIN
		s.writeBuf:=DS.Create(buffer);
	END SetWriteBuffer;
	
	PROCEDURE (s : StdStream) ReadBuffer() : POINTER TO ARRAY OF CHAR;
	BEGIN
		RETURN s.readBuf.String();
	END ReadBuffer;
	
	PROCEDURE (s : StdStream) WriteBuffer() : POINTER TO ARRAY OF CHAR;
	BEGIN
		RETURN s.writeBuf.String();
	END WriteBuffer;
	
	PROCEDURE (s : StdStream) Base() : ANYPTR;
	BEGIN
		RETURN s.base;
	END Base;
	
	PROCEDURE (s : StdStream) Owner() : Owner;
	BEGIN
		RETURN s.owner;
	END Owner;
	
	PROCEDURE (s : StdStream) Init (protocol, remoteAdr, localAdr : ARRAY OF CHAR; OUT res : INTEGER);
	VAR a : AlertAction;
	BEGIN
		CommStreams.NewStream(protocol, localAdr, remoteAdr, s.base, res);
		IF res=CommStreams.done THEN
			NEW(a); a.stream:=s;
			Services.DoLater(a, Services.Ticks()+2*Services.resolution);
		ELSE Log.String('no socket on '); Log.String(remoteAdr); Log.Ln; END;
		s.readBuf:=DS.Create(''); s.writeBuf:=DS.Create('');
		s.limit:=0;
	END Init;
	
	PROCEDURE (s : StdStream) Close;
	BEGIN
		s.base.Close;
	END Close;
	
	PROCEDURE (s : StdStream) Raw(raw : ARRAY OF CHAR);
	VAR a : RawAction;
	BEGIN
		s.writeBuf:=DS.Create(raw);
		NEW(a); a.buf:=s.writeBuf; a.stream:=s; Services.DoLater(a, Services.now);
	END Raw;
	
	PROCEDURE (s: StdStream) Limit (max: INTEGER);
	BEGIN
		s.limit:=max;
	END Limit;
	
	(* ???? ? ??????? *)
	PROCEDURE (VAR b: Buffer) Limit(max: INTEGER), NEW;
	BEGIN
		b.max:=max;
		IF max=0 THEN b.next_ts:=0; b.prev_ts:=0; ELSE b.prev_ts:=Services.Ticks(); b.next_ts:=Services.Ticks() END
	END Limit;
	
	PROCEDURE (VAR b: Buffer) Limited(): BOOLEAN, NEW;
	BEGIN
		RETURN (b.max>0) & (Services.Ticks()<=b.next_ts);
	END Limited;
	
	PROCEDURE (VAR b: Buffer) Drop, NEW;
		VAR x: ANYPTR;
	BEGIN 
		x:=b.queue.first;
		IF x#NIL THEN
			b.queue.Remove(x(ListsIterable.IteratorItem));
		END;
	END Drop;
		
	PROCEDURE (VAR b: Buffer) Inc, NEW;
		VAR x: ANYPTR; len: INTEGER; i: BufferItem;
	BEGIN
		len:=b.this.s.Length();
		 IF (len>0) & (len<=b.max) THEN
			b.queue.Insert(b.this, b.queue.first); 
		ELSIF (len>b.max) THEN
			b.queue.Add(b.this);
		END; 
		IF len>0 THEN
		 	(* b.queue.Add(b.this); *)
			NEW(b.this); b.this.s:=DS.Create('');
		END;
	END Inc;
	
	PROCEDURE (VAR b: Buffer) Get(): DynString, NEW;
		VAR x: ANYPTR; res: DynString;
		
		PROCEDURE Next(len: INTEGER);
		BEGIN
			INC(b.count, len);
			IF b.Limited() & (len>b.max) THEN 
				b.next_ts:=Services.Ticks()+(1000*((b.count DIV b.max)+1));
				b.count:=0;
			ELSE 
				b.next_ts:=0;
			END;
			b.prev_ts:=Services.Ticks();
		END Next;
		
	BEGIN
		res:=dummy;
		x:=b.queue.first;
		IF (x#NIL) & ~b.Limited() THEN
			WITH x: BufferItem DO
				res:=x.s; 
			ELSE END;
		ELSIF (x=NIL) THEN
			b.Inc;
		END;
		Next(res.Length());
		RETURN res
	END Get;
	
	PROCEDURE (VAR b: Buffer) Init, NEW;
	BEGIN
		b.queue:=ListsIterable.NewIterator();
		b.max:=0; b.next_ts:=0; b.count:=0;
		NEW(b.this); b.this.s:=DS.Create('');
	END Init;
	
	PROCEDURE (VAR b: Buffer) AddChar(ch: CHAR), NEW;
		VAR x: ANYPTR;
	BEGIN
		b.this.s.AddChar(ch);
	END AddChar;
	
	PROCEDURE SendRecieveMsg(stream : Stream);
	BEGIN
		stream.Owner().Read;
	END SendRecieveMsg;
	
	PROCEDURE SendTransmitMsg(stream : Stream);
	BEGIN
		stream.Owner().Write;
	END SendTransmitMsg;
	
	PROCEDURE ConvertToByte(str : DynString; VAR x : ABYTE; OUT len : INTEGER);
	VAR pos : INTEGER; ch : CHAR;
	BEGIN	(* UTF-8 format *)
		pos:=0; len:=0;
		WHILE (pos<str.Length()) DO
		ch:=str.Char(pos);
			IF ch <= 7FX THEN
				x[len]:=(SHORT(SHORT(ORD(ch)))); INC(len)
			ELSIF ch <= 7FFX THEN
				x[len]:=(SHORT(SHORT(-64 + ORD(ch) DIV 64))); INC(len);
				x[len]:=(SHORT(SHORT(-128 + ORD(ch) MOD 64))); INC(len)
			ELSE
				x[len]:=(SHORT(SHORT(-32 + ORD(ch) DIV 4096))); INC(len);
				x[len]:=(SHORT(SHORT(-128 + ORD(ch) DIV 64 MOD 64))); INC(len);
				x[len]:=(SHORT(SHORT(-128 + ORD(ch) MOD 64))); INC(len)
			END; 			
		INC(pos);
		END;
	END ConvertToByte;
	
	PROCEDURE ConvertFromByte(VAR x : ABYTE; str : DynString; len : INTEGER);
	VAR c1, c2, c3: BYTE; ch : CHAR; pos : INTEGER;
	BEGIN
		ASSERT(str#NIL); 
		pos:=0; 
		WHILE pos<len DO
			c1:=x[pos]; INC(pos);
			ch := CHR(c1);
			IF c1 < 0 THEN
				c2:=x[pos]; INC(pos);
				ch := CHR(64 * (c1 MOD 32) + (c2 MOD 64));
				IF c1 > - 32 THEN
					c3:=x[pos]; INC(pos);
					ch := CHR(4096 * (c1 MOD 16) + 64 * (c2 MOD 64) + (c3 MOD 64));
				END;
			END;
			str.AddChar(ch);
		END;
	END ConvertFromByte;
	
	PROCEDURE (a : WriteAction) Do;
		VAR tmp: DynString; buf : ABYTE; len, written, i : INTEGER; 
	BEGIN
		len:=0; written:=0;
		IF a.wr.stream.Base()(CommStreams.Stream).IsConnected() THEN
			tmp:=a.wr.buf.Get();
			ConvertToByte(tmp, buf, len);
			IF len>0 THEN
				a.wr.stream.Base()(CommStreams.Stream).WriteBytes(buf, 0, len, written);  
				IF written#0 THEN 
					ASSERT(written=len,22); 
					a.wr.buf.Drop;
					a.wr.buf.Limit(a.wr.stream(StdStream).limit);
					a.wr.stream.SetWriteBuffer(tmp.String()); 
					SendTransmitMsg(a.wr.stream);
				ELSE END;
			END;
			Services.DoLater(a, Services.Ticks()+100);
		ELSE END
	END Do;
	
	PROCEDURE (a : ReadAction) Do;
	VAR buf : ABYTE; x : DynString; len, written, read, i : INTEGER; 
	BEGIN
		read:=0; len:=0;
		IF a.rd.stream.Base()(CommStreams.Stream).IsConnected() THEN
			a.rd.stream.Base()(CommStreams.Stream).ReadBytes (buf, 0, LEN(buf)-1, read);
			IF (read#0) & ~a.reading THEN
				a.rd.buf.Clear;
				ConvertFromByte(buf, a.rd.buf, read);
				a.reading:=TRUE;
			ELSIF (read#0) & a.reading THEN
				x:=DS.Create('');
				ConvertFromByte(buf, x, read);
				a.rd.buf.AddString(x.String());	
			ELSIF (read=0) & a.reading  & (a.rd.buf.Char(a.rd.buf.Length()-1)='>') THEN
				a.rd.stream.SetReadBuffer(a.rd.buf.String());
				SendRecieveMsg(a.rd.stream);
				a.rd.buf.Clear;
				a.reading:=FALSE;
			END;
			Services.DoLater(a, Services.now);
		ELSE END
	END Do;
	
	PROCEDURE (rd : StreamReader) Start, NEW;
	BEGIN
		NEW(rd.action); rd.action.rd:=rd; rd.action.reading:=FALSE;
		Services.DoLater(rd.action, Services.now);
	END Start;
	
	PROCEDURE (rd : StreamReader) ConnectTo(source : ANYPTR);
	BEGIN
		ASSERT(source IS Stream);
		rd.stream:=source(Stream); 
		rd.buf:=DS.Create('<?xml version="1.0">'); rd.pos:=0;
		rd.Start;
	END ConnectTo;

	PROCEDURE (rd : StreamReader) ReadChar;
	BEGIN
		INC(rd.pos);
	END ReadChar;

	PROCEDURE (rd : StreamReader) SetPos(pos : INTEGER);
	BEGIN
		rd.pos:=pos;
	END SetPos;

	PROCEDURE (rd : StreamReader) Eof():BOOLEAN;
	BEGIN
		RETURN rd.pos>=rd.buf.Length();
	END Eof;

	PROCEDURE (rd : StreamReader) Char():CHAR;
	BEGIN
		RETURN rd.buf.Char(rd.pos-1);
	END Char;
	
	PROCEDURE (wr : StreamWriter) Start, NEW;
	BEGIN
		NEW(wr.action); wr.action.wr:=wr;
		Services.DoLater(wr.action, Services.now);
	END Start;
	
	PROCEDURE (wr : StreamWriter) ConnectTo(target : ANYPTR);
	BEGIN
		ASSERT(target IS Stream);
		wr.stream:=target(Stream); 
		wr.buf.Init; wr.buf.Limit(target(StdStream).limit);
		wr.Start; 
	END ConnectTo;

	PROCEDURE (wr : StreamWriter) Char (ch: CHAR);
	BEGIN
		wr.buf.AddChar(ch);
	END Char;
	
	PROCEDURE (wr: StreamWriter) String (IN str: ARRAY OF CHAR);
		VAR i: INTEGER; ch: CHAR;
	BEGIN
		i := 0; ch := str[0];
		WHILE ch # 0X DO wr.Char(ch); INC(i); ch := str[i] END
	END String;

	PROCEDURE (d : StreamSDirectory) NewScanner(rd : XmlcoreScanner.Reader) : XmlcoreScanner.Scanner;
	BEGIN
		RETURN XmlcoreScanner.stdDir.NewScanner(rd);
	END NewScanner;

	PROCEDURE (d : StreamSDirectory) NewReader(source : ANYPTR) : XmlcoreScanner.Reader;
	VAR rd : StreamReader;
	BEGIN
		ASSERT(source#NIL);
		NEW(rd);
		rd.ConnectTo(source);
		RETURN rd;
	END NewReader;

	PROCEDURE (d : StreamFDirectory) NewFormatter (wr: XmlcoreFormatters.Writer): XmlcoreFormatters.Formatter;
	BEGIN
		WITH wr: StreamWriter DO
			wr.buf.Inc;
		ELSE END;
		RETURN XmlcoreFormatters.stdDir.NewFormatter(wr);
	END NewFormatter;
	
	PROCEDURE (d : StreamFDirectory) NewWriter(target: ANYPTR) : XmlcoreFormatters.Writer;
	VAR wr : StreamWriter;
	BEGIN
		NEW(wr);
		wr.ConnectTo(target);
		RETURN wr;
	END NewWriter;
	
	PROCEDURE (a : AlertAction) Do;
	BEGIN
		IF a.stream.Base()(CommStreams.Stream).IsConnected() THEN
			Services.DoLater(a, Services.Ticks()+2*Services.resolution);
		ELSE
			a.stream.Owner().Alert(disconnected);
		END
	END Do;
	
	PROCEDURE (a : RawAction) Do;
	VAR buf : ABYTE; len, written, i : INTEGER;
	BEGIN
		IF a.stream.Base()(CommStreams.Stream).IsConnected() THEN
			ConvertToByte(a.buf, buf, len);
			IF len>0 THEN
				a.stream.Base()(CommStreams.Stream).WriteBytes(buf, 0, len, written);  
				IF written#0 THEN ASSERT(written=len,22); a.stream.SetWriteBuffer(a.buf.String()) END;
			END;
		ELSE
		END
	END Do;
	
	PROCEDURE (d : StdDirectory) NewStream(owner : Owner) : Stream;
	VAR s : StdStream;
	BEGIN
		NEW(s);
		s.owner:=owner;
		RETURN s;
	END NewStream;
	
	PROCEDURE InstallDir*;
	VAR sd : StreamSDirectory; fd : StreamFDirectory;
	BEGIN
		NEW(sd); NEW(fd);
		XmlcoreScanner.SetDir(sd);
		XmlcoreFormatters.SetDir(fd);
	END InstallDir;
	
	PROCEDURE ResetDir*;
	BEGIN
		XmlcoreScanner.SetDir(XmlcoreScanner.stdDir);
		XmlcoreFormatters.SetDir(XmlcoreFormatters.stdDir);
	END ResetDir;
	
	PROCEDURE SetDir*(d : Directory);
	BEGIN
		dir:=d
	END SetDir;

	PROCEDURE Init;
	VAR d : StdDirectory;
	BEGIN
		NEW(d);
		dir:=d; stdDir:=d;
		dummy:=DS.Create('');
	END Init;

BEGIN
	Init;	

CLOSE
	XmlcoreScanner.SetDir(XmlcoreScanner.stdDir);
	XmlcoreFormatters.SetDir(XmlcoreFormatters.stdDir);
END XmppXmlStream.