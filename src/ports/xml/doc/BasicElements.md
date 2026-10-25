# Basic element objects

`XMLBasicParser` constructs application objects from a small XML document.
Applications describe each element by extending `XMLBasicElement.ElementDesc`.
The parser invokes those methods as it reads the document, reports application
errors through `XMLError.List` and returns a root object on success.

## Defining elements

1. Extend `ElementDesc` and call `XMLBasicElement.InitElement` when creating
   each instance. Initialize the application's fields at the same time.
2. Implement `IsAttributeName` and `AddAttribute` for accepted attributes.
   Return `FALSE` from `AddAttribute` for an invalid value.
3. Implement `IsChildName`, `NewChild` and `AddChild` for accepted children.
   `NewChild` may return `NIL` if the child cannot occur at that position.
   `XMLBasicElement.List` stores children and serializes them through their
   `Write` methods.
4. Implement `MissingAttribute` and `MissingChild` when the application requires
   particular attributes or children. Return the missing name or `NIL`.
5. Override `HasMixedContent` and `AddCharacters` for text-bearing elements.
   `XMLBasicElement.PCData` collects Unicode text and writes it with escaping.
6. Implement `CheckElement` for whole-element consistency checks, returning a
   diagnostic string or `NIL`. Implement `Write` to serialize the object with
   `XMLWriter` when the application needs output.

The base element accepts no attributes or children and assumes element-only
content. Its `AddChild`, `AddCharacters` and `Write` methods halt if called
without an implementation. `SetLocator` is called before attributes or content
on every object, including the root. The locator is live: copy its position or
base URI during that call if the object needs to retain them.

Factories, element names and text use UTF-16 code-unit arrays through the shared
`oocUnicode.LONGCHAR` type. `NewString` and `NewStringBuffer` copy their input;
`StringBuffer.AddCharacters` appends a half-open region `[start, end)`.
`PCData.Normalize` collapses whitespace, optionally stripping either end.

## Parsing

Create a root factory with `XMLBasicElement.NewRootFactory()`. Register each
accepted root name and a parameterless constructor returning an `Element` with
`factory.AddFactory(name, constructor)`. The factory copies the name.

Pass the input `Channel.Reader`, optional base URI and encoding factory, root
factory, maximum nesting depth and flags to `XMLBasicParser.Parse`. A depth of
zero allows only the root; a negative depth allows unrestricted element nesting.
The parser reports qualified names to application objects.

Use `{XMLBasicParser.validate}` to enable DTD validation. On success, `Parse`
returns the root and sets the error-list result to `NIL`. On failure it returns
`NIL` and supplies diagnostics. Application callbacks stop after the first
application error. The caller retains ownership of the input channel.

`XMLBasicParser.ParseLimited` accepts the same arguments with an `XMLLimits`
budget after `flags` and before the error-list result. It applies shared
input, entity, nesting and work limits before input prefetch. `Parse` retains
its unlimited resource behavior. The separate Basic nesting-depth argument
covers application element objects.

Both entry points follow external references when a base URI is supplied or
validation is enabled. Use trusted documents and bound application callback
work; see [input policy and resource review](Security.md).

## Typed attributes

`XMLBasicDataType` provides helpers for `DTD.AttValue`:

- `GetIntAttr` checks a signed `LONGINT` without truncating a long input.
- `GetStringLatin1Attr` succeeds only when every unit fits Latin-1 and the
  destination has room for the terminator. Failure leaves the destination
  unchanged.
- `GetURIAttr` normalizes Unicode URI text to UTF-8 percent escapes and resolves
  relative references against an optional base URI. Malformed UTF-16 fails.

All helpers return a Boolean success result.

## Callback traces

`XMLBuilderParserProtocol.New(channel, codecFactory)` records parser callbacks
as XML for diagnostics. Connect it directly to `XMLParser`, or behind namespace
and validation builders. `EndDocument` closes and flushes the trace, including
when parsing reports an error. Check `builder.w.writer.res` and
`builder.w.codec.invalidChars` before using the output.

`XMLCheck --protocol file.xml` prints the trace for successful parses. Add
`--external`, `--namespaces` or `--validate` as needed for trusted local fixtures.
