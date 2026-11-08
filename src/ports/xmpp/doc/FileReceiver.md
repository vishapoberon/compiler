# receiving negotiated files

`XmppFileReceiver` connects incoming XEP-0095/0096 offers to the checked IBB
receiver. It holds offers while the application obtains consent and authorizes
only the accepted peer, SID and selected byte count.

## setup

Create the receiver before client negotiation:

```oberon
receiver := FileReceiver.New(applicationHook, fileHook,
                             maximumBytes, maximumBlock, timeoutMS);
IF receiver # NIL THEN
  client := Client.New(transport, receiver.router, domain,
                       username, password, resource, TRUE, error);
END;
```

The receiver owns its IQ router and IBB engine. Other extensions can register
on `receiver.router` before login. Client hooks pass through to
`applicationHook`, which can itself be a presence/MUC tracking chain. File
reception activates only after authenticated readiness.
Rebuild the native XMPP modules and their consumers when updating: the IBB hook
interface now includes completion validation.

The configured byte, block and timeout limits follow `XmppIbbTransfer`.
At most 16 sessions can be queued, waiting for IBB, or receiving. An offer over
the byte limit is rejected before consent. This receiver selects IBB; an offer
advertising only SOCKS5 is rejected while the native SOCKS5 adapter is pending.

## asynchronous consent

Override `Hook.Offered(receiver, session)` to present an offer to the user.
The callback can return without deciding. `session.offer` contains the bounded
file metadata; `peer` and `sid` identify the requesting session. The library
keeps a separate authoritative copy, so editing presentation metadata does not
alter the permitted source, destination session or byte count.

An undecided offer sends no success response and authorizes no IBB open.
Its consent deadline is driven by `receiver.Tick`. The default callback leaves
the offer undecided until that deadline.

After obtaining consent, prepare a checked output writer and call:

```oberon
accepted := receiver.Accept(session, writer, offset, length);
```

For a complete file, use offset zero and the offered size. A partial selection
requires the offer's range capability and must fit inside the advertised file.
Position the writer at the chosen destination offset before calling `Accept`;
the receiver writes at its current position. Writers remain application-owned.

`Accept` validates the writer and range, records a one-use authorization, and
sends the method/range result. It returns false for invalid or stale decisions
or a synchronous send/cancellation failure. `receiver.Reject(session)` rejects
an undecided offer. `receiver.Cancel(session)` cancels any live session.

Use an independently chosen safe destination. Offer names are untrusted display
metadata; the library never turns them into paths, opens files, or publishes
received output automatically. Keep the writer exclusive to this session.

## binding the bytestream

The accepted offer enters `waiting`. An IBB open must match both its canonical
exact peer and original SID. Other resources, unrelated SIDs, unaccepted offers
and expired or previously consumed authorizations are refused. A duplicate
offer cannot replace an existing session or reuse a pending IQ ID with another
SID for the same peer.

On a matching open, the session enters `receiving` and exposes its IBB
`transfer`. That engine checks blocks, Base64, sequence numbers, writes and
flushes. Its byte ceiling is the selected `length`. A close is successful only
if exactly that many bytes arrived; a premature close receives an error rather
than a success acknowledgement. A resume counts only the selected range's
bytes, not any existing prefix of the destination.

## progress and lifecycle

`Hook.Progress(receiver, session, cancel)` runs after a complete checked write.
Set `cancel` to request cancellation. `Hook.Done(receiver, session)` runs once,
after releasing the session slot and output reference. Its status distinguishes
`done`, rejection, cancellation, expiry, protocol/I/O errors, disconnection and
send failure. The `bytes` count records complete writes. Inspect the status
before publishing output; failures can leave a partial destination, which the
application owns and must discard or retain explicitly.
Verify any required advertised checksum before publishing; the native checksum
helper is still being ported.

Drive `receiver.Tick(elapsedMS)` for consent, pending-open and receive-idle
deadlines, and `receiver.router.Tick(elapsedMS)` for outgoing IQ deadlines on
the shared router. They are separate clocks; do not tick an underlying IBB
engine independently. Callback-created approvals get a fresh timeout rather
than inheriting the remainder of the current tick.

Client errors and stream closure release queued offers, unused authorizations
and active transfers. `receiver.Stop` disables reception and releases all live
sessions. Before `client.Abort`, stop the receiver and other trackers, then stop
the IQ router: abort skips lifecycle callbacks. Stop does not close application
writers. Late approval attempts cannot revive a finished session.

The receiver uses the IQ router's `Deferred()` handler token to own asynchronous
replies. Custom handlers using that token must likewise bound their queues,
retain only necessary request metadata, and supply explicit deadlines and
cleanup.
