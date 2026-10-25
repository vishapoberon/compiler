(*      $Id: Builder.Mod,v 1.13 2001/03/20 22:16:31 mva Exp $   *)
MODULE XMLBuilder;
(*  Low-level builder interface to the XML parser.
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
  URI, Limits := XMLLimits, DTD := XMLDTD, Locator := XMLLocator;


TYPE
  Builder* = POINTER TO BuilderDesc;
  BuilderDesc* = RECORD
  (**This abstract class defines the interface of the XML parser to the
     application.  It is based on the W3C Working Draft @samp{XML Information
     Set}, dated March 2001.  This specification can be obtained at
     @url{http://www.w3.org/TR/2001/WD-xml-infoset-20010316/}.  All information
     items required by the XML Information Set are made available by the
     parser.

     The low-level interface to the parser is governed by two requirements: It
     must make all core properties (and, as far as possible, all peripheral
     properties) of the XML Infoset available to the application, and the
     parser must be able to serve it without any overhead.  For this reason,
     the interface is not an instance of any of the established parser
     interfaces, like SAX, SAX2, or DOM.  Specializations of @otype{Builder}
     provide these interfaces.

     The parser itself is @emph{not} namespace aware, even if this interface
     has the necessary hooks to provide namespace information.  Namespaces are
     implemented by a special builder, @otype{*XML:Builder:Namespaces.Builder},
     that translates between the parser and a namespace-aware application.

     The parser calls the type-bound procedures of the builder while traversing
     the document.  The string arguments passed to the procedures should not be
     modified by any concrete builder.

     In case of a fatal error, the parser will stop invoking any builder
     procedures, with the exception of @oproc{Builder.EndDocument}.

     @strong{Important}: The locator positions always refer to the top level of
     the processed file.  They do not follow internal entity references.  For
     example, if a start tag of an element is defined within an internal
     entity, then the locator position of @oproc{Builder.StartElement} is the
     position of the entity reference, instead of the position of the markup
     text.  *)
    limits-: Limits.Budget;
  END;


TYPE
  Attribute* = POINTER TO AttributeDesc;
  AttributeDesc = RECORD
  (**This class holds all the information passed to @oproc{Builder.Attribute}.
     The fields corresponds one-to-one to parameters of
     @oproc{Builder.Attribute}.  It is provided as a service to builders and
     applications that need to store attribute values before they can process
     them.  An example for this is the namespace-aware builder
     @otype{*XML:Builder:Namespaces.Builder}.  The parser does @emph{not}
     create instances of this class.  *)
    namespaceDecl*: DTD.NamespaceDeclaration; 
    localName*: DTD.String;
    attrDecl-: DTD.AttrDecl;
    value-: DTD.AttValue;
    specified-: BOOLEAN;
    pos-: Locator.Position;
  END;
  
TYPE
  AttributeList* = POINTER TO AttributeListDesc;
  AttributeArray = POINTER TO ARRAY OF Attribute;
  AttributeListDesc = RECORD
  (**Implements a list of attribute values.  Like @otype{Attribute}, this class
     is not used by the parser.  *)
    len-: LONGINT;
    (**The length of the attribute list.  *)
    attr-: AttributeArray;
    (**The attribute values stored in the list.  The pointers in the range
       @samp{[0, @ofield{len}-1[} refer to @otype{Attribute} instances.

       The array pointer can change when the list is modified.  *)
  END;


PROCEDURE (b: Builder) SetLimits* (limits: Limits.Budget);
(**Installs an optional shared parser budget. Delegating builders forward it
   to their delegate before document callbacks begin. *)
  BEGIN b. limits := limits END SetLimits;

PROCEDURE (b: Builder) Charge* (steps: LONGINT): BOOLEAN;
  BEGIN RETURN (b. limits = NIL) OR b. limits. Charge (Limits.work, steps) END Charge;

PROCEDURE (b: Builder) SetLocator* (locator: Locator.Locator);
(**Indicates which locator object the parser uses to communicate positional
   information.  If this method is not called before
   @oproc{Builder.StartDocument}, the builder should assume that no 
   locator is available during processing.  This method may be called 
   several times during processing of a document.
   
   @precond
   @samp{locator} is not @code{NIL}.
   @end precond  *)
  BEGIN
  END SetLocator;

PROCEDURE (b: Builder) SetErrorListener* (el: Locator.ErrorListener);
(**Indicates the object @oparam{el} that the builder should use for
   error signalling.  Any errors will subsequently be reported through
   @oproc{el.Error}.  This method is called by the parser before it
   begins processing of the document.  *)
  BEGIN
  END SetErrorListener;



PROCEDURE (b: Builder) StartDocument* (documentEntity: DTD.ExternalEntity);
(**Marks the start of the document.  This method is called just before parsing
   begins.  The base URI of the document can be obtained from
   @oparam{documentEntity}, if it has been passed to
   @oproc{*XML:Parser.NewChannel}.  The locator is positioned at the very
   beginning of the file.  *)
  BEGIN
  END StartDocument;

PROCEDURE (b: Builder) EndDocument*;
(**Called by the parser after it has processed the whole document.  Afterwards,
   none of the other builder methods will be called.  Note that unlike all the
   other event reporting methods, this method is even called if the document
   had a fatal error.  The locator is positioned at the very end of the
   file.  *)
  BEGIN
  END EndDocument;

PROCEDURE (b: Builder) StartDTD* (dtdBuilder: DTD.Builder);
(**Called by the parser just before it begins parsing the document type
   declaration.  @oparam{dtdBuilder} is the object that is used by the parser
   to build the DTD data structure.  All comments and processing instruction
   events that are reported between @oproc{Builder.StartDTD} and
   @oproc{Builder.EndDTD} are part of the DTD.  Events from the internal DTD
   are reported before events of the external DTD.  The locator is positioned
   at the beginning of @samp{<!DOCTYPE}.  *)
  BEGIN
  END StartDTD;

PROCEDURE (b: Builder) EndDTD* (externalDTD: DTD.ExternalEntity;
                                allDeclarationsProcessed: BOOLEAN);
(**This method is called by the paser when is done parsing the document type
   declaration.  If the DTD had an external subset, the reference to the entity
   is passed in @oparam{externalDTD}.  The public and system identifier of the
   external subset are available through the entity item.

   If @oparam{allDeclarationsProcessed} is @code{TRUE}, then the parser has
   read the complete DTD.

   The locator is positioned after the closing @samp{>} of the DTD, and the
   external DTD subset has been processed.  *)
  BEGIN
  END EndDTD;



PROCEDURE (b: Builder) StartElement* (namespaceDecl: DTD.NamespaceDeclaration; 
                                      localName: DTD.String);
(**Called whenever a start tag is being parsed.  For a namespace aware parser,
   @oparam{namespaceDecl} refers to the namespace URI of the element name.  If
   the name has no namespace part, the argument is @code{NIL}.
   @oparam{localName} is the element minus the namespace prefix and the colon.
   The namespace prefix of the attribute name can be obtained from
   @oparam{namespaceDecl}.

b   The locator is positioned at the beginning of the start tag's name.

   @strong{Note}: Namespaces are only partially supported in the parser itself.
   For full namespace support, the special builder class
   @otype{*XML:Builder:Namespaces.Builder} must be put between the parser and
   the application.  *)
  BEGIN
  END StartElement;

PROCEDURE (b: Builder) EndElement* (namespaceDecl: DTD.NamespaceDeclaration; 
                                    localName: DTD.String);
(**Called when an end tag is parsed.  See @oproc{Builder.StartElement} for
   a description of the arguments.  The locator is positioned at the beginning
   of the end tag's name, if an explicit end tag exists.  Otherwise, it is
   placed after the closing @samp{/>} of the empty element tag.  *)
  BEGIN
  END EndElement;

PROCEDURE (b: Builder) Attribute* (namespaceDecl: DTD.NamespaceDeclaration; 
                                   localName: DTD.String;
                                   attrDecl: DTD.AttrDecl;
                                   value: DTD.AttValue;
                                   specified: BOOLEAN);
(**Called for every attribute (specified or defaulted) of the current element.
   For a namespace aware parser, @oparam{namespaceDecl} refers to the namespace
   URI of the element name.  If the name has no namespace part, the argument is
   @code{NIL}.  @oparam{localName} is the element minus the namespace prefix
   and the colon.  The namespace prefix of the attribute name can be obtained
   from @oparam{namespaceDecl}.

   If an attribute declaration for this attribute is known to the parser, it is
   passed in @oparam{attrDecl}.  Without a declaration, the application should
   treat the attribute as if it were of type @oconst{DTD.attrCDATA}.

   If the attribute is specified in the element's attribute list, instead of
   being defaulted from the attribute's declaration, @oparam{specified} is
   @code{TRUE}.

   The attribute's value is passed into the parameter @oparam{value}.  Call
   @oproc{DTD.AttValue.Flatten} or @oproc{DTD.AttValue.FlattenValue} to
   retrieve the normalized value of the attribute.  You can also access the
   data structure @oparam{value}.  The string values in the data structure are
   normalized for @code{CDATA} values.  When reading @oparam{value} for
   non-@code{CDATA} attributes, you must collapse sequences of whitespace into
   a single space, and remove any whitespace from the beginning and the end of
   the attribute value.

   The locator is at the beginning of the attribute's name, if
   @oparam{specified} is @code{TRUE}.  For defaulted attributes, the locator is
   undefined.  *)
  BEGIN
  END Attribute;

PROCEDURE (b: Builder) NamespaceDeclaration* (namespaceDecl: DTD.NamespaceDeclaration);
(**Called for namespace declarations in an attribute list.  Note: The parser
   implementation @otype{*XML:Parser.Parser} does not know about namespaces and
   never calls this method.  Use the adapter builder
   @otype{*XML:Builder:Namespaces.Builder} to introduce namespace information
   into the event stream.  The locator position is undefined.  *)
  BEGIN
  END NamespaceDeclaration;

PROCEDURE (b: Builder) AttributesDone*;
(**Called when the all attributes of a start tag, specified or defaulted,
   have been reported to the application.  The locator is positioned after
   the closing @samp{>} of the start or empty element tag.  *)
  BEGIN
  END AttributesDone;


PROCEDURE (b: Builder) SkippedEntity* (name: DTD.String; entity: DTD.Entity);
(**This method is called for every entity skipped by a non-validating parser,
   if it configured to ignore references to external parsed entities.
   @oparam{name} is the name of the skipped entity and @oparam{entity} its
   entity declaration, if this information is available.  The locator refers to
   the beginning of the name of the entity reference.  *)
  BEGIN
  END SkippedEntity;


PROCEDURE (b: Builder) Characters* (VAR chars: DTD.StringVar;
                                 charsStart, charsEnd: DTD.CharPos;
                                 elementWhitespace: DTD.ElementWhitespaceType);
(**Called for non-markup characters that appear within the document element.
   The array slice @samp{@oparam{chars}[@oparam{charsStart},
   @oparam{charsEnd}[} holds the character data.  @oparam{elementWhitespace}
   indicates whether the characters are whitespace appearing within element
   content.  

   The locator refers to the first character.

   @emph{Note}: It is up to the parser how it partitions character data before
   reporting it to the application.  For example, the character data of an
   element may be reported in one call to @oproc{Builder.Characters}, or in
   multiple chunks, depending on embedded character references, general entity
   references, CDATA sections, and the size of the character content.  It is
   only guaranteed that this procedure is called with an integral number of ISO
   10646 characters (e.g., surrogate pairs are reported in one call).  *)
  BEGIN
  END Characters;


PROCEDURE (b: Builder) StartCDATA*;
(**Called at the beginning of a CDATA section.  The next calls to
   @oproc{Builder.Characters} before @oproc{Builder.EndCDATA} represent the
   CDATA's character content.

   The locator is positioned at @samp{<![CDATA[}.  *)
  BEGIN
  END StartCDATA;

PROCEDURE (b: Builder) EndCDATA*;
(**Called at the end of a CDATA section.  The locator refers to the position
   after the @samp{]]>}.  *)
  BEGIN
  END EndCDATA;

PROCEDURE (b: Builder) StartEntity* (entity: DTD.Entity);
(**This method is called before the replacement text of a general entity
   is inspected in an element's content.  @oparam{entity} refers to the
   entity that is being expanded.  The locator points to the @samp{&} in front
   of the name of the entity reference.  *)
  BEGIN
  END StartEntity;

PROCEDURE (b: Builder) EndEntity* (entity: DTD.Entity);
(**Called when parsing of the replacement text of @oparam{entity} is done.
  The locator points to the first character after the entity reference.  *)
  BEGIN
  END EndEntity;



PROCEDURE (b: Builder) EntityDecl* (entity: DTD.Entity);
(**Called for declarations of general entities.  The locator points to the
   first character of the declared name.

   Note: The document entity is passed to @oproc{Builder.StartDocument}, and
   the entity for the external DTD subset to @oproc{Builder.EndDTD}, of it
   exists.  *)
  BEGIN
  END EntityDecl;

PROCEDURE (b: Builder) Notation* (notation: DTD.Notation);
(**Called for notation declarations.  The locator points to the 
   first character of the declared name.  *)
  BEGIN
  END Notation;

PROCEDURE (b: Builder) ProcessingInstruction* (
                     target: DTD.String; VAR content: DTD.StringVar;
                     contentStart, contentEnd: DTD.CharPos; baseURI: URI.URI);
(**Called for processing instructions.  @oparam{target} holds the PI's target
   part.  The array slice @samp{@oparam{content}[@oparam{contentStart},
   @oparam{contentEnd}[} holds the content data.  @oparam{baseURI} is the
   absolute URI of the entity in which the PI appears.

   The locator is positioned at the @samp{<?}.  *)
  BEGIN
  END ProcessingInstruction;

PROCEDURE (b: Builder) Comment* (VAR chars: DTD.StringVar;
                                 charsStart, charsEnd: DTD.CharPos);
(**Called for comments.  The array slice
   @samp{@oparam{chars}[@oparam{charsStart}, @oparam{charsEnd}[} holds the
   comment's content.

   The locator is positioned at the @samp{<!--}.  *)
  BEGIN
  END Comment;



PROCEDURE Init* (b: Builder);
  BEGIN
    b. limits := NIL
  END Init;

PROCEDURE New*(): Builder;
(**Creates a new builder that does not do anything with the callbacks initiated
   by the parser.  *)
  VAR
    b: Builder;
  BEGIN
    NEW (b);
    Init (b);
    RETURN b
  END New;


(* Attribute Lists
   ------------------------------------------------------------------------ *)

PROCEDURE InitAttribute* (attr: Attribute;
                          namespaceDecl: DTD.NamespaceDeclaration; 
                          localName: DTD.String;
                          attrDecl: DTD.AttrDecl;
                          value: DTD.AttValue;
                          specified: BOOLEAN;
                          locator: Locator.Locator);
  BEGIN
    attr. namespaceDecl := namespaceDecl;
    attr. localName := localName;
    attr. attrDecl := attrDecl;
    attr. value := value;
    attr. specified := specified;
    IF locator # NIL THEN
      attr. pos := locator^
    ELSE
      attr. pos. charIndex := 0; attr. pos. line := 0; attr. pos. column := 0;
      attr. pos. entity := NIL; attr. pos. inInternalEntity := NIL
    END
  END InitAttribute;

PROCEDURE NewAttribute* (namespaceDecl: DTD.NamespaceDeclaration; 
                         localName: DTD.String;
                         attrDecl: DTD.AttrDecl;
                         value: DTD.AttValue;
                         specified: BOOLEAN;
                         locator: Locator.Locator): Attribute;
(**Creates a new attribute instance.  The instance's field are taken directly
   from the passed arguments.  The @oparam{locator} is discarded if 
   @oparam{specified} is @code{FALSE}.  *)
  VAR
    attr: Attribute;
  BEGIN
    NEW (attr);
    IF ~specified THEN
      locator := NIL
    END;
    InitAttribute (attr, namespaceDecl, localName, attrDecl, value,
                   specified, locator);
    RETURN attr
  END NewAttribute;


PROCEDURE InitAttributeList* (attrList: AttributeList);
  BEGIN
    NEW (attrList. attr, 4);
    attrList. len := 0
  END InitAttributeList;

PROCEDURE NewAttributeList* (): AttributeList;
(**Creates a new, empty attribute list.  *)
  VAR
    attrList: AttributeList;
  BEGIN
    NEW (attrList);
    InitAttributeList (attrList);
    RETURN attrList
  END NewAttributeList;

PROCEDURE (attrList: AttributeList) Clear*;
(**Returns @oparam{attrList} to an empty list.  *)
  VAR
    i: LONGINT;
  BEGIN
    FOR i := 0 TO attrList. len-1 DO
      attrList. attr[i] := NIL
    END;
    attrList. len := 0
  END Clear;

PROCEDURE (attrList: AttributeList) Append* (attr: Attribute);
(**Appends the attribute @oparam{attr} to the list.  *)
  VAR
    new: AttributeArray;
    i: LONGINT;
  BEGIN
    IF (attrList. len = LEN (attrList. attr^)) THEN
      NEW (new, attrList. len*2);
      FOR i := 0 TO attrList. len-1 DO
        new[i] := attrList. attr[i]
      END;
      attrList. attr := new
    END;
    attrList. attr[attrList. len] := attr;
    INC (attrList. len)
  END Append;

END XMLBuilder.
