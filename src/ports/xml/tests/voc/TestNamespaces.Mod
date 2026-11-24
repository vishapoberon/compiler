MODULE TestNamespaces;

IMPORT Out, S := LongStrings, M := Msg, Mem := IOMemory, Ch := Channel,
  D := XMLDTD, B := XMLBuilder, N := XMLBuilderNamespaces, P := XMLParser;

TYPE
  Event = RECORD name: D.String; namespaceDecl: D.NamespaceDeclaration END;
  Capture = POINTER TO CaptureDesc;
  CaptureDesc = RECORD (B.BuilderDesc)
    starts, ends, attributes, declarations, documents: LONGINT;
    elements, attrs: ARRAY 128 OF Event;
    values: ARRAY 128 OF D.String;
  END;

PROCEDURE (b: Capture) StartElement(namespaceDecl: D.NamespaceDeclaration; localName: D.String);
BEGIN
  ASSERT(b.starts < LEN(b.elements), 201);
  b.elements[b.starts].name := localName; b.elements[b.starts].namespaceDecl := namespaceDecl;
  INC(b.starts)
END StartElement;

PROCEDURE (b: Capture) EndElement(namespaceDecl: D.NamespaceDeclaration; localName: D.String);
BEGIN INC(b.ends) END EndElement;

PROCEDURE (b: Capture) Attribute(namespaceDecl: D.NamespaceDeclaration; localName: D.String;
  attrDecl: D.AttrDecl; value: D.AttValue; specified: BOOLEAN);
BEGIN
  ASSERT(b.attributes < LEN(b.attrs), 202);
  b.attrs[b.attributes].name := localName; b.attrs[b.attributes].namespaceDecl := namespaceDecl;
  b.values[b.attributes] := value.Flatten(attrDecl); INC(b.attributes)
END Attribute;

PROCEDURE (b: Capture) NamespaceDeclaration(namespaceDecl: D.NamespaceDeclaration);
BEGIN INC(b.declarations) END NamespaceDeclaration;

PROCEDURE (b: Capture) EndDocument;
BEGIN INC(b.documents) END EndDocument;

PROCEDURE Parse(text: ARRAY OF CHAR; VAR b: Capture): P.Parser;
  VAR ch: Mem.Channel; writer: Ch.Writer; p: P.Parser; res: M.Msg;
BEGIN
  NEW(b); B.Init(b); b.starts := 0; b.ends := 0; b.attributes := 0;
  b.declarations := 0; b.documents := 0;
  ch := Mem.Tmp("", {Mem.read, Mem.write}, res); ASSERT(res = NIL, 203);
  writer := ch.NewWriter(); writer.WriteBytes(text, 0, S.Length8(text));
  p := P.NewChannel(ch, NIL, NIL, NIL, N.New(b));
  p.enforceQNames := TRUE; p.followExternalRef := FALSE; p.ParseDocument;
  ch.Close; ASSERT(b.documents = 1, 204); RETURN p
END Parse;

PROCEDURE Good(text: ARRAY OF CHAR): Capture;
  VAR b: Capture; p: P.Parser; msg: M.Msg; error: ARRAY 1024 OF CHAR;
BEGIN
  p := Parse(text, b); msg := p.errList.msgList;
  WHILE msg # NIL DO msg.GetText(error); Out.String(error); Out.Ln; msg := msg.nextMsg END;
  ASSERT((p.errList.msgCount = 0) & (b.starts = b.ends), 205); RETURN b
END Good;

PROCEDURE Bad(text: ARRAY OF CHAR);
  VAR b: Capture; p: P.Parser;
BEGIN
  p := Parse(text, b);
  IF p.errList.msgCount = 0 THEN Out.String("Accepted: "); Out.String(text); Out.Ln END;
  ASSERT(p.errList.msgCount > 0, 206)
END Bad;

PROCEDURE Check(event: Event; name, uri: ARRAY OF CHAR);
BEGIN
  ASSERT(S.Equal8(event.name^, name), 207);
  IF uri = "" THEN ASSERT(event.namespaceDecl = NIL, 208)
  ELSE ASSERT((event.namespaceDecl # NIL) & (event.namespaceDecl.uri^ = uri), 209)
  END
END Check;

PROCEDURE BasicChecks;
  VAR b: Capture;
BEGIN
  b := Good('<r a="one"><s b="two"/><t/></r>');
  ASSERT((b.starts = 3) & (b.attributes = 2) & (b.declarations = 0), 210);
  Check(b.elements[0], "r", ""); Check(b.attrs[0], "a", ""); Check(b.attrs[1], "b", "");
  ASSERT(S.Equal8(b.values[0]^, "one") & S.Equal8(b.values[1]^, "two"), 211);
  b := Good('<p:r p:a="v" xmlns:p="urn:one"><p:s xmlns:p="urn:two"/><p:t/></p:r>');
  ASSERT((b.starts = 3) & (b.attributes = 1) & (b.declarations = 2), 212);
  Check(b.elements[0], "r", "urn:one"); Check(b.elements[1], "s", "urn:two");
  Check(b.elements[2], "t", "urn:one"); Check(b.attrs[0], "a", "urn:one");
  b := Good('<r xmlns="urn:default" xmlns:p="urn:prefix" a="v"><p:s/><s xmlns=""><t/></s><t/></r>');
  ASSERT((b.starts = 5) & (b.attributes = 1), 213);
  Check(b.elements[0], "r", "urn:default"); Check(b.elements[1], "s", "urn:prefix");
  Check(b.elements[2], "s", ""); Check(b.elements[3], "t", "");
  Check(b.elements[4], "t", "urn:default"); Check(b.attrs[0], "a", "");
  b := Good('<r xml:lang="hy" xml:space="preserve"/>');
  ASSERT(b.attributes = 2, 214);
  Check(b.attrs[0], "lang", "http://www.w3.org/XML/1998/namespace");
  b := Good('<r xmlns:xml="http://www.w3.org/XML/1998/namespace" xml:lang="en"/>');
  Check(b.attrs[0], "lang", "http://www.w3.org/XML/1998/namespace");
  b := Good('<!DOCTYPE r [<!ATTLIST r xmlns:p CDATA "urn:default" p:a CDATA "v">]><r/>');
  ASSERT((b.attributes = 1) & (b.declarations = 1), 215);
  Check(b.attrs[0], "a", "urn:default")
END BasicChecks;

PROCEDURE RelativeChecks;
  VAR b: Capture;
BEGIN
  b := Good('<vCard xmlns="vcard-temp"><PHOTO/></vCard>');
  Check(b.elements[0], "vCard", "vcard-temp"); Check(b.elements[1], "PHOTO", "vcard-temp");
  b := Good('<r xmlns:p="../names?x=1#part" p:a="v"><p:s/></r>');
  Check(b.elements[1], "s", "../names?x=1#part"); Check(b.attrs[0], "a", "../names?x=1#part");
  Bad('<r xmlns="relative%XX"/>');
  b := Good('<r xmlns="relative name"/>'); Check(b.elements[0], "r", "relative%20name")
END RelativeChecks;

PROCEDURE UnicodeChecks;
  VAR text: ARRAY 128 OF CHAR; b: Capture;
BEGIN
  text := '<r xmlns:p="urn:';
  text[16] := 0D4X; text[17] := 0B1X; text[18] := '"'; text[19] := " ";
  text[20] := "p"; text[21] := ":"; text[22] := 0D4X; text[23] := 0B1X;
  text[24] := "="; text[25] := '"'; text[26] := "v"; text[27] := '"';
  text[28] := "/"; text[29] := ">"; text[30] := 0X;
  b := Good(text);
  ASSERT((b.attributes = 1) & (b.attrs[0].name[0] = 531H) &
    (b.attrs[0].namespaceDecl.uri^ = "urn:%D4%B1"), 216)
END UnicodeChecks;

PROCEDURE GrowthChecks;
  VAR text: ARRAY 2048 OF CHAR; pos, i: LONGINT; b: Capture;

  PROCEDURE Append(part: ARRAY OF CHAR);
    VAR j: LONGINT;
  BEGIN
    j := 0;
    WHILE part[j] # 0X DO text[pos] := part[j]; INC(pos); INC(j) END;
    text[pos] := 0X
  END Append;

BEGIN
  pos := 0;
  FOR i := 0 TO 31 DO Append('<p:r xmlns:p="urn:g">') END;
  FOR i := 0 TO 31 DO Append('</p:r>') END;
  b := Good(text); ASSERT((b.starts = 32) & (b.declarations = 32), 217);
  FOR i := 0 TO 31 DO Check(b.elements[i], "r", "urn:g") END;
  b := Good('<r a="1" b="2" c="3" d="4" e="5" f="6" g="7" h="8" i="9"/>');
  ASSERT(b.attributes = 9, 218)
END GrowthChecks;

BEGIN
  BasicChecks; RelativeChecks; UnicodeChecks; GrowthChecks;
  Bad("<p:r/>"); Bad('<r xmlns="urn:def" p:a="v"/>');
  Bad('<r xmlns:p="urn:one" xmlns:q="urn:one" p:a="1" q:a="2"/>');
  Bad('<r xmlns:p=""/>'); Bad('<r xmlns:p="urn:one" p:a:b="v"/>');
  Bad('<r xmlns:p="urn:one"><p:/></r>'); Bad("<:r/>");
  Bad('<r xmlns:xml="urn:wrong"/>'); Bad('<r xmlns:xmlns="urn:wrong"/>');
  Bad('<r xmlns:p="http://www.w3.org/XML/1998/namespace"/>');
  Bad('<r xmlns="http://www.w3.org/XML/1998/namespace"/>');
  Bad('<r xmlns:p="http://www.w3.org/2000/xmlns/"/>');
  Bad('<r xmlns:p="urn:%XX"/>');
  Out.String("XML namespace checks passed"); Out.Ln
END TestNamespaces.
