# Vishap Oberon 5.3

Vishap Oberon compiles Oberon-2 programs through a C backend and supplies
libraries and tools for conventional operating systems. Version 5.3 adds
native signing APIs and pinned mutual TLS authentication to its networking
libraries.

## Ed25519 signatures and incremental SHA-512

`TLSEd25519` and `TLSEd25519Keys` provide RFC 8032 key derivation, generation,
signing and strict signature verification. Incremental `TLSSHA512` contexts
support messages larger than `TLSBytes.Buffer`. The implementations are
written in Oberon and do not require OpenSSL at runtime.

See [Ed25519 APIs and verification policy](../src/ports/norayr/tls/Ed25519.md)
for key formats, streaming operations and verification constraints.

## Pinned mutual TLS 1.3

`TLSCertGen.Ed25519SelfSigned` creates a certificate from an existing identity
seed. `TLSIdentity.FromEd25519` supplies that certificate and signing key to
client and server handshakes.

`TLS13Live.BeginEd25519` and `TLS13Server.BeginEd25519` authenticate peers
against exact 32-byte public-key pins. Both peers present an Ed25519
certificate during the initial TLS handshake. Certificate validity, relevant
key usages, self-signatures, CertificateVerify and Finished are checked
before application access is enabled.

These handshakes are resumable. Readiness queries support writable event
watches and draining buffered plaintext. Callers own the overall timeout and
cancellation policy; pending client handshakes share a serialized parser.
See [the TLS library guide](../src/ports/norayr/tls/README.md) for ownership
contracts and the client/server APIs. Rebuild programs which embed TLS state
records when upgrading.

The native cryptography has not been independently security audited, and its
arithmetic is not constant time.

## Additional updates

- TLS certificate-request processing honors advertised signature schemes.
- Handshake buffers are bounded, and CA-bundle caching and Internet timeouts
  are synchronized with their upstream libraries.
- Editor completion and parameter hints handle unfinished declarations.

## Building and upgrading

Build with `make`. Linux model-2 networking includes the new TLS APIs;
`WITH_NETWORK=0` omits the live networking profile. Rebuild dependent Oberon
programs after installing the updated libraries.

Native TLS programs and independent local interoperability checks cover
signatures, certificate policy, client and server authentication, fragmented
I/O, cancellation, queued handshakes and record readiness. Live pinned TLS
validation is on 64-bit Linux; other platform bindings need separate testing.
