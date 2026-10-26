# IQ extensions

`XmppIQ` routes authenticated IQ requests by namespace and local name, correlates
replies and forwards unhandled client events to the application's `XmppClient.Hook`.
It preserves the existing client lifecycle and message/presence interfaces.

## Setup

1. Create `router := XmppIQ.New(applicationHook)`.
2. Before login, register handlers with `router.Register`, or create
   `XmppPing.New(router)`, `XmppVersion.New(router, name, version, os)` and
   `XmppDisco.New(router, category, type, name)`. Constructors return `NIL` on
   invalid configuration or exhausted/duplicate registrations. Software metadata
   is published only when its handler is explicitly created.
3. Pass the router as the hook to `XmppClient.New`. Use one router per client.
4. After `Ready`, call an extension's `Query` or `router.Query` with a detached
   payload, UTF-16 peer JID, timeout in milliseconds and `XmppIQ.Action`.

Override `Action.Done(router, request)` to inspect `request.status`. It runs once
after the pending slot has been released, so it can submit another request.
Immediate validation/offline/queue failures return `NIL` and a diagnostic without
calling `Done`. A request accepted into the queue can instead complete with
`sendFailed`, including a synchronous send failure.

`result` and `stanzaError` distinguish successful replies from stanza errors.
`malformed` identifies an address-matched reply with an invalid IQ envelope or
error structure. `reply` retains that stanza. Use `EmptyResult` for a ping,
`XmppVersion.Read` for bounded software metadata, and `XmppDisco.Read` for a
namespace/node-matched discovery tree. Applications interpret discovery entries
and decide which advertised features to trust.

`XmppDisco` serves one configured identity, up to 64 features and 64 items.
Add features explicitly with `AddFeature`, including ping/version when enabled.
Unknown nonempty discovery nodes receive `item-not-found`. Custom IQ handlers
extend `HandlerDesc` and return `Response` or `ErrorReply`; unknown requests
receive `service-unavailable`. Replies to replies are never generated.

## Bounds and lifecycle

There are at most 16 handlers and 32 pending requests. Handler registration is
frozen after `Ready`. IDs have at most 128 UTF-16 units; generated IDs are
monotonic within the router and never reused. Timeouts range from 1 ms to one
hour. Incoming XML retains the client's stanza, depth and work limits. Completed
requests retain their reply and outgoing payload for the caller; release those
references when finished.

Call `router.Tick(elapsedMilliseconds)` with elapsed time from the application's
clock. It processes only requests present when the tick started. `Cancel`
completes one pending request; `Stop` cancels all requests and disables the
router. Client errors and normal stream closure drain the queue automatically.
Call `router.Stop` before `client.Abort`, because aborting deliberately skips
client hooks. Transport reads can block until their configured deadline; IQ
timers do not interrupt them. The application must bound its overall run time.

## Reply addresses

A reply must match the request ID, its peer and the local bound full/bare JID
when `to` is present. A full peer JID requires that exact resource; a bare
account may reply from one of its resources. Domain-only peers require that
domain without a resource. An omitted peer addresses the local server; replies
may omit `from` or identify that server or the local account. Explicit empty
addresses are rejected. Foreign, duplicate, unknown-ID and late replies remain
unhandled events and do not complete a pending request.

A server answering on behalf of the local bare account can omit `from`, as
specified by RFC 6120 section 8.1.2.1. Such a reply can complete a request to
that account's bare JID, including personal publishing or storage requests.

Domain comparison uses shared native IDNA preparation, so U-labels and A-labels
compare consistently while XML identities remain Unicode. Localparts and
resources retain their supplied code units; full username/resource preparation
remains pending. The application hook should use the router's completion path
for request results rather than trusting unhandled IQs.
