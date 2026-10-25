MODULE XMLLimits;

IMPORT SYSTEM, Channel, Msg, LongStrings;

CONST
  codeBase* = 1000;
  (**A resource diagnostic's code is codeBase plus its limit kind. *)
  inputBytes* = 1;
  nesting* = 2;
  entityExpansions* = 3;
  expandedUnits* = 4;
  work* = 5;
  attributeUnits* = 6;
  modelParticles* = 7;
  outputBytes* = 8;

TYPE
  Budget* = POINTER TO BudgetDesc;
  BudgetDesc* = RECORD
    (**Per-parse resource counters. Set maxima before constructing the parser;
       a negative maximum disables that limit. An exhausted budget stays failed. *)
    maxInputBytes*, maxNesting*, maxEntityExpansions*, maxExpandedUnits*,
      maxWork*, maxAttributeUnits*, maxModelParticles*, maxOutputBytes*: LONGINT;
    bytesRead-, bytesWritten-, depth-, expansions-, units-, steps-: LONGINT;
    error-: Msg.Msg;
  END;
  Reader = POINTER TO ReaderDesc;
  ReaderDesc = RECORD (Channel.ReaderDesc)
    inner: Channel.Reader;
    budget: Budget;
  END;
  Writer = POINTER TO WriterDesc;
  WriterDesc = RECORD (Channel.WriterDesc)
    inner: Channel.Writer;
    budget: Budget;
  END;
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (context: Context) GetTemplate(message: Msg.Msg; VAR template: Msg.LString);
  VAR text: ARRAY 80 OF CHAR;
BEGIN
  CASE message.code-codeBase OF
  | inputBytes: text := "XML input byte limit exceeded"
  | nesting: text := "XML nesting limit exceeded"
  | entityExpansions: text := "XML entity expansion count limit exceeded"
  | expandedUnits: text := "XML expanded code-unit limit exceeded"
  | work: text := "XML processing work limit exceeded"
  | attributeUnits: text := "XML attribute value code-unit limit exceeded"
  | modelParticles: text := "XML content-model particle limit exceeded"
  | outputBytes: text := "XML output byte limit exceeded"
  ELSE text := "XML resource limit exceeded"
  END;
  LongStrings.Long(text, template)
END GetTemplate;

PROCEDURE (budget: Budget) Fail* (kind: SHORTINT);
BEGIN
  IF budget.error = NIL THEN budget.error := Msg.New(context, kind+codeBase) END
END Fail;

PROCEDURE Take(budget: Budget; kind: SHORTINT; n, maximum: LONGINT; VAR used: LONGINT): BOOLEAN;
BEGIN
  ASSERT(n >= 0);
  IF budget.error # NIL THEN RETURN FALSE END;
  IF (n > MAX(LONGINT)-used) OR ((maximum >= 0) & ((used > maximum) OR (n > maximum-used))) THEN
    budget.Fail(kind); RETURN FALSE
  END;
  INC(used, n); RETURN TRUE
END Take;

PROCEDURE (budget: Budget) Charge* (kind: SHORTINT; n: LONGINT): BOOLEAN;
BEGIN
  CASE kind OF
  | inputBytes: RETURN Take(budget, kind, n, budget.maxInputBytes, budget.bytesRead)
  | entityExpansions: RETURN Take(budget, kind, n, budget.maxEntityExpansions, budget.expansions)
  | expandedUnits: RETURN Take(budget, kind, n, budget.maxExpandedUnits, budget.units)
  | work: RETURN Take(budget, kind, n, budget.maxWork, budget.steps)
  | outputBytes: RETURN Take(budget, kind, n, budget.maxOutputBytes, budget.bytesWritten)
  ELSE RETURN FALSE
  END;
  RETURN FALSE
END Charge;

PROCEDURE (budget: Budget) Enter* (): BOOLEAN;
BEGIN RETURN Take(budget, nesting, 1, budget.maxNesting, budget.depth) END Enter;

PROCEDURE (budget: Budget) Leave*;
BEGIN ASSERT(budget.depth > 0); DEC(budget.depth) END Leave;

PROCEDURE New* (): Budget;
  VAR budget: Budget;
BEGIN
  NEW(budget);
  budget.maxInputBytes := 16*1024*1024; budget.maxNesting := 128;
  budget.maxEntityExpansions := 10000; budget.maxExpandedUnits := 16*1024*1024;
  budget.maxWork := 100000; budget.maxAttributeUnits := 1024*1024;
  budget.maxModelParticles := 256;
  budget.maxOutputBytes := 16*1024*1024;
  budget.bytesWritten := 0;
  budget.bytesRead := 0; budget.depth := 0; budget.expansions := 0;
  budget.units := 0; budget.steps := 0; budget.error := NIL;
  RETURN budget
END New;

PROCEDURE (reader: Reader) ReadBytes(VAR bytes: ARRAY OF SYSTEM.BYTE; start, n: LONGINT);
  VAR available, count: LONGINT; probe: ARRAY 1 OF SYSTEM.BYTE; accepted: BOOLEAN;
BEGIN
  ASSERT((start >= 0) & (start <= LEN(bytes)) & (n >= 0) & (n <= LEN(bytes)-start));
  reader.bytesRead := 0;
  IF reader.res # NIL THEN RETURN END;
  IF reader.budget.error # NIL THEN reader.res := reader.budget.error; RETURN END;
  IF n = 0 THEN RETURN END;
  available := n;
  IF reader.budget.maxInputBytes >= 0 THEN
    available := reader.budget.maxInputBytes-reader.budget.bytesRead;
    IF available < 0 THEN available := 0 END;
    IF available > n THEN available := n END
  END;
  IF available = 0 THEN
    (* A single probe distinguishes an exact-size input from an overrun. *)
    reader.inner.ReadBytes(probe, 0, 1);
    IF reader.inner.bytesRead # 0 THEN
      reader.budget.Fail(inputBytes); reader.res := reader.budget.error
    ELSE reader.res := reader.inner.res
    END
  ELSE
    reader.inner.ReadBytes(bytes, start, available);
    count := reader.inner.bytesRead;
    ASSERT((count >= 0) & (count <= available));
    accepted := reader.budget.Charge(inputBytes, count);
    IF accepted THEN reader.bytesRead := count; reader.res := reader.inner.res
    ELSE reader.res := reader.budget.error
    END
  END
END ReadBytes;

PROCEDURE (reader: Reader) ReadByte(VAR byte: SYSTEM.BYTE);
  VAR bytes: ARRAY 1 OF SYSTEM.BYTE;
BEGIN
  reader.ReadBytes(bytes, 0, 1);
  IF reader.bytesRead = 1 THEN byte := bytes[0] END
END ReadByte;

PROCEDURE (reader: Reader) Pos(): LONGINT;
BEGIN RETURN reader.inner.Pos() END Pos;

PROCEDURE (reader: Reader) Available(): LONGINT;
  VAR n, remaining: LONGINT;
BEGIN
  IF reader.budget.error # NIL THEN RETURN -1 END;
  n := reader.inner.Available();
  IF reader.budget.maxInputBytes >= 0 THEN
    remaining := reader.budget.maxInputBytes-reader.budget.bytesRead;
    IF (n > remaining) & (remaining >= 0) THEN n := remaining END
  END;
  RETURN n
END Available;

PROCEDURE Wrap* (reader: Channel.Reader; budget: Budget): Channel.Reader;
  VAR limited: Reader;
BEGIN
  IF budget = NIL THEN RETURN reader END;
  NEW(limited); limited.base := reader.base; limited.res := reader.res;
  limited.bytesRead := 0; limited.positionable := FALSE;
  limited.inner := reader; limited.budget := budget;
  RETURN limited
END Wrap;

PROCEDURE (writer: Writer) WriteBytes(VAR bytes: ARRAY OF SYSTEM.BYTE; start, n: LONGINT);
  VAR available: LONGINT; accepted: BOOLEAN;
BEGIN
  ASSERT((start >= 0) & (start <= LEN(bytes)) & (n >= 0) & (n <= LEN(bytes)-start));
  writer.bytesWritten := 0;
  IF writer.res # NIL THEN RETURN END;
  IF writer.budget.error # NIL THEN writer.res := writer.budget.error; RETURN END;
  IF n = 0 THEN RETURN END;
  available := n;
  IF writer.budget.maxOutputBytes >= 0 THEN
    available := writer.budget.maxOutputBytes-writer.budget.bytesWritten;
    IF available < 0 THEN available := 0 END;
    IF available > n THEN available := n END
  END;
  IF available = 0 THEN
    writer.budget.Fail(outputBytes); writer.res := writer.budget.error; RETURN
  END;
  writer.inner.WriteBytes(bytes, start, available);
  ASSERT((writer.inner.bytesWritten >= 0) & (writer.inner.bytesWritten <= available));
  accepted := writer.budget.Charge(outputBytes, writer.inner.bytesWritten);
  IF accepted THEN writer.bytesWritten := writer.inner.bytesWritten; writer.res := writer.inner.res
  ELSE writer.res := writer.budget.error
  END
END WriteBytes;

PROCEDURE (writer: Writer) WriteByte(byte: SYSTEM.BYTE);
  VAR bytes: ARRAY 1 OF SYSTEM.BYTE;
BEGIN bytes[0] := byte; writer.WriteBytes(bytes, 0, 1) END WriteByte;

PROCEDURE (writer: Writer) Pos(): LONGINT;
BEGIN RETURN writer.inner.Pos() END Pos;

PROCEDURE WrapWriter* (writer: Channel.Writer; budget: Budget): Channel.Writer;
  VAR limited: Writer;
BEGIN
  IF budget = NIL THEN RETURN writer END;
  NEW(limited); limited.base := writer.base; limited.res := writer.res;
  limited.bytesWritten := 0; limited.positionable := FALSE;
  limited.inner := writer; limited.budget := budget;
  RETURN limited
END WrapWriter;

BEGIN
  NEW(context); Msg.InitContext(context, "XMLLimits")
END XMLLimits.
