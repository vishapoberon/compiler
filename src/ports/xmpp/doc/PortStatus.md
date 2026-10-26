# XMPP adaptation inventory

The supplied Component Pascal subsystem implements XMPP sessions, messages,
presence, extensions and a BlackBox user interface. The preserved revision is
`a2cde5435bea63de16239c2c31e399ad0fd43ad2`; its original modules and resources
are in `upstream/`, with SHA-256 checks in `upstream/manifest.json`.

## Native foundation

The VOC modules use Oberon-2, explicit Component Pascal width mappings and the
shared ooc Unicode code-unit type. Native XML trees retain expanded names,
namespaced attributes and mixed-content ordering. `XMLStream` frames byte-fed
input, and ooc-xml validates complete stanzas with stream-level namespace scope.
Session hooks deliver stream headers, features and IQ/message/presence stanzas.
The connection layer accepts caller-supplied input and a `Channel.Writer`,
including checked stream-header, stanza and closing-tag output.

The portable interfaces are defined by the new `.Mod` sources and package
README. The supplied Component Pascal modules remain available for adapting
their remaining session actions and extension behavior.

| Original module | Current adaptation |
| --- | --- |
| `Const` | Protocol string values retained; identifiers use VOC camel case. |
| `XmlStream`, `XmlGen`, `Connections` | Native receive framing, stanza trees, bounded output, owner callbacks, counters and stream restarts. `XmppTCP` supplies synchronous TCP/TLS. |
| `Core` | Stanza metadata, feature lookup, language inheritance and session hooks. `XmppClient` adds TLS/SASL/resource-binding negotiation; `XmppIQ` supplies explicit IQ handler registration and bounded request correlation. |
| `Strings` | UTF-16 JID splitting/joining and structural checks. Native TCP supplies Unicode-domain normalization through shared `IDNA`. ID generation and full username/resource preparation remain pending. |
| `Messenger` | Basic message-body construction. Delivery tracking and receipts remain pending. |
| `Presence` | Bounded available/unavailable and subscription builders, multilingual status decoding and explicit-contact per-resource tracking with disconnect cleanup. Automatic subscription policy, MUC-specific presence and scheduling remain application work. |
| `Sasl` | Bounded Unicode SASL PLAIN response with explicit opt-in over verified TLS. Original DIGEST-MD5 remains pending; SCRAM is an additional planned mechanism. |
| `Disco`, `Ping`, `Version` | Bounded IQ routing, XEP-0199 ping, opt-in XEP-0092 metadata and XEP-0030 info/items queries and configured replies. Discovery exposes the checked reply tree; dynamic discovery nodes remain application-owned. |
| `Roster` | Bounded full retrieval, contact edits/removals and sender-checked pushes with atomic snapshots and stale-fetch protection. Roster versioning and presence-subscription automation remain pending. |
| `Register`, `Muc` | Pending extension behavior and tests. |
| `Ibb`, `ByteStreams`, `StreamInit`, `Files` | Pending file-transfer state, sockets and file adapters. |
| `DateTime`, `Stuff` | Pending portable helpers and scheduling/collection replacements. |
| `Session`, `Bus`, `StdBus`, `ObxBus` | `XmppClient` supplies the authenticated client lifecycle. Original session management, remaining extension lifecycle and bus/service integration remain pending. |
| `Console`, `ConsoleForm`, `Cmds`, `Obx`, `Basic`, `Extended` | Preserved original interfaces, commands and examples; native frontends remain pending. |

`XmppTypes` and `XmppItems` provide the new width and tree interfaces used by
these native modules. All 31 original module pairs are retained as both `.txt`
exports and native `.odc` documents.

## Dependency boundaries

| Supplied imports | Native integration |
| --- | --- |
| `XmlcoreScanner`, `XmlcoreParser`, `XmlcoreDom`, `XmlcoreItems`, `XmlcoreFormatters`, `XmlcoreStrings` | ooc-xml plus `XmppItems`, `XmppXmlStream` and `XmppXmlGen`. |
| `StringsDyn`, `StringsUtf`, BlackBox `Strings` | Shared `oocUnicode`, `LongStrings`, XML codecs and dynamic UTF-16 arrays in the adapted foundation. |
| `CommStreams`, `Services` | `XmppWire` transport and `XmppTCP` synchronous socket/TLS driver; event-loop scheduling remains application-owned. |
| `ListsLinear`, `ListsMap`, `ListsIterable` | Ordered stanza content in `XmppItems`; fixed-capacity IQ handlers and pending requests in `XmppIQ`. Remaining extension collections are pending. |
| `ypkEncBase64`, `ypkCryptMd5`, `ypkMathRandom`, `ypkEncPunycode` | PLAIN encodes its binary UTF-8 response directly; native TLS supplies handshake randomness. Native `IDNA` prepares internationalized domains with UTS #46, NFC and IDNA2008 checks. Original DIGEST-MD5 and full username/resource preparation remain pending. |
| `ypkSysActions`, `ypkProxyCmds`, `ypkCommSrv`, `AbfBus` | Pending application scheduling, proxy and bus adapters. |
| `Kernel`, `Meta`, `SYSTEM` | Pending module/extension dispatch review; use explicit native registration where needed. |
| `Files`, `Dates`, `Math` | Pending portable file-transfer and time helpers; reuse VOC interfaces. |
| `Dialog`, `Log`, `StdLog`, `TextViews`, `TextModels`, `TextMappers`, `Views`, `Ports` | Pending application-facing logging and user interfaces. |

The client now connects through VOC networking/TLS, requires certificate
verification, restarts streams after TLS/SASL, binds a resource and delivers
online stanzas. Offline and local-server tests cover that lifecycle, including
Unicode service domains and A-label certificate identities. Live-server coverage
includes a UTF-8 (Armenian language) account and domain, verified STARTTLS,
PLAIN login, Unicode resource binding, a Unicode self-message round trip and
orderly closure.
The IQ layer now handles ping, version and discovery with address-checked
responses, cancellation and caller-driven deadlines; see [IQ extensions](IQ.md).
Roster and reusable PubSub/PEP operations now have offline and local TLS
coverage; see [rosters and PEP](RosterPEP.md). Presence builders and explicit-contact
resource tracking have the same coverage; see [presence](Presence.md). The next stages adapt
remaining extension behavior, scheduling and authentication functionality.
Broader interoperability, full username/resource preparation and adversarial
security review remain pending.
