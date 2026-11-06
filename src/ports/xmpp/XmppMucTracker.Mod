MODULE XmppMucTracker;

(* Explicit room joins and bounded occupant state on an authenticated client. *)

IMPORT Msg, S := LongStrings, T := XmppTypes, Items := XmppItems,
  Core := XmppCore, Client := XmppClient, IQ := XmppIQ, P := XmppPresence, M := XmppMuc;

CONST
  maxRooms* = 16; maxOccupants* = 128; maxTrackedUnits* = 262144;
  transitionTimeoutMS* = 30000;
  joining* = 0; joined* = 1; renaming* = 2; leaving* = 3;
  left* = 4; failed* = 5; disconnected* = 6;
  invalidRequest* = 1; offline* = 2; capacity* = 3;

TYPE
  Deadline = POINTER TO DeadlineDesc;
  DeadlineDesc = RECORD END;
  Room* = POINTER TO RoomDesc;
  RoomDesc* = RECORD
    address-, nick-, wantedNick-: T.String;
    state-: SHORTINT;
    created-, expired-, uncertain-, truncated-: BOOLEAN;
    count-: LONGINT;
    occupants-: ARRAY maxOccupants OF M.Occupant;
    sizes: ARRAY maxOccupants OF LONGINT;
    remaining, units: LONGINT;
    deadline: Deadline;
    renamed: BOOLEAN
  END;
  Tracker* = POINTER TO TrackerDesc;
  Hook* = POINTER TO HookDesc;
  HookDesc* = RECORD END;
  TrackerDesc* = RECORD (Client.HookDesc)
    client-: Client.Client;
    active-: BOOLEAN;
    count-, occupantCount-: LONGINT;
    rooms-: ARRAY maxRooms OF Room;
    units: LONGINT;
    own, bare: T.String;
    application: Client.Hook;
    hook: Hook;
    stopping, ticking: BOOLEAN
  END;
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (c: Context) GetTemplate(message: Msg.Msg; VAR text: Msg.LString);
BEGIN
  CASE message.code OF
  | offline: S.Long("XMPP room tracker is not online", text)
  | capacity: S.Long("XMPP room tracking limit exceeded", text)
  ELSE S.Long("Invalid bounded XMPP room transition", text)
  END
END GetTemplate;

PROCEDURE (h: Hook) Changed*(tracker: Tracker; room: Room);
BEGIN END Changed;
PROCEDURE (h: Hook) Presence*(tracker: Tracker; room: Room; event: M.Occupant; applied: BOOLEAN);
BEGIN END Presence;
PROCEDURE (h: Hook) Reset*(tracker: Tracker);
BEGIN END Reset;

PROCEDURE Arm(room: Room; timeoutMS: LONGINT);
BEGIN NEW(room.deadline); room.remaining := timeoutMS END Arm;

PROCEDURE Disarm(room: Room);
BEGIN room.deadline := NIL; room.remaining := 0 END Disarm;

PROCEDURE Owns(tracker: Tracker; room: Room): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  FOR i := 0 TO tracker.count-1 DO IF tracker.rooms[i] = room THEN RETURN TRUE END END;
  RETURN FALSE
END Owns;

PROCEDURE (t: Tracker) Find*(address: ARRAY OF T.CodeUnit): Room;
  VAR canonical: T.String; i: LONGINT;
BEGIN
  canonical := M.Room(address); IF canonical = NIL THEN RETURN NIL END;
  FOR i := 0 TO t.count-1 DO IF S.Equal(t.rooms[i].address^, canonical^) THEN RETURN t.rooms[i] END END;
  RETURN NIL
END Find;

PROCEDURE (r: Room) Find*(nick: ARRAY OF T.CodeUnit): M.Occupant;
  VAR i: LONGINT;
BEGIN
  FOR i := 0 TO r.count-1 DO IF S.Equal(r.occupants[i].nick^, nick) THEN RETURN r.occupants[i] END END;
  RETURN NIL
END Find;

PROCEDURE Units(event: M.Occupant): LONGINT;
  VAR units, i: LONGINT;
BEGIN
  units := S.Length(event.room^)+S.Length(event.nick^)+S.Length(event.jid^)+S.Length(event.role^)+
    S.Length(event.affiliation^)+S.Length(event.newNick^)+S.Length(event.actorJID^)+S.Length(event.actorNick^)+
    S.Length(event.reason^)+S.Length(event.alternateRoom^)+S.Length(event.destroyReason^);
  INC(units, S.Length(event.presence.from^)+S.Length(event.presence.bare^)+S.Length(event.presence.to^)+
    S.Length(event.presence.show^));
  FOR i := 0 TO event.presence.statusCount-1 DO
    INC(units, S.Length(event.presence.statuses[i].language^)+S.Length(event.presence.statuses[i].text^))
  END;
  RETURN units
END Units;

PROCEDURE ClearRoom(tracker: Tracker; room: Room);
  VAR i: LONGINT;
BEGIN
  DEC(tracker.units, room.units); DEC(tracker.occupantCount, room.count);
  FOR i := 0 TO room.count-1 DO room.occupants[i] := NIL; room.sizes[i] := 0 END;
  room.units := 0; room.count := 0; room.truncated := FALSE
END ClearRoom;

PROCEDURE Remove(tracker: Tracker; room: Room; nick: T.String);
  VAR slot, i, units: LONGINT;
BEGIN
  slot := 0;
  WHILE (slot < room.count) & ~S.Equal(room.occupants[slot].nick^, nick^) DO INC(slot) END;
  IF slot = room.count THEN RETURN END;
  units := room.sizes[slot]; DEC(room.units, units); DEC(tracker.units, units);
  DEC(room.count); DEC(tracker.occupantCount);
  FOR i := slot TO room.count-1 DO room.occupants[i] := room.occupants[i+1]; room.sizes[i] := room.sizes[i+1] END;
  room.occupants[room.count] := NIL; room.sizes[room.count] := 0
END Remove;

PROCEDURE Put(tracker: Tracker; room: Room; event: M.Occupant): BOOLEAN;
  VAR slot, units, previous: LONGINT;
BEGIN
  slot := 0;
  WHILE (slot < room.count) & ~S.Equal(room.occupants[slot].nick^, event.nick^) DO INC(slot) END;
  previous := 0;
  IF slot < room.count THEN previous := room.sizes[slot]
  ELSIF room.count = maxOccupants THEN room.truncated := TRUE; RETURN FALSE
  END;
  units := Units(event);
  IF units > maxTrackedUnits-tracker.units+previous THEN room.truncated := TRUE; RETURN FALSE END;
  INC(tracker.units, units-previous); INC(room.units, units-previous);
  room.occupants[slot] := event; room.sizes[slot] := units;
  IF slot = room.count THEN INC(room.count); INC(tracker.occupantCount) END;
  RETURN TRUE
END Put;

PROCEDURE (t: Tracker) Forget*(room: Room): BOOLEAN;
  VAR slot, i: LONGINT;
BEGIN
  IF (room = NIL) OR ~((room.state = left) OR (room.state = failed)) OR
     (room.uncertain & t.active) THEN RETURN FALSE END;
  slot := 0; WHILE (slot < t.count) & (t.rooms[slot] # room) DO INC(slot) END;
  IF slot = t.count THEN RETURN FALSE END;
  ClearRoom(t, room); DEC(t.count);
  FOR i := slot TO t.count-1 DO t.rooms[i] := t.rooms[i+1] END;
  t.rooms[t.count] := NIL; RETURN TRUE
END Forget;

PROCEDURE (t: Tracker) Stop*;
  VAR i: LONGINT; room: Room;
BEGIN
  IF t.stopping THEN RETURN END;
  t.stopping := TRUE; t.active := FALSE;
  FOR i := 0 TO t.count-1 DO
    room := t.rooms[i]; ClearRoom(t, room); room.state := disconnected; Disarm(room);
    t.rooms[i] := NIL
  END;
  t.count := 0; t.hook.Reset(t); t.stopping := FALSE
END Stop;

PROCEDURE Online(tracker: Tracker; timeoutMS: LONGINT; VAR error: Msg.Msg): BOOLEAN;
BEGIN
  error := NIL;
  IF ~tracker.active OR (tracker.client.state # Client.online) THEN error := Msg.New(context, offline); RETURN FALSE END;
  IF (timeoutMS <= 0) OR (timeoutMS > IQ.maxTimeoutMS) THEN error := Msg.New(context, invalidRequest); RETURN FALSE END;
  RETURN TRUE
END Online;

PROCEDURE (t: Tracker) Join*(address, nick, password: ARRAY OF T.CodeUnit; historyStanzas, timeoutMS: LONGINT;
                           VAR error: Msg.Msg): Room;
  VAR stanza: Core.Stanza; room: Room; canonical: T.String;
BEGIN
  IF ~Online(t, timeoutMS, error) THEN RETURN NIL END;
  stanza := M.Join(address, nick, password, historyStanzas); canonical := M.Room(address);
  IF (stanza = NIL) OR (canonical = NIL) OR (t.Find(address) # NIL) THEN error := Msg.New(context, invalidRequest); RETURN NIL END;
  IF t.count = maxRooms THEN error := Msg.New(context, capacity); RETURN NIL END;
  NEW(room); room.address := canonical; room.nick := Items.Copy16(nick); room.wantedNick := room.nick;
  room.state := joining; Arm(room, timeoutMS);
  t.rooms[t.count] := room; INC(t.count);
  t.client.Send(stanza, error);
  IF (error # NIL) & t.active THEN t.Stop END;
  IF t.active & Owns(t, room) & (room.state = joining) THEN t.hook.Changed(t, room) END;
  RETURN room
END Join;

PROCEDURE (t: Tracker) Rename*(room: Room; nick: ARRAY OF T.CodeUnit; timeoutMS: LONGINT; VAR error: Msg.Msg): BOOLEAN;
  VAR stanza: Core.Stanza;
BEGIN
  IF ~Online(t, timeoutMS, error) THEN RETURN FALSE END;
  IF ~Owns(t, room) OR (room.state # joined) OR S.Equal(room.nick^, nick) THEN
    error := Msg.New(context, invalidRequest); RETURN FALSE
  END;
  stanza := M.ChangeNick(room.address^, nick); IF stanza = NIL THEN error := Msg.New(context, invalidRequest); RETURN FALSE END;
  room.wantedNick := Items.Copy16(nick); room.state := renaming; Arm(room, timeoutMS);
  room.renamed := FALSE; room.expired := FALSE; t.client.Send(stanza, error);
  IF (error # NIL) & t.active THEN t.Stop END;
  IF t.active & Owns(t, room) & (room.state = renaming) THEN t.hook.Changed(t, room) END;
  RETURN error = NIL
END Rename;

PROCEDURE (t: Tracker) Leave*(room: Room; status: ARRAY OF T.CodeUnit; timeoutMS: LONGINT; VAR error: Msg.Msg): BOOLEAN;
  VAR stanza: Core.Stanza;
BEGIN
  IF ~Online(t, timeoutMS, error) THEN RETURN FALSE END;
  IF ~Owns(t, room) OR ~((room.state = joined) OR (room.state = renaming)) THEN
    error := Msg.New(context, invalidRequest); RETURN FALSE
  END;
  stanza := M.Leave(room.address^, room.nick^, status); IF stanza = NIL THEN error := Msg.New(context, invalidRequest); RETURN FALSE END;
  room.state := leaving; Arm(room, timeoutMS); room.expired := FALSE; t.client.Send(stanza, error);
  IF (error # NIL) & t.active THEN t.Stop END;
  IF t.active & Owns(t, room) & (room.state = leaving) THEN t.hook.Changed(t, room) END;
  RETURN error = NIL
END Leave;

PROCEDURE (t: Tracker) Tick*(elapsedMS: LONGINT);
  VAR rooms: ARRAY maxRooms OF Room; deadlines: ARRAY maxRooms OF Deadline; room: Room; i, count: LONGINT;
BEGIN
  ASSERT(elapsedMS >= 0); IF t.ticking THEN RETURN END;
  t.ticking := TRUE; rooms := t.rooms; count := t.count;
  FOR i := 0 TO count-1 DO deadlines[i] := rooms[i].deadline END;
  FOR i := 0 TO count-1 DO
    room := rooms[i];
    IF t.active & Owns(t, room) & (room.deadline = deadlines[i]) & (room.remaining > 0) THEN
      IF elapsedMS >= room.remaining THEN
        Disarm(room); room.expired := TRUE; room.uncertain := TRUE; room.state := failed; ClearRoom(t, room);
        t.hook.Changed(t, room)
      ELSE DEC(room.remaining, elapsedMS)
      END
    END
  END;
  t.ticking := FALSE
END Tick;

PROCEDURE ErrorPresence(tracker: Tracker; room: Room; event: M.Occupant): BOOLEAN;
BEGIN
  IF (event.nick[0] # 0) & ~S.Equal(event.nick^, room.nick^) &
     ~S.Equal(event.nick^, room.wantedNick^) THEN RETURN FALSE END;
  IF (room.state = joining) OR (((room.state = renaming) OR (room.state = leaving)) & room.renamed) THEN
    room.uncertain := room.renamed;
    room.state := failed; ClearRoom(tracker, room)
  ELSIF (room.state = renaming) OR (room.state = leaving) THEN
    room.state := joined; room.wantedNick := room.nick
  ELSE RETURN FALSE
  END;
  Disarm(room); RETURN TRUE
END ErrorPresence;

PROCEDURE Apply(tracker: Tracker; room: Room; event: M.Occupant): BOOLEAN;
  VAR self, applied: BOOLEAN;
BEGIN
  IF event.presence.kind = P.stanzaError THEN RETURN ErrorPresence(tracker, room, event) END;
  self := event.HasStatus(110) OR ((room.state # joining) & S.Equal(event.nick^, room.nick^));
  IF self THEN
    IF room.state = joining THEN
      IF ~S.Equal(event.nick^, room.wantedNick^) &
         ~((event.presence.kind = P.available) & event.HasStatus(210)) THEN RETURN FALSE END
    ELSIF ~S.Equal(event.nick^, room.nick^) &
          ~((room.state = renaming) & S.Equal(event.nick^, room.wantedNick^)) THEN RETURN FALSE
    END
  END;
  IF event.presence.kind = P.available THEN
    IF self & (room.state = renaming) & S.Equal(event.nick^, room.wantedNick^) &
       ~S.Equal(event.nick^, room.nick^) THEN Remove(tracker, room, room.nick) END;
    applied := Put(tracker, room, event);
    IF self & ((room.state = joining) OR
       ((room.state = renaming) & S.Equal(event.nick^, room.wantedNick^))) THEN
      IF room.state = joining THEN room.created := event.HasStatus(201) END;
      room.nick := event.nick; room.wantedNick := room.nick; room.state := joined;
      Disarm(room); room.renamed := FALSE
    END;
    RETURN applied
  END;
  Remove(tracker, room, event.nick);
  IF self THEN
    IF event.HasStatus(303) THEN
      room.nick := event.newNick; room.wantedNick := event.newNick; room.renamed := TRUE;
      IF room.state # leaving THEN
        IF room.remaining = 0 THEN Arm(room, transitionTimeoutMS) END;
        room.state := renaming
      END
    ELSE
      room.state := left; Disarm(room); ClearRoom(tracker, room)
    END
  END;
  RETURN TRUE
END Apply;

PROCEDURE Addressed(tracker: Tracker; stanza: Core.Stanza): BOOLEAN;
  VAR to: T.String;
BEGIN
  IF stanza.to[0] = 0 THEN RETURN stanza.item.GetAttribute("", "to") = NIL END;
  to := IQ.CanonicalJID(stanza.to^);
  RETURN (to # NIL) & (S.Equal(to^, tracker.own^) OR S.Equal(to^, tracker.bare^))
END Addressed;

PROCEDURE (t: Tracker) Ready*(client: Client.Client; jid: T.String);
BEGIN
  ASSERT(t.client = NIL); t.client := client; t.own := IQ.CanonicalJID(jid^);
  IF t.own = NIL THEN client.Abort; t.application.Error(client, Msg.New(context, invalidRequest)); RETURN END;
  t.bare := P.Bare(t.own^); t.active := TRUE; t.hook.Reset(t);
  IF t.active THEN t.application.Ready(client, jid) END
END Ready;

PROCEDURE (t: Tracker) RegistrationReady*(client: Client.Client);
BEGIN
  ASSERT(t.client = NIL); t.client := client; t.application.RegistrationReady(client)
END RegistrationReady;

PROCEDURE (t: Tracker) Received*(client: Client.Client; stanza: Core.Stanza);
  VAR from, bare: T.String; room: Room; event: M.Occupant; applied: BOOLEAN; state: SHORTINT;
BEGIN
  ASSERT(client = t.client);
  IF t.active & (client.state = Client.online) & (stanza.kind = Core.presence) & Addressed(t, stanza) THEN
    from := IQ.CanonicalJID(stanza.from^);
    IF from # NIL THEN
      bare := P.Bare(from^); room := t.Find(bare^);
      IF (room # NIL) & ((room.state = joining) OR (room.state = joined) OR
         (room.state = renaming) OR (room.state = leaving)) THEN
        event := M.ReadPresence(stanza, room.address^);
        IF event # NIL THEN
          state := room.state; applied := Apply(t, room, event);
          IF state # room.state THEN t.hook.Changed(t, room) END;
          IF t.active & Owns(t, room) THEN t.hook.Presence(t, room, event, applied) END
        END
      END
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

BEGIN NEW(context); Msg.InitContext(context, "XmppMucTracker")
END XmppMucTracker.
