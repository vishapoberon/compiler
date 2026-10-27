(*      $Id: Namespaces.Mod,v 1.6 2001/03/16 21:39:40 mva Exp $   *)
MODULE XMLBuilderNamespaces;
(*  Provides namespace support for XML:Parser.
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
  Msg, LongStrings, URI, URIParser, String := URIString, Limits := XMLLimits,
  Unparsed := URIFragmentUnparsed, Hierarchical := URISchemeHierarchical,
  Error := XMLError, DTD := XMLDTD, Locator := XMLLocator,
  B := XMLBuilder, EntityResolver := XMLEntityResolver;


TYPE
  NamespaceList = POINTER TO ARRAY OF DTD.NamespaceDeclaration;
  ElementData = RECORD
    namespaceDecl: DTD.NamespaceDeclaration;
    (* namespace URI of current element *)
    localName: DTD.String;
    (* local name of current element *)
    pos: Locator.Position;
    default: DTD.NamespaceDeclaration;
    startLocal: LONGINT;
  END;
  Stack = POINTER TO ARRAY OF ElementData;

TYPE
  Builder* = POINTER TO BuilderDesc;
  BuilderDesc = RECORD
  (**This builder adds namespace support to the parser.  It rewrites element
     and attribute names if they have a namespace prefix.  The rewritten
     element and attribute data is then passed on to the delegate builder.  All
     other callbacks are propagated without changes.

     Assuming that @samp{builder} is an instance of
     @otype{B.Builder}, the following commands create a
     namespace-aware parser:

     @example
     builder := Namespaces.New (builder);
     p := Parser.NewFile (arg, NIL, NIL, NIL, builder, res);
     p. enforceQNames := TRUE;
     @end example  *)
  
    (B.BuilderDesc)
    parserLocator: Locator.Locator;
    namespaceLocator: Locator.Locator;
    delegateBuilder: B.Builder;
    errorListener: Locator.ErrorListener;
    
    currLevel: LONGINT;
    (* level of current element; document element is 0, each nesting level
       adds 1 *)
    stack: Stack;
    
    namespaceList: NamespaceList;
    lenNamespaceList: LONGINT;
    
    attrList: B.AttributeList;
    failed: BOOLEAN;
  END;


CONST  (* error codes *)
  emptyURI = 1;
  malformedURIRef = 2;
  undeclaredPrefix = 3;
  nameClash = 4;
  reservedBinding = 5;

CONST
  xmlURI = "http://www.w3.org/XML/1998/namespace";
  xmlnsURI = "http://www.w3.org/2000/xmlns/";
  
VAR
  namespacesContext: Error.Context;

PROCEDURE ReportError (b: Builder; code: Error.Code; pos: Locator.Position): Error.Msg;
  BEGIN
    b. failed := TRUE;
    RETURN b. errorListener. Error (namespacesContext, code, TRUE, pos)
  END ReportError;


PROCEDURE (b: Builder) SetLocator* (locator: Locator.Locator);
  BEGIN
    b. parserLocator := locator;
    b. delegateBuilder. SetLocator (locator)
  END SetLocator;

PROCEDURE (b: Builder) SetErrorListener* (el: Locator.ErrorListener);
  BEGIN
    b. errorListener := el;
    b. delegateBuilder. SetErrorListener (el)
  END SetErrorListener;

PROCEDURE (b: Builder) SetLimits* (limits: Limits.Budget);
  BEGIN b. SetLimits^ (limits); b. delegateBuilder. SetLimits (limits) END SetLimits;


PROCEDURE (b: Builder) StartDocument* (documentEntity: DTD.ExternalEntity);
  BEGIN
    b. delegateBuilder. StartDocument (documentEntity)
  END StartDocument;

PROCEDURE (b: Builder) EndDocument*;
  BEGIN
    b. delegateBuilder. EndDocument
  END EndDocument;

PROCEDURE (b: Builder) StartDTD* (dtdBuilder: DTD.Builder);
  BEGIN
    b. delegateBuilder. StartDTD (dtdBuilder)
  END StartDTD;

PROCEDURE (b: Builder) EndDTD* (externalDTD: DTD.ExternalEntity;
                                allDeclarationsProcessed: BOOLEAN);
  BEGIN
    b. delegateBuilder. EndDTD (externalDTD, allDeclarationsProcessed)
  END EndDTD;



PROCEDURE (b: Builder) StartElement* (namespaceDecl: DTD.NamespaceDeclaration; 
                                      localName: DTD.String);
  VAR
    new: Stack;
    i: LONGINT;
  BEGIN
    IF ~b. Charge (1) THEN RETURN END;
    ASSERT (namespaceDecl = NIL);
    INC (b. currLevel);
    IF (b. currLevel = LEN (b. stack^)) THEN
      NEW (new, LEN (b. stack^)*2);
      FOR i := 0 TO LEN (b. stack^)-1 DO
        new[i] := b. stack[i]
      END;
      b. stack := new
    END;
    
    b. stack[b. currLevel]. namespaceDecl := namespaceDecl;
    b. stack[b. currLevel]. localName := localName;
    b. stack[b. currLevel]. pos := b. parserLocator^;
    IF (b. currLevel > 0) THEN
      b. stack[b. currLevel]. default := b. stack[b. currLevel-1]. default
    ELSE
      b. stack[b. currLevel]. default := NIL
    END;
    b. stack[b. currLevel]. startLocal := b. lenNamespaceList
  END StartElement;

PROCEDURE (b: Builder) EndElement* (namespaceDecl: DTD.NamespaceDeclaration; 
                                    localName: DTD.String);
  BEGIN
    IF ~b. Charge (1) THEN RETURN END;
    ASSERT (namespaceDecl = NIL);
    b. delegateBuilder. EndElement (b. stack[b. currLevel]. namespaceDecl,
                                    b. stack[b. currLevel]. localName);
    b. lenNamespaceList := b. stack[b. currLevel]. startLocal;
    DEC (b. currLevel);
  END EndElement;

PROCEDURE (b: Builder) Attribute* (namespaceDecl: DTD.NamespaceDeclaration; 
                                   localName: DTD.String;
                                   attrDecl: DTD.AttrDecl;
                                   value: DTD.AttValue;
                                   specified: BOOLEAN);
  VAR
    prefix, str: DTD.String;
    err: Error.Msg;
    nspDecl: DTD.NamespaceDeclaration;
    
  PROCEDURE IsNamespaceDecl (VAR str: ARRAY OF DTD.Char): BOOLEAN;
    BEGIN
      RETURN (str[0] = ORD ("x")) & (str[1] = ORD ("m")) & (str[2] = ORD ("l")) &
             (str[3] = ORD ("n")) & (str[4] = ORD ("s")) &
             ((str[5] = 0) OR (str[5] = ORD (":")))
    END IsNamespaceDecl;
  
  PROCEDURE GetURI (str: DTD.String): DTD.StringURI;
    VAR
      str8: DTD.StringURI;
      baseURI: URI.URI;
      uriRef: URI.Reference;
      res: Msg.Msg;
      err: Error.Msg;
      fragm: Unparsed.Fragment;
    BEGIN
      str8 := EntityResolver.NormalizeURI (str);
      IF str8 = NIL THEN
        err := ReportError (b, malformedURIRef, b. parserLocator^);
        RETURN NIL
      END;
      baseURI := b. parserLocator. entity. baseURI;
      fragm := Unparsed.New (String.Copy (""));
      IF (baseURI # NIL) & (baseURI IS URI.HierarchicalURI) THEN
        uriRef := URIParser.NewReference (str8^, baseURI(URI.HierarchicalURI), fragm, res)
      ELSE
        (* Namespace names retain their literal URI reference. A synthetic
           hierarchical base permits syntax checking of relative names in
           memory documents; no resolved URI is used or opened. *)
        baseURI := Hierarchical.New (NIL, NIL, NIL);
        uriRef := URIParser.NewReference (str8^, baseURI(URI.HierarchicalURI), fragm, res)
      END;
      IF (res # NIL) THEN
        err := ReportError (b, malformedURIRef, b. parserLocator^);
        err. SetMsgAttrib ("uri_error", res);
        RETURN NIL
      ELSE
        RETURN str8
      END
    END GetURI;
  
  PROCEDURE AddDecl (namespaceDecl: DTD.NamespaceDeclaration);
    VAR
      new: NamespaceList;
      i: LONGINT;
    BEGIN
      IF (b. lenNamespaceList = LEN (b. namespaceList^)) THEN
        NEW (new, LEN (b. namespaceList^)*2);
        FOR i := 0 TO LEN (b. namespaceList^)-1 DO
          new[i] := b. namespaceList[i]
        END;
        b. namespaceList := new
      END;
      
      IF ~((namespaceDecl. prefix # NIL) &
           (namespaceDecl. uri = NIL)) THEN
        b. namespaceList[b. lenNamespaceList] := namespaceDecl;
        INC (b. lenNamespaceList)
      END
    END AddDecl;
  
  BEGIN
    IF ~b. Charge (1) THEN RETURN END;
    ASSERT (namespaceDecl = NIL);
    IF IsNamespaceDecl (localName^) THEN
      (* create a record for the namespace declarations local to the current
         element, unless this record already exists *)
      str := value. Flatten (attrDecl);
      IF (localName[5] = 0) THEN        (* default declaration *)
        IF (str[0] = 0) THEN
          AddDecl (DTD.NewNamespaceDeclaration (NIL, NIL));
          b. stack[b. currLevel]. default := NIL
        ELSE
          IF LongStrings.Equal8 (str^, xmlURI) OR LongStrings.Equal8 (str^, xmlnsURI) THEN
            err := ReportError (b, reservedBinding, b. parserLocator^)
          ELSE
            nspDecl := DTD.NewNamespaceDeclaration (NIL, GetURI (str));
            AddDecl (nspDecl);
            b. stack[b. currLevel]. default := nspDecl
          END
        END
      ELSE
        prefix := DTD.GetString (localName^, 6, LongStrings.Length (localName^));
        IF (str[0] = 0) THEN
          err := ReportError (b, emptyURI, b. parserLocator^)
        ELSIF LongStrings.Equal8 (prefix^, "xmlns") OR
              LongStrings.Equal8 (str^, xmlnsURI) OR
              (LongStrings.Equal8 (prefix^, "xml") # LongStrings.Equal8 (str^, xmlURI)) THEN
          err := ReportError (b, reservedBinding, b. parserLocator^)
        ELSE
          AddDecl (DTD.NewNamespaceDeclaration (prefix, GetURI (str)))
        END
      END
    ELSE
      b. attrList. Append (B.NewAttribute (namespaceDecl, localName, attrDecl,
                           value, specified, b. parserLocator))
    END
  END Attribute;
  
PROCEDURE (b: Builder) NamespaceDeclaration* (namespaceDecl: DTD.NamespaceDeclaration);
  BEGIN
    HALT (127)
  END NamespaceDeclaration;

PROCEDURE (b: Builder) AttributesDone*;
  VAR
    i, j, colon: LONGINT;
    attr: B.Attribute;
    localName: DTD.String;
    namespaceDecl: DTD.NamespaceDeclaration;
    err: Error.Msg;
  
  PROCEDURE GetColon (VAR str: ARRAY OF DTD.Char): LONGINT;
    VAR
      i: LONGINT;
    BEGIN
      i := 0;
      WHILE (str[i] # 0) & (str[i] # ORD (":")) DO
        INC (i)
      END;
      IF (str[i] = ORD (":")) THEN
        RETURN i
      ELSE
        RETURN -1
      END
    END GetColon;
  
  PROCEDURE GetNamespace (VAR str: ARRAY OF DTD.Char; colon: LONGINT): DTD.NamespaceDeclaration;
    VAR
      i: LONGINT;
      err: Error.Msg;
    BEGIN
      str[colon] := 0;
      i := b. lenNamespaceList-1;
      WHILE (i >= 0) DO
        IF ~b. Charge (1) THEN str[colon] := ORD (":"); RETURN NIL END;
        IF (b. namespaceList[i]. prefix # NIL) &
           LongStrings.Equal (b. namespaceList[i]. prefix^, str) THEN
          str[colon] := ORD (":");
          RETURN b. namespaceList[i]
        END;
        DEC (i)
      END;
      err := ReportError (b, undeclaredPrefix, b. namespaceLocator^);
      err. SetLStringAttrib ("prefix", Msg.GetLStringPtr (str));
      str[colon] := ORD (":");
      RETURN NIL
    END GetNamespace;

  PROCEDURE RestoreLocator;
    BEGIN
      b. attrList. Clear;
      b. delegateBuilder. SetLocator (b. parserLocator)
    END RestoreLocator;
  
  BEGIN
    IF ~b. Charge (1) THEN RETURN END;
    b. delegateBuilder. SetLocator (b. namespaceLocator);
    
    (* emit start element *)
    b. namespaceLocator^ := b. stack[b. currLevel]. pos;
    localName := b. stack[b. currLevel]. localName;
    colon := GetColon (localName^);
    IF (colon >= 0) THEN
      namespaceDecl := GetNamespace (localName^, colon);
      localName := DTD.GetString (localName^, colon+1, LongStrings.Length (localName^))
    ELSE
      namespaceDecl := b. stack[b. currLevel]. default
    END;
    IF b. failed OR ~b. Charge (0) THEN RestoreLocator; RETURN END;
    b. stack[b. currLevel]. namespaceDecl := namespaceDecl;
    b. stack[b. currLevel]. localName := localName;
    b. delegateBuilder. StartElement (namespaceDecl, localName);
    
    (* emit namespace declarations *)
    i := b. stack[b. currLevel]. startLocal;
    WHILE (i # b. lenNamespaceList) DO
      IF ~b. Charge (1) THEN RestoreLocator; RETURN END;
      b. delegateBuilder. NamespaceDeclaration (b. namespaceList[i]);
      INC (i)
    END;
    
    (* emit all other atttributes *)
    i := 0;
    WHILE (i # b. attrList. len) DO
      IF ~b. Charge (1) THEN RestoreLocator; RETURN END;
      attr := b. attrList. attr[i];
      b. namespaceLocator^ := attr. pos;
      
      localName := attr. localName;
      colon := GetColon (localName^);
      IF (colon >= 0) THEN
        namespaceDecl := GetNamespace (localName^, colon);
        localName := DTD.GetString (localName^, colon+1, LongStrings.Length (localName^));
        
        (* make sure that no other attribute until now had the same local name
           and namespace URI *)
        j := 0;
        WHILE (j # i) DO
          IF ~b. Charge (1) THEN RestoreLocator; RETURN END;
          IF (namespaceDecl # NIL) & (namespaceDecl. uri # NIL) &
             LongStrings.Equal (b. attrList. attr[j]. localName^, localName^) &
             (b. attrList. attr[j]. namespaceDecl # NIL) &
             (b. attrList. attr[j]. namespaceDecl. uri # NIL) &
             (b. attrList. attr[j]. namespaceDecl. uri^ = namespaceDecl. uri^) THEN
            err := ReportError (b, nameClash, b. namespaceLocator^);
            err. SetLStringAttrib ("prefix", Msg.GetLStringPtr (b. attrList. attr[j]. namespaceDecl. prefix^));
            err. SetLStringAttrib ("localName", Msg.GetLStringPtr (localName^));
          END;
          INC (j)
        END
      ELSE
        namespaceDecl := NIL
      END;
      attr. namespaceDecl := namespaceDecl;
      attr. localName := localName;
      IF b. failed OR ~b. Charge (0) THEN RestoreLocator; RETURN END;
      
      b. delegateBuilder. Attribute (namespaceDecl,
                                     localName,
                                     attr. attrDecl,
                                     attr. value,
                                     attr. specified);
      INC (i)
    END;
    RestoreLocator;
    IF b. Charge (0) THEN b. delegateBuilder. AttributesDone END
  END AttributesDone;


PROCEDURE (b: Builder) SkippedEntity* (name: DTD.String; referent: DTD.Entity);
  BEGIN
    b. delegateBuilder. SkippedEntity (name, referent)
  END SkippedEntity;


PROCEDURE (b: Builder) Characters* (VAR chars: DTD.StringVar;
                                    charsStart, charsEnd: DTD.CharPos;
                                    elementWhitespace: DTD.ElementWhitespaceType);
  BEGIN
    b. delegateBuilder. Characters (chars, charsStart, charsEnd,
                                    elementWhitespace)
  END Characters;


PROCEDURE (b: Builder) StartCDATA*;
  BEGIN
    b. delegateBuilder. StartCDATA
  END StartCDATA;

PROCEDURE (b: Builder) EndCDATA*;
  BEGIN
    b. delegateBuilder. EndCDATA
  END EndCDATA;

PROCEDURE (b: Builder) StartEntity* (entity: DTD.Entity);
  BEGIN
    b. delegateBuilder. StartEntity (entity)
  END StartEntity;

PROCEDURE (b: Builder) EndEntity* (entity: DTD.Entity);
  BEGIN
    b. delegateBuilder. EndEntity (entity)
  END EndEntity;



PROCEDURE (b: Builder) EntityDecl* (entity: DTD.Entity);
  BEGIN
    b. delegateBuilder. EntityDecl (entity)
  END EntityDecl;

PROCEDURE (b: Builder) Notation* (notation: DTD.Notation);
  BEGIN
    b. delegateBuilder. Notation (notation)
  END Notation;

PROCEDURE (b: Builder) ProcessingInstruction* (
                     target: DTD.String; VAR content: DTD.StringVar;
                     contentStart, contentEnd: DTD.CharPos; baseURI: URI.URI);
  BEGIN
    b. delegateBuilder. ProcessingInstruction (target, content,
      contentStart, contentEnd, baseURI)
  END ProcessingInstruction;

PROCEDURE (b: Builder) Comment* (VAR chars: DTD.StringVar;
                                 start, end: DTD.CharPos);
  BEGIN
    b. delegateBuilder. Comment (chars, start, end)
  END Comment;



PROCEDURE Init* (b: Builder; delegateBuilder: B.Builder);
  VAR prefix: DTD.String; builtinURI: DTD.StringURI;
  BEGIN
    b. delegateBuilder := delegateBuilder;
    NEW (b. namespaceLocator);
    b. parserLocator := NIL;
    b. errorListener := NIL;
    b. failed := FALSE;
    
    b. currLevel := -1;
    NEW (b. stack, 16);
    
    NEW (b. namespaceList, 16);
    NEW (prefix, 4); LongStrings.Long ("xml", prefix^);
    NEW (builtinURI, LongStrings.Length8 (xmlURI)+1); COPY (xmlURI, builtinURI^);
    b. namespaceList[0] := DTD.NewNamespaceDeclaration (prefix, builtinURI);
    b. lenNamespaceList := 1;
    
    b. attrList := B.NewAttributeList();
  END Init;

PROCEDURE New* (delegateBuilder: B.Builder): Builder;
(**Creates a new builder that performs namespaces transformations on the
   parser callbacks.  Except for splitting qualified names into namespace URI
   and local name, all callbacks are passed on to @oparam{delegateBuilder}
   unchanged.  *)
  VAR
    b: Builder;
  BEGIN
    NEW (b);
    Init (b, delegateBuilder);
    RETURN b
  END New;


PROCEDURE SetErrorMessages;
  VAR
    i: INTEGER;
    t: ARRAY 128 OF CHAR;
  BEGIN
    FOR i := 0 TO 999 DO
      CASE i OF
      | emptyURI:
        t := "Namespace URI must not be empty"
      | malformedURIRef:
        t := "Malformed URI reference: ${uri_error}"
      | undeclaredPrefix:
        t := "Prefix `${prefix}' is not declared"
      | nameClash:
        t := "Attribute name conflicts with `${prefix}:${localName}'"
      | reservedBinding:
        t := "Reserved namespace prefix or URI binding"
      ELSE
        t := ""
      END;
      IF (t # "") THEN
        namespacesContext. SetString (i, t)
      END
    END
  END SetErrorMessages;

BEGIN
  namespacesContext := Error.NewContext ("XML:Builder:Namespaces");
  SetErrorMessages
END XMLBuilderNamespaces.
