MODULE XmppSasl;
(**	project	= "XMPP"
	organization	= ""
	contributors	= ""
	purpose	= "???????? ?????????? ????????? SASL"
	changes	= "
	- , nn, ...
	"
	issues	= ""
**)
	IMPORT DS:=StringsDyn, Log, Const:=XmppConst, Md5:=ypkCryptMd5, Strings, StringsUtf;

	TYPE
		DynString* = DS.DynString;
		String* = ARRAY OF CHAR;
		
		Str*=ARRAY 256 OF CHAR;
		
		Data* = RECORD
			nonce*, 
			qop*,
			charset*,
			algorithm* : Str;
			username*,
			cnonce*,
			nc*,
			digestUri*,
			response*,
			password*,
			realm*,
			rspauth* : Str;
		END;
(********************************************************************************)
	PROCEDURE (VAR D : Data) Fill* (s : DynString), NEW;
	VAR i, res : INTEGER; nm : BOOLEAN; name, val : DynString;
		PROCEDURE Flush;
		BEGIN
			IF name.String()$=Const.sasl_nonce THEN D.nonce:=val.String()$
			ELSIF name.String()$=Const.sasl_qop THEN D.qop:=val.String()$
			ELSIF name.String()$=Const.sasl_charset THEN D.charset:=val.String()$
			ELSIF name.String()$=Const.sasl_algorithm THEN D.algorithm:=val.String()$
			ELSIF name.String()$=Const.sasl_realm THEN D.realm:=val.String()$
			ELSIF name.String()$=Const.sasl_rspauth THEN D.rspauth:=val.String()$
			ELSE END;
			name.Clear; val.Clear; nm:=TRUE;
		END Flush;
	BEGIN
		D.nonce:=''; D.qop:=''; D.charset:=''; D.algorithm:=''; D.realm:=''; D.rspauth:='';
		name:=DS.Create(''); val:=DS.Create(''); i:=0; nm:=TRUE;
		WHILE i<s.Length() DO
			CASE s.Char(i) OF 
				',':	Flush;
				|'=': nm:=FALSE;
				|'"', "'", ' ': 
			ELSE
				IF nm THEN name.AddChar(s.Char(i)) ELSE val.AddChar(s.Char(i)) END;
			END;
			INC(i);
		END;
		Flush;
	END Fill;
	
	PROCEDURE (VAR D : Data) Make*(VAR s : DynString), NEW;
	BEGIN
		s:=DS.Create('');
		s.AddString(Const.sasl_username+'="'+D.username$+'",');
		s.AddString(Const.sasl_realm+'="'+D.realm$+'",');
		 s.AddString(Const.sasl_nonce+'="'+D.nonce$+'",');
		s.AddString(Const.sasl_cnonce+'="'+D.cnonce$+'",');
		s.AddString(Const.sasl_nc+'='+D.nc$+',');
		s.AddString(Const.sasl_digest_uri+'="'+D.digestUri$+'",');
		s.AddString(Const.sasl_qop+'='+D.qop$+',');
		s.AddString(Const.sasl_response+'='+D.response$+',');
		s.AddString(Const.sasl_charset+'='+D.charset$);
		(* s.AddChar(0X); *)
	END Make;
	
	PROCEDURE (VAR D : Data) Gen*, NEW;
	VAR A1, A2 : POINTER TO ARRAY OF SHORTCHAR; d1 : Md5.Digest;
		
		PROCEDURE H(IN x : ARRAY OF SHORTCHAR) : POINTER TO Md5.Digest;
		VAR c : Md5.Context; y : POINTER TO Md5.Digest; i : INTEGER;
		BEGIN
			c:=Md5.New(); i:=0; NEW(y);
			WHILE x[i]#0X DO Md5.Write(c,x[i]); INC(i); END;
			Md5.Close(c,y);
			RETURN y;
		END H;
		
		PROCEDURE KD(s1, s2 : ARRAY OF SHORTCHAR) : POINTER TO Md5.Digest;
		BEGIN
			RETURN H(s1$+':'+s2$);
		END KD;
		
		PROCEDURE HEX (d : Md5.Digest) : POINTER TO ARRAY OF SHORTCHAR;
		VAR s : POINTER TO ARRAY OF SHORTCHAR;
		BEGIN
			NEW(s, 33);
			Md5.ToString(d,s);
			RETURN s;
		END HEX;
		
		PROCEDURE Short(IN x : ARRAY OF CHAR) : POINTER TO ARRAY OF SHORTCHAR;
		VAR s : POINTER TO ARRAY OF SHORTCHAR; i : INTEGER;
		BEGIN
			NEW(s, LEN(x)); 
			FOR i:=0 TO LEN(s)-1 DO s[i]:=SHORT(x[i]) END;
			(* StringsUtf.ToUtf8(x, s); *) 
			RETURN s;
		END Short;
		
	BEGIN
		(**) 
		d1:=H(Short(D.username$+':'+D.realm$+':' +D.password$));
		d1:=H(Short(d1+':'+D.nonce+':'+D.cnonce));
		A1:=HEX(d1);
		d1:=H(Short('AUTHENTICATE:'+D.digestUri));
		A2:=HEX(d1);
		d1:=H(A1+Short(':'+D.nonce+':'+D.nc+':'+D.cnonce+':'+D.qop+':')+A2);
		A1:=HEX(d1);
		D.response:=A1^$;
		(* Log.String(D.response); Log.Ln; *)
	END Gen;
	
BEGIN

END XmppSasl.