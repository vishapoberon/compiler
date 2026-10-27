# Incremental XML element streams

`XMLStream` accepts UTF-8 input in arbitrary byte chunks and reports an opening
stream element, individual complete child elements, and the closing stream
element. It supports protocols such as XMPP, whose outer element remains open
while messages are exchanged. Existing `XMLParser`, builder and writer APIs
retain their signatures and behavior.

## Feeding input

```oberon
stream := XMLStream.New(16384, 1024*1024, 64);
event := stream.Feed(bytes, offset, available, builder, consumed);
INC(offset, consumed);
```

`Feed` returns after **one event**, consuming exactly the reported number of
bytes. Its results are `needInput`, `opened`, `stanza`, `closed`, and `failed`.
`needInput` consumes the supplied slice and retains an incomplete frame.
An empty slice makes no progress. A closed or failed stream consumes no further
input. The caller must handle those events instead of retrying the same slice.

When bytes remain after an event, handle that event before calling `Feed` again.
This is essential when a TLS or authentication result changes the interpretation
of the remaining bytes. After the protocol has accepted a restart, call
`Restart()` before feeding the new opening stream. Restart succeeds only at a
frame boundary on a stream without an error. Transport EOF is separate:
`Finish()` succeeds only after an explicit closing stream tag.

## Parsing and namespace context

Namespace names are validated as URI references and retain their literal
spelling after URI character escaping. Relative namespace names, including
the legacy `vcard-temp` name, are accepted in memory-backed streams without
a document base URI. A synthetic hierarchical base is used only for syntax
validation; no URI is retrieved or substituted into the namespace name.

The adapter buffers one bounded stanza. It frames markup across chunk boundaries,
then checks the complete frame with the existing `XMLParser`, UTF-8 codec and
namespace builder. Each stanza is parsed inside the saved opening element and
its matching synthetic closing tag. Namespace declarations on the stream root
are therefore available to every stanza; declarations on one stanza do not leak
into later stanzas.

The supplied builder receives a complete synthetic document for each event,
including the stream root. On a stanza event, the stanza is the root's one child
element. The opening event produces a document containing only the stream root.
The closing event checks the received closing tag against that root. Builder
locations refer to the synthetic document, rather than a cumulative socket
offset. Stream-level attributes such as `xml:lang` remain available on its root.

Callbacks may precede a syntax error, following the existing parser convention.
Build a temporary result and publish it only when `Feed` returns a successful
event. `stream.error` holds the diagnostic on failure; `stream.parser.errList`
contains parser diagnostics when a parser was constructed. The XMPP adapter
follows this commit-after-validation rule.

## Input and resource policy

The stream profile accepts XML 1.0 with UTF-8 encoding. It rejects DTDs, comments,
processing instructions other than the initial XML declaration, and standalone
declarations. CDATA sections and predefined/numeric references are supported.
The parser always has external reference access disabled.

Constructor limits bound the retained opening header, each stanza, and child
element nesting. Supported maxima are 64 KiB for the header, 16 MiB per stanza,
and 127 child levels. Defaults are 16 KiB, 1 MiB and 64 levels. A fresh
`XMLLimits` budget applies to each synthetic document; traffic over the lifetime
of a connection does not exhaust a single document budget. Inter-stanza
keepalive whitespace is consumed without retaining a growing buffer.

Application builders, transport queues, write buffering, deadlines and stanza
semantic checks require their own bounds. Receiving data is passive: the API
never opens a socket or performs TLS negotiation. Broader adversarial XML review
remains pending; the library's trusted-input status still applies.

`TestStream` covers byte-chunk boundaries, namespace inheritance and isolation,
references, quoted delimiters, CDATA, exact event consumption, restarts, EOF,
restricted markup, resource limits and deterministic malformed-input mutations.

## Validation status

The stream tests and the full XML/shared regression suites pass on x86-64 Linux
with GCC/C23, Clang/C23, TCC and Clang ASan/UBSan. The
stream program adds 232 chunk-size runs and 486 malformed-input mutations.
Lifetime checks consume 256 KiB of keepalive whitespace and 256 stanzas with
an 8-byte stanza limit, exercising per-frame rather than connection-wide bounds.
The existing 2,687 conformance/output, 53 hostile-input and 2,655 mutation cases
also pass. The VOC modular build passes the stream consumer and bundled
ABI/load checks. Native Windows validation remains pending.
