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

`TestXmppIbb` adds 671 binary-codec and IQ-payload checks: RFC 4648 vectors,
all byte values, explicit source ranges, raw blocks up to 65,535 bytes,
canonical padding, malformed alphabets, Unicode SIDs, 128 XML input split sizes,
bounded text parts and the full 16-bit sequence wrap. These validate the IBB
wire layer.

`TestXmppIbbTransfer` adds 69 checks covering consent, exact peer/SID matching, acknowledged source
ranges, empty transfers, byte/block/table limits, duplicate and out-of-order
blocks, malformed Base64, short reads/writes, flush errors, deadlines,
cancellation and reentrant cleanup. It exercises a full receive sequence wrap
and paired clients exchanging 0, 1, 513 and 65,537 bytes through fragmented XML.
Its standalone timeout is 120 seconds to allow the complete wrap test.
Two additional local TLS cases transfer binary data in both directions over
STARTTLS and direct TLS, including a Unicode service domain and spoofed-peer
rejection. These use synthetic local peers and memory-backed I/O.
The lifecycle suite passes GCC conventional/shared builds and the XMPP-module
Clang ASan/UBSan profile; other platforms remain unvalidated for this addition.

`TestXmppStreamInit` adds 162 checks for file metadata, empty and maximum-sized
offers, 128 fragmented Unicode offer round trips, transport selection, resume
bounds and malformed method forms. These pass conventional/shared GCC builds
and the XMPP-module Clang ASan/UBSan profile. The two IBB TLS fixtures first
negotiate an offer and select IBB, rejecting a spoofed resource's selection before sending
the file data.

In the standalone checkout, `make history-test` restores and verifies the
preserved Mercurial repository and checks the imported Git history. See
[the history record](History.md) for source revisions and the conversion checks.

The IQ tests add 145 checks covering namespace dispatch, all 110 transport split
sizes, Unicode peers, full/bare/domain address matching, spoofed and duplicate
replies, malformed payloads, cancellation, reentrant callbacks, queue limits,
stream closure and synchronous write failure.

Room-management integration adds 153 IQ checks, including 110 configuration-form
input split sizes, exact-room reply matching, form submission validation,
role/affiliation changes, configuration cancellation, destruction and deadlines.
Typed admin lists cover canonical identities, optional undisclosed fields,
filter checks, duplicates, empty lists and exact entry-capacity limits.

Roster and PubSub/PEP tests add 176 checks, including 110 push split sizes,
Unicode contact/group/item data, forged pushes, atomic snapshots, stale fetches,
reentrant completion, cancellation, synchronous failures, contact/group/text
budgets, matched publication results, retrieval limits and trusted-publisher
notification parsing. Payloadless items, retractions, purge/deletion events,
duplicate IDs and shared payload-byte budgets are covered.

Presence tests add 167 checks for explicit subscription construction, multilingual
status parsing, all 110 transport split sizes, recipient checks, per-resource
selection, watch/resource/text limits, reentrant callbacks and disconnect cleanup.

Multi-user-chat tests add 607 checks for join/leave, group-message and subject
construction, room-checked occupant decoding, roles, affiliations, disclosed JIDs,
nickname changes, removals, destruction, errors, mediated invitations/declines,
continued-chat invitations and language/text/status limits.
They include 160 input split sizes each for Unicode occupant presence and group
messages and invitations, plus byte-fragmented UTF-8 output round trips.

Room-state tracking adds 410 checks for explicit joins and self confirmation,
assigned nicknames, nickname changes, departures, removal/destruction,
recipient checks, join/rename/leave deadlines and disconnect cleanup. They
include 110 input split sizes, reentrant replies and callbacks, deadline
replacement during a tick, room/occupant capacity, retained-text budgets and
uncertain-state retry rejection.

Registration adds 196 checks for separate pre-login readiness, TLS capability
checks, explicit legacy-field submission, exact-peer replies, Unicode values,
account changes/removal, ownership, secret-buffer clearing and unsupported-form
rejection. Fragmented field responses cover 128 input split sizes. Ten additional
local TLS cases check creation, unavailable registration, invalid certificates
and Unicode/A-label domains over STARTTLS and direct TLS. No real account is
created, changed or removed by these fixtures.

Twenty-eight Python/OpenSSL loopback cases cover STARTTLS, direct TLS, Unicode
credentials, messages and domains, certificate and protocol-version rejection,
binding failures, stalled reads/handshakes, ping/version/discovery dispatch,
roster retrieval/edits/pushes and PubSub publish/retrieve/retract/notification
round trips, plus availability and all four subscription stanzas, and room
join/message/subject/leave exchanges with spoofed-room rejection, invitations,
configuration forms, role/affiliation changes, destruction and occupant-address
IQ spoof rejection. The MUC exchanges use the room tracker for confirmed joins,
Unicode nickname switches and departures, then check its disconnect cleanup.
Fixtures use
synthetic accounts and local peers. Live-server coverage includes verified
STARTTLS publication and exact-item retrieval with matching Atom text; live
roster/presence testing and broader server interoperability remain pending.
The shared IDNA suite has 38
conversion and rejection cases. The TLS regression target also runs the 36
existing TLS programs, HTTP/TLS loopback tests and 40 Gemini checks.

The earlier baseline passes on x86-64 Linux with GCC/C23, Clang/C23, TCC and
Clang ASan/UBSan. The registration additions have GCC and Clang ASan/UBSan
coverage; their complete compiler/platform matrix remains pending.
The sanitizer build uses an uninstrumented conservative core runtime, with
`ASAN_OPTIONS=detect_leaks=0:detect_stack_use_after_return=0` and
`UBSAN_OPTIONS=halt_on_error=1`. Shared IDNA and the XMPP module consumers
also pass against a modular VOC image.

On 2026-11-03, fresh GCC x86-64 Linux builds passed the conventional XMPP suite
with 607 MUC and 285 IQ checks, all 28 local TLS cases and the shared-library
suite. Admin-list tests subsequently brought the IQ suite to 298 checks, passing
both conventionally and with shared libraries. Clang ASan/UBSan passed the
607 MUC and 298 IQ checks with the XMPP
modules and test entry points instrumented; the conservative runtime and
non-XMPP dependencies remained uninstrumented. The complete compiler matrix
has not yet been repeated for the latest additions.

On 2026-11-05, the room tracker passed 410 checks conventionally, through shared
libraries and with Clang ASan/UBSan. The full conventional/shared library suites
also passed, and all 28 local TLS cases passed with tracked room joins, nickname
changes, departures and disconnect cleanup. The final checks include rejection
before writing when transport identity is lost. Sanitizer exclusions are the
same as above; native Windows validation remains pending.

Shared-module tests cover XMPP and publisher interfaces and bundled library
ABI/loading. The publisher's 21 payload/configuration checks, 22 file/XML
cases and 24 TLS loopback cases pass both conventionally and with shared modules.

Live-server coverage also includes a UTF-8 (Armenian language) account and domain,
verified STARTTLS, PLAIN authentication, resource binding, an Armenian/supplementary
self-message round trip and clean shutdown.

The XML/shared suites also pass: 14 XML programs, seven shared programs,
114 codec vectors, 77 URI fixtures, 2,687 conformance/output cases, 53 hostile
inputs and 2,655 deterministic mutation checks. XML stream coverage includes
486 additional mutations and lifetime/exact-consumption limits.
