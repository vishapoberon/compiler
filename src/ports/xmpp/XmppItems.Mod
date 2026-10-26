MODULE XmppItems;

(* Namespace-aware stanza trees. Text nodes retain mixed-content order and
   UTF-16 code units. Wire namespace URIs are UTF-8, as in XMLDTD. *)

IMPORT S := LongStrings, T := XmppTypes, C := XMLUnicodeCodec, CodecUTF8 := XMLUnicodeCodecUTF8;

TYPE
  Bytes* = POINTER TO ARRAY OF CHAR;
  Attribute* = POINTER TO AttributeDesc;
  AttributeDesc* = RECORD
    next-: Attribute;
    name-, value-: T.String;
    namespaceURI-: Bytes;
  END;
  Item* = POINTER TO ItemDesc;
  Content* = POINTER TO ContentDesc;
  ContentDesc* = RECORD
    next-: Content;
    element-: Item;
    text-: T.String;
  END;
  ItemDesc* = RECORD
    name-: T.String;
    namespaceURI-: Bytes;
    parent-: Item;
    attributes-, lastAttribute: Attribute;
    content-, lastContent: Content;
  END;

PROCEDURE Copy16*(text: ARRAY OF T.CodeUnit): T.String;
  VAR copy: T.String;
BEGIN NEW(copy, S.Length(text)+1); S.Assign(text, copy^); RETURN copy END Copy16;

PROCEDURE Copy8*(text: ARRAY OF CHAR): Bytes;
  VAR copy: Bytes;
BEGIN NEW(copy, S.Length8(text)+1); COPY(text, copy^); RETURN copy END Copy8;

PROCEDURE Latin1*(text: ARRAY OF CHAR): T.String;
  VAR copy: T.String;
BEGIN NEW(copy, S.Length8(text)+1); S.Long(text, copy^); RETURN copy END Latin1;

PROCEDURE UTF8*(bytes: ARRAY OF CHAR): T.String;
  VAR text: T.String; codec: C.Codec; pos, out, length: LONGINT;
BEGIN
  length := S.Length8(bytes); NEW(text, length+2);
  codec := CodecUTF8.factory.NewCodec(); pos := 0; out := 0;
  WHILE pos < length DO codec.Decode(bytes, pos, length, text^, out, length+1, pos, out) END;
  IF codec.invalidChars # 0 THEN RETURN NIL END;
  text[out] := 0; RETURN text
END UTF8;

PROCEDURE UTF8Bytes*(text: ARRAY OF T.CodeUnit): Bytes;
  VAR source: T.String; bytes: Bytes; codec: C.Codec; pos, out, length, i: LONGINT;
BEGIN
  source := Copy16(text); length := S.Length(source^);
  IF length > (MAX(LONGINT)-8) DIV 3 THEN RETURN NIL END;
  FOR i := 0 TO length-1 DO IF (source[i] < 0) OR (source[i] > 0FFFFH) THEN RETURN NIL END END;
  NEW(bytes, 3*length+8); codec := CodecUTF8.factory.NewCodec(); pos := 0; out := 0;
  WHILE pos < length DO codec.Encode(source^, pos, length, bytes^, out, LEN(bytes^)-1, pos, out) END;
  IF codec.invalidChars # 0 THEN RETURN NIL END;
  bytes[out] := 0X; RETURN bytes
END UTF8Bytes;

PROCEDURE New16*(name: ARRAY OF T.CodeUnit; namespaceURI: ARRAY OF CHAR): Item;
  VAR item: Item;
BEGIN
  NEW(item); item.name := Copy16(name); item.namespaceURI := Copy8(namespaceURI);
  RETURN item
END New16;

PROCEDURE New*(name, namespaceURI: ARRAY OF CHAR): Item;
  VAR units: T.String;
BEGIN units := Latin1(name); RETURN New16(units^, namespaceURI) END New;

PROCEDURE (item: Item) AddChild*(child: Item);
  VAR content: Content; ancestor: Item;
BEGIN
  ASSERT((child # NIL) & (child.parent = NIL));
  ancestor := item;
  WHILE ancestor # NIL DO ASSERT(ancestor # child); ancestor := ancestor.parent END;
  NEW(content); content.element := child; child.parent := item;
  IF item.lastContent = NIL THEN item.content := content ELSE item.lastContent.next := content END;
  item.lastContent := content
END AddChild;

PROCEDURE (item: Item) AddText*(text: ARRAY OF T.CodeUnit; start, end: LONGINT);
  VAR content: Content; i: LONGINT;
BEGIN
  ASSERT((start >= 0) & (start <= end) & (end <= LEN(text)));
  IF start = end THEN RETURN END;
  NEW(content); NEW(content.text, end-start+1);
  FOR i := start TO end-1 DO content.text[i-start] := text[i] END;
  content.text[end-start] := 0;
  IF item.lastContent = NIL THEN item.content := content ELSE item.lastContent.next := content END;
  item.lastContent := content
END AddText;

PROCEDURE (item: Item) SetAttribute*(name: ARRAY OF T.CodeUnit; namespaceURI: ARRAY OF CHAR;
                                    value: ARRAY OF T.CodeUnit);
  VAR attr: Attribute;
BEGIN
  attr := item.attributes;
  WHILE (attr # NIL) & ~((attr.namespaceURI^ = namespaceURI) & S.Equal(attr.name^, name)) DO
    attr := attr.next
  END;
  IF attr = NIL THEN
    NEW(attr); attr.name := Copy16(name); attr.namespaceURI := Copy8(namespaceURI);
    IF item.lastAttribute = NIL THEN item.attributes := attr ELSE item.lastAttribute.next := attr END;
    item.lastAttribute := attr
  END;
  attr.value := Copy16(value)
END SetAttribute;

PROCEDURE (item: Item) SetParam*(name: ARRAY OF CHAR; value: ARRAY OF T.CodeUnit);
  VAR units: T.String;
BEGIN units := Latin1(name); item.SetAttribute(units^, "", value) END SetParam;

PROCEDURE (item: Item) GetAttribute*(namespaceURI, name: ARRAY OF CHAR): T.String;
  VAR attr: Attribute;
BEGIN
  attr := item.attributes;
  WHILE attr # NIL DO
    IF (attr.namespaceURI^ = namespaceURI) & S.Equal8(attr.name^, name) THEN RETURN attr.value END;
    attr := attr.next
  END;
  RETURN NIL
END GetAttribute;

PROCEDURE (item: Item) First*(namespaceURI, name: ARRAY OF CHAR): Item;
  VAR content: Content;
BEGIN
  content := item.content;
  WHILE content # NIL DO
    IF (content.element # NIL) & (content.element.namespaceURI^ = namespaceURI) &
       S.Equal8(content.element.name^, name) THEN RETURN content.element END;
    content := content.next
  END;
  RETURN NIL
END First;

PROCEDURE (item: Item) Text*(): T.String;
(* Concatenates this element's direct text nodes. Child element text is separate. *)
  VAR content: Content; text: T.String; length, n, i: LONGINT;
BEGIN
  length := 0; content := item.content;
  WHILE content # NIL DO
    IF content.text # NIL THEN
      n := S.Length(content.text^); ASSERT(n < MAX(LONGINT)-length); INC(length, n)
    END;
    content := content.next
  END;
  NEW(text, length+1); length := 0; content := item.content;
  WHILE content # NIL DO
    IF content.text # NIL THEN
      n := S.Length(content.text^);
      FOR i := 0 TO n-1 DO text[length+i] := content.text[i] END;
      INC(length, n)
    END;
    content := content.next
  END;
  text[length] := 0; RETURN text
END Text;

END XmppItems.
