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
| `Core` | Stanza metadata, feature lookup, language inheritance and session hooks. `XmppClient` adds TLS/SASL/resource-binding negotiation; extension dispatch remains pending. |
| `Strings` | UTF-16 JID splitting/joining and structural checks. Native TCP supplies Unicode-domain normalization through shared `IDNA`. ID generation and full username/resource preparation remain pending. |
| `Messenger`, `Presence` | Basic message-body and presence-status construction. Original delivery tracking, receipts, roster state and scheduling remain pending. |
| `Sasl` | Bounded Unicode SASL PLAIN response with explicit opt-in over verified TLS. Original DIGEST-MD5 remains pending; SCRAM is an additional planned mechanism. |
| `Roster`, `Disco`, `Ping`, `Version`, `Register`, `Muc` | Pending extension behavior and tests. |
| `Ibb`, `ByteStreams`, `StreamInit`, `Files` | Pending file-transfer state, sockets and file adapters. |
| `DateTime`, `Stuff` | Pending portable helpers and scheduling/collection replacements. |
| `Session`, `Bus`, `StdBus`, `ObxBus` | `XmppClient` supplies the authenticated client lifecycle. Original session management, extension dispatch and bus/service integration remain pending. |
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
| `ListsLinear`, `ListsMap`, `ListsIterable` | Ordered stanza content is implemented in `XmppItems`; extension registries/maps remain pending. |
| `ypkEncBase64`, `ypkCryptMd5`, `ypkMathRandom`, `ypkEncPunycode` | PLAIN encodes its binary UTF-8 response directly; native TLS supplies handshake randomness. Shared `IDNA`/libidn2 normalizes internationalized domains. Original DIGEST-MD5 and full username/resource preparation remain pending. |
| `ypkSysActions`, `ypkProxyCmds`, `ypkCommSrv`, `AbfBus` | Pending application scheduling, proxy and bus adapters. |
| `Kernel`, `Meta`, `SYSTEM` | Pending module/extension dispatch review; use explicit native registration where needed. |
| `Files`, `Dates`, `Math` | Pending portable file-transfer and time helpers; reuse VOC interfaces. |
| `Dialog`, `Log`, `StdLog`, `TextViews`, `TextModels`, `TextMappers`, `Views`, `Ports` | Pending application-facing logging and user interfaces. |

The client now connects through VOC networking/TLS, requires certificate
verification, restarts streams after TLS/SASL, binds a resource and delivers
online stanzas. Offline and local-server tests cover that lifecycle, including
Unicode service domains and A-label certificate identities. Live-server coverage
includes a UTF-8 (Armenian language) account and domain, verified STARTTLS, PLAIN login,
Unicode resource binding, a Unicode self-message round trip and orderly closure.
The next stages adapt the original extension/IQ dispatch, roster/discovery/
presence behavior, scheduling and remaining authentication functionality.
Broader interoperability, full username/resource preparation and adversarial
security review remain pending.
