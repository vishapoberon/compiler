MODULE XmppPEP;

(* Building bounded XEP-0277 microblog entries for XEP-0060 personal publishing. *)

IMPORT S := LongStrings, Strings := oocStrings, IDNA, JulianDay, T := XmppTypes,
  Items := XmppItems, IQ := XmppIQ, PubSub := XmppPubSub;

CONST
  pubsubURI* = "http://jabber.org/protocol/pubsub";
  microblogNode* = "urn:xmpp:microblog:0";
  atomURI* = "http://www.w3.org/2005/Atom";
  maxTextUnits* = 4096;

PROCEDURE Timestamp*(stamp: ARRAY OF CHAR): BOOLEAN;
  VAR i, year, month, day, hour, minute, second: LONGINT;
    checkDay, checkMonth: SHORTINT; checkYear: INTEGER;
BEGIN
  IF (S.Length8(stamp) # 20) OR (stamp[4] # "-") OR (stamp[7] # "-") OR
     (stamp[10] # "T") OR (stamp[13] # ":") OR (stamp[16] # ":") OR (stamp[19] # "Z") THEN RETURN FALSE END;
  FOR i := 0 TO 18 DO
    IF (i # 4) & (i # 7) & (i # 10) & (i # 13) & (i # 16) THEN
      IF (stamp[i] < "0") OR (stamp[i] > "9") THEN RETURN FALSE END
    END
  END;
  year := 0; FOR i := 0 TO 3 DO year := 10*year+ORD(stamp[i])-ORD("0") END;
  month := 10*(ORD(stamp[5])-ORD("0"))+ORD(stamp[6])-ORD("0");
  day := 10*(ORD(stamp[8])-ORD("0"))+ORD(stamp[9])-ORD("0");
  hour := 10*(ORD(stamp[11])-ORD("0"))+ORD(stamp[12])-ORD("0");
  minute := 10*(ORD(stamp[14])-ORD("0"))+ORD(stamp[15])-ORD("0");
  second := 10*(ORD(stamp[17])-ORD("0"))+ORD(stamp[18])-ORD("0");
  IF (year < 1970) OR (month < 1) OR (month > 12) OR (day < 1) OR (day > 31) OR
     (hour > 23) OR (minute > 59) OR (second > 59) THEN RETURN FALSE END;
  JulianDay.DaysToDate(JulianDay.DateToDays(SHORT(SHORT(day)), SHORT(SHORT(month)), SHORT(year)), checkDay, checkMonth, checkYear);
  RETURN (day = checkDay) & (month = checkMonth) & (year = checkYear)
END Timestamp;

PROCEDURE Text(parent: Items.Item; name: ARRAY OF CHAR; value: T.String): Items.Item;
  VAR item: Items.Item;
BEGIN
  item := Items.New(name, atomURI); item.AddText(value^, 0, S.Length(value^)); parent.AddChild(item); RETURN item
END Text;

PROCEDURE Build*(domain: ARRAY OF CHAR; text: ARRAY OF T.CodeUnit; itemID, stamp: ARRAY OF CHAR): Items.Item;
  VAR entry, child: Items.Item; value, node, id: T.String;
    unicode, ascii: IDNA.String; status, i, length: LONGINT;
    tag: ARRAY 512 OF CHAR;
BEGIN
  IF ~IQ.Value(text, maxTextUnits) OR (S.Length(text) = 0) OR ~Timestamp(stamp) THEN RETURN NIL END;
  length := S.Length8(itemID); IF (length = 0) OR (length > 64) THEN RETURN NIL END;
  FOR i := 0 TO length-1 DO
    IF ~(((itemID[i] >= "a") & (itemID[i] <= "z")) OR ((itemID[i] >= "A") & (itemID[i] <= "Z")) OR
         ((itemID[i] >= "0") & (itemID[i] <= "9")) OR (itemID[i] = "-")) THEN RETURN NIL END
  END;
  IDNA.Names(domain, unicode, ascii, status); IF status # 0 THEN RETURN NIL END;
  entry := Items.New("entry", atomURI);
  child := Text(entry, "title", Items.Copy16(text)); value := Items.Latin1("text"); child.SetParam("type", value^);
  child := Text(entry, "content", Items.Copy16(text)); child.SetParam("type", value^);
  tag := "tag:"; Strings.Append(ascii^, tag); Strings.Append(",", tag);
  length := S.Length8(tag); FOR i := 0 TO 9 DO tag[length+i] := stamp[i] END; tag[length+10] := 0X;
  Strings.Append(":posts-", tag); Strings.Append(itemID, tag);
  child := Text(entry, "id", Items.Latin1(tag));
  child := Text(entry, "published", Items.Latin1(stamp)); child := Text(entry, "updated", Items.Latin1(stamp));
  node := Items.Latin1(microblogNode); id := Items.Latin1(itemID);
  RETURN PubSub.BuildPublish(node^, id^, entry)
END Build;

PROCEDURE Accepted*(request: IQ.Request; itemID: ARRAY OF CHAR): BOOLEAN;
  VAR publish, item: Items.Item; value: T.String;
BEGIN
  IF ~PubSub.Published(request) THEN RETURN FALSE END;
  publish := request.payload.First(pubsubURI, "publish"); IF publish = NIL THEN RETURN FALSE END;
  value := publish.GetAttribute("", "node"); IF (value = NIL) OR ~S.Equal8(value^, microblogNode) THEN RETURN FALSE END;
  item := publish.First(pubsubURI, "item"); IF item = NIL THEN RETURN FALSE END;
  value := item.GetAttribute("", "id"); RETURN (value # NIL) & S.Equal8(value^, itemID)
END Accepted;

END XmppPEP.
