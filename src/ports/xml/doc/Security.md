# XML input policy and resource review

The port currently requires **trusted XML**. External access controls and
parser and built-in builder resource budgets have regression coverage.
Application callbacks and underlying allocation/I/O failures still require
their own policies and broader adversarial testing.

## External resources

`XMLParser.followExternalRef` controls the external DTD subset, external general
entities and external parameter entities. The library retains the upstream
default of `TRUE`; set it explicitly before calling `ParseDocument`.

- With `FALSE`, ordinary external references are skipped. A guard at the shared
  external-buffer opening point also prevents reads during error recovery.
  Malformed input cannot bypass this guard through parameter-entity insertion.
- With `TRUE`, references may open any resource accepted by the supplied entity
  resolver and registered URI schemes. The resolver translates identifiers;
  the returned URI's `GetChannel` method opens the resource.
- The primary input is separate: `NewFile` and `NewURI` open the requested
  document before `followExternalRef` can be configured. `NewReader` and
  `NewChannel` use an application-supplied input and prefetch buffered data.
- Identifier resolution can still invoke the application's resolver when
  external reads are disabled. Custom resolvers, URI implementations and
  builder callbacks must enforce their own side-effect policies.

`XMLCheck` disables external reads by default. `--external` enables them, and
`--validate` enables them to read the complete DTD. Canonical and protocol output
flags alone leave external reads disabled. `XMLBasicParser.Parse` enables
external reads when a base URI is supplied or validation is requested.

## Reviewed paths and fixes

The external-opening paths converge on `XMLParser.GetBuffer`. These include
streamed DTD/general-entity parsing and `Internalize`, which reads an external
parameter entity into a Unicode string before inserting it into another value.

`TestEntityPolicy` uses an instrumented in-memory URI implementation, without
opening host files. It counts opens and checks:

- DTD subsets, general entities and parameter entities with access enabled and
  disabled;
- malformed parameter references inside internal entity declarations and
  indirect external references in attributes;
- unused unparsed entities, direct/indirect general-entity cycles and recursive
  external parameter entities;
- malformed UTF-8 in an internalized external parameter entity.

The review fixed three issues:

1. A parameter reference inside a malformed internal entity declaration could
   read an external resource despite `followExternalRef = FALSE`. The shared
   opening guard now rejects that path before calling `GetChannel`.
2. Parameter-entity references did not check whether the referent was already
   expanding. Direct and indirect cycles now produce a fatal diagnostic before
   another expansion or read.
3. `Internalize` checked the caller's decoder instead of the external entity's
   decoder. It now reports malformed encodings from the buffer actually read.

## Parser resource budgets

`XMLLimits.New()` creates a budget for one parse. Set its maxima before passing
it to `XMLParser.NewReaderLimited`, `NewChannelLimited`, `NewURILimited` or
`NewFileLimited`. These constructors have the corresponding original
constructor's arguments, with the budget after the builder and before any
result argument. For example:

```oberon
budget := XMLLimits.New();
budget.maxInputBytes := 1024*1024;
parser := XMLParser.NewReaderLimited(reader, baseURI, NIL, NIL, builder, budget);
parser.followExternalRef := FALSE;
parser.ParseDocument;
(* Inspect parser.errList before using the result. *)
```

The original constructors retain their unlimited behavior. `XMLCheck` uses a
fresh default budget for every invocation, including namespace, validation,
canonical and protocol modes. `XMLBasicParser.ParseLimited` accepts a budget
after `flags` and before `errList`; the original `Parse` remains unlimited.
Both Basic entry points retain the external-reference policy described above.

| Budget maximum | Default | Accounted resources |
| --- | ---: | --- |
| `maxInputBytes` | 16 MiB | Accepted bytes across the document and all opened external entities. |
| `maxNesting` | 128 | Combined active element, entity, content-model, conditional-section, regular-expression construction and attribute-graph traversal levels. |
| `maxEntityExpansions` | 10,000 | Entity entries, including the external DTD and eager checking of internal declarations. |
| `maxExpandedUnits` | 16,777,216 | UTF-16 code units copied for entity insertion/internalization and visited while checking attribute/entity values. |
| `maxWork` | 100,000 | Name/string construction, character fragments, graph visits, parser diagnostics, declaration/attribute comparisons, validation/ID/enumeration scans, regular-expression states/sets, namespace searches and canonical sorting. |
| `maxAttributeUnits` | 1,048,576 | Code units in one flattened attribute or entity value. |
| `maxModelParticles` | 256 | Groups and named particles in one DTD content model. |
| `maxOutputBytes` | 16 MiB | Encoded bytes delivered by built-in canonical and protocol builders. |

Zero is a real limit; a negative maximum disables that particular limit.
Counters are cumulative and a failed budget remains failed. Keep the budget
exclusive to its parse and leave the maxima unchanged during parsing.
Expansion accounting is conservative: checking a reused value can charge its
units again. `maxWork` bounds construction and comparison operations, rather
than measuring allocated bytes or elapsed time.

The byte budget wraps the reader before constructor prefetch and is shared
with every subsequent external reader. At an exact byte boundary a one-byte
probe distinguishes EOF from an overrun; at most one extra byte is consumed
and none of it is delivered to the parser. Expansion and nesting reservations
precede opening or internalizing an entity. Opening the primary URI and running
application resolver code still have their own side effects.

On exhaustion the parser records a resource diagnostic, sets `parser.aborted`,
suppresses further content callbacks and unwinds its grammar/entity stacks.
The original builder still receives `EndDocument` once. Its result may be
incomplete and must be discarded. `budget.error` identifies the diagnostic;
its code is `XMLLimits.codeBase` plus the relevant limit constant. `XMLCheck`
returns 1 for a resource diagnostic, just as for other XML errors.

Attribute graphs are checked for nesting, work and expanded length before
recursive length calculation or flattening. This also covers default values
and unused entity declarations. DTD namespace insertion is iterative and both
lookup and insertion charge comparisons. Retained-token byte and Unicode
buffers grow geometrically, keeping long-token copying linear in total size.

The parser calls `XMLBuilder.SetLimits` before document callbacks. The namespace
and validation builders forward the same budget to their delegates. Validation
charges aggregate costs across content models, ID/IDREF and enumeration checks;
`XMLRegexp.NewLimited` also supplies this accounting to direct callers. The
original `XMLRegexp.New` remains unlimited. Canonical and protocol builders wrap
their output writers before flushing any document bytes. The output cap counts
bytes successfully written, including buffered output and escaping expansion;
an incomplete output must be discarded on exhaustion.

DTD values created by a limited parser retain its budget for subsequent length
and flattening operations. Directly created values can opt in with
`XMLDTD.AttValue.SetLimits`, covering nested entity values and cycles. Direct
namespace lookups can use `XMLDTD.Namespace.SetLimits`. Other direct DTD
construction operations retain their caller-managed resource policy.

## Adversarial checks

`TestLimits` tests exact boundaries and independently exhausts every limit.
It varies byte, work, expansion, value-length, nesting and content-model
cutoffs throughout a document containing declarations, attributes, entities,
comments, instructions and CDATA. It checks diagnostics, stack unwinding,
content callback suppression and final notification in plain, namespace,
validation and combined modes. It also sweeps canonical/protocol output cutoffs
and checks directly constructed entity cycles. `TestBasic` exercises work
cutoffs through `ParseLimited`.

`TestEntityPolicy` also cuts the shared byte allowance at every position across
external DTDs, repeated streamed entities and external-parameter internalization.
It checks that expansion exhaustion prevents a further external open.

```sh
make -C src/ports/xml test conformance limits fuzz
```

The `limits` target runs 53 hostile-input checks: deep elements, content models
and conditional sections, wide models, unused entity amplification, long entity
chains, parameter expansion, large attributes/input/names, many attributes and
siblings, malformed-control/reference floods and external internalization.
The general cases run in plain, namespace and validation modes. Additional
cases exercise validation closure/aggregate costs, IDREF/enumeration floods,
namespace searches, canonical notation sorting and escaped output growth.
Every case must return a resource diagnostic with exit code 1.
The runner applies a 10-second CPU allowance,
a wall-clock timeout and a 512 MiB address-space ceiling on Linux. Under ASan
the address-space ceiling is disabled to accommodate shadow memory; CPU and
wall-clock limits remain active. Logs and results go under `BUILD/limits`.

The `fuzz` target runs 2,655 deterministic truncation and byte-mutation checks
with seed 20261025 across plain, namespace, validation, canonical and protocol
modes. Every invocation must finish with success or XML diagnostics, rather
than a trap, timeout, opening/usage failure or sanitizer error. Its CPU,
wall-clock and output-file limits bound each process; the same address-space
policy applies as above. Reports and reproducing inputs are in `BUILD/fuzz`.

## Remaining resource work

Continue using trusted documents while completing:

- broader malformed-input and randomized testing, including larger graphs and
  different mutation seeds, resolver/channel stalls and
  recovery from underlying allocation failures;
- application-builder accounting and caller-managed direct DTD construction.

Applications must bound their own resolver, channel and builder behavior.
Custom delegating builders should forward `SetLimits` and charge their own
work; callbacks are application code. Retain
process-level time and memory limits when exercising hostile inputs.
