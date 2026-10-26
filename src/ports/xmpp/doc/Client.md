# Client negotiation and transport

`XmppClient` provides a synchronous XMPP client lifecycle using the native stanza
and ooc-xml stream interfaces. `XmppWire.Transport` is its byte-channel boundary;
`XmppTCP` implements that boundary with VOC's Linux networking and TLS 1.3 modules.
Applications implement `XmppClient.HookDesc` methods for readiness, received/sent
stanzas, errors and stream closure.

For correlated IQ requests and explicitly registered ping, version and discovery
handlers, place an [IQ router](IQ.md) between the client and application hook.

## Creating a client

The service domain is the account's domain as a UTF-8 byte string. For example,
`ծոց.հայ` is accepted directly. It is separate from the host used to establish
the TCP connection. `XmppTCP` accepts UTF-8 dial hosts, ASCII DNS names and
literal IP addresses.

The transport's `DomainName(domain, canonical)` method supplies the validated,
canonical UTF-8 identity used by `XmppClient`. The base `XmppWire` policy accepts
ASCII DNS names; `XmppTCP` uses VOC's native `IDNA` module for non-transitional
UTS #46 processing, Unicode 16.0 NFC, case mapping and IDNA2008 checks.
ASCII A-label input is accepted and converted to canonical Unicode U-labels.
The host-name profile rejects trailing root dots and address delimiters, checks
canonical A-label round trips and applies RFC 5893 bidi rules across the domain.

XML stream `to` values remain Unicode. Only DNS lookup, TLS SNI and DNS
certificate matching use the corresponding ASCII A-label name. Received stream
identities and bound-JID domains are compared through the same normalization,
so equivalent Unicode and A-label forms match without accepting another domain.

```oberon
transport := XmppTCP.Open(dialHost, port, serviceDomain, directTLS, 5000, error);
(* Check transport and error before continuing. *)
client := XmppClient.New(transport, hook, serviceDomain,
  username^, password^, resource^, TRUE, error);
XmppSasl.Wipe(password);
(* On constructor failure, close transport. Otherwise check client.Start(). *)
```

The final Boolean explicitly enables SASL PLAIN. Credentials and the requested
resource use `XmppTypes.CodeUnit` UTF-16 arrays. `XmppItems.UTF8` converts UTF-8
input to that representation and returns `NIL` for invalid input. Credential
fields must be nonempty and at most 1,024 code units each; the optional resource
has the same code-unit maximum. Full username, password and resource preparation
remains an application responsibility. Supply an empty resource to request server
assignment. `New` copies its input; callers can clear their password array
afterward. Constructor failure leaves transport ownership with the caller.

Use `directTLS = TRUE` for a TLS connection established before the first XML
header. With `FALSE`, the client exchanges a plaintext stream header, requires
an advertised STARTTLS feature, and upgrades the same socket before proceeding.
There is no automatic port discovery; supply the dial host and numeric port.

The shared TLS API `TLS13Live.Start(host, fd, state)` authenticates an already
connected descriptor, taking ownership and closing it on failure. It requires
an inactive state and no retained pre-TLS input. The existing
`TLS13Live.Connect(host, port, state)` API uses the same handshake path.

## Driving the lifecycle

Call `Start()` once, then call `Step()` to consume input. A step processes at
most one XML event, using previously retained bytes before reading again. It can
block for transport input or TLS negotiation. Important read-only fields are:

- `state`: `idle`, `opening`, `features`, `proceeding`, `upgrading`,
  `authenticating`, `binding`, `online`, `closing`, `closed` or `failed`.
- `authenticated`: SASL has completed successfully; resource binding must also
  finish before the client becomes `online`.
- `jid`: the server-assigned full JID, published after successful binding.
- `error`: the diagnostic on a failed client, including transport/parser errors.

`hook.Ready(client, jid)` runs after binding. `Send(stanza, error)` accepts
application stanzas only while online and authenticated for the service domain.
`hook.Received` and `hook.Sent` expose application stanzas; authentication and
binding traffic bypasses these hooks. Stream-level language attributes continue
to supply stanza defaults through `XmppCore`.

Call `Close(error)` while online to send the closing stream tag. Continue
stepping until the server closes its XML stream; in-flight application stanzas
are still delivered while closing. A server-initiated close is answered with the
client's closing tag before transport shutdown. `Abort` closes the transport
immediately and is also safe after failure. The client closes its transport on
negotiation failure or peer stream closure. No automatic reconnection or
credential retry takes place.

## Authentication and restart policy

The transport must report `AuthenticatedFor(serviceDomain)`. `XmppTCP` reports
this only after TLS has verified the certificate chain, DNS identity,
CertificateVerify and Finished. It uses the normal VOC trust store:
`SSL_CERT_FILE`, or the TLS package's default system CA bundle. The transport
performs ordinary CA verification and does not enable key-pinning/TOFU mode.

SASL PLAIN requires both the explicit constructor opt-in and an exact advertised
PLAIN mechanism in the SASL namespace. Its initial response is the binary
sequence `NUL`, UTF-8 username, `NUL`, UTF-8 password, encoded as base64.
Credentials are sent only over TLS authenticated for the service domain.
Failures, unexpected challenges and unsupported mechanisms end the connection.

TLS and SASL success discard the preceding stream's namespace and feature
context. The client checks each new stream version and any advertised `from`
domain. It correlates the binding IQ by its request ID and requires one scalar
full JID in the binding namespace with a local part, the configured domain and
a nonempty resource. Duplicate or malformed binding results fail the session.

Input after a SASL result stays buffered for the restarted XML stream. Bytes
already received after a STARTTLS `proceed` are rejected: a TLS server cannot
send its ServerHello before this client sends ClientHello. This client-side
policy prevents plaintext injection across the upgrade. The underlying
`XMLStream` API continues to report exact consumption for other protocol owners.

`XmppConnections.WritePrivate` suppresses output hooks for protocol credentials
and clears its published byte buffer. The client also clears its retained
password and temporary SASL response. XML serialization/parsing and the
conservative collector can retain temporary copies; these clearing operations
provide best-effort lifetime reduction rather than guaranteed secret erasure.
Applications should apply their own credential/logging policies.

## Resource and platform boundaries

The XML defaults bound headers to 16 KiB, stanzas to 1 MiB, nesting to 64 child
levels and retained trees to 16,384 element/attribute/text events. Negotiation
has additional 256 KiB and 64-event limits. The input queue holds 8 KiB, retains
unconsumed bytes and resets XML budgets for each complete frame.

`XmppTCP.Open` requires a per-operation socket timeout of 1..600,000 ms. DNS and
the initial TCP connect use VOC's existing blocking interfaces; that timeout is
applied after connection establishment. It is not an overall negotiation or
application deadline. The caller must arrange an overall deadline where needed.
Client driving and TLS operations must be serialized; avoid recursive `Step`
calls from hooks. The transport
is currently Linux-specific; the negotiation and byte-fed XML layers are Oberon.

SCRAM, original DIGEST-MD5, SRV discovery, full username/resource preparation,
extension dispatch and broader adversarial testing remain pending. Continue
using the XML package's documented trusted-input development policy.

## Live login probe

`make -C src/ports/xmpp probe VOC="$PWD/install/bin/voc"` builds
`build/ports/xmpp/2/XmppProbe`. It accepts a UTF-8 JID, an explicit dial host
and port, and optional `self-test` mode. The password is read as a UTF-8 line
from standard input. Supply it through a protected pipe or a `getpass` wrapper
to avoid terminal echo and command-line credentials. For example, from the
repository root:

```python
from getpass import getpass
import subprocess

subprocess.run([
    "build/ports/xmpp/2/XmppProbe", "user@example.org",
    "xmpp.example.org", "5222", "self-test",
], input=getpass("XMPP password: ") + "\n", text=True, check=True, timeout=60)
```

The probe uses STARTTLS, verifies the service domain, explicitly enables PLAIN
and requests `/voc-մուտք` when no resource is supplied. Self-test mode sends
presence and one Armenian/supplementary message to its own bound resource,
then waits for its return and closes the stream. The subprocess timeout supplies
an overall deadline in addition to the transport's ten-second operation timeout.
Only state transitions, the bound JID, result messages and errors are printed.

## Regression commands

From the VOC repository root:

```sh
make -C src/ports/xmpp test network-test tls-regression VOC="$PWD/install/bin/voc"
```

From the standalone XMPP checkout, use `make test network-test tls-regression`
with `VOC` and `VOCSRC` set for the matching VOC installation and sources.
The probe is built by `make probe` and placed in `build/2/XmppProbe`.

The offline client suite fragments complete negotiations, checks invalid state
transitions, mechanism policy, identity mismatches, binding correlation and
negotiation exhaustion. The Python/OpenSSL loopback peer independently decodes
UTF-8 SASL credentials, observes stream restarts, checks resource requests,
exchanges Armenian/supplementary messages and tests certificate, TLS-version,
authentication and binding failures, plus stalled read/handshake timeouts.
It also checks shared TLS failure diagnostics and identity-state reset after
both ordinary connection failures and invalid-descriptor upgrades.
It requires Python 3.13+ and OpenSSL.
All network fixtures use `127.0.0.1`; generated certificates and keys stay in
the selected build directory.
