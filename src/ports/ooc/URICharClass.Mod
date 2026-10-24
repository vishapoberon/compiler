(* 	$Id: CharClass.Mod,v 1.3 2000/08/08 16:22:41 mva Exp $	 *)
MODULE URICharClass;
(*  Predicates and auxiliary functions for URI character classes.
    Copyright (C) 2000  Michael van Acken

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


CONST
  unreservedPChar* = ":@&=+$,";
  (**All characters that are classified as reserved, but need not to be
     escaped if used as a @samp{pchar}.  In particular, these characters
     can be used unchanged as part of a path segment or path parameter.  *)
  unreservedUserinfo* = ";:&=+$,";
  (**All characters that are classified as reserved, but need not to be
     escaped if used within a userinfo string.  *)
  reserved* = ";/?:@&=+$,[]";
  (**The list of characters that are allowed within a URI, but may not be
     allowed within a particular component of the generic URI syntax.  Note:
     RFC 2732, @cite{Format for Literal IPv6 Addresses in URL's}, adds the
     characters @samp{[} and @samp{]} to the set of reserved characters.  Until
     @omodule{*URI:Authority:ServerBased} implements literal IPv6 addresses,
     extending @oconst{reserved} only prevents other modules (e.g., the XML
     parser) from escaping these characters.  *)


PROCEDURE IsAlpha* (ch: CHAR): BOOLEAN;
  BEGIN
    RETURN ("A" <= ch) & (ch <= "Z") OR ("a" <= ch) & (ch <= "z")
  END IsAlpha;

PROCEDURE SkipAlpha* (VAR str: ARRAY OF CHAR; VAR pos: LONGINT): BOOLEAN;
  BEGIN
    IF IsAlpha (str[pos]) THEN
      INC (pos);
      RETURN TRUE
    ELSE
      RETURN FALSE
    END
  END SkipAlpha;

PROCEDURE IsDigit* (ch: CHAR): BOOLEAN;
  BEGIN
    RETURN ("0" <= ch) & (ch <= "9")
  END IsDigit;

PROCEDURE SkipDigit* (VAR str: ARRAY OF CHAR; VAR pos: LONGINT): BOOLEAN;
  BEGIN
    IF ("0" <= str[pos]) & (str[pos] <= "9") THEN
      INC (pos);
      RETURN TRUE
    ELSE
      RETURN FALSE
    END
  END SkipDigit;

PROCEDURE IsAlphaNum* (ch: CHAR): BOOLEAN;
  BEGIN
    RETURN IsAlpha (ch) OR IsDigit (ch)
  END IsAlphaNum;

PROCEDURE SkipAlphaNum* (VAR str: ARRAY OF CHAR; VAR pos: LONGINT): BOOLEAN;
  BEGIN
    RETURN SkipAlpha (str, pos) OR SkipDigit (str, pos)
  END SkipAlphaNum;

PROCEDURE IsMember* (ch: CHAR; set: ARRAY OF CHAR): BOOLEAN;
  VAR
    i: LONGINT;
  BEGIN
    i := 0;
    WHILE (set[i] # 0X) & (set[i] # ch) DO
      INC (i)
    END;
    RETURN (set[i] # 0X)
  END IsMember;

PROCEDURE IsReserved* (ch: CHAR): BOOLEAN;
  BEGIN
    RETURN IsMember (ch, reserved)
  END IsReserved;

PROCEDURE SkipReserved* (VAR str: ARRAY OF CHAR; VAR pos: LONGINT): BOOLEAN;
  BEGIN
    IF IsMember (str[pos], reserved) THEN
      INC (pos);
      RETURN TRUE
    ELSE
      RETURN FALSE
    END
  END SkipReserved;

PROCEDURE IsMark* (ch: CHAR): BOOLEAN;
  BEGIN
    CASE ch OF
    | "-", "_", ".", "!", "~", "*", "'", "(", ")":
      RETURN TRUE
    ELSE
      RETURN FALSE
    END
  END IsMark;

PROCEDURE SkipMark* (VAR str: ARRAY OF CHAR; VAR pos: LONGINT): BOOLEAN;
  BEGIN
    IF IsMark (str[pos]) THEN
      INC (pos);
      RETURN TRUE
    ELSE
      RETURN FALSE
    END
  END SkipMark;

PROCEDURE IsUnreserved* (ch: CHAR): BOOLEAN;
  BEGIN
    RETURN IsAlphaNum (ch) OR IsMark (ch)
  END IsUnreserved;

PROCEDURE SkipUnreserved* (VAR str: ARRAY OF CHAR; VAR pos: LONGINT): BOOLEAN;
  BEGIN
    RETURN SkipAlphaNum (str, pos) OR SkipMark (str, pos)
  END SkipUnreserved;

PROCEDURE SkipEscaped* (VAR str: ARRAY OF CHAR; VAR pos: LONGINT): BOOLEAN;
  PROCEDURE SkipHex (ch: CHAR): BOOLEAN;
    BEGIN
      RETURN ("0" <= ch) & (ch <= "9") OR ("A" <= ch) & (ch <= "F") OR
             ("a" <= ch) & (ch <= "f")
    END SkipHex;

  BEGIN
    IF (str[pos] = "%") & (pos < LEN (str)-2) &
       SkipHex (str[pos+1]) & SkipHex (str[pos+2]) &
       ((str[pos+1] # "0") OR (str[pos+2] # "0")) THEN
      INC (pos, 3);
      RETURN TRUE
    ELSE
      RETURN FALSE
    END
  END SkipEscaped;

PROCEDURE SkipPChar* (VAR str: ARRAY OF CHAR; VAR pos: LONGINT): BOOLEAN;
  BEGIN
    IF IsMember (str[pos], unreservedPChar) THEN
      INC (pos);
      RETURN TRUE
    ELSE
      RETURN SkipUnreserved (str, pos) OR SkipEscaped (str, pos)
    END
  END SkipPChar;

PROCEDURE SkipURIC* (VAR str: ARRAY OF CHAR; VAR pos: LONGINT): BOOLEAN;
  BEGIN
    RETURN SkipUnreserved (str, pos) OR
           SkipReserved (str, pos) OR
           SkipEscaped (str, pos)
  END SkipURIC;

PROCEDURE SkipMember* (VAR str: ARRAY OF CHAR; VAR pos: LONGINT;
                       set: ARRAY OF CHAR): BOOLEAN;
  BEGIN
    IF IsMember (str[pos], set) THEN
      INC (pos);
      RETURN TRUE
    ELSE
      RETURN FALSE
    END
  END SkipMember;

PROCEDURE SkipAuthChar* (VAR str: ARRAY OF CHAR; VAR pos: LONGINT): BOOLEAN;
  BEGIN
    RETURN SkipUnreserved (str, pos) OR
           SkipEscaped (str, pos) OR
           SkipMember (str, pos, "$,;:@&=+")
  END SkipAuthChar;

END URICharClass.
