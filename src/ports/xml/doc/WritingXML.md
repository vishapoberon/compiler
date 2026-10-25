# Writing XML

`XMLWriter` generates XML into a VOC `Channel.Writer`. It buffers output,
escapes text and attribute values, and optionally indents element-only content.
Use UTF-8 or UTF-16 to represent the complete supported Unicode range.

```oberon
IMPORT W := XMLWriter, C := XMLUnicodeCodec, S := LongStrings,
       XMLUnicodeCodecImportAll;

VAR writer: W.Writer;
    attribute: ARRAY 16 OF W.Char;

(* output is an application-supplied Channel.Writer. *)
writer := W.New(output, C.GetFactory("UTF-8"), FALSE, -1);
writer.WriteTextDecl("1.0", "");
writer.StartTagLatin1("message", TRUE);
S.Long("count", attribute);
writer.AttrInt(attribute, 1);
writer.WriteLatin1("Hello & welcome");
writer.EndTag;
writer.EndOfText;
```

Import `XMLUnicodeCodecImportAll` to register the bundled encoding factories.
The constructor's Boolean controls BOM generation for encodings supporting a
BOM. Indentation is disabled with `-1`; a nonnegative value specifies spaces
per nesting level. Pass `TRUE` for mixed-content elements to preserve text
without inserted indentation.

## Text and attributes

- `StartTag`, `EmptyTag`, `Write` and `AttrString` accept UTF-16 code-unit
  arrays using the shared `oocUnicode.LONGCHAR` type. These `VAR` parameters
  are treated as read-only. Supplementary characters use surrogate pairs.
- Methods ending in `Latin1` interpret bytes as Latin-1. For Unicode input,
  decode UTF-8 bytes before passing wide arrays to the writer.
- `WriteI` and `WriteLatin1I` accept a half-open region `[start, end)`.
- `AttrString` and `AttrStringLatin1` require an open start tag. Attribute
  names are wide strings in both methods. Attribute values escape apostrophes,
  markup delimiters and TAB/LF/CR. Text escapes markup delimiters and CR.
- `AttrInt`, `AttrBool` and `AttrURI` generate attribute values. `WriteURI`
  generates URI text; `SetBaseURI` supplies the base for relative URI output.

Applications provide valid XML names, declaration fields and character data,
and balance `StartTag` with `EndTag`. `EmptyTag` emits a complete empty element
when the next operation closes its start tag; it needs no `EndTag` of its own.
Call `EndOfText` to close pending empty tags and flush buffered output.

## Output errors

Check `writer.writer.res` for channel errors and `writer.codec.invalidChars`
for invalid or unrepresentable Unicode input. Do not treat output as successful
if either indicates an error. Partial writes are retried by the output buffer.
After repairing a channel error, clear its writer error and retry `Flush`;
pending bytes remain buffered. Stop generating new content while an error is
outstanding.

## Canonical output

`XMLBuilderCanonical.New(channel, codecFactory, format)` consumes parser
callbacks and writes canonical output. It expands empty tags, sorts attributes,
escapes text consistently and omits comments. `firstCanonicalForm` omits DTD
notations; `secondCanonicalForm` includes sorted notation declarations.
Connect it directly to the parser, optionally behind the DTD validator, so it
receives qualified names. Its `EndDocument` callback flushes output.

`XMLCheck --canonical --external file.xml` writes UTF-8 canonical output to
standard output; use `--second` for the second form. These modes buffer their
result until parsing succeeds. Use trusted inputs while the parser's resource
limits and external-entity security review remain pending.
