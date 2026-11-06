MODULE TestXmppIbb;

IMPORT Out, Msg, S := LongStrings, T := XmppTypes, Items := XmppItems,
  B := XmppBase64, I := XmppIbb, XML := XmppXmlStream, Gen := XmppXmlGen;

VAR checks: LONGINT; sid: T.String;

PROCEDURE Check(ok: BOOLEAN; name: ARRAY OF CHAR);
BEGIN
  IF ~ok THEN Out.String("IBB check failed: "); Out.String(name); Out.Ln; HALT(1) END;
  INC(checks)
END Check;

PROCEDURE Vector(raw, encoded: ARRAY OF CHAR);
  VAR text, bytes: Items.Bytes; length: LONGINT;
BEGIN
  text := B.Encode(raw, 0, S.Length8(raw)); Check((text # NIL) & (text^ = encoded), "RFC 4648 encoding");
  bytes := B.Decode(encoded, S.Length8(encoded), B.maxBytes, length);
  Check((bytes # NIL) & (length = S.Length8(raw)) & (bytes^ = raw), "RFC 4648 decoding")
END Vector;

PROCEDURE Bad(text: ARRAY OF CHAR);
  VAR bytes: Items.Bytes; length: LONGINT;
BEGIN
  length := -1; bytes := B.Decode(text, S.Length8(text), B.maxBytes, length);
  Check((bytes = NIL) & (length = 0), "rejecting invalid Base64 atomically")
END Bad;

PROCEDURE Codec;
  VAR bytes, encoded, decoded: Items.Bytes; i, j, n, length: LONGINT; raw: ARRAY 260 OF CHAR;
BEGIN
  Vector("", ""); Vector("f", "Zg=="); Vector("fo", "Zm8="); Vector("foo", "Zm9v");
  Vector("foob", "Zm9vYg=="); Vector("fooba", "Zm9vYmE="); Vector("foobar", "Zm9vYmFy");
  Bad("Zg"); Bad("Zg="); Bad("Zg==="); Bad("=AAA"); Bad("A=AA"); Bad("AA=A"); Bad("====");
  Bad("Zg==AAAA"); Bad("AAAA=AAA"); Bad("AA?A"); Bad("AA-A"); Bad("AA_A");
  Bad("Zg== "); Bad(" Zg=="); Bad("Z g=="); Bad("Zh=="); Bad("Zm9="); Bad("ԱԱԱԱ");
  FOR i := 0 TO 255 DO raw[i+2] := CHR(i) END;
  FOR n := 0 TO 256 DO
    encoded := B.Encode(raw, 2, n); decoded := B.Decode(encoded^, S.Length8(encoded^), n, length);
    Check((decoded # NIL) & (length = n), "binary lengths including zero bytes");
    FOR j := 0 TO n-1 DO ASSERT(decoded[j] = raw[j+2]) END
  END;
  FOR i := 0 TO 255 DO
    IF ~(((i >= ORD("A")) & (i <= ORD("Z"))) OR ((i >= ORD("a")) & (i <= ORD("z"))) OR
      ((i >= ORD("0")) & (i <= ORD("9"))) OR (i = ORD("+")) OR (i = ORD("/"))) THEN
      raw[0] := CHR(i); raw[1] := "A"; raw[2] := "A"; raw[3] := "A";
      Check(B.Decode(raw, 4, 3, length) = NIL, "rejecting every non-alphabet byte")
    END
  END;
  FOR i := 1 TO 15 DO
    raw[0] := "A"; raw[1] := CHR(ORD("A")+i); raw[2] := "="; raw[3] := "=";
    Check(B.Decode(raw, 4, 1, length) = NIL, "rejecting nonzero single-byte padding bits")
  END;
  Check((B.Encode(raw, -1, 1) = NIL) & (B.Encode(raw, 0, -1) = NIL) &
    (B.Encode(raw, LEN(raw), 1) = NIL) & (B.Encode(raw, 1, LEN(raw)) = NIL), "checking binary source ranges");
  Check((B.Decode("AAAA", -1, 3, length) = NIL) & (B.Decode("AAAA", 5, 3, length) = NIL) &
    (B.Decode("AAAA", 4, 2, length) = NIL) & (B.Decode("", 0, -1, length) = NIL), "checking decoding bounds");
  NEW(bytes, B.maxBytes+1);
  FOR i := 0 TO B.maxBytes-1 DO bytes[i] := CHR(i MOD 256) END;
  encoded := B.Encode(bytes^, 0, B.maxBytes);
  Check((encoded # NIL) & (S.Length8(encoded^) = B.maxText), "encoding the largest block");
  decoded := B.Decode(encoded^, B.maxText, B.maxBytes, length);
  Check((decoded # NIL) & (length = B.maxBytes), "decoding the largest block");
  FOR i := 0 TO length-1 DO ASSERT(decoded[i] = bytes[i]) END;
  Check(B.Encode(bytes^, 0, B.maxBytes+1) = NIL, "bounding encoded allocation");
  Check(B.Decode(encoded^, B.maxText, B.maxBytes-1, length) = NIL, "bounding decoded allocation")
END Codec;

PROCEDURE Feed(stream: XML.Stream; text: ARRAY OF CHAR; chunk: LONGINT): Items.Item;
  VAR position, count, consumed: LONGINT; event: SHORTINT; item: Items.Item;
BEGIN
  position := 0; item := NIL;
  WHILE position < S.Length8(text) DO
    count := S.Length8(text)-position; IF count > chunk THEN count := chunk END;
    event := stream.Feed(text, position, count, consumed);
    ASSERT((event # XML.failed) & (consumed > 0)); INC(position, consumed);
    IF event = XML.stanza THEN ASSERT(item = NIL); item := stream.item END
  END;
  RETURN item
END Feed;

PROCEDURE Parse(text: ARRAY OF CHAR; chunk: LONGINT): Items.Item;
  VAR stream: XML.Stream; item: Items.Item;
BEGIN
  stream := XML.New(); item := Feed(stream,
    '<s:stream xmlns:s="http://etherx.jabber.org/streams" xmlns="jabber:client">', chunk);
  item := Feed(stream, text, chunk); ASSERT(item # NIL); RETURN item
END Parse;

PROCEDURE Param(item: Items.Item; name, value: ARRAY OF CHAR);
  VAR text: T.String;
BEGIN text := Items.Latin1(value); item.SetParam(name, text^) END Param;

PROCEDURE Payloads;
  VAR item, iq: Items.Item; event: I.Event; text: T.String; bytes: Items.Bytes;
    raw: ARRAY 256 OF CHAR; length, i, j, sequence: LONGINT; error: Msg.Msg;
BEGIN
  item := I.Open(sid^, I.defaultBlockSize); event := I.Read(item, I.maxBlockSize);
  Check((event # NIL) & (event.kind = I.opening) & (event.blockSize = 1024) & S.Equal(event.sid^, sid^), "open payload");
  item := I.Close(sid^); event := I.Read(item, 1);
  Check((event # NIL) & (event.kind = I.closing), "close payload");
  FOR i := 0 TO 255 DO raw[i] := CHR(i) END;
  item := I.Data(sid^, 65535, raw, 0, 256); event := I.Read(item, 256);
  Check((event # NIL) & (event.kind = I.data) & (event.sequence = 65535) & (event.length = 256), "binary data payload");
  FOR i := 0 TO 255 DO ASSERT(event.bytes[i] = raw[i]) END;
  Check(I.Read(item, 255) = NIL, "enforcing negotiated raw block size");
  iq := Items.New("iq", "jabber:client"); iq.AddChild(item);
  Gen.Encode(iq, 65536, bytes, length, error); ASSERT(error = NIL);
  FOR i := 1 TO 128 DO
    iq := Parse(bytes^, i); item := iq.First(I.namespaceURI, "data"); event := I.Read(item, 256);
    Check((event # NIL) & (event.length = 256) & S.Equal(event.sid^, sid^), "fragmented XML binary round trips");
    FOR j := 0 TO 255 DO ASSERT(event.bytes[j] = raw[j]) END
  END;
  item := I.Open(sid^, 1); Param(item, "stanza", "message");
  Check(I.Read(item, 1) = NIL, "keeping original IQ-based scope");
  item := Items.New("open", I.namespaceURI); item.SetParam("sid", sid^); Param(item, "block-size", "65535");
  Check(I.Read(item, 1) # NIL, "reading the largest advertised block for later policy checks");
  Param(item, "block-size", "65536"); Check(I.Read(item, 1) = NIL, "rejecting oversized advertised block");
  Param(item, "block-size", "0"); Check(I.Read(item, 1) = NIL, "rejecting zero advertised block");
  Param(item, "block-size", "-1"); Check(I.Read(item, 1) = NIL, "rejecting signed block size");
  Param(item, "block-size", "1x"); Check(I.Read(item, 1) = NIL, "rejecting malformed block size");
  Param(item, "block-size", "1"); item.AddChild(Items.New("x", "urn:test"));
  Check(I.Read(item, 1) = NIL, "rejecting nested open payload");
  item := I.Data(sid^, 0, raw, 0, 1); text := Items.Latin1("AAAA"); item.AddText(text^, 0, 4);
  Check(I.Read(item, 1) = NIL, "bounding combined text parts");
  item := I.Data(sid^, 0, raw, 0, 1); item.AddChild(Items.New("x", "urn:test"));
  Check(I.Read(item, 1) = NIL, "rejecting nested data payload");
  item := I.Close(sid^); text := Items.Latin1("junk"); item.AddText(text^, 0, 4);
  Check(I.Read(item, 1) = NIL, "rejecting close text");
  sequence := 0;
  FOR i := 0 TO 65535 DO ASSERT(sequence = i); sequence := I.NextSequence(sequence) END;
  Check(sequence = 0, "wrapping the complete 16-bit sequence");
  Check((I.NextSequence(-1) = -1) & (I.NextSequence(65536) = -1), "rejecting invalid sequence state");
  Check((I.Data(sid^, -1, raw, 0, 1) = NIL) & (I.Data(sid^, 65536, raw, 0, 1) = NIL), "rejecting invalid sequence builders");
  Check((I.Open(sid^, 0) = NIL) & (I.Open(sid^, 65536) = NIL) &
    (I.Read(NIL, 1) = NIL) & (I.Read(I.Close(sid^), 0) = NIL), "checking payload bounds")
END Payloads;

PROCEDURE Identifiers;
  VAR text: T.String; i: LONGINT;
BEGIN
  text := Items.Latin1(""); Check(~I.SID(text^), "rejecting empty SID");
  text := Items.Latin1("has space"); Check(~I.SID(text^), "rejecting whitespace in SID");
  text := Items.Latin1("slash/path"); Check(~I.SID(text^), "rejecting non-name SID characters");
  text := Items.Latin1("0:._-token"); Check(I.SID(text^), "accepting NMTOKEN initial digits and punctuation");
  NEW(text, I.maxSIDUnits+2); FOR i := 0 TO I.maxSIDUnits DO text[i] := ORD("a") END; text[I.maxSIDUnits+1] := 0;
  Check(~I.SID(text^), "bounding SID units"); text[I.maxSIDUnits] := 0; Check(I.SID(text^), "SID at bound");
  text[0] := 0D800H; text[1] := 0; Check(~I.SID(text^), "rejecting unpaired SID surrogate");
  text := Items.UTF8("հոսք😀"); Check(I.SID(text^), "accepting Unicode SID")
END Identifiers;

PROCEDURE BadPayloads;
  VAR iq, item: Items.Item; text: T.String; i: LONGINT;
BEGIN
  iq := Parse('<iq><open xmlns="http://jabber.org/protocol/ibb" sid="s" block-size="1"/></iq>', 1);
  Check(I.Read(iq.First(I.namespaceURI, "open"), 1) # NIL, "defaulting omitted stanza mode to IQ");
  iq := Parse('<iq><data xmlns="http://jabber.org/protocol/ibb" sid="s" seq="0">Zg==</data></iq>', 1);
  Check(I.Read(iq.First(I.namespaceURI, "data"), 1) # NIL, "reading padded XML data");
  item := iq.First(I.namespaceURI, "data");
  Param(item, "seq", "65536"); Check(I.Read(item, 1) = NIL, "rejecting oversized sequence");
  Param(item, "seq", "-1"); Check(I.Read(item, 1) = NIL, "rejecting negative sequence");
  Param(item, "seq", "+1"); Check(I.Read(item, 1) = NIL, "rejecting signed sequence");
  Param(item, "seq", ""); Check(I.Read(item, 1) = NIL, "rejecting empty sequence");
  Param(item, "seq", "0"); Param(item, "sid", "bad sid"); Check(I.Read(item, 1) = NIL, "validating received SID");
  iq := Parse('<iq><data xmlns="http://jabber.org/protocol/ibb" sid="s" seq="0">Zh==</data></iq>', 1);
  Check(I.Read(iq.First(I.namespaceURI, "data"), 1) = NIL, "rejecting malformed padding through XML");
  iq := Parse('<iq><data xmlns="http://jabber.org/protocol/ibb" sid="s" seq="0"> Zg== </data></iq>', 1);
  Check(I.Read(iq.First(I.namespaceURI, "data"), 1) = NIL, "rejecting non-alphabet whitespace");
  iq := Parse('<iq><data xmlns="http://jabber.org/protocol/ibb" sid="s" seq="0">ԱԱԱԱ</data></iq>', 1);
  Check(I.Read(iq.First(I.namespaceURI, "data"), 3) = NIL, "rejecting Unicode Base64 lookalikes");
  iq := Parse('<iq><open xmlns="http://jabber.org/protocol/ibb" block-size="1"/></iq>', 1);
  Check(I.Read(iq.First(I.namespaceURI, "open"), 1) = NIL, "requiring SID");
  item := Items.New("data", I.namespaceURI); Param(item, "sid", "s");
  Check(I.Read(item, 1) = NIL, "requiring sequence");
  Param(item, "seq", "0"); text := Items.Latin1("AAAA");
  FOR i := 1 TO 128 DO item.AddText(text^, 0, 4) END;
  Check(I.Read(item, I.maxBlockSize) # NIL, "accepting bounded text parts");
  item.AddText(text^, 0, 4);
  Check(I.Read(item, I.maxBlockSize) = NIL, "bounding content parts");
  item := Items.New("open", "urn:wrong"); Param(item, "sid", "s"); Param(item, "block-size", "1");
  Check(I.Read(item, 1) = NIL, "rejecting namespace lookalikes")
END BadPayloads;

BEGIN
  sid := Items.UTF8("հոսք😀"); Codec; Payloads; Identifiers; BadPayloads;
  Out.String("XMPP IBB codec and payload checks passed: "); Out.Int(checks, 0); Out.Ln
END TestXmppIbb.
