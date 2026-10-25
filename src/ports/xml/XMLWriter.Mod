(*      $Id: Writer.Mod,v 1.14 2002/03/10 12:44:03 mva Exp $   *)
MODULE XMLWriter;
(*  Support for generating XML documents.
    Copyright (C) 2000-2002  Michael van Acken

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
   Planned changes for future releases:

   @itemize @bullet
   @item
   Rename @samp{*I} methods to @samp{*Region}.

   @item
   Provide methods for writing unquoted text (inherited methods from
   @otype{UnicodeBuffer.OutputDesc} are not sufficient, because the writer
   holds state of start tag).
   @end itemize  *)

IMPORT
  Ascii, Channel, LongStrings, IntStr, RealStr, URI,
  Unicode := oocUnicode, Codec := XMLUnicodeCodec, UnicodeBuffer := XMLUnicodeBuffer;


TYPE
  Char* = Unicode.LONGCHAR;
  String = POINTER TO ARRAY OF Char;
  Bytes = POINTER TO ARRAY OF CHAR;
  Elements = POINTER TO ARRAY OF
               RECORD
                 name: String;
                 mixedContent: BOOLEAN;
               END;

TYPE
  Writer* = POINTER TO WriterDesc;
  WriterDesc* = RECORD
  (**Note: Output is buffered.  Calling @oproc{Writer.EndOfText} will also
     flush the buffers.  *)
    (UnicodeBuffer.OutputDesc)
    indentLevel: LONGINT;
    indent: LONGINT;
    newLine: ARRAY 3 OF CHAR;
    lenNewLine: LONGINT;
    emptyElementHTML: BOOLEAN;
    baseURI-: URI.HierarchicalURI;
    
    elementStack: Elements;
    lenElementStack: LONGINT;
    doIndent: BOOLEAN;
    openStartTag: BOOLEAN;
    openEmptyTag: BOOLEAN;
  END;


PROCEDURE Init* (w: Writer; 
                 writer: Channel.Writer; codecFactory: Codec.Factory;
                 writeBOM: BOOLEAN; indentLevel: LONGINT);
  BEGIN
    UnicodeBuffer.InitOutput (w, TRUE, writer, codecFactory, writeBOM);
    NEW (w. elementStack, 8);
    
    w. indentLevel := indentLevel;
    w. indent := 0;
    w. emptyElementHTML := FALSE;
    w. baseURI := NIL;
    w. newLine[0] := Ascii.lf; w. newLine[1] := 0X;
    w. lenNewLine := 1;
    
    w. lenElementStack := 0;
    w. doIndent := FALSE;                (* don't indent first start tag *)
    w. openStartTag := FALSE;
    w. openEmptyTag := FALSE;
  END Init;

PROCEDURE New* (writer: Channel.Writer; codecFactory: Codec.Factory;
                writeBOM: BOOLEAN; indentLevel: LONGINT): Writer;
  VAR
    w: Writer;
  BEGIN
    NEW (w);
    Init (w, writer, codecFactory, writeBOM, indentLevel);
    RETURN w
  END New;

(*PROCEDURE (w: Writer) Reset* (writer: Channel.Writer; 
                              codecFactory: Codec.Factory;
                              writeBOM: BOOLEAN);
  BEGIN
    w. Reset^ (writer, codecFactory, writeBOM);
    Init (w, FALSE, writer, codecFactory, writeBOM, w. indentLevel);
  END Reset;*)

PROCEDURE (w: Writer) SetBaseURI* (baseURI: URI.HierarchicalURI);
  BEGIN
    w. baseURI := baseURI
  END SetBaseURI;

PROCEDURE (w: Writer) SetEmptyElementHTML* (html: BOOLEAN);
  BEGIN
    w. emptyElementHTML := html
  END SetEmptyElementHTML;

PROCEDURE (w: Writer) WriteTextDecl* (version, standalone: ARRAY OF CHAR);
  VAR
    encoding: ARRAY 256 OF CHAR;
  BEGIN
    w. Write8 ("<?xml");
    IF (version # "") THEN
      w. Write8 (" version='");
      w. Write8 (version);
      w. Write8 ("'")
    END;
    w. Write8 (" encoding='");
    w. codecFactory. GetEncodingName (encoding);
    w. Write8 (encoding);
    w. Write8 ("'");
    IF (standalone # "") THEN
      w. Write8 (" standalone='");
      w. Write8 (standalone);
      w. Write8 ("'")
    END;
    w. Write8 ("?>");
    w. doIndent := (w. indentLevel >= 0)
  END WriteTextDecl;

PROCEDURE (w: Writer) NewLine*;
  VAR
    i: LONGINT;
  BEGIN
    IF w. doIndent THEN
      w. Write8I (w. newLine, 0, w. lenNewLine);
      FOR i := 1 TO w. indent DO
        w. Write8 (" ")
      END
    END
  END NewLine;


PROCEDURE (w: Writer) CloseStartTag*;
  BEGIN
    ASSERT (w. openStartTag);
    IF w. openEmptyTag THEN
      IF w. emptyElementHTML THEN
        w. Write8 (" />")
      ELSE
        w. Write8 ("/>")
      END;
      w. openEmptyTag := FALSE
    ELSE
      w. Write8 (">")
    END;
    w. openStartTag := FALSE
  END CloseStartTag;


PROCEDURE (w: Writer) WriteI* (VAR str: ARRAY OF Char; s, e: LONGINT);
  VAR
    last: LONGINT;
  BEGIN
    ASSERT ((0 <= s) & (s <= e) & (e <= LEN (str)));
    IF w. openStartTag THEN w. CloseStartTag END;
    WHILE (s # e) DO
      last := s;
      WHILE (s # e) &
            (str[s] # 38) & (str[s] # 60) & (str[s] # 62) & (str[s] # 13) DO
        INC (s)
      END;
      w. Write16I (str, last, s);
      IF (s # e) THEN
        CASE str[s] OF
        | 38: w. Write8 ("&amp;")
        | 60: w. Write8 ("&lt;")
        | 62: w. Write8 ("&gt;")
        | 13: w. Write8 ("&#13;")
        END;
        INC (s)
      END
    END
  END WriteI;

PROCEDURE (w: Writer) WriteLatin1I* (VAR str: ARRAY OF CHAR;
                                     s, e: LONGINT);
  VAR
    last: LONGINT;
  BEGIN
    ASSERT ((0 <= s) & (s <= e) & (e <= LEN (str)));
    IF w. openStartTag THEN w. CloseStartTag END;
    WHILE (s # e) DO
      last := s;
      WHILE (s # e) &
            (str[s] # "&") & (str[s] # "<") & (str[s] # ">") & (str[s] # Ascii.cr) DO
        INC (s)
      END;
      w. Write8I (str, last, s);
      IF (s # e) THEN
        CASE str[s] OF
        | "&": w. Write8 ("&amp;")
        | "<": w. Write8 ("&lt;")
        | ">": w. Write8 ("&gt;")
        | Ascii.cr: w. Write8 ("&#13;")
        END;
        INC (s)
      END
    END
  END WriteLatin1I;

PROCEDURE (w: Writer) Write* (VAR str: ARRAY OF Char);
  BEGIN
    w. WriteI (str, 0, LongStrings.Length (str))
  END Write;

PROCEDURE (w: Writer) WriteLatin1* (str: ARRAY OF CHAR);
  BEGIN
    w. WriteLatin1I (str, 0, LongStrings.Length8 (str))
  END WriteLatin1;

PROCEDURE URIText (w: Writer; uri: URI.URI; absolute: BOOLEAN): Bytes;
  VAR str: Bytes; capacity: LONGINT;
  BEGIN
    ASSERT (uri # NIL);
    IF ~absolute THEN
      uri := uri. MakeRelative (w. baseURI)
    END;
    capacity := 128;
    LOOP
      NEW (str, capacity);
      uri. GetString (str^);
      IF LongStrings.Length8 (str^) < capacity-1 THEN RETURN str END;
      ASSERT (capacity <= MAX (LONGINT) DIV 2);
      INC (capacity, capacity)
    END
  END URIText;

PROCEDURE (w: Writer) WriteURI* (uri: URI.URI; absolute: BOOLEAN);
  VAR str: Bytes;
  BEGIN
    str := URIText (w, uri, absolute);
    w. WriteLatin1 (str^)
  END WriteURI;

PROCEDURE (w: Writer) WriteLInt* (value: LONGINT);
  VAR
    val: ARRAY 32 OF CHAR;
  BEGIN
    IntStr.IntToStr (value, val);
    w. WriteLatin1 (val)
  END WriteLInt;

PROCEDURE (w: Writer) WriteRealFix* (real: REAL; k: LONGINT);
  VAR
    val: ARRAY 128 OF CHAR;
  BEGIN
    ASSERT ((MIN (INTEGER) <= k) & (k < MAX (INTEGER)));
    RealStr.RealToFixed(real, SHORT(k), val);
    w. WriteLatin1 (val)
  END WriteRealFix;

PROCEDURE GetString (VAR str: ARRAY OF Char): String;
  VAR
    s: String;
  BEGIN
    NEW (s, LongStrings.Length (str)+1);
    LongStrings.Assign (str, s^);
    RETURN s
  END GetString;

PROCEDURE (w: Writer) StartTag* (VAR name: ARRAY OF Char;
                                 mixedContent: BOOLEAN);
  VAR
    new: Elements;
    i: LONGINT;
  BEGIN
    IF w. openStartTag THEN w. CloseStartTag END;
    w. NewLine;
    w. Write8 ("<");
    w. Write16 (name);
    
    IF (w. lenElementStack = LEN (w. elementStack^)) THEN
      NEW (new, w. lenElementStack*2);
      FOR i := 0 TO w. lenElementStack-1 DO
        new[i] := w. elementStack[i]
      END;
      w. elementStack := new
    END;
    w. elementStack[w. lenElementStack]. name := GetString (name);
    w. elementStack[w. lenElementStack]. mixedContent := mixedContent;
    INC (w. lenElementStack);
    w. openStartTag := TRUE;
    
    w. doIndent := (w. indentLevel >= 0) & ~mixedContent;
    IF w. doIndent THEN
      INC (w. indent, w. indentLevel)
    END
  END StartTag;

PROCEDURE (w: Writer) StartTagLatin1* (name: ARRAY OF CHAR;
                                       mixedContent: BOOLEAN);
  VAR
    name16: String;
  BEGIN
    NEW (name16, LongStrings.Length8 (name)+1);
    LongStrings.Long (name, name16^);
    w. StartTag (name16^, mixedContent)
  END StartTagLatin1;

PROCEDURE (w: Writer) EmptyTag* (VAR name: ARRAY OF Char);
  BEGIN
    IF w. openStartTag THEN w. CloseStartTag END;
    w. NewLine;
    w. Write8 ("<");
    w. Write16 (name);
    (* no need to push the element name on the stack, because
       we will not have to write out the matching end tag *)
    w. openStartTag := TRUE;
    w. openEmptyTag := TRUE
  END EmptyTag;

PROCEDURE (w: Writer) EmptyTagLatin1* (name: ARRAY OF CHAR);
  VAR
    name16: String;
  BEGIN
    NEW (name16, LongStrings.Length8 (name)+1);
    LongStrings.Long (name, name16^);
    w. EmptyTag (name16^)
  END EmptyTagLatin1;


PROCEDURE (w: Writer) AttrString* (VAR name, value: ARRAY OF Char);
  VAR
    s, e, last: LONGINT;
  BEGIN
    ASSERT (w. openStartTag);
    w. Write8 (" ");
    w. Write16 (name);
    w. Write8 ("='");
    
    s := 0; e := LongStrings.Length (value);
    WHILE (s # e) DO
      last := s;
      WHILE (s # e) & (value[s] # 39) &
            (value[s] # 38) & (value[s] # 60) & (value[s] # 62) &
            (value[s] # 9) & (value[s] # 10) & (value[s] # 13) DO
        INC (s)
      END;
      w. Write16I (value, last, s);
      IF (s # e) THEN
        CASE value[s] OF
        | 38: w. Write8 ("&amp;")
        | 60: w. Write8 ("&lt;")
        | 62: w. Write8 ("&gt;")
        | 39: w. Write8 ("&apos;")
        | 9: w. Write8 ("&#9;")
        | 10: w. Write8 ("&#10;")
        | 13: w. Write8 ("&#13;")
        END;
        INC (s)
      END
    END;
    
    w. Write8 ("'")
  END AttrString;

PROCEDURE (w: Writer) AttrStringLatin1* (VAR name: ARRAY OF Char;
                                          value: ARRAY OF CHAR);
  VAR
    s, e, last: LONGINT;
  BEGIN
    ASSERT (w. openStartTag);
    w. Write8 (" ");
    w. Write16 (name);
    w. Write8 ("='");
    
    s := 0; e := LongStrings.Length8 (value);
    WHILE (s # e) DO
      last := s;
      WHILE (s # e) & (value[s] # "'") &
            (value[s] # "&") & (value[s] # "<") & (value[s] # ">") &
            (value[s] # Ascii.ht) & (value[s] # Ascii.lf) & (value[s] # Ascii.cr) DO
        INC (s)
      END;
      w. Write8I (value, last, s);
      IF (s # e) THEN
        CASE value[s] OF
        | "&": w. Write8 ("&amp;")
        | "<": w. Write8 ("&lt;")
        | ">": w. Write8 ("&gt;")
        | "'": w. Write8 ("&apos;")
        | Ascii.ht: w. Write8 ("&#9;")
        | Ascii.lf: w. Write8 ("&#10;")
        | Ascii.cr: w. Write8 ("&#13;")
        END;
        INC (s)
      END
    END;
    
    w. Write8 ("'")
  END AttrStringLatin1;

PROCEDURE (w: Writer) AttrInt* (VAR name: ARRAY OF Char; value: LONGINT);
  VAR
    val: ARRAY 32 OF CHAR;
  BEGIN
    IntStr.IntToStr (value, val);
    w. AttrStringLatin1 (name, val)
  END AttrInt;

PROCEDURE (w: Writer) AttrBool* (VAR name: ARRAY OF Char; value: BOOLEAN);
  BEGIN
    IF value THEN
      w. AttrStringLatin1 (name, "yes")
    ELSE
      w. AttrStringLatin1 (name, "no")
    END
  END AttrBool;

PROCEDURE (w: Writer) AttrURI* (VAR name: ARRAY OF Char; uri: URI.URI;
                                absolute: BOOLEAN);
  VAR
    str: Bytes;
  BEGIN
    ASSERT (w. openStartTag);
    str := URIText (w, uri, absolute);
    w. AttrStringLatin1 (name, str^)
  END AttrURI;


PROCEDURE (w: Writer) EndTag*;
  BEGIN
    IF (w. lenElementStack <= 0) THEN
      w. Flush; HALT (127)
    END;
    
    IF w. doIndent THEN
      DEC (w. indent, w. indentLevel)
    END;
    DEC (w. lenElementStack);
    
    IF w. openEmptyTag THEN              (* preceding element was empty tag *)
      w. CloseStartTag;
      w. NewLine;
      w. Write8 ("</");
      w. Write16 (w. elementStack[w. lenElementStack]. name^);
      w. Write8 (">")
    ELSIF w. openStartTag THEN           (* no content, make empty tag *)
      IF w. emptyElementHTML THEN
        w. Write8 (" />")
      ELSE
        w. Write8 ("/>")
      END;
      w. openStartTag := FALSE
    ELSE                                 (* write end tag *)
      w. NewLine;
      w. Write8 ("</");
      w. Write16 (w. elementStack[w. lenElementStack]. name^);
      w. Write8 (">")
    END;
    
    w. doIndent := (w. indentLevel >= 0);
    IF (w. lenElementStack > 0) THEN
      w. doIndent := w. doIndent &
                     ~(w. elementStack[w. lenElementStack-1]. mixedContent)
    END
  END EndTag;

PROCEDURE (w: Writer) EndOfText*;
(**Adds final newline to text and flushes all buffers.  *)
  BEGIN
    IF w. openStartTag THEN w. CloseStartTag END;
    w. NewLine;
    w. Flush;
    ASSERT (w. lenElementStack = 0);
  END EndOfText;
  
END XMLWriter.
