MODULE TestXmppRSM;

IMPORT Out, S := LongStrings, T := XmppTypes, Items := XmppItems, RSM := XmppRSM;

VAR checks, failed: LONGINT;

PROCEDURE Check(value: BOOLEAN; name: ARRAY OF CHAR);
BEGIN
  INC(checks);
  IF ~value THEN INC(failed); Out.String(name); Out.Ln END
END Check;

PROCEDURE Field(parent: Items.Item; name, text: ARRAY OF CHAR): Items.Item;
  VAR item: Items.Item; value: T.String;
BEGIN
  item := Items.New(name, RSM.namespaceURI); value := Items.UTF8(text);
  item.AddText(value^, 0, S.Length(value^)); parent.AddChild(item); RETURN item
END Field;

PROCEDURE ResultData(): Items.Item;
  VAR item, first, unused: Items.Item; value: T.String;
BEGIN
  item := Items.New("set", RSM.namespaceURI); first := Field(item, "first", "առաջին😀");
  value := Items.Latin1("10"); first.SetParam("index", value^);
  unused := Field(item, "last", "վերջին"); unused := Field(item, "count", "20"); RETURN item
END ResultData;

PROCEDURE Requests;
  VAR item, child: Items.Item; empty, cursor, long: T.String; request: RSM.Request;
    i: LONGINT; valid: BOOLEAN;
BEGIN
  empty := Items.Latin1(""); cursor := Items.UTF8("առաջին😀");
  FOR i := RSM.firstPage TO RSM.beforePage DO
    IF i = RSM.firstPage THEN item := RSM.Build(i, 16, empty^)
    ELSE item := RSM.Build(i, 16, cursor^)
    END;
    valid := RSM.ReadRequest(item, request); Check(valid, "decoding page request");
    IF valid THEN
      Check((request.maximum = 16) & (request.direction = i), "page request direction and maximum");
      IF i = RSM.firstPage THEN Check(request.cursor[0] = 0, "first page has no cursor")
      ELSE Check(S.Equal(request.cursor^, cursor^), "retaining Unicode cursor")
      END
    END
  END;
  item := RSM.Build(RSM.beforePage, 16, empty^);
  Check(RSM.ReadRequest(item, request), "empty before selects last page");
  Check((request.direction = RSM.beforePage) & (request.cursor[0] = 0), "last-page request");
  item := RSM.Build(RSM.firstPage, 0, empty^);
  Check(RSM.ReadRequest(item, request) & (request.maximum = 0), "count-only page request");
  item := RSM.Build(RSM.firstPage, MAX(LONGINT), empty^);
  Check(RSM.ReadRequest(item, request) & (request.maximum = MAX(LONGINT)), "maximum signed count");
  item := RSM.BuildIndex(16, 10);
  Check(RSM.ReadRequest(item, request), "indexed page request");
  Check((request.direction = RSM.indexedPage) & (request.index = 10), "indexed-page position");
  Check(RSM.BuildIndex(1, -1) = NIL, "rejecting negative page index");
  Check(RSM.BuildIndex(-1, 0) = NIL, "rejecting negative indexed maximum");
  Check(RSM.Build(RSM.firstPage, -1, empty^) = NIL, "rejecting negative page maximum");
  Check(RSM.Build(RSM.afterPage, 1, empty^) = NIL, "after requires a cursor");
  Check(RSM.Build(RSM.firstPage, 1, cursor^) = NIL, "first-page cursor is not discarded");
  Check(RSM.Build(10, 1, cursor^) = NIL, "rejecting unknown page direction");
  item := Items.New("set", RSM.namespaceURI);
  Check(RSM.ReadRequest(item, request) & (request.maximum = -1), "unspecified maximum is explicit");
  FOR i := 0 TO 7 DO
    item := RSM.Build(RSM.firstPage, 16, empty^);
    CASE i OF
    | 0: child := Field(item, "max", "2")
    | 1: child := Field(item, "after", "a"); child := Field(item, "before", "b")
    | 2: child := Field(item, "after", "a"); child := Field(item, "index", "2")
    | 3: child := Field(item, "after", "")
    | 4: child := Items.New("after", "urn:wrong"); item.AddChild(child)
    | 5: child := Field(item, "after", "a"); child.AddChild(Items.New("x", RSM.namespaceURI))
    | 6: child := Field(item, "first", "a")
    | 7: item.AddText(cursor^, 0, S.Length(cursor^))
    ELSE HALT(100)
    END;
    request.maximum := 123;
    Check(~RSM.ReadRequest(item, request), "rejecting malformed page request");
    Check(request.maximum = 123, "invalid request leaves output unchanged")
  END;
  FOR i := 0 TO 3 DO
    item := Items.New("set", RSM.namespaceURI);
    CASE i OF
    | 0: child := Field(item, "max", "2147483648")
    | 1: child := Field(item, "max", "-1")
    | 2: child := Field(item, "max", "1x")
    | 3: child := Field(item, "max", "")
    ELSE HALT(100)
    END;
    Check(~RSM.ReadRequest(item, request), "rejecting invalid decimal maximum")
  END;
  NEW(long, RSM.maxCursorUnits+2);
  FOR i := 0 TO RSM.maxCursorUnits DO long[i] := ORD("x") END; long[RSM.maxCursorUnits+1] := 0;
  Check(RSM.Build(RSM.afterPage, 1, long^) = NIL, "bounding outgoing cursor");
  item := Items.New("set", RSM.namespaceURI); child := Items.New("after", RSM.namespaceURI);
  child.AddText(long^, 0, S.Length(long^)); item.AddChild(child);
  Check(~RSM.ReadRequest(item, request), "bounding incoming cursor");
  long[0] := 0D800H; long[1] := 0;
  Check(RSM.Build(RSM.afterPage, 1, long^) = NIL, "rejecting invalid UTF-16 cursor")
END Requests;

PROCEDURE Results;
  VAR item, child, first: Items.Item; result: RSM.Result; request: RSM.Request; value, expected: T.String;
    i: LONGINT; valid: BOOLEAN;
BEGIN
  item := ResultData(); valid := RSM.ReadResult(item, result);
  Check(valid, "decoding result metadata");
  IF valid THEN
    expected := Items.UTF8("առաջին😀"); Check(S.Equal(result.first^, expected^), "Unicode first UID");
    expected := Items.UTF8("վերջին"); Check(S.Equal(result.last^, expected^), "Unicode last UID");
    Check(result.hasCount & (result.count = 20) & result.hasIndex & (result.index = 10), "result count and index")
  END;
  item := Items.New("set", RSM.namespaceURI); child := Field(item, "count", "0");
  Check(RSM.ReadResult(item, result), "empty result metadata");
  Check(result.hasCount & (result.count = 0) & (result.first = NIL) & (result.last = NIL), "empty result has no cursors");
  item := Items.New("set", RSM.namespaceURI); child := Field(item, "count", "2147483647");
  Check(RSM.ReadResult(item, result) & (result.count = MAX(LONGINT)), "maximum signed result count");
  item := Items.New("set", RSM.namespaceURI);
  child := Field(item, "first", "only"); child := Field(item, "last", "only");
  Check(RSM.ReadResult(item, result) & ~result.hasCount & ~result.hasIndex, "optional count and index");
  FOR i := 0 TO 10 DO
    item := ResultData(); first := item.First(RSM.namespaceURI, "first");
    CASE i OF
    | 0: child := Field(item, "first", "duplicate")
    | 1: child := Field(item, "last", "duplicate")
    | 2: child := Field(item, "count", "20")
    | 3: value := Items.Latin1("-1"); first.SetParam("index", value^)
    | 4: value := Items.Latin1("20"); first.SetParam("index", value^)
    | 5: first.AddChild(Items.New("x", RSM.namespaceURI))
    | 6: child := Items.New("count", "urn:wrong"); item.AddChild(child)
    | 7: child := Field(item, "max", "10")
    | 8: value := Items.Latin1("text"); item.AddText(value^, 0, S.Length(value^))
    | 9: item := Items.New("set", RSM.namespaceURI); child := Field(item, "first", "a")
    | 10: item := Items.New("set", RSM.namespaceURI); child := Field(item, "count", "2147483648")
    ELSE HALT(100)
    END;
    result.count := 123;
    Check(~RSM.ReadResult(item, result), "rejecting malformed result metadata");
    Check(result.count = 123, "invalid metadata leaves output unchanged")
  END;
  item := Items.New("set", RSM.namespaceURI);
  child := Field(item, "first", "a"); child := Field(item, "last", "a"); child := Field(item, "count", "0");
  Check(~RSM.ReadResult(item, result), "zero count cannot contain a cursor");
  item := Items.New("set", "urn:wrong");
  Check(~RSM.ReadResult(item, result) & ~RSM.ReadRequest(item, request), "exact RSM namespace")
END Results;

BEGIN
  Requests; Results;
  Out.String("TestXmppRSM: "); Out.Int(checks, 0); Out.String(" checks, ");
  Out.Int(failed, 0); Out.String(" failed"); Out.Ln;
  IF failed # 0 THEN HALT(100) END
END TestXmppRSM.
