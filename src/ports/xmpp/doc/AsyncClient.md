# Caller-driven XMPP connections

`XmppClient.Feed` processes caller-owned application bytes, allowing an event
loop to drive the existing TLS, SASL and resource-binding state machine. Each
call consumes at most one XML event and reports its exact byte count. Keep any
remaining bytes for the next call. Call `Start` before supplying input; a
zero-byte feed means no available input. `End` reports transport EOF or failure.

When the client reaches `upgrading`, stop feeding plaintext. Complete the TLS
handshake in the transport, verify the configured service identity and call
`TLSReady`. This restarts the XML stream. The transport's `AuthenticatedFor`
capability is checked before authentication and stream restart. Feed-based and
`Step`-based input driving are exclusive for each client. Client driving and
callbacks remain serialized.

## Linux TCP/TLS transport

`XmppAsyncTCP.OpenAddress` starts a nonblocking connection to a supplied
`Sockets.Address`. The service domain is independent of the dial address and
is normalized through IDNA for XML and certificate verification. The API accepts
an explicit port, STARTTLS/direct-TLS choice and a 1–600,000 ms negotiation deadline.
Hostname resolution and SRV selection remain application integration work.

Create an `XmppClient` using this transport, then drive it through
`transport.Drive(client)`. The driver starts the stream, buffers partial input,
limits each call to one connection/handshake step, one output flush, at most one
application read and eight XML events. It handles STARTTLS and stream restarts.
Do not also call the client's `Start`, `Step`, `Feed` or `TLSReady` methods.

Register `Descriptor` with the event loop using `WantRead` and `WantWrite`.
Also drive the connection periodically and call `Tick` with actual elapsed
milliseconds, including periods without socket readiness. Periodic calls advance
TLS handshake phases and pending TLS control output. The TLS API currently
serializes client handshakes internally. Socket operations remain nonblocking;
cryptographic operations and certificate-store loading run within their step.

Writes enter a 128 KiB queue, with complete admission or failure. Partial writes
retain their remaining bytes. Queue overflow fails the connection. Sent and
cancelled buffers are cleared, and TLS owns the descriptor after handshake
startup. `Cancel` aborts the client, clears output and closes its socket.

An orderly peer closure can leave its XML close acknowledgement queued. Continue
driving until the transport reaches `closed`, even when the client has already
reported closure. Negotiation deadlines also bound this final drain; applications
may cancel immediately when their own shutdown policy requires it.
