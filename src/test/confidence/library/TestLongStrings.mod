MODULE TestLongStrings;

IMPORT Out, U := oocUnicode, S := LongStrings;

TYPE String = POINTER TO ARRAY OF U.LONGCHAR;

VAR
  a, b, pattern, expected: ARRAY 32 OF U.LONGCHAR;
  small: ARRAY 3 OF U.LONGCHAR;
  octets: ARRAY 16 OF CHAR;
  result, empty, large: String;
  empty8, large8: POINTER TO ARRAY OF CHAR;
  cap, destLen, sourceLen, start, length, removed, i, pos: LONGINT;
  found: BOOLEAN;

PROCEDURE Fill(VAR text: ARRAY OF U.LONGCHAR; length: LONGINT; first: U.LONGCHAR);
  VAR i: LONGINT;
BEGIN
  FOR i := 0 TO length-1 DO text[i] := first+i END;
  text[length] := 0
END Fill;

PROCEDURE Equal(actual, expected: ARRAY OF U.LONGCHAR);
BEGIN
  ASSERT(S.Equal(actual, expected), 40)
END Equal;

PROCEDURE Equal8(actual: ARRAY OF U.LONGCHAR; expected: ARRAY OF CHAR);
  VAR wide: ARRAY 128 OF U.LONGCHAR;
BEGIN
  S.Long(expected, wide); Equal(actual, wide)
END Equal8;

BEGIN
  a[0] := 0; ASSERT(S.Length(a) = 0, 41);
  a[0] := 531H; a[1] := 561H; a[2] := 0D83DH; a[3] := 0DE42H;
  a[4] := 0FFFFH; a[5] := 0;
  ASSERT(S.Length(a) = 5, 42);
  S.Assign(a, b); Equal(a, b); S.Assign(b, b); Equal(a, b);
  S.Assign(a, small);
  ASSERT((small[0] = 531H) & (small[1] = 561H) & (small[2] = 0), 43);
  b[4] := 8000H;
  ASSERT((S.Compare(a, b) = S.greater) & (S.Compare(b, a) = S.less), 44);
  S.FindDiff(a, b, found, pos); ASSERT(found & (pos = 4), 45);
  S.Assign(a, b); pos := 123; S.FindDiff(a, b, found, pos);
  ASSERT(~found & (pos = 123) & (S.Compare(a, b) = S.equal), 46);
  S.Extract(a, 2, 2, b);
  ASSERT((S.Length(b) = 2) & (b[0] = 0D83DH) & (b[1] = 0DE42H), 47);

  octets[0] := "A"; octets[1] := 0FFX; octets[2] := 0X;
  S.Long(octets, a); ASSERT((a[0] = 41H) & (a[1] = 255) & (a[2] = 0), 48);
  S.Short(a, "?", octets); ASSERT((octets[0] = "A") & (octets[1] = 0FFX), 49);
  a[0] := 531H; a[1] := -1; a[2] := 0;
  S.Short(a, "?", octets); ASSERT(octets = "??", 50);
  S.Long("ab", a); S.Append8("cd", a); Equal8(a, "abcd");
  S.Append(a, a); Equal8(a, "abcdabcd");

  S.Long("a", a); a[1] := 0E0H; a[2] := 0F7H; a[3] := 0FFH;
  a[4] := 561H; a[5] := 0D83DH; a[6] := 0DE42H; a[7] := 0;
  S.Capitalize(a);
  ASSERT((a[0] = 41H) & (a[1] = 0C0H) & (a[2] = 0F7H) & (a[3] = 0FFH), 51);
  ASSERT((a[4] = 561H) & (a[5] = 0D83DH) & (a[6] = 0DE42H), 52);

  S.Long("ababa", a); S.Long("aba", pattern);
  S.FindNext(pattern, a, 0, found, pos); ASSERT(found & (pos = 0), 53);
  S.FindNext(pattern, a, 1, found, pos); ASSERT(found & (pos = 2), 54);
  S.FindPrev(pattern, a, MAX(LONGINT), found, pos); ASSERT(found & (pos = 2), 55);
  S.FindPrev(pattern, a, 1, found, pos); ASSERT(found & (pos = 0), 56);
  pos := 123; S.FindPrev(pattern, a, -1, found, pos); ASSERT(~found & (pos = 123), 57);
  S.Long("ababab", pattern);
  S.FindNext(pattern, a, 0, found, pos); ASSERT(~found & (pos = 123), 58);
  S.FindPrev(pattern, a, MAX(LONGINT), found, pos); ASSERT(~found & (pos = 123), 59);
  pattern[0] := 0;
  S.FindNext(pattern, a, 5, found, pos); ASSERT(~found & (pos = 123), 60);
  S.FindPrev(pattern, a, 5, found, pos); ASSERT(found & (pos = 5), 61);

  S.Long("abc", a); S.Long("X", b);
  S.Insert(b, 8, a); Equal8(a, "abc");
  S.Insert(b, MAX(LONGINT), a); Equal8(a, "abc");
  S.Delete(a, MAX(LONGINT), MAX(LONGINT)); Equal8(a, "abc");
  S.Delete(a, 1, MAX(LONGINT)); Equal8(a, "a");
  S.Extract(a, MAX(LONGINT), MAX(LONGINT), b); Equal8(b, "");
  ASSERT(~S.CanExtractAll(MAX(LONGINT), MAX(LONGINT), 1, a), 62);
  ASSERT(~S.CanDeleteAll(MAX(LONGINT), MAX(LONGINT), 1), 63);
  ASSERT(~S.CanInsertAll(MAX(LONGINT), 0, a), 64);
  ASSERT(~S.CanReplaceAll(MAX(LONGINT), MAX(LONGINT), a), 65);
  ASSERT(~S.CanAppendAll(MAX(LONGINT), a), 66);
  ASSERT(~S.CanConcatAll(MAX(LONGINT), MAX(LONGINT), a), 67);

  (* Exercise bounded edits against independent, code-unit reference results. *)
  FOR cap := 1 TO 10 DO
    NEW(result, cap);
    FOR destLen := 0 TO cap-1 DO
      FOR sourceLen := 0 TO 8 DO
        Fill(a, destLen, 3000H); Fill(b, sourceLen, 5000H);
        length := destLen+sourceLen;
        IF length >= cap THEN length := cap-1 END;
        FOR i := 0 TO length-1 DO
          IF i < destLen THEN expected[i] := 3000H+i
          ELSE expected[i] := 5000H+i-destLen END
        END;
        expected[length] := 0;
        S.Assign(a, result^); S.Append(b, result^); Equal(result^, expected);
        S.Concat(a, b, result^); Equal(result^, expected);
        ASSERT(S.CanAssignAll(sourceLen, result^) = (sourceLen < cap), 68);
        S.Assign(a, result^);
        ASSERT(S.CanAppendAll(sourceLen, result^) = (destLen+sourceLen < cap), 69);
        ASSERT(S.CanConcatAll(destLen, sourceLen, result^) = (destLen+sourceLen < cap), 70);
        FOR start := 0 TO destLen+2 DO
          S.Assign(a, result^);
          ASSERT(S.CanInsertAll(sourceLen, start, result^) =
                 ((start <= destLen) & (destLen+sourceLen < cap)), 71);
          ASSERT(S.CanReplaceAll(sourceLen, start, result^) =
                 (start+sourceLen <= destLen), 72);
          IF start > destLen THEN S.Assign(a, expected)
          ELSE
            length := destLen+sourceLen;
            IF length >= cap THEN length := cap-1 END;
            FOR i := 0 TO length-1 DO
              IF i < start THEN expected[i] := 3000H+i
              ELSIF i-start < sourceLen THEN expected[i] := 5000H+i-start
              ELSE expected[i] := 3000H+i-sourceLen END
            END;
            expected[length] := 0
          END;
          S.Insert(b, start, result^); Equal(result^, expected);
          S.Assign(a, result^); S.Assign(a, expected);
          FOR i := 0 TO sourceLen-1 DO
            IF start+i < destLen THEN expected[start+i] := 5000H+i END
          END;
          S.Replace(b, start, result^); Equal(result^, expected);
          removed := 0;
          IF start < destLen THEN
            removed := sourceLen;
            IF removed > destLen-start THEN removed := destLen-start END
          END;
          length := destLen-removed;
          FOR i := 0 TO length-1 DO
            IF i < start THEN expected[i] := 3000H+i
            ELSE expected[i] := 3000H+i+removed END
          END;
          expected[length] := 0;
          S.Assign(a, result^); S.Delete(result^, start, sourceLen);
          Equal(result^, expected);
          length := 0;
          IF start < destLen THEN
            length := sourceLen;
            IF length > destLen-start THEN length := destLen-start END;
            IF length >= cap THEN length := cap-1 END
          END;
          FOR i := 0 TO length-1 DO expected[i] := 3000H+start+i END;
          expected[length] := 0;
          S.Extract(a, start, sourceLen, result^); Equal(result^, expected);
          ASSERT(S.CanExtractAll(destLen, start, sourceLen, result^) =
                 ((start+sourceLen <= destLen) & (sourceLen < cap)), 73);
          ASSERT(S.CanDeleteAll(destLen, start, sourceLen) =
                 (start+sourceLen <= destLen), 74)
        END
      END
    END
  END;

  (* A destination with room only for the terminator stays empty. *)
  NEW(empty, 1); NEW(empty8, 1); empty[0] := 0;
  S.Assign(a, empty^); S.Extract(a, 0, 2, empty^); S.Delete(empty^, 0, 2);
  S.Insert(a, 0, empty^); S.Replace(a, 0, empty^); S.Append(a, empty^);
  S.Concat(a, b, empty^); S.Long("abc", empty^); S.Append8("abc", empty^);
  S.Short(a, "?", empty8^);
  ASSERT((empty[0] = 0) & (empty8[0] = 0X), 75);
  ASSERT(S.CanAssignAll(0, empty^) & S.CanInsertAll(0, 0, empty^) &
         S.CanReplaceAll(0, 0, empty^) & S.CanAppendAll(0, empty^) &
         S.CanConcatAll(0, 0, empty^) & ~S.CanAssignAll(1, empty^), 81);

  (* Positions above the signed 16-bit INTEGER limit remain usable under -O2. *)
  NEW(large, 40002); NEW(large8, 40002);
  FOR i := 0 TO 40000 DO large[i] := 531H; large8[i] := "x" END;
  large[40000] := 561H; large[40001] := 0; large8[40001] := 0X;
  ASSERT((S.Length(large^) = 40001) & (S.Length8(large8^) = 40001), 76);
  pattern[0] := 561H; pattern[1] := 0;
  S.FindNext(pattern, large^, 32768, found, pos); ASSERT(found & (pos = 40000), 77);
  S.FindPrev(pattern, large^, MAX(LONGINT), found, pos); ASSERT(found & (pos = 40000), 78);
  S.Extract(large^, 39999, 3, a);
  ASSERT((a[0] = 531H) & (a[1] = 561H) & (a[2] = 0), 79);
  S.Delete(large^, 39999, MAX(LONGINT)); ASSERT(S.Length(large^) = 39999, 80);
  Out.String("LongStrings checks passed"); Out.Ln
END TestLongStrings.
