MODULE XmppObx;
(**	project	= "Xmpp"
	organization	= ""
	contributors	= ""
 	purpose	= ""
	changes	= "
	- , nn, ...
	"
	issues	= ""
	selectors	= ??????????
**)

	IMPORT S:=XmppSession, Cmds:=XmppCmds, Console:=XmppConsole, Dialog, AbfBus, Services, Strings, Linear:= ListsLinear, Files, StdLog;
	
	TYPE
		Msg* = POINTER TO RECORD (S.BusMsg) 
			dlg* : RECORD
				user*, server*, pwd*, res*, remoteAdr*, to* : Dialog.String;
			END;
			x* : INTEGER; y* : REAL; z* : SET; u* : BOOLEAN;
			v* : ARRAY 4 OF ARRAY 3 OF ARRAY 4 OF RECORD x* :INTEGER; y* : REAL END;
			d* : LONGINT;
			j* : CHAR;
		END;
			
		Msg2* = RECORD (S.BusMsg)
			title*, content*: Dialog.String;
		END;
		
	VAR
		dlg* : RECORD
			user*, server*, pwd*, res*, remoteAdr*: Dialog.String;
			 to*: Dialog.Combo;
			in*, out-: ARRAY 2048 OF CHAR;
		END;
		rec : RECORD
			s : S.Session;
			fn: Files.Name;
		END;
	
	PROCEDURE FillRoster(list: Linear.List);
	VAR i: INTEGER; it: S.RosterItem;
	BEGIN
		i:=0; dlg.to.SetLen(list.len);
		WHILE i<list.len DO it:=list.GetItem(i)(S.RosterItem); dlg.to.SetItem(i, it.jid$); INC(i) END;
		Dialog.UpdateList(dlg.to);
	END FillRoster;
	
	PROCEDURE InGuard*(VAR par: Dialog.Par);
	BEGIN
		par.disabled:=(dlg.in$='');
	END InGuard;
		
	PROCEDURE Log*(str: ARRAY OF CHAR);
	BEGIN
		IF LEN(dlg.out$)+LEN(str$)>=LEN(dlg.out) THEN
			Strings.Extract(dlg.out, 0, 100, dlg.out);
		END;
		dlg.out:=str$+CHR(13)+dlg.out$;
		Dialog.UpdateString(dlg.out);
	END Log;
	
	PROCEDURE Ready(): BOOLEAN;
	BEGIN
		RETURN (rec.s#NIL) & (rec.s.s#NIL) & rec.s.s.Authorized() & (dlg.to.item#'');
	END Ready;
	
	PROCEDURE SendMsg2*;
	VAR m: Msg2; res: INTEGER;
	BEGIN
		Strings.IntToString((Services.Ticks() DIV 1000), m.title); m.content:=dlg.in$;
		dlg.in:=''; Dialog.UpdateString(dlg.in); 
		S.SendTo(rec.s, dlg.to.item, m, res);
		Log('msg sent');
	END SendMsg2;
	
	PROCEDURE SendMsgGuard*(VAR par: Dialog.Par);
	BEGIN
		par.disabled:=~Ready();
	END SendMsgGuard;
	
	PROCEDURE SendMsg2Guard*(VAR par: Dialog.Par);
	BEGIN
		par.disabled:=(~Ready() OR (dlg.in=''));
	END SendMsg2Guard;
	
	PROCEDURE SendMsg*;
	VAR m : Msg; i, j, z, res : INTEGER;
	BEGIN
		NEW(m);
		m.dlg.user:='akapetryxa';
		m.dlg.server:='jabber.org';
		m.dlg.pwd:='00018152';
		m.dlg.res:='bus';
		m.dlg.remoteAdr:='jabber.org';
		m.dlg.to:='petryxa-coder@jabber.ru';
		m.x:=66666;
		m.y:=0.51651;
		m.z:={0,2, 8, 6};
		m.u:=FALSE;
		m.d:=5545444545454;
		m.j:='f';
		FOR i:=0 TO 2 DO
			FOR j:=0 TO 2 DO
				FOR z:=0 TO 3 DO 
					m.v[i, j, z].x:=i*j;
					m.v[i, j, z].y:=(i/10)*(j/10); 
				END;
			END;
		END;
		S.SendTo(rec.s, dlg.to.item, m, res);
	END SendMsg;
	
	PROCEDURE SendTextGuard*(VAR par: Dialog.Par);
	BEGIN
		par.disabled:=(~Ready() OR (dlg.in=''));
	END SendTextGuard;
	
	PROCEDURE SendText*;
	VAR m: S.SendStdMsg; res: INTEGER;
	BEGIN
		m.type:=S.chatMsg;
		NEW(m.subject, 1); NEW(m.thread, 1); NEW(m.body, LEN(dlg.in$)+1);
		m.subject^:=''; m.thread^:=''; m.body^:=dlg.in$; 
		S.SendTo(rec.s, dlg.to.item, m, res);
		dlg.in:=''; Dialog.UpdateString(dlg.in);
	END SendText;
	
	PROCEDURE SendText2*;
	VAR m: S.SendConfirmableMsg; res: INTEGER;
	BEGIN
		m.type:=S.chatMsg;
		NEW(m.subject, 1); NEW(m.thread, 1); NEW(m.body, LEN(dlg.in$)+1);
		m.subject^:=''; m.thread^:=''; m.body^:=dlg.in$; 
		S.SendTo(rec.s, dlg.to.item, m, res);
		Log('waiting to confirm '+m.id);
		dlg.in:=''; Dialog.UpdateString(dlg.in);
	END SendText2;
	
	PROCEDURE SendFile*;
	VAR loc: Files.Locator; name: Files.Name; m: S.SendFileMsg; res: INTEGER;
	BEGIN
		Dialog.GetIntSpec('*', loc, name);
		IF loc#NIL THEN
			m.name:=name$;
			m.file:=Files.dir.Old(loc, name, Files.shared);
			IF m.file#NIL THEN
				m.range:=FALSE;
				m.offset:=0; m.length:=m.file.Length(); 
				m.descr:='some file';
				m.date:='1969-07-21T02:56:15Z';
				m.methods:={S.ibbMethod};
				S.SendTo(rec.s, dlg.to.item, m, res);
				ASSERT(m.sid#NIL);
			END;
		END;
	END SendFile;
	
	PROCEDURE RecvFile(from, name: ARRAY OF CHAR; id: S.StreamId);
	VAR loc: Files.Locator; m: S.AcceptFileMsg; res: INTEGER;
	BEGIN
		Dialog.GetExtSpec(name$, '*', loc, rec.fn);
		IF loc#NIL THEN 
			m.file:=Files.dir.New(loc, Files.dontAsk);
			m.id:=id; m.method:=S.ibbMethod;
			S.SendTo(rec.s, from, m, res)
		END;
	END RecvFile;
	
	PROCEDURE Disconnect*;
	BEGIN
		Cmds.StopSession(rec.s);
	END Disconnect;
		
	PROCEDURE Connect*;
	VAR res : INTEGER;
	BEGIN
		Cmds.NewSession(dlg.user, dlg.pwd, dlg.server, dlg.res, dlg.remoteAdr, rec.s, res);
		IF res=0 THEN
			Cmds.StartSession(rec.s, res);
			IF res=0 THEN
				Console.Open(rec.s.s);
			END
		END
	END Connect;
	
	PROCEDURE HandleBusMsg* (VAR msg: AbfBus.Message);
	VAR name, to, from : ARRAY 256 OF CHAR; grm: S.GetRosterMsg; s: S.Session; res: INTEGER;
	BEGIN	
		Services.GetTypeName(msg, name); StdLog.Ln; StdLog.String(name);
		WITH 
			|msg: S.ConnectingMsg DO Log(msg.op);
			|msg: S.ConnectedMsg DO Log('connected as '+msg.resource); S.Send(rec.s, grm, res);
			|msg: S.ErrorMsg DO Log('error '+msg.type+'('+msg.description+') occurred')
			|msg: Msg2 DO Log(msg.title+': '+msg.content)
			|msg: S.RosterMsg DO 
				StdLog.Int(msg.length); Log('roster received');
				FillRoster(msg.list);
			|msg: S.StdMsg DO msg.MetaInf(to, from, s, res); Log(from$+': '+msg.body$);
			|msg: S.ConfirmedMsg DO msg.MetaInf(to, from, s, res); Log(from$ + ' received '+msg.id$);
			|msg: S.TimeOutMsg DO msg.MetaInf(to, from, s, res); Log('no confirmation from ' + from$ + ' on message '+msg.id$);
			|msg: S.IncomingFileMsg DO msg.MetaInf(to, from, s, res); RecvFile(from, msg.name$, msg.id);
		ELSE END;
	END HandleBusMsg;
	
	PROCEDURE Init;
	BEGIN
		dlg.user:='sim0ne';
		dlg.server:='xmpp.ru';
		dlg.pwd:='00018152';
		dlg.res:='bus';
		dlg.remoteAdr:='xmpp.ru';
		dlg.to.item:='psi@peter/bus';
		dlg.in:=''; dlg.out:='';
	END Init;
	
BEGIN
	Init;
CLOSE

END XmppObx.

