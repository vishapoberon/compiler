(* Platform-backed port of Ulm's UnixFiles stream module. *)
MODULE ulmUnixFiles;

IMPORT Events := ulmEvents, Priorities := ulmPriorities,
  RelatedEvents := ulmRelatedEvents, Services := ulmServices,
  Streams := ulmStreams, Sys := ulmSys, SysErrors := ulmSysErrors,
  SysIO := ulmSysIO, SysStat := ulmSysStat, SysTypes := ulmSysTypes,
  Platform, SYSTEM;

CONST
  illegalMode* = 0;
  invalidFd* = 1;
  errorcodes* = 2;

  read* = 0;
  write* = 1;
  rdwr* = 2;
  create* = 4;
  condcreate* = 8;

TYPE
  ErrorCode* = SHORTINT;
  ErrorEvent* = POINTER TO ErrorEventRec;
  ErrorEventRec* = RECORD (Events.EventRec)
    errorcode*: ErrorCode
  END;

  Mode* = SHORTINT;
  Stream* = POINTER TO StreamRec;
  StreamRec* = RECORD (Streams.StreamRec)
    file*: SysTypes.File;
    interrupted*: BOOLEAN;
    retry*: BOOLEAN
  END;

VAR
  error*: Events.EventType;
  errormsg*: ARRAY errorcodes OF Events.Message;
  interface: Streams.Interface;
  type: Services.Type;

PROCEDURE Error(errors: RelatedEvents.Object; errorcode: ErrorCode);
  VAR event: ErrorEvent;
BEGIN
  NEW(event);
  event.type := error;
  event.message := errormsg[errorcode];
  event.errorcode := errorcode;
  RelatedEvents.Raise(errors, event)
END Error;

PROCEDURE ReadBuf(s: Streams.Stream; address: SysTypes.Address;
                  count: SysTypes.Count): SysTypes.Count;
BEGIN
  WITH s: Stream DO
    RETURN SysIO.Read(s.file, address, count, s, s.retry, s.interrupted)
  END
END ReadBuf;

PROCEDURE WriteBuf(s: Streams.Stream; address: SysTypes.Address;
                   count: SysTypes.Count): SysTypes.Count;
BEGIN
  WITH s: Stream DO
    RETURN SysIO.Write(s.file, address, count, s, s.retry, s.interrupted)
  END
END WriteBuf;

PROCEDURE ReadByte(s: Streams.Stream; VAR byte: Streams.Byte): BOOLEAN;
  VAR count: SysTypes.Count;
BEGIN
  WITH s: Stream DO
    count := SysIO.Read(s.file, SYSTEM.ADR(byte), 1, s,
                        s.retry, s.interrupted);
    RETURN count = 1
  END
END ReadByte;

PROCEDURE WriteByte(s: Streams.Stream; byte: Streams.Byte): BOOLEAN;
  VAR count: SysTypes.Count;
BEGIN
  WITH s: Stream DO
    count := SysIO.Write(s.file, SYSTEM.ADR(byte), 1, s,
                         s.retry, s.interrupted);
    RETURN count = 1
  END
END WriteByte;

PROCEDURE Seek(s: Streams.Stream; offset: SysTypes.Count;
               whence: Streams.Whence): BOOLEAN;
BEGIN
  WITH s: Stream DO
    RETURN SysIO.Seek(s.file, offset, whence, s)
  END
END Seek;

PROCEDURE Tell(s: Streams.Stream; VAR offset: SysTypes.Count): BOOLEAN;
BEGIN
  WITH s: Stream DO
    RETURN SysIO.Tell(s.file, offset, s)
  END
END Tell;

PROCEDURE Close(s: Streams.Stream): BOOLEAN;
BEGIN
  WITH s: Stream DO
    RETURN SysIO.Close(s.file, s, FALSE, s.interrupted)
  END
END Close;

PROCEDURE OpenFd*(VAR s: Streams.Stream; fd: SysTypes.File;
                  mode: Mode; bufmode: Streams.BufMode;
                  errors: RelatedEvents.Object): BOOLEAN;
  VAR caps: Streams.CapabilitySet; newfile: Stream; stat: SysStat.StatRec;
BEGIN
  IF ~SysStat.Fstat(fd, stat, errors) THEN
    Error(errors, invalidFd);
    RETURN FALSE
  END;

  caps := {Streams.addrio, Streams.close};
  CASE mode OF
  | read: INCL(caps, Streams.read)
  | write: INCL(caps, Streams.write)
  | rdwr: caps := caps + {Streams.read, Streams.write}
  ELSE
    Error(errors, illegalMode);
    RETURN FALSE
  END;

  IF SysIO.Seekable(fd) THEN
    caps := caps + {Streams.seek, Streams.tell, Streams.holes}
  END;

  NEW(newfile);
  Services.Init(newfile, type);
  Streams.Init(newfile, interface, caps, bufmode);
  newfile.file := fd;
  newfile.interrupted := FALSE;
  newfile.retry := TRUE;
  RelatedEvents.QueueEvents(newfile);
  s := newfile;
  RETURN TRUE
END OpenFd;

PROCEDURE Open*(VAR s: Streams.Stream; filename: ARRAY OF CHAR;
                mode: Mode; bufmode: Streams.BufMode;
                errors: RelatedEvents.Object): BOOLEAN;
  CONST accessMask = 4;
  VAR accessMode, openMode: Mode; access, creation: INTEGER;
      fd: SysTypes.File; interrupted: BOOLEAN; hostError: Platform.ErrorCode;
BEGIN
  accessMode := mode MOD accessMask;
  openMode := mode - accessMode;

  CASE accessMode OF
  | read: access := Platform.ReadOnly
  | write: access := Platform.WriteOnly
  | rdwr: access := Platform.ReadWrite
  ELSE
    Error(errors, illegalMode);
    RETURN FALSE
  END;

  CASE openMode OF
  | 0: creation := Platform.OpenExisting
  | create: creation := Platform.CreateAlways
  | condcreate: creation := Platform.OpenAlways
  ELSE
    Error(errors, illegalMode);
    RETURN FALSE
  END;

  filename[LEN(filename)-1] := 0X;
  REPEAT
    hostError := Platform.OpenFile(filename, access, creation, fd)
  UNTIL (hostError = 0) OR ~Platform.Interrupted(hostError);
  IF hostError # 0 THEN
    SysErrors.Raise(errors, hostError, Sys.open, filename);
    RETURN FALSE
  END;

  IF OpenFd(s, fd, accessMode, bufmode, errors) THEN
    RETURN TRUE
  END;
  IF ~SysIO.Close(fd, errors, FALSE, interrupted) THEN END;
  RETURN FALSE
END Open;

PROCEDURE InitInterface;
BEGIN
  NEW(interface);
  interface.addrread := ReadBuf;
  interface.addrwrite := WriteBuf;
  interface.read := ReadByte;
  interface.write := WriteByte;
  interface.seek := Seek;
  interface.tell := Tell;
  interface.close := Close
END InitInterface;

PROCEDURE InitStandardStreams;
  PROCEDURE Connect(VAR stream: Streams.Stream; fd: SysTypes.File; mode: Mode);
    VAR bufmode: Streams.BufMode;
  BEGIN
    IF fd = SysIO.StdErr() THEN
      bufmode := Streams.nobuf
    ELSIF SysIO.Isatty(fd) THEN
      bufmode := Streams.linebuf
    ELSIF fd = SysIO.StdOut() THEN
      (* ULM process termination is not wired into VOC program shutdown. *)
      bufmode := Streams.nobuf
    ELSE
      bufmode := Streams.onebuf
    END;
    IF ~OpenFd(stream, fd, mode, bufmode, NIL) THEN END
  END Connect;
BEGIN
  Connect(Streams.stdin, SysIO.StdIn(), rdwr);
  Connect(Streams.stdout, SysIO.StdOut(), rdwr);
  Connect(Streams.stderr, SysIO.StdErr(), write);
  IF (Streams.GetBufMode(Streams.stdin) = Streams.linebuf) &
     (Streams.GetBufMode(Streams.stdout) = Streams.linebuf) THEN
    Streams.Tie(Streams.stdin, Streams.stdout)
  END
END InitStandardStreams;

BEGIN
  errormsg[illegalMode] := "illegal opening mode";
  errormsg[invalidFd] := "invalid file descriptor";
  Events.Define(error);
  Events.SetPriority(error, Priorities.liberrors);
  InitInterface;
  Services.CreateType(type, "UnixFiles.Stream", "Streams.Stream");
  InitStandardStreams
END ulmUnixFiles.
