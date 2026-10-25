MODULE TestMemoryBuffers;

IMPORT Out, SYSTEM, M := Msg, Ch := Channel, Mem := IOMemory,
  U := oocUnicode, C := XMLUnicodeCodec,
  XMLUnicodeCodecImportAll, B := XMLInputBuffer, UB := XMLUnicodeBuffer;

TYPE
  Bytes = POINTER TO ARRAY OF CHAR;
  Units = POINTER TO ARRAY OF U.LONGCHAR;
  ShortReader = POINTER TO ShortReaderDesc;
  ShortReaderDesc = RECORD (Ch.ReaderDesc)
    inner: Ch.Reader; chunk, calls: LONGINT; fail, zero: BOOLEAN;
  END;
  PartialWriter = POINTER TO PartialWriterDesc;
  PartialWriterDesc = RECORD (Ch.WriterDesc)
    inner: Ch.Writer; chunk: LONGINT; fail, zero: BOOLEAN;
  END;

VAR context: M.Context;

PROCEDURE (r: ShortReader) ReadBytes(VAR x: ARRAY OF SYSTEM.BYTE; start, n: LONGINT);
BEGIN
  r.bytesRead := 0;
  IF r.res # NIL THEN RETURN END;
  INC(r.calls);
  IF r.zero THEN RETURN END;
  IF n > r.chunk THEN n := r.chunk END;
  r.inner.ReadBytes(x, start, n);
  r.bytesRead := r.inner.bytesRead; r.res := r.inner.res;
  IF r.fail THEN r.res := M.New(context, Ch.readError); r.fail := FALSE END
END ReadBytes;

PROCEDURE Reader(inner: Ch.Reader; chunk: LONGINT): ShortReader;
  VAR r: ShortReader;
BEGIN
  NEW(r); r.inner := inner; r.base := inner.base; r.chunk := chunk;
  r.calls := 0; r.res := NIL; r.fail := FALSE; r.zero := FALSE;
  RETURN r
END Reader;

PROCEDURE (w: PartialWriter) WriteBytes(VAR x: ARRAY OF SYSTEM.BYTE; start, n: LONGINT);
BEGIN
  w.bytesWritten := 0;
  IF (w.res # NIL) OR w.zero THEN RETURN END;
  IF n > w.chunk THEN n := w.chunk END;
  w.inner.WriteBytes(x, start, n);
  w.bytesWritten := w.inner.bytesWritten; w.res := w.inner.res;
  IF w.fail THEN w.res := M.New(context, Ch.writeError); w.fail := FALSE END
END WriteBytes;

PROCEDURE Writer(inner: Ch.Writer; chunk: LONGINT): PartialWriter;
  VAR w: PartialWriter;
BEGIN
  NEW(w); w.inner := inner; w.base := inner.base; w.chunk := chunk;
  w.res := NIL; w.fail := FALSE; w.zero := FALSE;
  RETURN w
END Writer;

PROCEDURE File(VAR bytes: ARRAY OF CHAR; length: LONGINT): Mem.Channel;
  VAR ch: Mem.Channel; res: M.Msg; w: Ch.Writer;
BEGIN
  ch := Mem.Tmp("", {Mem.read, Mem.write}, res); ASSERT(res = NIL, 120);
  w := ch.NewWriter(); w.WriteBytes(bytes, 0, length); ASSERT(w.res = NIL, 121);
  RETURN ch
END File;

PROCEDURE MemoryChecks;
  VAR
    ch, other: Mem.Channel; res: M.Msg;
    r: Ch.Reader; w: Ch.Writer;
    data, copy: Bytes; byte: CHAR;
    i, j, power, rotated: LONGINT;
    key, expectedKey: ARRAY 4 OF CHAR;
    message: ARRAY 128 OF CHAR;
    partial: PartialWriter;
BEGIN
  ch := Mem.New("invalid", {}, res); ASSERT((ch = NIL) & (res.code = Mem.accessDenied), 122);
  res.GetText(message); ASSERT(message = "Access denied", 176);
  ch := Mem.Old("missing", {Mem.read}, res); ASSERT((ch = NIL) & (res.code = Mem.noSuchFile), 123);
  NEW(data, 50000); NEW(copy, 50000);
  FOR i := 0 TO 49999 DO data[i] := CHR(i MOD 256) END;
  ch := Mem.Tmp("memory-test", {Mem.read, Mem.write}, res);
  ASSERT(~Mem.Exists("memory-test"), 124);
  w := ch.NewWriter(); w.WriteBytes(data^, 0, 100); w.WriteBytes(data^, 100, 49900);
  ASSERT((w.res = NIL) & (ch.Length() = 50000), 125);
  r := ch.NewReader(); r.ReadBytes(copy^, 0, 50000);
  ASSERT((r.res = NIL) & (r.bytesRead = 50000), 126);
  FOR i := 0 TO 49999 DO ASSERT(copy[i] = data[i], 127) END;
  r.SetPos(MAX(LONGINT)); ASSERT(r.Available() = 0, 128);
  r.ReadBytes(copy^, LEN(copy^), 0); ASSERT((r.res = NIL) & (r.bytesRead = 0), 129);
  r.ReadByte(byte); ASSERT((r.res.code = Ch.readAfterEnd) & (r.bytesRead = 0), 130);
  r.SetPos(0); r.ReadBytes(copy^, 0, 1); ASSERT(r.bytesRead = 0, 131);
  r.ClearError; r.SetPos(0);
  r.ReadBytes(copy^, 0, MAX(LONGINT)); ASSERT((r.res.code = Ch.outOfRange) & (r.Pos() = 0), 132);
  r.ClearError; r.ReadBytes(copy^, -1, 1); ASSERT(r.res.code = Ch.outOfRange, 133);
  r.ClearError; r.ReadBytes(copy^, LEN(copy^)+1, 0); ASSERT(r.res.code = Ch.outOfRange, 177);
  w.WriteBytes(data^, 0, -1); ASSERT(w.res.code = Ch.outOfRange, 178);
  w.ClearError;
  w.WriteBytes(data^, LEN(data^), 0); ASSERT(w.res = NIL, 134);
  w.SetPos(MAX(LONGINT)); w.WriteByte(0FFX);
  ASSERT((w.res.code = Ch.outOfRange) & (w.bytesWritten = 0), 135);
  w.ClearError; w.SetPos(MAX(LONGINT)-1); w.WriteBytes(data^, 0, 2);
  ASSERT((w.res.code = Ch.outOfRange) & (ch.Length() = 50000), 136);
  w.ClearError; w.SetPos(50010); w.WriteByte(0FFX);
  ASSERT((w.res = NIL) & (ch.Length() = 50011), 137);
  FOR i := 50000 TO 50009 DO ASSERT(ch.file.data[i] = 0X, 138) END;
  ASSERT(ch.file.data[50010] = 0FFX, 139);
  w(Mem.Writer).Truncate(-1); ASSERT(w.res.code = Ch.outOfRange, 140);
  w.ClearError; w(Mem.Writer).Truncate(100); w(Mem.Writer).Truncate(150);
  FOR i := 100 TO 149 DO ASSERT(ch.file.data[i] = 0X, 141) END;
  (* Public file storage may also be used as an overlapping copy source. *)
  w.SetPos(1); w.WriteBytes(ch.file.data^, 0, 20);
  FOR i := 1 TO 20 DO ASSERT(ch.file.data[i] = CHR(i-1), 142) END;
  r.ClearError; r.SetPos(1); r.ReadBytes(ch.file.data^, 0, 20);
  FOR i := 0 TO 19 DO ASSERT(ch.file.data[i] = CHR(i), 143) END;
  w(Mem.Writer).Truncate(4); w.SetPos(0);
  data[0] := 1X; data[1] := 2X; data[2] := 3X; data[3] := 4X;
  w.WriteBytes(data^, 0, 4); ch.Fingerprint(key, 0, 4);
  FOR i := 0 TO 3 DO ASSERT(key[i] = CHR(i+1), 144) END;
  FOR i := 0 TO 511 DO data[i] := CHR(i MOD 256) END;
  w.SetPos(0); w.WriteBytes(data^, 0, 512);
  FOR i := 0 TO 3 DO expectedKey[i] := 0X END;
  FOR i := 0 TO 511 DO
    j := (i DIV 4) MOD 8; power := ASH(1, j);
    rotated := ((i MOD 256)*power) MOD 256 + (i MOD 256) DIV (256 DIV power);
    j := i MOD 4; expectedKey[j] := CHR((ORD(expectedKey[j])+rotated) MOD 256)
  END;
  ch.Fingerprint(key, 0, 512);
  FOR i := 0 TO 3 DO ASSERT(key[i] = expectedKey[i], 179) END;
  other := Mem.Tmp("copy", {Mem.read, Mem.write}, res);
  partial := Writer(other.NewWriter(), 3); ch.CopyToWriter(partial);
  ASSERT((ch.res = NIL) & (other.Length() = 512), 180);
  FOR i := 0 TO 511 DO ASSERT(other.file.data[i] = data[i], 181) END;
  other.Close;
  ch.Register; ASSERT(Mem.Exists("memory-test"), 145);
  other := Mem.Old("memory-test", {Mem.read}, res);
  w := other.NewWriter(); ASSERT((w = NIL) & (other.res.code = Ch.noWriteAccess), 146);
  other.res.GetText(message); ASSERT(message = "No write permission for channel", 182);
  other.Close; ch.Close;
  ASSERT(ch.Length() = Ch.noLength, 147);
  r.ClearError; r.ReadByte(byte); ASSERT(r.res.code = Ch.channelClosed, 148);
  ch.Register; ASSERT(ch.res.code = Ch.channelClosed, 149)
END MemoryChecks;

PROCEDURE ByteBufferChecks;
  VAR data: Bytes; ch: Mem.Channel; b: B.Buffer; r: ShortReader;
    errors: M.MsgList; i: LONGINT; progress: BOOLEAN;
BEGIN
  NEW(data, 50000); FOR i := 0 TO 49999 DO data[i] := CHR(i MOD 256) END;
  ch := File(data^, 50000); errors := M.NewMsgList(); b := B.New(ch.NewReader(), errors);
  ASSERT((b.chars[0] = 0X) & ~b.EndOfBuffer(0), 150);
  progress := TRUE;
  WHILE progress DO progress := b.NextBlock() END;
  ASSERT((b.endOfBuffer = 50000) & b.EndOfBuffer(50000) & (errors.msgCount = 0), 151);
  FOR i := 0 TO 49999 DO ASSERT(b.chars[i] = data[i], 152) END;
  ASSERT(~b.NextBlock() & (errors.msgCount = 0), 153); b.Close;
  ch := File(data^, 50000); r := Reader(ch.NewReader(), 4096);
  errors := M.NewMsgList(); b := B.New(r, errors); b.discardable := 1;
  progress := b.NextBlock();
  ASSERT(progress & (b.offsetFromPos0 = 1) & (b.endOfBuffer = 8191), 154);
  FOR i := 0 TO 8190 DO ASSERT(b.chars[i] = data[i+1], 155) END;
  b.Close;
  ch := File(data^, 8); r := Reader(ch.NewReader(), 3); r.fail := TRUE;
  errors := M.NewMsgList(); b := B.New(r, errors);
  ASSERT((b.endOfBuffer = 3) & (errors.msgCount = 1), 156);
  ASSERT(~b.NextBlock() & ~b.NextBlock() & (errors.msgCount = 1), 157);
  ASSERT(errors.msgList.nextMsg = NIL, 158); b.Close;
  ch := File(data^, 8); r := Reader(ch.NewReader(), 3); r.zero := TRUE;
  errors := M.NewMsgList(); b := B.New(r, errors);
  ASSERT(~b.NextBlock() & (r.calls = 1) & (errors.msgCount = 0), 159); b.Close
END ByteBufferChecks;

PROCEDURE CheckStream(ch: Mem.Channel; encoding: ARRAY OF CHAR; chunk: LONGINT;
                      VAR expected: ARRAY OF U.LONGCHAR; length, invalid: LONGINT;
                      discard: BOOLEAN);
  VAR input: UB.Input; reader: Ch.Reader; errors: M.MsgList;
    factory: C.Factory; pos, total: LONGINT; progress: BOOLEAN;
BEGIN
  reader := ch.NewReader();
  IF chunk > 0 THEN reader := Reader(reader, chunk) END;
  factory := NIL; IF encoding # "" THEN factory := C.GetFactory(encoding) END;
  errors := M.NewMsgList(); input := UB.NewInput(reader, factory, errors);
  pos := 0; total := 0;
  LOOP
    WHILE pos < input.endOfBuffer DO
      ASSERT(total < length, 160); ASSERT(input.chars[pos] = expected[total], 161);
      INC(pos); INC(total)
    END;
    IF discard THEN input.discardable := pos END;
    progress := input.NextBlock();
    pos := total-input.offsetFromPos0;
    IF ~progress THEN EXIT END
  END;
  ASSERT((total = length) & (errors.msgCount = 0) & (input.codec.invalidChars = invalid), 162);
  ASSERT((input.chars[input.endOfBuffer] = UB.markerEOD) & ~input.NextBlock(), 163);
  input.Close
END CheckStream;

PROCEDURE UnicodeChecks;
  VAR bytes: ARRAY 32 OF CHAR; expected: ARRAY 16 OF U.LONGCHAR;
    ch: Mem.Channel; input: UB.Input; errors: M.MsgList;
    largeBytes: Bytes; largeUnits: Units; i: LONGINT;
BEGIN
  ch := File(bytes, 0); CheckStream(ch, "", 1, expected, 0, 0, FALSE);
  bytes[0] := 0EFX; bytes[1] := 0BBX; bytes[2] := 0BFX;
  ch := File(bytes, 3); CheckStream(ch, "", 1, expected, 0, 0, FALSE);
  bytes[0] := 0FEX; bytes[1] := 0FFX;
  ch := File(bytes, 2); CheckStream(ch, "", 1, expected, 0, 0, FALSE);
  bytes[0] := 0FFX; bytes[1] := 0FEX;
  ch := File(bytes, 2); CheckStream(ch, "", 1, expected, 0, 0, FALSE);
  bytes[0] := 0EFX; bytes[1] := 0BBX; bytes[2] := 0BFX;
  bytes[3] := 0D4X; bytes[4] := 0B1X; bytes[5] := 0F0X;
  bytes[6] := 9FX; bytes[7] := 99X; bytes[8] := 82X;
  expected[0] := 531H; expected[1] := 0D83DH; expected[2] := 0DE42H;
  ch := File(bytes, 9); CheckStream(ch, "", 1, expected, 3, 0, FALSE);
  ch := File(bytes, 9); CheckStream(ch, "UTF-8", 2, expected, 3, 0, FALSE);
  bytes[0] := 0E2X; bytes[1] := 82X; expected[0] := C.decodeError;
  ch := File(bytes, 2); CheckStream(ch, "", 1, expected, 1, 1, FALSE);
  bytes[0] := 0X; expected[0] := 0;
  ch := File(bytes, 1); CheckStream(ch, "UTF-8", 1, expected, 1, 0, FALSE);
  bytes[0] := 0X; bytes[1] := "<"; bytes[2] := 0X; bytes[3] := "?";
  expected[0] := 3CH; expected[1] := 3FH;
  ch := File(bytes, 4); CheckStream(ch, "", 1, expected, 2, 0, FALSE);
  bytes[0] := "<"; bytes[1] := 0X; bytes[2] := "?"; bytes[3] := 0X;
  ch := File(bytes, 4); CheckStream(ch, "", 1, expected, 2, 0, FALSE);
  bytes[0] := 0X; bytes[1] := 0X; bytes[2] := 0X; bytes[3] := "<";
  ch := File(bytes, 4); errors := M.NewMsgList(); input := UB.NewInput(ch.NewReader(), NIL, errors);
  ASSERT((errors.msgCount = 1) & (input.chars[0] = UB.markerEOD) & ~input.NextBlock(), 164);
  input.Close;
  bytes[0] := 0D4X; bytes[1] := 0B1X;
  ch := File(bytes, 2); errors := M.NewMsgList();
  input := UB.NewInput(ch.NewReader(), NIL, errors);
  ASSERT((input.endOfBuffer = 1) & (input.chars[0] = 531H), 184);
  input.SetCodec(C.GetFactory("LATIN1"), FALSE);
  ASSERT((input.endOfBuffer = 2) & (input.chars[0] = 0D4H) &
         (input.chars[1] = 0B1H) & ~input.autoDetectedCodec, 185);
  input.Close;
  (* Split a UTF-8 character at the normal 12288-byte read boundary. *)
  NEW(largeBytes, 50003); NEW(largeUnits, 50003);
  FOR i := 0 TO 12286 DO largeBytes[i] := "A"; largeUnits[i] := 41H END;
  largeBytes[12287] := 0D4X; largeBytes[12288] := 0B1X; largeUnits[12287] := 531H;
  FOR i := 12289 TO 50002 DO largeBytes[i] := "B"; largeUnits[i-1] := 42H END;
  ch := File(largeBytes^, 50003); CheckStream(ch, "", 0, largeUnits^, 50002, 0, TRUE)
END UnicodeChecks;

PROCEDURE OutputChecks;
  VAR
    ch: Mem.Channel; res: M.Msg; writer: Ch.Writer; partial: PartialWriter;
    output: UB.Output; factory: C.Factory; units: Units;
    small: ARRAY 4 OF U.LONGCHAR;
    empty: ARRAY 1 OF CHAR;
    i, variant, length: LONGINT;
BEGIN
  NEW(units, 40002);
  FOR i := 0 TO 40000 DO units[i] := 531H END;
  units[8191] := 0D83DH; units[8192] := 0DE42H; units[40001] := 0;
  units[20000] := 0FEFFH;
  FOR variant := 0 TO 2 DO
    IF variant = 0 THEN factory := C.GetFactory("UTF-8")
    ELSIF variant = 1 THEN factory := C.GetFactory("UTF-16")
    ELSE factory := C.GetFactory("UTF-16LE") END;
    ch := Mem.Tmp("", {Mem.read, Mem.write}, res); writer := ch.NewWriter();
    output := UB.NewOutput(writer, factory, variant = 1);
    output.Write8(""); output.Write16I(units^, 0, 8192);
    output.Write16I(units^, 8192, 40001); output.Flush;
    ASSERT((writer.res = NIL) & (output.codec.invalidChars = 0), 165);
    length := ch.Length(); output.Flush;
    ASSERT(ch.Length() = length, 166);
    IF variant = 1 THEN ASSERT(length = 80004, 174)
    ELSIF variant = 0 THEN ASSERT(length = 80003, 175)
    ELSE ASSERT(length = 80002, 183) END;
    IF variant = 2 THEN CheckStream(ch, "UTF-16LE", 0, units^, 40001, 0, TRUE)
    ELSE CheckStream(ch, "", 0, units^, 40001, 0, variant = 1) END
  END;
  factory := C.GetFactory("UTF-8");
  small[0] := 531H; small[1] := 0D83DH; small[2] := 0DE42H; small[3] := 0;
  ch := File(empty, 0); partial := Writer(ch.NewWriter(), 1); partial.fail := TRUE;
  output := UB.NewOutput(partial, factory, FALSE); output.Write16(small); output.Flush;
  ASSERT((partial.res.code = Ch.writeError) & (ch.Length() = 1), 167);
  partial.ClearError; output.Flush; ASSERT((partial.res = NIL) & (ch.Length() = 6), 168);
  output.Flush; ASSERT(ch.Length() = 6, 169);
  CheckStream(ch, "", 1, small, 3, 0, FALSE);
  ch := File(empty, 0); partial := Writer(ch.NewWriter(), 1); partial.zero := TRUE;
  output := UB.NewOutput(partial, factory, FALSE); output.Write8("abc"); output.Flush;
  ASSERT((partial.res.code = Ch.writeError) & (ch.Length() = 0), 170);
  partial.zero := FALSE; partial.ClearError; output.Flush;
  ASSERT((partial.res = NIL) & (ch.Length() = 3), 171);
  ASSERT((ch.file.data[0] = "a") & (ch.file.data[2] = "c"), 172); ch.Close;
  ch := File(empty, 0); output := UB.NewOutput(ch.NewWriter(), factory, FALSE);
  small[0] := 0D800H; output.Write16I(small, 0, 1); output.Flush; output.Flush;
  ASSERT((output.codec.invalidChars = 1) & (ch.Length() = 1) & (ch.file.data[0] = "?"), 173);
  ch.Close
END OutputChecks;

BEGIN
  NEW(context); M.InitContext(context, "TestMemoryBuffers");
  MemoryChecks; ByteBufferChecks; UnicodeChecks; OutputChecks;
  Out.String("Memory channel and XML buffer checks passed (-O2)"); Out.Ln
END TestMemoryBuffers.
