MODULE BadCoreABI;
  (* The test makefile corrupts only the generated runtime-identity pointer,
     retaining the compiler's ABI layout descriptor. *)
BEGIN
  HALT(99) (* Rejection must happen before this initializer runs. *)
END BadCoreABI.
