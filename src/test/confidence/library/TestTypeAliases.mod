MODULE TestTypeAliases;
  (* No direct ConvTypes import: the aliases must supply the defining header. *)
  IMPORT TypeAliases, Out;
  VAR state, copy: TypeAliases.ScanState; desc: TypeAliases.ScanDesc;
BEGIN
  NEW(state); copy := state;
  ASSERT(copy = state);
  desc.p := NIL; ASSERT(desc.p = NIL);
  ASSERT(SIZE(TypeAliases.ScanDesc) > 0);
  Out.String("type-only aliases passed"); Out.Ln
END TestTypeAliases.
