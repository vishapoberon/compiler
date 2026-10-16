MODULE TestBDBounds;
IMPORT bdStrings, Out;
VAR s: POINTER TO ARRAY OF CHAR;
    small: ARRAY 5 OF CHAR;
    one: ARRAY 1 OF CHAR;
    n, e, i, pos: LONGINT;

PROCEDURE Check(size, end: LONGINT);
VAR i: LONGINT;
BEGIN
  NEW(s, size);
  FOR i := 0 TO size - 1 DO s[i] := 'a' END;
  bdStrings.terminate(s^, end);
  ASSERT(bdStrings.eos(s^) = end);
  ASSERT(bdStrings.length(s^) = end);
  IF end < size THEN ASSERT(s[end] = 0X) END
END Check;

BEGIN
  Check(1, 0); Check(255, 0); Check(256, 0);
  Check(257, 1); Check(65536, 0); Check(65536, 65535);
  Check(65537, 0); Check(70000, 65536); Check(70000, 69999);
  Check(70000, 70000);
  bdStrings.init(one); ASSERT(bdStrings.isEmpty(one));
  bdStrings.appendChar(one, 'x'); ASSERT(bdStrings.length(one) = 1);
  bdStrings.assign(small, 'hello!'); ASSERT(bdStrings.eos(small) = 5);
  bdStrings.assign(small, 'ab'); bdStrings.append(small, 'cd');
  ASSERT(bdStrings.length(small) = 4);
  bdStrings.appendChar(small, 'e'); ASSERT(bdStrings.eos(small) = 5);
  bdStrings.init(small); pos := -1;
  ASSERT(bdStrings.nextChar(small, pos) = 0X); ASSERT(pos = -1);
  bdStrings.appendUpTo(small, 'abc', pos, ','); ASSERT(bdStrings.isEmpty(small));
  pos := 0; bdStrings.appendUpTo(small, 'ab,cd', pos, ',');
  ASSERT(small = 'ab'); ASSERT(pos = 2);
  Out.String('bd string bounds tests passed'); Out.Ln
END TestBDBounds.
