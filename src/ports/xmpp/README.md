# XMPP for VOC

An Oberon-2 XMPP library using ooc-xml for XML streams and VOC's TCP/TLS modules
for connections. It handles Unicode JIDs and messages, STARTTLS or direct TLS,
SASL PLAIN authentication, resource binding and incoming/outgoing stanzas.

The port is under development. Login, binding and a Unicode self-message round
trip have been tested against a live server with an Armenian account and domain.
The original extension dispatch, roster, discovery, file transfers, scheduling
and DIGEST-MD5 authentication still need porting. Applications currently drive
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
targets require Linux, libidn2 development files and `pkg-config`; the loopback
tests also need Python 3.13+ and OpenSSL. Output goes into `build/ports/xmpp/2`.
Override `BUILD`, `VOC`, `CC` or `CFLAGS` as needed.

The portable modules are included in VOC's normal Oberon-2 and modular library
builds. `XmppTCP` and the shared `IDNA` binding are built separately by the
network target. Programs linking them need
`LDLIBS="$(pkg-config --libs libidn2)"` when invoking VOC.

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
This version uses libidn2 for domain normalization and validation.

`XmppProbe` reads a password from standard input and can send a test message
to its own bound resource. See [client setup and the probe](doc/Client.md) for
the API, examples, timeouts and credential handling. The XML stream API is
documented in [Streaming.md](../xml/doc/Streaming.md).

## Tests and status

The offline, loopback and shared-TLS tests pass with GCC, Clang, TCC and
ASan/UBSan. See [testing](doc/Testing.md) for coverage and recorded live results,
and [the port inventory](doc/PortStatus.md) for the remaining modules.
Security review is ongoing; use trusted XML during development.

## Sources

The standalone project is [norayr/xmpp](https://github.com/norayr/xmpp), continuing
the VOC port started in 2019. This directory contains its native modules,
tests and the preserved Component Pascal snapshot at revision
`a2cde5435bea63de16239c2c31e399ad0fd43ad2`.

`upstream/` retains all 88 supplied files, including 31 paired `.txt`/`.odc`
modules. The manifest records their sizes and SHA-256 hashes. The `.odc`
documents retain Unicode text that was lost in some text exports. Original
notices are retained; the supplied subsystem has no explicit license grant.
