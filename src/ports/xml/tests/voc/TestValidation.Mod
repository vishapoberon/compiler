MODULE TestValidation;

IMPORT Out, S := LongStrings, M := Msg, Mem := IOMemory, Ch := Channel,
  D := XMLDTD, B := XMLBuilder, V := XMLBuilderValidation, N := XMLBuilderNamespaces,
  P := XMLParser, URI, URIParser;

TYPE
  Capture = POINTER TO CaptureDesc;
  CaptureDesc = RECORD (B.BuilderDesc)
    starts, ends, documents, attributes, whitespace: LONGINT;
  END;

VAR base: URI.URI; result: M.Msg;

PROCEDURE (b: Capture) StartElement(namespaceDecl: D.NamespaceDeclaration; localName: D.String);
BEGIN INC(b.starts) END StartElement;

PROCEDURE (b: Capture) EndElement(namespaceDecl: D.NamespaceDeclaration; localName: D.String);
BEGIN INC(b.ends) END EndElement;

PROCEDURE (b: Capture) EndDocument;
BEGIN INC(b.documents) END EndDocument;

PROCEDURE (b: Capture) Attribute(namespaceDecl: D.NamespaceDeclaration; localName: D.String;
  attrDecl: D.AttrDecl; value: D.AttValue; specified: BOOLEAN);
BEGIN INC(b.attributes) END Attribute;

PROCEDURE (b: Capture) Characters(VAR chars: D.StringVar; charsStart, charsEnd: D.CharPos;
  elementWhitespace: D.ElementWhitespaceType);
BEGIN
  IF elementWhitespace = D.elementWhitespaceYes THEN INC(b.whitespace, charsEnd-charsStart) END
END Characters;

PROCEDURE Parse(text: ARRAY OF CHAR; namespaces: BOOLEAN; VAR b: Capture): P.Parser;
  VAR ch: Mem.Channel; writer: Ch.Writer; p: P.Parser; res: M.Msg; builder: B.Builder;
BEGIN
  NEW(b); B.Init(b); b.starts := 0; b.ends := 0; b.documents := 0;
  b.attributes := 0; b.whitespace := 0;
  ch := Mem.Tmp("", {Mem.read, Mem.write}, res); ASSERT(res = NIL, 201);
  writer := ch.NewWriter(); writer.WriteBytes(text, 0, S.Length8(text));
  builder := b; IF namespaces THEN builder := N.New(builder) END;
  p := P.NewChannel(ch, base, NIL, NIL, V.New(builder));
  p.validating := TRUE; p.enforceQNames := namespaces; p.followExternalRef := FALSE;
  p.ParseDocument; ch.Close;
  ASSERT(b.documents = 1, 202); RETURN p
END Parse;

PROCEDURE Check(text: ARRAY OF CHAR; valid: BOOLEAN);
  VAR b: Capture; p: P.Parser; msg: M.Msg; error: ARRAY 1024 OF CHAR;
BEGIN
  p := Parse(text, FALSE, b);
  IF (p.errList.msgCount = 0) # valid THEN
    Out.String("Unexpected validation result: "); Out.String(text); Out.Ln;
    msg := p.errList.msgList;
    WHILE msg # NIL DO msg.GetText(error); Out.String(error); Out.Ln; msg := msg.nextMsg END
  END;
  ASSERT((p.errList.msgCount = 0) = valid, 203);
  IF valid THEN ASSERT(b.starts = b.ends, 204) END
END Check;

PROCEDURE ContentChecks;
BEGIN
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY>]><r/>', TRUE);
  Check('<!DOCTYPE r [<!ELEMENT r ANY><!ELEMENT a EMPTY>]><r>text<a/></r>', TRUE);
  Check('<!DOCTYPE r [<!ELEMENT r (a,b?,(c|d)+)><!ELEMENT a EMPTY><!ELEMENT b EMPTY><!ELEMENT c EMPTY><!ELEMENT d EMPTY>]><r><a/><b/><c/><d/></r>', TRUE);
  Check('<!DOCTYPE r [<!ELEMENT r (a,b?,(c|d)+)><!ELEMENT a EMPTY><!ELEMENT c EMPTY>]><r><a/><c/></r>', TRUE);
  Check('<!DOCTYPE r [<!ELEMENT r ((a?)*)><!ELEMENT a EMPTY>]><r/>', TRUE);
  Check('<!DOCTYPE r [<!ELEMENT r (#PCDATA|a)*><!ELEMENT a EMPTY>]><r>x<a/>y</r>', TRUE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY>]><r> </r>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY>]><r><![CDATA[]]></r>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r (a)><!ELEMENT a EMPTY>]><r/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r (a)><!ELEMENT a EMPTY>]><r>x<a/></r>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r (a)><!ELEMENT a EMPTY>]><r>&#32;<a/></r>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r (a,b)><!ELEMENT a EMPTY><!ELEMENT b EMPTY>]><r><b/><a/></r>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r (#PCDATA|a)*><!ELEMENT a EMPTY><!ELEMENT b EMPTY>]><r><b/></r>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r (#PCDATA|a|a)*><!ELEMENT a EMPTY>]><r/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r (a|a)><!ELEMENT a EMPTY>]><r><a/></r>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r (a*,a)><!ELEMENT a EMPTY>]><r><a/></r>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r ((a,b)|(a,c))><!ELEMENT a EMPTY><!ELEMENT b EMPTY><!ELEMENT c EMPTY>]><r><a/><b/></r>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r (a,(b|c))><!ELEMENT a EMPTY><!ELEMENT b EMPTY><!ELEMENT c EMPTY>]><r><a/><b/></r>', TRUE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ELEMENT r EMPTY>]><r/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY>]><other/>', FALSE);
  Check('<r/>', FALSE)
END ContentChecks;

PROCEDURE AttributeChecks;
BEGIN
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r id ID #REQUIRED ref IDREF #IMPLIED refs IDREFS #IMPLIED>]><r id="a" ref="a" refs="a a"/>', TRUE);
  Check('<!DOCTYPE r [<!ELEMENT r (a*)><!ELEMENT a EMPTY><!ATTLIST r ref IDREF #IMPLIED><!ATTLIST a id ID #REQUIRED>]><r ref="later"><a id="later"/></r>', TRUE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a NMTOKENS " a b " b (x|y) "x" c CDATA #FIXED "v">]><r c="v"/>', TRUE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a NMTOKENS #IMPLIED>]><r a=" a  b "/>', TRUE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a CDATA #REQUIRED>]><r/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY>]><r a="v"/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a CDATA #FIXED "v">]><r a="x"/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a NMTOKEN #IMPLIED>]><r a="a b"/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a NMTOKENS #IMPLIED>]><r a=""/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a NMTOKENS #IMPLIED>]><r a="a&#10;b"/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a (x|y) #IMPLIED>]><r a="z"/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a (x|x) #IMPLIED>]><r/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a NMTOKEN "a b">]><r/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a ID "id">]><r/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a ID #IMPLIED b ID #IMPLIED>]><r/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r (a*)><!ELEMENT a EMPTY><!ATTLIST a id ID #REQUIRED>]><r><a id="dup"/><a id="dup"/></r>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a ID #IMPLIED>]><r a="123"/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a IDREF #IMPLIED>]><r a="missing"/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a IDREFS #IMPLIED>]><r a="missing another"/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a IDREFS #IMPLIED>]><r a=""/>', FALSE)
END AttributeChecks;

PROCEDURE NotationChecks;
BEGIN
  Check('<!DOCTYPE r [<!ELEMENT r ANY><!NOTATION n SYSTEM "n"><!ENTITY e SYSTEM "e" NDATA n><!ATTLIST r a ENTITY #IMPLIED b ENTITIES #IMPLIED c NOTATION (n) #IMPLIED>]><r a="e" b="e e" c="n"/>', TRUE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r a ENTITY #IMPLIED>]><r a="missing"/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ENTITY e "text"><!ATTLIST r a ENTITY #IMPLIED>]><r a="e"/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!ENTITY e SYSTEM "e" NDATA missing>]><r/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r ANY><!ATTLIST r a NOTATION (missing) #IMPLIED>]><r/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r ANY><!NOTATION n SYSTEM "n"><!ATTLIST r a NOTATION (n) #IMPLIED>]><r a="other"/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r ANY><!NOTATION n SYSTEM "n"><!NOTATION n SYSTEM "n">]><r/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r EMPTY><!NOTATION n SYSTEM "n"><!ATTLIST r a NOTATION (n) #IMPLIED>]><r/>', FALSE);
  Check('<!DOCTYPE r [<!ELEMENT r ANY><!NOTATION n SYSTEM "n"><!ENTITY good SYSTEM "e" NDATA n><!ENTITY bad "text"><!ATTLIST r a ENTITY "bad">]><r a="good"/>', TRUE);
  Check('<!DOCTYPE r [<!ELEMENT r ANY><!NOTATION n SYSTEM "n"><!ENTITY good SYSTEM "e" NDATA n><!ENTITY bad "text"><!ATTLIST r a ENTITIES "good bad">]><r a="good"/>', TRUE);
  Check('<!DOCTYPE r [<!ELEMENT r ANY><!ENTITY bad "text"><!ATTLIST r a ENTITY "bad">]><r/>', FALSE)
END NotationChecks;

PROCEDURE GrowthChecks;
  VAR text: ARRAY 4096 OF CHAR; pos, i: LONGINT; b: Capture; p: P.Parser;

  PROCEDURE Append(part: ARRAY OF CHAR);
    VAR j: LONGINT;
  BEGIN
    j := 0;
    WHILE part[j] # 0X DO text[pos] := part[j]; INC(pos); INC(j) END;
    text[pos] := 0X
  END Append;

BEGIN
  pos := 0; Append('<!DOCTYPE r [<!ELEMENT r (r*)>]>');
  FOR i := 0 TO 63 DO Append('<r>') END;
  FOR i := 0 TO 63 DO Append('</r>') END;
  p := Parse(text, FALSE, b);
  ASSERT((p.errList.msgCount = 0) & (b.starts = 64) & (b.ends = 64), 205);
  p := Parse('<!DOCTYPE p:r [<!ELEMENT p:r (p:s)><!ELEMENT p:s EMPTY><!ATTLIST p:r xmlns:p CDATA #FIXED "urn:p">]><p:r> <p:s/> </p:r>', TRUE, b);
  ASSERT((p.errList.msgCount = 0) & (b.starts = 2) & (b.whitespace = 2), 206)
END GrowthChecks;

PROCEDURE LongUnicodeChecks;
  VAR text: ARRAY 100000 OF CHAR; pos, i: LONGINT;
    b: Capture; p: P.Parser;

  PROCEDURE Append(part: ARRAY OF CHAR);
    VAR j: LONGINT;
  BEGIN
    j := 0;
    WHILE part[j] # 0X DO text[pos] := part[j]; INC(pos); INC(j) END;
    text[pos] := 0X
  END Append;

  PROCEDURE Armenian;
  BEGIN text[pos] := 0D4X; text[pos+1] := 0B1X; INC(pos, 2); text[pos] := 0X END Armenian;

BEGIN
  pos := 0;
  Append('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r id ID #REQUIRED refs IDREFS #IMPLIED>]><r id="');
  Armenian; Append('" refs="');
  FOR i := 0 TO 19999 DO IF i > 0 THEN Append(' ') END; Armenian END;
  Append('"/>');
  p := Parse(text, FALSE, b);
  ASSERT((p.errList.msgCount = 0) & (b.attributes = 2), 208);
  pos := 0; Append('<!DOCTYPE r [<!ELEMENT r (#PCDATA|');
  FOR i := 1 TO 80 DO Append('a') END;
  Append('|b)*><!ELEMENT x EMPTY>]><r><x/></r>');
  p := Parse(text, FALSE, b); ASSERT(p.errList.msgCount > 0, 209)
END LongUnicodeChecks;

BEGIN
  base := URIParser.NewURI("file:/xml-tests/document.xml", NIL, result); ASSERT(result = NIL, 207);
  ContentChecks; AttributeChecks; NotationChecks; GrowthChecks; LongUnicodeChecks;
  Out.String("XML validation checks passed"); Out.Ln
END TestValidation.
