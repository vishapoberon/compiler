# Roster and personal publishing

`XmppRoster` implements RFC 6121 roster retrieval, edits and server pushes.
`XmppPubSub` supplies XEP-0060 publish, subscription, retrieval and retraction operations and
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
See [presence](Presence.md) for subscription builders and resource tracking.

## Explicit subscriptions

`Subscribe(router, peer, node, jid, timeoutMS, action, error)` requests a
subscription to a PubSub node. `peer` identifies the service, `node` the feed,
and `jid` the subscriber's bare or full JID. Subscriber domains are canonicalized
without changing the resource. `BuildSubscribe` returns the detached payload.
Supply a non-NIL `XmppIQ.Action` callback, as with other router queries.

In the completion callback, `ReadSubscription(request)` returns a checked
subscription record or `NIL`. Its `node` and canonical `jid` must match the
request. The record retains the optional subscription `id`, the server's `state`
and whether `configurationRequired` is set. States are `subscriptionNone`,
`subscriptionPending`, `subscriptionUnconfigured` and `subscriptionSubscribed`.
Only `subscriptionSubscribed` without required configuration establishes an
active subscription; pending approval and configuration remain explicit.
An empty successful IQ does not establish a subscription.

`Unsubscribe(router, peer, node, jid, id, timeoutMS, action, error)` cancels a
subscription. Pass the returned subscription ID when the service requires it,
or an empty string when there is no ID. `BuildUnsubscribe` exposes the payload.
`Unsubscribed(request)` requires an empty successful result for that exact
unsubscribe operation. Timeouts, cancellation, errors and unrelated replies do
not establish or cancel local follow state automatically.

The IQ router checks response senders and request IDs. Subscription results
also reject mismatched nodes/JIDs, duplicate result operations, invalid states,
malformed configuration markers and over-limit IDs. Choosing feeds, subscriber
identities, access models and authorization remains application policy.

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

### Paged history

After discovering the service's `http://jabber.org/protocol/pubsub#rsm` feature,
use `FetchPage(router, peer, node, cursor, direction, maximum, timeoutMS, action,
error)`. `BuildPage` returns its detached payload. The XEP-0059 `<set>` element
is a sibling of `<items>` inside `<pubsub>`.

Directions come from `XmppRSM`:

- `firstPage` with an empty cursor requests the first page.
- `afterPage` requires the preceding page's opaque last UID.
- `beforePage` uses the following page's first UID; an empty cursor requests the
  final page.

Page maxima range from zero to 64. Zero requests count metadata without items.
`ReadPage(request)` returns a checked page or `NIL`. A page exposes its `items`
tree, actual `size`, and RSM `info`: first/last UIDs, count and first-item index.
`hasCount` and `hasIndex` distinguish omitted metadata from a genuine zero.
The first and last UIDs must match the returned items. Duplicate operations,
mismatched nodes, repeated requested cursors, inconsistent counts and malformed
metadata are rejected. A page request without RSM reply metadata is not accepted.
`ReadItems` can read the validated item tree of a paged request and accepts valid
RSM metadata accompanying an ordinary `Fetch` result.

Treat returned trees and metadata strings as read-only. RSM cursors identify
items, not timestamps or arithmetic offsets. Pages describe a changing result
set, not a frozen snapshot. An incomplete, failed or truncated traversal must
not be interpreted as deletion of cached posts.

`XmppRSM` also exposes generic `Build`, `BuildIndex`, `ReadRequest` and
`ReadResult` helpers. A decoded request has `maximum = -1` when the peer omits
the maximum; the application must impose its own resource bound. Request and
result parsers preserve the previous output record on failure, bound Unicode
cursors to 1,024 units and reject decimal overflow. These helpers describe
payloads; authorization and history retention remain service decisions.

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
presence when the chosen PEP service requires them. Access models, subscription
policy, node configuration, publish options and retry policy remain
application-owned. Retain item IDs when implementing idempotent retries;
a failed connection after sending can leave the publication outcome uncertain.

`XmppPEP` in the microblog publisher builds bounded XEP-0277 Atom entries using
these shared operations. The separate VOC
[publisher example](https://github.com/vishapoberon/compiler/tree/master/src/examples/network/xmpp-publish)
provides configuration, login and one-shot publishing.

Offline and verified local TLS tests cover roster and PubSub operations,
including Unicode accounts/domains, spoofed pushes and notifications, stale
fetches and bounded malformed input. Live-server tests cover verified STARTTLS,
publication and exact-item retrieval with matching Atom text. Live roster
testing and broader PEP interoperability remain pending.
