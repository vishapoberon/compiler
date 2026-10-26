# XMPP tests

Run these commands from the VOC checkout:

```sh
make -C src/ports/xmpp test network-test tls-regression VOC="$PWD/install/bin/voc"
```

The offline tests cover UTF-16 code units, UTF-8 wire encoding, mixed XML
content, namespace scope, stream restarts, partial writes and session hooks.
They include 232 input split sizes, a 40,002-code-unit message and 665
TLS/SASL/binding negotiation checks. The snapshot check verifies all 88
preserved upstream files by size and SHA-256.

In the standalone checkout, `make history-test` restores and verifies the
preserved Mercurial repository and checks the imported Git history. See
[the history record](History.md) for source revisions and the conversion checks.

The IQ tests add 145 checks covering namespace dispatch, all 110 transport split
sizes, Unicode peers, full/bare/domain address matching, spoofed and duplicate
replies, malformed payloads, cancellation, reentrant callbacks, queue limits,
stream closure and synchronous write failure.

Roster and PubSub/PEP tests add 176 checks, including 110 push split sizes,
Unicode contact/group/item data, forged pushes, atomic snapshots, stale fetches,
reentrant completion, cancellation, synchronous failures, contact/group/text
budgets, matched publication results, retrieval limits and trusted-publisher
notification parsing. Payloadless items, retractions, purge/deletion events,
duplicate IDs and shared payload-byte budgets are covered.

Twenty-four Python/OpenSSL loopback cases cover STARTTLS, direct TLS, Unicode
credentials, messages and domains, certificate and protocol-version rejection,
binding failures, stalled reads/handshakes, ping/version/discovery dispatch,
roster retrieval/edits/pushes and PubSub publish/retrieve/retract/notification
round trips. Roster/PEP fixtures use synthetic accounts and local peers;
live interoperability remains pending.
The shared IDNA suite has 38
conversion and rejection cases. The TLS regression target also runs the 36
existing TLS programs, HTTP/TLS loopback tests and 40 Gemini checks.

These pass on x86-64 Linux with GCC/C23, Clang/C23, TCC and Clang ASan/UBSan.
The sanitizer build uses an uninstrumented conservative core runtime, with
`ASAN_OPTIONS=detect_leaks=0:detect_stack_use_after_return=0` and
`UBSAN_OPTIONS=halt_on_error=1`. Shared IDNA and the XMPP module consumers
also pass against a modular VOC image.

Shared-module tests cover XMPP and publisher interfaces and bundled library
ABI/loading. The publisher's 21 payload/configuration checks, 22 file/XML
cases and 19 TLS loopback cases pass both conventionally and with shared modules.

Live-server coverage also includes a UTF-8 (Armenian language) account and domain,
verified STARTTLS, PLAIN authentication, resource binding, an Armenian/supplementary
self-message round trip and clean shutdown.

The XML/shared suites also pass: 14 XML programs, seven shared programs,
114 codec vectors, 77 URI fixtures, 2,687 conformance/output cases, 53 hostile
inputs and 2,655 deterministic mutation checks. XML stream coverage includes
486 additional mutations and lifetime/exact-consumption limits.
