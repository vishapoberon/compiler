(* Host bindings for the standard streams used by ulmStreams. *)
MODULE ulmStreamsHost;

IMPORT SYSTEM, Platform;

TYPE
  Address* = SYSTEM.ADDRESS;
  Count* = SYSTEM.INT32;

PROCEDURE ReadStdIn* (address: Address; count: Count): Count;
  VAR actual: LONGINT;
BEGIN
  IF Platform.Read(Platform.StdIn, address, count, actual) # 0 THEN
    RETURN -1
  END;
  RETURN actual
END ReadStdIn;

PROCEDURE WriteStdOut* (address: Address; count: Count): Count;
BEGIN
  IF Platform.Write(Platform.StdOut, address, count) # 0 THEN
    RETURN -1
  END;
  RETURN count
END WriteStdOut;

PROCEDURE WriteStdErr* (address: Address; count: Count): Count;
BEGIN
  IF Platform.Write(Platform.StdErr, address, count) # 0 THEN
    RETURN -1
  END;
  RETURN count
END WriteStdErr;

END ulmStreamsHost.
