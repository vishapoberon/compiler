# room-state tracking

`XmppMucTracker` keeps bounded state for rooms that the application explicitly
joins. It wraps a `XmppClient.Hook`, using the stanza builders and decoders in
`XmppMuc`. Room permissions and configuration remain explicit application
decisions.

## attaching the tracker

Construct the room tracker before the IQ router and pass the router to the
client:

```oberon
rooms := Rooms.New(application, observer);
router := IQ.New(rooms);
client := Client.New(transport, router, domain, username^, password^,
  resource^, TRUE, error);
```

Here `Rooms` names `XmppMucTracker`, `application` extends `XmppClient.HookDesc`
and `observer` extends `Rooms.HookDesc`. If contact presence tracking is also
needed, place `XmppPresenceTracker` between the IQ router and the room tracker.
Each hook forwards the original client events to the next hook.
Keep tracker calls and callbacks on the same serialized execution context as
the VOC runtime; the tracker does not add cross-thread synchronization.

The tracker becomes active after the client's authenticated `Ready` event.
Create a fresh tracker and client for each connection. Joining is explicit:

```oberon
room := rooms.Join(address^, nick^, roomPassword^, 0, 10000, error);
IF (room # NIL) & (error = NIL) THEN
  (* the join has been sent; membership is confirmed by self-presence *)
END;
```

The history argument has the same meaning as `XmppMuc.Join`. A successful local
write leaves the room in `joining`; self-presence with status `110` confirms
membership. Status `210` permits a server-assigned nickname, and status `201`
sets `room.created`. The application decides whether and how to configure a
new room. Join passwords are used in the outgoing stanza but are not retained
in room records. Output hooks must still keep those stanzas out of logs.

Invalid arguments, duplicate rooms and capacity failures return `NIL` with an
error. A synchronous transport failure can return a room record together with
an error; client-error cleanup has already detached its state.

## transitions

`room.state` is one of:

- `joining`: waiting for the requested or explicitly assigned self identity;
- `joined`: confirmed membership;
- `renaming`: waiting for a nickname transition to finish;
- `leaving`: waiting for unavailable self-presence;
- `left`: the room confirmed departure, removal or destruction;
- `failed`: a stanza error or deadline ended the pending transition;
- `disconnected`: client close/error or local tracker shutdown detached the room.

`rooms.Rename(room, nick, timeoutMS, error)` starts a nickname change on a joined
room. `wantedNick` records the request; `nick` remains the old target until the
room announces the switch or confirms the new self identity. Status `303`
removes the old cache entry and moves `nick` to the announced replacement, but
the state stays `renaming` until available self-presence confirms it. A
server-initiated switch gets a 30-second transition deadline. A rejection before
the old nickname is removed restores the confirmed membership. A failure after
that removal cannot safely restore it.

`rooms.Leave(room, status, timeoutMS, error)` sends unavailable presence to the
current target. The state stays `leaving` until the room confirms departure.
The tracker also recognizes removal or destruction sent to its confirmed
occupant address. Other occupants' unavailable presence removes only their own
cache entries. A successful administration IQ does not invent presence updates.

Call `rooms.Tick(elapsedMS)` with nonnegative elapsed milliseconds. Transition
deadlines are at most `XmppIQ.maxTimeoutMS`. Timed-out transitions set `expired`
and `uncertain`, enter `failed` and clear their occupant cache. Late presence
cannot revive them. Since ordinary MUC presence has no reliable request/reply
correlation for a retry, an uncertain room cannot be forgotten and rejoined on
the same active tracker. Reconnect with a fresh client/tracker instead. An
explicitly rejected join can be forgotten with `rooms.Forget(room)`.

Timer callbacks may start transitions on other rooms. A new deadline receives
its full duration, without consuming the elapsed time from the tick that
created it. Nested `Tick` calls during a tick are ignored.

## occupants and limits

`rooms.Find(address)` looks up a canonical bare room. `room.Find(nick)` looks up
an occupant by its exact nickname; `room.occupants` and `room.count` expose the
bounded cache. Nicknames and room localparts retain their spelling. Domains use
the shared IDNA policy.

There are at most 16 tracked room records, 128 occupants per room and 262,144
retained UTF-16 text units across all occupant caches. Each event also obeys the
stanza decoder's limits. Updating an existing occupant replaces its budget;
departures release it. Cache overflow rejects the new cache entry without
evicting another occupant, sets `room.truncated` and reports `applied = FALSE`.
A genuine self-presence can still confirm membership when its cache entry does
not fit. Once truncated, the cache stays marked incomplete until room cleanup.

`rooms.Forget` releases records for confirmed departures and safely rejected
transitions. It rejects active rooms and uncertain failures. Ended rooms count
toward the room limit until forgotten or the tracker is stopped.

## callbacks and cleanup

Implement these `Rooms.Hook` methods:

- `Changed(tracker, room)` observes a state transition after it is committed.
- `Presence(tracker, room, event, applied)` receives decoded room presence and
  whether its cache/transition update was accepted. Use this for nickname and
  occupant metadata changes that do not change the room state.
- `Reset(tracker)` runs after all room and occupant state has been cleared.

Recipients must match the bound local full/bare JID or be omitted. Explicit
empty recipients and other recipients are ignored. Only explicitly tracked
rooms can affect state. The underlying client still receives the original
stanza, including ignored or rejected room input.

Callbacks can forget ended rooms or stop the tracker. Subsequent observer
notifications for a removed room are suppressed. `Stop` guards recursive reset
callbacks and clears records before notifying the application. It clears local
tracking; use `Leave` or transport closure to end server-side membership.

Normal client close/error hooks stop the tracker automatically. `client.Abort`
deliberately skips hooks: call `router.Stop` and `rooms.Stop` first, together with
any other tracking hooks in the chain, then abort the client. This cancels IQs
and discards room state before closing the transport.

The room tracker does not automatically accept invitations, approve membership,
change configuration, retry failed joins or reconnect. Those actions require
application policy and user consent.
