MODULE TestLoaded;
  (* Replacement for TestLoaded.Mod, adding an import. The module name stays
     TestLoaded so it replaces the shared library without rebuilding the host. *)
  IMPORT SharedProvider, Out;
BEGIN
  ASSERT(SharedProvider.Next() = 1);
  Out.String("changed application import passed"); Out.Ln
END TestLoaded.
