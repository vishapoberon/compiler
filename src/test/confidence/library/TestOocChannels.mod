MODULE TestOocChannels;

IMPORT Out, M := Msg, S := LongStrings, U := oocUnicode,
  Ch := Channel, Mem := IOMemory, F := oocFiles,
  T := TextRider, B := BinaryRider, ProgramArgs;

VAR
  memory: Mem.Channel;
  file: F.File;
  res: M.Msg;
  tw: T.Writer;
  tr: T.Reader;
  bw: B.Writer;
  br: B.Reader;
  reader: Ch.Reader;
  writer: Ch.Writer;
  number: LONGINT;
  text: ARRAY 128 OF CHAR;
  wide, expected: ARRAY 128 OF U.LONGCHAR;

PROCEDURE CheckMessage(msg: M.Msg; expected8: ARRAY OF CHAR);
BEGIN
  ASSERT(msg # NIL, 1);
  msg.GetText(text); ASSERT(text = expected8, 2);
  msg.GetLText(wide); S.Long(expected8, expected);
  ASSERT(S.Equal(wide, expected), 3)
END CheckMessage;

BEGIN
  memory := Mem.Tmp("", {Mem.read, Mem.write}, res); ASSERT(res = NIL, 4);
  tw := T.ConnectWriter(memory); tw.WriteLInt(12345, 0); tw.WriteLn;
  ASSERT(tw.res = NIL, 5);
  tr := T.ConnectReader(memory); tr.ReadLInt(number);
  ASSERT((tr.res = NIL) & (number = 12345), 6);
  memory.Close;

  memory := Mem.Tmp("", {Mem.read, Mem.write}, res); ASSERT(res = NIL, 7);
  tw := T.ConnectWriter(memory);
  tw.WriteString("123456789012345678901234567890 ");
  tr := T.ConnectReader(memory); tr.ReadLInt(number);
  ASSERT(tr.res.code = T.valueOutOfRange, 8);
  CheckMessage(tr.res, "Number exceeded limits or string was too long");
  memory.Close;

  memory := Mem.Tmp("", {Mem.read, Mem.write}, res); ASSERT(res = NIL, 9);
  bw := B.ConnectWriter(memory); bw.WriteLInt(123456789);
  ASSERT(bw.res = NIL, 10);
  br := B.ConnectReader(memory); br.ReadLInt(number);
  ASSERT((br.res = NIL) & (number = 123456789), 11);
  br.ReadLInt(number); ASSERT(br.res.code = Ch.readAfterEnd, 12);
  CheckMessage(br.res, "Trying to read past the end of the file");
  memory.Close;

  file := F.Tmp("", {F.read, F.write}, res); ASSERT(res = NIL, 13);
  writer := file.NewWriter(); writer.WriteByte("A");
  ASSERT((writer.res = NIL) & (writer.bytesWritten = 1), 14);
  reader := file.NewReader(); reader.ReadBytes(text, 0, 2);
  ASSERT((reader.res.code = Ch.readAfterEnd) & (reader.bytesRead = 1) &
         (text[0] = "A"), 15);
  CheckMessage(reader.res, "Trying to read past the end of the file");
  file.Register; ASSERT(file.res.code = F.anonymousFile, 16);
  CheckMessage(file.res, "Anonymous temporary file cannot be registered");
  file.Close; ASSERT(file.res = NIL, 17);

  reader := ProgramArgs.args.NewReader(); ASSERT(reader # NIL, 18);
  reader.SetPos(-1); ASSERT(reader.res.code = Ch.outOfRange, 19);
  CheckMessage(reader.res, "Trying to set invalid position");
  reader.ClearError; ASSERT(reader.res = NIL, 20);
  Out.String("oo2c channel compatibility checks passed"); Out.Ln
END TestOocChannels.
