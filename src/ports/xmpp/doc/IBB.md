# in-band bytestream payloads

`XmppIbb` builds and decodes the IQ-based open, data and close payloads used by
the original Component Pascal file-transfer implementation (XEP-0047).

`Open(sid, blockSize)`, `Data(sid, sequence, bytes, start, count)` and `Close(sid)`
return detached `XmppItems.Item` payloads, or `NIL` for invalid arguments.
Binary input uses explicit ranges and can contain any byte, including zero.
The open builder explicitly selects IQ stanzas; the decoder also accepts an
omitted stanza mode, whose protocol default is IQ.

`Read(item, maximumBlock)` returns an `Event`, or `NIL` for malformed or
unsupported payloads. Events expose their kind, SID and, where applicable,
advertised block size, sequence, decoded bytes and length. Only `length` bytes
of the binary result are data; a trailing zero is a convenience, not a delimiter.
The maximum raw block size is 65,535 bytes. The decoder checks data against
`maximumBlock`; an open event reports its advertised size so the caller can
apply acceptance policy before establishing a stream.

SIDs are bounded to 128 UTF-16 units and must be XML NMTOKENs. Sequences range
from 0 to 65,535. `NextSequence` advances and wraps a valid sequence, returning
`-1` for invalid input. Data decoding rejects nested elements, excess text parts,
non-alphabet bytes, missing or misplaced padding and nonzero padding bits.
Base64 whitespace is rejected under XEP-0047's strict alphabet requirement.

`XmppBase64` supplies the shared binary encoder/decoder. Its explicit input
lengths avoid truncating binary data at zero bytes. SASL PLAIN uses the same
encoder, clearing temporary credential buffers after constructing its response.

## transfer lifecycle

`XmppIbbTransfer` manages the original one-way file-transfer workflow over
IQ-based IBB. It supplies explicit receive consent, checked binary I/O,
acknowledged sending, progress callbacks, deadlines and cancellation.
[Stream-initiation payloads](StreamInit.md) negotiate file offers and transport
selection. [`XmppFileReceiver`](FileReceiver.md) binds incoming consent and
selected byte counts to IBB. SOCKS5 bytestreams and the original checksum helper
remain pending.

Create one manager per client, before starting negotiation:

```oberon
manager := Transfers.New(applicationHook, transferHook,
                         maximumBytes, maximumBlock, timeoutMS);
IF manager # NIL THEN
  client := Client.New(transport, manager.router, domain,
                       username, password, resource, TRUE, error);
END;
```

The manager creates its IQ router and registers the three IBB handlers. Register
other extensions on `manager.router` before login. Client events pass through
to `applicationHook`, which can itself be a presence or MUC tracker. Transfers
activate only after authenticated `Ready`; registration readiness is forwarded
without activating file transfers.

The table holds at most 16 simultaneous transfers. Configure a total byte limit
from zero through 1 GiB, a block limit from 1 through 65,535 bytes and a timeout
from 1 through `XmppIQ.maxTimeoutMS` milliseconds. A caller chooses unique SIDs
for its sessions; do not reuse a SID with the same peer on a live connection.

### sending

`manager.Send(peer, sid, reader, length, blockSize, error)` sends exactly `length`
bytes from the current position of a `Channel.Reader`. It returns a `Transfer`,
or `NIL` for an immediate configuration, offline or capacity error. An admitted
transfer can fail synchronously during sending; inspect its status and implement
the completion callback. The reader must have an open base channel and no
pending error. Keep each reader exclusive to its transfer.

No bytes are read before the open acknowledgement. There is at most one pending
IQ per sending transfer. Each data acknowledgement advances `bytes`, calls
`Progress`, and permits the next block. Short reads fail instead of sending
uninitialized bytes or extending the requested range. Empty transfers send only
open and close. A sender reports `done` only after an empty close result.

### receiving

Override `Hook.Incoming(manager, transfer, writer, maximum)`. Its default answer
is refusal. Inspect `transfer.peer`, `sid` and `blockSize`, obtain application
consent, return a checked `Channel.Writer`, and optionally reduce `maximum`
from the manager's total byte limit. Returning false, no usable writer or an
invalid limit rejects the open without writing data. A refusal completes the
offered transfer with `cancelled`.

Active sessions are keyed by both the canonical exact peer and SID. An unrelated
resource cannot supply blocks or close an existing session. A duplicate open
cannot replace its writer. Before writing, the receiver checks the negotiated
block limit, total remaining byte allowance, Base64 and expected sequence. The
sequence starts at zero and wraps after 65,535. A malformed, repeated or
out-of-order block ends the transfer; subsequent blocks cannot be written into
that session. The receiving `length` field is its maximum allowance, not a
declared file length. Applications negotiating file sizes must also verify the
final `bytes` count against their offer.

The receiver acknowledges a data block only after the full write succeeds. It
flushes the output channel on close, checks the flush result and calls
`Hook.Complete(manager, transfer)` before reporting `done`. This defaults to
true; a negotiated file adapter can reject incomplete content before the close
result is sent. Receive completion means the content was flushed; it does not guarantee
the peer received the close acknowledgement. A failed or short write can leave
partial output. The application owns discarding incomplete files and publishing
successful ones.

### progress, deadlines and cleanup

`Hook.Progress(manager, transfer, cancel)` runs after an acknowledged send or a
complete receive write. Setting `cancel` requests cancellation.
`manager.Cancel(transfer)` also cancels an active transfer. `Hook.Done` runs once,
after releasing the transfer slot and its reader/writer references. Completion
callbacks can start another transfer. Channels remain caller-owned and are not
closed by the manager.

Transfer statuses distinguish success, cancellation, deadlines, I/O errors,
protocol errors, peer errors, disconnects and send failures. On failure or
cancellation, a best-effort close is sent when possible; its acknowledgement
is not retained as a pending transfer. There are no automatic retries or
resumptions. Late replies to a best-effort close can reach the application's
unhandled-IQ callback. Exposed `request` references identify the currently pending IQ;
they become `NIL` when the transfer finishes.

Drive both `manager.router.Tick(elapsedMS)` for sender IQ deadlines and
`manager.Tick(elapsedMS)` for receive idle deadlines. Valid receive blocks reset
the idle deadline. These are per-request/idle deadlines, not a total elapsed
transfer deadline. Add an application deadline if needed.

Normal client error and closure hooks stop remaining transfers and forward the
event. `manager.Stop` disables transfers and cancels them without closing the
XMPP client. Before `client.Abort`, call `manager.Stop`, stop other trackers and
call `manager.router.Stop`: abort intentionally skips lifecycle callbacks.
