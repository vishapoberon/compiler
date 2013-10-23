(* Ulm's Oberon Library
   Copyright (C) 1989-1994 by University of Ulm, SAI, D-89069 Ulm, Germany
   ----------------------------------------------------------------------------
   Ulm's Oberon Library is free software; you can redistribute it
   and/or modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either version
   2 of the License, or (at your option) any later version.

   Ulm's Oberon Library is distributed in the hope that it will be
   useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
   ----------------------------------------------------------------------------
   E-mail contact: oberon@mathematik.uni-ulm.de
   ----------------------------------------------------------------------------
   $Id: SysConversi.om,v 1.2 1997/07/30 09:38:16 borchert Exp $
   ----------------------------------------------------------------------------
   $Log: SysConversi.om,v $
   Revision 1.2  1997/07/30  09:38:16  borchert
   bug in ReadConv fixed: cv.flags was used but not set for
                          counts > 1

   Revision 1.1  1994/02/23  07:58:28  borchert
   Initial revision

   ----------------------------------------------------------------------------
   AFB 8/90
   adapted to linux cae 02/01
   ----------------------------------------------------------------------------
*)

MODULE ulmSysConversions;

   (* convert Oberon records to/from C structures *)

   IMPORT Events := ulmEvents, Objects := ulmObjects, Priorities := ulmPriorities, Streams := ulmStreams, Strings := ulmStrings,
      SYS := SYSTEM, SysTypes := ulmSysTypes, Texts := ulmTexts;

   TYPE
      Address* = SysTypes.Address;
      Size* = Address;

   (* format:

      Format = Conversion { "/" Conversion } .
      Conversion = [ Factors ] ConvChars [ Comment ] .
      Factors = Array | Factor | Array Factor | Factor Array .
      Array = Integer ":" .
      Factor = Integer "*" .
      ConvChars = OberonType CType | Skip CType | OberonType Skip .
      OberonType = "a" | "b" | "c" | "s" | "i" | "l" | "S" .
      CType = "a" | "c" | "s" | "i" | "l" .
      Integer = Digit { Digit } .
      Digit = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" .
      Skip = "-" .
      Comment = "=" { AnyChar } .
      AnyChar = (* all characters except "/" *) .

      Oberon data types:

      a: Address
      b: BYTE
      B: BOOLEAN
      c: CHAR
      s: SHORTINT
      i: INTEGER
      l: LONGINT
      S: SET

      C data types:

      a: char *
      c: /* signed */ char
      C: unsigned char
      s: short int
      S: unsigned short int
      i: int
      I: unsigned int
      u: unsigned int
      l: long int
      L: unsigned long int

      example:

      conversion from

	 Rec =
	    RECORD
	       a, b: INTEGER;
	       c: CHAR;
	       s: SET;
	       f: ARRAY 3 OF INTEGER;
	    END;

      to

	 struct rec {
	    short a, b;
	    char c;
	    int xx;	/* to be skipped on conversion */
	    int s;
	    int f[3];
	 };

      or vice versa:

	 "2*is=a,b/cc=c/-i=xx/Si=s/3:ii=f"

      The comments allow to give the field names.
   *)

   CONST
      (* conversion flags *)
      unsigned = 0;		(* suppress sign extension *)
      boolean = 1;		(* convert anything # 0 to 1 *)
   TYPE
      Flags = SET;
      Event* = POINTER TO EventRec;
      EventRec* =
	 RECORD
	    (Events.EventRec)
	    format*: Events.Message;
	 END;
      ConvStream = POINTER TO ConvStreamRec;
      ConvStreamRec =
	 RECORD
	    fmt: Texts.Text;
	    char: CHAR;
	    eof: BOOLEAN;
	    (* 1: Oberon type
	       2: C type
	    *)
	    type1, type2: CHAR; length: INTEGER; left: INTEGER;
	    offset1, offset2: Address;
	    size1, size2: Address; elementsleft: INTEGER; flags: Flags;
	 END;

      Format = POINTER TO FormatRec;
      FormatRec* =
	 RECORD
	    (Objects.ObjectRec)
	    offset1, offset2: Address;
	    size1, size2: Address;
	    flags: Flags;
	    next: Format;
	 END;
   VAR
      badformat*: Events.EventType;

   PROCEDURE Error(cv: ConvStream; msg: ARRAY OF CHAR);
      VAR
	 event: Event;
   BEGIN
      NEW(event);
      event.type := badformat;
      event.message := "SysConversions: ";
      Strings.Concatenate(event.message, msg);
      Strings.Read(event.format, cv.fmt);
      Events.Raise(event);
      cv.eof := TRUE;
      cv.char := 0X;
      cv.left := 0;
      cv.elementsleft := 0;
   END Error;

   PROCEDURE SizeError(msg, format: ARRAY OF CHAR);
      VAR
	 event: Event;
   BEGIN
      NEW(event);
      event.type := badformat;
      event.message := "SysConversions: ";
      Strings.Concatenate(event.message, msg);
      COPY(format, event.format);
      Events.Raise(event);
   END SizeError;

   PROCEDURE NextCh(cv: ConvStream);
   BEGIN
      cv.eof := cv.eof OR ~Streams.ReadByte(cv.fmt, cv.char) OR (cv.char = 0X);
      IF cv.eof THEN
	 cv.char := 0X;
      END;
   END NextCh;

   PROCEDURE IsDigit(ch: CHAR) : BOOLEAN;
   BEGIN
      RETURN (ch >= "0") & (ch <= "9")
   END IsDigit;

   PROCEDURE ReadInt(cv: ConvStream; VAR i: INTEGER);
   BEGIN
      i := 0;
      REPEAT
	 i := 10 * i + ORD(cv.char) - ORD("0");
	 NextCh(cv);
      UNTIL ~IsDigit(cv.char);
   END ReadInt;

   PROCEDURE Open(VAR cv: ConvStream; format: ARRAY OF CHAR);
   BEGIN
      NEW(cv);
      Texts.Open(SYS.VAL(Streams.Stream, cv.fmt));
      Strings.Write(cv.fmt, format);
      cv.left := 0; cv.elementsleft := 0;
      cv.offset1 := 0; cv.offset2 := 0;
      cv.eof := FALSE;
      NextCh(cv);
   END Open;

   PROCEDURE Close(VAR cv: ConvStream);
   BEGIN
      IF ~Streams.Close(cv.fmt) THEN END;
   END Close;

   PROCEDURE ScanConv(cv: ConvStream;
		      VAR type1, type2: CHAR;
		      VAR length: INTEGER) : BOOLEAN;
      VAR
	 i: INTEGER;
	 factor: INTEGER;
   BEGIN
      IF cv.left > 0 THEN
	 type1 := cv.type1;
	 type2 := cv.type2;
	 length := cv.length;
	 DEC(cv.left);
	 RETURN TRUE
      END;
      IF cv.char = "/" THEN
	 NextCh(cv);
      END;
      IF cv.eof THEN
	 RETURN FALSE
      END;
      factor := 0; length := 0;
      WHILE IsDigit(cv.char) DO
	 ReadInt(cv, i);
	 IF i <= 0 THEN
	    Error(cv, "integer must be positive"); RETURN FALSE
	 END;
	 IF cv.char = ":" THEN
	    IF length # 0 THEN
	       Error(cv, "multiple length specification"); RETURN FALSE
	    END;
	    length := i;
	    NextCh(cv);
	 ELSIF cv.char = "*" THEN
	    IF factor # 0 THEN
	       Error(cv, "multiple factor specification"); RETURN FALSE
	    END;
	    factor := i; cv.left := factor - 1;
	    NextCh(cv);
	 ELSE
	    Error(cv, "factor or length expected"); RETURN FALSE
	 END;
      END;
      type1 := cv.char; NextCh(cv);
      type2 := cv.char; NextCh(cv);
      IF cv.left > 0 THEN
	 cv.type1 := type1; cv.type2 := type2; cv.length := length;
      END;
      IF cv.char = "=" THEN (* comment *)
	 REPEAT
	    NextCh(cv);
	 UNTIL cv.eof OR (cv.char = "/");
      END;
      RETURN TRUE
   END ScanConv;

   PROCEDURE Align(VAR offset: Address; boundary: Address);
   BEGIN
      IF SYS.VAL (INTEGER, offset) MOD SYS.VAL (INTEGER, boundary) # 0 THEN
	 offset := SYS.VAL (INTEGER, offset) + (SYS.VAL (INTEGER, boundary) - SYS.VAL (INTEGER, offset) MOD SYS.VAL (INTEGER, boundary));
      END;
   END Align;

   PROCEDURE ReadConv(cv: ConvStream;
		      VAR offset1, offset2: Address;
		      VAR size1, size2: Address;
		      VAR flags: Flags) : BOOLEAN;
      VAR
	 type1, type2: CHAR;
	 length: INTEGER;
	 align: BOOLEAN;
	 boundary: INTEGER;
   BEGIN
      IF cv.elementsleft > 0 THEN
	 DEC(cv.elementsleft);

	 (* Oberon type *)
	 IF size1 > SIZE(SYS.BYTE) THEN
	    Align(cv.offset1, SIZE(INTEGER));
	 END;
	 offset1 := cv.offset1; cv.offset1 := SYS.VAL (INTEGER, cv.offset1) + size1;
	 size1 := cv.size1; size2 := cv.size2; flags := cv.flags;
	 IF (size1 > 0) & (cv.elementsleft = 0) THEN
	    Align(cv.offset1, SIZE(INTEGER));
	 END;

	 (* C type *)
	 IF size2 > 1 THEN
	    Align(cv.offset2, 2);
	 END;
	 offset2 := cv.offset2; cv.offset2 := SYS.VAL (INTEGER, cv.offset2) + SYS.VAL (INTEGER, size2);

	 RETURN TRUE
      END;
      IF ScanConv(cv, type1, type2, length) THEN
	 flags := {};
	 (* Oberon type *)
	 CASE type1 OF
	 | "a":   size1 := SIZE(Address);  INCL(flags, unsigned);
	 | "b":   size1 := SIZE(SYS.BYTE);     INCL(flags, unsigned);
	 | "B":   size1 := SIZE(BOOLEAN);  INCL(flags, boolean);
	 | "c":   size1 := SIZE(CHAR);     INCL(flags, unsigned);
	 | "s":   size1 := SIZE(SHORTINT);
	 | "i":   size1 := SIZE(INTEGER);
	 | "l":   size1 := SIZE(LONGINT);
	 | "S":   size1 := SIZE(SET);      INCL(flags, unsigned);
	 | "-":   size1 := 0;
	 ELSE     Error(cv, "bad Oberon type specifier"); RETURN FALSE
	 END;
	 IF size1 > 0 THEN
	    IF length > 0 THEN
	       Align(cv.offset1, SIZE(INTEGER));
	    ELSIF size1 > SIZE(SYS.BYTE) THEN
	       Align(cv.offset1, SIZE(INTEGER));
	    END;
	 END;
	 offset1 := cv.offset1; cv.offset1 := SYS.VAL (INTEGER, cv.offset1) + size1;

	 (* C type *)
	 CASE type2 OF
	 | "a":   size2 := 4; INCL(flags, unsigned); (* char*              *)
	 | "c":   size2 := 1;                        (* /* signed */ char  *)
	 | "C":   size2 := 1; INCL(flags, unsigned); (* unsigned char      *)
	 | "s":   size2 := 2;                        (* short int          *)
	 | "S":   size2 := 2; INCL(flags, unsigned); (* unsigned short int *)
	 | "i":   size2 := 4;                        (* int                *)
	 | "I":   size2 := 4; INCL(flags, unsigned); (* unsigned int       *)
	 | "u":   size2 := 4; INCL(flags, unsigned); (* unsigned int       *)
	 | "l":   size2 := 4;                        (* long int           *)
	 | "L":   size2 := 4; INCL(flags, unsigned); (* long int           *)
	 | "-":   size2 := 0;
	 ELSE     Error(cv, "bad C type specifier"); RETURN FALSE
	 END;
	 IF size2 > 1 THEN
	    Align(cv.offset2, size2);
	 END;
	 offset2 := cv.offset2; cv.offset2 := SYS.VAL (INTEGER, cv.offset2) + SYS.VAL (INTEGER, size2);

	 cv.size1 := size1; cv.size2 := size2;
	 IF length > 0 THEN
	    cv.elementsleft := length - 1;
	    cv.flags := flags;
	 END;
	 RETURN TRUE
      ELSE
	 RETURN FALSE
      END;
   END ReadConv;

   PROCEDURE Convert(from, to: Address; ssize, dsize: Address; flags: Flags);
      TYPE
	 Bytes = ARRAY 8 OF CHAR;
	 Pointer = POINTER TO Bytes;
      VAR
	 dest, source: Pointer;
	 dindex, sindex: INTEGER;
	 nonzero: BOOLEAN;
	 fill : CHAR;
   BEGIN
      IF ssize > 0 THEN
	 dest := SYS.VAL(Pointer, to);
	 source := SYS.VAL(Pointer, from);
	 dindex := 0; sindex := 0;
	 IF boolean IN flags THEN
	    nonzero := FALSE;
	    WHILE ssize > 0 DO
	       nonzero := nonzero OR (source[sindex] # 0X);
	       INC(sindex); ssize := SYS.VAL (INTEGER, ssize) - 1;
	    END;
	    IF dsize > 0 THEN
	       IF nonzero THEN
		  dest[dindex] := 1X;
	       ELSE
		  dest[dindex] := 0X;
	       END;
	       dsize := dsize - 1; INC (dindex);
	    END;
	    WHILE dsize > 0 DO
	       dest[dindex] := 0X;
	       dsize := SYS.VAL (INTEGER, dsize) - 1; INC(dindex);
	    END;
	 ELSE
	    WHILE (dsize > 0) & (ssize > 0) DO
	       dest[dindex] := source[sindex];
	       ssize := SYS.VAL (INTEGER, ssize) - 1;
	       dsize := dsize - 1;
	       INC(dindex); INC(sindex);
	    END;
	    IF dsize > 0 THEN
	       (* sindex has been incremented at least once because
	        * ssize and dsize were greater than 0, i.e. sindex-1
		* is a valid inex. *)
	       fill := 0X;
	       IF ~(unsigned IN flags) & (source[sindex-1] >= 080X) THEN
	          fill := 0FFX;
	       END;
	    END;
	    WHILE dsize > 0 DO
	       dest[dindex] := fill;
	       dsize := SYS.VAL (INTEGER, dsize) - 1; INC(dindex);
	    END;
	 END;
      END;
   END Convert;

   PROCEDURE ByAddrToC*(from, to: Address; format: ARRAY OF CHAR);
      VAR
	 cv: ConvStream;
	 offset1, offset2, size1, size2: Address;
	 flags: Flags;
   BEGIN
      Open(cv, format);
      WHILE ReadConv(cv, offset1, offset2, size1, size2, flags) DO
	 Convert(from + offset1, to + offset2, size1, size2, flags);
      END;
      Close(cv);
   END ByAddrToC;

   PROCEDURE ByAddrFromC*(from, to: Address; format: ARRAY OF CHAR);
      VAR
	 cv: ConvStream;
	 offset1, offset2, size1, size2: Address;
	 flags: Flags;
   BEGIN
      Open(cv, format);
      WHILE ReadConv(cv, offset1, offset2, size1, size2, flags) DO
	 Convert(from + offset2, to + offset1, size2, size1, flags);
      END;
      Close(cv);
   END ByAddrFromC;

   PROCEDURE CSize*(format: ARRAY OF CHAR) : Size;
      (* returns the size of the C-structure described by `format' *)
      VAR
	 cv: ConvStream;
	 offset1, offset2, size1, size2: Address;
	 size: Address;
	 flags: Flags;
   BEGIN
      Open(cv, format);
      WHILE ReadConv(cv, offset1, offset2, size1, size2, flags) DO END;
      Close(cv);
      size := offset2 + size2;
      Align(size, 2);
      RETURN size
   END CSize;

   PROCEDURE OberonSize*(format: ARRAY OF CHAR) : Size;
      (* returns the size of the Oberon-structure described by `format' *)
      VAR
	 cv: ConvStream;
	 offset1, offset2, size1, size2: Address;
	 size: Address;
	 flags: Flags;
   BEGIN
      Open(cv, format);
      WHILE ReadConv(cv, offset1, offset2, size1, size2, flags) DO END;
      Close(cv);
      size := offset1 + size1;
      Align(size, SIZE(INTEGER));
      RETURN size
   END OberonSize;

   PROCEDURE ToC*(VAR from, to: ARRAY OF SYS.BYTE; format: ARRAY OF CHAR);
   BEGIN
      IF OberonSize(format) > LEN(from) THEN
	 SizeError("Oberon record is too small", format); RETURN
      END;
      IF CSize(format) > LEN(to) THEN
	 SizeError("C structure is too small", format); RETURN
      END;
      ByAddrToC(SYS.ADR(from), SYS.ADR(to), format);
   END ToC;

   PROCEDURE FromC*(VAR from, to: ARRAY OF SYS.BYTE; format: ARRAY OF CHAR);
   BEGIN
      IF OberonSize(format) > LEN(to) THEN
	 SizeError("Oberon record is too small", format); RETURN
      END;
      IF CSize(format) > LEN(from) THEN
	 SizeError("C structure is too small", format); RETURN
      END;
      ByAddrFromC(SYS.ADR(from), SYS.ADR(to), format);
   END FromC;

   PROCEDURE Compile*(VAR fmt: Format; format: ARRAY OF CHAR);
      (* translate format into an internal representation
	 which is later referenced by fmt;
	 ByFmtToC and ByFmtFromC are faster than ToC and FromC
      *)
      VAR
	 cv: ConvStream;
	 offset1, offset2, size1, size2: Address;
	 flags: Flags;
	 element: Format;
	 head, tail: Format;
   BEGIN
      Open(cv, format);
      head := NIL; tail := NIL;
      WHILE ReadConv(cv, offset1, offset2, size1, size2, flags) DO
	 NEW(element);
	 element.offset1 := offset1;
	 element.offset2 := offset2;
	 element.size1 := size1;
	 element.size2 := size2;
	 element.flags := flags;
	 element.next := NIL;
	 IF tail # NIL THEN
	    tail.next := element;
	 ELSE
	    head := element;
	 END;
	 tail := element;
      END;
      fmt := head;
      Close(cv);
   END Compile;

   PROCEDURE ByFmtAndAddrToC*(from, to: Address; format: Format);
      VAR
	 offset1, offset2, size1, size2: Address;
	 flags: Flags;
   BEGIN
      WHILE format # NIL DO
	 Convert(from + format.offset1, to + format.offset2,
		 format.size1, format.size2, format.flags);
	 format := format.next;
      END;
   END ByFmtAndAddrToC;

   PROCEDURE ByFmtAndAddrFromC*(from, to: Address; format: Format);
      VAR
	 offset1, offset2, size1, size2: Address;
	 flags: Flags;
   BEGIN
      WHILE format # NIL DO
	 Convert(from + format.offset2, to + format.offset1,
		 format.size2, format.size1, format.flags);
	 format := format.next;
      END;
   END ByFmtAndAddrFromC;

   PROCEDURE ByFmtToC*(VAR from, to: ARRAY OF SYS.BYTE; format: Format);
   BEGIN
      ByFmtAndAddrToC(SYS.ADR(from), SYS.ADR(to), format);
   END ByFmtToC;

   PROCEDURE ByFmtFromC*(VAR from, to: ARRAY OF SYS.BYTE; format: Format);
   BEGIN
      ByFmtAndAddrFromC(SYS.ADR(from), SYS.ADR(to), format);
   END ByFmtFromC;

BEGIN
   Events.Define(badformat);
   Events.SetPriority(badformat, Priorities.liberrors);
END ulmSysConversions.
