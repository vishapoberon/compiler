(* Synchronous Unix terminal streams backed by Platform termios operations. *)
MODULE ulmUnixTerminals;

IMPORT Heap, SYSTEM, Forwarders := ulmForwarders,
  RelatedEvents := ulmRelatedEvents, Services := ulmServices,
  Streams := ulmStreams, Sys := ulmSys, SysErrors := ulmSysErrors,
  Terminals := ulmTerminals, UnixFiles := ulmUnixFiles, Platform;

TYPE
  Stream = POINTER TO StreamRec;
  StreamRec = RECORD (Terminals.StreamRec)
    instream, outstream: Streams.Stream;
    inputState, outputState: Platform.TerminalState;
    inputHandle, outputHandle: Platform.FileHandle;
    owned: Streams.Stream
  END;

VAR
  streamType: Services.Type;
  streamInterface: Streams.Interface;
  terminalInterface: Terminals.Interface;

PROCEDURE RaiseHostError(s: Streams.Stream; error: Platform.ErrorCode);
BEGIN
  IF error # 0 THEN SysErrors.Raise(s, error, Sys.ioctl, "") END
END RaiseHostError;

PROCEDURE ReadByte(s: Streams.Stream; VAR byte: Streams.Byte): BOOLEAN;
BEGIN
  WITH s: Stream DO RETURN Streams.ReadByte(s.instream, byte) END
END ReadByte;

PROCEDURE WriteByte(s: Streams.Stream; byte: Streams.Byte): BOOLEAN;
BEGIN
  WITH s: Stream DO RETURN Streams.WriteByte(s.outstream, byte) END
END WriteByte;

PROCEDURE Flush(s: Streams.Stream): BOOLEAN;
BEGIN
  WITH s: Stream DO RETURN Streams.Flush(s.outstream) END
END Flush;

PROCEDURE RestoreState(handle: Platform.FileHandle;
                       VAR state: Platform.TerminalState): Platform.ErrorCode;
  VAR error: Platform.ErrorCode;
BEGIN
  IF state = 0 THEN RETURN 0 END;
  REPEAT
    error := Platform.RestoreTerminalState(handle, state)
  UNTIL (error = 0) OR ~Platform.Interrupted(error);
  IF error = 0 THEN Platform.ReleaseTerminalState(state) END;
  RETURN error
END RestoreState;

PROCEDURE Restore(s: Stream; report: BOOLEAN): BOOLEAN;
  VAR ok: BOOLEAN; error: Platform.ErrorCode;
BEGIN
  ok := TRUE;
  error := RestoreState(s.outputHandle, s.outputState);
  IF error # 0 THEN
    IF report THEN RaiseHostError(s, error) END;
    ok := FALSE
  END;
  error := RestoreState(s.inputHandle, s.inputState);
  IF error # 0 THEN
    IF report THEN RaiseHostError(s, error) END;
    ok := FALSE
  END;
  RETURN ok
END Restore;

PROCEDURE Close(s: Streams.Stream): BOOLEAN;
  VAR ok: BOOLEAN;
BEGIN
  WITH s: Stream DO
    ok := Restore(s, TRUE);
    IF ok & (s.owned # NIL) THEN
      ok := Streams.Close(s.owned);
      IF ok THEN s.owned := NIL END
    END;
    RETURN ok
  END
END Close;

PROCEDURE Finalize(object: SYSTEM.PTR);
  VAR s: Stream;
BEGIN
  s := SYSTEM.VAL(Stream, object);
  IF ~Restore(s, FALSE) THEN
    Platform.ReleaseTerminalState(s.outputState);
    Platform.ReleaseTerminalState(s.inputState)
  END;
  IF s.owned # NIL THEN
    IF Streams.Close(s.owned) THEN END;
    s.owned := NIL
  END
END Finalize;

PROCEDURE SetEcho(s: Streams.Stream; mode: Terminals.EchoMode);
  VAR error: Platform.ErrorCode;
BEGIN
  WITH s: Stream DO
    IF s.inputState # 0 THEN
      REPEAT
        error := Platform.SetTerminalEcho(s.inputHandle, mode = Terminals.on)
      UNTIL (error = 0) OR ~Platform.Interrupted(error);
      RaiseHostError(s, error)
    END
  END
END SetEcho;

PROCEDURE SetTermMode(s: Streams.Stream; mode: Terminals.TermMode);
  VAR error: Platform.ErrorCode; raw: BOOLEAN;
BEGIN
  WITH s: Stream DO
    raw := mode = Terminals.raw;
    IF s.inputState # 0 THEN
      REPEAT
        error := Platform.SetTerminalInputMode(s.inputHandle, raw)
      UNTIL (error = 0) OR ~Platform.Interrupted(error);
      RaiseHostError(s, error)
    END;
    IF s.outputState # 0 THEN
      IF ~Streams.Flush(s.outstream) THEN END;
      REPEAT
        error := Platform.SetTerminalOutputMode(s.outputHandle, raw)
      UNTIL (error = 0) OR ~Platform.Interrupted(error);
      RaiseHostError(s, error)
    END
  END
END SetTermMode;

PROCEDURE Open*(VAR s: Streams.Stream; instream, outstream: Streams.Stream;
                 tiname: ARRAY OF CHAR;
                 errors: RelatedEvents.Object): BOOLEAN;
  VAR newterm: Stream; status: Terminals.Status;
      caps: Terminals.CapabilitySet; streamCaps: Streams.CapabilitySet;
      hostError: Platform.ErrorCode;
BEGIN
  IF (instream = NIL) OR (outstream = NIL) THEN RETURN FALSE END;
  streamCaps := Streams.Capabilities(instream);
  IF ~(Streams.read IN streamCaps) THEN RETURN FALSE END;
  streamCaps := Streams.Capabilities(outstream);
  IF ~(Streams.write IN streamCaps) THEN RETURN FALSE END;

  NEW(newterm);
  newterm.instream := instream;
  newterm.outstream := outstream;
  newterm.inputState := 0;
  newterm.outputState := 0;
  newterm.owned := NIL;
  caps := {};

  IF instream IS UnixFiles.Stream THEN
    newterm.inputHandle := instream(UnixFiles.Stream).file;
    IF Platform.IsConsole(newterm.inputHandle) THEN
      hostError := Platform.CaptureTerminalState(newterm.inputHandle,
                                                 newterm.inputState);
      IF hostError # 0 THEN
        SysErrors.Raise(errors, hostError, Sys.ioctl, "");
        RETURN FALSE
      END;
      INCL(caps, Terminals.setEcho);
      INCL(caps, Terminals.setTermMode)
    END
  END;

  IF outstream IS UnixFiles.Stream THEN
    newterm.outputHandle := outstream(UnixFiles.Stream).file;
    IF Platform.IsConsole(newterm.outputHandle) THEN
      hostError := Platform.CaptureTerminalState(newterm.outputHandle,
                                                 newterm.outputState);
      IF hostError # 0 THEN
        IF newterm.inputState # 0 THEN
          Platform.ReleaseTerminalState(newterm.inputState)
        END;
        SysErrors.Raise(errors, hostError, Sys.ioctl, "");
        RETURN FALSE
      END;
      INCL(caps, Terminals.setTermMode)
    END
  END;

  IF caps = {} THEN RETURN FALSE END;

  IF newterm.inputState # 0 THEN
    hostError := Platform.SetTerminalEcho(newterm.inputHandle, TRUE);
    IF hostError = 0 THEN
      hostError := Platform.SetTerminalInputMode(newterm.inputHandle, FALSE)
    END
  ELSE
    hostError := 0
  END;
  IF (hostError = 0) & (newterm.outputState # 0) THEN
    IF Streams.Flush(outstream) THEN
      hostError := Platform.SetTerminalOutputMode(newterm.outputHandle, FALSE)
    ELSE
      IF ~Restore(newterm, FALSE) THEN END;
      RETURN FALSE
    END
  END;
  IF hostError # 0 THEN
    IF ~Restore(newterm, FALSE) THEN END;
    SysErrors.Raise(errors, hostError, Sys.ioctl, "");
    RETURN FALSE
  END;

  status.lines := 24;
  status.columns := 80;
  IF newterm.outputState # 0 THEN
    hostError := Platform.GetTerminalSize(newterm.outputHandle,
                                          status.lines, status.columns)
  ELSE
    hostError := Platform.GetTerminalSize(newterm.inputHandle,
                                          status.lines, status.columns)
  END;
  IF (hostError # 0) OR (status.lines <= 0) OR (status.columns <= 0) THEN
    status.lines := 24;
    status.columns := 80
  END;
  status.scrtop := 0;
  status.scrbottom := status.lines - 1;
  status.echo := Terminals.on;
  status.mode := Terminals.cooked;
  status.characteristics := {};
  status.scrollDirections := {};
  status.cursorShape := Terminals.visible;

  Services.Init(newterm, streamType);
  Streams.Init(newterm, streamInterface,
               {Streams.read, Streams.write, Streams.flush, Streams.close},
               Streams.nobuf);
  Terminals.Init(newterm, status, caps, terminalInterface);
  RelatedEvents.QueueEvents(newterm);
  RelatedEvents.Forward(instream, newterm);
  Forwarders.Forward(newterm, outstream);
  Heap.RegisterFinalizer(newterm, Finalize);
  s := newterm;
  RETURN TRUE
END Open;

PROCEDURE OpenByName*(VAR s: Streams.Stream; devicename, tiname: ARRAY OF CHAR;
                      errors: RelatedEvents.Object): BOOLEAN;
  VAR name: ARRAY 1024 OF CHAR; file: Streams.Stream;
BEGIN
  IF devicename[0] = 0X THEN COPY("/dev/tty", name)
  ELSE COPY(devicename, name)
  END;
  IF ~UnixFiles.Open(file, name, UnixFiles.rdwr, Streams.nobuf, errors) THEN
    RETURN FALSE
  END;
  IF Open(s, file, file, tiname, errors) THEN
    s(Stream).owned := file;
    RETURN TRUE
  END;
  IF ~Streams.Close(file) THEN END;
  RETURN FALSE
END OpenByName;

PROCEDURE InitInterfaces;
BEGIN
  NEW(streamInterface);
  streamInterface.read := ReadByte;
  streamInterface.write := WriteByte;
  streamInterface.flush := Flush;
  streamInterface.close := Close;

  NEW(terminalInterface);
  terminalInterface.setEcho := SetEcho;
  terminalInterface.setTermMode := SetTermMode
END InitInterfaces;

PROCEDURE OpenConsole;
  VAR console, oldout, file: Streams.Stream;
      name, tiname: ARRAY 16 OF CHAR; handle: Platform.FileHandle;
      hostError: Platform.ErrorCode; opened: BOOLEAN;
BEGIN
  oldout := Streams.stdout;
  opened := FALSE;
  IF (Streams.stdin IS UnixFiles.Stream) &
     (Streams.stdout IS UnixFiles.Stream) THEN
    IF Platform.IsConsole(Streams.stdin(UnixFiles.Stream).file) &
       Platform.IsConsole(Streams.stdout(UnixFiles.Stream).file) &
       Platform.SameTerminal(Streams.stdin(UnixFiles.Stream).file,
                             Streams.stdout(UnixFiles.Stream).file) THEN
      opened := Open(console, Streams.stdin, Streams.stdout, "",
                     RelatedEvents.null)
    END
  END;

  IF ~opened THEN
    COPY("/dev/tty", name);
    REPEAT
      hostError := Platform.OpenFile(name, Platform.ReadWrite,
                                     Platform.OpenExisting, handle)
    UNTIL (hostError = 0) OR ~Platform.Interrupted(hostError);
    IF hostError = 0 THEN
      IF UnixFiles.OpenFd(file, handle, UnixFiles.rdwr, Streams.nobuf,
                          RelatedEvents.null) THEN
        IF Open(console, file, file, "", RelatedEvents.null) THEN
          console(Stream).owned := file;
          opened := TRUE
        ELSE
          IF ~Streams.Close(file) THEN END
        END
      ELSE
        IF Platform.Close(handle) # 0 THEN END
      END
    END
  END;

  IF opened THEN
    Terminals.console := console;
    IF oldout IS UnixFiles.Stream THEN
      IF Platform.SameTerminal(oldout(UnixFiles.Stream).file,
                               console(Stream).outputHandle) THEN
        Streams.stdout := console
      END
    END
  END
END OpenConsole;

BEGIN
  Services.CreateType(streamType, "UnixTerminals.Stream", "Terminals.Stream");
  InitInterfaces;
  OpenConsole
END ulmUnixTerminals.
