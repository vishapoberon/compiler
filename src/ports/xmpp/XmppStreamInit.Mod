MODULE XmppStreamInit;

(* Bounded XEP-0095/0096 file offers and transport selection. *)

IMPORT Msg, S := LongStrings, IntStr, T := XmppTypes, Items := XmppItems,
  IQ := XmppIQ, I := XmppIbb;

CONST
  namespaceURI* = "http://jabber.org/protocol/si";
  fileURI* = "http://jabber.org/protocol/si/profile/file-transfer";
  featureURI* = "http://jabber.org/protocol/feature-neg";
  formURI* = "jabber:x:data";
  socksURI* = "http://jabber.org/protocol/bytestreams";
  ibb* = 0; socks5* = 1;
  maxFileBytes* = 1024*1024*1024; maxNameUnits* = 1024; maxDescriptionUnits* = 4096;

TYPE
  Offer* = POINTER TO OfferDesc;
  OfferDesc* = RECORD
    sid*, name*, description*, mime*, hash*, date*: T.String;
    size*: LONGINT;
    range*: BOOLEAN;
    methods*: SET
  END;
  Selection* = POINTER TO SelectionDesc;
  SelectionDesc* = RECORD
    method-, offset-, length-: LONGINT;
    sid-: T.String
  END;
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (c: Context) GetTemplate(message: Msg.Msg; VAR text: Msg.LString);
BEGIN S.Long("Invalid bounded XMPP file offer or explicit peer", text) END GetTemplate;

PROCEDURE Named(item: Items.Item; uri, name: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN IQ.Named(item, uri, name) END Named;

PROCEDURE White(text: T.String): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  IF S.Length(text^) > maxDescriptionUnits THEN RETURN FALSE END;
  FOR i := 0 TO S.Length(text^)-1 DO
    IF (text[i] # 32) & (text[i] # 9) & (text[i] # 10) & (text[i] # 13) THEN RETURN FALSE END
  END;
  RETURN TRUE
END White;

PROCEDURE Layout(item: Items.Item; VAR first: Items.Item): LONGINT;
  VAR content: Items.Content; count, parts: LONGINT;
BEGIN
  first := NIL; count := 0; parts := 0; content := item.content;
  WHILE content # NIL DO
    INC(parts); IF parts > 32 THEN RETURN -1 END;
    IF content.element # NIL THEN
      IF first = NIL THEN first := content.element END;
      INC(count)
    ELSIF ~White(content.text) THEN RETURN -1
    END;
    content := content.next
  END;
  RETURN count
END Layout;

PROCEDURE Scalar(item: Items.Item; maximum: LONGINT): T.String;
  VAR content: Items.Content; count, parts: LONGINT; text: T.String;
BEGIN
  count := 0; parts := 0; content := item.content;
  WHILE content # NIL DO
    INC(parts); IF (parts > 32) OR (content.element # NIL) THEN RETURN NIL END;
    IF S.Length(content.text^) > maximum-count THEN RETURN NIL END;
    INC(count, S.Length(content.text^)); content := content.next
  END;
  text := item.Text(); IF ~IQ.Value(text^, maximum) THEN RETURN NIL END; RETURN text
END Scalar;

PROCEDURE Attr(item: Items.Item; name: ARRAY OF CHAR; maximum: LONGINT; required: BOOLEAN): T.String;
  VAR text: T.String;
BEGIN
  text := item.GetAttribute("", name);
  IF text = NIL THEN IF required THEN RETURN NIL ELSE RETURN Items.Latin1("") END END;
  IF ~IQ.Value(text^, maximum) OR (required & (text[0] = 0)) THEN RETURN NIL END;
  RETURN Items.Copy16(text^)
END Attr;

PROCEDURE Number(item: Items.Item; name: ARRAY OF CHAR; VAR value: LONGINT): BOOLEAN;
  VAR text: T.String; i, digit: LONGINT;
BEGIN
  text := item.GetAttribute("", name); value := 0;
  IF (text = NIL) OR (S.Length(text^) = 0) OR (S.Length(text^) > 10) THEN RETURN FALSE END;
  FOR i := 0 TO S.Length(text^)-1 DO
    digit := text[i]-ORD("0");
    IF (digit < 0) OR (digit > 9) OR (value > (maxFileBytes-digit) DIV 10) THEN RETURN FALSE END;
    value := value*10+digit
  END;
  RETURN TRUE
END Number;

PROCEDURE Set(item: Items.Item; name: ARRAY OF CHAR; value: ARRAY OF T.CodeUnit);
BEGIN item.SetParam(name, value) END Set;

PROCEDURE ASCII(item: Items.Item; name, value: ARRAY OF CHAR);
  VAR text: T.String;
BEGIN text := Items.Latin1(value); Set(item, name, text^) END ASCII;

PROCEDURE SetNumber(item: Items.Item; name: ARRAY OF CHAR; value: LONGINT);
  VAR text: ARRAY 16 OF CHAR;
BEGIN IntStr.IntToStr(value, text); ASCII(item, name, text) END SetNumber;

PROCEDURE Hash(text: T.String): BOOLEAN;
  VAR i: LONGINT; code: T.CodeUnit;
BEGIN
  IF text = NIL THEN RETURN FALSE END;
  IF text[0] = 0 THEN RETURN TRUE END;
  IF S.Length(text^) # 32 THEN RETURN FALSE END;
  FOR i := 0 TO 31 DO
    code := text[i];
    IF ~(((code >= ORD("0")) & (code <= ORD("9"))) OR ((code >= ORD("a")) & (code <= ORD("f"))) OR
      ((code >= ORD("A")) & (code <= ORD("F")))) THEN RETURN FALSE END
  END;
  RETURN TRUE
END Hash;

PROCEDURE Valid(offer: Offer): BOOLEAN;
BEGIN
  RETURN (offer # NIL) & (offer.sid # NIL) & I.SID(offer.sid^) &
    (offer.name # NIL) & (offer.name[0] # 0) & IQ.Value(offer.name^, maxNameUnits) &
    (offer.description # NIL) & IQ.Value(offer.description^, maxDescriptionUnits) &
    (offer.mime # NIL) & (offer.mime[0] # 0) & IQ.Value(offer.mime^, 128) & Hash(offer.hash) &
    (offer.date # NIL) & IQ.Value(offer.date^, 64) & (offer.size >= 0) & (offer.size <= maxFileBytes) &
    (offer.methods # {}) & (offer.methods - {ibb, socks5} = {})
END Valid;

PROCEDURE NewOffer*(sid, name: ARRAY OF T.CodeUnit; size: LONGINT; methods: SET): Offer;
  VAR offer: Offer;
BEGIN
  NEW(offer); offer.sid := Items.Copy16(sid); offer.name := Items.Copy16(name); offer.size := size; offer.methods := methods;
  offer.description := Items.Latin1(""); offer.hash := Items.Latin1(""); offer.date := Items.Latin1("");
  offer.mime := Items.Latin1("application/octet-stream");
  IF ~Valid(offer) THEN RETURN NIL END; RETURN offer
END NewOffer;

PROCEDURE Method(value: T.String): LONGINT;
BEGIN
  IF S.Equal8(value^, I.namespaceURI) THEN RETURN ibb
  ELSIF S.Equal8(value^, socksURI) THEN RETURN socks5
  ELSE RETURN -1
  END
END Method;

PROCEDURE Value(method: LONGINT): Items.Item;
  VAR item: Items.Item; text: T.String;
BEGIN
  item := Items.New("value", formURI);
  IF method = ibb THEN text := Items.Latin1(I.namespaceURI) ELSE text := Items.Latin1(socksURI) END;
  item.AddText(text^, 0, S.Length(text^)); RETURN item
END Value;

PROCEDURE Feature(methods: SET; submit: BOOLEAN): Items.Item;
  VAR feature, x, field, option: Items.Item; i: LONGINT;
BEGIN
  feature := Items.New("feature", featureURI); x := Items.New("x", formURI);
  IF submit THEN ASCII(x, "type", "submit") ELSE ASCII(x, "type", "form") END;
  feature.AddChild(x); field := Items.New("field", formURI); ASCII(field, "var", "stream-method");
  IF ~submit THEN ASCII(field, "type", "list-single") END;
  x.AddChild(field);
  FOR i := ibb TO socks5 DO
    IF i IN methods THEN
      IF submit THEN field.AddChild(Value(i))
      ELSE option := Items.New("option", formURI); option.AddChild(Value(i)); field.AddChild(option)
      END
    END
  END;
  RETURN feature
END Feature;

PROCEDURE Build*(offer: Offer): Items.Item;
  VAR si, file, item: Items.Item;
BEGIN
  IF ~Valid(offer) THEN RETURN NIL END;
  si := Items.New("si", namespaceURI); Set(si, "id", offer.sid^); ASCII(si, "profile", fileURI); Set(si, "mime-type", offer.mime^);
  file := Items.New("file", fileURI); Set(file, "name", offer.name^); SetNumber(file, "size", offer.size);
  IF offer.hash[0] # 0 THEN Set(file, "hash", offer.hash^) END;
  IF offer.date[0] # 0 THEN Set(file, "date", offer.date^) END;
  IF offer.description[0] # 0 THEN
    item := Items.New("desc", fileURI); item.AddText(offer.description^, 0, S.Length(offer.description^)); file.AddChild(item)
  END;
  IF offer.range THEN file.AddChild(Items.New("range", fileURI)) END;
  si.AddChild(file); si.AddChild(Feature(offer.methods, FALSE)); RETURN si
END Build;

PROCEDURE Methods(feature: Items.Item; submit: BOOLEAN; VAR methods: SET): BOOLEAN;
  VAR x, field, item, value: Items.Item; content: Items.Content; text, type: T.String; count, method: LONGINT;
BEGIN
  methods := {};
  IF (Layout(feature, x) # 1) OR ~Named(x, formURI, "x") THEN RETURN FALSE END;
  type := x.GetAttribute("", "type"); IF type = NIL THEN RETURN FALSE END;
  IF submit THEN IF ~S.Equal8(type^, "submit") THEN RETURN FALSE END
  ELSE IF ~S.Equal8(type^, "form") THEN RETURN FALSE END
  END;
  IF (Layout(x, field) # 1) OR ~Named(field, formURI, "field") THEN RETURN FALSE END;
  text := field.GetAttribute("", "var"); IF (text = NIL) OR ~S.Equal8(text^, "stream-method") THEN RETURN FALSE END;
  type := field.GetAttribute("", "type");
  IF ~submit & ((type = NIL) OR ~S.Equal8(type^, "list-single")) THEN RETURN FALSE END;
  count := Layout(field, item); IF (count < 1) OR (count > 8) OR (submit & (count # 1)) THEN RETURN FALSE END;
  content := field.content;
  WHILE content # NIL DO
    item := content.element;
    IF item # NIL THEN
      IF submit THEN value := item
      ELSE
        IF ~Named(item, formURI, "option") OR (Layout(item, value) # 1) THEN RETURN FALSE END
      END;
      IF ~Named(value, formURI, "value") THEN RETURN FALSE END;
      text := Scalar(value, 256); IF (text = NIL) OR (text[0] = 0) THEN RETURN FALSE END;
      method := Method(text);
      IF method >= 0 THEN
        IF method IN methods THEN RETURN FALSE END;
        INCL(methods, method)
      ELSIF submit THEN RETURN FALSE
      END
    END;
    content := content.next
  END;
  RETURN methods # {}
END Methods;

PROCEDURE ReadOffer*(si: Items.Item): Offer;
  VAR offer: Offer; file, feature, item: Items.Item; content: Items.Content; profile: T.String;
    count, descriptions, ranges: LONGINT;
BEGIN
  IF ~Named(si, namespaceURI, "si") OR (Layout(si, item) # 2) THEN RETURN NIL END;
  file := si.First(fileURI, "file"); feature := si.First(featureURI, "feature");
  IF (file = NIL) OR (feature = NIL) THEN RETURN NIL END;
  profile := si.GetAttribute("", "profile"); IF (profile = NIL) OR ~S.Equal8(profile^, fileURI) THEN RETURN NIL END;
  NEW(offer); offer.sid := Attr(si, "id", I.maxSIDUnits, TRUE); offer.mime := Attr(si, "mime-type", 128, FALSE);
  IF (offer.mime # NIL) & (offer.mime[0] = 0) THEN offer.mime := Items.Latin1("application/octet-stream") END;
  offer.name := Attr(file, "name", maxNameUnits, TRUE); offer.date := Attr(file, "date", 64, FALSE);
  offer.hash := Attr(file, "hash", 32, FALSE); offer.description := Items.Latin1("");
  IF ~Number(file, "size", offer.size) OR ~Methods(feature, FALSE, offer.methods) THEN RETURN NIL END;
  count := Layout(file, item); IF (count < 0) OR (count > 2) THEN RETURN NIL END;
  descriptions := 0; ranges := 0; content := file.content;
  WHILE content # NIL DO
    item := content.element;
    IF item # NIL THEN
      IF Named(item, fileURI, "desc") THEN
        INC(descriptions); offer.description := Scalar(item, maxDescriptionUnits)
      ELSIF Named(item, fileURI, "range") THEN
        INC(ranges); IF ~IQ.Empty(item) OR (item.GetAttribute("", "offset") # NIL) OR
          (item.GetAttribute("", "length") # NIL) THEN RETURN NIL END;
        offer.range := TRUE
      ELSE RETURN NIL
      END
    END;
    content := content.next
  END;
  IF (descriptions > 1) OR (ranges > 1) OR ~Valid(offer) THEN RETURN NIL END;
  RETURN offer
END ReadOffer;

PROCEDURE Accept*(offer: Offer; method, offset, length: LONGINT): Items.Item;
  VAR si, file, range: Items.Item;
BEGIN
  IF ~Valid(offer) OR (method < ibb) OR (method > socks5) OR ~(method IN offer.methods) OR
    (offset < 0) OR (offset > offer.size) OR (length < 0) OR (length > offer.size-offset) OR
    (~offer.range & ((offset # 0) OR (length # offer.size))) THEN RETURN NIL END;
  si := Items.New("si", namespaceURI);
  IF (offset # 0) OR (length # offer.size) THEN
    file := Items.New("file", fileURI); range := Items.New("range", fileURI);
    SetNumber(range, "offset", offset); SetNumber(range, "length", length); file.AddChild(range); si.AddChild(file)
  END;
  si.AddChild(Feature({method}, TRUE)); RETURN si
END Accept;

PROCEDURE Query*(router: IQ.Router; peer: ARRAY OF T.CodeUnit; offer: Offer; timeoutMS: LONGINT;
                 action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
  VAR target: T.String; payload: Items.Item;
BEGIN
  error := NIL; target := IQ.CanonicalJID(peer); payload := Build(offer);
  IF (router = NIL) OR (target = NIL) OR (payload = NIL) THEN error := Msg.New(context, 1); RETURN NIL END;
  RETURN router.QueryExact(target^, payload, TRUE, timeoutMS, action, error)
END Query;

PROCEDURE ReadAccept*(si: Items.Item; offer: Offer): Selection;
  VAR selection: Selection; file, range, feature, item: Items.Item;
    methods: SET; id, profile: T.String; count: LONGINT;
BEGIN
  IF ~Valid(offer) OR ~Named(si, namespaceURI, "si") THEN RETURN NIL END;
  id := si.GetAttribute("", "id"); IF (id # NIL) & ~S.Equal(id^, offer.sid^) THEN RETURN NIL END;
  profile := si.GetAttribute("", "profile"); IF (profile # NIL) & ~S.Equal8(profile^, fileURI) THEN RETURN NIL END;
  count := Layout(si, item); IF (count < 1) OR (count > 2) THEN RETURN NIL END;
  feature := si.First(featureURI, "feature"); IF (feature = NIL) OR ~Methods(feature, TRUE, methods) OR
    (methods-offer.methods # {}) THEN RETURN NIL END;
  NEW(selection); selection.sid := offer.sid; selection.length := offer.size;
  IF ibb IN methods THEN selection.method := ibb ELSE selection.method := socks5 END;
  file := si.First(fileURI, "file");
  IF file # NIL THEN
    IF ~offer.range OR (Layout(file, range) # 1) OR ~Named(range, fileURI, "range") OR ~IQ.Empty(range) THEN RETURN NIL END;
    IF range.GetAttribute("", "offset") # NIL THEN IF ~Number(range, "offset", selection.offset) THEN RETURN NIL END END;
    IF selection.offset > offer.size THEN RETURN NIL END;
    selection.length := offer.size-selection.offset;
    IF range.GetAttribute("", "length") # NIL THEN IF ~Number(range, "length", selection.length) THEN RETURN NIL END END;
    IF selection.length > offer.size-selection.offset THEN RETURN NIL END
  ELSIF count # 1 THEN RETURN NIL
  END;
  RETURN selection
END ReadAccept;

PROCEDURE ReadSelection*(request: IQ.Request): Selection;
  VAR offer: Offer; si: Items.Item; peer: T.String;
BEGIN
  IF request = NIL THEN RETURN NIL END;
  offer := ReadOffer(request.payload); IF offer = NIL THEN RETURN NIL END;
  si := IQ.Payload(request, namespaceURI, "si"); IF si = NIL THEN RETURN NIL END;
  peer := IQ.CanonicalJID(request.reply.from^);
  IF (peer = NIL) OR ~S.Equal(peer^, request.peer^) THEN RETURN NIL END;
  RETURN ReadAccept(si, offer)
END ReadSelection;

BEGIN NEW(context); Msg.InitContext(context, "XmppStreamInit")
END XmppStreamInit.
