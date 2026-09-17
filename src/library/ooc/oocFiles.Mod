(* VOC implementation of the oo2c 1.x Files channel interface. *)
MODULE oocFiles;

IMPORT
  Host := oocFilesHost,
  Channel := oocChannel, Time := oocTime, JulianDay := oocJulianDay,
  Strings := oocStrings, IntStr := oocIntStr, Msg := oocMsg;

TYPE
  Result* = Channel.Result;

CONST
  noLength* = Channel.noLength;
  noPosition* = Channel.noPosition;

  done* = Channel.done;
  invalidChannel* = Channel.invalidChannel;
  writeError* = Channel.writeError;
  noRoom* = Channel.noRoom;
  outOfRange* = Channel.outOfRange;
  readAfterEnd* = Channel.readAfterEnd;
  channelClosed* = Channel.channelClosed;
  readError* = Channel.readError;
  invalidFormat* = Channel.invalidFormat;
  noReadAccess* = Channel.noReadAccess;
  noWriteAccess* = Channel.noWriteAccess;
  closeError* = Channel.closeError;
  noModTime* = Channel.noModTime;
  noTmpName* = Channel.noTmpName;

  accessDenied* = Channel.freeErrorCode;
  isDirectory* = Channel.freeErrorCode+1;
  tooManyFiles* = Channel.freeErrorCode+2;
  noSuchFile* = Channel.freeErrorCode+3;
  directoryFull* = Channel.freeErrorCode+4;
  readOnlyFileSystem* = Channel.freeErrorCode+5;
  invalidTime* = Channel.freeErrorCode+6;
  notOwner* = Channel.freeErrorCode+7;
  anonymousFile* = Channel.freeErrorCode+8;
  dirWriteDenied* = Channel.freeErrorCode+9;
  fileError* = Channel.freeErrorCode+10;
  nameTooLong* = Channel.freeErrorCode+11;
  notDirectory* = Channel.freeErrorCode+12;
  linkLoop* = Channel.freeErrorCode+13;

  read* = 0;
  write* = 1;
  tryRead* = 2;
  tryWrite* = 3;

  maxPath = 4096;

TYPE
  File* = POINTER TO FileDesc;
  Reader* = POINTER TO ReaderDesc;
  Writer* = POINTER TO WriterDesc;

  FileDesc* = RECORD
    (Channel.ChannelDesc)
    handle: Host.Handle;
    name, tmpName: ARRAY maxPath OF CHAR;
    temporary, anonymous: BOOLEAN
  END;

  ReaderDesc* = RECORD
    (Channel.ReaderDesc)
    pos: LONGINT
  END;

  WriterDesc* = RECORD
    (Channel.WriterDesc)
    pos: LONGINT
  END;

  ErrorContext* = POINTER TO ErrorContextDesc;
  ErrorContextDesc* = RECORD
    (Channel.ErrorContextDesc)
  END;

VAR
  errorContext: ErrorContext;
  tmpNumber: INTEGER;

PROCEDURE GetError(code: Msg.Code): Result;
BEGIN
  RETURN Msg.New(errorContext, code)
END GetError;

PROCEDURE OpenError(error: Host.Error): Result;
BEGIN
  IF Host.Absent(error) THEN
    RETURN GetError(noSuchFile)
  ELSIF Host.TooManyFiles(error) THEN
    RETURN GetError(tooManyFiles)
  ELSIF Host.Inaccessible(error) THEN
    RETURN GetError(accessDenied)
  ELSE
    RETURN GetError(fileError)
  END
END OpenError;

PROCEDURE (context: ErrorContext) GetTemplate* (msg: Msg.Msg; VAR templ: Msg.LString);
  VAR str: ARRAY 128 OF CHAR;
BEGIN
  CASE msg.code OF
  | accessDenied:       str := "Access denied"
  | isDirectory:        str := "File is a directory"
  | tooManyFiles:       str := "Too many files are open"
  | noSuchFile:         str := "No such file or directory"
  | directoryFull:      str := "Directory or file system is full"
  | readOnlyFileSystem: str := "File system is read-only"
  | invalidTime:        str := "Invalid modification time"
  | notOwner:           str := "Not the owner of the file"
  | anonymousFile:      str := "Anonymous temporary file cannot be registered"
  | dirWriteDenied:     str := "Directory is not writable"
  | fileError:          str := "File operation failed"
  | nameTooLong:        str := "File name is too long"
  | notDirectory:       str := "Path component is not a directory"
  | linkLoop:           str := "Too many symbolic links"
  ELSE
    str := "";
    context.GetTemplate^(msg, templ)
  END;
  IF str # "" THEN COPY(str, templ) END
END GetTemplate;

PROCEDURE ReaderFile(r: Reader): File;
BEGIN
  RETURN r.base(File)
END ReaderFile;

PROCEDURE WriterFile(w: Writer): File;
BEGIN
  RETURN w.base(File)
END WriterFile;

PROCEDURE Seek(f: File; pos: LONGINT; VAR res: Result): BOOLEAN;
  VAR error: Host.Error;
BEGIN
  error := Host.Seek(f.handle, pos);
  IF error # 0 THEN
    res := GetError(outOfRange);
    RETURN FALSE
  END;
  RETURN TRUE
END Seek;

PROCEDURE (r: Reader) Pos* (): LONGINT;
BEGIN
  RETURN r.pos
END Pos;

PROCEDURE (r: Reader) Available* (): LONGINT;
  VAR f: File; length: LONGINT; error: Host.Error;
BEGIN
  f := ReaderFile(r);
  IF ~f.open THEN RETURN -1 END;
  error := Host.Size(f.handle, length);
  IF error # 0 THEN RETURN 0 END;
  IF length > r.pos THEN RETURN length-r.pos ELSE RETURN 0 END
END Available;

PROCEDURE (r: Reader) SetPos* (newPos: LONGINT);
  VAR f: File;
BEGIN
  IF r.res = done THEN
    f := ReaderFile(r);
    IF ~f.open THEN
      r.res := GetError(channelClosed)
    ELSIF ~r.positionable OR (newPos < 0) THEN
      r.res := GetError(outOfRange)
    ELSE
      r.pos := newPos
    END
  END
END SetPos;

PROCEDURE (r: Reader) ReadByte* (VAR x: Host.Byte);
  VAR f: File; error: Host.Error; n: LONGINT;
BEGIN
  r.bytesRead := 0;
  IF r.res = done THEN
    f := ReaderFile(r);
    IF ~f.open THEN
      r.res := GetError(channelClosed)
    ELSIF Seek(f, r.pos, r.res) THEN
      error := Host.ReadByte(f.handle, x, n);
      IF error # 0 THEN
        r.res := GetError(readError)
      ELSIF n = 0 THEN
        x := 0X;
        r.res := GetError(readAfterEnd)
      ELSE
        INC(r.pos);
        r.bytesRead := 1
      END
    END
  END
END ReadByte;

PROCEDURE (r: Reader) ReadBytes* (VAR x: ARRAY OF Host.Byte; start, n: LONGINT);
  VAR f: File; error: Host.Error; count: LONGINT;
BEGIN
  ASSERT((n >= 0) & (start >= 0) & (start+n <= LEN(x)));
  r.bytesRead := 0;
  IF (r.res = done) & (n > 0) THEN
    f := ReaderFile(r);
    IF ~f.open THEN
      r.res := GetError(channelClosed)
    ELSIF Seek(f, r.pos, r.res) THEN
      error := Host.ReadBytes(f.handle, x, start, n, count);
      r.bytesRead := count;
      INC(r.pos, count);
      IF error # 0 THEN
        r.res := GetError(readError)
      ELSIF count # n THEN
        r.res := GetError(readAfterEnd)
      END
    END
  END
END ReadBytes;

PROCEDURE (w: Writer) Pos* (): LONGINT;
BEGIN
  RETURN w.pos
END Pos;

PROCEDURE (w: Writer) SetPos* (newPos: LONGINT);
  VAR f: File;
BEGIN
  IF w.res = done THEN
    f := WriterFile(w);
    IF ~f.open THEN
      w.res := GetError(channelClosed)
    ELSIF ~w.positionable OR (newPos < 0) THEN
      w.res := GetError(outOfRange)
    ELSE
      w.pos := newPos
    END
  END
END SetPos;

PROCEDURE (w: Writer) WriteByte* (x: Host.Byte);
  VAR f: File; error: Host.Error;
BEGIN
  w.bytesWritten := 0;
  IF w.res = done THEN
    f := WriterFile(w);
    IF ~f.open THEN
      w.res := GetError(channelClosed)
    ELSIF Seek(f, w.pos, w.res) THEN
      error := Host.WriteByte(f.handle, x);
      IF error # 0 THEN
        w.res := GetError(writeError)
      ELSE
        INC(w.pos);
        w.bytesWritten := 1
      END
    END
  END
END WriteByte;

PROCEDURE (w: Writer) WriteBytes* (VAR x: ARRAY OF Host.Byte; start, n: LONGINT);
  VAR f: File; error: Host.Error;
BEGIN
  ASSERT((n >= 0) & (start >= 0) & (start+n <= LEN(x)));
  w.bytesWritten := 0;
  IF (w.res = done) & (n > 0) THEN
    f := WriterFile(w);
    IF ~f.open THEN
      w.res := GetError(channelClosed)
    ELSIF Seek(f, w.pos, w.res) THEN
      error := Host.WriteBytes(f.handle, x, start, n);
      IF error # 0 THEN
        w.res := GetError(writeError)
      ELSE
        INC(w.pos, n);
        w.bytesWritten := n
      END
    END
  END
END WriteBytes;

PROCEDURE (w: Writer) Truncate* (newLength: LONGINT);
  VAR f: File; error: Host.Error;
BEGIN
  IF w.res = done THEN
    f := WriterFile(w);
    IF ~f.open THEN
      w.res := GetError(channelClosed)
    ELSIF newLength < 0 THEN
      w.res := GetError(outOfRange)
    ELSE
      error := Host.Truncate(f.handle, newLength);
      IF error # 0 THEN w.res := GetError(writeError) END
    END
  END
END Truncate;

PROCEDURE (f: File) Length* (): LONGINT;
  VAR length: LONGINT; error: Host.Error;
BEGIN
  IF ~f.open THEN RETURN noLength END;
  error := Host.Size(f.handle, length);
  IF error # 0 THEN
    f.res := GetError(invalidChannel);
    RETURN noLength
  END;
  RETURN length
END Length;

PROCEDURE (f: File) GetModTime* (VAR mtime: Time.TimeStamp);
  VAR
    packedTime, packedDate: LONGINT;
    day, month: SHORTINT;
    year: INTEGER;
    hour, minute, second: LONGINT;
    error: Host.Error;
BEGIN
  IF ~f.open THEN
    f.res := GetError(channelClosed)
  ELSE
    error := Host.GetModTime(f.handle, packedTime, packedDate);
    IF error # 0 THEN
      f.res := GetError(noModTime)
    ELSE
      day := SHORT(SHORT(packedDate MOD 32));
      month := SHORT(SHORT((packedDate DIV 32) MOD 16));
      year := SHORT(packedDate DIV 512);
      IF year < 70 THEN INC(year, 2000) ELSE INC(year, 1900) END;
      hour := packedTime DIV 4096;
      minute := (packedTime DIV 64) MOD 64;
      second := packedTime MOD 64;
      Time.InitTimeStamp(mtime, JulianDay.DateToDays(day, month, year),
                         ((hour*60+minute)*60+second)*Time.msecPerSec);
      f.res := done
    END
  END
END GetModTime;

PROCEDURE (f: File) NewReader* (): Channel.Reader;
  VAR r: Reader;
BEGIN
  IF ~f.open THEN
    f.res := GetError(channelClosed);
    RETURN NIL
  ELSIF ~f.readable THEN
    f.res := GetError(noReadAccess);
    RETURN NIL
  END;
  NEW(r);
  r.base := f;
  r.res := done;
  r.bytesRead := 0;
  r.positionable := TRUE;
  r.pos := 0;
  f.res := done;
  RETURN r
END NewReader;

PROCEDURE (f: File) NewWriter* (): Channel.Writer;
  VAR w: Writer;
BEGIN
  IF ~f.open THEN
    f.res := GetError(channelClosed);
    RETURN NIL
  ELSIF ~f.writable THEN
    f.res := GetError(noWriteAccess);
    RETURN NIL
  END;
  NEW(w);
  w.base := f;
  w.res := done;
  w.bytesWritten := 0;
  w.positionable := TRUE;
  w.pos := 0;
  f.res := done;
  RETURN w
END NewWriter;

PROCEDURE (f: File) Flush*;
  VAR error: Host.Error;
BEGIN
  IF ~f.open THEN
    f.res := GetError(channelClosed)
  ELSIF f.writable THEN
    error := Host.Sync(f.handle);
    IF error = 0 THEN f.res := done ELSE f.res := GetError(writeError) END
  ELSE
    f.res := done
  END
END Flush;

PROCEDURE (f: File) Close*;
  VAR error, ignore: Host.Error; flushResult: Result;
BEGIN
  IF ~f.open THEN
    f.res := GetError(channelClosed);
    RETURN
  END;
  f.Flush;
  flushResult := f.res;
  error := Host.Close(f.handle);
  f.open := FALSE;
  IF f.temporary THEN ignore := Host.Remove(f.tmpName) END;
  IF flushResult # done THEN
    f.res := flushResult
  ELSIF error # 0 THEN
    f.res := GetError(closeError)
  ELSE
    f.res := done
  END
END Close;

PROCEDURE (f: File) Register*;
  VAR error: Host.Error;
BEGIN
  IF ~f.open THEN
    f.res := GetError(channelClosed)
  ELSIF f.temporary THEN
    IF f.anonymous THEN
      f.res := GetError(anonymousFile)
    ELSE
      f.Flush;
      IF f.res = done THEN
        error := Host.Rename(f.tmpName, f.name);
        IF error = 0 THEN
          f.temporary := FALSE;
          f.tmpName := "";
          f.res := done
        ELSE
          f.res := OpenError(error)
        END
      END
    END
  ELSE
    f.res := done
  END
END Register;

PROCEDURE InitFile(f: File; handle: Host.Handle; readable, writable: BOOLEAN);
BEGIN
  f.handle := handle;
  f.res := done;
  f.readable := readable;
  f.writable := writable;
  f.open := TRUE;
  f.name := "";
  f.tmpName := "";
  f.temporary := FALSE;
  f.anonymous := FALSE
END InitFile;

PROCEDURE New* (file: ARRAY OF CHAR; flags: SET; VAR res: Result): File;
  VAR f: File; handle: Host.Handle; name: ARRAY maxPath OF CHAR;
      error: Host.Error; readable, writable: BOOLEAN;
BEGIN
  readable := (read IN flags) OR (tryRead IN flags);
  writable := (write IN flags) OR (tryWrite IN flags);
  IF ~(readable OR writable) THEN
    res := GetError(accessDenied);
    RETURN NIL
  END;
  COPY(file, name);
  error := Host.New(name, handle);
  IF error # 0 THEN
    res := OpenError(error);
    RETURN NIL
  END;
  NEW(f);
  InitFile(f, handle, readable, writable);
  COPY(file, f.name);
  res := done;
  RETURN f
END New;

PROCEDURE Old* (file: ARRAY OF CHAR; flags: SET; VAR res: Result): File;
  VAR
    f: File;
    handle: Host.Handle;
    name: ARRAY maxPath OF CHAR;
    error: Host.Error;
    wantRead, wantWrite, writable: BOOLEAN;
BEGIN
  wantRead := (read IN flags) OR (tryRead IN flags);
  wantWrite := (write IN flags) OR (tryWrite IN flags);
  IF ~(wantRead OR wantWrite) THEN
    res := GetError(accessDenied);
    RETURN NIL
  END;
  COPY(file, name);
  writable := FALSE;
  IF wantWrite THEN
    error := Host.OpenReadWrite(name, handle);
    writable := error = 0
  ELSE
    error := Host.OpenReadOnly(name, handle)
  END;
  IF (error # 0) & wantRead & (tryWrite IN flags) & ~(write IN flags) THEN
    error := Host.OpenReadOnly(name, handle);
    writable := FALSE
  END;
  IF error # 0 THEN
    res := OpenError(error);
    RETURN NIL
  END;
  NEW(f);
  InitFile(f, handle, wantRead, writable);
  COPY(file, f.name);
  res := done;
  RETURN f
END Old;

PROCEDURE MakeTmpName(file: ARRAY OF CHAR; VAR name: ARRAY OF CHAR);
  VAR number: ARRAY 32 OF CHAR;
BEGIN
  IF file # "" THEN
    COPY(file, name)
  ELSE
    Host.CurrentDirectory(name);
    IF (Strings.Length(name) > 0) & (name[Strings.Length(name)-1] # "/") THEN
      Strings.Append("/", name)
    END;
    Strings.Append("ooc", name)
  END;
  Strings.Append(".tmp.", name);
  IntStr.IntToStr(Host.ProcessId(), number);
  Strings.Append(number, name);
  Strings.Append(".", name);
  INC(tmpNumber);
  IntStr.IntToStr(tmpNumber, number);
  Strings.Append(number, name)
END MakeTmpName;

PROCEDURE Tmp* (file: ARRAY OF CHAR; flags: SET; VAR res: Result): File;
  VAR
    f: File;
    handle: Host.Handle;
    name: ARRAY maxPath OF CHAR;
    error: Host.Error;
    readable, writable: BOOLEAN;
BEGIN
  readable := (read IN flags) OR (tryRead IN flags);
  writable := (write IN flags) OR (tryWrite IN flags);
  IF ~(readable OR writable) THEN
    res := GetError(accessDenied);
    RETURN NIL
  END;
  REPEAT
    MakeTmpName(file, name);
    IF Host.Exists(name) THEN error := 0 ELSE error := 1 END
  UNTIL error # 0;
  error := Host.New(name, handle);
  IF error # 0 THEN
    res := OpenError(error);
    RETURN NIL
  END;
  NEW(f);
  InitFile(f, handle, readable, writable);
  COPY(file, f.name);
  COPY(name, f.tmpName);
  f.temporary := TRUE;
  f.anonymous := file = "";
  res := done;
  RETURN f
END Tmp;

PROCEDURE SetModTime* (file: ARRAY OF CHAR; mtime: Time.TimeStamp; VAR res: Result);
BEGIN
  (* The current host interface exposes modification-time queries only. *)
  res := GetError(noModTime)
END SetModTime;

PROCEDURE GetModTime* (file: ARRAY OF CHAR; VAR mtime: Time.TimeStamp; VAR res: Result);
  VAR f: File; closeResult: Result;
BEGIN
  f := Old(file, {read}, res);
  IF f # NIL THEN
    f.GetModTime(mtime);
    res := f.res;
    f.Close;
    closeResult := f.res;
    IF (res = done) & (closeResult # done) THEN res := closeResult END
  END
END GetModTime;

PROCEDURE Exists* (file: ARRAY OF CHAR): BOOLEAN;
  VAR name: ARRAY maxPath OF CHAR;
BEGIN
  COPY(file, name);
  RETURN Host.Exists(name)
END Exists;

BEGIN
  NEW(errorContext);
  Msg.InitContext(errorContext, "OOC:Core:Files");
  tmpNumber := 0
END oocFiles.
