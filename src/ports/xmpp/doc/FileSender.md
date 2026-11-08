# sending negotiated files

`XmppFileSender` sends a file offer, validates the exact peer's selection,
positions a checked source reader and sends the agreed range over acknowledged
IBB. It uses the existing client's IQ router and IBB manager.

## setup and source ownership

Create a sender with `FileSender.New(engine, hook, timeoutMS)`. The engine can
be an `XmppIbbTransfer.Manager`, or `receiver.Bytestreams()` when sharing a client
with `XmppFileReceiver`. The sender uses per-transfer IBB callbacks without
replacing incoming consent callbacks.

After the client is online, construct a `XmppStreamInit.Offer` with methods
`{StreamInit.ibb}` and call:

```oberon
session := sender.Offer(peer, offer, reader, blockSize, error);
```

The peer must be explicit. Byte/block sizes must fit the engine's configured
limits. At most 16 outgoing offers/transfers are retained per sender; an active
peer/SID cannot be replaced. Authoritative metadata is copied before sending.
Editing the caller's offer or the session's presentation copy does not change
the permitted range or SID.

Keep the reader exclusive and the source immutable until completion. No data
is read before offer acceptance and the IBB open acknowledgement. Channels
remain caller-owned and are never closed by the sender.

## selected ranges

The reader's position at offering time is the logical start of the advertised
file. For a positionable reader, the sender captures that origin and seeks to
`origin + selected offset` after acceptance. An unrelated source prefix is not
included in the transfer. Position/range arithmetic is checked before offering.

Advertising range support requires a positionable reader. A sequential reader
can offer a complete file without range support, sending from its current
position. Seek failures, closed/error channels and short reads terminate the
session. Reads cannot extend beyond the selected length. An empty range sends
open and close without data.

The sender advertises only IBB while its native SOCKS5 adapter remains pending.
The lower-level `XmppStreamInit` API represents both transports. Invalid,
mismatched or unoffered selections cannot start IBB.

## completion and cancellation

`Hook.Progress(sender, session, cancel)` reports acknowledged bytes in the
selected range. Set `cancel` to request cancellation. `Hook.Done(sender, session)`
runs once after releasing the sender slot and source reference. Inspect
`status`, `offset`, `length` and `bytes`; `done` requires the data and close
acknowledgements.

A session can fail synchronously inside `Offer`: implement `Done` and inspect
the returned status even when an object is returned. Immediate invalid,
offline or capacity requests return `NIL`.

`sender.Cancel(session)` cancels a live offer/transfer. Pending local IQ
correlation is removed, and active IBB is closed best-effort. Late acceptance
cannot revive a cancelled offer. There are no automatic retries. The remote
receiver's deadline releases an authorization that never gets an IBB open.

Drive `sender.router.Tick(elapsedMS)` for negotiation and IBB IQ deadlines.
When sharing a receiver, tick that router only once, and also call
`receiver.Tick(elapsedMS)` for incoming consent/open/receive deadlines.

`sender.Stop` cancels its sessions without stopping the shared engine. Before
`client.Abort`, stop the sender, receiver/engine, other tracking hooks and IQ
router explicitly. Normal client error/closure hooks finish pending IQs and
IBB transfers. Rebuild XMPP modules and consumers after interface updates.
