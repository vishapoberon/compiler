(* Host file-system bindings used by oocFiles. *)
MODULE oocFilesHost;

IMPORT SYSTEM, Platform;

TYPE
  Byte* = SYSTEM.BYTE;
  Handle* = Platform.FileHandle;
  Error* = Platform.ErrorCode;

PROCEDURE Absent* (error: Error): BOOLEAN;
BEGIN
  RETURN Platform.Absent(error)
END Absent;

PROCEDURE TooManyFiles* (error: Error): BOOLEAN;
BEGIN
  RETURN Platform.TooManyFiles(error)
END TooManyFiles;

PROCEDURE Inaccessible* (error: Error): BOOLEAN;
BEGIN
  RETURN Platform.Inaccessible(error)
END Inaccessible;

PROCEDURE New* (VAR name: ARRAY OF CHAR; VAR handle: Handle): Error;
BEGIN
  RETURN Platform.New(name, handle)
END New;

PROCEDURE OpenReadOnly* (VAR name: ARRAY OF CHAR; VAR handle: Handle): Error;
BEGIN
  RETURN Platform.OldRO(name, handle)
END OpenReadOnly;

PROCEDURE OpenReadWrite* (VAR name: ARRAY OF CHAR; VAR handle: Handle): Error;
BEGIN
  RETURN Platform.OldRW(name, handle)
END OpenReadWrite;

PROCEDURE Close* (handle: Handle): Error;
BEGIN
  RETURN Platform.Close(handle)
END Close;

PROCEDURE Size* (handle: Handle; VAR length: LONGINT): Error;
BEGIN
  RETURN Platform.Size(handle, length)
END Size;

PROCEDURE Seek* (handle: Handle; position: LONGINT): Error;
BEGIN
  RETURN Platform.Seek(handle, position, Platform.SeekSet)
END Seek;

PROCEDURE ReadByte* (handle: Handle; VAR x: Byte; VAR count: LONGINT): Error;
BEGIN
  RETURN Platform.Read(handle, SYSTEM.ADR(x), 1, count)
END ReadByte;

PROCEDURE ReadBytes* (handle: Handle; VAR x: ARRAY OF Byte;
                      start, n: LONGINT; VAR count: LONGINT): Error;
BEGIN
  RETURN Platform.Read(handle, SYSTEM.ADR(x[start]), n, count)
END ReadBytes;

PROCEDURE WriteByte* (handle: Handle; x: Byte): Error;
BEGIN
  RETURN Platform.Write(handle, SYSTEM.ADR(x), 1)
END WriteByte;

PROCEDURE WriteBytes* (handle: Handle; VAR x: ARRAY OF Byte;
                       start, n: LONGINT): Error;
BEGIN
  RETURN Platform.Write(handle, SYSTEM.ADR(x[start]), n)
END WriteBytes;

PROCEDURE Sync* (handle: Handle): Error;
BEGIN
  RETURN Platform.Sync(handle)
END Sync;

PROCEDURE Truncate* (handle: Handle; length: LONGINT): Error;
BEGIN
  RETURN Platform.Truncate(handle, length)
END Truncate;

PROCEDURE Remove* (VAR name: ARRAY OF CHAR): Error;
BEGIN
  RETURN Platform.Unlink(name)
END Remove;

PROCEDURE Rename* (VAR oldName, newName: ARRAY OF CHAR): Error;
BEGIN
  RETURN Platform.Rename(oldName, newName)
END Rename;

PROCEDURE Exists* (VAR name: ARRAY OF CHAR): BOOLEAN;
  VAR identity: Platform.FileIdentity;
BEGIN
  RETURN Platform.IdentifyByName(name, identity) = 0
END Exists;

PROCEDURE GetModTime* (handle: Handle; VAR packedTime, packedDate: LONGINT): Error;
  VAR identity: Platform.FileIdentity; error: Error;
BEGIN
  error := Platform.Identify(handle, identity);
  IF error = 0 THEN Platform.MTimeAsClock(identity, packedTime, packedDate) END;
  RETURN error
END GetModTime;

PROCEDURE SetModTime* (VAR name: ARRAY OF CHAR; year, month, day,
                       hour, minute, second: LONGINT): Error;
BEGIN
  RETURN Platform.SetFileMTime(name, year, month, day, hour, minute, second)
END SetModTime;

PROCEDURE CurrentDirectory* (VAR path: ARRAY OF CHAR);
BEGIN
  COPY(Platform.CWD, path)
END CurrentDirectory;

PROCEDURE ProcessId* (): INTEGER;
BEGIN
  RETURN Platform.PID
END ProcessId;

END oocFilesHost.
