MODULE TestPlatformWrite;
  (* Regression for vishap-bugs issue 59; WriteFaults.inc supplies the faults. *)
  IMPORT S := SYSTEM, Platform, Out;
  CONST Handle = 12345; Size = 37;
  VAR data: ARRAY Size OF CHAR; i, mode: LONGINT;
    written: LONGINT; error: Platform.ErrorCode;

  PROCEDURE -IncludeStdlib '#include <stdlib.h>';
  PROCEDURE -IncludeErrno '#include <errno.h>';
  PROCEDURE -IncludeDlfcn '#include <dlfcn.h>';
  PROCEDURE -Mode(): LONGINT 'atoi(getenv("VOC_WRITE_FAULT"))';
  PROCEDURE -Calls(): S.ADDRESS
    '((ADDRESS (*)(void))dlsym(RTLD_DEFAULT, "VocWriteCalls"))()';
  PROCEDURE -Completed(): S.ADDRESS
    '((ADDRESS (*)(void))dlsym(RTLD_DEFAULT, "VocWriteCompleted"))()';
  PROCEDURE -IOError(): Platform.ErrorCode 'EIO';
  PROCEDURE -Invalid(): Platform.ErrorCode 'EINVAL';

BEGIN
  FOR i := 0 TO Size-1 DO data[i] := CHR(i MOD 251) END;
  mode := Mode();
  IF mode = 5 THEN
    error := Platform.WriteCount(Handle, S.ADR(data), Size, written);
    ASSERT((error = 0) & (written = 3) & (Calls() = 1) & (Completed() = 3))
  ELSIF mode = 6 THEN
    error := Platform.Write(Handle, S.ADR(data), -1);
    ASSERT((error = Invalid()) & (Calls() = 0))
  ELSIF mode = 7 THEN
    error := Platform.Write(Handle, S.ADR(data), 0);
    ASSERT((error = 0) & (Calls() = 0))
  ELSE
    error := Platform.Write(Handle, S.ADR(data), Size);
    IF (mode = 1) OR (mode = 8) THEN
      ASSERT((error = 0) & (Completed() = Size));
      IF mode = 1 THEN ASSERT(Calls() = 14) ELSE ASSERT(Calls() = 13) END
    ELSIF mode = 2 THEN
      ASSERT((error = IOError()) & (Calls() = 2) & (Completed() = 3))
    ELSIF mode = 3 THEN
      ASSERT((error = IOError()) & (Calls() = 1) & (Completed() = 0))
    ELSE
      ASSERT((mode = 4) & Platform.Inaccessible(error) & (Calls() = 1))
    END
  END;
  Out.String("platform write tests passed"); Out.Ln
END TestPlatformWrite.
