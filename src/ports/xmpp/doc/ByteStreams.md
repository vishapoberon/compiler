# SOCKS5 bytestream foundations

`XmppByteStreams` builds and reads XEP-0065 TCP host offers and selected-host
results. An offer contains a bounded SID and one to eight hosts, each with a
JID, address and port. DNS names use shared IDNA normalization; duplicate JIDs
and normalized address/port pairs are rejected. Full IP-literal validation is
performed by the socket adapter. An omitted wire port defaults to 1080.

`NewHost`, `NewOffer` and `offer.Add` construct an offer. `Build` and `ReadOffer`
convert its query payload. `Select` and `ReadUsed` bind selection to an offered
host and check an optional response SID. `Query` uses exact-peer IQ correlation;
`Selected` returns a host only for a matching successful response. The caller
must authorize the peer, SID and endpoints before connecting. Explicit `dstaddr`
overrides and UDP offers require policies outside this interface and are rejected.

`XmppSocks5.Destination` computes the XEP-0065 SHA-1 identifier from UTF-8
`SID + requester JID + target JID`. Supply the actual prepared IQ identities,
including bare JIDs where applicable. The supplied spelling is preserved when
hashing; full username/resource preparation remains caller-owned. This SHA-1
value identifies the stream and does not authenticate a peer.

`XmppSocks5.New` creates an incremental no-authentication client handshake.
`Output`/`Sent` handle partial writes; `Needed`/`Feed` handle fragmented replies.
The reply must echo the destination domain hash and zero port. `Feed` consumes
only handshake bytes, leaving coalesced payload to its caller. `End` rejects a
truncated negotiation.

## Linux TCP adapter

`XmppSocks5TCP.OpenAddress` connects to an approved numeric address without DNS.
`Open` accepts a numeric literal or an IDNA hostname; hostname resolution is
synchronous and precedes caller-driven deadline accounting. Resolved addresses
are tried in order after connection failures. A stalled connection uses the
remaining overall deadline rather than a separate per-address deadline.

Drive `Step` on readiness indicated by `Descriptor`, `WantRead` and `WantWrite`;
each call performs bounded nonblocking work. Call `Tick` with elapsed milliseconds
even when no readiness event arrives. Timeouts are restricted to 1–600,000 ms.
`Cancel` closes an owned socket. On `ready`, `Release` transfers the nonblocking
`Sockets.Socket` to the application exactly once; its queued payload is intact.
The application then owns reads, writes and closure. Failures close the socket
and retain a diagnostic in `error`.

Direct streamhost listening, proxy activation and integration with accepted
file offers remain pending. File sender/receiver orchestration currently uses
IBB; these foundations alone do not establish a complete SOCKS5 file transfer.
