# Roster and personal publishing

`XmppRoster` implements RFC 6121 roster retrieval, edits and server pushes.
`XmppPubSub` supplies XEP-0060 publish, retrieval and retraction operations and
XEP-0163 personal-event parsing. Both use `XmppIQ` for peer-checked replies,
cancellation and application-driven deadlines. Strings use UTF-16 code units;
convert UTF-8 with `XmppItems.UTF8`.

## Roster

Before login, create `roster := XmppRoster.New(router, rosterHook)`, extending
`XmppRoster.HookDesc` for callbacks. Pass the router to `XmppClient.New` as
described in [IQ extensions](IQ.md). After `Ready`:

- `roster.Fetch(timeoutMS, error)` requests a full roster. One fetch can be
  pending at a time. It returns the correlated IQ request, or `NIL` and a
  diagnostic on immediate failure.
- `Hook.Loaded(roster, request, accepted)` runs on every queued fetch completion.
  `accepted` means a valid full snapshot replaced the cache. Inspect
  `request.status` for timeouts, cancellation, stanza errors and write failures.
- `roster.snapshot` holds a bounded snapshot with `count` and `entries`.
  `roster.Find(bareJID)` performs domain-canonicalized lookup.
  Entries expose the JID, name, subscription (`none`, `to`, `from`, `both`),
  outgoing pending-subscription flag, preapproval flag and groups.
- `XmppRoster.Set(router, jid, name, groups, removing, timeoutMS, action, error)`
  adds, renames, regroups or removes a contact. `groups` is an array of UTF-16
  string pointers; pass an empty array for no groups. `BuildSet` exposes the
  detached payload. Check `XmppIQ.EmptyResult` in the action's completion.
  Acknowledgements leave the cache unchanged; authoritative pushes update it.

Pushes must omit `from` or identify the account's own bare JID. Foreign senders,
including the server's domain and the account's full resource JIDs, are silently
ignored even when the roster IQ is structurally malformed. Valid pushes contain
exactly one item, update the cache and call `Hook.Changed(roster, entry)` before
the result acknowledgement is sent. A removal entry has subscription `remove`;
its JID is then absent from the cache. Repeated removals are acknowledged.

Snapshots are replaced atomically. Retained snapshots remain usable after
updates; treat their entries and strings as read-only. Invalid replies leave
the cache unchanged. A push received while a fetch is pending makes that fetch's
snapshot stale: `Loaded` reports `accepted = FALSE` even if its IQ status is
`result`. Applied pushes are preserved, and the application can refetch.
`complete` records that at least one full snapshot has been accepted. After
disconnect, the cache is historical; use a new roster/router for a new client.

There are at most 256 contacts, 16 groups per contact, 1,024 UTF-16 units per
name/group and 262,144 retained JID/name/group units across the roster.
Resource-qualified contact JIDs, duplicate canonical JIDs, duplicate groups,
invalid subscription values, nested group markup and over-limit data fail
without partial updates. Unknown foreign-namespace item extensions are ignored.
Oversized pushes receive `resource-constraint`. Full fetches use unversioned
roster requests. Presence subscription decisions remain application-owned;
explicitly request or authorize presence separately from editing roster entries.

## Publishing and retrieving personal events

Use the account's bare JID, or an empty peer for its local server, for personal
publication. Use the publisher's bare JID to retrieve their items. Generic
PubSub services can also be addressed through the same IQ operations.

- `Publish(router, peer, node, id, payload, timeoutMS, action, error)` publishes
  one detached XML payload with a caller-selected nonempty item ID.
- `Fetch(router, peer, node, id, maximum, timeoutMS, action, error)` retrieves
  items; an empty ID selects recent items, otherwise it selects that exact ID.
- `Retract(router, peer, node, id, notify, timeoutMS, action, error)` removes an
  item, optionally requesting a retraction notification.
- `BuildPublish`, `BuildItems` and `BuildRetract` expose detached IQ payloads.
  Successful `BuildPublish` adopts the supplied XML element. Construct fresh
  trees for subsequent sends; payload trees and queued requests must be treated
  as read-only after submission.
- `Published(request)` accepts an empty successful result or an exact
  node/item-matched publish acknowledgement. `Retracted(request)` requires an
  empty successful result for a retraction request. `ReadItems(request)` returns
  a validated, node/ID-matched `<items>` tree or `NIL`. A valid empty result set
  is an empty `<items>` element inside a successful IQ result.

Item lists reject duplicate IDs, wrong namespaces, mixed text and multiple
payload elements. Payloadless items are accepted and have no payload element.
At most 64 items are accepted, bounded further by the requested maximum and
by a single-ID selection. Nodes and IDs are limited to 1,024 UTF-16 units.
Serialized XML payloads have a 65,536-byte budget, shared across a received
item list or event. Incoming stanzas also retain the client's XML limits.

In the application's `Received` callback, call
`ReadEvent(stanza, expectedPublisher, expectedNode)`. It requires a matching
canonical bare sender and node, a normal/headline message, and exactly one
PubSub event operation. It returns `NIL` on invalid or unrelated messages.
An `items` event exposes up to 64 `updates`, each with `kind` (`published` or
`retracted`), `id` and optional XML `payload`. A payloadless publication or
retraction has `payload = NIL`. Purge and simple node deletion events have
kind `purged` or `deleted` and no updates; deletion redirects are unsupported.

Choose trusted publishers explicitly and interpret their payload namespaces
in application code. Subscriptions and publisher authorization are application
decisions. Advertise the node's `+notify` feature through `XmppDisco` and send
presence when the chosen PEP service requires them. Access models, explicit
subscriptions, node configuration, publish options and retry policy remain
application-owned. Retain item IDs when implementing idempotent retries;
a failed connection after sending can leave the publication outcome uncertain.

`XmppPEP` in the microblog publisher builds bounded XEP-0277 Atom entries using
these shared operations. The separate VOC
[publisher example](https://github.com/vishapoberon/compiler/tree/master/src/examples/network/xmpp-publish)
provides configuration, login and one-shot publishing.

Offline and verified local TLS tests cover roster and PubSub operations,
including Unicode accounts/domains, spoofed pushes and notifications, stale
fetches and bounded malformed input. Live roster/PEP interoperability remains pending.
