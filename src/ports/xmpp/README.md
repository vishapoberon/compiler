# XMPP for VOC

An Oberon-2 XMPP library using ooc-xml for XML streams and VOC's TCP/TLS modules
for connections. It handles Unicode JIDs and messages, STARTTLS or direct TLS,
SASL PLAIN authentication, resource binding, incoming/outgoing stanzas and
bounded IQ requests, ping, software version, service discovery, rosters and
personal publishing, presence subscriptions and per-resource availability.

The port is under development. Login, binding and a Unicode self-message round
trip have been tested against a live server with a UTF-8 (Armenian language)
account and domain.
File transfers, scheduling and DIGEST-MD5 authentication still need porting.
Roster retrieval/edits/pushes and PubSub/PEP publication, retrieval, retraction
and notifications have offline and local TLS coverage.
Presence construction/decoding and explicit-contact resource tracking have the
same local coverage; subscription approvals remain application decisions.
IQ extensions use explicit registration and bounded request
correlation. Applications drive
the synchronous client with `Start`, `Step`, `Send` and `Close`.

## Build

Use a matching VOC compiler/runtime installation, such as VOC 4.0.2. From the
VOC checkout:

```sh
make -C src/ports/xmpp test VOC="$PWD/install/bin/voc"
make -C src/ports/xmpp network-test tls-regression VOC="$PWD/install/bin/voc"
make -C src/ports/xmpp probe VOC="$PWD/install/bin/voc"
```

The first command builds the portable library and offline tests. The network
targets require Linux; the loopback tests also need Python 3.13+ and OpenSSL.
Output goes into `build/ports/xmpp/2`.
Override `BUILD`, `VOC`, `CC` or `CFLAGS` as needed.

The portable modules are included in VOC's normal Oberon-2 and modular library
builds. `XmppTCP` is built separately by the network target.

## Use

`XmppClient` negotiates a connection over `XmppWire.Transport`. `XmppTCP.Open`
provides the Linux transport; its dial host and service domain are separate.
The service domain is used for certificate verification. PLAIN must be enabled
explicitly and is sent only over verified TLS.

JIDs, element names and message text use shared `oocUnicode.LONGCHAR` UTF-16
code units. Network buffers and domain arguments use UTF-8 bytes. Use
`XmppItems.UTF8` and `UTF8Bytes` to convert between them. Supplementary
characters retain their surrogate pairs. `XmppTypes` records the source
Component Pascal type widths and their VOC representations.

Domains such as `ծոց.հայ` can be passed directly. XML stream identities remain
Unicode; DNS, TLS SNI and certificate matching use the corresponding A-labels.
VOC's native domain-name modules provide non-transitional UTS #46 mapping,
Unicode 16.0 NFC and IDNA2008 validation.

`XmppProbe` reads a password from standard input and can send a test message
to its own bound resource. See [client setup and the probe](doc/Client.md) for
the API, examples, timeouts and credential handling. The XML stream API is
documented in [Streaming.md](../xml/doc/Streaming.md).

See [IQ extensions](doc/IQ.md) for handler setup, reply matching and deadlines.
See [rosters and PEP](doc/RosterPEP.md) for cache updates and personal publishing.
See [presence](doc/Presence.md) for subscriptions, resource selection and cleanup.
The separate [xmpp-publish example](../../examples/network/xmpp-publish/readme.md)
publishes a Unicode PEP/Atom microblog entry with this library.

## Tests and status

The offline, loopback and shared-TLS tests pass with GCC, Clang, TCC and
ASan/UBSan. See [testing](doc/Testing.md) for coverage and recorded live results,
and [the port inventory](doc/PortStatus.md) for the remaining modules.
Security review is ongoing; use trusted XML during development.

## Sources

The standalone project is [norayr/xmpp](https://github.com/norayr/xmpp), continuing
the VOC port started in 2019. The original BlackBox component is by Pyotr
Mikhailovich Kushnir (Пётр Михайлович Кушнир), as recorded on OberonCore's
[component page](https://oberoncore.ru/bbcc/subs/xmpp/start) and in the
[history record](doc/History.md). This directory contains its native modules,
tests and the preserved Component Pascal snapshot at revision
`a2cde5435bea63de16239c2c31e399ad0fd43ad2`.

`upstream/` retains all 88 supplied files, including 31 paired `.txt`/`.odc`
modules. The manifest records their sizes and SHA-256 hashes. The `.odc`
documents retain Unicode text that was lost in some text exports. Original
notices are retained. Some headers refer to `Docu/BB-License`, which is absent
from the recovered history and supplied snapshot; licensing confirmation is
still needed.
