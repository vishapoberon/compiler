# Multi-user chat

`XmppMuc` constructs and decodes the core [XEP-0045](https://xmpp.org/extensions/xep-0045.html)
room stanzas. It provides joins, departures, group messages and subjects, and
reads occupant roles, affiliations, disclosed JIDs and room status codes.
It also handles mediated invitations and explicit owner/admin IQ operations.
It uses `XmppTypes.CodeUnit`, the shared UTF-16 code-unit type; XML on the wire
is UTF-8. Convert UTF-8 arguments with `XmppItems.UTF8`.

## Sending

After the client is online, construct a stanza and send it with `client.Send`:

```oberon
room := Items.UTF8("room@conference.example.org");
nickname := Items.UTF8("Անի");
empty := Items.Latin1("");
stanza := Muc.Join(room^, nickname^, empty^, 0);
IF stanza # NIL THEN client.Send(stanza, error) END;
```

All constructors return `NIL` for invalid addresses, text or limits:

- `Join(room, nick, password, historyStanzas)` addresses available presence to
  `room/nick` and adds the MUC join extension. An empty password omits that field.
  A history value of `0` requests no history, `1` through `1000` requests at most
  that many stanzas, and `-1` leaves the history policy to the server. This is a
  request to the server; applications must also bound the history they process.
- `Leave(room, nick, status)` constructs unavailable presence. Use the current
  nickname, including any change reported by the room.
- `GroupMessage(room, body)` addresses a `groupchat` message to the bare room.
- `Subject(room, subject)` constructs a subject-only group message. Empty text
  requests an empty subject.
- `ChangeNick(room, nick)` constructs available presence to the replacement
  occupant address without a fresh join extension. Wait for the room's nickname
  transition and self-presence before considering the change complete.

`Room(jid)` checks a bare `room@service` address. `OccupantJID(room, nick)` checks
and joins a room and nickname. Domain names use the shared IDNA policy. Localparts
and nicknames retain their spelling; full username/resource preparation remains
pending. Nicknames follow XMPP resourcepart syntax, including embedded `/` or `@`.

A successful send confirms only the local write. Wait for self-presence with
status `110` before treating a join as complete. Status `210` means the service
assigned the nickname; take it from the returned occupant address. Status `201`
signals a newly created room whose configuration may still be required.
Keep room passwords out of stanza logs and output hooks, and release password
strings and join stanzas when no longer needed.

## Invitations

`Invite(room, peer, reason)` sends a mediated invitation through the room.
`Decline(room, inviter, reason)` sends a refusal through the same room. Both
validate and canonicalize their destinations and omit an empty reason.
Sending an invitation does not add the recipient to an active-room cache or
grant membership locally; permission remains with the service.

`ReadInvitation(stanza, expectedRoom)` accepts a normal message from that bare
room with one MUC-user invitation or decline. The returned `Invitation` exposes
`room`, the canonical `peer`, `reason`, optional `password` and `declined`.
`continued` and `thread` describe an invitation continuing an existing chat.
Occupant-address senders, mismatched rooms, missing peers, duplicate payloads,
nested scalar text and password-bearing declines are rejected. As with presence,
the caller checks recipients and decides whether to trust or accept invitations.
Passwords must not be logged. Direct XEP-0249 invitations remain separate work.

## Configuration and administration

These procedures use an authenticated `XmppIQ.Router`, a positive timeout and
an `XmppIQ.Action`. They return an IQ request or `NIL` with an error. Drive
`router.Tick` for deadlines and inspect the request status in the completion
callback. A room-management reply must come from the exact bare room: a reply
from `room/nick` cannot complete it. This uses `router.QueryExact`; ordinary
account IQ requests retain their existing bare-account/resource matching.

- `RequestConfiguration(router, room, timeoutMS, action, error)` requests the
  owner's configuration form. `ReadConfiguration(request)` returns a bounded
  `jabber:x:data` form only for a successful configuration retrieval.
- `SubmitConfiguration(router, room, form, timeoutMS, action, error)` takes
  ownership of a detached data-form submission. Build a fresh `x` element in
  `jabber:x:data` with `type="submit"`; it must contain exactly one `FORM_TYPE`
  field/value equal to `http://jabber.org/protocol/muc#roomconfig`. Other fields
  have distinct nonempty `var` names and scalar `value` children. Do not reuse
  the form after handing it to this operation. Server-provided forms are views
  of their response tree, not detached submissions; select and copy the answers
  the application actually intends to send.
- `ConfigureDefault(router, room, cancel, timeoutMS, action, error)` sends an
  empty submission for an instant room when `cancel` is false, or cancels room
  configuration when true. Neither action is automatic on status `201`.
- `SetRole(router, room, nick, role, reason, timeoutMS, action, error)` changes
  an occupant's role. `none` requests removal; `moderator`, `participant` and
  `visitor` request those roles.
- `SetAffiliation(router, room, jid, affiliation, reason, timeoutMS, action, error)`
  requires a bare JID and one of `owner`, `admin`, `member`, `outcast` or `none`.
  `outcast` requests a ban. The server enforces privileges and room policy.
- `RequestRoleList(router, room, role, timeoutMS, action, error)` retrieves
  moderators, participants or visitors. `RequestAffiliationList` retrieves
  owners, admins, members or outcasts. `none` is not a list filter.
  `ReadMembers(request)` returns up to 64 typed entries with nickname, JID,
  role, affiliation and optional actor/reason fields. Optional undisclosed
  fields are empty strings. Duplicate identities, missing required identity
  fields, mismatched filters and over-limit responses fail atomically.
- `Destroy(router, room, alternate, reason, timeoutMS, action, error)` explicitly
  requests destruction, with an optional alternate bare room and reason.

For mutation results, `XmppIQ.EmptyResult(request)` confirms a successful empty
IQ response. Errors, cancellations, deadlines and send failures use the normal
IQ statuses. A successful IQ does not synthesize presence or update a room's
occupant state; process the actual room broadcasts. Field policy, form UI and
confirmation of destructive actions belong to the caller. A reusable room-state
tracker remains pending.

## Receiving

Call `ReadPresence(stanza, expectedRoom)` and `ReadMessage(stanza, expectedRoom)`
from the authenticated client's receive hook. Each returns `NIL` for unrelated
or malformed input. They canonicalize the sender's domain and require its bare
JID to match the explicit room; room localparts remain case-sensitive. These
checks rely on the authenticated connection's sender routing. Applications also
own recipient checks, pending joins and active-room state.

`ReadPresence` returns an `Occupant` with:

- `room`, `nick` and the base `XmppPresence.Event` in `presence`, including
  availability, multilingual statuses or a stanza error;
- `role`, `affiliation` and `jid`; the latter is empty when the room does not
  disclose the participant's real JID;
- `codes`, `codeCount` and `HasStatus(code)` for bounded, distinct status codes;
- `newNick` for nickname changes, and `actorJID`, `actorNick` and `reason` for
  administrative changes;
- `destroyed`, `alternateRoom` and `destroyReason` for room destruction.

Normal occupant presence requires one MUC-user extension with one item and
valid role/affiliation values. Stanza errors can originate from the bare room
or an occupant address and expose their error through `presence.error`.
Malformed duplicates, namespace lookalikes and invalid status codes fail.
Status `303` requires unavailable presence and a nonempty replacement nickname.
Unknown numeric codes in the range `100`–`999` are retained for the application.

`ReadMessage` accepts `groupchat` bodies and subjects from the room or one of
its occupant addresses. `bodies` and `subjects` retain language-tagged variants;
`body` and `subject` expose the first variant. Counts distinguish a missing
field from an explicitly empty one. Language tags are compared without ASCII
case differences, including inherited stream/stanza language. Other extensions,
such as delayed delivery, remain in the original stanza for the application.
Inspect delay metadata before presenting history as a new message.

Room membership, occupant caches, nickname-change sequencing and join deadlines
remain application or future extension work. On disconnect, clear room state
and require a new confirmed join.
Keep direct contact presence watches separate from room occupant tracking.

## Limits and tests

Bodies, subjects and reasons allow 4,096 UTF-16 units per field; message body and
subject variants share an 8,192-unit budget. Each body/subject list allows eight
languages. Passwords allow 1,024 units. Nicknames also obey the shared JID limit
of 1,023 UTF-8 bytes per component. Decoding accepts 32 distinct status codes and
at most 128 direct content parts in each processed structural or scalar element.
Configuration forms allow 256 nodes, nesting through depth 16 and a combined
16,384-unit text/attribute-value budget. Submissions allow 64 distinct fields
and 4,096 units per value. Received forms retain their tree for application
inspection; unsupported field policy is never accepted automatically.
The XML stream's byte, node and nesting limits apply before decoding.

`make test` runs `TestXmppMuc`, covering Unicode and escaping, fragmented input,
anonymous/disclosed identities, role and affiliation fields, nickname changes,
removals, destruction, errors, language variants, invitations, spoofed rooms and
budgets. `TestXmppIQ` exercises management requests, exact-room reply matching,
form validation, cancellation and deadlines, including 110 input split sizes.
`make network-test` also exercises join/message/subject/leave exchanges against
local STARTTLS and direct-TLS peers, plus mediated invitations, form retrieval
and submission, instant-room configuration, role/affiliation changes, destruction
and forged occupant-address IQ rejection. Broader live-server interoperability
remains pending.
