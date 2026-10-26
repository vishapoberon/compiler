MODULE XmppPresenceTracker;

(* Explicit contact watches and bounded per-resource presence on a client hook. *)

IMPORT Msg, S := LongStrings, T := XmppTypes, IQ := XmppIQ,
  P := XmppPresence, Core := XmppCore, Client := XmppClient;

CONST
  maxContacts* = 128; maxResources* = 16; maxEntries* = 256;
  maxWatchUnits* = 65536; maxTrackedUnits* = 262144;

TYPE
  Tracker* = POINTER TO TrackerDesc;
  Hook* = POINTER TO HookDesc;
  HookDesc* = RECORD END;
  TrackerDesc* = RECORD (Client.HookDesc)
    count-, watchCount-: LONGINT;
    entries-: ARRAY maxEntries OF P.Event;
    client-: Client.Client;
    active-: BOOLEAN;
    own, bare: T.String;
    watches: ARRAY maxContacts OF T.String;
    units, watchUnits: LONGINT;
    application: Client.Hook;
    hook: Hook;
  END;
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (c: Context) GetTemplate(message: Msg.Msg; VAR text: Msg.LString);
BEGIN S.Long("Invalid local JID for XMPP presence tracking", text) END GetTemplate;

PROCEDURE Units(event: P.Event): LONGINT;
  VAR units, i: LONGINT;
BEGIN
  units := S.Length(event.from^)+S.Length(event.bare^)+S.Length(event.to^)+S.Length(event.show^);
  FOR i := 0 TO event.statusCount-1 DO INC(units, S.Length(event.statuses[i].language^)+S.Length(event.statuses[i].text^)) END;
  RETURN units
END Units;

PROCEDURE Watched(tracker: Tracker; jid: T.String): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  FOR i := 0 TO tracker.watchCount-1 DO IF S.Equal(tracker.watches[i]^, jid^) THEN RETURN TRUE END END;
  RETURN FALSE
END Watched;

PROCEDURE (t: Tracker) Watch*(jid: ARRAY OF T.CodeUnit): BOOLEAN;
  VAR canonical, bare: T.String;
BEGIN
  canonical := IQ.CanonicalJID(jid); bare := P.Bare(jid);
  IF (canonical = NIL) OR (bare = NIL) OR ~S.Equal(canonical^, bare^) THEN RETURN FALSE END;
  IF Watched(t, canonical) THEN RETURN TRUE END;
  IF (t.watchCount = maxContacts) OR (t.watchUnits+S.Length(canonical^) > maxWatchUnits) THEN RETURN FALSE END;
  t.watches[t.watchCount] := canonical; INC(t.watchCount); INC(t.watchUnits, S.Length(canonical^)); RETURN TRUE
END Watch;

PROCEDURE (t: Tracker) Forget*(jid: ARRAY OF T.CodeUnit): BOOLEAN;
  VAR canonical, bare: T.String; i, count: LONGINT; remove, removed: BOOLEAN;
BEGIN
  canonical := IQ.CanonicalJID(jid); bare := P.Bare(jid); IF (canonical = NIL) OR (bare = NIL) THEN RETURN FALSE END;
  count := 0; removed := FALSE;
  FOR i := 0 TO t.count-1 DO
    remove := S.Equal(t.entries[i].from^, canonical^) OR (S.Equal(canonical^, bare^) & S.Equal(t.entries[i].bare^, bare^));
    IF remove THEN DEC(t.units, Units(t.entries[i])); removed := TRUE
    ELSE t.entries[count] := t.entries[i]; INC(count)
    END
  END;
  FOR i := count TO t.count-1 DO t.entries[i] := NIL END;
  t.count := count; RETURN removed
END Forget;

PROCEDURE (t: Tracker) Unwatch*(jid: ARRAY OF T.CodeUnit): BOOLEAN;
  VAR canonical, bare: T.String; i, slot: LONGINT; removed: BOOLEAN;
BEGIN
  canonical := IQ.CanonicalJID(jid); bare := P.Bare(jid);
  IF (canonical = NIL) OR (bare = NIL) OR ~S.Equal(canonical^, bare^) THEN RETURN FALSE END;
  slot := 0; WHILE (slot < t.watchCount) & ~S.Equal(t.watches[slot]^, canonical^) DO INC(slot) END;
  IF slot = t.watchCount THEN RETURN FALSE END;
  DEC(t.watchUnits, S.Length(t.watches[slot]^)); DEC(t.watchCount);
  FOR i := slot TO t.watchCount-1 DO t.watches[i] := t.watches[i+1] END;
  t.watches[t.watchCount] := NIL; removed := t.Forget(canonical^); RETURN TRUE
END Unwatch;

PROCEDURE (t: Tracker) Find*(jid: ARRAY OF T.CodeUnit): P.Event;
  VAR canonical: T.String; i: LONGINT;
BEGIN
  canonical := IQ.CanonicalJID(jid); IF canonical = NIL THEN RETURN NIL END;
  FOR i := 0 TO t.count-1 DO IF S.Equal(t.entries[i].from^, canonical^) THEN RETURN t.entries[i] END END;
  RETURN NIL
END Find;

PROCEDURE (t: Tracker) Best*(jid: ARRAY OF T.CodeUnit): P.Event;
  VAR canonical: T.String; i: LONGINT; best, event: P.Event;
BEGIN
  canonical := P.Bare(jid); IF canonical = NIL THEN RETURN NIL END;
  best := NIL;
  FOR i := 0 TO t.count-1 DO
    event := t.entries[i];
    IF S.Equal(event.bare^, canonical^) & (event.priority >= 0) THEN
      IF (best = NIL) OR (event.priority > best.priority) OR
         ((event.priority = best.priority) & (S.Compare(event.from^, best.from^) = S.less)) THEN best := event END
    END
  END;
  RETURN best
END Best;

PROCEDURE (h: Hook) Notice*(tracker: Tracker; event: P.Event; applied: BOOLEAN);
BEGIN END Notice;
PROCEDURE (h: Hook) Reset*(tracker: Tracker);
BEGIN END Reset;

PROCEDURE (t: Tracker) Clear*;
  VAR i: LONGINT;
BEGIN
  FOR i := 0 TO t.count-1 DO t.entries[i] := NIL END;
  t.count := 0; t.units := 0; t.hook.Reset(t)
END Clear;

PROCEDURE (t: Tracker) Stop*;
BEGIN t.active := FALSE; t.Clear END Stop;

PROCEDURE Apply(t: Tracker; event: P.Event): BOOLEAN;
  VAR i, slot, resources, units: LONGINT; removed: BOOLEAN;
BEGIN
  IF ~Watched(t, event.bare) THEN RETURN FALSE END;
  IF event.kind = P.unavailable THEN removed := t.Forget(event.from^); RETURN TRUE END;
  IF event.kind # P.available THEN RETURN FALSE END;
  slot := t.count; resources := 0;
  FOR i := 0 TO t.count-1 DO
    IF S.Equal(t.entries[i].from^, event.from^) THEN slot := i END;
    IF S.Equal(t.entries[i].bare^, event.bare^) THEN INC(resources) END
  END;
  units := t.units+Units(event);
  IF slot < t.count THEN DEC(units, Units(t.entries[slot]))
  ELSIF (t.count = maxEntries) OR (resources = maxResources) THEN RETURN FALSE
  END;
  IF units > maxTrackedUnits THEN RETURN FALSE END;
  t.entries[slot] := event; t.units := units; IF slot = t.count THEN INC(t.count) END;
  RETURN TRUE
END Apply;

PROCEDURE (t: Tracker) Ready*(client: Client.Client; jid: T.String);
BEGIN
  ASSERT(t.client = NIL); t.client := client; t.own := IQ.CanonicalJID(jid^); t.bare := P.Bare(jid^);
  IF (t.own = NIL) OR (t.bare = NIL) THEN
    t.Stop; client.Abort; t.application.Error(client, Msg.New(context, 1)); RETURN
  END;
  t.active := TRUE; t.Clear; t.application.Ready(client, jid)
END Ready;

PROCEDURE (t: Tracker) Received*(client: Client.Client; stanza: Core.Stanza);
  VAR event: P.Event; applied: BOOLEAN;
BEGIN
  ASSERT(client = t.client);
  IF t.active & (client.state = Client.online) & (stanza.kind = Core.presence) THEN
    event := P.Read(stanza);
    IF (event # NIL) & ((event.to[0] = 0) OR S.Equal(event.to^, t.own^) OR S.Equal(event.to^, t.bare^)) THEN
      applied := Apply(t, event); t.hook.Notice(t, event, applied)
    END
  END;
  t.application.Received(client, stanza)
END Received;
PROCEDURE (t: Tracker) Sent*(client: Client.Client; stanza: Core.Stanza);
BEGIN t.application.Sent(client, stanza) END Sent;
PROCEDURE (t: Tracker) Error*(client: Client.Client; error: Msg.Msg);
BEGIN t.Stop; t.application.Error(client, error) END Error;
PROCEDURE (t: Tracker) Closed*(client: Client.Client);
BEGIN t.Stop; t.application.Closed(client) END Closed;

PROCEDURE New*(application: Client.Hook; hook: Hook): Tracker;
  VAR tracker: Tracker;
BEGIN
  IF (application = NIL) OR (hook = NIL) THEN RETURN NIL END;
  NEW(tracker); tracker.application := application; tracker.hook := hook; RETURN tracker
END New;

BEGIN NEW(context); Msg.InitContext(context, "XmppPresenceTracker")
END XmppPresenceTracker.
