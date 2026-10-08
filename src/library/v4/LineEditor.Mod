MODULE LineEditor;

  (* Small dependency-free Unix command-line editor. OS handles and directory
     enumeration come from Platform; terminal modes from UnixTermios. *)
  IMPORT SYSTEM, Platform, UnixTermios, Heap;

  CONST MaxLine = 4096; MaxHistory = 64;
  TYPE
    Line = ARRAY MaxLine OF CHAR;
    Completer* = PROCEDURE(prefix: ARRAY OF CHAR);
    Entry = POINTER TO EntryDesc;
    EntryDesc = RECORD next: Entry; name: POINTER TO ARRAY OF CHAR END;
    Guard = POINTER TO GuardDesc;
    GuardDesc = RECORD state: UnixTermios.State END;

  VAR
    complete: Completer;
    candidates: Entry;
    terminal: Guard;
    history: ARRAY MaxHistory OF Line;
    historyCount: INTEGER;
    ioFailed: BOOLEAN;

  PROCEDURE Length(text: ARRAY OF CHAR): INTEGER;
    VAR i: INTEGER;
  BEGIN
    i := 0; WHILE (i < LEN(text)) & (text[i] # 0X) DO INC(i) END;
    RETURN i
  END Length;

  PROCEDURE Append(text: ARRAY OF CHAR; VAR target: ARRAY OF CHAR): BOOLEAN;
    VAR i, j: INTEGER;
  BEGIN
    i := Length(target); j := 0;
    IF i + Length(text) >= LEN(target) THEN RETURN FALSE END;
    WHILE text[j] # 0X DO target[i] := text[j]; INC(i); INC(j) END;
    target[i] := 0X; RETURN TRUE
  END Append;

  PROCEDURE StartsWith(name, prefix: ARRAY OF CHAR): BOOLEAN;
    VAR i: INTEGER;
  BEGIN
    i := 0;
    WHILE prefix[i] # 0X DO
      IF name[i] # prefix[i] THEN RETURN FALSE END;
      INC(i)
    END;
    RETURN TRUE
  END StartsWith;

  PROCEDURE Write(text: ARRAY OF CHAR);
    VAR length, offset, n: LONGINT; error: Platform.ErrorCode;
  BEGIN
    length := Length(text); offset := 0;
    WHILE offset < length DO
      error := Platform.WriteCount(Platform.StdOut, SYSTEM.ADR(text) + offset,
                                   length - offset, n);
      IF (error = 0) & (n > 0) THEN INC(offset, n)
      ELSIF ~Platform.Interrupted(error) THEN ioFailed := TRUE; RETURN
      END
    END
  END Write;

  PROCEDURE WriteChar(ch: CHAR);
    VAR text: ARRAY 2 OF CHAR;
  BEGIN text[0] := ch; text[1] := 0X; Write(text)
  END WriteChar;

  PROCEDURE ReadChar(VAR ch: CHAR): BOOLEAN;
    VAR error: Platform.ErrorCode; count: LONGINT;
  BEGIN
    (* Never read ahead past a command line: commands may themselves read stdin. *)
    REPEAT error := Platform.Read(Platform.StdIn, SYSTEM.ADR(ch), 1, count)
    UNTIL ~Platform.Interrupted(error);
    IF error # 0 THEN ioFailed := TRUE; RETURN FALSE END;
    RETURN count = 1
  END ReadChar;

  PROCEDURE Finalize(obj: SYSTEM.PTR);
    VAR guard: Guard;
  BEGIN guard := SYSTEM.VAL(Guard, obj); UnixTermios.Restore(guard.state)
  END Finalize;

  PROCEDURE Init*(callback: Completer);
  BEGIN
    complete := callback;
    IF terminal = NIL THEN
      NEW(terminal); Heap.RegisterFinalizer(terminal, Finalize)
    END
  END Init;

  PROCEDURE AddCompletion*(name: ARRAY OF CHAR);
    VAR entry, before, after: Entry; length: INTEGER;
  BEGIN
    length := Length(name);
    IF (length = 0) OR (length >= MaxLine) THEN RETURN END;
    before := NIL; after := candidates;
    WHILE (after # NIL) & (after.name^ < name) DO before := after; after := after.next END;
    IF (after # NIL) & (after.name^ = name) THEN RETURN END;
    NEW(entry); NEW(entry.name, length + 1); COPY(name, entry.name^);
    entry.next := after;
    IF before = NIL THEN candidates := entry ELSE before.next := entry END
  END AddCompletion;

  PROCEDURE Paths(prefix: ARRAY OF CHAR);
    VAR typed, directory, name, full, candidate: Line;
      handle: Platform.DirectoryHandle; error, closeError: Platform.ErrorCode;
      i, slash, j: INTEGER; done, ok: BOOLEAN;
  BEGIN
    slash := -1; i := 0;
    WHILE prefix[i] # 0X DO IF prefix[i] = "/" THEN slash := i END; INC(i) END;
    i := 0;
    WHILE i <= slash DO typed[i] := prefix[i]; INC(i) END;
    typed[i] := 0X;
    IF typed[0] = "~" THEN
      IF typed[1] # "/" THEN RETURN END;
      Platform.GetEnv("HOME", directory);
      IF directory = "" THEN RETURN END;
      i := 1; j := Length(directory);
      WHILE typed[i] # 0X DO
        IF j >= LEN(directory) - 1 THEN RETURN END;
        directory[j] := typed[i]; INC(j); INC(i)
      END;
      directory[j] := 0X
    ELSIF typed = "" THEN directory := "./"
    ELSE directory := typed
    END;
    error := Platform.OpenDirectory(directory, handle);
    IF error # 0 THEN RETURN END;
    LOOP
      error := Platform.ReadDirectory(handle, name, done);
      IF done OR (error # 0) THEN EXIT END;
      IF (name # ".") & (name # "..") &
          ((name[0] # ".") OR (prefix[slash + 1] = ".")) THEN
        candidate := typed; ok := Append(name, candidate);
        IF ok & StartsWith(candidate, prefix) THEN
          full := directory; ok := Append(name, full);
          IF ok THEN
            IF Platform.IsDirectory(full) THEN ok := Append("/", candidate) END;
            IF ok THEN AddCompletion(candidate) END
          END
        END
      END
    END;
    closeError := Platform.CloseDirectory(handle)
  END Paths;

  PROCEDURE Insert(ch: CHAR; VAR line: ARRAY OF CHAR; VAR length, cursor: INTEGER);
    VAR i: INTEGER;
  BEGIN
    IF length >= LEN(line) - 1 THEN Write(07X); RETURN END;
    i := length;
    WHILE i >= cursor DO line[i + 1] := line[i]; DEC(i) END;
    line[cursor] := ch; INC(cursor); INC(length)
  END Insert;

  PROCEDURE Redraw(line: ARRAY OF CHAR; cursor: INTEGER);
    VAR i, first, last, width, rows: INTEGER; error: Platform.ErrorCode;
  BEGIN
    width := 80; error := Platform.GetTerminalSize(Platform.StdOut, rows, width);
    IF (error # 0) OR (width < 10) THEN width := 80 END;
    (* A horizontally scrolling display avoids corrupting wrapped input lines. *)
    first := 0;
    IF cursor >= width - 3 THEN first := cursor - width + 4 END;
    last := Length(line);
    IF last > first + width - 3 THEN last := first + width - 3 END;
    Write(0DX); Write(1BX); Write("[2K> ");
    i := first;
    WHILE i < last DO WriteChar(line[i]); INC(i) END;
    WHILE i > cursor DO Write(1BX); Write("[D"); DEC(i) END
  END Redraw;

  PROCEDURE Complete(VAR line: ARRAY OF CHAR; VAR length, cursor: INTEGER);
    VAR prefix: Line; quote, ch: CHAR; first, start, i, j, common, count: INTEGER;
      entry: Entry; isPath, directory, needsQuote: BOOLEAN;
  BEGIN
    IF (cursor < length) & (line[cursor] > " ") THEN Write(07X); RETURN END;
    first := 0; WHILE (first < cursor) & (line[first] <= " ") DO INC(first) END;
    start := first; i := first; quote := 0X; isPath := FALSE;
    WHILE i < cursor DO
      ch := line[i];
      IF quote # 0X THEN
        IF ch = quote THEN quote := 0X END
      ELSIF (ch = '"') OR (ch = "'") THEN quote := ch
      ELSIF ch <= " " THEN start := i + 1; isPath := TRUE
      END;
      INC(i)
    END;
    IF (start < cursor) & ((line[start] = '"') OR (line[start] = "'")) THEN
      quote := line[start]; INC(start)
    END;
    i := start; j := 0;
    WHILE i < cursor DO prefix[j] := line[i]; INC(i); INC(j) END;
    prefix[j] := 0X; candidates := NIL;
    IF isPath THEN Paths(prefix) ELSIF complete # NIL THEN complete(prefix) END;
    IF candidates = NIL THEN Write(07X); RETURN END;
    common := Length(candidates.name^); count := 0; entry := candidates;
    WHILE entry # NIL DO
      INC(count); i := 0;
      WHILE (i < common) & (entry.name[i] = candidates.name[i]) DO INC(i) END;
      common := i; entry := entry.next
    END;
    needsQuote := FALSE;
    IF isPath & (quote = 0X) THEN
      i := 0;
      WHILE i < common DO
        IF candidates.name[i] <= " " THEN needsQuote := TRUE END;
        INC(i)
      END
    END;
    IF length + common - j + 4 > LEN(line) THEN
      Write(07X); candidates := NIL; RETURN
    END;
    IF needsQuote THEN
      i := cursor; cursor := start; Insert('"', line, length, cursor);
      cursor := i + 1; quote := '"'
    END;
    WHILE j < common DO Insert(candidates.name[j], line, length, cursor); INC(j) END;
    IF count = 1 THEN
      directory := isPath & (common > 0) & (candidates.name[common - 1] = "/");
      IF ~directory THEN
        IF quote # 0X THEN Insert(quote, line, length, cursor) END;
        IF isPath OR (candidates.name[common - 1] # ".") THEN
          IF cursor = length THEN Insert(" ", line, length, cursor) END
        END
      END
    ELSE
      Write(Platform.NL); entry := candidates;
      WHILE entry # NIL DO Write(entry.name^); Write(Platform.NL); entry := entry.next END
    END;
    candidates := NIL; Redraw(line, cursor)
  END Complete;

  PROCEDURE Remember(line: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN
    IF line = "" THEN RETURN END;
    IF (historyCount > 0) & (history[historyCount - 1] = line) THEN RETURN END;
    IF historyCount = MaxHistory THEN
      i := 1;
      WHILE i < MaxHistory DO history[i - 1] := history[i]; INC(i) END;
      DEC(historyCount)
    END;
    COPY(line, history[historyCount]); INC(historyCount)
  END Remember;

  PROCEDURE Batch(VAR line: ARRAY OF CHAR): INTEGER;
    VAR ch: CHAR; length: INTEGER; overflow, got: BOOLEAN;
  BEGIN
    length := 0; overflow := FALSE; got := FALSE;
    LOOP
      IF ~ReadChar(ch) THEN EXIT END;
      got := TRUE; IF ch = 0AX THEN EXIT END;
      IF length < LEN(line) - 1 THEN line[length] := ch; INC(length)
      ELSE overflow := TRUE
      END
    END;
    IF (length > 0) & (line[length - 1] = 0DX) THEN DEC(length) END;
    line[length] := 0X;
    IF ioFailed THEN RETURN -2 ELSIF overflow THEN RETURN -1
    ELSIF got THEN RETURN 1 ELSE RETURN 0
    END
  END Batch;

  (* Call Init first; the caller's line must hold 2..MaxLine characters.
     1: line; 0: EOF; -1: oversized batch line; -2: I/O or terminal error.
     Restore cooked mode before the caller executes a command. *)
  PROCEDURE ReadLine*(VAR line: ARRAY OF CHAR): INTEGER;
    VAR ch, key: CHAR; length, cursor, index, status, i: INTEGER;
      saved: Line; error: Platform.ErrorCode;
  BEGIN
    ioFailed := FALSE;
    IF (LEN(line) < 2) OR (LEN(line) > MaxLine) THEN RETURN -2 END;
    IF ~Platform.IsConsole(Platform.StdIn) OR ~Platform.IsConsole(Platform.StdOut) THEN
      RETURN Batch(line)
    END;
    error := UnixTermios.Enter(terminal.state);
    IF error # 0 THEN RETURN -2 END;
    line[0] := 0X; saved := ""; length := 0; cursor := 0; index := historyCount;
    status := 0; Write("> ");
    LOOP
      IF ioFailed OR ~ReadChar(ch) THEN EXIT END;
      IF (ch = 0AX) OR (ch = 0DX) THEN status := 1; Write(Platform.NL); EXIT
      ELSIF ch = 04X THEN
        IF length = 0 THEN Write(Platform.NL); EXIT END
      ELSIF ch = 03X THEN (* Ctrl-C cancels the line, not the shell. *)
        line[0] := 0X; length := 0; cursor := 0; index := historyCount;
        Write("^C"); Write(Platform.NL); Write("> ")
      ELSIF (ch = 08X) OR (ch = 07FX) THEN
        IF cursor > 0 THEN
          i := cursor;
          WHILE i <= length DO line[i - 1] := line[i]; INC(i) END;
          DEC(length); DEC(cursor); Redraw(line, cursor)
        END
      ELSIF ch = 09X THEN Complete(line, length, cursor)
      ELSIF ch = 01X THEN cursor := 0; Redraw(line, cursor)
      ELSIF ch = 05X THEN cursor := length; Redraw(line, cursor)
      ELSIF ch = 15X THEN
        line[0] := 0X; length := 0; cursor := 0; Redraw(line, cursor)
      ELSIF ch = 1BX THEN
        IF ReadChar(key) & ((key = "[") OR (key = "O")) THEN
          IF ReadChar(key) THEN
            IF (key = "A") OR (key = "B") THEN
              IF index = historyCount THEN COPY(line, saved) END;
              IF (key = "A") & (index > 0) THEN DEC(index)
              ELSIF (key = "B") & (index < historyCount) THEN INC(index)
              END;
              IF index = historyCount THEN COPY(saved, line) ELSE COPY(history[index], line) END;
              length := Length(line); cursor := length; Redraw(line, cursor)
            ELSIF (key = "D") & (cursor > 0) THEN DEC(cursor); Redraw(line, cursor)
            ELSIF (key = "C") & (cursor < length) THEN INC(cursor); Redraw(line, cursor)
            ELSIF key = "H" THEN cursor := 0; Redraw(line, cursor)
            ELSIF key = "F" THEN cursor := length; Redraw(line, cursor)
            ELSIF (key >= "1") & (key <= "6") THEN
              ch := key;
              IF ReadChar(key) & (key = "~") THEN
                IF (ch = "3") & (cursor < length) THEN
                  i := cursor;
                  WHILE i < length DO line[i] := line[i + 1]; INC(i) END;
                  DEC(length)
                ELSIF (ch = "1") OR (ch = "4") THEN
                  IF ch = "1" THEN cursor := 0 ELSE cursor := length END
                END;
                Redraw(line, cursor)
              END
            END
          END
        END
      ELSIF ch >= " " THEN Insert(ch, line, length, cursor); Redraw(line, cursor)
      END
    END;
    UnixTermios.Restore(terminal.state);
    IF ioFailed THEN RETURN -2 END;
    IF status = 1 THEN Remember(line) END;
    RETURN status
  END ReadLine;

END LineEditor.
