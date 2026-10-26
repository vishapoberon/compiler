# Presence and resource tracking

`XmppPresence` builds and decodes RFC 6121 availability and subscription
stanzas. `XmppPresenceTracker` keeps bounded availability for explicitly watched
contacts and forwards client events to the application. Use these alongside
the [roster](RosterPEP.md) and [IQ router](IQ.md).

## Sending presence

All string arguments use UTF-16 code units. Convert UTF-8 with
`XmppItems.UTF8`; pass an empty string for broadcast availability.

- `Available(to, show, status, priority)` builds available presence. `show` is
  empty, `away`, `chat`, `dnd` or `xa`; priority ranges from -128 through 127.
- `Unavailable(to, status)` builds directed or broadcast unavailable presence.
- `Subscription(to, status, kind)` builds `subscribe`, `subscribed`,
  `unsubscribe` or `unsubscribed`, selected by the corresponding constants.
  The target must be a bare JID. Approving a request uses `subscribed`;
  denying a request or revoking permission uses `unsubscribed`.

These builders return `NIL` on invalid JIDs, values or bounds. They canonicalize
domain names through shared IDNA while preserving Unicode XML identities.
`NewPresence(to, status)` retains the existing basic construction interface.
Send the constructed stanza explicitly through `client.Send(stanza, error)`.
Applications can attach their own subscription-tracking IDs before sending;
approval/denial IDs should be new IDs rather than copies of an incoming request.

After login, request the roster and then send initial availability when the
application intends to become available. Before orderly shutdown, send
unavailable presence and close the stream. Becoming available can make the
account visible to subscribed contacts and enable PEP notifications.

Subscription decisions are explicit application actions. Inbound requests are
reported for approval or denial; the library sends no automatic approval,
reciprocal subscription or presence probe. Roster subscription attributes stay
server-owned and change through authoritative roster pushes. Sending a
subscription stanza leaves the roster cache unchanged.

## Decoding

`XmppPresence.Read(stanza)` returns a decoded `Event` or `NIL`. Events expose
canonical `from`, `bare` and optional `to` JIDs, `kind`, `show`, `priority` and
status text. Kinds include available/unavailable, the four subscription types,
probes and stanza errors. The first status is also available as `event.status`.

The decoder accepts up to eight distinct status languages, including inherited
`xml:lang`. Each status contains `language` and `text`; language tags use a
bounded ASCII letters/digits/hyphen profile and compare case-insensitively.
Each status is limited to 4,096 UTF-16 units, with 8,192 units across all statuses.
The default priority is zero. XML integer signs, leading zeroes and surrounding
XML whitespace are accepted within the 32-unit priority lexical limit.
Duplicate show/priority fields, unknown show values, out-of-range priorities,
nested status markup and duplicate effective status languages are rejected.
Foreign-namespace extensions remain available through the original stanza and
are ignored by this decoder. Error events expose the validated `<error>` tree.

Incoming subscription senders can include a resource; use `event.bare` for
account-level subscription decisions and outgoing requests. Full localpart and
resource preparation remains pending as documented in the IQ address policy.
Treat received status text and extension payloads as untrusted application data.

## Hook and watchlist setup

1. Extend `XmppPresenceTracker.HookDesc` and implement
   `Notice(tracker, event, applied)` and optionally `Reset(tracker)`.
2. Create `tracker := XmppPresenceTracker.New(applicationHook, presenceHook)`.
3. Add chosen bare JIDs with `tracker.Watch(jid)`. Roster entries with
   subscription `to` or `both` are typical choices; update watches explicitly
   in roster callbacks. Directed-presence contacts can be watched separately.
4. Create `router := XmppIQ.New(tracker)`, register IQ/roster handlers, and pass
   the router as the client's hook. The tracker can also be the direct client
   hook when the application handles IQs itself. Use a fresh chain per client.

The tracker checks presence recipients against its local full/bare JID, or
accepts omitted recipients. Invalid, unrelated-recipient and non-presence
stanzas are forwarded only to the application hook. Valid presence is decoded,
applied to watched resources when appropriate, and delivered to `Notice` before
the original stanza reaches the application hook. The raw hook receives every
stanza, including malformed/unrelated ones, so applications should use the
validated event path for availability decisions.

`applied` is true for a watched availability update accepted within the limits,
including an unavailable update for an already absent resource. Subscription,
probe and error events are notices without availability-cache changes. Valid
unwatched presence and over-limit resource updates have `applied = FALSE`.
Callbacks may unwatch or stop tracking; state changes precede the callback.

## Resource cache and lifecycle

- `Find(fullJID)` returns the exact resource's latest available event.
- `Best(jid)` returns the highest nonnegative-priority resource for that bare
  account, breaking ties lexically by canonical full JID. Negative-priority
  resources remain visible through `Find` and `entries`. Routing decisions
  remain application-owned.
- `Forget(fullJID)` removes one resource; `Forget(bareJID)` removes all of its
  resources. Inbound unavailable presence follows the same rule.
- `Unwatch(bareJID)` removes the watch and its resources. Repeated `Watch` calls
  for the same canonical bare JID succeed without adding duplicates.
- `Clear` removes resources and calls `Reset`, preserving watches.
- `Stop` disables tracking and clears resources. Call it, then `router.Stop`,
  before `client.Abort`, which deliberately skips client hooks. Client errors
  and orderly stream closure stop/clear tracking automatically.

Watchlists have at most 128 contacts and 65,536 retained JID units. Resource
state has at most 16 resources per contact, 256 entries overall and 262,144
retained JID/show/status/language units. Updates that exceed a limit preserve
the previous cache. Replacements release the old entry's budget before charging
the new entry. Event pointers retained by the application remain read-only
snapshots; release them when finished. `Ready` clears resources before forwarding
the client's ready notification, and `Reset` observes an empty cache.

Offline tests cover Unicode JIDs/statuses, all 110 transport split sizes,
subscription notices, resource selection, malformed data, limits, reentrant
callbacks and disconnect cleanup. Local verified STARTTLS/direct-TLS peers
exercise availability and all four explicit subscription stanzas. Broader live
presence interoperability remains pending.
