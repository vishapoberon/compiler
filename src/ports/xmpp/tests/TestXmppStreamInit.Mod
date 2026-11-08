MODULE TestXmppStreamInit;

IMPORT Out, Msg, S := LongStrings, T := XmppTypes, Items := XmppItems,
  SI := XmppStreamInit, I := XmppIbb, XML := XmppXmlStream, Gen := XmppXmlGen;

VAR checks: LONGINT; sid, name: T.String;

PROCEDURE Check(ok: BOOLEAN; label: ARRAY OF CHAR);
BEGIN
  IF ~ok THEN Out.String("stream-initiation check failed: "); Out.String(label); Out.Ln; HALT(1) END;
  INC(checks)
END Check;

PROCEDURE Param(item: Items.Item; key, value: ARRAY OF CHAR);
  VAR text: T.String;
BEGIN text := Items.Latin1(value); item.SetParam(key, text^) END Param;

PROCEDURE Offer(): SI.Offer;
  VAR offer: SI.Offer;
BEGIN
  offer := SI.NewOffer(sid^, name^, 513, {SI.ibb, SI.socks5}); ASSERT(offer # NIL);
  offer.description := Items.UTF8("Բարեւ <աշխարհ> & 😀");
  offer.hash := Items.Latin1("D41D8CD98F00B204E9800998ECF8427E");
  offer.date := Items.Latin1("2026-11-07T12:34:56Z"); offer.range := TRUE; RETURN offer
END Offer;

PROCEDURE Feed(stream: XML.Stream; text: ARRAY OF CHAR; chunk: LONGINT): Items.Item;
  VAR pos, count, consumed, length: LONGINT; event: SHORTINT; item: Items.Item;
BEGIN
  pos := 0; item := NIL; length := S.Length8(text);
  WHILE pos < length DO
    count := length-pos; IF count > chunk THEN count := chunk END;
    event := stream.Feed(text, pos, count, consumed); ASSERT((event # XML.failed) & (consumed > 0)); INC(pos, consumed);
    IF event = XML.stanza THEN ASSERT(item = NIL); item := stream.item END
  END;
  RETURN item
END Feed;

PROCEDURE RoundTrip(payload: Items.Item; chunk: LONGINT): Items.Item;
  VAR iq, item: Items.Item; bytes: Items.Bytes; length: LONGINT; error: Msg.Msg; stream: XML.Stream;
BEGIN
  iq := Items.New("iq", "jabber:client"); iq.AddChild(payload);
  Gen.Encode(iq, 32768, bytes, length, error); ASSERT(error = NIL);
  stream := XML.New(); item := Feed(stream, '<s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client">', chunk);
  item := Feed(stream, bytes^, chunk); ASSERT(item # NIL); RETURN item.First(SI.namespaceURI, "si")
END RoundTrip;

PROCEDURE Builders;
  VAR offer, read: SI.Offer; selection: SI.Selection; item, file, x: Items.Item; i: LONGINT; empty, text: T.String;
BEGIN
  offer := Offer(); empty := Items.Latin1("");
  FOR i := 1 TO 128 DO
    item := RoundTrip(SI.Build(offer), i); read := SI.ReadOffer(item);
    Check((read # NIL) & S.Equal(read.sid^, sid^) & S.Equal(read.name^, name^) &
      S.Equal(read.description^, offer.description^) & (read.size = 513) & read.range &
      (read.methods = {SI.ibb, SI.socks5}), "fragmented Unicode offer round trip")
  END;
  FOR i := SI.ibb TO SI.socks5 DO
    item := RoundTrip(SI.Accept(offer, i, 0, 513), 1); selection := SI.ReadAccept(item, offer);
    Check((selection # NIL) & (selection.method = i) & (selection.offset = 0) & (selection.length = 513), "selecting an offered transport");
    item := RoundTrip(SI.Accept(offer, i, 123, 234), 1); selection := SI.ReadAccept(item, offer);
    Check((selection # NIL) & (selection.offset = 123) & (selection.length = 234), "selecting a checked file range")
  END;
  item := SI.Accept(offer, SI.ibb, 513, 0); selection := SI.ReadAccept(item, offer);
  Check((selection # NIL) & (selection.offset = 513) & (selection.length = 0), "accepting an empty end range");
  offer.range := FALSE;
  Check((SI.Accept(offer, SI.ibb, 1, 512) = NIL) & (SI.Accept(offer, SI.ibb, 0, 512) = NIL), "requiring range support before resuming");
  Check((SI.Accept(offer, SI.ibb, -1, 1) = NIL) & (SI.Accept(offer, SI.ibb, 514, 0) = NIL) &
    (SI.Accept(offer, SI.ibb, 512, 2) = NIL) & (SI.Accept(offer, SI.ibb, 0, -1) = NIL), "bounding accepted source range");
  offer.methods := {SI.ibb}; Check(SI.Accept(offer, SI.socks5, 0, 513) = NIL, "not accepting an unoffered transport");
  Check((SI.NewOffer(empty^, name^, 1, {SI.ibb}) = NIL) & (SI.NewOffer(sid^, empty^, 1, {SI.ibb}) = NIL), "requiring SID and file name");
  Check((SI.NewOffer(sid^, name^, -1, {SI.ibb}) = NIL) & (SI.NewOffer(sid^, name^, SI.maxFileBytes+1, {SI.ibb}) = NIL), "bounding advertised file size");
  Check((SI.NewOffer(sid^, name^, 0, {}) = NIL) & (SI.NewOffer(sid^, name^, 0, {2}) = NIL), "requiring supported transport set");
  read := SI.NewOffer(sid^, name^, 0, {SI.ibb}); Check(SI.ReadOffer(SI.Build(read)) # NIL, "supporting empty files");
  read.size := SI.maxFileBytes; Check(SI.ReadOffer(SI.Build(read)) # NIL, "supporting file size at bound");
  offer := Offer(); offer.hash := Items.Latin1("invalid"); Check(SI.Build(offer) = NIL, "checking MD5 metadata shape");
  offer := Offer(); NEW(text, SI.maxNameUnits+2); FOR i := 0 TO SI.maxNameUnits DO text[i] := ORD("a") END;
  text[SI.maxNameUnits+1] := 0; offer.name := text; Check(SI.Build(offer) = NIL, "bounding file names");
  text[0] := 0D800H; text[1] := 0; Check(SI.Build(offer) = NIL, "checking file-name surrogate validity");
  offer := Offer(); item := SI.Build(offer); Param(item, "mime-type", "");
  read := SI.ReadOffer(item); Check((read # NIL) & S.Equal8(read.mime^, "application/octet-stream"), "defaulting MIME metadata");
  Check((SI.ReadOffer(NIL) = NIL) & (SI.ReadAccept(NIL, offer) = NIL) & (SI.ReadSelection(NIL) = NIL), "handling absent payloads")
END Builders;

PROCEDURE Malformed;
  VAR offer: SI.Offer; item, file, feature, x, field, option, value: Items.Item; selection: SI.Selection; text: T.String;
BEGIN
  offer := Offer(); item := SI.Build(offer); Param(item, "profile", "urn:wrong"); Check(SI.ReadOffer(item) = NIL, "requiring file-transfer profile");
  item := SI.Build(offer); item.AddChild(Items.New("extra", "urn:test")); Check(SI.ReadOffer(item) = NIL, "rejecting unexpected root payload");
  item := SI.Build(offer); file := item.First(SI.fileURI, "file"); Param(file, "size", "9999999999");
  Check(SI.ReadOffer(item) = NIL, "rejecting numeric overflow");
  Param(file, "size", "-1"); Check(SI.ReadOffer(item) = NIL, "rejecting negative size");
  Param(file, "size", "1x"); Check(SI.ReadOffer(item) = NIL, "rejecting malformed size");
  item := SI.Build(offer); file := item.First(SI.fileURI, "file"); file.AddChild(Items.New("desc", SI.fileURI));
  Check(SI.ReadOffer(item) = NIL, "rejecting duplicate descriptions");
  item := SI.Build(offer); file := item.First(SI.fileURI, "file"); Param(file.First(SI.fileURI, "range"), "offset", "1");
  Check(SI.ReadOffer(item) = NIL, "requiring empty range capability in an offer");
  item := SI.Build(offer); feature := item.First(SI.featureURI, "feature"); x := feature.First(SI.formURI, "x");
  Param(x, "type", "submit"); Check(SI.ReadOffer(item) = NIL, "requiring form in offer");
  item := SI.Build(offer); feature := item.First(SI.featureURI, "feature"); x := feature.First(SI.formURI, "x");
  field := x.First(SI.formURI, "field"); Param(field, "var", "unrelated"); Check(SI.ReadOffer(item) = NIL, "requiring stream-method field");
  item := SI.Build(offer); feature := item.First(SI.featureURI, "feature"); x := feature.First(SI.formURI, "x"); field := x.First(SI.formURI, "field");
  option := Items.New("option", SI.formURI); value := Items.New("value", SI.formURI); text := Items.Latin1(I.namespaceURI);
  value.AddText(text^, 0, S.Length(text^)); option.AddChild(value); field.AddChild(option);
  Check(SI.ReadOffer(item) = NIL, "rejecting duplicate supported transport");
  item := SI.Accept(offer, SI.ibb, 0, 513); Param(item, "id", "other");
  Check(SI.ReadAccept(item, offer) = NIL, "checking optional response SID");
  item := SI.Accept(offer, SI.ibb, 0, 513); Param(item, "profile", "urn:wrong");
  Check(SI.ReadAccept(item, offer) = NIL, "checking optional response profile");
  item := SI.Accept(offer, SI.ibb, 1, 512); file := item.First(SI.fileURI, "file"); Param(file.First(SI.fileURI, "range"), "length", "513");
  Check(SI.ReadAccept(item, offer) = NIL, "rejecting selection beyond offered range");
  item := SI.Accept(offer, SI.ibb, 1, 512); offer.range := FALSE;
  Check(SI.ReadAccept(item, offer) = NIL, "rejecting unsolicited resume"); offer.range := TRUE;
  item := SI.Accept(offer, SI.socks5, 0, 513); offer.methods := {SI.ibb};
  Check(SI.ReadAccept(item, offer) = NIL, "rejecting selection outside offered transports");
  offer := Offer(); item := SI.Accept(offer, SI.ibb, 0, 513); feature := item.First(SI.featureURI, "feature");
  x := feature.First(SI.formURI, "x"); field := x.First(SI.formURI, "field");
  value := Items.New("value", SI.formURI); text := Items.Latin1(SI.socksURI); value.AddText(text^, 0, S.Length(text^)); field.AddChild(value);
  Check(SI.ReadAccept(item, offer) = NIL, "requiring exactly one selected transport")
END Malformed;

BEGIN
  sid := Items.UTF8("հոսք😀"); name := Items.UTF8("փաստաթուղթ<&😀.bin"); Builders; Malformed;
  Out.String("XMPP stream-initiation checks passed: "); Out.Int(checks, 0); Out.Ln
END TestXmppStreamInit.
