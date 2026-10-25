MODULE TestBasic;

IMPORT Out, S := LongStrings, M := Msg, Mem := IOMemory, Ch := Channel,
  URI, URIParser, D := XMLDTD, E := XMLBasicElement, T := XMLBasicDataType,
  P := XMLBasicParser, L := XMLLocator, Err := XMLError, W := XMLWriter,
  C := XMLUnicodeCodec, Limits := XMLLimits, XMLUnicodeCodecImportAll;

TYPE
  Node = POINTER TO NodeDesc;
  NodeDesc = RECORD (E.ElementDesc)
    children: E.List; text: E.PCData; depth, number: LONGINT;
    located, hasNumber: BOOLEAN; position: L.Position; href: URI.URI;
  END;

VAR base: URI.URI; result: M.Msg; factory: E.RootFactory;
  options: SET; created, located, completed: LONGINT;
  rootName, required, semantic: D.String;
  initValue: D.AttValue; unicodeXML: ARRAY 6 OF CHAR;

PROCEDURE NewNode(depth: LONGINT): Node;
  VAR node: Node;
BEGIN
  NEW(node); E.InitElement(node); node.children := E.NewList(); node.text := E.NewPCData();
  node.depth := depth; node.number := 0; node.located := FALSE; node.hasNumber := FALSE;
  node.href := NIL; INC(created); RETURN node
END NewNode;

PROCEDURE Root(): E.Element;
BEGIN RETURN NewNode(0) END Root;

PROCEDURE (node: Node) SetLocator(locator: L.Locator);
BEGIN
  ASSERT(~node.located & (locator # NIL), 1);
  node.located := TRUE; node.position := locator^; INC(located)
END SetLocator;

PROCEDURE (node: Node) IsChildName(name: E.String): BOOLEAN;
BEGIN ASSERT(node.located, 2); RETURN S.Equal(name^, rootName^) END IsChildName;

PROCEDURE (node: Node) NewChild(name: E.String): E.Element;
BEGIN
  IF 4 IN options THEN RETURN NIL END;
  RETURN NewNode(node.depth+1)
END NewChild;

PROCEDURE (node: Node) AddChild(child: E.Element);
BEGIN ASSERT(node.located, 3); node.children.Append(child) END AddChild;

PROCEDURE (node: Node) MissingChild(): E.String;
BEGIN
  IF (1 IN options) & node.children.IsEmpty() THEN RETURN rootName END;
  RETURN NIL
END MissingChild;

PROCEDURE (node: Node) IsAttributeName(name: E.String): BOOLEAN;
BEGIN ASSERT(node.located, 4); RETURN S.Equal8(name^, "n") OR S.Equal8(name^, "href") END IsAttributeName;

PROCEDURE (node: Node) AddAttribute(name: E.String; value: E.AttValue): BOOLEAN;
BEGIN
  ASSERT(node.located, 5);
  IF S.Equal8(name^, "n") THEN
    node.hasNumber := T.GetIntAttr(value, node.number); RETURN node.hasNumber
  ELSE RETURN T.GetURIAttr(value, node.position.entity.baseURI, node.href)
  END
END AddAttribute;

PROCEDURE (node: Node) MissingAttribute(): E.String;
BEGIN
  IF (0 IN options) & ~node.hasNumber THEN RETURN required END;
  RETURN NIL
END MissingAttribute;

PROCEDURE (node: Node) HasMixedContent(): BOOLEAN;
BEGIN RETURN ~(3 IN options) END HasMixedContent;

PROCEDURE (node: Node) AddCharacters(VAR chars: E.StringVar; start, end: E.CharPos);
BEGIN ASSERT(node.located, 6); node.text.AddCharacters(chars, start, end) END AddCharacters;

PROCEDURE (node: Node) CheckElement(): E.String;
BEGIN
  INC(completed);
  IF 2 IN options THEN RETURN semantic END;
  RETURN NIL
END CheckElement;

PROCEDURE (node: Node) Write(writer: W.Writer);
BEGIN
  writer.StartTag(rootName^, TRUE);
  IF node.hasNumber THEN writer.AttrInt(required^, node.number) END;
  node.text.Write(writer); node.children.Write(writer); writer.EndTag
END Write;

PROCEDURE Memory(): Mem.Channel;
  VAR ch: Mem.Channel; res: M.Msg;
BEGIN
  ch := Mem.Tmp("", {Mem.read, Mem.write}, res); ASSERT(res = NIL, 7); RETURN ch
END Memory;

PROCEDURE Errors(list: Err.List);
  VAR msg: M.Msg; text: ARRAY 1024 OF CHAR;
BEGIN
  IF list # NIL THEN
    msg := list.msgList;
    WHILE msg # NIL DO msg.GetText(text); Out.String(text); Out.Ln; msg := msg.nextMsg END
  END
END Errors;

PROCEDURE Parse(text: ARRAY OF CHAR; depth: LONGINT; flags: SET; valid: BOOLEAN): Node;
  VAR ch: Mem.Channel; writer: Ch.Writer; node: E.Element; list: Err.List;
BEGIN
  ch := Memory(); writer := ch.NewWriter(); writer.WriteBytes(text, 0, S.Length8(text));
  created := 0; located := 0; completed := 0;
  node := P.Parse(ch.NewReader(), base, NIL, factory, depth, flags, list); ch.Close;
  IF (node # NIL) # valid THEN Errors(list); Out.String(text); Out.Ln END;
  ASSERT((node # NIL) = valid, 8); ASSERT((list = NIL) = valid, 9);
  IF valid THEN
    ASSERT((created = located) & (created = completed), 10); RETURN node(Node)
  ELSE ASSERT(list.msgCount > 0, 11); RETURN NIL
  END
END Parse;

PROCEDURE ParserChecks;
  VAR node, child: Node; ch: Mem.Channel; writer: W.Writer; bytes: ARRAY 2048 OF CHAR;
    i, pos: LONGINT;
BEGIN
  options := {}; node := Parse('<r n="42" href="child"><r/>text</r>', -1, {}, TRUE);
  ASSERT((node.number = 42) & (node.position.charIndex = 1), 12);
  node.href.GetString(bytes); ASSERT(bytes = "file:/xml-tests/child", 13);
  ASSERT(S.Equal8(node.text.chars.array^, "text"), 14);
  ASSERT(node.children.head = node.children.tail, 15);
  child := node.children.head(Node); ASSERT((child.depth = 1) & child.children.IsEmpty(), 16);
  ch := Memory(); writer := W.New(ch.NewWriter(), C.GetFactory("UTF-8"), FALSE, -1);
  node.Write(writer); writer.EndOfText;
  ASSERT((ch.Length() = 25) & (writer.writer.res = NIL), 17); ch.Close;
  options := {0}; node := Parse('<r n="-2147483648"/>', 0, {}, TRUE);
  ASSERT(node.number = MIN(LONGINT), 18);
  node := Parse('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r n CDATA "7">]><r/>', 0, {P.validate}, TRUE);
  ASSERT(node.number = 7, 19);
  node := Parse('<!DOCTYPE r [<!ELEMENT r EMPTY><!ATTLIST r n CDATA #REQUIRED>]><r/>', 0, {P.validate}, FALSE);
  node := Parse('<r/>', 0, {}, FALSE);
  options := {}; node := Parse('<unknown><r/></unknown>', -1, {}, FALSE);
  node := Parse('<r><unknown/></r>', -1, {}, FALSE);
  node := Parse('<r bad="1"/>', -1, {}, FALSE);
  node := Parse('<r n="wrong"/>', -1, {}, FALSE);
  node := Parse('<r><r/></r>', 0, {}, FALSE);
  node := Parse('<r><r/></r>', 1, {}, TRUE);
  node := Parse('<r>', -1, {}, FALSE);
  node := Parse('<r/><r/>', -1, {}, FALSE);
  options := {1}; node := Parse('<r/>', -1, {}, FALSE);
  options := {2}; node := Parse('<r/>', -1, {}, FALSE);
  options := {3}; node := Parse('<r> </r>', -1, {}, TRUE);
  node := Parse('<r>text</r>', -1, {}, FALSE);
  options := {4}; node := Parse('<r><r/></r>', -1, {}, FALSE);
  options := {}; pos := 0;
  FOR i := 0 TO 63 DO bytes[pos] := "<"; bytes[pos+1] := "r"; bytes[pos+2] := ">"; INC(pos, 3) END;
  FOR i := 0 TO 63 DO
    bytes[pos] := "<"; bytes[pos+1] := "/"; bytes[pos+2] := "r"; bytes[pos+3] := ">"; INC(pos, 4)
  END;
  bytes[pos] := 0X; node := Parse(bytes, -1, {}, TRUE);
  ASSERT((created = 64) & (node.depth = 0), 20);
  FOR i := 1 TO 63 DO node := node.children.head(Node); ASSERT(node.depth = i, 21) END
END ParserChecks;

PROCEDURE Value(text: ARRAY OF CHAR): D.AttValue;
  VAR b: D.Builder; value: D.AttValue; units: D.String;
BEGIN
  b := D.New(); NEW(units, S.Length8(text)+1); S.Long(text, units^);
  value := b.NewAttValue(); value.Append(b.NewCharacters(units, 0, S.Length(units^), FALSE)); RETURN value
END Value;

PROCEDURE DataChecks;
  VAR value: D.AttValue; number, i: LONGINT; bytes: ARRAY 8 OF CHAR;
    long: ARRAY 40001 OF CHAR; uri: URI.URI; units: ARRAY 8 OF D.Char;
BEGIN
  ASSERT(T.GetIntAttr(Value("2147483647"), number) & (number = MAX(LONGINT)), 22);
  ASSERT(~T.GetIntAttr(Value("2147483648"), number), 23);
  ASSERT(~T.GetIntAttr(Value("-2147483649"), number), 24);
  FOR i := 0 TO 39998 DO long[i] := "0" END; long[39999] := "x"; long[40000] := 0X;
  ASSERT(~T.GetIntAttr(Value(long), number), 25);
  bytes := "keep";
  ASSERT(~T.GetStringLatin1Attr(Value("too long"), bytes) & (bytes = "keep"), 26);
  units[0] := 531H; units[1] := 0;
  value := Value("x"); value.fragmentList(D.Characters).source[0] := units[0];
  ASSERT(~T.GetStringLatin1Attr(value, bytes) & (bytes = "keep"), 27);
  ASSERT(T.GetStringLatin1Attr(Value("short"), bytes) & (bytes = "short"), 28);
  value := Value("path"); ASSERT(T.GetURIAttr(value, base, uri), 29);
  value := Value("bad%"); ASSERT(~T.GetURIAttr(value, base, uri), 30);
  value := Value("a"); value.fragmentList(D.Characters).source[0] := 0D800H;
  ASSERT(~T.GetURIAttr(value, base, uri) & (uri = NIL), 31)
END DataChecks;

PROCEDURE BufferChecks;
  VAR pcdata: E.PCData; buffer: E.StringBuffer; units: D.String;
    initial: ARRAY 16 OF D.Char; i: LONGINT;
BEGIN
  S.Long(" a  b ", initial); pcdata := E.NewPCData(); pcdata.AddCharacters(initial, 0, S.Length(initial));
  pcdata.Normalize(TRUE, TRUE); ASSERT(S.Equal8(pcdata.chars.array^, "a b"), 32);
  S.Long("  ", initial); pcdata := E.NewPCData(); pcdata.AddCharacters(initial, 0, 2);
  pcdata.Normalize(TRUE, TRUE); ASSERT(pcdata.chars.length = 0, 33);
  S.Long("a", initial); buffer := E.NewStringBuffer(initial); initial[0] := 98;
  ASSERT(buffer.array[0] = 97, 34);
  NEW(units, 70001); FOR i := 0 TO 69999 DO units[i] := 531H END; units[70000] := 0;
  units[8191] := 0D83DH; units[8192] := 0DE42H;
  buffer.AddCharacters(units^, 0, 70000);
  ASSERT((buffer.length = 70001) & (buffer.array[70001] = 0), 35);
  FOR i := 0 TO 69999 DO ASSERT(buffer.array[i+1] = units[i], 36) END;
  pcdata := E.NewPCData(); pcdata.AddCharacters(units^, 8191, 8193); pcdata.Normalize(TRUE, TRUE);
  ASSERT((pcdata.chars.length = 2) & (pcdata.chars.array[0] = 0D83DH), 37)
END BufferChecks;

PROCEDURE LimitedChecks;
  VAR budget: Limits.Budget; ch: Mem.Channel; writer: Ch.Writer;
    node: E.Element; list: Err.List; i: LONGINT; text: ARRAY 64 OF CHAR;
BEGIN
  options := {}; text := '<r><r/>text</r>';
  FOR i := 0 TO 200 DO
    ch := Memory(); writer := ch.NewWriter(); writer.WriteBytes(text, 0, S.Length8(text));
    budget := Limits.New(); budget.maxWork := i;
    created := 0; located := 0; completed := 0;
    node := P.ParseLimited(ch.NewReader(), base, NIL, factory, -1, {}, budget, list);
    IF budget.error # NIL THEN ASSERT((node = NIL) & (list # NIL), 40)
    ELSE ASSERT((node # NIL) & (list = NIL), 41)
    END;
    ASSERT(budget.depth = 0, 42); ch.Close
  END
END LimitedChecks;

BEGIN
  base := URIParser.NewURI("file:/xml-tests/document.xml", NIL, result); ASSERT(result = NIL, 38);
  initValue := Value("r"); rootName := initValue.Flatten(NIL);
  initValue := Value("n"); required := initValue.Flatten(NIL);
  initValue := Value("element consistency failure"); semantic := initValue.Flatten(NIL);
  factory := E.NewRootFactory(); factory.AddFactory(rootName^, Root);
  ParserChecks; DataChecks; BufferChecks; LimitedChecks;
  rootName[0] := 531H; factory.AddFactory(rootName^, Root);
  options := {};
  unicodeXML[0] := "<"; unicodeXML[1] := 0D4X; unicodeXML[2] := 0B1X;
  unicodeXML[3] := "/"; unicodeXML[4] := ">"; unicodeXML[5] := 0X;
  ASSERT(Parse(unicodeXML, -1, {}, TRUE) # NIL, 39);
  Out.String("XML basic element checks passed"); Out.Ln
END TestBasic.
