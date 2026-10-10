MODULE TestLoaded;
  (* A replacement application with a new import. Its executable host is not
     rebuilt when this version is compiled with -l. *)
  IMPORT SharedProvider, Out;
BEGIN
  ASSERT(SharedProvider.Next() = 1);
  Out.String("changed application import passed"); Out.Ln
END TestLoaded.
