(*      $Id: Regexp.Mod,v 1.2 2001/03/20 22:16:32 mva Exp $   *)
MODULE XMLRegexp;
(*  Creates regular expression data structure from `children' content model.
    Copyright (C) 2001  Michael van Acken

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


IMPORT
  Out, LongStrings, Limits := XMLLimits, DTD := XMLDTD;


TYPE
  Regexp* = POINTER TO RegexpDesc;
  State = LONGINT;
  States = POINTER TO ARRAY OF RECORD
    elem: DTD.String;
    next1, next2: State;
  END;
  RegexpDesc = RECORD
    (DTD.RegexpInfoDesc)
    limits: Limits.Budget;
    states: States;
    initialState: State;
    size: State;
  END;

TYPE
  Set = POINTER TO SetDesc;
  Members = POINTER TO ARRAY OF State;
  SetDesc = RECORD
    limits: Limits.Budget;
    members: Members;
    size: LONGINT;
  END;

TYPE
  Matcher* = POINTER TO MatcherDesc;
  MatcherDesc = RECORD
    limits: Limits.Budget;
    states: States;
    current: Set;
  END;

CONST
  endOfRegexp = -1;


PROCEDURE DumpRegexp (regexp: Regexp);
  VAR
    str: ARRAY 128 OF CHAR;
    i: LONGINT;
  BEGIN
    Out.String ("initial state: ");
    Out.Int (regexp. initialState, 0);
    Out.Ln;
    FOR i := 0 TO regexp. size-1 DO
      Out.Int (i, 0);
      Out.String (": name=");
      IF (regexp. states[i]. elem = NIL) THEN
        Out.String ("*EMPTY*")
      ELSE
        LongStrings.Short (regexp. states[i]. elem^, "?", str);
        Out.String (str)
      END;
      Out.String (", next1=");
      Out.Int (regexp. states[i]. next1, 0);
      Out.String (", next2=");
      Out.Int (regexp. states[i]. next2, 0);
      Out.Ln
    END
  END DumpRegexp;


PROCEDURE Step (limits: Limits.Budget; n: LONGINT): BOOLEAN;
  BEGIN RETURN (limits = NIL) OR limits. Charge (Limits.work, n) END Step;

PROCEDURE NewLimited* (contentModel: DTD.CP; limits: Limits.Budget): Regexp;
(**@precond
   The @oparam{contentModel} is neither @code{EMPTY}, @code{ANY}, nor
   @samp{Mixed}.
   @end precond  *)

  VAR
    regexp: Regexp;
    
  PROCEDURE NewState (): State;
    VAR
      newState: State;
      new: States;
      i: LONGINT;
    BEGIN
      IF ~Step (limits, 1) THEN RETURN 0 END;
      IF (regexp. size = LEN (regexp. states^)) THEN
        NEW (new, LEN (regexp. states^)*2);
        FOR i := 0 TO LEN (regexp. states^)-1 DO
          new[i] := regexp. states[i]
        END;
        FOR i := LEN (regexp. states^) TO LEN (new^)-1 DO
          new[i]. elem := NIL
        END;
        regexp. states := new
      END;
      newState := regexp. size;
      regexp. states[newState]. elem := NIL; (* empty node *)
      regexp. states[newState]. next1 := -2;
      regexp. states[newState]. next2 := -2;
      INC (regexp. size);
      RETURN newState
    END NewState;

  PROCEDURE Convert (cp: DTD.CP; start, end: State);
  (* Converts content particle `cp' into a regular expression machine.  The
     first state of the machine is placed into `start', overwriting the
     state data that is already in there.  All exists from the machine
     point to state `end'  .  *)
    VAR
      subStart: State;
    
    PROCEDURE ConvertCP (cp: DTD.CP; start, end: State);
      PROCEDURE ConvertChoiceList (ptr: DTD.CP; start, end: State);
        VAR
          first1, first2: State;
        BEGIN
          WHILE ptr # NIL DO
            IF ~Step (limits, 1) THEN RETURN END;
            IF ptr. next = NIL THEN Convert (ptr, start, end); RETURN END;
            first1 := NewState();
            Convert (ptr, first1, end);
            first2 := NewState();
            IF ~Step (limits, 0) THEN RETURN END;
            regexp. states[start]. next1 := first1;
            regexp. states[start]. next2 := first2;
            start := first2; ptr := ptr. next
          END
        END ConvertChoiceList;

      PROCEDURE ConvertSeqList (ptr: DTD.CP; start, end: State);
        VAR
          first1: State;
        BEGIN
          WHILE ptr # NIL DO
            IF ~Step (limits, 1) THEN RETURN END;
            IF ptr. next = NIL THEN Convert (ptr, start, end); RETURN END;
            first1 := NewState();
            Convert (ptr, start, first1);
            start := first1; ptr := ptr. next
          END
        END ConvertSeqList;

      BEGIN
        IF ~Step (limits, 1) THEN RETURN END;
        WITH cp: DTD.NameCP DO
          regexp. states[start]. elem := cp. name;
          regexp. states[start]. next1 := end;
          regexp. states[start]. next2 := end

        | cp: DTD.ChoiceCP DO
          ConvertChoiceList (cp. list, start, end)

        | cp: DTD.SeqCP DO
          ConvertSeqList (cp. list, start, end)
        END
      END ConvertCP;
      
    BEGIN
      IF ~Step (limits, 1) THEN RETURN END;
      IF (limits # NIL) & ~limits. Enter() THEN RETURN END;
      CASE cp. cpMode OF
      | DTD.cpOnce:
        ConvertCP (cp, start, end)
      | DTD.cpOptional:
        subStart := NewState();
        ConvertCP (cp, subStart, end);
        regexp. states[start]. next1 := end;
        regexp. states[start]. next2 := subStart
      | DTD.cpRepeat0:
        subStart := NewState ();
        ConvertCP (cp, subStart, start);
        regexp. states[start]. next1 := end;
        regexp. states[start]. next2 := subStart
      | DTD.cpRepeat1:
        subStart := NewState ();
        ConvertCP (cp, start, subStart);
        regexp. states[subStart]. next1 := end;
        regexp. states[subStart]. next2 := start
      END;
      IF limits # NIL THEN limits. Leave END
    END Convert;
  
  BEGIN
    NEW (regexp);
    regexp. limits := limits;
    NEW (regexp. states, 16);
    regexp. size := 0;
    regexp. initialState := NewState();
    Convert (contentModel, regexp. initialState, endOfRegexp);
    IF ~Step (limits, 0) THEN RETURN NIL END;
    (*DumpRegexp (regexp);*)
    RETURN regexp
  END NewLimited;

PROCEDURE New* (contentModel: DTD.CP): Regexp;
  BEGIN RETURN NewLimited (contentModel, NIL) END New;


PROCEDURE NewSet(limits: Limits.Budget): Set;
  VAR
    set: Set;
  BEGIN
    NEW (set);
    set. limits := limits;
    NEW (set. members, 8);
    set. size := 0;
    RETURN set
  END NewSet;

PROCEDURE Include (set: Set; element: State);
  VAR
    i, j: LONGINT;
    new: Members;
  BEGIN
    IF ~Step (set. limits, 1) THEN RETURN END;
    i := 0;
    WHILE (i # set. size) & (set. members[i] # element) DO
      IF ~Step (set. limits, 1) THEN RETURN END;
      INC (i)
    END;
    
    IF (i = set. size) THEN
      IF (i = LEN (set. members^)) THEN
        NEW (new, i*2);
        FOR j := 0 TO i-1 DO
          new[j] := set. members[j]
        END;
        set. members := new
      END;
      set. members[i] := element;
      INC (set. size)
    END
  END Include;

PROCEDURE IsMember (set: Set; element: State): BOOLEAN;
  VAR
    i: LONGINT;
  BEGIN
    i := 0;
    WHILE (i # set. size) & (set. members[i] # element) DO
      INC (i)
    END;
    RETURN (i # set. size)
  END IsMember;

PROCEDURE Expand (states: States; set: Set);
(* Adds epsilon-reachable states, visiting each state at most once. *)
  VAR i: LONGINT; s: State;
  BEGIN
    i := 0;
    WHILE i < set. size DO
      IF ~Step (set. limits, 1) THEN RETURN END;
      s := set. members[i];
      IF (s # endOfRegexp) & (states[s]. elem = NIL) THEN
        Include (set, states[s]. next1);
        Include (set, states[s]. next2)
      END;
      INC (i)
    END
  END Expand;

PROCEDURE (regexp: Regexp) IsDeterministic* (): BOOLEAN;
(**Checks that each input name identifies one content-particle occurrence,
   both at the start and after each named particle. *)
  VAR closure: Set; i, j, k: LONGINT; s, t: State;
  BEGIN
    FOR i := -1 TO regexp. size-1 DO
      IF ~Step (regexp. limits, 1) THEN RETURN FALSE END;
      IF (i = -1) OR (regexp. states[i]. elem # NIL) THEN
        closure := NewSet(regexp. limits);
        IF i = -1 THEN Include (closure, regexp. initialState)
        ELSE Include (closure, regexp. states[i]. next1)
        END;
        Expand (regexp. states, closure);
        FOR j := 0 TO closure. size-1 DO
          IF ~Step (regexp. limits, 1) THEN RETURN FALSE END;
          s := closure. members[j];
          IF (s # endOfRegexp) & (regexp. states[s]. elem # NIL) THEN
            FOR k := j+1 TO closure. size-1 DO
              IF ~Step (regexp. limits, 1) THEN RETURN FALSE END;
              t := closure. members[k];
              IF (t # endOfRegexp) & (regexp. states[t]. elem # NIL) &
                 LongStrings.Equal (regexp. states[s]. elem^, regexp. states[t]. elem^) THEN
                RETURN FALSE
              END
            END
          END
        END
      END
    END;
    RETURN Step (regexp. limits, 0)
  END IsDeterministic;



PROCEDURE NewMatcher* (regexp: Regexp): Matcher;
  VAR
    m: Matcher;
  BEGIN
    NEW (m);
    m. limits := regexp. limits;
    m. states := regexp. states;
    m. current := NewSet(m. limits);
    Include (m. current, regexp. initialState);
    RETURN m
  END NewMatcher;

PROCEDURE (m: Matcher) Matches* (name: DTD.String): BOOLEAN;
  VAR
    i: LONGINT;
    s: State;
    newSet: Set;
  BEGIN
    IF ~Step (m. limits, 1) THEN RETURN FALSE END;
    IF (m. current. size = 0) THEN
      (* a previous mismatch reduced the current set of states to the empty 
         set; no need to report further mismatches *)
      RETURN TRUE
    ELSE
      newSet := NewSet(m. limits);
      i := 0;
      WHILE (i # m. current. size) DO
        IF ~Step (m. limits, 1) THEN RETURN FALSE END;
        s := m. current. members[i];
        IF (s = endOfRegexp) THEN
          (* this pseudo state does not match any element *)
        ELSIF (m. states[s]. elem = NIL) THEN
          Include (m. current, m. states[s]. next1);
          IF (m. states[s]. next1 # m. states[s]. next2) THEN
            Include (m. current, m. states[s]. next2)
          END
        ELSIF LongStrings.Equal (m. states[s]. elem^, name^) THEN
          Include (newSet, m. states[s]. next1)
        END;
        INC (i)
      END;

      IF (newSet. size # 0) THEN
        m. current := newSet;
        RETURN Step (m. limits, 0)
      ELSE
        RETURN FALSE
      END
    END
  END Matches;

PROCEDURE (m: Matcher) EndOfRegexp* (): BOOLEAN;
  VAR
    i: LONGINT;
    s: State;
  BEGIN
    i := 0;
    WHILE (i # m. current. size) DO
      IF ~Step (m. limits, 1) THEN RETURN FALSE END;
      s := m. current. members[i];
      IF (s = endOfRegexp) THEN
        RETURN TRUE
      ELSIF (m. states[s]. elem = NIL) THEN
        Include (m. current, m. states[s]. next1);
        IF (m. states[s]. next1 # m. states[s]. next2) THEN
          Include (m. current, m. states[s]. next2)
        END
      END;
      INC (i)
    END;
    RETURN FALSE
  END EndOfRegexp;

PROCEDURE (m: Matcher) ExpectedTags* (currentElement: DTD.String): DTD.String;
(* pre: `Matches' reported FALSE *)
  VAR
    i, len: LONGINT;
    str: DTD.String;
  BEGIN
    IF (m. current. size = 0) THEN
      RETURN NIL
    ELSE
      (* sort set of element names before putting the string together?*)
      
      len := 0;
      i := 0;
      WHILE (i # m. current. size) DO
        IF ~Step (m. limits, 1) THEN RETURN NIL END;
        IF (m. current. members[i] = endOfRegexp) THEN
          INC (len, LongStrings.Length (currentElement^)+2)
        ELSIF (m. states[m. current. members[i]]. elem # NIL) THEN
          INC (len, LongStrings.Length (m. states[m. current. members[i]]. elem^)+1)
        END;
        INC (i)
      END;
      
      NEW (str, len+1);
      str[0] := 0;
      i := 0;
      WHILE (i # m. current. size) DO
        IF ~Step (m. limits, 1) THEN RETURN NIL END;
        IF (m. current. members[i] = endOfRegexp) THEN
          LongStrings.Append8 (" /", str^);
          LongStrings.Append (currentElement^, str^)
        ELSIF (m. states[m. current. members[i]]. elem # NIL) THEN
          LongStrings.Append8 (" ", str^);
          LongStrings.Append (m. states[m. current. members[i]]. elem^, str^)
        END;
        INC (i)
      END;
      RETURN str
    END
  END ExpectedTags;

END XMLRegexp.
