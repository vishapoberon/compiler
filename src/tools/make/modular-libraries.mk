# Bundled libraries in import order. oocC has one source per C data model;
# ooc2/oocwrapperlibc.Mod is a duplicate of the ooc module, not a second library.
MODULAR_V4 = Args Console Printer Sets
MODULAR_OOC = oocLowReal oocLowLReal oocRealMath oocOakMath oocLRealMath \
 oocLongInts oocComplexMath oocLComplexMath oocAscii oocCharClass oocStrings \
 oocConvTypes oocLRealConv oocLRealStr oocRealConv oocRealStr oocIntConv \
 oocIntStr oocMsg oocSysClock oocTime oocChannel oocProgramArgsHost \
 oocProgramArgs oocStrings2 oocRts oocFilenames oocTextRider oocBinaryRider \
 oocJulianDay oocFilesHost oocFiles oocwrapperlibc oocOakStrings oocRandomNumbers
MODULAR_OOC2 = ooc2Strings ooc2Ascii ooc2CharClass ooc2ConvTypes ooc2IntConv \
 ooc2IntStr ooc2Real0 ooc2LRealConv
MODULAR_ULM = ulmTypes ulmObjects ulmPriorities ulmDisciplines ulmServices \
 ulmSys ulmSYSTEM ulmEvents ulmProcess ulmResources ulmForwarders \
 ulmRelatedEvents ulmStreamsHost ulmStreams ulmTerminals ulmStrings \
 ulmSysTypes ulmTexts ulmSysConversions ulmErrors ulmSysErrors ulmSysStat \
 ulmASCII ulmSets ulmIO ulmAssertions ulmIndirectDisciplines ulmStreamDisciplines \
 ulmIEEE ulmMC68881 ulmReals ulmPrint ulmWrite ulmConstStrings ulmPlotters \
 ulmSysIO ulmUnixFiles ulmUnixTerminals ulmLoader ulmNetIO ulmPersistentObjects \
 ulmPersistentDisciplines ulmOperations ulmScales ulmTimes ulmClocks ulmTimers \
 ulmConditions ulmStreamConditions ulmTimeConditions ulmCiphers ulmCipherOps \
 ulmBlockCiphers ulmAsymmetricCiphers ulmConclusions ulmRandomGenerators \
 ulmTCrypt ulmIntOperations
MODULAR_POW = powStrings
MODULAR_MISC = crt Listen MersenneTwister MultiArrays MultiArrayRiders
MODULAR_S3 = ethBTrees ethMD5 ethSets ethZlib ethZlibBuffers ethZlibInflate \
 ethZlibDeflate ethZlibReaders ethZlibWriters ethZip ethRandomNumbers \
 ethGZReaders ethGZWriters ethUnicode ethDates ethReals ethStrings ethBase64
MODULAR_X11 = oocX11 oocXutil oocXYplane
