(*      $Id: Validation.Mod,v 1.10 2001/03/24 01:11:35 mva Exp $   *)
MODULE XMLBuilderValidation;
(*  Adds validation services to the XML:Parser.
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
  Ascii, Msg, LongStrings, URI, Limits := XMLLimits,
  Error := XMLError, DTD := XMLDTD, Locator := XMLLocator,
  Parser := XMLParser, Regexp := XMLRegexp, B := XMLBuilder;


TYPE
  Builder* = POINTER TO BuilderDesc;
  Stack = POINTER TO ARRAY OF
    RECORD
      elem: DTD.ElementDecl;
      matcher: Regexp.Matcher;
    END;
  BuilderDesc = RECORD
  (**This builder adds validation services to the parser.  It performs
     additional error checking, but does not change element, attribute, or
     content data.

     Assuming that @samp{builder} is an instance of @otype{B.Builder}, the
     following commands create a validating parser:

     @example
      builder := Validation.New (builder);
     p := Parser.NewFile (filePath, NIL, NIL, NIL, builder, res);
     p. validating := TRUE;
     @end example  *)
    (B.BuilderDesc)
    parserLocator: Locator.Locator;
    delegateBuilder: B.Builder;
    errorListener: Locator.ErrorListener;
    
    documentEntity: DTD.ExternalEntity;
    dtd: DTD.Builder;
    notationNamespace: DTD.Namespace;
    idNamespace: DTD.Namespace;
    idrefNamespace: DTD.Namespace;
    
    currLevel: LONGINT;
    (* level of current element; document element is 0, each nesting level
       adds 1 *)
    stack: Stack;
    (* stack[currLevel].elem may be NIL, if the element type is not declared *)
  END;

TYPE
  IDDecl = POINTER TO IDDeclDesc;
  IDDeclDesc = RECORD
  (**Created for every attribute with the type ID.  *)
    (DTD.DeclarationDesc)
  END;



CONST  (* error codes *)
  attributeNotDeclared = 1;
  notName = 2;
  notNames = 3;
  noSuchGeneralEntity = 4;
  notAnUnparsedEntity = 5;
  multipleIDAttr = 6;
  multipleNOTATIONAttr = 7;
  emptyElemWithNOTATION = 8;
  notationMismatch = 9;
  notationAlreadyDeclared = 10;
  noSuchNotation = 11;
  notNmtoken = 12;
  notNmtokens = 13;
  notInEnumeration = 14;
  fixedDefaultMismatch = 15;
  invalidDefaultID = 16;
  invalidDefaultValue = 17;
  multipleIDs = 18;
  invalidIDREF = 19;
  invalidStandaloneWhitespace = 20;
  invalidStandaloneAttrNormalization = 21;
  invalidStandaloneAttrEntityRef = 22;
  invalidStandaloneDefaultAttr = 23;
  invalidStandaloneElemEntityRef = 24;
  invalidCharacterContent = 25;
  rootMismatch = 26;
  mixedTypeDuplicate = 27;
  unknownUnparsedEntityNotation = 28;
  expectedEndTag = 29;
  expectedElement = 30;
  noSuchElementType = 31;
  invalidContentInEMPTY = 32;
  multipleElemDecl = 33;
  invalidElementContentCDATA = 34;
  duplicateToken = 35;
  nondeterministicContent = 36;
  
VAR
  validationContext: Error.Context;
  dummyElement: DTD.ElementDecl;
  dummyName: ARRAY 32 OF DTD.Char;
  

PROCEDURE (b: Builder) SetLocator* (locator: Locator.Locator);
  BEGIN
    b. parserLocator := locator;
    b. delegateBuilder. SetLocator (locator)
  END SetLocator;

PROCEDURE (b: Builder) SetLimits* (limits: Limits.Budget);
  BEGIN
    b. SetLimits^ (limits);
    b. notationNamespace. SetLimits (limits); b. idNamespace. SetLimits (limits);
    b. idrefNamespace. SetLimits (limits); b. delegateBuilder. SetLimits (limits)
  END SetLimits;

PROCEDURE (b: Builder) SetErrorListener* (el: Locator.ErrorListener);
  BEGIN
    b. errorListener := el;
    b. delegateBuilder. SetErrorListener (el)
  END SetErrorListener;

PROCEDURE Err (b: Builder; code: Error.Code);
  VAR
    err: Error.Msg;
  BEGIN
    err := b. errorListener. Error (validationContext, code,
                                    FALSE, b. parserLocator^)
  END Err;

PROCEDURE ErrString (b: Builder; code: Error.Code;
                     name: ARRAY OF CHAR; value: DTD.String);
  VAR
    err: Error.Msg;
  BEGIN
    err := b. errorListener. Error (validationContext, code,
                                    FALSE, b. parserLocator^);
    err. SetLStringAttrib (name, Msg.GetLStringPtr (value^));
  END ErrString;

PROCEDURE ErrString2 (b: Builder; code: Error.Code;
                      name1: ARRAY OF CHAR; value1: DTD.String;
                      name2: ARRAY OF CHAR; value2: DTD.String);
  VAR
    err: Error.Msg;
  BEGIN
    err := b. errorListener. Error (validationContext, code,
                                    FALSE, b. parserLocator^);
    err. SetLStringAttrib (name1, Msg.GetLStringPtr (value1^));
    err. SetLStringAttrib (name2, Msg.GetLStringPtr (value2^));
  END ErrString2;

PROCEDURE ErrString3 (b: Builder; code: Error.Code;
                      name1: ARRAY OF CHAR; value1: DTD.String;
                      name2: ARRAY OF CHAR; value2: DTD.String;
                      name3: ARRAY OF CHAR; value3: DTD.String);
  VAR
    err: Error.Msg;
  BEGIN
    err := b. errorListener. Error (validationContext, code,
                                    FALSE, b. parserLocator^);
    err. SetLStringAttrib (name1, Msg.GetLStringPtr (value1^));
    err. SetLStringAttrib (name2, Msg.GetLStringPtr (value2^));
    err. SetLStringAttrib (name3, Msg.GetLStringPtr (value3^));
  END ErrString3;

PROCEDURE IncErrorPos (b: Builder; delta: LONGINT);
  BEGIN
    INC (b. parserLocator. charIndex, delta);
    INC (b. parserLocator. column, delta)
  END IncErrorPos;


PROCEDURE IsS (ch: DTD.Char): BOOLEAN;
  BEGIN
    RETURN (ch = ORD (Ascii.sp)) OR (ch = ORD (Ascii.ht)) OR
           (ch = ORD (Ascii.cr)) OR (ch = ORD (Ascii.lf))
  END IsS;

PROCEDURE IsName (VAR string: ARRAY OF DTD.Char): BOOLEAN;
  VAR
    i: LONGINT;
  BEGIN
    IF ~Parser.IsNameChar0 (string[0]) THEN
      RETURN FALSE
    ELSE
      i := 1;
      WHILE (string[i] # 0) DO
        IF ~Parser.IsNameChar (string[i]) THEN
          RETURN FALSE
        END;
        INC (i)
      END;
      RETURN TRUE
    END
  END IsName;

PROCEDURE IsNames (VAR string: ARRAY OF DTD.Char): BOOLEAN;
  VAR
    i: LONGINT;
  BEGIN
    i := 0;
    LOOP
      IF Parser.IsNameChar0 (string[i]) THEN
        REPEAT
          INC (i)
        UNTIL ~Parser.IsNameChar (string[i]);
        IF (string[i] = 0) THEN       (* end of string *)
          RETURN TRUE
        ELSIF (string[i] = ORD (Ascii.sp)) THEN
          INC (i)
        ELSE                           (* name includes invalid char *)
          EXIT
        END
      ELSE
        EXIT                           (* not looking at Name *)
      END
    END;
    RETURN FALSE
  END IsNames;

PROCEDURE IsNmtoken (VAR string: ARRAY OF DTD.Char): BOOLEAN;
  VAR
    i: LONGINT;
  BEGIN
    IF ~Parser.IsNameChar (string[0]) THEN
      RETURN FALSE
    ELSE
      i := 1;
      WHILE (string[i] # 0) DO
        IF ~Parser.IsNameChar (string[i]) THEN
          RETURN FALSE
        END;
        INC (i)
      END;
      RETURN TRUE
    END
  END IsNmtoken;

PROCEDURE IsNmtokens (VAR string: ARRAY OF DTD.Char): BOOLEAN;
  VAR
    i: LONGINT;
  BEGIN
    i := 0;
    LOOP
      IF Parser.IsNameChar (string[i]) THEN
        REPEAT
          INC (i)
        UNTIL ~Parser.IsNameChar (string[i]);
        IF (string[i] = 0) THEN       (* end of string *)
          RETURN TRUE
        ELSIF (string[i] = ORD (Ascii.sp)) THEN
          INC (i)
        ELSE                           (* name includes invalid char *)
          EXIT
        END
      ELSE
        EXIT                           (* not looking at Name *)
      END
    END;
    RETURN FALSE
  END IsNmtokens;

PROCEDURE IsStandalone (b: Builder): BOOLEAN;
  BEGIN
    RETURN (b. documentEntity. standalone = DTD.standaloneYes) &
           (b. parserLocator. entity. type = DTD.entityDocument)
  END IsStandalone;


PROCEDURE NewIDDecl (name: DTD.String): IDDecl;
  VAR
    idDecl: IDDecl;
  BEGIN
    NEW (idDecl);
    DTD.InitDeclaration (idDecl, name);
    RETURN idDecl
  END NewIDDecl;

PROCEDURE PushElement (b: Builder; elemDecl: DTD.Declaration);
  VAR
    i: LONGINT;
    new: Stack;
  BEGIN
    IF (b. currLevel+1 = LEN (b. stack^)) THEN
      NEW (new, LEN (b. stack^)*2);
      FOR i := 0 TO LEN (b. stack^)-1 DO
        new[i] := b. stack[i]
      END;
      b. stack := new;
    END;
    INC (b. currLevel);
    IF (elemDecl = NIL) THEN
      b. stack[b. currLevel]. elem := dummyElement;
      b. stack[b. currLevel]. matcher := NIL;
    ELSE
      b. stack[b. currLevel]. elem := elemDecl(DTD.ElementDecl);
      IF (elemDecl(DTD.ElementDecl). regexp = NIL) THEN
        b. stack[b. currLevel]. matcher := NIL
      ELSE
        b. stack[b. currLevel]. matcher :=
          Regexp.NewMatcher (elemDecl(DTD.ElementDecl). regexp(Regexp.Regexp))
      END
    END
  END PushElement;

PROCEDURE PopElement (b: Builder);
  BEGIN
    b. stack[b. currLevel]. elem := NIL;
    b. stack[b. currLevel]. matcher := NIL;
    DEC (b. currLevel)
  END PopElement;




PROCEDURE (b: Builder) StartDocument* (documentEntity: DTD.ExternalEntity);
  BEGIN
    b. documentEntity := documentEntity;
    b. delegateBuilder. StartDocument (documentEntity)
  END StartDocument;

PROCEDURE (b: Builder) EndDocument*;
  VAR
    ptr: DTD.Declaration;
  BEGIN
    (* check that all IDREF attributes have a matching ID counterpart *)
    ptr := b. idrefNamespace. declList;
    WHILE (ptr # NIL) DO
      IF ~b. Charge (1) THEN b. delegateBuilder. EndDocument; RETURN END;
      IF (b. idNamespace. Get (ptr. name) = NIL) THEN
        ErrString (b, invalidIDREF, "name", ptr. name)
      END;
      ptr := ptr. next
    END;
    
    b. delegateBuilder. EndDocument
  END EndDocument;

PROCEDURE (b: Builder) StartDTD* (dtdBuilder: DTD.Builder);
  BEGIN
    b. dtd := dtdBuilder;
    b. delegateBuilder. StartDTD (dtdBuilder)
  END StartDTD;

PROCEDURE (b: Builder) EndDTD* (externalDTD: DTD.ExternalEntity;
                                allDeclarationsProcessed: BOOLEAN);
  VAR
    decl: DTD.Declaration;
    elemDecl: DTD.ElementDecl;
    nameNode: DTD.NameNode;
    cp: DTD.CP;
    
  PROCEDURE CheckAttributes (list: DTD.Declaration);
    VAR
      decl: DTD.Declaration;
      attrDecl: DTD.AttrDecl;
      default: DTD.String;
      match, didNormalization: BOOLEAN;
    
    PROCEDURE DuplicateToken (list: DTD.NameNode): DTD.String;
      VAR
        ptr1, ptr2: DTD.NameNode;
      BEGIN
        ptr1 := list;
        WHILE (ptr1 # NIL) DO
          IF ~b. Charge (1) THEN RETURN NIL END;
          ptr2 := ptr1. next;
          WHILE (ptr2 # NIL) DO
            IF ~b. Charge (1) THEN RETURN NIL END;
            IF LongStrings.Equal (ptr1. name^, ptr2. name^) THEN
              RETURN ptr1. name
            END;
            ptr2 := ptr2. next
          END;
          ptr1 := ptr1. next
        END;
        RETURN NIL
      END DuplicateToken;
  
    BEGIN
      decl := list;
      WHILE (decl # NIL) DO
        IF ~b. Charge (1) THEN RETURN END;
        attrDecl := decl(DTD.AttrDecl);
        
        IF (attrDecl. default >= DTD.attrDefault) THEN
          IF (attrDecl. type = DTD.attrID) THEN
            (* an ID attribute must be #IMPLIED or #REQUIRED *)
            ErrString2 (b, invalidDefaultID, "element", attrDecl. elementName,
                        "attribute", attrDecl. name)
          ELSE
            (* the default value of an attribute must match the syntactical 
               contraints of the attribute type *)
            default := attrDecl. defaultValue. FlattenNorm (attrDecl,
                                                            didNormalization);
            CASE attrDecl. type OF
            | DTD.attrIDREF, DTD.attrENTITY:
              match := IsName (default^)
            | DTD.attrIDREFS, DTD.attrENTITIES:
              match := IsNames (default^)
            | DTD.attrNMTOKEN:
              match := IsNmtoken (default^)
            | DTD.attrNMTOKENS:
              match := IsNmtokens (default^)
            | DTD.attrENUMERATED:
              match := IsNmtoken (default^) &
                       attrDecl. enumeration. Matches (default^)
            | DTD.attrNOTATION:
              match := IsName (default^) &
                       attrDecl. enumeration. Matches (default^)
            | DTD.attrCDATA:
              match := TRUE
            END;
            IF ~match THEN
              ErrString2 (b, invalidDefaultValue,
                          "element", attrDecl. elementName,
                          "attribute", attrDecl. name)
            END
          END
        END;
        
        (* all names in a attribute notation declaration must be declared *)
        IF (attrDecl. type = DTD.attrNOTATION) THEN
          nameNode := attrDecl. enumeration. nameList;
          WHILE (nameNode # NIL) DO
            IF ~b. Charge (1) THEN RETURN END;
            IF (b. notationNamespace. Get (nameNode. name) = NIL) THEN
              ErrString3 (b, noSuchNotation, 
                          "name", nameNode. name,
                          "element", attrDecl. elementName,
                          "attribute", attrDecl. name)
            END;
            nameNode := nameNode. next
          END
        END;
        
        (* the tokens in a enumeration/NOTATION declaration must be unique *)
        IF ((attrDecl. type = DTD.attrENUMERATED) OR
            (attrDecl. type = DTD.attrNOTATION)) &
           (DuplicateToken (attrDecl. enumeration. nameList) # NIL) THEN
          ErrString3 (b, duplicateToken, 
                      "name", DuplicateToken (attrDecl.enumeration.nameList),
                      "element", attrDecl. elementName,
                      "attribute", attrDecl. name)
        END;
    
        decl := decl. next
      END
    END CheckAttributes;
  
  PROCEDURE InList (name: DTD.String; list: DTD.CP): BOOLEAN;
    BEGIN
      WHILE (list # NIL) & ~LongStrings.Equal (list(DTD.NameCP). name^, name^) DO
        IF ~b. Charge (1) THEN RETURN FALSE END;
        list := list. next
      END;
      RETURN (list # NIL)
    END InList;
  
  BEGIN
    (* check VCs on attributes that could not be attached to any element *)
    CheckAttributes (b. dtd. attributeList);
    
    decl := b. dtd. elementNamespace. declList;
    WHILE (decl # NIL) DO
      IF ~b. Charge (1) THEN RETURN END;
      elemDecl := decl(DTD.ElementDecl);
      
      IF elemDecl. multipleDecl THEN
        (* an element type must be declared only once *)
        ErrString (b, multipleElemDecl, "element", elemDecl. name)
      END;
      
      IF (elemDecl. idAttr = DTD.undefAttr) THEN
        (* an element may have at most one ID attribute *)
        ErrString (b, multipleIDAttr, "element", elemDecl. name)
      END;
      
      IF (elemDecl. notationAttr = DTD.undefAttr) THEN
        (* an element may have at most one NOTATION attribute *)
        ErrString (b, multipleNOTATIONAttr, "element", elemDecl. name)
      ELSIF (elemDecl. notationAttr # NIL) & elemDecl. IsEmpty() THEN
        ErrString2 (b, emptyElemWithNOTATION,
                     "element", elemDecl. name,
                     "attribute", elemDecl. notationAttr. name)
      END;
      
      IF (elemDecl. contentType = DTD.contentChildren) THEN
        (* create regular expression for `children' content *)
        elemDecl. SetRegexp (Regexp.NewLimited (elemDecl. contentModel, b. limits));
        IF ~b. Charge (0) THEN RETURN END;
        IF ~elemDecl. regexp(Regexp.Regexp). IsDeterministic() THEN
          ErrString (b, nondeterministicContent, "element", elemDecl. name)
        END
      ELSIF (elemDecl. contentType = DTD.contentMixed) THEN
        (* check that every child entry in a Mixed type is unique *)
        cp := elemDecl. contentModel(DTD.ChoiceCP). list;
        WHILE (cp # NIL) DO
          IF ~b. Charge (1) THEN RETURN END;
          IF InList (cp(DTD.NameCP). name, cp. next) THEN
            ErrString2 (b, mixedTypeDuplicate,
                        "element", elemDecl. name,
                        "child", cp(DTD.NameCP). name)
          END;
          cp := cp. next
        END
      END;
      
      (* check VCs on attributes attached to the current element *)
      CheckAttributes (elemDecl. attrNamespace. declList);
      
      decl := decl. next
    END;
    
    decl := b. dtd. geNamespace. declList;
    WHILE (decl # NIL) DO
      IF ~b. Charge (1) THEN RETURN END;
      IF (decl(DTD.Entity). type = DTD.entityUnparsed) &
         (b. notationNamespace. Get (decl(DTD.ExternalEntity). ndata) = NIL) THEN
        ErrString2 (b, unknownUnparsedEntityNotation,
                    "entity", decl. name,
                    "notation", decl(DTD.ExternalEntity). ndata)
      END;
      decl := decl. next
    END;
    
    b. delegateBuilder. EndDTD (externalDTD, allDeclarationsProcessed)
  END EndDTD;



PROCEDURE CheckEmpty (b: Builder);
  BEGIN
    IF (b. currLevel >= 0) &
       (b. stack[b. currLevel]. elem. contentType = DTD.contentEMPTY) THEN
      ErrString (b, invalidContentInEMPTY,
                 "element", b. stack[b. currLevel]. elem. name)
    END
  END CheckEmpty;

PROCEDURE (b: Builder) StartElement* (namespaceDecl: DTD.NamespaceDeclaration; 
                                      localName: DTD.String);
  VAR
    elemDecl: DTD.Declaration;
    expected: DTD.String;
    list: DTD.CP;
  
  PROCEDURE InCPList (name: DTD.String; list: DTD.CP): BOOLEAN;
    BEGIN
      WHILE (list # NIL) & ~LongStrings.Equal (list(DTD.NameCP). name^, name^) DO
        IF ~b. Charge (1) THEN RETURN FALSE END;
        list := list. next
      END;
      RETURN (list # NIL)
    END InCPList;
  
  PROCEDURE ListMixedElements (list: DTD.CP): DTD.String;
    VAR
      str, str2: DTD.String;
      len, i: LONGINT;
    BEGIN
      NEW (str, 64);
      str[0] := 0;
      len := 0;
      
      WHILE (list # NIL) DO
        IF ~b. Charge (1) THEN RETURN str END;
        i := LongStrings.Length (list(DTD.NameCP). name^);
        IF (len+i+1 >= LEN (str^)) THEN
          NEW (str2, len+i+2);
          LongStrings.Assign (str^, str2^);
          str := str2
        END;
        str[len] := ORD (" ");
        str[len+1] := 0;
        LongStrings.Append (list(DTD.NameCP). name^, str^);
        INC (len, i+1);
        list := list. next
      END;
      RETURN str
    END ListMixedElements;

  BEGIN
    IF ~b. Charge (1) THEN RETURN END;
    CheckEmpty (b);
    IF (b. currLevel = -1) THEN          (* this is the root element *)
      IF (b. dtd = NIL) THEN
        (* document has no DTD, e.g. because it's completely broken *)
        b. dtd := DTD.New()
      ELSIF ~LongStrings.Equal (b. dtd. rootName^, localName^) THEN
        ErrString (b, rootMismatch, "name", b. dtd. rootName)
      END
      
    ELSIF (b. stack[b. currLevel]. matcher # NIL) THEN
      (* this element has a parent, and we are within a `children' content
         model *)
      IF ~b. stack[b. currLevel]. matcher. Matches (localName) THEN
        expected := b. stack[b. currLevel]. matcher. ExpectedTags (b. stack[b. currLevel]. elem. name);
        IncErrorPos (b, -1);
        IF (expected = NIL) THEN
          ErrString (b, expectedEndTag,
                     "element", b. stack[b. currLevel]. elem. name)
        ELSE
          ErrString (b, expectedElement, "elements", expected)
        END;
        IncErrorPos (b, 1);
      END
      
    ELSIF (b. stack[b. currLevel]. elem. contentType = DTD.contentMixed) THEN
      (* this element has a parent, and we are within a `Mixed' content
         model: make sure that this element is in the given list *)
      list := b. stack[b. currLevel]. elem. contentModel(DTD.ChoiceCP). list;
      IF ~InCPList (localName, list) THEN
        IncErrorPos (b, -1);
        ErrString (b, expectedElement, "elements", ListMixedElements (list));
        IncErrorPos (b, 1);
      END
    END;
    
    (* check that the element type is declared *)
    elemDecl := b. dtd. elementNamespace. Get (localName);
    IF ~b. Charge (0) THEN RETURN END;
    IF (elemDecl = NIL) THEN
      ErrString (b, noSuchElementType, "name", localName)
    END;
    PushElement (b, elemDecl);
    IF ~b. Charge (0) THEN RETURN END;
    b. delegateBuilder. StartElement (namespaceDecl, localName)
  END StartElement;

PROCEDURE (b: Builder) EndElement* (namespaceDecl: DTD.NamespaceDeclaration; 
                                    localName: DTD.String);
  VAR
    expected: DTD.String;
  BEGIN
    IF ~b. Charge (1) THEN RETURN END;
    (* did we reach the end of the regular expression of the `children'
       content model? *)
    IF (b. stack[b. currLevel]. matcher # NIL) &
       ~b. stack[b. currLevel]. matcher. EndOfRegexp() THEN
      expected := b. stack[b. currLevel]. matcher. ExpectedTags (b. stack[b. currLevel]. elem. name);
      IF (expected # NIL) THEN
        IncErrorPos (b, -2);
        ErrString(b, expectedElement, "elements", 
                  expected);
        IncErrorPos (b, 2)
      END
    END;
    
    IF ~b. Charge (0) THEN RETURN END;
    b. delegateBuilder. EndElement (namespaceDecl, localName);
    PopElement (b)
  END EndElement;

PROCEDURE (b: Builder) Attribute* (namespaceDecl: DTD.NamespaceDeclaration; 
                                   localName: DTD.String;
                                   attrDecl: DTD.AttrDecl;
                                   value: DTD.AttValue;
                                   specified: BOOLEAN);
  VAR
    string, substr, default: DTD.String;
    decl: DTD.Declaration;
    i, start: LONGINT;
    dummy, didNormalization: BOOLEAN;
    ref: DTD.Entity;
  
  PROCEDURE ExternalReference (attValue: DTD.AttValue): DTD.Entity;
    VAR
      fragment: DTD.Fragment;
      ref: DTD.Entity;
    BEGIN
      ref := NIL;
      IF attValue = NIL THEN RETURN NIL END;
      fragment := attValue. fragmentList;
      WHILE (ref = NIL) & (fragment # NIL) DO
        IF ~b. Charge (1) THEN RETURN NIL END;
        IF (fragment IS DTD.EntityRef) &
           (fragment(DTD.EntityRef). entity # NIL) THEN
          IF fragment(DTD.EntityRef). entity. externalMarkupDecl THEN
            ref := fragment(DTD.EntityRef). entity
          ELSE
            ref := 
              ExternalReference (fragment(DTD.EntityRef). entity. attValue)
          END
        END;
        fragment := fragment. next
      END;
      RETURN ref
    END ExternalReference;
  
  BEGIN
    IF ~b. Charge (1) THEN RETURN END;
    IF (attrDecl = NIL) THEN
      Err (b, attributeNotDeclared)
    ELSE
      string := value. FlattenNorm (attrDecl, didNormalization);
      CASE attrDecl. type OF
      | DTD.attrENTITY:
        (* check if an unparsed entity of the given name exists; we don't need
           to check the attribute syntax, because all declared entities have
           a valid name *)
        IF specified & ~IsName (string^) THEN
          ErrString (b, notName, "name", string)
        ELSE
          decl := b. dtd. geNamespace. Get (string);
          IF (decl = NIL) THEN
            ErrString (b, noSuchGeneralEntity, "name", string)
          ELSIF (decl(DTD.Entity). type # DTD.entityUnparsed) THEN
            ErrString (b, notAnUnparsedEntity, "name", string)
          END
        END
      
      | DTD.attrENTITIES:
        IF specified & ~IsNames (string^) THEN
          Err (b, notNames)
        ELSE
          i := 0;
          LOOP
            IF ~b. Charge (1) THEN RETURN END;
            start := i;
            WHILE (string[i] > ORD (Ascii.sp)) DO
              INC (i)
            END;
            
            NEW (substr, i-start+1);
            LongStrings.Extract (string^, start, i-start, substr^);
            decl := b. dtd. geNamespace. Get (substr);
            IF (decl = NIL) THEN
              ErrString (b, noSuchGeneralEntity, "name", substr)
            ELSIF (decl(DTD.Entity). type # DTD.entityUnparsed) THEN
              ErrString (b, notAnUnparsedEntity, "name", substr)
            END;
            
            IF (string[i] = 0) THEN
              EXIT
            ELSE
              INC (i)
            END
          END
        END
      
      | DTD.attrNOTATION:
        IF ~attrDecl. enumeration. Matches (string^) THEN
          ErrString (b, notationMismatch, "name", string)
        END
        
      | DTD.attrNMTOKEN:
        IF specified & ~IsNmtoken (string^) THEN
          ErrString (b, notNmtoken, "name", string)
        END
      
      | DTD.attrNMTOKENS:
        IF specified & ~IsNmtokens (string^) THEN
          Err (b, notNmtokens)
        END
      
      | DTD.attrENUMERATED:
        IF specified & ~IsNmtoken (string^) THEN
          Err (b, notNmtoken)
        ELSIF ~attrDecl. enumeration. Matches (string^) THEN
          ErrString (b, notInEnumeration, "name", string)
        END
      
      | DTD.attrID:
        IF specified & ~IsName (string^) THEN
          ErrString (b, notName, "name", string)
        ELSIF ~b. idNamespace. Add (NewIDDecl (string)) THEN
          ErrString (b, multipleIDs, "name", string)
        END
        
      | DTD.attrIDREF:
        IF specified & ~IsName (string^) THEN
          ErrString (b, notName, "name", string)
        ELSE
          dummy := ~b. idrefNamespace. Add (NewIDDecl (string))
        END
        
      | DTD.attrIDREFS:
        IF specified & ~IsNames (string^) THEN
          ErrString (b, notNames, "name", string)
        ELSE
          i := 0;
          LOOP
            IF ~b. Charge (1) THEN RETURN END;
            start := i;
            WHILE (string[i] > ORD (Ascii.sp)) DO
              INC (i)
            END;
            
            NEW (substr, i-start+1);
            LongStrings.Extract (string^, start, i-start, substr^);
            dummy := ~b. idrefNamespace. Add (NewIDDecl (substr));
            
            IF (string[i] = 0) THEN
              EXIT
            ELSE
              INC (i)
            END
          END
        END
        
      ELSE  (* no validity constraints apply to the other attribute types *)
      END;
      
      (* for a #FIXED attribute, the value must match the default from the
         declaration *)
      IF (attrDecl. default = DTD.attrFixed) THEN
        default := attrDecl. defaultValue. Flatten (attrDecl);
        string := value. Flatten (attrDecl);
        IF ~LongStrings.Equal (string^, default^) THEN
          Err (b, fixedDefaultMismatch)
        END
      END;
      
      IF IsStandalone (b) THEN
        (* with standalone='yes', an attribute's default value must not be
           taken from an external markup declaration *)
        IF ~specified & attrDecl. externalMarkupDecl THEN
          ErrString (b, invalidStandaloneDefaultAttr,
                     "attribute", attrDecl. name)
        END;
        
        (* with standalone='yes', an attribute's value must not change with
           normalization, if the attribute was declared in an external markup
           declaration *)
        IF didNormalization & attrDecl. externalMarkupDecl THEN
          Err (b, invalidStandaloneAttrNormalization)
        END;
        
        (* with standalone='yes', an attribute's replacement text must not
           contain references to entities declared in an external markup
           declaration *)
        ref := ExternalReference (value);
        IF (ref # NIL) THEN
          ErrString (b, invalidStandaloneAttrEntityRef, "name", ref. name)
        END
      END
    END;
    
    IF ~b. Charge (0) THEN RETURN END;
    b. delegateBuilder. Attribute (namespaceDecl, localName, attrDecl,
                                   value, specified)
  END Attribute;
  
PROCEDURE (b: Builder) NamespaceDeclaration* (namespaceDecl: DTD.NamespaceDeclaration);
  BEGIN
    HALT (127)
  END NamespaceDeclaration;

PROCEDURE (b: Builder) AttributesDone*;
  BEGIN
    b. delegateBuilder. AttributesDone
  END AttributesDone;


PROCEDURE (b: Builder) SkippedEntity* (name: DTD.String; referent: DTD.Entity);
  BEGIN
    CheckEmpty (b);
    b. delegateBuilder. SkippedEntity (name, referent)
  END SkippedEntity;


PROCEDURE (b: Builder) Characters* (VAR chars: DTD.StringVar;
                                    charsStart, charsEnd: DTD.CharPos;
                                    elementWhitespace: DTD.ElementWhitespaceType);
  VAR
    elemDecl: DTD.ElementDecl;
  BEGIN
    IF ~b. Charge (1) THEN RETURN END;
    CheckEmpty (b);
    IF b. stack[b. currLevel]. elem. IsElementContent() THEN
      elemDecl := b. stack[b. currLevel]. elem;
      IF (elementWhitespace = DTD.elementWhitespaceNo) THEN
        ErrString (b, invalidElementContentCDATA, "element", elemDecl. name)
      ELSIF elemDecl. externalMarkupDecl & IsStandalone (b) THEN
        ErrString (b, invalidStandaloneWhitespace, "element", elemDecl. name)
      END;
      IF (elementWhitespace = DTD.elementWhitespaceUnknown) THEN
        elementWhitespace := DTD.elementWhitespaceYes
      END
    END;
    
    IF ~b. Charge (0) THEN RETURN END;
    b. delegateBuilder. Characters (chars, charsStart, charsEnd,
                                    elementWhitespace)
  END Characters;


PROCEDURE (b: Builder) StartCDATA*;
  BEGIN
    CheckEmpty (b);
    
    (* an element with element content cannot include non-whitespace character
       data; a CDATA section does not match S and is therefore forbidden *)
    IF b. stack[b. currLevel]. elem. IsElementContent() THEN
      ErrString (b, invalidCharacterContent,
                 "element", b. stack[b. currLevel]. elem. name)
    END;
    
    b. delegateBuilder. StartCDATA
  END StartCDATA;

PROCEDURE (b: Builder) EndCDATA*;
  BEGIN
    b. delegateBuilder. EndCDATA
  END EndCDATA;

PROCEDURE (b: Builder) StartEntity* (entity: DTD.Entity);
  BEGIN
    CheckEmpty (b);
    IF IsStandalone (b) & entity. externalMarkupDecl THEN
      Err (b, invalidStandaloneElemEntityRef)
    END;
    
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
    IF ~b. notationNamespace. Add (notation) THEN
      ErrString (b, notationAlreadyDeclared, "name", notation. name)
    END;
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
  VAR
    i: LONGINT;
  BEGIN
    b. delegateBuilder := delegateBuilder;
    b. parserLocator := NIL;
    b. errorListener := NIL;
    
    b. documentEntity := NIL;
    b. dtd := NIL;
    b. notationNamespace := DTD.NewNamespace();
    b. idNamespace := DTD.NewNamespace();
    b. idrefNamespace := DTD.NewNamespace();
    
    b. currLevel := -1;
    NEW (b. stack, 16);
    FOR i := 0 TO LEN (b. stack^)-1 DO
      b. stack[i]. elem := NIL;
      b. stack[i]. matcher := NIL;
    END
  END Init;

PROCEDURE New* (delegateBuilder: B.Builder): Builder;
(**Creates a builder that checks DTD validity and forwards callbacks to the
   application. Set the parser's validating field to TRUE and enable external
   references to check the complete DTD. Place this builder before the
   namespace builder so declarations are matched against qualified names. *)
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
      | attributeNotDeclared:
        t := "Attribute has not been declared"
      | notName:
        t := "Attribute value `${name}' does not match the Name production"
      | notNames:
        t := "Attribute value does not match the Names production"
      | noSuchGeneralEntity:
        t := "`${name}' refers to an unknown general entity"
      | notAnUnparsedEntity:
        t := "`${name}' refers to a parsed entity"
      | multipleIDAttr:
        t := "Element `${element}' has more than one ID attribute"
      | multipleNOTATIONAttr:
        t := "Element `${element}' has more than one NOTATION attribute"
      | emptyElemWithNOTATION:
        t := "Empty element `${element}' has a NOTATION attribute `${attribute}'"
      | notationMismatch:
        t := "`${name}' does not match any of the names of the notation declaration"
      | notationAlreadyDeclared:
        t := "Notation `${name}' is already declared"
      | noSuchNotation:
        t := "Attribute declaration `${element}/@${attribute}' refers to undeclared notation `${name}'"
      | notNmtoken:
        t := "Attribute value `${name}' does not match the Nmtoken production"
      | notNmtokens:
        t := "Attribute value does not match the Nmtokens production"
      | notInEnumeration:
        t := "`${name}' does not match any of the names of the enumeration declaration"
      | fixedDefaultMismatch:
        t := "Attribute value does not match the fixed default value"
      | invalidDefaultID:
        t := "Attribute declaration `${element}/@${attribute}' of type ID must not have a default value"
      | invalidDefaultValue:
        t := "Invalid default value in attribute declaration `${element}/@${attribute}'"
      | multipleIDs:
        t := "ID `${name}' is already defined"
      | invalidIDREF:
        t := "No matching ID attribute for IDREF `${name}'"
      | invalidStandaloneWhitespace:
        t := "With standalone='yes', `${element}' cannot have white space content"
      | invalidStandaloneAttrNormalization:
        t := "With standalone='yes', this attribute value must not change with normalization"
      | invalidStandaloneAttrEntityRef:
        t := "With standalone='yes', the attribute value refers to the externally declared entity `&${name};'"
      | invalidStandaloneDefaultAttr:
        t := "With standalone='yes', the attribute `${attribute}' is taken from an external markup declaration"
      | invalidStandaloneElemEntityRef:
        t := "With standalone='yes', this entity reference points to an externally declared entity"
      | invalidCharacterContent:
        t := "`${element}' does not have character content"
      | rootMismatch:
        t := "Element name does not match root name `${name}' from the DTD"
      | mixedTypeDuplicate:
        t := "In element `${element}', child `${child}' appears multiple times in the Mixed declaration"
      | unknownUnparsedEntityNotation:
        t := "Unparsed entity `${entity}' refers to undeclared notation `${notation}'"
      | expectedEndTag:
        t := "Expected end tag </${element}>"
      | expectedElement:
        t := "Expected tags:${elements}"
      | noSuchElementType:
        t := "Element type `${name}' is not declared"
      | invalidContentInEMPTY:
        t := "Parent element `${element}' is declared EMPTY"
      | multipleElemDecl:
        t := "Element `${element}' is declared more than once"
      | invalidElementContentCDATA:
        t := "Element `${element}' is restricted to element content"
      | duplicateToken:
        t := "Duplicate token `${name}' in enumerated attribute type `${element}/@${attribute}'"
      | nondeterministicContent:
        t := "Element `${element}' has a non-deterministic content model"
      ELSE
        t := ""
      END;
      IF (t # "") THEN
        validationContext. SetString (i, t)
      END
    END
  END SetErrorMessages;

BEGIN
  validationContext := Error.NewContext ("XML:Builder:Validation");
  SetErrorMessages;
  NEW (dummyElement);
  LongStrings.Long ("&validation-dummy", dummyName);
  DTD.InitElementDecl (dummyElement, DTD.GetStringValue (dummyName),
                       NIL, NIL, FALSE);
END XMLBuilderValidation.
