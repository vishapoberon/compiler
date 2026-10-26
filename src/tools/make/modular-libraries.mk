# Bundled libraries in import order. C has one source per C data model.
# Conventional and modular builds share the unified oo2c module lists.
MODULAR_CLI = Args Console
MODULAR_TERMINAL = termios UnixTermios LineEditor
MODULAR_V4 = Printer Sets
MODULAR_PUNYCODE = Punycode IDNAMapping IDNAData UnicodeNFC IDNA
MODULAR_OOC = LowReal LowLReal RealMath OakMath LRealMath \
 LongInts ComplexMath LComplexMath Ascii CharClass oocStrings \
 ConvTypes LRealConv LRealStr RealConv RealStr IntConv \
 IntStr oocUnicode LongStrings Msg SysClock Time Channel IOMemory ProgramArgsHost \
 ProgramArgs Strings2 Rts Filenames TextRider BinaryRider \
 JulianDay FilesHost oocFiles wrapperlibc OakStrings oocRandomNumbers \
  Real0 oo2c2LRealConv URICharClass URIString URIError URI \
 URIAuthorityUnparsed URIAuthorityRegistryBased URIAuthorityServerBased \
 URIQueryUnparsed URIFragmentUnparsed URISchemeHierarchical URISchemeOpaque \
 URISchemeCurrentDoc URIParser URISchemeFile URISchemeMemory URISchemeMailTo
MODULAR_XML = XMLUnicodeCodec XMLUnicodeCodecASCII XMLUnicodeCodecLatin1 \
 XMLUnicodeCodecUTF8 XMLUnicodeCodecUTF16 XMLUnicodeCodecImportAll \
 XMLLimits XMLInputBuffer XMLUnicodeBuffer XMLDTD XMLEntityResolver \
 XMLError XMLLocator XMLBuilder XMLParser XMLBuilderNamespaces XMLStream XMLRegexp \
 XMLBuilderValidation XMLWriter XMLBuilderCanonical XMLBuilderParserProtocol \
 XMLBasicElement XMLBasicDataType XMLBasicParser
MODULAR_XMPP = XmppTypes XmppConst XmppItems XmppXmlStream XmppXmlGen \
 XmppConnections XmppStrings XmppCore XmppMessenger XmppPresence \
 XmppWire XmppSasl XmppClient XmppIQ XmppPing XmppVersion XmppDisco XmppRoster XmppPubSub
MODULAR_XMPP_PUBLISH = XmppPEP XmppPublishConfig
MODULAR_ULM = Types Objects Priorities Disciplines Services \
 Sys ulmSYSTEM Events Process Resources Forwarders \
 RelatedEvents StreamsHost Streams Terminals ulmStrings \
 SysTypes ulmTexts SysConversions Errors SysErrors SysStat \
 ulmASCII ulmSets IO Assertions IndirectDisciplines StreamDisciplines \
 IEEE MC68881 ulmReals Print Write ConstStrings Plotters \
 SysIO UnixFiles UnixTerminals Loader NetIO PersistentObjects \
 PersistentDisciplines Operations Scales Times Clocks Timers \
 Conditions StreamConditions TimeConditions Ciphers CipherOps \
 BlockCiphers AsymmetricCiphers Conclusions RandomGenerators \
 TCrypt IntOperations
MODULAR_POW = powStrings
MODULAR_MISC = crt Listen MersenneTwister MultiArrays MultiArrayRiders
MODULAR_ARCHIVE = Zlib ZlibBuffers ZlibInflate ZlibDeflate ZlibReaders \
 ZlibWriters Zip GZReaders GZWriters
MODULAR_S3 = BTrees MD5 ethSets Zlib ZlibBuffers ZlibInflate \
 ZlibDeflate ZlibReaders ZlibWriters Zip RandomNumbers \
 GZReaders GZWriters Unicode Dates ethReals ethStrings Base64 BIT TwoComplement DES
MODULAR_X11 = oocX11 oocXutil oocXYplane
MODULAR_CAIRO = Cairo
MODULAR_RAYLIB = RaylibNative Raylib
# Independently syncable portable ports, in import order under src/ports.
MODULAR_PORTABLE = norayr/base64/StringBase64 norayr/bdStrings/bdStrings \
 norayr/strutils/strTypes norayr/strutils/strUtils norayr/lists/List norayr/lists/StringList \
 norayr/opts/optsosv norayr/opts/opts norayr/toml/TOML sts-q/ssqJson/Json

# Unix libc-backed ports, with no extra native-library dependencies.
MODULAR_UNIX_PORTS = sts-q/oberon/Kbd

# Linux-only native boundary and its clients. Do not compile these on FreeBSD,
# macOS, native Windows or a Windows cross-target hosted on Linux.
MODULAR_INTERNET = norayr/Internet/unixNet norayr/Internet/Kernel norayr/Internet/Sockets \
 norayr/Internet/DNS norayr/Internet/Internet norayr/Internet/netForker \
 norayr/Internet/server norayr/Internet/NetSystem
MODULAR_HTTP = norayr/http/hexIntStr norayr/http/http
MODULAR_TLS = norayr/tls/TLSBytes norayr/tls/TLSSHA256 norayr/tls/TLSHKDF \
 norayr/tls/TLSSHA512 norayr/tls/TLSNum norayr/tls/TLSECDSA norayr/tls/TLSX25519 \
 norayr/tls/TLSAESGCM norayr/tls/TLS13Records norayr/tls/TLS13Handshake \
 norayr/tls/TLS13Keys norayr/tls/TLS13Finished norayr/tls/TLSBase64 \
 norayr/tls/TLSPEM norayr/tls/TLS13Certs norayr/tls/TLSASN1 norayr/tls/TLSX509 \
 norayr/tls/TLSX509Validity norayr/tls/TLSRSA norayr/tls/TLSX509Names \
 norayr/tls/TLSX509Ext norayr/tls/TLSSig norayr/tls/TLSNameConstraints \
 norayr/tls/TLSX509Chain norayr/tls/TLSCABundle norayr/tls/TLS13EncHandshake \
 norayr/tls/TLS13ClientFinished norayr/tls/TLS13Application norayr/tls/TLS13Random \
 norayr/tls/TLSNow norayr/tls/TLSIdentity norayr/tls/TLSCertGen \
 norayr/tls/TLS13Live norayr/tls/TLS13Server norayr/tls/httpsPure
MODULAR_HTTPS = norayr/https/https
MODULAR_GEMINI = norayr/netHost/NetHost norayr/gemini/Gemini0 norayr/gemini/Gemtext0
MODULAR_LINUX_BASE_PORTS = norayr/pipes/pipes norayr/xattr/xattr
MODULAR_LINUX_PORTS = $(MODULAR_INTERNET) $(MODULAR_HTTP) $(MODULAR_TLS) $(MODULAR_HTTPS) $(MODULAR_GEMINI)
