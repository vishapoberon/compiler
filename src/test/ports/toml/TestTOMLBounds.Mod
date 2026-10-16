MODULE TestTOMLBounds;
IMPORT TOML, Out;
VAR raw: ARRAY 3 OF CHAR;
    empty: ARRAY 1 OF CHAR;
    source: ARRAY 256 OF CHAR;
    name, key: ARRAY 32 OF CHAR;
    doc: TOML.Doc;
    section: TOML.Section;
    field: TOML.Field;
BEGIN
  empty := ''; TOML.Trim(empty); TOML.ToLower(empty);
  raw[0] := ' '; raw[1] := ' '; raw[2] := ' ';
  TOML.TrimLeft(raw); ASSERT(raw[0] = 0X);
  raw[0] := ' '; raw[1] := 'A'; raw[2] := 'B';
  TOML.TrimLeft(raw); ASSERT(raw = 'AB');
  raw[0] := 'A'; raw[1] := 'B'; raw[2] := 'C';
  TOML.ToLower(raw); ASSERT(raw[0] = 'a'); ASSERT(raw[2] = 'c');
  raw[0] := 'n'; raw[1] := '='; raw[2] := '1';
  doc := TOML.Parse(raw); ASSERT(doc.errors = 0);
  name := ''; section := TOML.GetSection(doc, name); key := 'n';
  field := TOML.Find(section, key); ASSERT(field # NIL); ASSERT(field.value = '1');
  source := 'title="hello"'; doc := TOML.Parse(source); ASSERT(doc.errors = 0);
  source := 'n=[1,2,3]'; doc := TOML.Parse(source); ASSERT(doc.errors = 0);
  section := TOML.GetSection(doc, name); field := TOML.Find(section, key);
  ASSERT(field.kind = TOML.Array); ASSERT(field.items.next.next.value = '3');
  source := 'n="unterminated'; doc := TOML.Parse(source); ASSERT(doc.errors > 0);
  Out.String('toml bounds tests passed'); Out.Ln
END TestTOMLBounds.
