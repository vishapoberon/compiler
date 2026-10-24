(* 	$Id$	 *)
MODULE LongStrings;
(*  Facilities for manipulating strings in LONGCHAR arrays.
    Copyright (C) 1996, 1997  Michael van Acken

    This module is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public License
    as published by the Free Software Foundation; either version 2 of
    the License, or (at your option) any later version.

    This module is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with OOC. If not, write to the Free Software Foundation,
    59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*)


(**

Input strings must contain a zero terminator within their array bounds.
Output strings are likewise terminated when the destination has room.

Positions and lengths count UTF-16 code units and use LONGINT under VOC's
Oberon-2 model. Supplementary characters occupy two positions. Truncation
and extraction operate on code units and can split a surrogate pair.
Source strings must be terminated; a zero-capacity destination is left
untouched.

*)

IMPORT
  Unicode := oocUnicode;

TYPE
  LONGCHAR* = Unicode.LONGCHAR;
  CompareResults* = SHORTINT;
  (**Result type of @oproc{Compare}.  *)

CONST
  less* = -1;
  (**Result of @oproc{Compare} if the first argument is lexically less
     than the second one.  *)
  equal* = 0;
  (**Result of @oproc{Compare} if the first argument is equal to the second
     one.  *)
  greater* = 1;
  (**Result of @oproc{Compare} if the first argument is lexically greater
     than the second one.  *)


PROCEDURE Length* (stringVal: ARRAY OF LONGCHAR): LONGINT;
(**Returns the length of @oparam{stringVal}.  This is equal to the number of
   code units in @oparam{stringVal} up to and excluding the first @code{0}. *)
  VAR
    i: LONGINT;
  BEGIN
    i := 0;
    WHILE (i < LEN (stringVal)) & (stringVal[i] # 0) DO
      INC (i)
    END;
    ASSERT (i < LEN (stringVal));
    RETURN i
  END Length;

PROCEDURE Length8* (stringVal: ARRAY OF CHAR): LONGINT;
(**Returns the number of octets before the terminator in a narrow string. *)
  VAR i: LONGINT;
  BEGIN
    i := 0;
    WHILE (i < LEN (stringVal)) & (stringVal[i] # 0X) DO INC (i) END;
    ASSERT (i < LEN (stringVal));
    RETURN i
  END Length8;



PROCEDURE Assign* (source: ARRAY OF LONGCHAR; VAR destination: ARRAY OF LONGCHAR);
(**Copies @oparam{source} to @oparam{destination}, truncating to the available
   capacity and preserving the terminator. *)
  VAR
    i: LONGINT;
  BEGIN
    IF LEN (destination) = 0 THEN RETURN END;
    i := 0;
    WHILE (i < LEN (destination)-1) & (source[i] # 0) DO
      destination[i] := source[i]; INC (i)
    END;
    destination[i] := 0
  END Assign;

PROCEDURE Extract* (source: ARRAY OF LONGCHAR; startPos, numberToExtract: LONGINT;
                    VAR destination: ARRAY OF LONGCHAR);
(**Copies at most @oparam{numberToExtract} characters from @oparam{source} to
   @oparam{destination}, starting at position @oparam{startPos} in
   @oparam{source}.  An empty string value will be extracted if
   @oparam{startPos} is greater than or equal to @samp{Length(source)}.

   @precond
   @oparam{startPos} and @oparam{numberToExtract} are not negative.
   @end precond  *)
  VAR
    sourceLength, i: LONGINT;
  BEGIN
    ASSERT ((startPos >= 0) & (numberToExtract >= 0));
    IF LEN (destination) = 0 THEN RETURN END;
    (* make sure that we get an empty string if `startPos' refers to an array
       index beyond `Length (source)'  *)
    sourceLength := Length (source);
    IF (startPos > sourceLength) THEN
      startPos := sourceLength
    END;

    (* make sure that `numberToExtract' doesn't exceed the capacity
       of `destination' *)
    IF (numberToExtract >= LEN (destination)) THEN
      numberToExtract := LEN (destination)-1
    END;

    (* copy up to `numberToExtract' characters to `destination' *)
    i := 0;
    WHILE (i < numberToExtract) & (source[startPos+i] # 0) DO
      destination[i] := source[startPos+i];
      INC (i)
    END;
    destination[i] := 0
  END Extract;

PROCEDURE Delete* (VAR stringVar: ARRAY OF LONGCHAR;
                  startPos, numberToDelete: LONGINT);
(**Deletes at most @oparam{numberToDelete} characters from @oparam{stringVar},
   starting at position @oparam{startPos}.  The string value in
   @oparam{stringVar} is not altered if @oparam{startPos} is greater than or
   equal to @samp{Length(stringVar)}.

   @precond
   @oparam{startPos} and @oparam{numberToDelete} are not negative.
   @end precond  *)
  VAR
    stringLength, i: LONGINT;
  BEGIN
    ASSERT ((startPos >= 0) & (numberToDelete >= 0));
    IF LEN (stringVar) = 0 THEN RETURN END;
    stringLength := Length (stringVar);
    IF (startPos < stringLength) & (numberToDelete < stringLength-startPos) THEN
      (* `stringVar' has remaining characters beyond the deleted section;
         these have to be moved forward by `numberToDelete' characters *)
      FOR i := startPos TO stringLength-numberToDelete DO
        stringVar[i] := stringVar[i+numberToDelete]
      END
    ELSIF (startPos < stringLength) THEN
      stringVar[startPos] := 0
    END
  END Delete;

PROCEDURE Insert* (source: ARRAY OF LONGCHAR; startPos: LONGINT;
                   VAR destination: ARRAY OF LONGCHAR);
(**Inserts @oparam{source} into @oparam{destination} at position
   @oparam{startPos}.  After the call @oparam{destination} contains the string
   that is contructed by first splitting @oparam{destination} at the position
   @oparam{startPos} and then concatenating the first half, @oparam{source},
   and the second half.  The string value in @oparam{destination} is not
    altered if @oparam{startPos} is greater than @samp{Length(destination)}.  If
    @samp{startPos = Length(destination)}, then @oparam{source} is appended to
   @oparam{destination}.

   @precond
   @oparam{startPos} is not negative.
   @end precond  *)
  VAR
    sourceLength, destLength, destMax, i: LONGINT;
  BEGIN
    ASSERT (startPos >= 0);
    IF LEN (destination) = 0 THEN RETURN END;
    destLength := Length (destination);
    IF startPos > destLength THEN RETURN END;
    sourceLength := Length (source);
    destMax := LEN (destination)-1;
    IF (sourceLength < destMax-startPos) THEN
      (* `source' is inserted inside of `destination' *)
      IF (sourceLength > destMax-destLength) THEN
        (* `destination' too long, truncate it *)
        destLength := destMax-sourceLength;
        destination[destLength] := 0
      END;

      (* move tail section of `destination' *)
      FOR i := destLength TO startPos BY -1 DO
        destination[i+sourceLength] := destination[i]
      END
    ELSE
      (* `source' replaces `destination' from `startPos' on *)
      destination[destMax] := 0;         (* set string terminator *)
      sourceLength := destMax-startPos   (* truncate `source' *)
    END;
    (* copy characters from `source' to `destination' *)
    FOR i := 0 TO sourceLength-1 DO
      destination[startPos+i] := source[i]
    END
  END Insert;

PROCEDURE Replace* (source: ARRAY OF LONGCHAR; startPos: LONGINT;
                    VAR destination: ARRAY OF LONGCHAR);
(**Copies @oparam{source} into @oparam{destination}, starting at position
   @oparam{startPos}. Copying stops when all of @oparam{source} has been
   copied, or when the last character of the string value in
   @oparam{destination} has been replaced.  The string value in
   @oparam{destination} is not altered if @oparam{startPos} is greater than or
    equal to @samp{Length(destination)}.

   @precond
   @oparam{startPos} is not negative.
   @end precond  *)
  VAR
    destLength, i: LONGINT;
  BEGIN
    ASSERT (startPos >= 0);
    IF LEN (destination) = 0 THEN RETURN END;
    destLength := Length (destination);
    IF (startPos < destLength) THEN
      (* if `startPos' is inside `destination', then replace characters until
         the end of `source' or `destination' is reached *)
      i := 0;
      WHILE (startPos # destLength) & (source[i] # 0) DO
        destination[startPos] := source[i];
        INC (startPos);
        INC (i)
      END
    END
  END Replace;

PROCEDURE Append* (source: ARRAY OF LONGCHAR; VAR destination: ARRAY OF LONGCHAR);
(**Appends @oparam{source} to @oparam{destination}. *)
  VAR
    destLength, sourceLength, i: LONGINT;
  BEGIN
    IF LEN (destination) = 0 THEN RETURN END;
    destLength := Length (destination);
    sourceLength := Length (source);
    i := 0;
    WHILE (destLength < LEN (destination)-1) & (i < sourceLength) DO
      destination[destLength] := source[i];
      INC (destLength);
      INC (i)
    END;
    destination[destLength] := 0
  END Append;

PROCEDURE Concat* (source1, source2: ARRAY OF LONGCHAR;
                   VAR destination: ARRAY OF LONGCHAR);
(**Concatenates @oparam{source2} onto @oparam{source1} and copies the result
   into @oparam{destination}.  *)
  VAR
    i, j: LONGINT;
  BEGIN
    IF LEN (destination) = 0 THEN RETURN END;
    (* copy `source1' into `destination' *)
    i := 0;
    WHILE (i < LEN(destination)-1) & (source1[i] # 0) DO
      destination[i] := source1[i];
      INC (i)
    END;

    (* append `source2' to `destination' *)
    j := 0;
    WHILE (i < LEN (destination)-1) & (source2[j] # 0) DO
      destination[i] := source2[j];
      INC (j); INC (i)
    END;
    destination[i] := 0
  END Concat;



PROCEDURE CanAssignAll* (sourceLength: LONGINT; VAR destination: ARRAY OF LONGCHAR): BOOLEAN;
(**Returns @code{TRUE} if a number of characters, indicated by
   @oparam{sourceLength}, will fit into @oparam{destination}; otherwise returns
   @code{FALSE}.

   @precond
   @oparam{sourceLength} is not negative.
   @end precond  *)
  BEGIN
    ASSERT (sourceLength >= 0);
    RETURN (sourceLength < LEN (destination))
  END CanAssignAll;

PROCEDURE CanExtractAll* (sourceLength, startPos, numberToExtract: LONGINT;
                          VAR destination: ARRAY OF LONGCHAR): BOOLEAN;
(**Returns @code{TRUE} if there are @oparam{numberToExtract} characters
   starting at @oparam{startPos} and within the @oparam{sourceLength} of some
   string, and if the capacity of @oparam{destination} is sufficient to hold
   @oparam{numberToExtract} characters; otherwise returns @code{FALSE}.

   @precond
   @oparam{sourceLength}, @oparam{startPos}, and @oparam{numberToExtract} are
   not negative.
   @end precond  *)
  BEGIN
    ASSERT ((sourceLength >= 0) & (startPos >= 0) & (numberToExtract >= 0));
    RETURN (startPos <= sourceLength) & (numberToExtract <= sourceLength-startPos) &
           (numberToExtract < LEN (destination))
  END CanExtractAll;

PROCEDURE CanDeleteAll* (stringLength, startPos,
                        numberToDelete: LONGINT): BOOLEAN;
(**Returns @code{TRUE} if there are @oparam{numberToDelete} characters starting
   at @oparam{startPos} and within the @oparam{stringLength} of some string;
   otherwise returns @code{FALSE}.

   @precond
   @oparam{stringLength}, @oparam{startPos} and @oparam{numberToDelete} are not
   negative.
   @end precond  *)
  BEGIN
    ASSERT ((stringLength >= 0) & (startPos >= 0) & (numberToDelete >= 0));
    RETURN (startPos <= stringLength) & (numberToDelete <= stringLength-startPos)
  END CanDeleteAll;

PROCEDURE CanInsertAll* (sourceLength, startPos: LONGINT;
                         VAR destination: ARRAY OF LONGCHAR): BOOLEAN;
(**Returns @code{TRUE} if there is room for the insertion of
   @oparam{sourceLength} characters from some string into @oparam{destination}
   starting at @oparam{startPos}; otherwise returns @code{FALSE}.

   @precond
   @oparam{sourceLength} and @oparam{startPos} are not negative.
   @end precond  *)
  VAR
    lenDestination: LONGINT;
  BEGIN
    ASSERT ((sourceLength >= 0) & (startPos >= 0));
    IF LEN (destination) = 0 THEN RETURN FALSE END;
    lenDestination := Length (destination);
    RETURN (startPos <= lenDestination) &
            (sourceLength < LEN (destination)-lenDestination)
  END CanInsertAll;

PROCEDURE CanReplaceAll* (sourceLength, startPos: LONGINT;
                          VAR destination: ARRAY OF LONGCHAR): BOOLEAN;
(**Returns @code{TRUE} if there is room for the replacement of
   @oparam{sourceLength} characters in @oparam{destination} starting at
   @oparam{startPos}; otherwise returns @code{FALSE}.

   @precond
   @oparam{sourceLength} and @oparam{startPos} are not negative.
   @end precond  *)
  VAR lenDestination: LONGINT;
  BEGIN
    ASSERT ((sourceLength >= 0) & (startPos >= 0));
    IF LEN (destination) = 0 THEN RETURN FALSE END;
    lenDestination := Length (destination);
    RETURN (startPos <= lenDestination) & (sourceLength <= lenDestination-startPos)
  END CanReplaceAll;

PROCEDURE CanAppendAll* (sourceLength: LONGINT;
                         VAR destination: ARRAY OF LONGCHAR): BOOLEAN;
(**Returns @code{TRUE} if there is sufficient room in @oparam{destination} to
   append a string of length @oparam{sourceLength} to the string in
   @oparam{destination}; otherwise returns @code{FALSE}.

   @precond
   @oparam{sourceLength} is not negative.
   @end precond  *)
  BEGIN
    ASSERT (sourceLength >= 0);
    IF LEN (destination) = 0 THEN RETURN FALSE END;
    RETURN (sourceLength < LEN (destination)-Length (destination))
  END CanAppendAll;

PROCEDURE CanConcatAll* (source1Length, source2Length: LONGINT;
                         VAR destination: ARRAY OF LONGCHAR): BOOLEAN;
(**Returns @code{TRUE} if there is sufficient room in @oparam{destination} for
   two strings of lengths @oparam{source1Length} and @oparam{source2Length};
   otherwise returns @code{FALSE}.

   @precond
   @oparam{source1Length} and @oparam{source2Length} are not negative.
   @end precond  *)
  BEGIN
    ASSERT ((source1Length >= 0) & (source2Length >= 0));
    RETURN (source1Length < LEN (destination)) &
           (source2Length < LEN (destination)-source1Length)
  END CanConcatAll;



PROCEDURE Compare* (stringVal1, stringVal2: ARRAY OF LONGCHAR): CompareResults;
(**Returns @oconst{less}, @oconst{equal}, or @oconst{greater}, according as
   @oparam{stringVal1} is lexically less than, equal to, or greater than
   @oparam{stringVal2}. Comparison uses numeric UTF-16 code-unit order. *)
  VAR
    i: LONGINT;
  BEGIN
    i := 0;
    WHILE (stringVal1[i] # 0) & (stringVal1[i] = stringVal2[i]) DO
      INC (i)
    END;
    IF (stringVal1[i] < stringVal2[i]) THEN
      RETURN less
    ELSIF (stringVal1[i] > stringVal2[i]) THEN
      RETURN greater
    ELSE
      RETURN equal
    END
  END Compare;

PROCEDURE Equal* (stringVal1, stringVal2: ARRAY OF LONGCHAR): BOOLEAN;
(**Returns TRUE if both strings contain the same sequence of code units. *)
  VAR
    i: LONGINT;
  BEGIN
    i := 0;
    WHILE (stringVal1[i] # 0) & (stringVal1[i] = stringVal2[i]) DO
      INC (i)
    END;
    RETURN (stringVal1[i] = 0) & (stringVal2[i] = 0)
  END Equal;

PROCEDURE Equal8* (wide: ARRAY OF LONGCHAR; narrow: ARRAY OF CHAR): BOOLEAN;
(**Compares UTF-16 code units with unsigned Latin-1 bytes. *)
  VAR i: LONGINT;
  BEGIN
    i := 0;
    WHILE (i < LEN (wide)) & (i < LEN (narrow)) DO
      IF wide[i] # ORD (narrow[i]) THEN RETURN FALSE END;
      IF wide[i] = 0 THEN RETURN TRUE END;
      INC (i)
    END;
    RETURN FALSE
  END Equal8;

PROCEDURE FindNext* (pattern, stringToSearch: ARRAY OF LONGCHAR; startPos: LONGINT;
                     VAR patternFound: BOOLEAN; VAR posOfPattern: LONGINT);
(**Looks forward for next occurrence of @oparam{pattern} in
   @oparam{stringToSearch}, starting the search at position @oparam{startPos}.
   If @samp{startPos < Length(stringToSearch)} and @oparam{pattern} is found,
   @oparam{patternFound} is returned as @code{TRUE}, and @oparam{posOfPattern}
   contains the start position in @oparam{stringToSearch} of @oparam{pattern}.
   The position is a value in the range [startPos..Length(stringToSearch)-1].
   Otherwise @oparam{patternFound} is returned as @code{FALSE}, and
   @oparam{posOfPattern} is unchanged.  If @samp{startPos >
   Length(stringToSearch)-Length(Pattern)} then @oparam{patternFound} is
   returned as @code{FALSE}.

   @precond
   @oparam{startPos} is not negative.
   @end precond  *)
  VAR
    patternPos: LONGINT;
  BEGIN
    ASSERT (startPos >= 0);
    IF (startPos < Length (stringToSearch)) THEN
      patternPos := 0;
      LOOP
        IF (pattern[patternPos] = 0) THEN
          (* reached end of pattern *)
          patternFound := TRUE;
          posOfPattern := startPos-patternPos;
          EXIT
        ELSIF (stringToSearch[startPos] = 0) THEN
          (* end of string (but not of pattern) *)
          patternFound := FALSE;
          EXIT
        ELSIF (stringToSearch[startPos] = pattern[patternPos]) THEN
          (* characters identic, compare next one *)
          INC (startPos);
          INC (patternPos)
        ELSE
          (* difference found: reset indices and restart *)
          startPos := startPos-patternPos+1;
          patternPos := 0
        END
      END
    ELSE
      patternFound := FALSE
    END
  END FindNext;

PROCEDURE FindPrev* (pattern, stringToSearch: ARRAY OF LONGCHAR; startPos: LONGINT;
                     VAR patternFound: BOOLEAN; VAR posOfPattern: LONGINT);
(**Looks backward for the previous occurrence of @oparam{pattern} in
   @oparam{stringToSearch} and returns the position of the first character of
   the @oparam{pattern} if found.  The search for the pattern begins at
   @oparam{startPos}.  If @oparam{pattern} is found, @oparam{patternFound} is
   returned as @code{TRUE}, and @oparam{posOfPattern} contains the start
   position in @oparam{stringToSearch} of pattern in the range [0..startPos].
   Otherwise @oparam{patternFound} is returned as @code{FALSE}, and
   @oparam{posOfPattern} is unchanged.  The pattern might be found at the given
   value of @oparam{startPos}.  The search will fail if @oparam{startPos} is
   negative.  If @samp{startPos > Length(stringToSearch)-Length(pattern)} the
   whole string value is searched.  *)
  VAR
    patternPos, stringLength, patternLength: LONGINT;
  BEGIN
    (* correct `startPos' if it is larger than the possible searching range *)
    stringLength := Length (stringToSearch);
    patternLength := Length (pattern);
    IF (startPos > stringLength-patternLength) THEN
      startPos := stringLength-patternLength
    END;

    IF (startPos >= 0) THEN
      patternPos := 0;
      LOOP
        IF (pattern[patternPos] = 0) THEN
          (* reached end of pattern *)
          patternFound := TRUE;
          posOfPattern := startPos-patternPos;
          EXIT
        ELSIF (stringToSearch[startPos] # pattern[patternPos]) THEN
          (* characters differ: reset indices and restart *)
          IF (startPos > patternPos) THEN
            startPos := startPos-patternPos-1;
            patternPos := 0
          ELSE
            (* reached beginning of `stringToSearch' without finding a match *)
            patternFound := FALSE;
            EXIT
          END
        ELSE  (* characters identic, compare next one *)
          INC (startPos);
          INC (patternPos)
        END
      END
    ELSE
      patternFound := FALSE
    END
  END FindPrev;

PROCEDURE FindDiff* (stringVal1, stringVal2: ARRAY OF LONGCHAR;
                     VAR differenceFound: BOOLEAN;
                     VAR posOfDifference: LONGINT);
(**Compares the string values in @oparam{stringVal1} and @oparam{stringVal2}
   for differences.  If they are equal, @oparam{differenceFound} is returned as
   @code{FALSE}, and @code{TRUE} otherwise.  If @oparam{differenceFound} is
   @code{TRUE}, @oparam{posOfDifference} is set to the position of the first
   difference; otherwise @oparam{posOfDifference} is unchanged.  *)
  VAR
    i: LONGINT;
  BEGIN
    i := 0;
    WHILE (stringVal1[i] # 0) & (stringVal1[i] = stringVal2[i]) DO
      INC (i)
    END;
    differenceFound := (stringVal1[i] # 0) OR (stringVal2[i] # 0);
    IF differenceFound THEN
      posOfDifference := i
    END
  END FindDiff;


PROCEDURE Capitalize* (VAR stringVar: ARRAY OF LONGCHAR);
(**Applies oo2c's ASCII and Latin-1 CAP mapping to each code unit. *)
  VAR
    i: LONGINT;
  BEGIN
    i := 0;
    WHILE (stringVar[i] # 0) DO
      IF (61H <= stringVar[i]) & (stringVar[i] <= 7AH) OR
         (0E0H <= stringVar[i]) & (stringVar[i] < 0FFH) & (stringVar[i] # 0F7H) THEN
        DEC (stringVar[i], 20H)
      END;
      INC (i)
    END
  END Capitalize;


PROCEDURE Long* (source: ARRAY OF CHAR; VAR destination: ARRAY OF LONGCHAR);
(**Widens Latin-1 octets to UTF-16 code units, with bounded, terminated output. *)
  VAR i: LONGINT;
  BEGIN
    IF LEN (destination) = 0 THEN RETURN END;
    i := 0;
    WHILE (i < LEN (destination)-1) & (source[i] # 0X) DO
      destination[i] := ORD (source[i]); INC (i)
    END;
    destination[i] := 0
  END Long;

PROCEDURE Append8* (source: ARRAY OF CHAR; VAR destination: ARRAY OF LONGCHAR);
(**Appends narrow Latin-1 text, widening each octet to a code unit. *)
  VAR i, destLength: LONGINT;
  BEGIN
    IF LEN (destination) = 0 THEN RETURN END;
    destLength := Length (destination);
    i := 0;
    WHILE (destLength < LEN (destination)-1) & (source[i] # 0X) DO
      destination[destLength] := ORD (source[i]);
      INC (destLength); INC (i)
    END;
    destination[destLength] := 0
  END Append8;

PROCEDURE Short* (source: ARRAY OF LONGCHAR; repl: CHAR; VAR destination: ARRAY OF CHAR);
(**Copies @oparam{source} to @oparam{destination}, converting @samp{LONGCHAR}
   values to CHAR on the way.  @samp{LONGCHAR} characters outside the range
   @samp{[MIN(CHAR)..MAX(CHAR)]} are replaced by the character @oparam{repl}.  *)
  VAR
    i, len: LONGINT;
  BEGIN
    IF LEN (destination) = 0 THEN RETURN END;
    len := LEN (destination)-1;
    i := 0;
    WHILE (i < len) & (source[i] # 0) DO
      IF (0 <= source[i]) & (source[i] <= 0FFH) THEN
        destination[i] := CHR (source[i])
      ELSE
        destination[i] := repl
      END;
      INC (i)
    END;
    destination[i] := 0X
  END Short;

END LongStrings.
