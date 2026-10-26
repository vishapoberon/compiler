MODULE XmppDateTime;
(**
	project	= "XMPP"
	organization	= ""
	contributors	= ""
	purpose	= "???????? ??????????????? ????/??????? ? ?????? XMPP, ???????? ? http://www.xmpp.org/extensions/xep-0082.html"
	changes	= "
	- , nn, ...
	"
	issues	= ""
**)

	IMPORT Strings, DS:=StringsDyn, Dates, Log;
	
	TYPE
		Date* = RECORD
			year*, month*, day* : INTEGER;
		END;
		
		Time* = RECORD
			hour*, min*, sec*, mSec*, zoneOffset* : INTEGER; utc* : BOOLEAN;
		END;
		
	PROCEDURE DateToString*(IN date : Date; OUT s : ARRAY OF CHAR);
	VAR y : ARRAY 5 OF CHAR; m : ARRAY 3 OF CHAR; d : ARRAY 3 OF CHAR; res : INTEGER;
	BEGIN
		ASSERT(LEN(s)>=11, 21); ASSERT((date.month<13) & (date.month>0)); ASSERT((date.day<32)&(date.day>0));
		Strings.IntToStringForm(date.year,Strings.decimal,4,'0',Strings.hideBase,y);
		Strings.IntToStringForm(date.month,Strings.decimal, 2,'0',Strings.hideBase,m);
		Strings.IntToStringForm(date.day,Strings.decimal, 2,'0',Strings.hideBase,d);
		s:=y$+'-'+m$+'-'+d$;		
	END DateToString;
	
	PROCEDURE TimeToString*(IN time : Time; withMsec, withTimeZone : BOOLEAN;  OUT s : ARRAY OF CHAR);
	VAR h,m,ss : ARRAY 3 OF CHAR; ms : ARRAY 4 OF CHAR; z : ARRAY 7 OF CHAR;
	BEGIN
		ASSERT(LEN(s)>=16, 21); ASSERT((time.hour<25) & (time.hour>-1)); ASSERT((time.min<60) & (time.min>-1)); ASSERT((time.sec<60) & (time.sec>-1)); 
		IF withMsec THEN ASSERT((time.mSec<1000) & (time.mSec>-1)); END;
		IF withTimeZone THEN ASSERT((time.zoneOffset<13) & (time.zoneOffset>-13)); END;
		z:=''; ms:='';
		Strings.IntToStringForm(time.hour,Strings.decimal, 2,'0',Strings.hideBase,h);
		Strings.IntToStringForm(time.min,Strings.decimal, 2,'0',Strings.hideBase,m);
		Strings.IntToStringForm(time.sec,Strings.decimal,2,'0',Strings.hideBase,ss);
		s:=h$+':'+m$+':'+ss$;
		IF withMsec THEN
			Strings.IntToStringForm(time.mSec,Strings.decimal,3,'0',Strings.hideBase,ms);
			s:=s$+'.'+ms$;
		END;
		 IF withTimeZone THEN
			IF ~time.utc&(time.zoneOffset#0) THEN	
				IF time.zoneOffset > 0 THEN
					Strings.IntToStringForm(time.zoneOffset,Strings.decimal,2,'0',Strings.hideBase,z); 
					z:='+'+z$; 
				ELSE
					Strings.IntToStringForm(time.zoneOffset,Strings.decimal,3,'0',Strings.hideBase,z); 
				END;
				z:=z$+':00';
			ELSIF time.utc THEN  z:='Z' END;			
			s:=s$+z$;
		END;
	END TimeToString;
	
	PROCEDURE DateTimeToString*(IN date : Date; IN time : Time; withMsec, withTimeZone : BOOLEAN; OUT s : ARRAY OF CHAR);
	VAR ds, ts : ARRAY 16 OF CHAR;
	BEGIN
		ASSERT(LEN(s)>=27);
		DateToString(date, ds);
		TimeToString(time, withMsec, withTimeZone, ts);
		s:=ds$+'T'+ts$;
	END DateTimeToString;
	
	PROCEDURE StringToDateTime*(IN s : ARRAY OF CHAR; OUT date : Date; OUT time : Time);
	(** layout : CCYY-MM-DDThh:mm:ss[.sss]TZD **)
	VAR i, pos : INTEGER; res : INTEGER; buf : DS.DynString; hasTime, expectZone, expectMsec : BOOLEAN;
	BEGIN
		i:=0; pos:=0; buf:=DS.Create(''); res:=0; expectZone:=FALSE; expectMsec:=FALSE; hasTime:=FALSE;
		date.year:=-1; date.month:=-1; date.day:=-1; time.hour:=-1; time.min:=-1; time.sec:=-1; time.mSec:=-1; time.zoneOffset:=MAX(INTEGER); time.utc:=FALSE;
		WHILE pos<LEN(s$) DO
			CASE s[pos] OF
				'-' : 
					CASE pos OF
						4 : Strings.StringToInt(buf.String(), date.year, res); ASSERT(res=0); buf.Clear;
						|7 : Strings.StringToInt(buf.String(), date.month, res); ASSERT(res=0); buf.Clear;
						|8, 13, 19, 23 : 
							expectZone:=TRUE;
							IF expectMsec THEN
								Strings.StringToInt(buf.String(), time.mSec, res); ASSERT(res=0); buf.Clear;
								expectMsec:=FALSE;
							ELSE
								Strings.StringToInt(buf.String(), time.sec, res); ASSERT(res=0); buf.Clear;
							END;
							buf.AddChar(s[pos]);
					ELSE HALT(99); END;
				|'+' : 
					expectZone:=TRUE;
					IF expectMsec THEN
						Strings.StringToInt(buf.String(), time.mSec, res); ASSERT(res=0); buf.Clear;
					ELSE
						Strings.StringToInt(buf.String(), time.sec, res); ASSERT(res=0); buf.Clear;
					END;
				|':' :
					CASE pos OF
						2, 13 : 
							hasTime:=TRUE; 
							Strings.StringToInt(buf.String(), time.hour, res); ASSERT(res=0); buf.Clear;
						|5,16 : Strings.StringToInt(buf.String(), time.min, res); ASSERT(res=0); buf.Clear;
						|11, 15, 22, 26 : 
							IF expectZone THEN
								Strings.StringToInt(buf.String(), time.zoneOffset, res); ASSERT(res=0); buf.Clear;
							END;		
					ELSE HALT(99); END;
				|'.' : expectMsec:=TRUE; Strings.StringToInt(buf.String(), time.sec, res); ASSERT(res=0); buf.Clear;
				|'Z' : time.utc:=TRUE;
				|'T' : hasTime:=TRUE; Strings.StringToInt(buf.String(), date.day, res); ASSERT(res=0); buf.Clear;
				|'0'..'9' : buf.AddChar(s[pos]);
			ELSE HALT(99); END;
			INC(pos);
		END;
		IF buf.Length()#0 THEN
			IF ~hasTime THEN Strings.StringToInt(buf.String(), date.day, res); ASSERT(res=0)
			ELSIF ~expectZone THEN
				IF expectMsec THEN
					Strings.StringToInt(buf.String(), time.mSec, res); ASSERT(res=0);
				ELSE
					Strings.StringToInt(buf.String(), time.sec, res); ASSERT(res=0);
				END;
			END;
		END;
	END StringToDateTime;
	
	PROCEDURE GetDate*(OUT d: Date; utc: BOOLEAN);
		VAR d0: Dates.Date;
	BEGIN
		IF utc THEN Dates.GetUTCDate(d0) ELSE Dates.GetDate(d0) END;
		d.year:=d0.year;
		d.month:=d0.month;
		d.day:=d0.day;
	END GetDate;
	
	PROCEDURE GetTime*(OUT t: Time);
		VAR t0: Dates.Time;
	BEGIN
		Dates.GetUTCTime(t0);
		t.hour:=t0.hour; 
		t.min:=t0.minute;
		t.sec:=t0.second;
		t.mSec:=0;
		Dates.GetUTCBias(t.zoneOffset);
		t.utc:=TRUE;
	END GetTime;

(**  Test  **)
END XmppDateTime.