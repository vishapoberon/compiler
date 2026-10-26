MODULE XmppCmds;
(**	project	= "Xmpp"
	organization	= ""
	contributors	= ""
 	purpose	= ""
	changes	= "
	- 20120224, pk, ????????-?????????? srv ? ????????
	"
	issues	= ""
	selectors	= ????
**)

	IMPORT Kernel, ypkProxyCmds, ypkEncPunycode, ypkCommSrv, XmppSession, XmppConnections, XmppRegister, XmppConsole, AbfBus, Log;
	
	CONST
		socks4* = ypkProxyCmds.socks4;
		socks5* =  ypkProxyCmds.socks5;
		none* = '';
		sessMsg* = 1;
		rosterMsg* = 2;
		presenceMsg* = 3;
		messengerMsg* = 4;
		ibbMsg* = 5;
		bytestreamMsg* = 6;
		discoMsg* = 7;
		busMsg* = 8;
		
	TYPE
		RegHook* = POINTER TO ABSTRACT RECORD (XmppRegister.RegisterHook) END;	
	
	VAR 
		cfg- : RECORD
			proxy-: RECORD
				type- : ARRAY 127 OF CHAR;
				host-, port- : ARRAY 256 OF CHAR;
			END; 
			localAdr-, port- : ARRAY 127 OF CHAR;
		END;
	
	PROCEDURE SetDefaults*;
	BEGIN
		cfg.localAdr:='0.0.0.0:0';
		cfg.port:='5222';
		cfg.proxy.type:=none;
		cfg.proxy.host:='';
		cfg.proxy.port:='';
	END SetDefaults;
	
	PROCEDURE UseProxy*(type, host, port : ARRAY OF CHAR);
	BEGIN
		IF type#none THEN ASSERT(host#'', 20); ASSERT(port#'', 21) END;
		IF (type=socks4) OR (type=socks5) THEN
			cfg.proxy.type:=type$; 
			cfg.proxy.host:=host$;
			cfg.proxy.port:=port$;
		ELSIF type=none THEN
			cfg.proxy.type:=none;
		ELSE END;
	END UseProxy;
	
	(* PROCEDURE Subscribe*(s: XmppSession.Session; modName : ARRAY OF CHAR; opts : SET);
	BEGIN
		ASSERT(modName#'', 20);
		ASSERT(Kernel.ThisMod(modName)#NIL, 21);
		ASSERT(s#NIL, 22);
		ASSERT(opts#{}, 23);
	END Subscribe; *)
	
	PROCEDURE NewSession*(user, password, server, resource, remoteAdr : ARRAY OF CHAR; OUT s : XmppSession.Session; OUT res : INTEGER);
	VAR adr, lAdr, rAdr, protocol : ARRAY 256 OF CHAR;
	BEGIN
		IF server$=remoteAdr$ THEN
			ypkEncPunycode.Encode(remoteAdr$, rAdr);
			ypkCommSrv.Lookup(rAdr$, rAdr);
		ELSE rAdr:=remoteAdr$ END;
		IF cfg.proxy.type#none THEN
			ypkProxyCmds.PrepareAdr(cfg.proxy.type, rAdr$+':'+cfg.port, cfg.localAdr, cfg.proxy.host+':'+cfg.proxy.port, '', '', adr, lAdr, protocol, res);
			IF res=ypkProxyCmds.ok THEN XmppConnections.InitDriver(protocol, lAdr) END;
		ELSE 
			XmppConnections.InitDriver('CommTCP', '0.0.0.0:0'); 
			protocol:='CommTCP'; 
			lAdr:=cfg.localAdr$; adr:=rAdr$+':'+cfg.port; 
			res:=0;
		END;
		IF res=0 THEN XmppSession.New(protocol, lAdr, adr, user, password, server, resource, s) END;
	END NewSession;
	
	PROCEDURE StartSession*(s: XmppSession.Session; OUT res: INTEGER);
	BEGIN
		ASSERT(s#NIL, 20);
		XmppSession.Start(s, res); 
	END StartSession;
	
	PROCEDURE StopSession*(s : XmppSession.Session);
	BEGIN
		ASSERT(s#NIL, 20);
		XmppSession.Stop(s) 
	END StopSession;
	
	PROCEDURE Register*(remoteAdr, username, server, password, proxyType, proxyAdr, proxyPort, proxyUser, proxyPwd : ARRAY OF CHAR; regHook : RegHook);
	VAR adr, lAdr, rAdr, protocol : ARRAY 512 OF CHAR; res : INTEGER; 
	BEGIN
		ASSERT(regHook#NIL, 20);
		IF server$=remoteAdr$ THEN
			ypkEncPunycode.Encode(remoteAdr$, rAdr);
			ypkCommSrv.Lookup(rAdr$, rAdr);
		ELSE rAdr:=remoteAdr$ END;
		IF cfg.proxy.type#none THEN
			ypkProxyCmds.PrepareAdr(cfg.proxy.type, rAdr+':'+cfg.port, cfg.localAdr, cfg.proxy.host+':'+cfg.proxy.port, '', '', adr, lAdr, protocol, res);
			ASSERT(res=ypkProxyCmds.ok, 60);
			XmppConnections.InitDriver(protocol, lAdr);
		ELSE XmppConnections.InitDriver('CommTCP', '0.0.0.0:0'); adr:=rAdr+':'+cfg.port END;
		XmppRegister.Register(adr, username, server, password, regHook);
	END Register;

BEGIN
	SetDefaults	
END XmppCmds.