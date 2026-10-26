MODULE XmppBasic;

	IMPORT Core:=XmppCore, Console:=XmppConsole, Log:=StdLog, Dialog, StdCmds, Services;

	TYPE Action = POINTER TO RECORD (Services.Action) END;
	
	VAR
		s : Core.Session;
		user*, password*, remoteAdr* : Dialog.String;
	
	PROCEDURE (a : Action) Do;
	VAR res : INTEGER;
	BEGIN
		IF ~s.Authorized() THEN	
			s.StartStream;
		END;
	END Do;

	PROCEDURE Disconnect*;
	BEGIN
		s.CloseStream;
	END Disconnect;
	
	PROCEDURE DisconnectGuard*(VAR par : Dialog.Par);
	BEGIN
		par.disabled:=(s=NIL);
	END DisconnectGuard;

	PROCEDURE Connect*;
	VAR a : Action;
	BEGIN
		IF s#NIL THEN Disconnect; END;
		s:=Core.dir.NewSession(remoteAdr, user, password, Core.normalOpts);
		NEW(a); Services.DoLater(a, Services.Ticks()+Services.resolution DIV 3);
		Console.Open(s);
	END Connect;
	
	PROCEDURE ConnectGuard*(VAR par : Dialog.Par);
	BEGIN
		par.disabled:=(password$='') OR (user$='') OR (remoteAdr$='');
	END ConnectGuard;

	PROCEDURE OpenConsole*;
	BEGIN
		Console.Open(s);
	END OpenConsole;
	
	PROCEDURE ConsoleGuard*(VAR par : Dialog.Par);
	BEGIN
		par.disabled:=(s=NIL);
	END ConsoleGuard;
	
	PROCEDURE Start*;
	BEGIN
		StdCmds.OpenAuxDialog('Xmpp/Rsrc/Basic', 'Basic XMPP session');
	END Start;
	
	PROCEDURE Init*;
	BEGIN
		user:='bb@peter/blackbox'; password:='00018152'; remoteAdr:='127.0.0.1:5222';
	END Init;
	
	PROCEDURE Close*;
	BEGIN
		IF s#NIL THEN Disconnect; END;
	END Close;
		
BEGIN
	Init;
CLOSE
	Close;
END XmppBasic.


