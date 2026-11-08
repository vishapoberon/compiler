MODULE TestXmppSocks5;

IMPORT Out, S := LongStrings, T := XmppTypes, Items := XmppItems, K := XmppSocks5;

VAR checks: LONGINT; destination: Items.Bytes;

PROCEDURE Check(ok: BOOLEAN; label: ARRAY OF CHAR);
BEGIN
  IF ~ok THEN Out.String("SOCKS5 check failed: "); Out.String(label); Out.Ln; HALT(1) END;
  INC(checks)
END Check;

PROCEDURE Vector(n: LONGINT; expected: ARRAY OF CHAR);
  VAR sid, requester, target: T.String; actual: Items.Bytes; i: LONGINT;
BEGIN
  NEW(sid, n+1); FOR i := 0 TO n-1 DO sid[i] := ORD("a") END; sid[n] := 0;
  requester := Items.Latin1("a@b/r"); target := Items.Latin1("c@d/s");
  actual := K.Destination(sid^, requester^, target^);
  Check((actual # NIL) & (actual^ = expected), "hashing exact protocol identities across SHA-1 padding boundaries")
END Vector;

PROCEDURE Hashes;
  VAR sid, requester, target: T.String; actual: Items.Bytes;
BEGIN
  Vector(1, "e7d7c63b0e5859af19fe0cc84cc5469da86cd860");
  Vector(45, "99613247e2daa654de9c4a5e257f3960ed79e4a9");
  Vector(46, "51279b536c1f4c12af99bc5e4482b01928b37948");
  Vector(53, "4cdb82688956bc55776871ad783b4ef048a10ecb");
  Vector(54, "2120a67516a4749e1ad4ac87b7ee60762f2184a4");
  Vector(55, "68956f9aa6c1d524f5a234395c927552c5207a58");
  Vector(128, "2d6ce9125419bb19894a01f561c99ee9e93498e0");
  sid := Items.Latin1("yia72g3v49j7"); requester := Items.Latin1("requester@example.com/foo"); target := Items.Latin1("room@conference.example.net/Tget");
  actual := K.Destination(sid^, requester^, target^); Check(actual^ = "416781edf1ae50bad01cb8509ba35b43952bc345", "matching published XEP-0065 destination");
  sid := Items.UTF8("հոսք😀"); requester := Items.UTF8("Անի@ծոց.հայ/մուտք😀"); target := Items.UTF8("Բոբ@ծոց.հայ/r");
  actual := K.Destination(sid^, requester^, target^); Check(actual^ = "cc2b48896119a5832fa2299ce821f895858f821d", "hashing Unicode identities as UTF-8");
  sid := Items.Latin1(""); Check(K.Destination(sid^, requester^, target^) = NIL, "requiring bounded nonempty SID");
  Check(~K.Valid("bad") & ~K.Valid("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"), "checking canonical destination shape")
END Hashes;

PROCEDURE Method(h: K.Handshake; chunk: LONGINT);
  VAR bytes: ARRAY 64 OF CHAR; n, pos, consumed: LONGINT; state: SHORTINT;
BEGIN
  pos := 0;
  WHILE h.Pending() > 0 DO
    n := h.Output(bytes, pos, chunk); ASSERT(n > 0); ASSERT(h.Sent(n)); INC(pos, n)
  END;
  ASSERT((pos = 3) & (bytes[0] = 5X) & (bytes[1] = 1X) & (bytes[2] = 0X));
  bytes[0] := 5X; bytes[1] := 0X; state := h.Feed(bytes, 0, 1, consumed); ASSERT(consumed = 1);
  state := h.Feed(bytes, 1, 1, consumed); ASSERT((consumed = 1) & (state = K.connect))
END Method;

PROCEDURE Request(h: K.Handshake; chunk: LONGINT; VAR bytes: ARRAY OF CHAR);
  VAR n, pos, i: LONGINT;
BEGIN
  pos := 0;
  WHILE h.Pending() > 0 DO
    n := 47-pos; IF n > chunk THEN n := chunk END;
    n := h.Output(bytes, pos, n); ASSERT(n > 0); ASSERT(h.Sent(n)); INC(pos, n)
  END;
  ASSERT((pos = 47) & (bytes[0] = 5X) & (bytes[1] = 1X) & (bytes[2] = 0X) & (bytes[3] = 3X) & (bytes[4] = CHR(40)));
  FOR i := 0 TO 39 DO ASSERT(bytes[i+5] = destination[i]) END;
  ASSERT((bytes[45] = 0X) & (bytes[46] = 0X)); bytes[1] := 0X
END Request;

PROCEDURE Fragments;
  VAR h: K.Handshake; bytes: ARRAY 64 OF CHAR; chunk, pos, n, consumed, split: LONGINT; state: SHORTINT;
BEGIN
  FOR chunk := 1 TO 47 DO
    h := K.New(destination^); Method(h, chunk); Request(h, chunk, bytes); pos := 0;
    WHILE pos < 47 DO
      n := 47-pos; IF n > chunk THEN n := chunk END;
      state := h.Feed(bytes, pos, n, consumed); ASSERT(consumed = n); INC(pos, consumed)
    END;
    Check((state = K.ready) & (h.Pending() = 0) & (h.Needed() = 0), "handling fragmented writes and replies")
  END;
  FOR split := 0 TO 47 DO
    h := K.New(destination^); Method(h, 64); Request(h, 64, bytes);
    state := h.Feed(bytes, 0, split, consumed); ASSERT(consumed = split);
    bytes[47] := 0X; bytes[48] := 0FFX;
    state := h.Feed(bytes, split, 49-split, consumed);
    Check((state = K.ready) & (consumed = 47-split), "not consuming coalesced binary payload after handshake")
  END
END Fragments;

PROCEDURE Invalid;
  VAR h: K.Handshake; bytes: ARRAY 64 OF CHAR; i, consumed: LONGINT; state: SHORTINT;
BEGIN
  FOR i := 0 TO 46 DO
    h := K.New(destination^); Method(h, 64); Request(h, 64, bytes);
    IF bytes[i] = 0X THEN bytes[i] := 1X ELSE bytes[i] := 0X END;
    state := h.Feed(bytes, 0, 47, consumed); Check(state = K.failed, "rejecting malformed or mismatched SOCKS5 reply")
  END;
  FOR i := 0 TO 46 DO
    h := K.New(destination^); Method(h, 64); Request(h, 64, bytes);
    state := h.Feed(bytes, 0, i, consumed); h.End;
    Check(h.state = K.failed, "failing truncated reply on EOF")
  END;
  h := K.New(destination^); Check(~h.Sent(4) & (h.state = K.greeting), "rejecting excess acknowledged writes");
  Check(h.Output(bytes, -1, 1) = -1, "checking output ranges");
  state := h.Feed(bytes, -1, 1, consumed); Check((state = K.failed) & (consumed = 0), "checking input ranges");
  h := K.New(destination^); ASSERT(h.Sent(3)); bytes[0] := 5X; bytes[1] := 2X;
  state := h.Feed(bytes, 0, 2, consumed); Check(state = K.failed, "rejecting unoffered authentication method");
  Check(K.New("invalid") = NIL, "refusing invalid destination")
END Invalid;

BEGIN
  destination := Items.Copy8("416781edf1ae50bad01cb8509ba35b43952bc345"); Hashes; Fragments; Invalid;
  Out.String("XMPP SOCKS5 checks passed: "); Out.Int(checks, 0); Out.Ln
END TestXmppSocks5.
