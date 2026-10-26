MODULE XmppXmlGen;

(**
	project	= "XML Core"
	organization	= ""
	contributors	= ""
	purpose	= "???????? ?????????????????? ????????? XML"
	changes	= "
	- , nn, ...
	"
	issues	= ""
**)
IMPORT Log, Dom:=XmlcoreDom, DynStrings := XmlcoreStrings, Files, Strings, Formatters:= XmlcoreFormatters;

TYPE
	Generator* = POINTER TO RECORD
		fm* : Formatters.Formatter;
	END;
	
	EntityString = ARRAY 10 OF CHAR;
	
PROCEDURE Entity(ch : CHAR; VAR out : EntityString);
BEGIN
	IF ch='&' THEN  out:='&amp;'
	ELSIF ch='<' THEN out:='&lt;'
	ELSIF ch='>' THEN out:='&gt;'
	ELSIF ch="'" THEN out:='&apos;'
	ELSIF ch='"' THEN out:='&quot;'
	ELSE 
		out[0]:=ch; out[1]:=0X;
	END;
END Entity;

PROCEDURE WithEntities(str : DynStrings.String) : DynStrings.String;
VAR
	s : DynStrings.DynString;
	buf : DynStrings.DynString;
	i, res : INTEGER; ok : BOOLEAN;
	out : EntityString;
BEGIN	
	res:=-1; ok:=FALSE;
	Strings.Find(str,'&',0,res);
	IF res=-1 THEN Strings.Find(str,'<',0,res); 
		IF res=-1 THEN Strings.Find(str,'>',0,res); 
			IF res=-1 THEN Strings.Find(str,'"',0,res);
				IF res=-1 THEN Strings.Find(str,"'",0,res);
					IF res>-1 THEN ok:=TRUE END;
				ELSE ok:=TRUE END;	
			ELSE ok:=TRUE END;	
		ELSE ok:=TRUE END;
	ELSE ok:=TRUE END;
	
	IF ok  THEN
		buf:=DynStrings.Create('');
		FOR i:=0 TO LEN(str)-1 DO
			out:='';
			Entity(str[i], out);
			buf.AddString(out);
		END;
	ELSE
		RETURN str;
	END;
	RETURN buf.String();
END WithEntities;

PROCEDURE (g : Generator) Attr(root : Dom.Element), NEW;
VAR
		a : Dom.Attr;
		i : INTEGER;
BEGIN
	IF (root.attributes#NIL) THEN
		FOR i:=0 TO root.attributes.length-1 DO
			a:=root.attributes.Item(i)(Dom.Attr);
			g.fm.Attr(a.name$,WithEntities(a.value)$);
		END;
	END;
END Attr;

PROCEDURE (g : Generator) Element*(root : Dom.Node; split : BOOLEAN), NEW;
VAR
	n : Dom.Node;
BEGIN
	n:=root.firstChild; 
	WHILE n#NIL DO
		WITH n : Dom.Element DO 
				g.fm.StartTag(n.nodeName$,Formatters.preserve);
				g.Attr(n); 
				g.Element(n, FALSE);
				IF ~split THEN g.fm.EndTag; ELSE g.fm.wr.String(' >'); END;
			|n : Dom.Text DO g.fm.Data(WithEntities(n.GetData())$);
			|n : Dom.Comment DO g.fm.Comment(n.GetData()$); g.fm.Ln;
			|n : Dom.CDATASection DO g.fm.CDATASect(n.GetData()$);
			|n : Dom.ProcessingInstruction DO g.fm.Instruction(n.target$, n.data$); g.fm.Ln;
		ELSE
		END;
		n:=n.nextSibling;
	END;
END Element;

PROCEDURE NewGenerator*(target : ANYPTR) : Generator;
VAR
	g : Generator;
BEGIN
	NEW(g);
	g.fm:=Formatters.dir.NewFormatter(Formatters.dir.NewWriter(target));
	RETURN g;
END NewGenerator;

END XmppXmlGen.