MODULE TestUnicodeMessages;

IMPORT Out, U := oocUnicode, S := LongStrings, M := Msg,
  UC := XMLUnicodeCodec, XMLUnicodeCodecImportAll;

TYPE
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (M.ContextDesc) END;

VAR
  context: Context;
  factory: UC.Factory;
  codec: UC.Codec;
  msg: M.Msg;
  input, output: ARRAY 32 OF CHAR;
  value, text: ARRAY 32 OF U.LONGCHAR;
  start, dest, done, written, length, i: LONGINT;

PROCEDURE (context: Context) GetTemplate(msg: M.Msg; VAR text: M.LString);
BEGIN
  S.Long("${value}", text)
END GetTemplate;

BEGIN
  NEW(context); M.InitContext(context, "TestUnicodeMessages");
  (* Armenian U+0531 and supplementary U+1F642 cross all three interfaces. *)
  input[0] := 0D4X; input[1] := 0B1X;
  input[2] := 0F0X; input[3] := 9FX; input[4] := 99X; input[5] := 82X;
  factory := UC.GetFactory("UTF-8"); codec := factory.NewCodec();
  start := 0; dest := 0;
  WHILE start < 6 DO
    codec.Decode(input, start, 6, value, dest, LEN(value), done, written);
    ASSERT((done > start) & (written > dest), 110);
    start := done; dest := written
  END;
  ASSERT((dest = 3) & (codec.invalidChars = 0), 111);
  value[dest] := 0;
  msg := M.New(context, 1); msg.SetLStringAttrib("value", M.GetLStringPtr(value));
  msg.GetLText(text); ASSERT(S.Equal(value, text), 112);
  length := S.Length(text); start := 0; dest := 0;
  WHILE start < length DO
    codec.Encode(text, start, length, output, dest, LEN(output), done, written);
    ASSERT((done > start) & (written > dest), 113);
    start := done; dest := written
  END;
  ASSERT((dest = 6) & (codec.invalidChars = 0), 114);
  FOR i := 0 TO 5 DO ASSERT(input[i] = output[i], 115) END;
  Out.String("Unicode codec/message integration checks passed (-O2)"); Out.Ln
END TestUnicodeMessages.
