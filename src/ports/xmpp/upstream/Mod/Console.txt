MODULE XmppConsole;

(**
	project	= "Xmpp"
	organization	= ""
	contributors	= ""
	version	= "System/Rsrc/About"
	copyright	= "Kushnir Piotr Michailovich"
	license	= "Docu/BB-License"
	purpose	= "??????? xml-?????? ?????? XmppCore"
	changes	= "
	- 20130617, pk, ????????????? ?????????
"
	issues	= ""
**)


	IMPORT 
		Core:=XmppCore, 
		DS:=StringsDyn, AbfBus,
		Log;
	
	TYPE
		Console* = POINTER TO ABSTRACT RECORD END;
		
		StdCons = POINTER TO RECORD (Console) END;
		
	VAR
		cons-: Console;

	PROCEDURE (c: Console) ConnectTo* (s: Core.Session), NEW, ABSTRACT;
	
	PROCEDURE (c: StdCons) ConnectTo (s: Core.Session);
	BEGIN
	
	END ConnectTo;
	
	PROCEDURE Open*(session : Core.Session);
	BEGIN
		IF cons#NIL THEN cons.ConnectTo(session) END
	END Open;
	
	PROCEDURE HandleBusMsg* (VAR msg: AbfBus.Message);
	BEGIN
		WITH msg : Core.ConsoleMsg DO
			IF (cons#NIL) THEN
				WITH cons: StdCons DO
					CASE msg.code OF
						Core.in: Log.Ln; Log.String(msg.in$); Log.Ln;
						|Core.out: Log.Ln; Log.String(msg.out$); Log.Ln;
					ELSE END;
				ELSE END;
			END;
		ELSE END;
	END HandleBusMsg;
	
	PROCEDURE Install* (c: Console);
	BEGIN
		ASSERT(c#NIL, 20);
		cons:=c	
	END Install;
		
	PROCEDURE Init;
		VAR c: StdCons;
	BEGIN
		NEW(c);
		Install(c);
		AbfBus.Subscribe("XmppConsole", "XmppCore", "ConsoleMsg", FALSE);
		AbfBus.Subscribe("XmppConsoleForm", "XmppCore", "ConsoleMsg", TRUE); (* ????????? ?????????? ??? ??????????? ??, ???? ?????????. *)
	END Init;

BEGIN
	Init	
END XmppConsole.