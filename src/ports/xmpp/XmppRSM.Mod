MODULE XmppRSM;

(* Bounded XEP-0059 request and result payloads. *)

IMPORT S := LongStrings, IntStr, T := XmppTypes, Items := XmppItems, IQ := XmppIQ;

CONST
  namespaceURI* = "http://jabber.org/protocol/rsm";
  maxCursorUnits* = 1024;
  firstPage* = 0; afterPage* = 1; beforePage* = 2; indexedPage* = 3;

TYPE
  Request* = RECORD
    maximum*, direction*, index*: LONGINT;
    cursor*: T.String;
  END;
  Result* = RECORD
    first*, last*: T.String;
    count*, index*: LONGINT;
    hasCount*, hasIndex*: BOOLEAN;
  END;

PROCEDURE White(text: T.String): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  IF text = NIL THEN RETURN TRUE END;
  FOR i := 0 TO S.Length(text^)-1 DO
    IF (text[i] # 32) & (text[i] # 9) & (text[i] # 10) & (text[i] # 13) THEN RETURN FALSE END
  END;
  RETURN TRUE
END White;

PROCEDURE Plain(item: Items.Item; maximum: LONGINT): T.String;
  VAR content: Items.Content; length, n: LONGINT; text: T.String;
BEGIN
  length := 0; content := item.content;
  WHILE content # NIL DO
    IF content.element # NIL THEN RETURN NIL END;
    n := S.Length(content.text^); IF n > maximum-length THEN RETURN NIL END;
    INC(length, n); content := content.next
  END;
  text := item.Text(); IF ~IQ.Value(text^, maximum) THEN RETURN NIL END;
  RETURN text
END Plain;

PROCEDURE Natural(text: T.String; VAR value: LONGINT): BOOLEAN;
  VAR i, n, digit: LONGINT;
BEGIN
  IF text = NIL THEN RETURN FALSE END;
  n := S.Length(text^); IF (n = 0) OR (n > 32) THEN RETURN FALSE END;
  value := 0;
  FOR i := 0 TO n-1 DO
    digit := text[i]-ORD("0");
    IF (digit < 0) OR (digit > 9) OR (value > (MAX(LONGINT)-digit) DIV 10) THEN RETURN FALSE END;
    value := value*10+digit
  END;
  RETURN TRUE
END Natural;

PROCEDURE Number(parent: Items.Item; name: ARRAY OF CHAR; value: LONGINT);
  VAR child: Items.Item; number: ARRAY 16 OF CHAR; text: T.String;
BEGIN
  child := Items.New(name, namespaceURI); IntStr.IntToStr(value, number);
  text := Items.Latin1(number); child.AddText(text^, 0, S.Length(text^)); parent.AddChild(child)
END Number;

PROCEDURE Build*(direction, maximum: LONGINT; cursor: ARRAY OF T.CodeUnit): Items.Item;
  VAR item, child: Items.Item;
BEGIN
  IF (maximum < 0) OR (direction < firstPage) OR (direction > beforePage) OR
     ~IQ.Value(cursor, maxCursorUnits) THEN RETURN NIL END;
  IF ((direction = firstPage) & (cursor[0] # 0)) OR
     ((direction = afterPage) & (cursor[0] = 0)) THEN RETURN NIL END;
  item := Items.New("set", namespaceURI); Number(item, "max", maximum);
  IF direction # firstPage THEN
    IF direction = afterPage THEN child := Items.New("after", namespaceURI)
    ELSE child := Items.New("before", namespaceURI)
    END;
    child.AddText(cursor, 0, S.Length(cursor)); item.AddChild(child)
  END;
  RETURN item
END Build;

PROCEDURE BuildIndex*(maximum, index: LONGINT): Items.Item;
  VAR item: Items.Item;
BEGIN
  IF (maximum < 0) OR (index < 0) THEN RETURN NIL END;
  item := Items.New("set", namespaceURI); Number(item, "max", maximum);
  Number(item, "index", index); RETURN item
END BuildIndex;

PROCEDURE ReadRequest*(item: Items.Item; VAR request: Request): BOOLEAN;
  VAR content: Items.Content; child: Items.Item; value: Request; text: T.String; seenMax, seenDirection: BOOLEAN;
BEGIN
  IF ~IQ.Named(item, namespaceURI, "set") THEN RETURN FALSE END;
  value.maximum := -1; value.direction := firstPage; value.index := 0;
  value.cursor := Items.Latin1(""); seenMax := FALSE; seenDirection := FALSE;
  content := item.content;
  WHILE content # NIL DO
    child := content.element;
    IF child # NIL THEN
      IF child.namespaceURI^ # namespaceURI THEN RETURN FALSE END;
      IF S.Equal8(child.name^, "max") THEN
        IF seenMax OR ~Natural(Plain(child, 32), value.maximum) THEN RETURN FALSE END;
        seenMax := TRUE
      ELSIF S.Equal8(child.name^, "after") OR S.Equal8(child.name^, "before") THEN
        IF seenDirection THEN RETURN FALSE END;
        text := Plain(child, maxCursorUnits); IF text = NIL THEN RETURN FALSE END;
        IF S.Equal8(child.name^, "after") THEN
          IF text[0] = 0 THEN RETURN FALSE END;
          value.direction := afterPage
        ELSE value.direction := beforePage
        END;
        value.cursor := text; seenDirection := TRUE
      ELSIF S.Equal8(child.name^, "index") THEN
        IF seenDirection OR ~Natural(Plain(child, 32), value.index) THEN RETURN FALSE END;
        value.direction := indexedPage; seenDirection := TRUE
      ELSE RETURN FALSE
      END
    ELSIF ~White(content.text) THEN RETURN FALSE
    END;
    content := content.next
  END;
  request := value; RETURN TRUE
END ReadRequest;

PROCEDURE ReadResult*(item: Items.Item; VAR result: Result): BOOLEAN;
  VAR content: Items.Content; child: Items.Item; value: Result; text: T.String; seenFirst, seenLast: BOOLEAN;
BEGIN
  IF ~IQ.Named(item, namespaceURI, "set") THEN RETURN FALSE END;
  value.first := NIL; value.last := NIL; value.count := 0; value.index := 0;
  value.hasCount := FALSE; value.hasIndex := FALSE; seenFirst := FALSE; seenLast := FALSE;
  content := item.content;
  WHILE content # NIL DO
    child := content.element;
    IF child # NIL THEN
      IF child.namespaceURI^ # namespaceURI THEN RETURN FALSE END;
      IF S.Equal8(child.name^, "first") THEN
        IF seenFirst THEN RETURN FALSE END;
        value.first := Plain(child, maxCursorUnits);
        IF (value.first = NIL) OR (value.first[0] = 0) THEN RETURN FALSE END;
        text := child.GetAttribute("", "index"); value.hasIndex := text # NIL;
        IF value.hasIndex & ~Natural(text, value.index) THEN RETURN FALSE END;
        seenFirst := TRUE
      ELSIF S.Equal8(child.name^, "last") THEN
        IF seenLast THEN RETURN FALSE END;
        value.last := Plain(child, maxCursorUnits);
        IF (value.last = NIL) OR (value.last[0] = 0) THEN RETURN FALSE END;
        seenLast := TRUE
      ELSIF S.Equal8(child.name^, "count") THEN
        IF value.hasCount OR ~Natural(Plain(child, 32), value.count) THEN RETURN FALSE END;
        value.hasCount := TRUE
      ELSE RETURN FALSE
      END
    ELSIF ~White(content.text) THEN RETURN FALSE
    END;
    content := content.next
  END;
  IF seenFirst # seenLast THEN RETURN FALSE END;
  IF value.hasCount & seenFirst THEN
    IF (value.count = 0) OR (value.hasIndex & (value.index >= value.count)) THEN RETURN FALSE END
  END;
  result := value; RETURN TRUE
END ReadResult;

END XmppRSM.
