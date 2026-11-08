MODULE XmppByteStreams;

(* Bounded TCP bytestream host offers and exact-peer host selection. *)

IMPORT Msg, S := LongStrings, IntStr, IDNA, T := XmppTypes, Items := XmppItems,
  IQ := XmppIQ, I := XmppIbb;

CONST
  namespaceURI* = "http://jabber.org/protocol/bytestreams";
  maxHosts* = 8; maxHostBytes* = 253;

TYPE
  Host* = POINTER TO HostDesc;
  HostDesc* = RECORD jid-: T.String; address-: Items.Bytes; port-: LONGINT END;
  Offer* = POINTER TO OfferDesc;
  OfferDesc* = RECORD sid-: T.String; count-: LONGINT; hosts-: ARRAY maxHosts OF Host END;
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (c: Context) GetTemplate(message: Msg.Msg; VAR text: Msg.LString);
BEGIN S.Long("Invalid bounded XMPP bytestream host offer or explicit peer", text) END GetTemplate;

PROCEDURE Address(text: ARRAY OF CHAR): Items.Bytes;
  VAR i, colons, first, last: LONGINT; bytes: Items.Bytes; unicode, ascii: IDNA.String; status: LONGINT;
BEGIN
  last := S.Length8(text); IF (last = 0) OR (last > maxHostBytes) THEN RETURN NIL END;
  colons := 0;
  FOR i := 0 TO last-1 DO
    IF (text[i] <= " ") OR (text[i] = 7FX) OR (text[i] = "/") OR (text[i] = "@") OR (text[i] = "%") THEN RETURN NIL END;
    IF text[i] = ":" THEN INC(colons) END
  END;
  IF colons > 0 THEN
    IF colons < 2 THEN RETURN NIL END;
    first := 0;
    IF text[0] = "[" THEN
      IF text[last-1] # "]" THEN RETURN NIL END;
      first := 1; DEC(last)
    END;
    NEW(bytes, last-first+1);
    FOR i := first TO last-1 DO
      IF ~(((text[i] >= "0") & (text[i] <= "9")) OR ((CAP(text[i]) >= "A") & (CAP(text[i]) <= "F")) OR
        (text[i] = ":") OR (text[i] = ".")) THEN RETURN NIL END;
      bytes[i-first] := text[i]
    END;
    bytes[last-first] := 0X; RETURN bytes
  END;
  IDNA.Names(text, unicode, ascii, status); IF status # 0 THEN RETURN NIL END;
  RETURN Items.Copy8(ascii^)
END Address;

PROCEDURE NewHost*(jid: ARRAY OF T.CodeUnit; address: ARRAY OF CHAR; port: LONGINT): Host;
  VAR host: Host; target: T.String; bytes: Items.Bytes;
BEGIN
  target := IQ.CanonicalJID(jid); bytes := Address(address);
  IF (target = NIL) OR (bytes = NIL) OR (port < 1) OR (port > 65535) THEN RETURN NIL END;
  NEW(host); host.jid := target; host.address := bytes; host.port := port; RETURN host
END NewHost;

PROCEDURE NewOffer*(sid: ARRAY OF T.CodeUnit): Offer;
  VAR offer: Offer;
BEGIN
  IF ~I.SID(sid) THEN RETURN NIL END;
  NEW(offer); offer.sid := Items.Copy16(sid); RETURN offer
END NewOffer;

PROCEDURE (offer: Offer) Add*(host: Host): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  IF (host = NIL) OR (offer.count = maxHosts) THEN RETURN FALSE END;
  FOR i := 0 TO offer.count-1 DO
    IF S.Equal(offer.hosts[i].jid^, host.jid^) OR
      ((offer.hosts[i].address^ = host.address^) & (offer.hosts[i].port = host.port)) THEN RETURN FALSE END
  END;
  offer.hosts[offer.count] := host; INC(offer.count); RETURN TRUE
END Add;

PROCEDURE Number(item: Items.Item; VAR value: LONGINT): BOOLEAN;
  VAR text: T.String; i, digit: LONGINT;
BEGIN
  text := item.GetAttribute("", "port"); value := 1080;
  IF text = NIL THEN RETURN TRUE END;
  IF (S.Length(text^) = 0) OR (S.Length(text^) > 5) THEN RETURN FALSE END;
  value := 0;
  FOR i := 0 TO S.Length(text^)-1 DO
    digit := text[i]-ORD("0"); IF (digit < 0) OR (digit > 9) THEN RETURN FALSE END;
    value := value*10+digit
  END;
  RETURN (value > 0) & (value <= 65535)
END Number;

PROCEDURE White(text: T.String): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  IF S.Length(text^) > 4096 THEN RETURN FALSE END;
  FOR i := 0 TO S.Length(text^)-1 DO
    IF (text[i] # 32) & (text[i] # 9) & (text[i] # 10) & (text[i] # 13) THEN RETURN FALSE END
  END;
  RETURN TRUE
END White;

PROCEDURE ReadOffer*(query: Items.Item): Offer;
  VAR offer: Offer; host: Host; sid, mode, jid, address: T.String; bytes: Items.Bytes;
    content: Items.Content; item: Items.Item; parts, port: LONGINT;
BEGIN
  IF ~IQ.Named(query, namespaceURI, "query") THEN RETURN NIL END;
  sid := query.GetAttribute("", "sid"); IF sid = NIL THEN RETURN NIL END;
  offer := NewOffer(sid^); IF offer = NIL THEN RETURN NIL END;
  mode := query.GetAttribute("", "mode"); IF (mode # NIL) & ~S.Equal8(mode^, "tcp") THEN RETURN NIL END;
  (* Explicit alternate destination hashes require a separate negotiated policy. *)
  IF query.GetAttribute("", "dstaddr") # NIL THEN RETURN NIL END;
  parts := 0; content := query.content;
  WHILE content # NIL DO
    INC(parts); IF parts > 32 THEN RETURN NIL END;
    item := content.element;
    IF item # NIL THEN
      IF ~IQ.Named(item, namespaceURI, "streamhost") OR ~IQ.Empty(item) OR ~Number(item, port) THEN RETURN NIL END;
      jid := item.GetAttribute("", "jid"); address := item.GetAttribute("", "host");
      IF (jid = NIL) OR (address = NIL) OR ~IQ.Value(address^, maxHostBytes) THEN RETURN NIL END;
      bytes := Items.UTF8Bytes(address^); IF bytes = NIL THEN RETURN NIL END;
      host := NewHost(jid^, bytes^, port); IF ~offer.Add(host) THEN RETURN NIL END
    ELSIF ~White(content.text) THEN RETURN NIL
    END;
    content := content.next
  END;
  IF offer.count = 0 THEN RETURN NIL END;
  RETURN offer
END ReadOffer;

PROCEDURE Build*(offer: Offer): Items.Item;
  VAR query, item: Items.Item; host: Host; text: T.String; i: LONGINT; number: ARRAY 16 OF CHAR;
BEGIN
  IF (offer = NIL) OR (offer.sid = NIL) OR ~I.SID(offer.sid^) OR (offer.count < 1) OR (offer.count > maxHosts) THEN RETURN NIL END;
  query := Items.New("query", namespaceURI); query.SetParam("sid", offer.sid^);
  text := Items.Latin1("tcp"); query.SetParam("mode", text^);
  FOR i := 0 TO offer.count-1 DO
    host := offer.hosts[i]; IF host = NIL THEN RETURN NIL END;
    host := NewHost(host.jid^, host.address^, host.port); IF host = NIL THEN RETURN NIL END;
    item := Items.New("streamhost", namespaceURI); item.SetParam("jid", host.jid^);
    text := Items.UTF8(host.address^); item.SetParam("host", text^);
    IntStr.IntToStr(host.port, number); text := Items.Latin1(number); item.SetParam("port", text^); query.AddChild(item)
  END;
  (* Revalidate uniqueness even if a caller changed an exposed host string. *)
  IF ReadOffer(query) = NIL THEN RETURN NIL END;
  RETURN query
END Build;

PROCEDURE Select*(offer: Offer; jid: ARRAY OF T.CodeUnit): Items.Item;
  VAR query, item: Items.Item; target: T.String; i: LONGINT;
BEGIN
  IF (offer = NIL) OR (Build(offer) = NIL) THEN RETURN NIL END;
  target := IQ.CanonicalJID(jid); IF target = NIL THEN RETURN NIL END;
  FOR i := 0 TO offer.count-1 DO
    IF S.Equal(offer.hosts[i].jid^, target^) THEN
      query := Items.New("query", namespaceURI); query.SetParam("sid", offer.sid^);
      item := Items.New("streamhost-used", namespaceURI); item.SetParam("jid", target^); query.AddChild(item); RETURN query
    END
  END;
  RETURN NIL
END Select;

PROCEDURE ReadUsed*(query: Items.Item; offer: Offer): Host;
  VAR content: Items.Content; item, used: Items.Item; target, sid: T.String; i, count, parts: LONGINT;
BEGIN
  IF ~IQ.Named(query, namespaceURI, "query") OR (offer = NIL) OR (Build(offer) = NIL) THEN RETURN NIL END;
  sid := query.GetAttribute("", "sid"); IF (sid # NIL) & ~S.Equal(sid^, offer.sid^) THEN RETURN NIL END;
  content := query.content; count := 0; parts := 0; used := NIL;
  WHILE content # NIL DO
    INC(parts); IF parts > 32 THEN RETURN NIL END;
    item := content.element;
    IF item # NIL THEN
      IF ~IQ.Named(item, namespaceURI, "streamhost-used") OR ~IQ.Empty(item) THEN RETURN NIL END;
      INC(count); used := item
    ELSIF ~White(content.text) THEN RETURN NIL
    END;
    content := content.next
  END;
  IF count # 1 THEN RETURN NIL END;
  target := used.GetAttribute("", "jid"); IF target = NIL THEN RETURN NIL END;
  target := IQ.CanonicalJID(target^); IF target = NIL THEN RETURN NIL END;
  FOR i := 0 TO offer.count-1 DO IF S.Equal(offer.hosts[i].jid^, target^) THEN RETURN offer.hosts[i] END END;
  RETURN NIL
END ReadUsed;

PROCEDURE Query*(router: IQ.Router; peer: ARRAY OF T.CodeUnit; offer: Offer; timeoutMS: LONGINT;
                 action: IQ.Action; VAR error: Msg.Msg): IQ.Request;
  VAR target: T.String; payload: Items.Item;
BEGIN
  error := NIL; target := IQ.CanonicalJID(peer); payload := Build(offer);
  IF (router = NIL) OR (target = NIL) OR (payload = NIL) THEN error := Msg.New(context, 1); RETURN NIL END;
  RETURN router.QueryExact(target^, payload, TRUE, timeoutMS, action, error)
END Query;

PROCEDURE Selected*(request: IQ.Request): Host;
  VAR offer: Offer; query: Items.Item; peer: T.String;
BEGIN
  IF request = NIL THEN RETURN NIL END;
  offer := ReadOffer(request.payload); IF offer = NIL THEN RETURN NIL END;
  query := IQ.Payload(request, namespaceURI, "query"); IF query = NIL THEN RETURN NIL END;
  peer := IQ.CanonicalJID(request.reply.from^);
  IF (peer = NIL) OR ~S.Equal(peer^, request.peer^) THEN RETURN NIL END;
  RETURN ReadUsed(query, offer)
END Selected;

BEGIN NEW(context); Msg.InitContext(context, "XmppByteStreams")
END XmppByteStreams.
