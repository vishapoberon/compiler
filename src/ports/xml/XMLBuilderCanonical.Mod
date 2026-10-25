(*      $Id: Canonical.Mod,v 1.8 2000/11/08 14:15:07 mva Exp $   *)
MODULE XMLBuilderCanonical;
(*  Translates XML document to canonical XML.
    Copyright (C) 2000, 2001  Michael van Acken

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
  LongStrings, Channel, URI, Ascii, Limits := XMLLimits,
  Codec := XMLUnicodeCodec, DTD := XMLDTD, B := XMLBuilder,
  UnicodeBuffer := XMLUnicodeBuffer;

CONST
  firstCanonicalForm* = 1;
  secondCanonicalForm* = 2;
  thirdCanonicalForm* = 3;  (* not supported... *)

TYPE
  Attribute = RECORD
    name: DTD.String;
    decl: DTD.AttrDecl;
    value: DTD.AttValue;
  END;
  AttributeList = POINTER TO ARRAY OF Attribute;
  
TYPE
  Node = POINTER TO NodeDesc;
  NodeDesc = RECORD
    next: Node;
    notation: DTD.Notation;
  END;

TYPE
  Builder* = POINTER TO BuilderDesc;
  BuilderDesc = RECORD
  (**Writes out the canonical form of an XML document.  *)
  
    (B.BuilderDesc)
    out-: UnicodeBuffer.Output;
    format: SHORTINT;
    
    notationList: Node;
    attrList: AttributeList;
    lenAttrList: LONGINT;
  END;

CONST
  initAttrList = 8;
  incrAttrList = 8;


PROCEDURE WriteQuoted (out: UnicodeBuffer.Output; VAR str: DTD.StringVar;
                       start, end: DTD.CharPos);
  VAR
    i: LONGINT;
  BEGIN
    ASSERT ((0 <= start) & (start <= end) & (end <= LEN (str)));
    i := start;
    WHILE (i # end) DO
      IF out. writer. res # NIL THEN RETURN END;
      LOOP
        CASE str[i] OF
        | 38,60,62,34,00H..1FH:
          (* only the control characters 09X,0AX,0DX can appear here *)
          EXIT
        ELSE
          INC (i);
          IF (i = end) THEN
            EXIT
          END
        END
      END;
      out. Write16I (str, start, i);
      
      IF (i # end) THEN
        CASE str[i] OF
        | 38: out. Write8 ("&amp;")
        | 60: out. Write8 ("&lt;")
        | 62: out. Write8 ("&gt;")
        | 34: out. Write8 ("&quot;")
        | 09H: out. Write8 ("&#9;")
        | 0AH: out. Write8 ("&#10;")
        | 0DH: out. Write8 ("&#13;")
        END;
        INC (i)
      END;
      start := i
    END
  END WriteQuoted;

PROCEDURE WriteLiteral (out: UnicodeBuffer.Output; VAR str: DTD.StringVar);
  VAR i: LONGINT; apostrophe: BOOLEAN;
  BEGIN
    i := 0; apostrophe := FALSE;
    WHILE str[i] # 0 DO
      IF str[i] = 39 THEN apostrophe := TRUE END;
      INC (i)
    END;
    IF apostrophe THEN out. Write8 ('"') ELSE out. Write8 ("'") END;
    out. Write16 (str);
    IF apostrophe THEN out. Write8 ('"') ELSE out. Write8 ("'") END
  END WriteLiteral;

PROCEDURE WriteDTD (b: Builder; root: DTD.String);
  VAR
    node: Node;
  
  PROCEDURE GetNext(): Node;
    VAR
      ptr, best: Node;
    BEGIN
      best := b. notationList;
      ptr := b. notationList. next;
      WHILE (ptr # NIL) DO
        IF ~b. Charge (1) THEN RETURN NIL END;
        IF (LongStrings.Compare (ptr. notation. name^, best. notation. name^) = LongStrings.less) THEN
          best := ptr
        END;
        ptr := ptr. next
      END;
      RETURN best
    END GetNext;
  
  PROCEDURE Remove (VAR list: Node; ptr: Node);
    VAR prev: Node;
    BEGIN
      IF ptr = list THEN list := list. next
      ELSE
        prev := list;
        WHILE prev. next # ptr DO
          IF ~b. Charge (1) THEN RETURN END;
          prev := prev. next
        END;
        prev. next := ptr. next
      END
    END Remove;
  
  BEGIN
    b. out. Write8 ("<!DOCTYPE ");
    b. out. Write16 (root^);
    b. out. Write8 (" ["); b. out. Write8 (Ascii.lf);
    WHILE (b. notationList # NIL) DO
      node := GetNext();
      IF node = NIL THEN RETURN END;
      Remove (b. notationList, node);
      IF ~b. Charge (1) THEN RETURN END;
      b. out. Write8 ("<!NOTATION ");
      b. out. Write16 (node. notation. name^);
      IF (node. notation. public # NIL) THEN
        b. out. Write8 (" PUBLIC ");
        WriteLiteral (b. out, node. notation. public^);
        IF (node. notation. system # NIL) THEN
          b. out. Write8 (" ");
          WriteLiteral (b. out, node. notation. system^)
        END
      ELSE
        b. out. Write8 (" SYSTEM ");
        WriteLiteral (b. out, node. notation. system^)
      END;
      b. out. Write8 (">"); b. out. Write8 (Ascii.lf)
    END;
    b. out. Write8 ("]>"); b. out. Write8 (Ascii.lf)
  END WriteDTD;



PROCEDURE (b: Builder) SetLimits* (limits: Limits.Budget);
  BEGIN b. SetLimits^ (limits); b. out. SetLimits (limits) END SetLimits;

PROCEDURE (b: Builder) StartDocument* (documentEntity: DTD.ExternalEntity);
  BEGIN
  END StartDocument;

PROCEDURE (b: Builder) EndDocument*;
  BEGIN
    b. out. Flush
  END EndDocument;

PROCEDURE (b: Builder) StartElement* (namespaceDecl: DTD.NamespaceDeclaration;
                                      localName: DTD.String);
  BEGIN
    IF ~b. Charge (1) THEN RETURN END;
    ASSERT (namespaceDecl = NIL);
    IF (b. notationList # NIL) & (b. format # firstCanonicalForm) THEN
      WriteDTD (b, localName)
    END;
    b. lenAttrList := 0;
    
    b. out. Write8 ("<");
    b. out. Write16 (localName^);
  END StartElement;

PROCEDURE (b: Builder) Attribute* (namespaceDecl: DTD.NamespaceDeclaration; 
                                   localName: DTD.String;
                                   attrDecl: DTD.AttrDecl;
                                   value: DTD.AttValue;
                                   specified: BOOLEAN);
  VAR
    newList: AttributeList;
    i: LONGINT;
  BEGIN
    IF ~b. Charge (1) THEN RETURN END;
    ASSERT (namespaceDecl = NIL);
    IF (b. lenAttrList = LEN (b. attrList^)) THEN
      NEW (newList, LEN (b. attrList^)+incrAttrList);
      FOR i := 0 TO LEN (b. attrList^)-1 DO
        newList[i] := b. attrList[i]
      END;
      b. attrList := newList
    END;
    b. attrList[b. lenAttrList]. name := localName;
    b. attrList[b. lenAttrList]. decl := attrDecl;
    b. attrList[b. lenAttrList]. value := value;
    INC (b. lenAttrList)
  END Attribute;

PROCEDURE (b: Builder) AttributesDone*;
  VAR
    i, j: LONGINT;
    str: DTD.String;
  
  PROCEDURE GetMin (start: LONGINT): LONGINT;
    VAR
      min, i: LONGINT;
    BEGIN
      min := start;
      FOR i := start+1 TO b. lenAttrList-1 DO
        IF ~b. Charge (1) THEN RETURN min END;
        IF (LongStrings.Compare (b. attrList[i]. name^, b. attrList[min]. name^) = LongStrings.less) THEN
          min := i
        END
      END;
      RETURN min
    END GetMin;
  
  BEGIN
    FOR i := 0 TO b. lenAttrList-1 DO
      j := GetMin (i);
      IF ~b. Charge (1) THEN RETURN END;
      b. out. Write8 (" ");
      b. out. Write16 (b. attrList[j]. name^);
      b. out. Write8 ('="');
      str := b. attrList[j]. value. Flatten (b. attrList[j]. decl);
      WriteQuoted (b. out, str^, 0, LongStrings.Length (str^));
      b. out. Write8 ('"');
      b. attrList[j] := b. attrList[i]
    END;
    FOR i := 0 TO b. lenAttrList-1 DO
      b. attrList[i]. name := NIL;
      b. attrList[i]. decl := NIL;
      b. attrList[i]. value := NIL
    END;
    b. lenAttrList := 0;
    b. out. Write8 (">")
  END AttributesDone;

PROCEDURE (b: Builder) EndElement* (namespaceDecl: DTD.NamespaceDeclaration;
                                    localName: DTD.String);
  BEGIN
    b. out. Write8 ("</");
    b. out. Write16 (localName^);
    b. out. Write8 (">");
  END EndElement;

PROCEDURE (b: Builder) Notation* (notation: DTD.Notation);
(**Called for notation declarations, see 2.10.  *)
  VAR
    node: Node;
  BEGIN
    IF ~b. Charge (1) THEN RETURN END;
    NEW (node);
    node. next := b. notationList;
    node. notation := notation;
    b. notationList := node
  END Notation;

PROCEDURE (b: Builder) ProcessingInstruction* (
    target: DTD.String;
    VAR content: DTD.StringVar; contentStart, contentEnd: DTD.CharPos;
    baseURI: URI.URI);
  BEGIN
    b. out. Write8 ("<?");
    b. out. Write16 (target^);
    b. out. Write8 (" ");
    b. out. Write16I (content, contentStart, contentEnd);
    b. out. Write8 ("?>");
  END ProcessingInstruction;

PROCEDURE (b: Builder) Characters* (VAR chars: DTD.StringVar;
                                    charsStart, charsEnd: DTD.CharPos;
                                    elementWhitespace: DTD.ElementWhitespaceType);
  BEGIN
    WriteQuoted (b. out, chars, charsStart, charsEnd);
  END Characters;


PROCEDURE New* (outputChannel: Channel.Channel;
                codecFactory: Codec.Factory;
                format: SHORTINT): Builder;
(**Creates a new writer.  The output is directed to @oparam{outputChannel},
   using the encoding specified with @oparam{codecFactory}.  @oparam{format}
   selects between the different canonical forms.  *)
  VAR
    b: Builder;
  BEGIN
    ASSERT ((format = firstCanonicalForm) OR (format = secondCanonicalForm));
    NEW (b);
    B.Init (b);
    b. out := UnicodeBuffer.NewOutput (outputChannel. NewWriter(),
                                       codecFactory, TRUE);
    b. format := format;
    
    b. notationList := NIL;
    NEW (b. attrList, initAttrList);
    b. lenAttrList := 0;
    
    RETURN b
  END New;

END XMLBuilderCanonical.
