MODULE TestModulePaths;
  IMPORT ModulePaths, Heap, Out;
  VAR cursor: LONGINT; directory: ARRAY 8 OF CHAR; name: Heap.ModuleName;
    file: ARRAY 128 OF CHAR; small: ARRAY 4 OF CHAR; i: LONGINT;
BEGIN
  cursor := 0;
  ASSERT(ModulePaths.Directory(":abc::", cursor, directory) & (directory = "."));
  ASSERT(ModulePaths.Directory(":abc::", cursor, directory) & (directory = "abc"));
  ASSERT(ModulePaths.Directory(":abc::", cursor, directory) & (directory = "."));
  ASSERT(ModulePaths.Directory(":abc::", cursor, directory) & (directory = "."));
  ASSERT(~ModulePaths.Directory(":abc::", cursor, directory));
  cursor := 0;
  ASSERT(ModulePaths.Directory("oversized-directory:good", cursor, directory) & (directory = "good"));
  ASSERT(~ModulePaths.Directory("oversized-directory:good", cursor, directory));
  cursor := 0; ASSERT(ModulePaths.Directory("", cursor, directory) & (directory = "."));
  ASSERT(~ModulePaths.Directory("", cursor, directory));
  ASSERT(ModulePaths.Identifier("A_9"));
  ASSERT(~ModulePaths.Identifier("")); ASSERT(~ModulePaths.Identifier("_A"));
  ASSERT(~ModulePaths.Identifier("../A")); ASSERT(~ModulePaths.Identifier("A-B"));
  FOR i := 0 TO LEN(name) - 2 DO name[i] := "a" END; name[LEN(name) - 1] := 0X;
  ASSERT(ModulePaths.Identifier(name));
  ASSERT(ModulePaths.Library(".", "Out", "O2", file) & (file = "./libvoc-Out-O2.so"));
  small := "abc"; ASSERT(~ModulePaths.Append("d", small)); ASSERT(small = "abc");
  Out.String("Oberon module path tests passed"); Out.Ln
END TestModulePaths.
