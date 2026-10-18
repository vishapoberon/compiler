MODULE Oberon;

(* this version should not have dependency on graphics -- noch *)

  IMPORT SYSTEM, Platform, Modules, Heap, Texts, Out;

  TYPE
    ParList* = POINTER TO ParRec;
    ParRec* = RECORD
      (*
      vwr*: Viewers.Viewer;
      frame*: Display.Frame;
      *)
      text*: Texts.Text;
      pos*: LONGINT
    END;
    Cleanup* = PROCEDURE;
    Stop = POINTER TO StopDesc;
    StopDesc = RECORD next: Stop; cleanup: Cleanup; retention: Modules.Retention END;

  VAR
    Log*:        Texts.Text;
    Par*:        ParList;      (*actual parameters*)
    OptionChar*: CHAR;
    stops: Stop;

    R: Texts.Reader;
    W: Texts.Writer;

  (*clocks*)

PROCEDURE GetClock* (VAR t, d: LONGINT);
BEGIN Platform.GetClock(t, d)
END GetClock;

PROCEDURE Time* (): LONGINT;
BEGIN RETURN Platform.Time()
END Time;

(* Persistent, idempotent command-stop cleanup, as used by console tools.
   The host calls Stopped in normal execution, never from its signal handler. *)
PROCEDURE -CleanupAddress(cleanup: Cleanup): SYSTEM.ADDRESS "(ADDRESS)cleanup";
PROCEDURE -DetachAddress(handler: Heap.UnloadHandler): SYSTEM.ADDRESS "(ADDRESS)handler";

PROCEDURE OnStop*(cleanup: Cleanup);
  VAR s, previous: Stop; owner: Modules.Module;
BEGIN
  IF cleanup = NIL THEN RETURN END;
  owner := Heap.ProcedureModule(CleanupAddress(cleanup));
  IF (owner # NIL) & (Heap.ModuleState(owner) > 2) THEN RETURN END;
  Platform.CommandCritical(TRUE);
  s := stops; previous := NIL;
  WHILE (s # NIL) & (s.cleanup # cleanup) DO previous := s; s := s.next END;
  IF s = NIL THEN
    NEW(s); s.cleanup := cleanup;
    IF previous = NIL THEN stops := s ELSE previous.next := s END
  END;
  Platform.CommandCritical(FALSE)
END OnStop;

PROCEDURE Stopped*;
  VAR saved, s: Stop; cleanup: Cleanup; owner: Modules.Module; released: BOOLEAN;
BEGIN
  Platform.CommandCritical(TRUE);
  saved := stops; stops := NIL;
  (* A callback may request freeing a different module. Protect all callbacks
     in this detached snapshot until they have been called and reinstalled. *)
  s := saved;
  WHILE s # NIL DO
    owner := Heap.ProcedureModule(CleanupAddress(s.cleanup));
    s.retention := Heap.RetainModule(owner); s := s.next
  END;
  s := saved;
  WHILE s # NIL DO cleanup := s.cleanup; cleanup; s := s.next END;
  s := saved;
  WHILE s # NIL DO OnStop(s.cleanup); s := s.next END;
  s := saved;
  WHILE s # NIL DO
    IF s.retention # NIL THEN released := Heap.ReleaseModule(s.retention); s.retention := NIL END;
    s := s.next
  END;
  Platform.CommandCritical(FALSE)
END Stopped;

PROCEDURE RemoveStop*(cleanup: Cleanup);
  VAR s, previous: Stop;
BEGIN
  Platform.CommandCritical(TRUE);
  s := stops; previous := NIL;
  WHILE (s # NIL) & (s.cleanup # cleanup) DO previous := s; s := s.next END;
  IF s # NIL THEN
    IF previous = NIL THEN stops := s.next ELSE previous.next := s.next END
  END;
  Platform.CommandCritical(FALSE)
END RemoveStop;

PROCEDURE DetachStops(owner: Modules.Module);
  VAR s: Stop; cleanup: Cleanup;
BEGIN
  (* A successful unload is another cleanup boundary, but unlike a command
     stop its callbacks must not be installed again afterward. *)
  s := stops;
  WHILE s # NIL DO
    IF Heap.ProcedureModule(CleanupAddress(s.cleanup)) = owner THEN
      cleanup := s.cleanup; RemoveStop(cleanup); cleanup;
      s := stops
    ELSE s := s.next END
  END
END DetachStops;

PROCEDURE PopulateParams;
  VAR W: Texts.Writer; i: INTEGER; str: ARRAY 256 OF CHAR;
BEGIN
  Texts.OpenWriter(W);
  i := 1; (* skip program name *)
  WHILE i < Modules.ArgCount DO
    Modules.GetArg(i, str); Texts.WriteString(W, str); Texts.Write(W, " ");
    INC(i)
  END;
  Texts.Append(Par^.text, W.buf);
END PopulateParams;

PROCEDURE GetSelection*(VAR text: Texts.Text; VAR beg, end, time: LONGINT);
BEGIN text := NIL; beg := 0; end := 0; time := 0
END GetSelection;

(* --- Notifier for echoing to the comsole all text appended to the log. --- *)
PROCEDURE LogNotifier(Log: Texts.Text; op: INTEGER; beg, end: LONGINT);
  VAR ch: CHAR;
BEGIN
  Texts.OpenReader(R, Log, beg);
  WHILE ~R.eot & (beg < end) DO
    Texts.Read(R, ch);
    IF ch = 0DX THEN Out.Ln ELSE Out.Char(ch) END;
    INC(beg)
  END
END LogNotifier;

BEGIN
   NEW(Par);
   NEW(Par.text);
   Par.pos := 0;
   OptionChar := '-';
   Texts.Open(Par.text, "");
   PopulateParams;
   NEW(Log);
   Texts.Open(Log, "");
    Log.notify := LogNotifier;
    (* Conventional builds have no procedure ownership metadata. *)
    IF Heap.ProcedureModule(DetachAddress(DetachStops)) # NIL THEN
      ASSERT(Heap.RegisterUnloadHook(DetachStops))
    END;
END Oberon.
