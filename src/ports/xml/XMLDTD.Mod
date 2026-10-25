(* 	$Id: DTD.Mod,v 1.18 2001/03/24 12:22:10 mva Exp $	 *)
MODULE XMLDTD;
(*  Implements the internal representation of a document DTD.
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


(**This module implements the mechanisms to store, maintain, and query the data
   gathered from an XML document's DTD.  An instance of @otype{Builder} is
   created by the parser @otype{*XML:Parser.Parser} to hold a document's DTD
   information.  *)

IMPORT
  LongStrings, URI, Limits := XMLLimits,
  UnicodeCodec := XMLUnicodeCodec, UnicodeBuffer := XMLUnicodeBuffer;


TYPE
  Char* = UnicodeBuffer.Char;
  (**Character type used to store names and character data from an XML
     document.  *)
  String* = UnicodeBuffer.CharArray;
  (**A pointer to an array of @otype{Char}.  *)
  StringVar* = ARRAY OF Char;
  (**An open array with @otype{Char} as element type.  *)
  CharPos* = UnicodeBuffer.CharPos;
  (**This integer type is used to store the position of a character in the
     input buffer or in a string.  *)
  
TYPE
  StandaloneType* = SHORTINT;
  (**Used to store information about the @samp{standalone} of an XML
     declaration.  One of @oconst{standaloneYes}, @oconst{standaloneNo},
     @oconst{standaloneNotPresent}, or @oconst{standaloneNotApplicable}.  *)

CONST
  standaloneYes* = 0;
  standaloneNo* = 1;
  standaloneNotPresent* = 2;
  standaloneNotApplicable* = 3;
  
TYPE
  Namespace* = POINTER TO NamespaceDesc;
  Declaration* = POINTER TO DeclarationDesc;
  Builder* = POINTER TO BuilderDesc;
  BuilderDesc* = RECORD
    limits-: Limits.Budget;
    rootName-: String;
    (**Name of the root name, as given in the DTD.  *)
    
    geNamespace-: Namespace;
    (**Namespace with general entity declarations.  *)
    peNamespace-: Namespace;
    (**Namespace with parameter entity declarations.  *)
    elementNamespace-: Namespace;
    (**Namespace with element declarations.  *)
    
    attributeList-, attributeTail: Declaration;
    (**Holds attributes that cannot be attached to an element declaration,
       because no matching element type exists.  Before
       @oproc{*XML:Builder.EndDTD} has been called, this list holds all
       attributes seen so far by the parser.  *)
  END;


(* Declarations and Namespace
   ------------------------------------------------------------------------ *)

TYPE
  DeclarationDesc* = RECORD
    next-: Declaration;
    (**Next declaration in namespace.  *)
    name-: String;
    (**Name of the declared object.  *)
  END;

TYPE
  NamespaceDesc = RECORD
    limits: Limits.Budget;
    declList-: Declaration;
    (**Refers to the first element of the list of declarations.  The other
       declarations can be reached through @ofield{Declaration.next}.  *)
    
  END;


(* Attribute and Entity Value
   ------------------------------------------------------------------------ *)

TYPE
  Fragment* = POINTER TO FragmentDesc;
  FragmentDesc = RECORD
  (**Abstract base type for @otype{Characters} and @otype{EntityRef}.  *)
    next-: Fragment;
    (**Refers to the next fragment in the list @ofield{AttValue.fragmentList}.  *)
  END;

TYPE
  Characters* = POINTER TO CharactersDesc;
  CharactersDesc = RECORD
  (**A sequence of characters appearing in an attribute value.  *)
    (FragmentDesc)
    source-: String;
    (**The array slice @samp{@ofield{source}[@ofield{sourceStart},
       @ofield{sourceEnd}[} holds the fragment's character data.  *)
    sourceStart-, sourceEnd-: CharPos;
  END;

TYPE
  EntityRef* = POINTER TO EntityRefDesc;
  Entity* = POINTER TO EntityDesc;
  EntityRefDesc = RECORD
  (**A general entity reference appearing in an attribute value.  *)
  (FragmentDesc)
    name-: String;
    (**The name of the reference.  *)
    entity*: Entity;
    (**After the name has been resolved successfully, this field refers to the
       internal entity declaration that is being referenced.  *)
  END;

TYPE
  AttValue* = POINTER TO AttValueDesc;
  AttValueDesc = RECORD
  (**An attribute value is stored as a list of character data and general
     entity references.  That is, the internal structure of the value string is
     not resolved at first.  Character data is stored as
      @otype{Characters}, and entity references as @otype{EntityRef}.  *)
    limits-: Limits.Budget;
    fragmentList-, fragmentTail: Fragment;
    (**The head of the list of attribute value fragments.  For an empty
       attribute, this is @code{NIL}.  *)
  END;


(* Attribute Declaration
   ------------------------------------------------------------------------ *)

TYPE
  NameNode* = POINTER TO NameNodeDesc;
  NameNodeDesc = RECORD
  (**A name in an @otype{Enumeration}.  *)
    next-: NameNode;
    name-: String;
  END;

TYPE
  Enumeration* = POINTER TO EnumerationDesc;
  EnumerationDesc = RECORD
  (**Used to store an attribute value enumeration.  *)
    limits: Limits.Budget;
    nameList-, nameTail: NameNode;
    (**A list of names.  Used for both @oconst{attrENUMERATED} and
       @oconst{attrNOTATION}.  @ofield{NameNode.next} refers to the next
       element in the list.  *)
  END;


TYPE
  AttributeType* = SHORTINT;
  (**Indicates the type of an attribute.  See @oconst{attrCDATA} et al.  *)

CONST
  attrID* = 0;
  attrIDREF* = 1;
  attrIDREFS* = 2;
  attrENTITY* = 3;
  attrENTITIES* = 4;
  attrNMTOKEN* = 5;
  attrNMTOKENS* = 6;
  attrNOTATION* = 7;
  attrENUMERATED* = 8;
  attrCDATA* = 9;

TYPE
  DefaultType* = SHORTINT;
  (**Indicates the defaulting mode of an attribute declaration.  One of
     @oconst{attrRequired}, @oconst{attrImplied}, @oconst{attrDefault}, or
     @oconst{attrFixed}.  *)
  
CONST
  attrRequired* = 0;
  attrImplied* = 1;
  attrDefault* = 2;
  attrFixed* = 3;

TYPE
  AttrDecl* = POINTER TO AttrDeclDesc;
  AttrDeclDesc = RECORD
  (**An attribute declaration from a DTD.  *)
  (DeclarationDesc)
    elementName-: String;
    type-: AttributeType;
    externalMarkupDecl-: BOOLEAN;
    enumeration-: Enumeration;
    default-: DefaultType;
    defaultValue-: AttValue;
  END;

VAR
  undefAttr-: AttrDecl;

(* Entities
   ------------------------------------------------------------------------ *)

TYPE
  EntityType* = SHORTINT;
  (**Values of this type indicate the type of an entity.  See
     @oconst{entityInternalGeneral} et al.  *)
  
CONST
  entityInternalGeneral* = 0;
  (**Internal general entity.  *)
  entityInternalParameter* = 1;
  (**Internal parameter entity.  Such entities do not appear in the XML
     infoset.  *)
  entityExternalGeneral* = 2;
  (**External general entity.  *)
  entityExternalParameter* = 3;
  (**External parameter entity.  Such entities do not appear in the XML
     infoset.  *)
  entityUnparsed* = 4;
  (**Unparsed external general entity.  *)
  entityDocument* = 5;
  (**Document entity.  It represents the top-level entity of a document,
     the one that holds the internal DTD subset and the root element.  *)
  entityExternalDTDSubset* = 6;
  (**Entity representing the external DTD subset.  *)

TYPE
  EntityDesc = RECORD
  (**Abstract base type for both internal and external entities.  *)
    (DeclarationDesc)
    type-: EntityType;
    (**This field indicates the kind of entity.  It distinguishes between
       general/parameter, internal/external, and parsed/unparsed.  *)
    entityValue-: String;
    (**This is either the value of an internal entity, or the internalized
       version of an external entity.  For an internal entity, this field
       is never @code{NIL}.  This string is not terminated with an @code{0X},
       use @oproc{Entity.LengthValue} to determine its length.  *)
    externalMarkupDecl-: BOOLEAN;
    (**Set if the entity is declared in an external markup declaration.  *)
    expanding*: BOOLEAN;
    (**This field is used internally by the parser.  While expanding the 
       entity, it is set to @code{TRUE}.  *)
    attValue*: AttValue;
    (**This field is used internally by the parser.  If an entity is ever
       expanded within an attribute value, this field holds the expanded
       text before non-CDATA normalization.  *)
  END;

TYPE
  InternalEntity* = POINTER TO InternalEntityDesc;
  InternalEntityDesc = RECORD
    (EntityDesc)
  END;

TYPE
  ExternalEntity* = POINTER TO ExternalEntityDesc;
  ExternalEntityDesc = RECORD
    (EntityDesc)
    public-: String;
    (**Public identifier of the external entity.  May be @code{NIL}.  *)
    system-: String;
    (**System identifier of the external entity.  This field is never
       @code{NIL}.  *)
    ndata-: String;
    (**For a parsed entity declaration, this field is @code{NIL}.  For an
       unparsed entity, it holds the name of the @code{NDATA}.  *)
    baseURI-: URI.URI;
    (**The base URI of the external entity.  For a document entity, this 
       is the URI passed to @oproc{*XML:Parser.NewChannel}, and therefore may
       be @code{NIL}.  For other entities, it is either derived from the
       public or system identifier, and always present.  *)
    
    version-: String;
    (**The version string from the XML or text declaration.  @code{NIL}, if
       the version is omitted.  *)
    encoding-: String;
    (**The encoding string from the XML or text declaration.  @code{NIL}, if
       no encoding is given.  *)
    standalone-: StandaloneType;
    (**The standalone declaration.  Only applicable to the document entity.  *)
    
    codecFactory-: UnicodeCodec.Factory;
    (**The factory object that produced the Unicode decoder that is used to
       access the files contents.  If @ofield{encoding} is @code{NIL}, the
       factory is derived by auto detection.  Otherwise, the encoding 
       declaration @ofield{encoding} is used to retrieve it.  *)
  END;


(* Notations
   ------------------------------------------------------------------------ *)

TYPE
  Notation* = POINTER TO NotationDesc;
  NotationDesc = RECORD
  (**This class represent notation declarations  *)
    (DeclarationDesc)
    public-:String;
    (**Public identifier.  May be @code{NIL}.  *)
    system-: String;
    (**System identifier.  May be @code{NIL}.  *)
    baseURI-: URI.URI;
    (**The base URI of the external entity.  For a document entity, this 
       is the URI passed to @oproc{*XML:Parser.NewChannel}, and therefore may
       be @code{NIL}.  For other entities, it is either derived from the
       public or system identifier, and always present.  *)
  END;


(* Element Declaration and Element Content
   ------------------------------------------------------------------------ *)

TYPE
  CPModeType* = SHORTINT;
  
CONST
  cpOnce* = 0;
  cpOptional* = 1;
  cpRepeat0* = 2;
  cpRepeat1* = 3;

TYPE
  ContentType* = SHORTINT;

CONST
  contentEMPTY* = 0;
  contentANY* = 1;
  contentMixed* = 2;
  contentChildren* = 3;

TYPE
  CP* = POINTER TO CPDesc;
  CPDesc = RECORD
    cpMode-: SHORTINT;                   (* once, "?", "*", or "+" *)
    next-: CP;                           (* next in sequence or alternative *)
  END;
  
  ChoiceCP* = POINTER TO ChoiceCPDesc;
  ChoiceCPDesc = RECORD
    (CPDesc)
    list-: CP;
  END;
  SeqCP* = POINTER TO SeqCPDesc;
  SeqCPDesc = RECORD
    (CPDesc)
    list-: CP;
  END;
  NameCP* = POINTER TO NameCPDesc;
  NameCPDesc = RECORD
    (CPDesc)
    name-: String;
  END;


TYPE
  RegexpInfo* = POINTER TO RegexpInfoDesc;
  RegexpInfoDesc* = RECORD
  END;

TYPE
  ElementDecl* = POINTER TO ElementDeclDesc;
  ElementDeclDesc = RECORD
  (**Instances of this class represent element declarations.  *)
    (DeclarationDesc)
    contentModel-: CP;
    (**The content model of the element.  *)
    regexp-: RegexpInfo;
    (**Regular expression contructed for @samp{children} element content.  *)
    contentType-: ContentType;
    (**Type of the content model.  *)
    externalMarkupDecl-: BOOLEAN;
    (**Set if the entity is declared in an external markup declaration.  *)
    multipleDecl-: BOOLEAN;
    (**Set to @code{TRUE}, if more than one declaration of this element type
       appears in the DTD.  *)
    attrNamespace-: Namespace;
    (**The attribute namespace of the element.  *)
    idAttr-: AttrDecl;
    (**If the element has an ID attribute, then this field refers to its
       attribute declaration after @oproc{Builder.AttachAttributes} has been
       called.  If the element has no ID attribute, then this field is
       @code{NIL}.  If it has multiple ID attributes, it has the value
       @ovar{undefAttr}.  *)
    notationAttr-: AttrDecl;
    (**If the element has a NOTATION attribute, then this field refers to its
       attribute declaration after @oproc{Builder.AttachAttributes} has been
       called.  If the element has no NOTATION attribute, then this field is
       @code{NIL}.  If it has multiple NOTATION attributes, it has the value
       @ovar{undefAttr}.  *)
  END;

(* ------------------------------------------------------------------------ *)

TYPE
  ElementWhitespaceType* = SHORTINT;

CONST
  elementWhitespaceYes* = 0;
  (**This flag is used if the document source matches the production @code{S},
     the parser is validating, and the current element only permits
     element content.  *)
  elementWhitespaceNo* = 1;
  (**If the document source for a character sequence does not match the
     @code{S} production (for example, because it includes a non-whitespace
     character, a character reference, or is a @code{CDATA} section), then
     @oparam{*XML:Builder.Characters.elementWhitespace} is
     @oconst{elementWhitespaceNo}.  *)
  elementWhitespaceUnknown* = 2;
  (**If the document source matches the production @code{S}, but the parser
     does not know if the current element permits only element content, then
     the character data is flagged as @oconst{elementWhitespaceUnknown}.  *)
  

TYPE
  NamespaceDeclaration* = POINTER TO NamespaceDeclarationDesc;
  StringURI* = POINTER TO ARRAY OF CHAR;
  NamespaceDeclarationDesc = RECORD
    (**This class describes notation declaration items of the XML Information
       Set.  *)
    prefix-: String;
    (**The prefix being declared.  Syntactically, this is the part of the
       attribute name following the @code{xmlns:} prefix.  If the attribute
       name is simply @code{xmlns}, this field is @code{NIL}.  *)
    uri-: StringURI;
    (**The absolute URI (plus optional fragment identifier) of the namespace
        being declared.  It may be @code{NIL} if the attribute name
        is @code{xmlns}.  *)
  END;


(* Declarations and Namespace
   ------------------------------------------------------------------------ *)

PROCEDURE InitDeclaration* (decl: Declaration; name: String);
  BEGIN
    decl. next := NIL;
    decl. name := name;
  END InitDeclaration;

PROCEDURE InitNamespace (ns: Namespace);
  BEGIN
    ns. declList := NIL; ns. limits := NIL
  END InitNamespace;

PROCEDURE NewNamespace*(): Namespace;
  VAR
    ns: Namespace;
  BEGIN
    NEW (ns);
    InitNamespace (ns);
    RETURN ns
  END NewNamespace;

PROCEDURE (ns: Namespace) SetLimits* (limits: Limits.Budget);
  BEGIN ns. limits := limits END SetLimits;

PROCEDURE (ns: Namespace) Add* (decl: Declaration): BOOLEAN;
(**Adds the declaration @oparam{decl} to the namespace @oparam{ns}.  Nothing is
   done if the namespace already contains a declaration of the same name.  In
   this case, the value @code{FALSE} is returned.  If the declaration was
   added to the namespace, then the result is @code{TRUE}.  *)
   
  VAR ptr, last: Declaration;
  BEGIN
    decl. next := NIL;
    ptr := ns. declList; last := NIL;
    WHILE ptr # NIL DO
      IF (ns. limits # NIL) & ~ns. limits. Charge (Limits.work, 1) THEN RETURN FALSE END;
      IF LongStrings.Equal (ptr. name^, decl. name^) THEN RETURN FALSE END;
      last := ptr; ptr := ptr. next
    END;
    IF last = NIL THEN ns. declList := decl ELSE last. next := decl END;
    RETURN TRUE
  END Add;

PROCEDURE (ns: Namespace) Get* (name: String): Declaration;
  VAR
    ptr: Declaration;
  BEGIN
    ptr := ns. declList;
    WHILE (ptr # NIL) DO
      IF (ns. limits # NIL) & ~ns. limits. Charge (Limits.work, 1) THEN RETURN NIL END;
      IF LongStrings.Equal (ptr. name^, name^) THEN RETURN ptr END;
      ptr := ptr. next
    END;
    RETURN ptr
  END Get;


(* Attribute Value
   ------------------------------------------------------------------------ *)

PROCEDURE InitFragment* (f: Fragment);
  BEGIN
    f. next := NIL;
  END InitFragment;


PROCEDURE InitCharacters* (chars: Characters;
                           source: String; start, end: CharPos);
  BEGIN
    InitFragment (chars);
    chars. source := source;
    chars. sourceStart := start;
    chars. sourceEnd := end
  END InitCharacters;

PROCEDURE (b: Builder) NewCharacters* (source: String; start, end: CharPos;
                                       createCopy: BOOLEAN): Characters;
  VAR
    chars: Characters;
    len, i: CharPos;
    copy: String;
  BEGIN
    ASSERT ((0 <= start) & (start <= end) & (end <= LEN (source^)));
    NEW (chars);
    IF createCopy THEN
      len := end-start;
      ASSERT (len < MAX (LONGINT));
      NEW (copy, len+1);
      FOR i := 0 TO len-1 DO
        copy[i] := source[start+i]
      END;
      copy[len] := 0;
      InitCharacters (chars, copy, 0, len)
    ELSE
      InitCharacters (chars, source, start, end)
    END;
    RETURN chars
  END NewCharacters;


PROCEDURE InitEntityRef* (entRef: EntityRef; name: String; entity: Entity);
  BEGIN
    InitFragment (entRef);
    entRef. name := name;
    entRef. entity := entity
  END InitEntityRef;

PROCEDURE (b: Builder) NewEntityRef* (name: String;
                                      entity: Entity): EntityRef;
  VAR
    entRef: EntityRef;
  BEGIN
    NEW (entRef);
    InitEntityRef (entRef, name, entity);
    RETURN entRef
  END NewEntityRef;


PROCEDURE InitAttValue* (attValue: AttValue);
  BEGIN
    attValue. limits := NIL;
    attValue. fragmentList := NIL;
    attValue. fragmentTail := NIL;
  END InitAttValue;

PROCEDURE (b: Builder) NewAttValue* (): AttValue;
  VAR
    attValue: AttValue;
  BEGIN
    NEW (attValue);
    InitAttValue (attValue);
    attValue. limits := b. limits;
    RETURN attValue
  END NewAttValue;

PROCEDURE (attValue: AttValue) SetLimits* (limits: Limits.Budget);
(**Applies a budget to length calculation and flattening of this value,
   including nested entity values created by an application. *)
  BEGIN attValue. limits := limits END SetLimits;

PROCEDURE ValueLength (value: AttValue; limits: Limits.Budget; VAR len: LONGINT): BOOLEAN;
  VAR fragment: Fragment; n, maximum: LONGINT; ok: BOOLEAN;
  BEGIN
    IF ~limits. Enter() THEN RETURN FALSE END;
    fragment := value. fragmentList; ok := TRUE;
    WHILE (fragment # NIL) & ok DO
      ok := limits. Charge (Limits.work, 1); n := 0;
      IF ok THEN
        WITH fragment: Characters DO n := fragment. sourceEnd-fragment. sourceStart
        | fragment: EntityRef DO
          IF (fragment. entity # NIL) & (fragment. entity. attValue # NIL) THEN
            ok := ValueLength (fragment. entity. attValue, limits, len)
          ELSE n := LongStrings.Length (fragment. name^)+2
          END
        END;
        maximum := limits. maxAttributeUnits;
        IF (maximum < 0) OR (maximum > MAX (LONGINT)-2) THEN maximum := MAX (LONGINT)-2 END;
        IF (len > maximum) OR (n > maximum-len) THEN
          limits. Fail (Limits.attributeUnits); ok := FALSE
        ELSIF ok THEN INC (len, n); ok := limits. Charge (Limits.expandedUnits, n)
        END
      END;
      fragment := fragment. next
    END;
    limits. Leave; RETURN ok
  END ValueLength;

PROCEDURE (attValue: AttValue) Clear*;
  BEGIN
    attValue. fragmentList := NIL;
    attValue. fragmentTail := NIL
  END Clear;

PROCEDURE (attValue: AttValue) Append* (fragment: Fragment);
  BEGIN
    fragment. next := NIL;
    IF (attValue. fragmentList = NIL) THEN
      attValue. fragmentList := fragment
    ELSE
      attValue. fragmentTail. next := fragment
    END;
    attValue. fragmentTail := fragment
  END Append;

PROCEDURE (attValue: AttValue) Length* (): LONGINT;
(**Calculates the length of the attribute value, as if it were of type
   CDATA.  *)
  VAR
    fragment: Fragment;
    len: LONGINT;
  BEGIN
    len := 0;
    IF attValue. limits # NIL THEN
      IF ~ValueLength (attValue, attValue. limits, len) THEN RETURN 0 END;
      RETURN len
    END;
    fragment := attValue. fragmentList;
    WHILE (fragment # NIL) DO
      WITH fragment: EntityRef DO
        IF (fragment. entity # NIL) THEN
          INC (len, fragment. entity. attValue. Length())
        ELSE
          INC (len, LongStrings.Length (fragment. name^)+2)
        END
      | fragment: Characters DO
        INC (len, fragment. sourceEnd-fragment. sourceStart)
      END;
      fragment := fragment. next
    END;
    RETURN len
  END Length;

PROCEDURE (attValue: AttValue) FlattenValue* (normalizeWhitespace: BOOLEAN;
                                        VAR didNormalization: BOOLEAN): String;
(**Returns the string representation of the attribute value @oparam{attValue}.
   If @oparam{normalizeWhitespace} is @code{TRUE}, then sequences of spaces are
   collapsed into a single space, and leading and trailing whitespace is
   removed from the string.  On completion, @oparam{didNormalization} is
   @code{TRUE} if, and only if, the value was modified by normalizing
   whitespace.  *)
   
  VAR
    str: String;
    len, pos: LONGINT;
    skipSpace: BOOLEAN;
  
  PROCEDURE Append (value: AttValue);
    VAR
      f: Fragment;
    
    PROCEDURE Copy (VAR source: StringVar; start, end: CharPos);
      VAR
        i: LONGINT;
      BEGIN
        i := start;
        WHILE (i # end) DO
          IF (source[i] = 32) THEN
            IF ~skipSpace THEN
              str[pos] := 32;
              INC (pos);
              skipSpace := normalizeWhitespace
            ELSE
              didNormalization := TRUE
            END;
          ELSE
            skipSpace := FALSE;
            str[pos] := source[i];
            INC (pos)
          END;
          INC (i)
        END
      END Copy;
    
    BEGIN
      IF (attValue. limits # NIL) & ~attValue. limits. Enter() THEN RETURN END;
      f := value. fragmentList;
      WHILE (f # NIL) DO
        IF (attValue. limits # NIL) & ~attValue. limits. Charge (Limits.work, 1) THEN
          attValue. limits. Leave; RETURN
        END;
        WITH f: EntityRef DO
          IF (f. entity # NIL) & (f. entity. attValue # NIL) THEN
            Append (f. entity. attValue)
          ELSE
            str[pos] := ORD ("&"); INC (pos); skipSpace := FALSE;
            Copy (f. name^, 0, LongStrings.Length (f. name^));
            str[pos] := ORD (";"); INC (pos); skipSpace := FALSE
          END
        | f: Characters DO
          Copy (f. source^, f. sourceStart, f. sourceEnd)
        END;
        f := f. next
      END;
      IF attValue. limits # NIL THEN attValue. limits. Leave END
    END Append;
  
  BEGIN
    len := attValue. Length();
    NEW (str, len+2);
    (* the second additional character is used for entity value padding
       by the XML parser *)
    pos := 0;
    skipSpace := normalizeWhitespace;
    didNormalization := FALSE;
    IF (attValue. limits # NIL) & (attValue. limits. error # NIL) THEN
      str[0] := 0; RETURN str
    END;
    Append (attValue);
    IF normalizeWhitespace & (pos # 0) & (str[pos-1] = 32) THEN
      DEC (pos); didNormalization := TRUE
    END;
    str[pos] := 0;
    RETURN str
  END FlattenValue;

PROCEDURE (attValue: AttValue) Flatten* (attrDecl: AttrDecl): String;
(**Returns the string representation of the attribute value @oparam{attrDecl}.
   If @oparam{attrDecl} is not @code{NIL}, and the attribute's type is not
   @oconst{attrCDATA}, then sequences of spaces are collapsed into a single
   space, and leading and trailing whitespace is removed from the string.  *)
  VAR
    didNormalization: BOOLEAN;
  BEGIN
    RETURN attValue. FlattenValue ((attrDecl # NIL) &
                                   (attrDecl. type # attrCDATA),
                                   didNormalization);
  END Flatten;

PROCEDURE (attValue: AttValue) FlattenNorm* (attrDecl: AttrDecl;
                                        VAR didNormalization: BOOLEAN): String;
(**Like @oproc{AttValue.Flatten}, but reports if normalization has been done.
   On completion, @oparam{didNormalization} is @code{TRUE} if, and only if, the
   value was modified by normalizing whitespace.  *)
  BEGIN
    RETURN attValue. FlattenValue ((attrDecl # NIL) &
                                   (attrDecl. type # attrCDATA),
                                   didNormalization);
  END FlattenNorm;


(* Attribute Declaration
   ------------------------------------------------------------------------ *)

PROCEDURE (b: Builder) NewEnumeration*(): Enumeration;
  VAR
    enum: Enumeration;
  BEGIN
    NEW (enum);
    enum. limits := b. limits;
    enum. nameList := NIL;
    enum. nameTail := NIL;
    RETURN enum
  END NewEnumeration;

PROCEDURE (enumeration: Enumeration) Append* (name: String);
  VAR
    node: NameNode;
  BEGIN
    NEW (node);
    node. next := NIL;
    node. name := name;
    
    IF (enumeration. nameList = NIL) THEN
      enumeration. nameList := node
    ELSE
      enumeration. nameTail. next := node
    END;
    enumeration. nameTail := node
  END Append;

PROCEDURE (enumeration: Enumeration) Matches* (VAR name: StringVar): BOOLEAN;
(**Returns @code{TRUE}, if one of the names listed in the enumeration matches
   the string @oparam{name}.  *)
  VAR
    ptr: NameNode;
  BEGIN
    ptr := enumeration. nameList;
    WHILE (ptr # NIL) & ~LongStrings.Equal (ptr. name^, name) DO
      IF (enumeration. limits # NIL) & ~enumeration. limits. Charge (Limits.work, 1) THEN RETURN FALSE END;
      ptr := ptr. next
    END;
    RETURN (ptr # NIL)
  END Matches;


PROCEDURE InitAttrDecl* (attrDecl: AttrDecl; elementName, name: String;
                         type: AttributeType; enum: Enumeration;
                         default: DefaultType; defaultValue: AttValue;
                         externalMarkupDecl: BOOLEAN);
  BEGIN
    InitDeclaration (attrDecl, name);
    attrDecl. elementName := elementName;
    attrDecl. type := type;
    attrDecl. externalMarkupDecl := externalMarkupDecl;
    attrDecl. enumeration := enum;
    attrDecl. default := default;
    attrDecl. defaultValue := defaultValue;
  END InitAttrDecl;

PROCEDURE (b: Builder) NewAttrDecl* (elementName, name: String;
                        type: AttributeType; enum: Enumeration;
                        default: DefaultType; defaultValue: AttValue;
                        externalMarkupDecl: BOOLEAN): AttrDecl;
  VAR
    attrDecl: AttrDecl;
  BEGIN
    NEW (attrDecl);
    InitAttrDecl (attrDecl, elementName, name, type, enum,
                  default, defaultValue, externalMarkupDecl);
    RETURN attrDecl
  END NewAttrDecl;

PROCEDURE (b: Builder) AddAttribute* (attrDecl: AttrDecl);
  BEGIN
    IF (b. attributeList = NIL) THEN
      b. attributeList := attrDecl
    ELSE
      b. attributeTail. next := attrDecl
    END;
    b. attributeTail := attrDecl
  END AddAttribute;

PROCEDURE (b: Builder) AttachAttributes*;
(**Attaches all attribute declarations in the DTD to the declarations of
   their element.  *)
  VAR
    attrDecl: AttrDecl;
    ptr, decl: Declaration;
    elemDecl: ElementDecl;
    dummy: BOOLEAN;
  BEGIN
    ptr := b. attributeList;
    b. attributeList := NIL;
    b. attributeTail := NIL;
    
    WHILE (ptr # NIL) DO
      IF (b. limits # NIL) & ~b. limits. Charge (Limits.work, 1) THEN RETURN END;
      attrDecl := ptr(AttrDecl);
      ptr := attrDecl. next;
      
      decl := b. elementNamespace. Get (attrDecl. elementName);
      IF (decl = NIL) THEN               (* no matching attribute *)
        b. AddAttribute (attrDecl)
      ELSE
        elemDecl := decl(ElementDecl);
        dummy := elemDecl. attrNamespace. Add (attrDecl);
        IF (attrDecl. type = attrID) THEN
          IF (elemDecl. idAttr = NIL) THEN
            elemDecl. idAttr := attrDecl
          ELSE
            elemDecl. idAttr := undefAttr
          END
        ELSIF (attrDecl. type = attrNOTATION) THEN
          IF (elemDecl. notationAttr = NIL) THEN
            elemDecl. notationAttr := attrDecl
          ELSE
            elemDecl. notationAttr := undefAttr
          END
        END
      END
    END;
    b. attributeTail := NIL
  END AttachAttributes;


(* Entities
   ------------------------------------------------------------------------ *)

PROCEDURE InitEntity (ent: Entity; name: String; type: EntityType;
                      entityValue: String; externalMarkupDecl: BOOLEAN);
  BEGIN
    InitDeclaration (ent, name);
    ent. type := type;
    ent. externalMarkupDecl := externalMarkupDecl;
    ent. entityValue := entityValue;
    ent. expanding := FALSE;
    ent. attValue := NIL
  END InitEntity;

PROCEDURE (entity: Entity) SetEntityValue* (entityValue: String);
  BEGIN
    entity. entityValue := entityValue
  END SetEntityValue;

PROCEDURE (entity: Entity) LengthValue*(): LONGINT;
(**Returns the length of the entity's value.  *)
  BEGIN
    RETURN LEN (entity. entityValue^)-2
  END LengthValue;

PROCEDURE (entity: Entity) IsDocumentEntity* (): BOOLEAN;
  BEGIN
    RETURN FALSE
  END IsDocumentEntity;


PROCEDURE InitInternalEntity (ent: InternalEntity;
                              name: String; type: EntityType;
                              entityValue: String;
                              externalMarkupDecl: BOOLEAN);
  BEGIN
    InitEntity (ent, name, type, entityValue, externalMarkupDecl);
  END InitInternalEntity;

PROCEDURE (b: Builder) NewInternalEntity* (name: String; type: EntityType;
                                          entityValue: String;
                                          externalMarkupDecl: BOOLEAN): InternalEntity;
  VAR
    ent: InternalEntity;
  BEGIN
    NEW (ent);
    InitInternalEntity (ent, name, type, entityValue, externalMarkupDecl);
    RETURN ent
  END NewInternalEntity;

PROCEDURE (b: Builder) IsValidEntityDecl* (name, entityValue: String): BOOLEAN;
(**Tests if the internal entity declaration is legal.  If the name
   @oparam{name} refers to a predefined entity, but @oparam{entityValue} is no
   legal replacement text for the entity, then this function returns
   @code{FALSE}.  Otherwise, it returns @code{TRUE}.  *)
  BEGIN
    IF LongStrings.Equal8 (name^, "lt") THEN
      RETURN LongStrings.Equal8 (entityValue^, "&#60;")
    ELSIF LongStrings.Equal8 (name^, "amp") THEN
      RETURN LongStrings.Equal8 (entityValue^, "&#38;")
    ELSIF LongStrings.Equal8 (name^, "gt") THEN
      RETURN LongStrings.Equal8 (entityValue^, ">") OR LongStrings.Equal8 (entityValue^, "&#62;")
    ELSIF LongStrings.Equal8 (name^, "apos") THEN
      RETURN LongStrings.Equal8 (entityValue^, "'") OR LongStrings.Equal8 (entityValue^, "&#39;")
    ELSIF LongStrings.Equal8 (name^, "quot") THEN
      RETURN LongStrings.Equal8 (entityValue^, '"') OR LongStrings.Equal8 (entityValue^, "&#34;")
    ELSE
      RETURN TRUE
    END
  END IsValidEntityDecl;

PROCEDURE InitExternalEntity (ent: ExternalEntity;
                              name: String; type: EntityType;
                              public, system, ndata: String;
                              baseURI: URI.URI;
                              externalMarkupDecl: BOOLEAN);
  BEGIN
    InitEntity (ent, name, type, NIL, externalMarkupDecl);
    ent. public := public;
    ent. system := system;
    ent. baseURI := baseURI;
    ent. ndata := ndata;
    ent. version := NIL;
    ent. encoding := NIL;
    ent. standalone := standaloneNotApplicable
  END InitExternalEntity;

PROCEDURE (b: Builder) NewExternalEntity* (name: String; type: EntityType;
                                           public, system, ndata: String;
                                           baseURI: URI.URI;
                                           externalMarkupDecl: BOOLEAN): ExternalEntity;
  VAR
    ent: ExternalEntity;
  BEGIN
    NEW (ent);
    InitExternalEntity (ent, name, type, public, system, ndata, baseURI, externalMarkupDecl);
    RETURN ent
  END NewExternalEntity;

PROCEDURE (entity: ExternalEntity) SetCodecFactory* (codecFactory: UnicodeCodec.Factory);
  BEGIN
    entity. codecFactory := codecFactory;
  END SetCodecFactory;

PROCEDURE (entity: ExternalEntity) SetVersion* (version: String);
  BEGIN
    entity. version := version
  END SetVersion;

PROCEDURE (entity: ExternalEntity) SetEncoding* (encoding: String);
  BEGIN
    entity. encoding := encoding
  END SetEncoding;

PROCEDURE (entity: ExternalEntity) SetStandalone* (standalone: StandaloneType);
  BEGIN
    entity. standalone := standalone
  END SetStandalone;

PROCEDURE (entity: ExternalEntity) IsDocumentEntity* (): BOOLEAN;
  BEGIN
    RETURN (entity. type = entityDocument)
  END IsDocumentEntity;

PROCEDURE (b: Builder) NewExternalDTD* (public, system: String;
                                        baseURI: URI.URI): ExternalEntity;
  VAR
    entity: ExternalEntity;
  BEGIN
    NEW (entity);
    InitExternalEntity (entity, NIL, entityExternalDTDSubset,
                        public, system, NIL, baseURI, FALSE);
    RETURN entity
  END NewExternalDTD;

PROCEDURE (b: Builder) NewDocumentEntity* (baseURI: URI.URI): ExternalEntity;
  VAR
    entity: ExternalEntity;
  BEGIN
    NEW (entity);
    InitExternalEntity (entity, NIL, entityDocument,
                        NIL, NIL, NIL, baseURI, FALSE);
    entity. standalone := standaloneNotPresent;
    RETURN entity
  END NewDocumentEntity;


(* Notations
   ------------------------------------------------------------------------ *)

PROCEDURE InitNotation (notation: Notation; name, public, system: String; baseURI: URI.URI);
  BEGIN
    InitDeclaration (notation, name);
    notation. public := public;
    notation. system := system;
    notation. baseURI := baseURI
  END InitNotation;

PROCEDURE (b: Builder) NewNotation* (name, public, system: String; baseURI: URI.URI): Notation;
  VAR
    notation: Notation;
  BEGIN
    NEW (notation);
    InitNotation (notation, name, public, system, baseURI);
    RETURN notation
  END NewNotation;


(* Element Declaration and Element Content
   ------------------------------------------------------------------------ *)

PROCEDURE InitCP (cp: CP; cpMode: CPModeType);
  BEGIN
    cp. cpMode := cpMode;
    cp. next := NIL
  END InitCP;

PROCEDURE (cp: CP) SetNext* (next: CP);
  BEGIN
    cp. next := next
  END SetNext;

PROCEDURE (cp: CP) SetMode* (cpMode: SHORTINT);
  BEGIN
    cp. cpMode := cpMode
  END SetMode;


PROCEDURE InitChoiceCP* (choiceCP: ChoiceCP; cpMode: CPModeType; list: CP);
  BEGIN
    InitCP (choiceCP, cpMode);
    choiceCP. list := list
  END InitChoiceCP;

PROCEDURE (b: Builder) NewChoiceCP* (cpMode: CPModeType; list: CP): ChoiceCP;
  VAR
    choiceCP: ChoiceCP;
  BEGIN
    NEW (choiceCP);
    InitChoiceCP (choiceCP, cpMode, list);
    RETURN choiceCP
  END NewChoiceCP;

PROCEDURE InitSeqCP* (seqCP: SeqCP; cpMode: CPModeType; list: CP);
  BEGIN
    InitCP (seqCP, cpMode);
    seqCP. list := list
  END InitSeqCP;

PROCEDURE (b: Builder) NewSeqCP* (cpMode: CPModeType; list: CP): SeqCP;
  VAR
    seqCP: SeqCP;
  BEGIN
    NEW (seqCP);
    InitSeqCP (seqCP, cpMode, list);
    RETURN seqCP
  END NewSeqCP;

PROCEDURE InitNameCP* (nameCP: NameCP; cpMode: CPModeType; name: String);
  BEGIN
    InitCP (nameCP, cpMode);
    nameCP. name := name
  END InitNameCP;

PROCEDURE (b: Builder) NewNameCP* (cpMode: CPModeType; name: String): NameCP;
  VAR
    nameCP: NameCP;
  BEGIN
    NEW (nameCP);
    InitNameCP (nameCP, cpMode, name);
    RETURN nameCP
  END NewNameCP;


PROCEDURE InitElementDecl* (elemDecl: ElementDecl; name: String; contentModel: CP; attrNamespace: Namespace; externalMarkupDecl: BOOLEAN);
  BEGIN
    InitDeclaration (elemDecl, name);
    elemDecl. contentModel := contentModel;
    elemDecl. contentType := contentANY;
    elemDecl. regexp := NIL;
    
    IF (elemDecl. contentModel # NIL) THEN
      WITH contentModel: NameCP DO
        IF LongStrings.Equal8 (contentModel. name^, "EMPTY") THEN
          elemDecl. contentType := contentEMPTY
        ELSIF LongStrings.Equal8 (contentModel. name^, "ANY") THEN
          elemDecl. contentType := contentANY
        ELSE
          elemDecl. contentType := contentANY
          (* only possible after well-formnedness error *)
        END
      | contentModel: ChoiceCP DO
        IF (contentModel. list IS NameCP) &
           LongStrings.Equal8 (contentModel. list(NameCP). name^, "#PCDATA") THEN
          elemDecl. contentType := contentMixed
        ELSE
          elemDecl. contentType := contentChildren
        END
      ELSE
        elemDecl. contentType := contentChildren
      END
    END;
    elemDecl. externalMarkupDecl := externalMarkupDecl;
    elemDecl. multipleDecl := FALSE;
    elemDecl. attrNamespace := attrNamespace;
    elemDecl. idAttr := NIL;
    elemDecl. notationAttr := NIL;
  END InitElementDecl;

PROCEDURE (b: Builder) NewElementDecl* (name: String; contentModel: CP; externalMarkupDecl: BOOLEAN): ElementDecl;
  VAR
    elemDecl: ElementDecl;
  BEGIN
    NEW (elemDecl);
    InitElementDecl (elemDecl, name, contentModel, NewNamespace(), externalMarkupDecl);
    elemDecl. attrNamespace. limits := b. limits;
    RETURN elemDecl
  END NewElementDecl;

PROCEDURE (elemDecl: ElementDecl) SetRegexp* (regexp: RegexpInfo);
  BEGIN
    elemDecl. regexp := regexp
  END SetRegexp;

PROCEDURE (elemDecl: ElementDecl) SetMultipleDecl*;
  BEGIN
    elemDecl. multipleDecl := TRUE
  END SetMultipleDecl;

PROCEDURE (elemDecl: ElementDecl) IsEmpty* (): BOOLEAN;
  BEGIN
    RETURN (elemDecl. contentType = contentEMPTY)
  END IsEmpty;

PROCEDURE (elemDecl: ElementDecl) IsElementContent* (): BOOLEAN;
  BEGIN
    RETURN (elemDecl. contentType = contentChildren)
  END IsElementContent;



(* Misc
   ------------------------------------------------------------------------ *)

PROCEDURE (b: Builder) SetRootName* (name: String);
  BEGIN
    b. rootName := name
  END SetRootName;


(* Namespace Declaration
   ------------------------------------------------------------------------ *)

PROCEDURE InitNamespaceDeclaration (namespaceDecl: NamespaceDeclaration;
                                    prefix: String; uri: StringURI);
  BEGIN
    namespaceDecl. prefix := prefix;
    namespaceDecl. uri := uri
  END InitNamespaceDeclaration;

PROCEDURE NewNamespaceDeclaration* (prefix: String; uri: StringURI): NamespaceDeclaration;
  VAR
    namespaceDecl: NamespaceDeclaration;
  BEGIN
    NEW (namespaceDecl);
    InitNamespaceDeclaration (namespaceDecl, prefix, uri);
    RETURN namespaceDecl
  END NewNamespaceDeclaration;


(* ------------------------------------------------------------------------ *)

PROCEDURE GetString* (VAR string: ARRAY OF Char; start, end: LONGINT): String;
  VAR
    s: String;
    i: LONGINT;
  BEGIN
    NEW (s, end-start+1);
    FOR i := 0 TO end-start-1 DO
      s[i] := string[start+i]
    END;
    s[end-start] := 0;
    RETURN s
  END GetString;

PROCEDURE GetStringValue* (string: ARRAY OF Char): String;
  BEGIN
    RETURN GetString (string, 0, LongStrings.Length (string))
  END GetStringValue;

PROCEDURE GetStringURI* (VAR string: ARRAY OF CHAR; start, end: LONGINT): StringURI;
  VAR
    s: StringURI;
    i: LONGINT;
  BEGIN
    NEW (s, end-start+1);
    FOR i := 0 TO end-start-1 DO
      s[i] := string[start+i]
    END;
    s[end-start] := 0X;
    RETURN s
  END GetStringURI;

PROCEDURE (b: Builder) SetLimits* (limits: Limits.Budget);
(**Shares the parser's budget with DTD declaration lookup and insertion.
   Set this before adding application declarations. *)
  BEGIN
    b. limits := limits;
    b. geNamespace. limits := limits; b. peNamespace. limits := limits;
    b. elementNamespace. limits := limits
  END SetLimits;

PROCEDURE Init* (b: Builder);
(**Initializes the DTD builder.  Also registers the predefined general entities
   @samp{lt}, @samp{gt}, @samp{amp}, @samp{apos}, and @samp{quot}.  *)
  PROCEDURE PredefEntity (name, replacement: ARRAY OF CHAR);
    VAR
      nameString, replString: String;
      entity: Entity;
      dummy: BOOLEAN;
    BEGIN
      NEW (nameString, LongStrings.Length8 (name)+1);
      LongStrings.Long (name, nameString^);
      NEW (replString, LongStrings.Length8 (replacement)+2);
      LongStrings.Long (replacement, replString^);
      replString[LEN (replString^)-2] := UnicodeBuffer.markerEOD;
      
      entity := b. NewInternalEntity (nameString, entityInternalGeneral, 
                                      replString, FALSE);
      dummy := b. geNamespace. Add (entity)
    END PredefEntity;
  
  BEGIN
    b. limits := NIL;
    b. rootName := NIL;
    b. geNamespace := NewNamespace();
    b. peNamespace := NewNamespace();
    b. elementNamespace := NewNamespace();
    
    b. attributeList := NIL;
    b. attributeTail := NIL;
    
    PredefEntity ("lt", "&#60;");
    PredefEntity ("gt", ">");
    PredefEntity ("amp", "&#38;");
    PredefEntity ("apos", "'");
    PredefEntity ("quot", '"')
  END Init;

PROCEDURE New*(): Builder;
  VAR
    b: Builder;
  BEGIN
    NEW (b);
    Init (b);
    RETURN b
  END New;

BEGIN
  NEW (undefAttr);
  InitAttrDecl (undefAttr, NIL, NIL, -1, NIL, -1, NIL, FALSE);
END XMLDTD.
