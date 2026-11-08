# file offers and transport selection

`XmppStreamInit` supplies the file-offer and transport-selection payloads from
the original XEP-0095/0096 workflow. Offers describe a file and advertise IBB,
SOCKS5 bytestreams, or both. A result chooses one offered transport and can
request a permitted file range.

## constructing and decoding offers

`NewOffer(sid, name, size, methods)` initializes an offer with empty description,
hash and date, `application/octet-stream` MIME metadata, and no range support.
Use `{StreamInit.ibb}`, `{StreamInit.socks5}` or both. Invalid arguments return
`NIL`. Fields can be edited before calling `Build(offer)`, which validates them
and returns a detached `si` element.

Offers bound size to 1 GiB, SID to the IBB-compatible 128-unit XML NMTOKEN
profile, name to 1,024 UTF-16 units, description to 4,096, MIME metadata to 128
and date to 64. An optional hash must have the 32-hex-digit MD5 shape used by
the original subsystem. Hash values and dates are metadata: this module does
not compute checksums or interpret timestamps.

`ReadOffer(payload)` returns a validated offer or `NIL`. It checks namespaces,
the file-transfer profile, a required size, duplicate metadata and the bounded
`stream-method` form. Unknown transport options can coexist with supported
ones, within the option bound; an offer with no supported transport fails.
Advertising `range` adds an empty range capability while retaining the full
file size. Missing MIME metadata defaults to `application/octet-stream`.

File names are untrusted descriptive metadata. The application must choose a
safe destination independently; receiving an offer never creates or opens a
file.

## sending an offer

[`XmppFileSender`](FileSender.md) connects this negotiation to a checked source
reader and acknowledged IBB sending, including selected resume ranges.

`Query(router, peer, offer, timeoutMS, action, error)` sends a checked offer
through exact-peer IQ correlation. The peer must be explicit. In the completion
callback, `ReadSelection(request)` validates the reply against the original
outgoing payload, including its offered methods and range capability. It returns
a `Selection` containing `sid`, `method`, `offset` and `length`, or `NIL` for an
error, malformed result, unexpected sender or unoffered selection. Request
deadlines, cancellation and transport errors use the IQ router's normal APIs.

After a successful IBB selection, position a checked reader at `offset` and
call `XmppIbbTransfer.Manager.Send` with the agreed peer, SID and selected
`length`. Keep the source immutable between offering and sending. A SOCKS5
selection describes the negotiated method; its native socket adapter is still
pending.

## answering an offer

An application IQ handler can call `ReadOffer`, obtain explicit user consent,
and build `Accept(offer, method, offset, length)`. Use the resulting payload in
`XmppIQ.Response`. The builder requires exactly one offered method and a range
inside the offered file. A partial selection requires advertised range support;
accepting the whole file omits the optional file/range result.

`ReadAccept(payload, offer)` performs the same payload validation independently
of IQ correlation. Its caller owns sender and request matching. Optional
response SID/profile attributes must match the offer. An omitted range selects
the entire file; omitted range length selects the remaining bytes after offset.

[`XmppFileReceiver`](FileReceiver.md) supplies incoming-offer dispatch,
asynchronous consent, deadlines and accepted-offer/IBB binding. It enforces the
selected byte count before acknowledging completion. File positioning and
publication policy remain application-owned. Applications using the lower-level
IBB manager directly must make the same connection between consent and the exact
peer, SID, size and chosen destination.
