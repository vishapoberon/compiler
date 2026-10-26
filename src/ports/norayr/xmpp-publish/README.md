# XMPP microblog publisher for VOC

Publishes one UTF-8 message to the account's personal XMPP microblog node
`urn:xmpp:microblog:0` using XEP-0060 and XEP-0277 Atom entries. It uses VOC's
native XMPP client, XML writer, IDNA preparation and verified TLS 1.3 transport.

## Build

From an updated VOC checkout:

```sh
make -C src/examples/network/xmpp-publish
make -C src/examples/network/xmpp-publish test
```

The executable is `build/examples/network/xmpp-publish/2/XmppPublish`. Set
`VOC`, `BUILD`, `CC` or `CFLAGS` to override the compiler and build settings. The network driver
currently requires Linux. Tests need Python 3.13+ and OpenSSL.

VOC also includes this package in `src/ports/norayr/xmpp-publish/`, with a
separate runnable example in `src/examples/network/xmpp-publish/`.

## Configure and publish

The default configuration file is `$HOME/.config/oolng-xmpp.conf`, retaining
the original location. Set `XMPP_CONFIG` to use a different file. Protect a
file containing a password with mode `0600`.

```ini
[account]
jid=user@example.org/voc-publish
password=replace-with-your-password
message=Բարեւ, աշխարհ 😀
allow_plain=yes
tls=starttls
port=5222
timeout_ms=10000
```

Run `build/examples/network/xmpp-publish/2/XmppPublish`. Successful publication prints `Microblog entry
published`; configuration and protocol failures return a nonzero exit status.
No account, message, password or raw stanza is printed.

| Setting | Environment override | Default |
| --- | --- | --- |
| `jid` | `XMPP_JID` | Required account JID; resource defaults to `voc-publish` |
| `password` | `XMPP_PASSWORD` | Required |
| `message` | `XMPP_MESSAGE` | `Hi! Welcome to my blog.` |
| `host` | `XMPP_HOST` | Account's domain; optional separate dial host/IP |
| `port` | `XMPP_PORT` | `5222`; set `5223` when appropriate for direct TLS |
| `allow_plain` | `XMPP_ALLOW_PLAIN` | `no`; explicitly set `yes` to authenticate |
| `tls` | `XMPP_TLS` | `starttls`; also accepts `direct` |
| `timeout_ms` | `XMPP_TIMEOUT_MS` | `10000`; maximum `60000` |

Nonempty environment settings override the file. Sections and whole-line
`#`/`;` comments are accepted. Leading/trailing whitespace is stripped; inline
comments and unknown settings are rejected. A missing default file permits
environment-only setup; a missing explicitly selected file is an error.

Internationalized domains such as `ծոց.հայ` remain Unicode in XML identities;
DNS and TLS use checked A-labels. Certificate verification is always required.
SASL PLAIN requires explicit opt-in and is sent only after verified TLS.
Supply the dial host/port directly when the service uses a different endpoint;
automatic SRV discovery and SCRAM remain pending in the XMPP library.

## Interfaces and limits

- `XmppPEP.Build(domain, text, itemID, utcTimestamp)` returns a detached pubsub
  payload or `NIL`. The caller supplies the item ID and timestamp. It emits
  escaped Atom text content/title, an A-label `tag:` URI, and matching UTC
  publication/update timestamps.
  Construction and acknowledgement checks use the XMPP library's reusable
  `XmppPubSub` operations; retrieval, retraction and notification parsing are
  available through that module.
- `XmppPEP.Accepted(request, itemID)` accepts an empty successful IQ result or
  a successful pubsub result with the expected node and item ID.
- `XmppPublishConfig.Load` reads bounded configuration without publishing.
- `XmppPublisher.Run(config, error)` logs in, publishes to the bound account's
  bare JID, checks its correlated acknowledgement and closes the stream.
  It clears its password copies and the configuration password on return.

Messages are limited to 4,096 UTF-16 code units. Configuration files have a
64 KiB limit and lines a 16 KiB limit; overlong fields fail instead of truncating.
The runner generates a random UUIDv4 for each item, bounds event processing and
checks an overall wall-clock deadline between client steps. A blocked socket
operation can last until its own timeout; DNS/connect use the existing transport
behavior. Clock rollback fails the run. The shared UTC clock currently uses
signed 32-bit Unix seconds, with the existing 2038 limit.

There are no automatic retries: failure after sending can leave publication
outcome uncertain. Applications requiring resumable/idempotent publication
should retain their own item IDs through the payload API. Password wiping is
best effort; environment variables and the configuration file remain owned by
the caller.

## Status and sources

Offline tests check payload construction, Unicode/XML escaping, timestamps,
bounds and configuration precedence. Local TLS peers check acknowledged and
empty results, spoofed/malformed replies, stanza errors, timeouts, input floods,
Unicode accounts/domains and certificate rejection. Live PEP interoperability
has not yet been tested.

On x86-64 Linux, all 21 payload/configuration checks, 22 configuration/XML cases
and 19 publisher loopback cases pass with GCC/C23, Clang/C23, TCC and Clang
ASan/UBSan. The integrated example also passes as a shared-module consumer.

The source project is [norayr/xmpp-publish](https://github.com/norayr/xmpp-publish),
adapted from revision `dd8a9ca481366bfc3f04d5719837dd0a1940fff5`.
`upstream/` preserves all nine files from that revision; the manifest records
their SHA-256 hashes. The source repository supplies no licence text; licensing
confirmation remains necessary. The XMPP library records its own source and
licensing status separately.
