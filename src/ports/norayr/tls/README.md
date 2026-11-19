# tls

TLS 1.3 (RFC 8446) written in Oberon, for the [voc](https://github.com/vishaps/voc) compiler and
for [polpo](https://github.com/polpo-system/polpo), which uses the same files with adapted
platform imports. It uses only 32 bit integers, so it runs wherever these compilers do, and the
cryptography is its own: no OpenSSL.

## What it does

- **The client:** X25519, or P-256 when the server asks for it with a HelloRetryRequest;
  TLS_AES_128_GCM_SHA256; randomness from `/dev/urandom`.
- **Checking the server:**
  - its certificate chain must lead to a root of `$SSL_CERT_FILE` or
    `/etc/ssl/certs/ca-certificates.crt`. RSA PKCS#1 and RSASSA-PSS, and ECDSA P-256, P-384 and
    P-521 signatures are understood;
  - validity, CA, key usage and name constraints are checked;
  - the certificate must be for the host name or IP address;
  - CertificateVerify and Finished must be right.

  Otherwise the connection is refused with the alert that says why. `ConnectPinned` accepts a
  server by the hash of its key instead, for protocols that trust on first use (Gemini).
- **Client certificates:** when a server asks for one, the client presents an identity
  (`TLS13Live.SetIdentity`) and signs its CertificateVerify, or sends an empty Certificate.
- **After the handshake:** KeyUpdate is followed both ways, and a connection that ends without
  close_notify is reported.
- **The server side** (`TLS13Server`): the same suite and groups, with a HelloRetryRequest when a
  client offers neither key share. The certificate is chosen by the host name the client asks for
  (SNI, `AcceptBy`), so one port can serve several hosts. There are no session tickets.
- **Identities** (`TLSIdentity`): a certificate chain and its key, ECDSA P-256 or RSA (2048 bits
  or more). They're read from PEM (`CERTIFICATE`; `EC PRIVATE KEY`, `RSA PRIVATE KEY` or
  `PRIVATE KEY`) and checked to belong together. They sign with ecdsa_secp256r1_sha256 (RFC 6979
  nonces) or rsa_pss_rsae_sha256 (CRT, each signature checked before it is sent). Servers and
  clients use them alike.
- **New certificates** (`TLSCertGen`): self-signed X.509 v3 with a new P-256 key, for an identity
  (name and mail) or a server (with its host name), written as PEM, with the key as PKCS #8. So
  openssl is not needed to make them.
- **Ed25519** (`TLSEd25519`, `TLSEd25519Keys`): pure RFC 8032 key derivation,
  generation, signing and strict verification, with incremental SHA-512 for
  messages larger than `TLSBytes.Buffer`. See [the API and verification policy](Ed25519.md).
- **Pinned mutual authentication:** resumable client and server handshakes can
  require an exact Ed25519 public-key pin and an initial client certificate.
  `TLSCertGen.Ed25519SelfSigned` creates certificates from existing identity seeds.

The arithmetic is not constant time: the code suits experimental servers and clients rather than
places where an attacker can measure many handshakes.

## Using it

A client:

```oberon
IF TLS13Live.Connect("example.org", "443", s) THEN
  ok := TLS13Live.WriteAppString(s, request);
  WHILE TLS13Live.ReadAppMax(s, buf, LEN(buf) - 1, n) DO ... END;
  TLS13Live.Disconnect(s)
ELSE Out.String(TLS13Live.lastError)
END
```

With a client certificate: `TLSIdentity.Load(cert, key, id)`, then `TLS13Live.SetIdentity(id)`
before connecting. After a connection, `TLS13Live.certPin` is the SHA-256 of the server's
certificate and `TLS13Live.keyPin` that of its key.

### Resumable client I/O

On VOC's Linux model-2 profile, `Begin(host, fd, state)` takes ownership of an
already connected descriptor and makes it nonblocking. Repeated
`PollHandshake(state)` calls return `0` while pending, `1` after verification
and Finished, or `-1` on failure. The caller supplies the overall deadline
and calls `CloseNow` on cancellation. The asynchronous path uses the same
chain, hostname, CertificateVerify and Finished checks as the blocking path.

After verification, `ReadSome(state, bytes, offset, count)` and `WriteSome`
return a positive byte count, `-2` when pending, or `-1` on failure.
`ReadSome` returns zero for close_notify. Retain the same unacknowledged
write span when retrying after `-2`; a positive result acknowledges plaintext
only after its complete encrypted record has been flushed. Writes accept
at most 16384 plaintext bytes at a time. Partial record headers, bodies and
writes are retained across calls. Post-handshake KeyUpdate responses are
queued in order with application records. `FlushOutput` advances pending
output and returns `0`, `1` or `-1` using the handshake status convention.

`UseNonblocking` switches an established blocking client or server session
to the resumable record API. Use `ReadSome`/`WriteSome` thereafter; the
blocking record entry points reject nonblocking states. `CloseNow` closes
immediately and clears keys, including a pending handshake. It aborts rather
than waiting to send close_notify; `Disconnect` has the same prompt behavior
for nonblocking states. Rebuild modules embedding `TLS13Live.State` when
updating this interface.

`WantsWrite(state)` reports queued encrypted output for writable event watches.
`PendingPlaintext(state)` reports buffered application bytes which can be drained
without waiting for another readable descriptor event.

The API is single-threaded. The current certificate-handshake parser has
shared state, so resumable handshakes are serialized; established sessions
can progress independently. Do not change identity/pinning settings during
an active handshake. Blocking client handshakes are refused while a
resumable handshake owns that parser. Certificate verification and CA-file
loading remain synchronous computation and file I/O. These entry points
require VOC's `Sockets` descriptor APIs; this profile has been tested on
Linux, with other platform bindings requiring separate validation.

### Manually pinned Ed25519 peers

Create a self-signed certificate from the persistent identity seed using
`TLSCertGen.Ed25519SelfSigned`, then load it with `TLSIdentity.FromEd25519`.
The peer pin is a `TLSBytes.Buffer` containing exactly 32 raw public-key bytes.
The caller supplies the pin from an independently authenticated source.

For a client, `TLS13Live.BeginEd25519(host, fd, identity, pin, state)` starts the
handshake on a connected descriptor. Drive it with `PollHandshake`; success
sets both `state.identitySent` and `state.peerAuthenticated`. The peer must
request the initial Ed25519 client certificate as well as present its own.

For a server, `TLS13Server.BeginEd25519(fd, identity, pin, pending)` starts a
handshake on an accepted descriptor. `PollEd25519(pending, state)` returns `0`
while pending, `1` on success or `-1` on failure. Supply an initialized, inactive
`TLS13Live.State`; success transfers the authenticated connection into it.
`WantsWrite(pending)` reports pending server output, and `ClosePending` cancels
an unfinished server handshake.

Both entry points take descriptor ownership, including on failure. They capture
the supplied identity and pin for that handshake. The certificate must contain
the pinned Ed25519 key, be self-signed and valid at the current time, and permit
the peer's TLS role when key-usage extensions are present. CertificateVerify and
Finished are checked before authentication succeeds. These strict entry points
do not fall back to CA trust or trust on first use.

Use the resumable application I/O API after success. Enforce an overall deadline
while handshakes are queued as well as while they are active, and close pending
state on cancellation. Client handshakes share the serialized parser described
above; established connections and pending server states progress independently.

A server, on a connection the caller accepted (with a timeout set on it):

```oberon
IF TLS13Server.Load("cert.pem", "key.pem", id) THEN
  ...
  IF TLS13Server.Accept(fd, id, s) THEN   (* s is then a TLS13Live.State, read and written as above *)
    ...
    TLS13Live.Disconnect(s)
  ELSE Out.String(TLS13Server.lastError)
  END
END
```

`TLS13Server.AcceptBy(fd, choose, s)` takes a procedure that gives the certificate for the host
name of the client (`TLS13Server.serverName`), or NIL to refuse it with unrecognized_name.

A new self-signed certificate: `TLSCertGen.SelfSigned(name, mail, dnsName, years, certPEM,
keyPEM)`; pass `""` for the mail or the host name you don't want.

## The modules

| modules | |
| --- | --- |
| `TLSBytes`, `BIT`, `TLSNum` | byte buffers, 32 bit words, big numbers (Montgomery) |
| `TLSSHA256`, `TLSSHA512`, `TLSHKDF` | hashes, HMAC, HKDF |
| `TLSAESGCM`, `TLSX25519`, `TLSECDSA`, `TLSRSA` | AES-128-GCM, X25519, ECDSA and ECDH (P-256/384/521), RSA |
| `TLSEd25519`, `TLSEd25519Keys` | Ed25519 signatures and entropy-backed seed generation |
| `TLSASN1`, `TLSBase64`, `TLSPEM` | DER, Base64, PEM (read and write) |
| `TLSX509`, `TLSX509Ext`, `TLSX509Names`, `TLSX509Validity`, `TLSNameConstraints`, `TLSX509Chain`, `TLSSig`, `TLSCABundle`, `TLSNow` | certificates and their chains |
| `TLS13Handshake`, `TLS13Keys`, `TLS13Records`, `TLS13EncHandshake`, `TLS13Certs`, `TLS13Finished`, `TLS13ClientFinished`, `TLS13Application`, `TLS13Random` | the protocol |
| `TLS13Live` | client connections |
| `TLSIdentity`, `TLSCertGen`, `TLS13Server` | identities, new certificates, the server side |
| `httpsPure` | HTTPS for the http module |

Programs: `tlsConnect host port` (connect and report), `httpsGet host port path [file]`,
`tlsServe cert key port [n]` (a test server), `tlsIdent host port path [cert key]` (a connection
with a client certificate), and `certGen name [mail] [dns]` (print a new certificate and key).

## Building and testing

```sh
make          # the dependencies (strutils, base64, Internet, http) are fetched into deps/
make tests    # the unit tests, against the files in test/certs
make async-tests # fragmented live TLS, resumable records and the blocking API
```

`async-tests` uses the installed VOC dependencies, Python 3 and OpenSSL's
command-line tool for temporary test certificates. It exercises split TLS
headers and bodies, KeyUpdate/new keys, close_notify, HelloRetryRequest,
verified connections and hostname/CA rejection. It compiles the current
`TLS13Live` source into an isolated temporary build.

The optional [Ed25519 interoperability driver](test/ed25519.py) uses Python
`cryptography` and `hashlib` to compare signatures and hashes independently,
including million-byte messages, malformed encodings and entropy-read failures.
See [Ed25519 signatures](Ed25519.md) for the command and security limitations.

The hexadecimal test dumps use `Out.HexDigits(value, width)`. Use a VOC
installation providing that procedure; `Out.Hex` has ETH Oberon's one-argument
interface. The five hexadecimal-dump tests match Polpo's versions at
`c9795fc1`, printing two uppercase digits per byte.

After the import of a module changes, run `make clean` first: voc keeps the import list of an old
symbol file when the interface stays the same, and the link then misses the new module.

The tests in `tools/` start real servers to test against (`testservers.py`, `keyupdate.sh`,
`hrrserver.sh`). For client certificates, `openssl s_server -verify 1 -www` shows what it got.

## In polpo

polpo keeps a copy in `src/lib/tls`, copied with `loksh vocsync.From tls/src/X.Mod ... src/lib/tls`:
the same files, as polpo has `unixNet`, `oocStrings` and `Out` too. Its tests are in
`src/lib/tls/test` (`TLS_TEST_CERTS=src/lib/tls/test/certs loksh TLSTestChain.Run` and so on). The
Gemini clients (dcs, DCS, Pishmish) and servers (agena, cobweb) of polpo are built on it.
