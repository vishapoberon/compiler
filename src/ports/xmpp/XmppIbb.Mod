MODULE XmppIbb;

(* IQ-based XEP-0047 payloads and bounded decoding. *)

IMPORT S := LongStrings, IntStr, T := XmppTypes, Items := XmppItems,
  IQ := XmppIQ, B := XmppBase64;

CONST
  namespaceURI* = "http://jabber.org/protocol/ibb";
  defaultBlockSize* = 1024; maxBlockSize* = B.maxBytes; maxSIDUnits* = 128;
  opening* = 0; data* = 1; closing* = 2;

TYPE
  Event* = POINTER TO EventDesc;
  EventDesc* = RECORD
    kind-: SHORTINT;
    sid-: T.String;
    blockSize-, sequence-, length-: LONGINT;
    bytes-: Items.Bytes;
  END;

PROCEDURE SID*(text: ARRAY OF T.CodeUnit): BOOLEAN;
  VAR i, code: LONGINT;
BEGIN
  IF (S.Length(text) = 0) OR ~IQ.Value(text, maxSIDUnits) THEN RETURN FALSE END;
  i := 0;
  WHILE text[i] # 0 DO
    code := text[i]; INC(i);
    IF (code >= 0D800H) & (code <= 0DBFFH) THEN
      code := 10000H+(code-0D800H)*400H+text[i]-0DC00H; INC(i)
    END;
    (* XML 1.0 NMTOKEN permits NameChar at every position. *)
    IF ~((code = 3AH) OR (code = 5FH) OR (code = 2DH) OR (code = 2EH) OR
      ((code >= 30H) & (code <= 39H)) OR ((code >= 41H) & (code <= 5AH)) OR
      ((code >= 61H) & (code <= 7AH)) OR (code = 0B7H) OR
      ((code >= 0C0H) & (code <= 0D6H)) OR ((code >= 0D8H) & (code <= 0F6H)) OR
      ((code >= 0F8H) & (code <= 37DH)) OR ((code >= 37FH) & (code <= 1FFFH)) OR
      ((code >= 200CH) & (code <= 200DH)) OR ((code >= 203FH) & (code <= 2040H)) OR
      ((code >= 2070H) & (code <= 218FH)) OR ((code >= 2C00H) & (code <= 2FEFH)) OR
      ((code >= 3001H) & (code <= 0D7FFH)) OR ((code >= 0F900H) & (code <= 0FDCFH)) OR
      ((code >= 0FDF0H) & (code <= 0FFFDH)) OR ((code >= 10000H) & (code <= 0EFFFFH))) THEN RETURN FALSE END
  END;
  RETURN TRUE
END SID;

PROCEDURE Number(item: Items.Item; name: ARRAY OF CHAR; maximum: LONGINT; VAR value: LONGINT): BOOLEAN;
  VAR text: T.String; i, digit: LONGINT;
BEGIN
  value := 0; text := item.GetAttribute("", name);
  IF (text = NIL) OR (S.Length(text^) = 0) OR (S.Length(text^) > 5) THEN RETURN FALSE END;
  FOR i := 0 TO S.Length(text^)-1 DO
    digit := text[i]-ORD("0");
    IF (digit < 0) OR (digit > 9) OR (value > (maximum-digit) DIV 10) THEN RETURN FALSE END;
    value := value*10+digit
  END;
  RETURN TRUE
END Number;

PROCEDURE SetNumber(item: Items.Item; name: ARRAY OF CHAR; value: LONGINT);
  VAR number: ARRAY 16 OF CHAR; text: T.String;
BEGIN IntStr.IntToStr(value, number); text := Items.Latin1(number); item.SetParam(name, text^) END SetNumber;

PROCEDURE Open*(sid: ARRAY OF T.CodeUnit; blockSize: LONGINT): Items.Item;
  VAR item: Items.Item; text: T.String;
BEGIN
  IF ~SID(sid) OR (blockSize < 1) OR (blockSize > maxBlockSize) THEN RETURN NIL END;
  item := Items.New("open", namespaceURI); item.SetParam("sid", sid); SetNumber(item, "block-size", blockSize);
  text := Items.Latin1("iq"); item.SetParam("stanza", text^); RETURN item
END Open;

PROCEDURE Data*(sid: ARRAY OF T.CodeUnit; sequence: LONGINT; bytes: ARRAY OF CHAR; start, count: LONGINT): Items.Item;
  VAR item: Items.Item; encoded: Items.Bytes; text: T.String;
BEGIN
  IF ~SID(sid) OR (sequence < 0) OR (sequence > 65535) THEN RETURN NIL END;
  encoded := B.Encode(bytes, start, count); IF encoded = NIL THEN RETURN NIL END;
  item := Items.New("data", namespaceURI); item.SetParam("sid", sid); SetNumber(item, "seq", sequence);
  text := Items.Latin1(encoded^); item.AddText(text^, 0, S.Length(text^)); RETURN item
END Data;

PROCEDURE Close*(sid: ARRAY OF T.CodeUnit): Items.Item;
  VAR item: Items.Item;
BEGIN
  IF ~SID(sid) THEN RETURN NIL END;
  item := Items.New("close", namespaceURI); item.SetParam("sid", sid); RETURN item
END Close;

PROCEDURE NextSequence*(sequence: LONGINT): LONGINT;
BEGIN
  IF (sequence < 0) OR (sequence > 65535) THEN RETURN -1 END;
  RETURN (sequence+1) MOD 65536
END NextSequence;

PROCEDURE Text(item: Items.Item; maximum: LONGINT): Items.Bytes;
  VAR content: Items.Content; count, parts, i, j, units: LONGINT; bytes: Items.Bytes;
BEGIN
  count := 0; parts := 0; content := item.content;
  WHILE content # NIL DO
    INC(parts); IF (parts > 128) OR (content.element # NIL) THEN RETURN NIL END;
    units := S.Length(content.text^); IF units > maximum-count THEN RETURN NIL END;
    INC(count, units); content := content.next
  END;
  NEW(bytes, count+1); j := 0; content := item.content;
  WHILE content # NIL DO
    FOR i := 0 TO S.Length(content.text^)-1 DO
      IF content.text[i] > 127 THEN RETURN NIL END;
      bytes[j] := CHR(content.text[i]); INC(j)
    END;
    content := content.next
  END;
  bytes[count] := 0X; RETURN bytes
END Text;

PROCEDURE Read*(item: Items.Item; maximumBlock: LONGINT): Event;
  VAR event: Event; sid, stanza: T.String; encoded: Items.Bytes;
BEGIN
  IF (item = NIL) OR (item.namespaceURI^ # namespaceURI) OR
     (maximumBlock < 1) OR (maximumBlock > maxBlockSize) THEN RETURN NIL END;
  sid := item.GetAttribute("", "sid"); IF (sid = NIL) OR ~SID(sid^) THEN RETURN NIL END;
  NEW(event); event.sid := Items.Copy16(sid^);
  IF S.Equal8(item.name^, "open") THEN
    event.kind := opening;
    IF ~IQ.Empty(item) OR ~Number(item, "block-size", maxBlockSize, event.blockSize) OR (event.blockSize = 0) THEN RETURN NIL END;
    stanza := item.GetAttribute("", "stanza");
    IF (stanza # NIL) & ~S.Equal8(stanza^, "iq") THEN RETURN NIL END
  ELSIF S.Equal8(item.name^, "data") THEN
    event.kind := data;
    IF ~Number(item, "seq", 65535, event.sequence) THEN RETURN NIL END;
    encoded := Text(item, 4*((maximumBlock+2) DIV 3)); IF encoded = NIL THEN RETURN NIL END;
    event.bytes := B.Decode(encoded^, S.Length8(encoded^), maximumBlock, event.length);
    IF event.bytes = NIL THEN RETURN NIL END
  ELSIF S.Equal8(item.name^, "close") THEN
    event.kind := closing; IF ~IQ.Empty(item) THEN RETURN NIL END
  ELSE RETURN NIL
  END;
  RETURN event
END Read;

END XmppIbb.
