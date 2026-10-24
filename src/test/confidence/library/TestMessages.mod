MODULE TestMessages;

IMPORT Out, IntStr, U := oocUnicode, S := LongStrings, M := Msg;

TYPE
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (M.ContextDesc) END;
  ExtendedList = POINTER TO ExtendedListDesc;
  ExtendedListDesc = RECORD (M.MsgListDesc) marker: LONGINT END;
  Guarded = RECORD before: CHAR; text: ARRAY 8 OF CHAR; after: CHAR END;

VAR
  context: Context;
  default: M.Context;
  msg, inner, first, second: M.Msg;
  attribute: M.Attribute;
  list, source: M.MsgList;
  extended: ExtendedList;
  text, expected, value: ARRAY 512 OF U.LONGCHAR;
  name: ARRAY M.sizeAttrName+1 OF CHAR;
  longTemplate, large, empty: M.LStringPtr;
  large8, empty8: M.StringPtr;
  short: Guarded;
  one: ARRAY 1 OF CHAR;
  oneWide: ARRAY 1 OF U.LONGCHAR;
  minimum, maximum: ARRAY 32 OF CHAR;
  i: LONGINT;

PROCEDURE (context: Context) GetTemplate(msg: M.Msg; VAR text: M.LString);
BEGIN
  CASE msg.code OF
  | 1: S.Long("${value}|${value}|${n}|${MSG_CONTEXT}|${MSG_CODE}", text)
  | 2: S.Long("${inner}", text)
  | 3: S.Long("${MSG_CONTEXT}/${MSG_CONTEXT}/${MSG_CODE}/${MSG_CODE}/${missing}", text)
  | 4: S.Assign(longTemplate^, text)
  | 5: S.Long("${", text); S.Append8(name, text); S.Append8("}", text)
  ELSE S.Long("${value}", text)
  END
END GetTemplate;

PROCEDURE Equal8(actual: ARRAY OF U.LONGCHAR; expected: ARRAY OF CHAR);
  VAR wide: ARRAY 512 OF U.LONGCHAR;
BEGIN
  S.Long(expected, wide); ASSERT(S.Equal(actual, wide), 90)
END Equal8;

BEGIN
  IntStr.IntToStr(MIN(LONGINT), minimum); IntStr.IntToStr(MAX(LONGINT), maximum);
  NEW(context); M.InitContext(context, "test");
  value[0] := 531H; value[1] := 561H; value[2] := 0D83DH; value[3] := 0DE42H;
  value[4] := 255; value[5] := 0;
  msg := M.New(context, 1);
  msg.SetLStringAttrib("value", M.GetLStringPtr(value));
  msg.SetIntAttrib("n", MIN(LONGINT));
  S.Assign(value, expected); S.Append8("|", expected);
  S.Append(value, expected); S.Append8("|", expected);
  S.Append8(minimum, expected); S.Append8("|test|1", expected);
  value[0] := 0;
  msg.GetLText(text); ASSERT(S.Equal(text, expected), 91);
  attribute := msg.GetAttribute("value"); ASSERT(attribute IS M.LStringAttribute, 92);
  ASSERT(msg.GetAttribute("absent") = NIL, 93);
  short.before := "<"; short.after := ">";
  msg.GetText(short.text);
  ASSERT((short.before = "<") & (short.after = ">") & (short.text[7] = 0X), 94);
  ASSERT((short.text[0] = "?") & (short.text[4] = 0FFX) & (short.text[5] = "|"), 95);
  one[0] := "x"; msg.GetText(one); ASSERT(one[0] = 0X, 96);
  oneWide[0] := 123; msg.GetLText(oneWide); ASSERT(oneWide[0] = 0, 97);

  (* Replacement, nested messages, and repeated built-in placeholders. *)
  msg.SetStringAttrib("value", M.GetStringPtr("replacement"));
  S.Long("replacement|replacement|", expected);
  S.Append8(minimum, expected); S.Append8("|test|1", expected);
  msg.GetLText(text); ASSERT(S.Equal(text, expected), 116);
  inner := msg;
  msg := M.New(context, 2); msg.SetMsgAttrib("inner", inner);
  msg.GetLText(text); ASSERT(S.Equal(text, expected), 117);
  msg := M.New(context, 3); msg.GetLText(text);
  Equal8(text, "test/test/3/3/${missing}");

  FOR i := 0 TO M.sizeAttrName-1 DO name[i] := "x" END;
  name[M.sizeAttrName] := 0X;
  msg := M.New(context, 5); msg.SetStringAttrib(name, M.GetStringPtr("boundary"));
  msg.GetLText(text); Equal8(text, "boundary");

  (* The default context orders attributes by name and preserves wide values. *)
  NEW(default); M.InitContext(default, "default");
  msg := M.New(default, 17);
  msg.SetIntAttrib("z", MAX(LONGINT));
  value[0] := 531H; value[1] := 0;
  msg.SetLStringAttrib("a", M.GetLStringPtr(value));
  S.Long("MSG_CONTEXT: default", expected); S.Append8(0AX, expected);
  S.Append8("MSG_CODE: 17", expected); S.Append8(0AX, expected);
  S.Append8("a: ", expected); S.Append(value, expected); S.Append8(0AX, expected);
  S.Append8("z: ", expected); S.Append8(maximum, expected); S.Append8(0AX, expected);
  msg.GetLText(text); ASSERT(S.Equal(text, expected), 98);

  (* Moving into either an empty or nonempty list must empty the source. *)
  NEW(extended); M.InitMsgList(extended); extended.marker := 531H;
  list := extended; source := M.NewMsgList();
  first := M.New(default, 1); second := M.New(default, 2);
  source.Append(first); list.AppendList(source);
  ASSERT((list.msgCount = 1) & (list.msgList = first), 99);
  ASSERT((source.msgCount = 0) & (source.msgList = NIL), 100);
  ASSERT(extended.marker = 531H, 109);
  source.Append(second); list.AppendList(source);
  ASSERT((list.msgCount = 2) & (first.nextMsg = second) & (second.prevMsg = first), 101);
  ASSERT((first.prevMsg = NIL) & (second.nextMsg = NIL) & (source.msgCount = 0), 102);
  list.AppendList(source); ASSERT(list.msgCount = 2, 103);

  NEW(empty, 1); NEW(empty8, 1);
  msg.GetLText(empty^); msg.GetText(empty8^);
  ASSERT((empty[0] = 0) & (empty8[0] = 0X), 108);

  (* Long templates exercise both wide and narrow output beyond 32767. *)
  NEW(longTemplate, 40032); NEW(large, 40032); NEW(large8, 40032);
  FOR i := 0 TO 39999 DO longTemplate[i] := 78H END;
  longTemplate[40000] := 0;
  S.Append8("${MSG_CODE}", longTemplate^);
  msg := M.New(context, 4); msg.GetLText(large^);
  ASSERT((S.Length(large^) = 40001) & (large[39999] = 78H) & (large[40000] = 34H), 104);
  msg.GetText(large8^);
  ASSERT((S.Length8(large8^) = 40001) & (large8[40000] = "4"), 105);
  large8 := M.GetStringPtr(large8^); ASSERT(S.Length8(large8^) = 40001, 106);
  large := M.GetLStringPtr(large^); ASSERT(S.Length(large^) = 40001, 107);
  Out.String("Unicode message checks passed"); Out.Ln
END TestMessages.
