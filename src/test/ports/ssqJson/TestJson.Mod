MODULE TestJson;
IMPORT Json, Out;
VAR source, output, error: ARRAY 1024 OF CHAR;
  value, selected: Json.Value; object: Json.Obj; array: Json.Arr;
  name: Json.jString; names: Json.NameList;

PROCEDURE Parse(text: ARRAY OF CHAR);
BEGIN
  COPY(text, source);
  ASSERT(Json.Parse(value, source, error)); ASSERT(error = "")
END Parse;

BEGIN
  Parse('{"name":"Oberon","count":42,"ready":true,"none":null,"items":[1,2,3]}');
  ASSERT(value IS Json.Obj); object := value(Json.Obj);
  names := Json.ObjNames(object); ASSERT(names # NIL); ASSERT(names.name^ = "name");
  NEW(name, 6); COPY("count", name^);
  ASSERT(Json.ObjSelect(selected, object, name)); ASSERT(selected IS Json.Int);
  ASSERT(selected(Json.Int).i = 42);
  object := value(Json.Obj); COPY("items", name^);
  ASSERT(Json.ObjSelect(selected, object, name)); ASSERT(selected IS Json.Arr);
  array := selected(Json.Arr); ASSERT(array.value(Json.Int).i = 1);
  array := array.next; ASSERT(array.value(Json.Int).i = 2);
  array := array.next; ASSERT(array.value(Json.Int).i = 3); ASSERT(array.next = NIL);
  ASSERT(Json.Format(output, value));
  COPY(output, source); ASSERT(Json.Parse(selected, source, error)); ASSERT(error = "");
  Parse("-123"); ASSERT(value(Json.Int).i = -123);
  ASSERT(Json.Format(output, value)); ASSERT(output[0] = "-");
  Parse("false"); ASSERT(~value(Json.Bool).b);
  Parse('"text"'); ASSERT(value(Json.Str).str^ = "text");
  Parse("null"); ASSERT(value IS Json.Null);
  Parse("1.25"); ASSERT(value(Json.Real).r = 1.25);
  source := '{"broken" 1}'; ASSERT(~Json.Parse(value, source, error));
  ASSERT(value = NIL); ASSERT(error # "");
  source := "true false"; ASSERT(~Json.Parse(value, source, error)); ASSERT(value = NIL);
  (* These are documented extensions, not strict JSON conformance. *)
  source := "[1,]"; ASSERT(Json.Parse(value, source, error)); ASSERT(error # "");
  source := "/* note */ true"; ASSERT(Json.Parse(value, source, error));
  ASSERT(value(Json.Bool).b);
  Out.String("ssqJson regressions passed"); Out.Ln
END TestJson.
