MODULE strUtils;
IMPORT S := strTypes, Strings := oocStrings, Out;  (* polpo: Strings := strings, Out := out *)

CONST
  CR* = 0DX;
  LF* = 0AX;

 TYPE string* = S.string;
      strings* = S.strings;
      pstring* = S.pstring;
      pstrings*= S.pstrings;

(** from the oo2c Strings module, implements string comparison, which should be implemented in a library level in case of Oberon-1 *)
TYPE  CompareResults* = SHORTINT;
  (**Result type of @oproc{Compare}.  *)

CONST
  (**Result of @oproc{Compare} if the first argument is lexically less than the second one.  *)
  less* = -1;
  (**Result of @oproc{Compare} if the first argument is equal to the second one.  *)
  equal* = 0;
  (**Result of @oproc{Compare} if the first argument is lexically greater than the second one.  *)
  greater* = 1;

(** this function copied from ooc source and may be considered a duplicate.$
   Returns @oconst{less}, @oconst{equal}, or @oconst{greater}, according as
   @oparam{stringVal1} is lexically less than, equal to, or greater than
   @oparam{stringVal2}.  Note that Oberon-2 and Oberon-07 already contains predefined comparison operators on strings.  *)
  PROCEDURE Compare* (stringVal1, stringVal2: ARRAY OF CHAR): CompareResults;
  VAR
    i: LONGINT;
    c1, c2: CHAR;
  BEGIN
    i := 0;
    LOOP
      c1 := 0X; c2 := 0X;
      IF i < LEN(stringVal1) THEN c1 := stringVal1[i] END;
      IF i < LEN(stringVal2) THEN c2 := stringVal2[i] END;
      IF c1 < c2 THEN RETURN less END;
      IF c1 > c2 THEN RETURN greater END;
      IF c1 = 0X THEN RETURN equal END;
      INC (i)
    END
  END Compare;

(**Copies @oparam{source} to @oparam{destination}.  Equivalent to the
   predefined procedure @code{COPY}.  Unlike @code{COPY}, this procedure can be
   assigned to a procedure variable.  *)

PROCEDURE Assign* (source: ARRAY OF CHAR; VAR destination: ARRAY OF CHAR);
  BEGIN
    COPY(source, destination)
  END Assign;

PROCEDURE Pos* (substr : CHAR ; s : ARRAY OF CHAR; n : INTEGER) : INTEGER;
VAR
  i : INTEGER;
BEGIN
  i := n;
  IF i < 0 THEN RETURN 0 END;
  WHILE (i < LEN(s)) & (i <= Strings.Length(s)) DO
    IF s[i] = substr THEN RETURN(i) END;
    INC(i)
  END;
  RETURN(0);
END Pos;

PROCEDURE RemoveLeftChars* (VAR s : ARRAY OF CHAR; ch : CHAR);
BEGIN
WHILE (LEN(s) > 0) & (s[0] # 0X) & (s[0] = ch) DO Strings.Delete (s, 0, 1) END

END RemoveLeftChars;

PROCEDURE RemoveRightChars* (VAR s : ARRAY OF CHAR; ch : CHAR);
VAR l : INTEGER;
BEGIN
l := Strings.Length(s);
WHILE (l > 0) & (s[l-1] = ch) DO DEC(l); s[l] := 0X END

END RemoveRightChars;

(** Returns the number of substrings (words) in s separated by character ch. *)

PROCEDURE WordCount* (s : ARRAY OF CHAR; ch : CHAR) : INTEGER;
VAR
  k,l : INTEGER;
  inWord: BOOLEAN;
BEGIN
  k := 0; l := 0; inWord := FALSE;
  WHILE (l < LEN(s)) & (s[l] # 0X) DO
    IF s[l] = ch THEN inWord := FALSE
    ELSE
      IF ~inWord THEN INC(k) END;
      inWord := TRUE
    END;
    INC(l)
  END;
  RETURN(k);
END WordCount;

(** Counts and returns the number of times character ch appears in string s. *)

PROCEDURE NumberOfChar* (s : ARRAY OF CHAR; ch : CHAR) : LONGINT;
VAR
  n, i : LONGINT;
BEGIN
  n := 0;
  i := 0;
  WHILE (i < LEN(s)) & (i <= Strings.Length(s)) DO
    IF s[i] = ch THEN INC(n) END;
    INC(i)
  END;
  RETURN(n);
END NumberOfChar;

(** Returns the rightmost index of character ch in string s; if not found, returns 0. *)

PROCEDURE Rpos* ( s : ARRAY OF CHAR ; ch : CHAR) : INTEGER;
VAR
  l : INTEGER;
BEGIN
  l := Strings.Length (s);
  IF (l < LEN(s)) & (s[l] = ch) THEN RETURN(l) END;
  WHILE l > 0 DO
    DEC(l);
    IF s[l] = ch THEN RETURN(l) END
  END;
  RETURN(0);
END Rpos;

(** Returns the leftmost index of character ch in string s; if not found, returns 0. *)

PROCEDURE Lpos* ( s : ARRAY OF CHAR ; ch : CHAR) : INTEGER;
VAR
  l : INTEGER;
BEGIN
  l := 0;
  WHILE (l < LEN(s)) & (l <= Strings.Length(s)) DO
    IF s[l] = ch THEN RETURN(l) END;
    INC(l)
  END;
  RETURN(0);
END Lpos;

(** Appends extra to destination, allocating or resizing destination as needed. *)

PROCEDURE append*(VAR extra, destination: pstring);
VAR
  tmp: pstring;
BEGIN
  IF extra # NIL THEN
       (*  Out.String("extra='"); Out.String(extra^); Out.Char("'"); Out.Ln; *)
    IF destination = NIL THEN
            Out.String("dest is nil"); Out.Ln;
      NEW(destination, Strings.Length(extra^)+1);
      COPY(extra^, destination^);
       (*  Out.String("now dest is '"); Out.String(destination^); Out.Char("'"); Out.Ln; *)
    ELSE
       (* Out.String("dest is not nil, it's '");Out.String(destination^);Out.Char("'");Out.Ln; *)
      NEW(tmp, Strings.Length(extra^) + Strings.Length(destination^)+1);
      COPY(destination^, tmp^);
           (* Out.String("copied dest to tmp, tmp is '"); Out.String(tmp^); Out.Char("'"); Out.Ln; *)
      Strings.Append(extra^, tmp^);
            (* Out.String("after appending tmp is '"); Out.String(tmp^); Out.Char("'"); Out.Ln; *)
      NEW(destination, Strings.Length(tmp^)+1);
      COPY(tmp^, destination^);
    END;
           (* Out.String("now dest is '"); Out.String(destination^); Out.Char("'"); Out.Ln; *)
  END
END append;

(** Copies up to quantity characters from src into dst, starting at index start. *)

PROCEDURE copyBytes*(VAR src, dst: ARRAY OF CHAR; start, quantity: LONGINT);
VAR
  i, j : LONGINT;
BEGIN
  i := start; j := 0;
  IF i < 0 THEN RETURN END;
  WHILE (i < LEN(dst)) & (j < LEN(src)) & (j < quantity) DO
    dst[i] := src[j]; INC(i); INC(j)
  END
END copyBytes;

(** Appends extraNum characters from extra to destinationNum characters of destination, reallocating destination. *)

PROCEDURE appendNumChars*(VAR extra: pstring; extraNum: LONGINT; VAR destination: pstring; destinationNum: LONGINT);
VAR
  tmp: pstring;
BEGIN
  IF extra # NIL THEN
    IF destination = NIL THEN
      NEW(destination, extraNum);
      copyBytes(extra^, destination^, 0, extraNum);
    ELSE
      NEW(tmp, extraNum + destinationNum);
      copyBytes(destination^, tmp^, 0, destinationNum);
      copyBytes(extra^, tmp^, destinationNum, extraNum);
      NEW(destination, LEN(tmp^));
      copyBytes(tmp^, destination^, 0, LEN(tmp^));
    END;
  END
END appendNumChars;

(** Allocates and assigns the contents of string s to the pstring d. *)

PROCEDURE string2pstring*(s: ARRAY OF CHAR; VAR d : pstring);
BEGIN
  NEW(d, Strings.Length(s)+1);
  Assign (s, d^);
END string2pstring;

(** Converts a CHAR array into a dynamic array of pstrings, one per line. *)

PROCEDURE string2pstrings*(VAR text: ARRAY OF CHAR): pstrings;
(* the lines end with LF, CR or CR LF; empty lines are left out; the text ends with 0X or the array *)
VAR
  i, k, n, start, lineNum: LONGINT;
  pstrs: pstrings;
  pstr:  pstring;
BEGIN
  n := 0; i := 0;
  WHILE (i < LEN(text)) & (text[i] # 0X) DO  (* count the lines *)
    IF (text[i] # 0AX) & (text[i] # 0DX) & ((i = 0) OR (text[i-1] = 0AX) OR (text[i-1] = 0DX)) THEN INC(n) END;
    INC(i)
  END;
  NEW(pstrs, n);
  lineNum := 0; i := 0;
  WHILE lineNum < n DO
    WHILE (text[i] = 0AX) OR (text[i] = 0DX) DO INC(i) END;
    start := i;
    WHILE (i < LEN(text)) & (text[i] # 0X) & (text[i] # 0AX) & (text[i] # 0DX) DO INC(i) END;
    NEW(pstr, i - start + 1);
    k := 0; WHILE k < i - start DO pstr[k] := text[start + k]; INC(k) END;
    pstr[k] := 0X;
    pstrs^[lineNum] := pstr;
    INC(lineNum)
  END;
  RETURN pstrs
END string2pstrings;

(** Returns the n-th substring from s, split by separator ch, as a pstring. *)

PROCEDURE ExtractWord* (n : INTEGER; s : ARRAY OF CHAR; ch : CHAR) : pstring;
VAR
  i, start, count, k : INTEGER;
  pstr : pstring;
BEGIN
  i := 0; count := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) DO
    WHILE (i < LEN(s)) & (s[i] = ch) DO INC(i) END;
    start := i;
    WHILE (i < LEN(s)) & (s[i] # 0X) & (s[i] # ch) DO INC(i) END;
    IF i > start THEN
      INC(count);
      IF count = n THEN
        NEW(pstr, i - start + 1);
        k := 0;
        WHILE start < i DO pstr[k] := s[start]; INC(k); INC(start) END;
        pstr[k] := 0X;
        RETURN pstr
      END
    END
  END;
  NEW(pstr, 1); pstr[0] := 0X;
  RETURN pstr
END ExtractWord;

(** Outputs a detailed dump of string s: index, ordinal value, and character. *)

PROCEDURE dumpStr*(s: ARRAY OF CHAR);
VAR
  i, j : INTEGER;
BEGIN
  i := 0; j := Strings.Length(s);
  REPEAT
    Out.Int(i, 0); Out.String("   "); Out.Int(ORD(s[i]), 0); Out. String("   "); Out.Char(s[i]); Out.Ln;
    INC(i)
  UNTIL i = j;
END dumpStr;

(** Returns an array of pstrings by splitting s on separator ch. *)

PROCEDURE tokenize*(s : ARRAY OF CHAR; ch : CHAR) : pstrings;
VAR
  pstr  : pstring;
  pstrs : pstrings;
  l, n : INTEGER;
BEGIN
  n := WordCount(s, ch);
  IF n # 0 THEN
    NEW (pstrs, n)
  ELSE
    pstrs := NIL;
    RETURN pstrs
  END;
  IF n = 1 THEN
    RemoveRightChars (s, ch);
    RemoveLeftChars (s, ch);
    string2pstring(s, pstrs^[0]);
  ELSE
    l := 0;
    REPEAT
      pstr := ExtractWord ( l+1, s, ch);
      pstrs^[l] := pstr;
      INC(l);
    UNTIL l = n;
  END;
  RETURN pstrs
END tokenize;

(** Copies up to LEN(dst)-1 chars from src to dst, including data past 0X, and null-terminates dst. *)


PROCEDURE copyAll* (src : ARRAY OF CHAR ; VAR dst : ARRAY OF CHAR);
VAR i, k : LONGINT;
BEGIN
  IF LEN (src) < LEN(dst) THEN k := LEN(src) ELSE k := LEN(dst)  END;
  IF LEN(dst) = 0 THEN RETURN END;
  IF k = 0 THEN dst[0] := 0X; RETURN END;
  i := 0;
  WHILE i <= k-2 DO
    dst[i] := src[i];
    INC(i)
  END;
  dst[k-1] := 0X;
END copyAll;

(** fills whole array with zeroes, useful when one needs to get several strings which contain characters < ' ' and not necessarily end with 0X *)
PROCEDURE zeroStr*(VAR str: ARRAY OF CHAR);
VAR
  i, j : LONGINT;
BEGIN
  i := LEN(str);
  j := 0;
  WHILE j < i DO
    str[j] := 0X;
    INC(j)
  END;
END zeroStr;

(** Appends LF and CR characters to str and updates the null terminator. *)

PROCEDURE appendLFCR*(VAR str: ARRAY OF CHAR);
VAR
  l : INTEGER;
BEGIN
        l := Strings.Length(str);
        IF l > LEN(str) - 3 THEN RETURN END;
        str[l] := LF;
        str[l+1] := CR;
        str[l+2] := 0X;
END appendLFCR;

(** Finds first occurrence of ch in line; returns position in pos and found flag in b. *)

PROCEDURE findChar*(ch: CHAR; VAR line: ARRAY OF CHAR; VAR b: BOOLEAN; VAR pos: INTEGER);
VAR
  i : INTEGER;
BEGIN
  i := -1; pos := -1;
  b := FALSE;
  IF LEN(line) = 0 THEN RETURN END;
  REPEAT
    INC(i);
    IF line[i] = ch THEN b := TRUE; pos := i END;
  UNTIL b OR (i = LEN(line) - 1);
END findChar;

(** Extracts the line from src up to the first LF character and stores it in dst. *)

PROCEDURE cutLine*(VAR src, dst: ARRAY OF CHAR);
VAR
 found: BOOLEAN;
 pos : INTEGER;
 i : INTEGER;
BEGIN
  COPY("", dst);
  findChar(LF, src, found, pos);
  IF found THEN
    IF LEN(dst) <= 1 THEN RETURN END;
    i := 0;
    REPEAT
      dst[i] := src[i];
      INC(i);
    UNTIL (i = pos) OR (i = LEN(dst)-2);
    dst[i] := src[i];
    dst[i+1] := 0X
  END;
END cutLine;

(** Terminates str immediately after the first LF by inserting 0X, preserving the LF itself. *)

PROCEDURE terminateLine*(VAR str: ARRAY OF CHAR);
VAR
 found: BOOLEAN;
 pos : INTEGER;
BEGIN
  findChar(LF, str, found, pos);
  IF found THEN
    IF (pos + 1) < LEN(str) THEN
      str[pos + 1] := 0X
    END
  END;
END terminateLine;
(** Extracts characters from src after spos into dst, stopping at the first control character (ASCII < ' '). *)

PROCEDURE getTillEOL*(VAR src: ARRAY OF CHAR; spos: INTEGER; VAR dst: ARRAY OF CHAR); (* actually get till any character < ' ' *)
VAR
  i, j: INTEGER;
BEGIN
  zeroStr(dst);
  i := 0;
  IF (spos < -1) OR (spos >= LEN(src) - 1) THEN RETURN END;
  j := spos+1;
  WHILE (j < LEN(src)) & (i < LEN(dst) - 1) & (src[j] >= ' ') DO
    dst[i] := src[j]; INC(i); INC(j)
  END;
END getTillEOL;

(** Extracts word from src starting at spos into dst, ending at space or control char. *)

PROCEDURE getNextWord*(VAR src: ARRAY OF CHAR; spos: INTEGER; VAR dst: ARRAY OF CHAR);
VAR
  i, j: INTEGER;
BEGIN
  zeroStr(dst);
  i := 0;
  j := spos;
  IF j < 0 THEN RETURN END;
  WHILE (j < LEN(src)) & (i < LEN(dst) - 1) & (src[j] > ' ') DO
    dst[i] := src[j]; INC(i); INC(j)
  END;
END getNextWord;


(** Copies characters from src to dst starting at spos, stopping at first non-alphanumeric or control character. *)

PROCEDURE getNextAlphaNumWord*(VAR src: ARRAY OF CHAR; spos: INTEGER; VAR dst: ARRAY OF CHAR);
VAR
  i, j: INTEGER;
  o: INTEGER;
BEGIN
  zeroStr(dst);
  i := 0;
  j := spos;
  IF j < 0 THEN RETURN END;
  WHILE (j < LEN(src)) & (i < LEN(dst) - 1) DO
    o := ORD(src[j]);
    IF ~(((o >= 48) & (o <= 57)) OR ((o >= 65) & (o <= 90)) OR
         ((o >= 97) & (o <= 122))) THEN RETURN END;
    dst[i] := src[j]; INC(i); INC(j)
  END;
END getNextAlphaNumWord;

(** Scans line manually to check if pattern occurs using substring comparison. *)

PROCEDURE contains* (VAR line : ARRAY OF CHAR; pattern: ARRAY OF CHAR): BOOLEAN;
VAR
 i, j, n, m: INTEGER;
BEGIN
  n := Strings.Length(line); m := Strings.Length(pattern); i := 0;
  WHILE i <= n - m DO
    j := 0;
    WHILE (j < m) & (line[i+j] = pattern[j]) DO INC(j) END;
    IF j = m THEN RETURN TRUE END;
    INC(i)
  END;
  RETURN FALSE
END contains;

(** Uses Strings.FindNext to check if pat is found in line starting at position 0. *)

PROCEDURE contains1*(VAR line: ARRAY OF CHAR; pat : ARRAY OF CHAR): BOOLEAN;
BEGIN
  RETURN contains(line, pat)
END contains1;

(*
PROCEDURE dumpText*(VAR text: ARRAY OF CHAR);
VAR
  i : INTEGER;
BEGIN
  i := 0;
  REPEAT
    Out.Int(i, 3); Out.String("   | ord: "); Out.Int(ORD(text[i]), 15); Out.String(", char: '"); Out.Char(text[i]); Out.Char("'"); Out.Ln;
    INC(i)
  UNTIL i = LEN(text);
END dumpText;

PROCEDURE dumpTextTill0*(VAR text: ARRAY OF CHAR);
VAR
  i : INTEGER;
BEGIN
  i := 0;
  REPEAT
    Out.Int(i, 3); Out.String("   | ord: "); Out.Int(ORD(text[i]), 15); Out.String(", char: '"); Out.Char(text[i]); Out.Char("'"); Out.Ln;
    INC(i)
  UNTIL (text[i] = 0X) OR (i = LEN(text));
END dumpTextTill0;
*)

   (* IntToStr routine taken from
   https://github.com/romiras/Oberon-F-components/blob/master/Ott/Mod/IntStr.cp
   and modified to work on 64bit system by dcwbrown,
   in order to avoid using oocIntStr, which has many dependencies *)
   PROCEDURE Reverse0 (VAR str : ARRAY OF CHAR; start, end : INTEGER);
   (* Reverses order of characters in the interval [start..end]. *)
   VAR
     h : CHAR;
   BEGIN
     WHILE start < end DO
       h := str[start]; str[start] := str[end]; str[end] := h;
       INC(start); DEC(end)
     END
   END Reverse0;

   (** Converts the value of `int' to string form and copies the possibly truncated
   result to `str'. *)
   PROCEDURE IntToStr*(int: LONGINT; VAR str: ARRAY OF CHAR);
   VAR
     b : ARRAY 21 OF CHAR;
     s, e: INTEGER;
     maxLength : SHORTINT; (* maximum number of digits representing a LONGINT value *)
   BEGIN
     IF SIZE(LONGINT) = 4 THEN maxLength := 11 END;
     IF SIZE(LONGINT) = 8 THEN maxLength := 20 END;
     (* build representation in string 'b' *)
     IF int = MIN(LONGINT) THEN (* smallest LONGINT, -int is an overflow *)
       IF SIZE(LONGINT) = 4 THEN
          b := "-2147483648";
          e := 11
       ELSE (* SIZE(LONGINT) = 8 *)
          b := "-9223372036854775808";
          e := 20
       END
     ELSE
       IF int < 0 THEN (* negative sign *)
         b[0] := "-"; int := -int; s := 1
       ELSE (* no sign *)
         s := 0
       END;
       e := s; (* 's' holds starting position of string *)
       REPEAT
         b[e] := CHR(int MOD 10+ORD("0"));
         int := int DIV 10;
         INC(e)
       UNTIL int = 0;
       b[e] := 0X;
       Reverse0(b, s, e-1);
     END;
       COPY(b, str) (* truncate output if necessary *)
   END IntToStr;

(** Prints each character in s with its index, up to the first 0X terminator. *)
PROCEDURE dumpChars*(VAR s : ARRAY OF CHAR);
VAR
  i : INTEGER;
  l : LONGINT;
BEGIN
  i := 0;
  l := Strings.Length(s);
  WHILE i < l DO
    Out.Int(i, 0); Out.Char(" "); Out.Char(s[i]); Out.Ln; INC(i)
  END
END dumpChars;

(** Prints all characters in s with their index, ignoring the 0X terminator. *)
PROCEDURE dumpAllChars*(VAR s : ARRAY OF CHAR);
VAR
  i : INTEGER;
  l : LONGINT;
BEGIN
  i := 0;
  l := LEN(s);
  WHILE i < l-1 DO
    Out.Int(i, 0); Out.Char(" "); Out.Char(s[i]); Out.Ln; INC(i)
  END
END dumpAllChars;


END strUtils.
