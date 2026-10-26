MODULE XmppStrings;
(**	project	= "Xmpp"
	organization	= ""
	contributors	= ""
 	purpose	= ""
	changes	= "
	- , nn, ...
	"
	issues	= ""
	selectors	= ????
**)
	IMPORT Strings, Rand:=ypkMathRandom;
	
	PROCEDURE ServerFromJid*(IN jid : ARRAY OF CHAR; OUT server : ARRAY OF CHAR; res : INTEGER);
	VAR start, end, len : INTEGER; str :  ARRAY 3096 OF CHAR;
	BEGIN
		ASSERT(jid#'', 21);
		Strings.Find(jid, '@', 0, start);
		server:=''; res:=0;
		Strings.Find(jid, '/', MAX(start, 0), end);
		IF end>-1 THEN Strings.Extract(jid$, start+1,LEN(jid$)-start-(LEN(jid$)-end+1), str);
		ELSE Strings.Extract(jid$, start+1,LEN(jid$)-start, str); END;
		server:=str$;  
	END ServerFromJid;
 
	PROCEDURE UsernameFromJid*(IN jid : ARRAY OF CHAR; OUT username : ARRAY OF CHAR; res : INTEGER);
	VAR start, end, len : INTEGER; str :  ARRAY 3096 OF CHAR;
	BEGIN
		ASSERT(jid#'', 21);
		Strings.Find(jid, '@',0,start);
		username:=''; res:=0;
		IF start#-1 THEN 
			ASSERT(start#-1, 21);
			Strings.Extract(jid$, 0,start, str);
			username:=str$;
		ELSE res:=-1 END; 
	END UsernameFromJid;
	
	PROCEDURE ResourceFromJid*(IN jid : ARRAY OF CHAR; OUT resource : ARRAY OF CHAR);
	VAR start, end, len : INTEGER; str :  ARRAY 3096 OF CHAR;
	BEGIN
		ASSERT(jid#'', 21);
		Strings.Find(jid, '/',0,start);
		IF start>-1 THEN 
			INC(start);
			Strings.Extract(jid$,start, LEN(jid$)-start, str);
		ELSE str:=''; END;
		resource:=str$+0X;  
	END ResourceFromJid;
	
	PROCEDURE GetProjectNameFromFullJid* (IN jid: ARRAY OF CHAR; OUT name: ARRAY OF CHAR);
	VAR res: INTEGER;
	BEGIN
		res := 0;
		Strings.Find(jid, '/', 0, res);
		ASSERT(res > 0, 20);
		Strings.Extract(jid, res + 1, LEN(jid$) - res, name)
	END GetProjectNameFromFullJid;

	PROCEDURE GetShortJidFromFullJid* (IN jid: ARRAY OF CHAR; OUT sJid: ARRAY OF CHAR);
	VAR res: INTEGER;
	BEGIN
		res := 0;
		Strings.Find(jid, '/', 0, res);
		IF res > 0 THEN Strings.Extract(jid, 0, res, sJid) ELSE sJid:=jid$ END
	END GetShortJidFromFullJid;

	PROCEDURE JidCorrect* (jid : ARRAY OF CHAR): BOOLEAN;
	VAR user, server: ARRAY 512 OF CHAR; res: INTEGER;
	BEGIN
		UsernameFromJid(jid, user, res);
		ServerFromJid(jid, server, res);
		Strings.Find(jid, ' ', 0, res);
		RETURN (server # '') & (user # '') & (res = - 1)
	END JidCorrect;
	
	PROCEDURE Jid*(user, server, resource : ARRAY OF CHAR; OUT jid: ARRAY OF CHAR);
	BEGIN
		jid:=user$+'@'+server$;
		IF resource#'' THEN jid:=jid+'/'+resource END;
	END Jid;
	
	PROCEDURE NewId*(prefix : ARRAY OF CHAR; OUT id: ARRAY OF CHAR);
	BEGIN
		Rand.UniRandStr(id, 5); id:=prefix$+'-'+id$;
	END NewId;
END XmppStrings.