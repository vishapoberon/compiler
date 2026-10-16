(*  $Id: IntStr.Mod,v 1.4 1999/09/02 13:07:47 acken Exp $  *)
MODULE IntStr;
(*  IntStr - Integer-number/string conversions.
    Copyright (C) 1995 Michael Griebling

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

IMPORT
  Conv := ConvTypes, IntConv;

TYPE
  (** possible values: strAllRight, strOutOfRange, strWrongFormat, strEmpty *)
  ConvResults*= Conv.ConvResults;

CONST
  (** the string format is correct for the corresponding conversion *)
  strAllRight*=Conv.strAllRight;
  (** the string is well-formed but the value cannot be represented *)
  strOutOfRange*=Conv.strOutOfRange;
  (** the string is in the wrong format for the conversion *)
  strWrongFormat*=Conv.strWrongFormat;
  (** the given string is empty *)
  strEmpty*=Conv.strEmpty;


(** the string form of a signed whole number is
     ["+" | "-"] decimal_digit {decimal_digit}
*)
(** Ignores any leading spaces in `str'. If the subsequent characters in `str'
   are in the format of a signed whole number, assigns a corresponding value to
   `int'.  Assigns a value indicating the format of `str' to `res'.  *)

PROCEDURE StrToInt*(str: ARRAY OF CHAR; VAR int: LONGINT; VAR res: ConvResults);
BEGIN
  res:=IntConv.FormatInt(str);
  IF (res = strAllRight) THEN
    int:=IntConv.ValueInt(str)
  END
END StrToInt;


PROCEDURE Reverse (VAR str : ARRAY OF CHAR; start, end : INTEGER);
(* Reverses order of characters in the interval [start..end]. *)
VAR
  h : CHAR;
BEGIN
  WHILE start < end DO
    h := str[start]; str[start] := str[end]; str[end] := h;
    INC(start); DEC(end)
  END
END Reverse;

(** Converts the value of `int' to string form and copies the possibly truncated
   result to `str'.  *)

PROCEDURE IntToStr*(int: LONGINT; VAR str: ARRAY OF CHAR);
CONST
  maxLength = 3 * SIZE(LONGINT); (* room for decimal digits and a sign *)
VAR
  b : ARRAY maxLength+1 OF CHAR;
  s, e: INTEGER;
  digit: LONGINT;
BEGIN
  IF LEN(str) = 0 THEN RETURN END;
  IF int < 0 THEN
    b[0] := "-"; s := 1;
    (* Extract the first digit without negating MIN(LONGINT). *)
    int := -(int + 1);
    digit := int MOD 10 + 1; int := int DIV 10;
    IF digit = 10 THEN digit := 0; INC(int) END
  ELSE
    s := 0;
    digit := int MOD 10; int := int DIV 10
  END;
  e := s; b[e] := CHR(digit + ORD("0")); INC(e);
  WHILE int > 0 DO
    b[e] := CHR(int MOD 10 + ORD("0"));
    int := int DIV 10; INC(e)
  END;
  b[e] := 0X;
  Reverse(b, s, e-1);

  COPY(b, str) (* truncate output if necessary *)
END IntToStr;

END IntStr.
