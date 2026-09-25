(* Basic terminal abstraction from Ulm's Oberon Library. *)
MODULE ulmTerminals;

IMPORT Events := ulmEvents, Objects := ulmObjects, Priorities := ulmPriorities,
  RelatedEvents := ulmRelatedEvents, Services := ulmServices,
  Streams := ulmStreams;

CONST
  autoleftmargin* = 0;
  autorightmargin* = 1;
  overstrikes* = 2;
  safelastcolumn* = 3;

  cannotSetEcho* = 0;
  cannotSetTermMode* = 1;
  cannotSetCursor* = 2;
  cannotMoveCursor* = 3;
  cannotSetAppearance* = 4;
  cannotScroll* = 5;
  cannotSetScrollRegion* = 6;
  cannotClearScreen* = 7;
  invalidDirection* = 8;
  invalidRegion* = 9;
  invalidPosition* = 10;
  notSupported* = 11;
  errorcodes* = 12;

  on* = 0;
  off* = 1;
  raw* = 0;
  cooked* = 1;
  forward* = 0;
  reverse* = 1;
  visible* = 0;
  invisible* = 1;

  setEcho* = 0;
  setTermMode* = 1;
  setCursor* = 2;
  moveCursor* = 3;
  setAppearance* = 4;
  scroll* = 5;
  setScrollRegion* = 6;
  clearScreen* = 7;

TYPE
  CapabilitySet* = SET;
  EchoMode* = SHORTINT;
  TermMode* = SHORTINT;
  Direction* = SHORTINT;
  Shape* = SHORTINT;
  Stream* = POINTER TO StreamRec;

  WindowChangeEvent* = POINTER TO WindowChangeEventRec;
  WindowChangeEventRec* = RECORD (Events.EventRec)
    stream*: Streams.Stream;
    newlines*, newcolumns*: INTEGER
  END;

  InterruptEvent* = POINTER TO InterruptEventRec;
  InterruptEventRec* = RECORD (Events.EventRec)
    stream*: Streams.Stream
  END;

  QuitEvent* = POINTER TO QuitEventRec;
  QuitEventRec* = RECORD (Events.EventRec)
    stream*: Streams.Stream
  END;

  HangupEvent* = POINTER TO HangupEventRec;
  HangupEventRec* = RECORD (Events.EventRec)
    stream*: Streams.Stream
  END;

  ErrorEvent* = POINTER TO ErrorEventRec;
  ErrorEventRec* = RECORD (Events.EventRec)
    errorcode*: SHORTINT
  END;

  SetTermModeProc* = PROCEDURE(s: Streams.Stream; mode: TermMode);
  SetEchoProc* = PROCEDURE(s: Streams.Stream; mode: EchoMode);
  SetCursorProc* = PROCEDURE(s: Streams.Stream; line, column: INTEGER);
  MoveCursorProc* = PROCEDURE(s: Streams.Stream; fromline, fromcolumn,
                              toline, tocolumn: INTEGER);
  SetAppearanceProc* = PROCEDURE(s: Streams.Stream; shape: Shape);
  ScrollProc* = PROCEDURE(s: Streams.Stream; dir: Direction);
  SetScrollRegionProc* = PROCEDURE(s: Streams.Stream; top, bottom: INTEGER);
  ClearProc* = PROCEDURE(s: Streams.Stream);

  Interface* = POINTER TO InterfaceRec;
  InterfaceRec* = RECORD (Objects.ObjectRec)
    setEcho*: SetEchoProc;
    setTermMode*: SetTermModeProc;
    setCursor*: SetCursorProc;
    moveCursor*: MoveCursorProc;
    setAppearance*: SetAppearanceProc;
    scroll*: ScrollProc;
    setScrollRegion*: SetScrollRegionProc;
    clearScreen*: ClearProc
  END;

  Status* = RECORD (Objects.ObjectRec)
    lines*, columns*: INTEGER;
    scrtop*, scrbottom*: INTEGER;
    echo*: EchoMode;
    mode*: TermMode;
    characteristics*: SET;
    scrollDirections*: SET;
    cursorShape*: Shape
  END;

  StreamRec* = RECORD (Streams.StreamRec)
    status: Status;
    caps: CapabilitySet;
    interface: Interface
  END;

VAR
  console*: Streams.Stream;
  windowchanged*, interrupt*, quit*, hangup*: Events.EventType;
  error*: Events.EventType;
  errormsg*: ARRAY errorcodes OF Events.Message;
  terminaltype: Services.Type;

PROCEDURE Error(object: RelatedEvents.Object; errorcode: SHORTINT);
  VAR event: ErrorEvent;
BEGIN
  NEW(event);
  event.type := error;
  event.message := errormsg[errorcode];
  event.errorcode := errorcode;
  RelatedEvents.Raise(object, event)
END Error;

PROCEDURE Init*(s: Stream; status: Status; caps: CapabilitySet;
                interface: Interface);
BEGIN
  ASSERT(interface # NIL);
  s.status := status;
  s.caps := caps;
  s.interface := interface
END Init;

PROCEDURE SetScreenSize(event: Events.Event);
BEGIN
  WITH event: WindowChangeEvent DO
    event.stream(Stream).status.lines := event.newlines;
    event.stream(Stream).status.columns := event.newcolumns
  END
END SetScreenSize;

PROCEDURE ClearScreen*(s: Streams.Stream);
BEGIN
  WITH s: Stream DO
    IF clearScreen IN s.caps THEN s.interface.clearScreen(s)
    ELSE Error(s, cannotClearScreen)
    END
  END
END ClearScreen;

PROCEDURE Echo*(s: Streams.Stream; mode: EchoMode);
BEGIN
  WITH s: Stream DO
    IF s.status.echo # mode THEN
      IF setEcho IN s.caps THEN
        s.interface.setEcho(s, mode);
        s.status.echo := mode
      ELSE
        Error(s, cannotSetEcho)
      END
    END
  END
END Echo;

PROCEDURE SetTermMode*(s: Streams.Stream; mode: TermMode);
BEGIN
  WITH s: Stream DO
    IF s.status.mode # mode THEN
      IF setTermMode IN s.caps THEN
        s.interface.setTermMode(s, mode);
        s.status.mode := mode
      ELSE
        Error(s, cannotSetTermMode)
      END
    END
  END
END SetTermMode;

PROCEDURE SetCursor*(s: Streams.Stream; line, column: INTEGER);
BEGIN
  WITH s: Stream DO
    IF (line >= 0) & (line < s.status.lines) &
       (column >= 0) & (column < s.status.columns) THEN
      IF setCursor IN s.caps THEN s.interface.setCursor(s, line, column)
      ELSE Error(s, cannotSetCursor)
      END
    ELSE
      Error(s, invalidPosition)
    END
  END
END SetCursor;

PROCEDURE MoveCursor*(s: Streams.Stream; fromline, fromcolumn,
                      toline, tocolumn: INTEGER);
BEGIN
  WITH s: Stream DO
    IF (fromline >= 0) & (fromline < s.status.lines) &
       (toline >= 0) & (toline < s.status.lines) &
       (fromcolumn >= 0) & (fromcolumn <= s.status.columns) &
       (tocolumn >= 0) & (tocolumn < s.status.columns) THEN
      IF moveCursor IN s.caps THEN
        s.interface.moveCursor(s, fromline, fromcolumn, toline, tocolumn)
      ELSIF setCursor IN s.caps THEN
        s.interface.setCursor(s, toline, tocolumn)
      ELSE
        Error(s, cannotMoveCursor)
      END
    ELSE
      Error(s, invalidPosition)
    END
  END
END MoveCursor;

PROCEDURE CursorAppearance*(s: Streams.Stream; shape: Shape);
BEGIN
  WITH s: Stream DO
    IF shape # s.status.cursorShape THEN
      IF setAppearance IN s.caps THEN
        s.interface.setAppearance(s, shape);
        s.status.cursorShape := shape
      ELSE
        Error(s, cannotSetAppearance)
      END
    END
  END
END CursorAppearance;

PROCEDURE Scroll*(s: Streams.Stream; dir: Direction);
BEGIN
  WITH s: Stream DO
    IF dir IN s.status.scrollDirections THEN
      IF scroll IN s.caps THEN s.interface.scroll(s, dir)
      ELSE Error(s, cannotScroll)
      END
    ELSE
      Error(s, invalidDirection)
    END
  END
END Scroll;

PROCEDURE SetScrollRegion*(s: Streams.Stream; top, bottom: INTEGER);
BEGIN
  WITH s: Stream DO
    IF (top >= 0) & (top < s.status.lines) &
       (bottom >= 0) & (bottom < s.status.lines) & (top < bottom) THEN
      IF setScrollRegion IN s.caps THEN
        s.interface.setScrollRegion(s, top, bottom);
        s.status.scrtop := top;
        s.status.scrbottom := bottom;
        IF setCursor IN s.caps THEN SetCursor(s, bottom, 0) END
      ELSE
        Error(s, cannotSetScrollRegion)
      END
    ELSE
      Error(s, invalidRegion)
    END
  END
END SetScrollRegion;

PROCEDURE Capabilities*(s: Streams.Stream): CapabilitySet;
BEGIN
  WITH s: Stream DO RETURN s.caps END
END Capabilities;

PROCEDURE GetStatus*(s: Streams.Stream; VAR status: Status);
BEGIN
  WITH s: Stream DO status := s.status END
END GetStatus;

BEGIN
  Services.CreateType(terminaltype, "Terminals.Stream", "Streams.Stream");

  Events.Define(error);
  Events.SetPriority(error, Priorities.liberrors);
  errormsg[cannotSetEcho] := "cannot change echo mode";
  errormsg[cannotSetTermMode] := "cannot change terminal mode";
  errormsg[cannotSetCursor] := "cannot set cursor";
  errormsg[cannotMoveCursor] := "cannot move cursor";
  errormsg[cannotSetAppearance] := "cannot change appearance of cursor";
  errormsg[cannotScroll] := "terminal cannot scroll";
  errormsg[cannotSetScrollRegion] := "scroll regions not supported by terminal";
  errormsg[cannotClearScreen] := "cannot clear screen";
  errormsg[invalidDirection] := "direction not valid";
  errormsg[invalidPosition] := "cursor coordinates not valid";
  errormsg[invalidRegion] := "parameters for scroll region not valid";
  errormsg[notSupported] :=
    "module Terminals not supported by underlying stream implementation";

  Events.Define(windowchanged);
  Events.Define(interrupt);
  Events.Define(quit);
  Events.Define(hangup);
  Events.SetPriority(windowchanged, Priorities.interrupts);
  Events.SetPriority(interrupt, Priorities.interrupts);
  Events.SetPriority(quit, Priorities.interrupts);
  Events.SetPriority(hangup, Priorities.interrupts);
  Events.Handler(windowchanged, SetScreenSize);
  console := NIL
END ulmTerminals.
