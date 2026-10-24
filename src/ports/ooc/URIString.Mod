(* 	$Id: String.Mod,v 1.1.1.2 2000/07/10 20:31:52 mva Exp $	 *)
MODULE URI:String;
(*  Auxiliary string functions for URI parser.
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


IMPORT
  Strings, URI:CharClass;


TYPE
  String* = ARRAY OF CHAR;
  StringPtr* = POINTER TO String;
  Offset* = INTEGER;


PROCEDURE Extract* (str: String; start, end: INTEGER): StringPtr;
(**Creates a copy of the character sequence @samp{str[start,end[}.  *)
  VAR
    i: INTEGER;
    ptr: StringPtr;
  BEGIN
    NEW (ptr, end-start+1);
    i := 0;
    WHILE (start # end) DO
      ptr[i] := str[start]; INC (i); INC (start)
    END;
    ptr[i] := 0X;
    RETURN ptr
  END Extract;

PROCEDURE Copy* (str: String): StringPtr;
(**Creates a copy of @oparam{str}.  *)
  BEGIN
    RETURN Extract (str, 0, Strings.Length (str))
  END Copy;

PROCEDURE Unescape* (str: StringPtr): StringPtr;
(**Replaces escaped characters with their ISO Latin-1 counterparts.  The
   escape sequence @samp{%00} is translated to a space (ASCII code 32).
   
   @precond
   The string @oparam{str} is well-formed.  That is, every occurence of
   the character @samp{%} is followed by two valid hexadecimal digits.
   @end precond  *)
  VAR
    i, j: Offset;
    res: StringPtr;
  
  PROCEDURE Hex (ch: CHAR): INTEGER;
    BEGIN
      CASE ch OF
      | "0".."9":
        RETURN ORD(ch)-ORD("0")
      | "a".."f":
        RETURN ORD(ch)-(ORD("a")-10)
      | "A".."F":
        RETURN ORD(ch)-(ORD("A")-10)
      END
    END Hex;
  
  BEGIN
    i := 0;
    WHILE (str[i] # 0X) & (str[i] # "%") DO
      INC (i)
    END;
    IF (str[i] = 0X) THEN
      RETURN str
    ELSE
      NEW (res, LEN (str^));
      i := 0; j := 0;
      WHILE (str[i] # 0X) DO
        IF (str[i] = "%") THEN
          res[j] := CHR (Hex(str[i+1])*16 + Hex(str[i+2]));
          IF (res[j] = 0X) THEN
            res[j] := " "
          END;
          INC (i, 3)
        ELSE
          res[j] := str[i];
          INC (i)
        END;
        INC (j)
      END;
      res[j] := 0X;
      RETURN res
    END
  END Unescape;

PROCEDURE AppendEscaped* (source, unreserved: ARRAY OF CHAR;
                          VAR dest: ARRAY OF CHAR);
(**Appends the string @oparam{source} to @oparam{dest}, possibly escaping some
   characters on the way.  All characters from @oproc{CharClass.IsUnreserved}
   and all characters in @oparam{unreserved} are copied as is.  Any other
   characters are translated into a three character sequence @samp{%HH}, where
   @samp{H} is a hex digit from @samp{[0-9A-F]}.  If @oparam{dest} cannot 
   hold the whole result, then the result string is truncated.  *)
  VAR
    i, j: INTEGER;
  
  PROCEDURE ToHex (i: INTEGER): CHAR;
    BEGIN
      IF (i < 10) THEN
        RETURN CHR (i+ORD ("0"))
      ELSE
        RETURN CHR (i+(ORD ("A")-10))
      END
    END ToHex;
  
  BEGIN
    i := 0; j := Strings.Length (dest);
    WHILE (source[i] # 0X) DO
      IF ~CharClass.IsUnreserved (source[i]) &
         ~CharClass.IsMember (source[i], unreserved) THEN
        IF (j < LEN (dest)) THEN
          dest[j] := "%"
        END;
        IF (j+1 < LEN (dest)) THEN
          dest[j+1] := ToHex (ORD (source[i]) DIV 16)
        END;
        IF (j+2 < LEN (dest)) THEN
          dest[j+2] := ToHex (ORD (source[i]) MOD 16)
        END;
        INC (j, 3)
      ELSIF (j < LEN (dest)) THEN
        dest[j] := source[i];
        INC (j)
      END;
      INC (i)
    END;
    IF (j < LEN (dest)) THEN
      dest[j] := 0X
    ELSE
      dest[LEN (dest)-1] := 0X
    END
  END AppendEscaped;

END URI:String.
