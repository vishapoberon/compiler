MODULE TypeAliases;
  (* Compiler regression fixture: export imported pointer and record types. *)
  IMPORT ConvTypes;
  TYPE ScanState* = ConvTypes.ScanState; ScanDesc* = ConvTypes.ScanDesc;
END TypeAliases.
