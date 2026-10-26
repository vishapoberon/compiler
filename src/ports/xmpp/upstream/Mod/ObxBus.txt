MODULE XmppObxBus;
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

	IMPORT S:=XmppSession, Cmds:=XmppCmds, Console:=XmppConsole, Dialog, AbfBus, Services, Log;
	
	TYPE
		Msg* = POINTER TO RECORD (S.Msg) 
			dlg* : RECORD
			user*, server*, pwd*, res*, remoteAdr*, to* : Dialog.String;
			END;
			x* : INTEGER; y* : REAL; z* : SET; u* : BOOLEAN;
			v* : ARRAY 4 OF ARRAY 3 OF ARRAY 4 OF RECORD x* :INTEGER; y* : REAL END;
			d* : LONGINT;
			j* : CHAR;
		END;
	
	VAR
		dlg* : RECORD
			user*, server*, pwd*, res*, remoteAdr*, to* : Dialog.String;
		END;
		rec : RECORD
			s : S.Session;
		END;
	
	PROCEDURE Do*;
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
		S.SendTo(rec.s, dlg.to, m, res);
	END Do;
	
	PROCEDURE Disconnect*;
	BEGIN
		Cmds.StopSession(rec.s);
	END Disconnect;
		
	PROCEDURE Connect*;
		VAR res : INTEGER;
	BEGIN
		Cmds.NewSession(dlg.user, dlg.pwd, dlg.server, dlg.res, dlg.remoteAdr, rec.s, res);
		ASSERT(res=0, 100);
		Cmds.StartSession(rec.s, res);
		ASSERT(res=0, 100);
		Console.Open(rec.s.s);
	END Connect;
	
	PROCEDURE HandleBusMsg* (VAR msg: AbfBus.Message);
	VAR name : ARRAY 256 OF CHAR;
	BEGIN	
		Services.GetTypeName(msg, name); Log.Ln; Log.String(name);
		(* WITH 
			msg :  DO

		ELSE END;
		*)
	END HandleBusMsg;
	
	PROCEDURE Init;
	BEGIN
		dlg.user:='bb';
		dlg.server:='peter';
		dlg.pwd:='00018152';
		dlg.res:='bus';
		dlg.remoteAdr:='localhost';
		dlg.to:='psi@peter/bus';
	END Init;
	
BEGIN
	Init;
CLOSE

END XmppObxBus.

