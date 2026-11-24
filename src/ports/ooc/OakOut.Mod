(*	$Id: OakOut.Mod,v 1.4 1999/09/02 13:18:29 acken Exp $	*)
MODULE OakOut;

(*
    OakOut -  Text-based output of Oberon variables.
    Copyright (C) 1997 Michael Griebling

    This module is free software; you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as
    published by the Free Software Foundation; either version 2 of the
    License, or (at your option) any later version.

    This module is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*)

(* see also [Oakwood Guidelines, revision 1A]
Module Out provides a set of basic routines for formatted output of characters,
numbers, and strings.  It assumes a standard output stream to which the symbols
are written.

Examples
                                output (asterisks denote blanks)
  Out.Open;
  Out.Int(-3, 5);               ***-3
  Out.Int(3, 0);                3
  Out.Real(1.5, 10);            ***1.5E+00  (original Oakwood: **1.50E+00(?))
  Out.Real(-0.005, 0)           -5.0E-03
*)

IMPORT
  RealStr, LRealStr, Strings := oocStrings, Out;

VAR
  opened: BOOLEAN;

PROCEDURE Open*;
(* Initializes the output stream. *)
  BEGIN
    Out.Open;
    opened := TRUE
  END Open;

PROCEDURE Char* (ch: CHAR);
(* Writes the character ch to the end of the output stream. *)
  BEGIN
    IF ~opened THEN RETURN END;
    Out.Char(ch); Out.Flush
  END Char;

PROCEDURE String* (s: ARRAY OF CHAR);
(* Writes the null-terminated character sequence s to the end of the output
   stream (without 0X). *)
  BEGIN
    IF ~opened THEN RETURN END;
    Out.String(s); Out.Flush
  END String;

PROCEDURE Int* (i, n: LONGINT);
(* Writes the integer number i to the end of the output stream.  If the textual
   representation of i requires m characters, i is right adjusted in a field of
   Max(n, m) characters padded with blanks at the left end.  A plus sign is not
   written. *)
  BEGIN
    IF ~opened THEN RETURN END;
    Out.Int(i, n); Out.Flush
  END Int;

PROCEDURE RemoveTrailingZeros (VAR str: ARRAY OF CHAR; pos: INTEGER);
  BEGIN
    WHILE (pos>1) & (str[pos-1]#".") & (str[pos]="0") DO
      Strings.Delete(str, pos, 1); DEC(pos)
    END
  END RemoveTrailingZeros;

PROCEDURE Real* (x: REAL; n: INTEGER);
(* Writes the real number x to the end of the output stream using an
   exponential form.  If the textual representation of x requires m characters
   (including a two-digit signed exponent), x is right adjusted in a field of
   Max(n, m) characters padded with blanks at the left end.  A plus sign of the
   mantissa is not written. *)
  VAR
    str: ARRAY 128 OF CHAR; pos: INTEGER; found: BOOLEAN;
  BEGIN
    IF ~opened THEN RETURN END;

    (* format the string *)
    RealStr.RealToFloat(x, 0, str);

    (* add exponent if it is zero *)
    Strings.FindNext("E", str, 0, found, pos);
    IF ~found THEN (* append zero exponent for Oakwood *)
      RemoveTrailingZeros(str, Strings.Length(str)-1);
      Strings.Append("E+00", str)
    ELSE
      (* add another zero to the exponent -- if needed *)
      IF Strings.Length(str)-pos<4 THEN Strings.Insert("0", pos+2, str) END;
      RemoveTrailingZeros(str, pos-1)
    END;

    (* output the string *)
    DEC(n, Strings.Length(str));
    WHILE n>0 DO Out.Char(" "); DEC(n) END;
    Out.String(str); Out.Flush
  END Real;

PROCEDURE LongReal* (x: LONGREAL; n: INTEGER);
(* Writes the long real number x to the end of the output stream using an
   exponential form.  If the textual representation of x requires m characters
   (including a three-digit signed exponent), x is right adjusted in a field of
   Max(n, m) characters padded with blanks at the left end.  A plus sign of the
   mantissa is not written. *)
  VAR
    str: ARRAY 128 OF CHAR; pos: INTEGER; found: BOOLEAN;
  BEGIN
    IF ~opened THEN RETURN END;

    (* format the string *)
    LRealStr.RealToFloat(x, 0, str);

    (* add exponent if it is zero *)
    Strings.FindNext("E", str, 0, found, pos);
    IF ~found THEN (* append zero exponent for Oakwood *)
      RemoveTrailingZeros(str, Strings.Length(str)-1);
      Strings.Append("E+000", str)
    ELSE
      (* add another zero to the exponent -- if needed *)
      WHILE Strings.Length(str)-pos<5 DO Strings.Insert("0", pos+2, str) END;
      RemoveTrailingZeros(str, pos-1)
    END;

    (* output the string *)
    DEC(n, Strings.Length(str));
    WHILE n>0 DO Out.Char(" "); DEC(n) END;
    Out.String(str); Out.Flush
  END LongReal;

PROCEDURE Ln*;
(* Writes an end-of-line symbol to the end of the output stream. *)
  BEGIN
    IF ~opened THEN RETURN END;
    Out.Ln
  END Ln;

BEGIN
  opened := FALSE
END OakOut.
