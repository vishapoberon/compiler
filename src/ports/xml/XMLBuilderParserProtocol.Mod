(*      $Id: ParserProtocol.Mod,v 1.11 2001/02/07 10:37:12 mva Exp $   *)
MODULE XMLBuilderParserProtocol;
(*  Records parser callbacks as XML for diagnostics and regression tests.
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
  Channel, IntStr, LongStrings, URI, File := URISchemeFile, Limits := XMLLimits,
  Codec := XMLUnicodeCodec, DTD := XMLDTD, B := XMLBuilder,
  Writer := XMLWriter, Locator := XMLLocator;


TYPE
  Builder* = POINTER TO BuilderDesc;
  BuilderDesc = RECORD
  (**Writes out the sequence of callbacks initiated by the parser.  Used for
     debugging purposes.  *)
    (B.BuilderDesc)
    w-: Writer.Writer;
    locator-: Locator.Locator;
  END;


PROCEDURE (b: Builder) SetLimits* (limits: Limits.Budget);
  BEGIN b. SetLimits^ (limits); b. w. SetLimits (limits) END SetLimits;

PROCEDURE String (w: Writer.Writer; name: ARRAY OF CHAR; string: DTD.String);
  BEGIN
    IF (string # NIL) THEN
      w. StartTagLatin1 (name, TRUE);
      w. Write (string^);
      w. EndTag
    END
  END String;

PROCEDURE Int (w: Writer.Writer; name: ARRAY OF CHAR; value: LONGINT);
  VAR
    val: ARRAY 32 OF CHAR;
  BEGIN
    w. StartTagLatin1 (name, TRUE);
    IntStr.IntToStr (value, val);
    w. WriteLatin1 (val);
    w. EndTag
  END Int;

PROCEDURE Boolean (w: Writer.Writer; name: ARRAY OF CHAR; value: BOOLEAN);
  BEGIN
    w. StartTagLatin1 (name, TRUE);
    IF value THEN
      w. WriteLatin1 ("yes")
    ELSE
      w. WriteLatin1 ("no")
    END;
    w. EndTag
  END Boolean;

PROCEDURE WriteURI (w: Writer.Writer; name: ARRAY OF CHAR; uri: URI.URI);
  BEGIN
    IF (uri # NIL) THEN
      w. StartTagLatin1 (name, TRUE);
      w. WriteURI (uri, FALSE);
      w. EndTag
    END
  END WriteURI;

PROCEDURE WritePos (b: Builder);
  BEGIN
    b. w. StartTagLatin1 ("locator", FALSE);
    IF (b. locator # NIL) & (b. locator. entity # NIL) &
       (b. locator. entity. baseURI # NIL) THEN
      Int (b. w, "char-index", b. locator. charIndex);
      Int (b. w, "line", b. locator. line);
      Int (b. w, "column", b. locator. column);
      WriteURI (b. w, "base-uri", b. locator. entity. baseURI)
    END;
    b. w. EndTag
  END WritePos;


PROCEDURE Notation (b: Builder; notation: DTD.Notation; writePos: BOOLEAN);
  VAR
    w: Writer.Writer;
  BEGIN
    IF (notation # NIL) THEN
      w := b. w;
      w. StartTagLatin1 ("notation", FALSE);
      String (w, "name", notation. name);
      String (w, "system-identifier", notation. system);
      String (w, "public-identifier", notation. public);
      WriteURI (w, "base-uri", notation. baseURI);
      IF writePos THEN
        WritePos (b)
      END;
      w. EndTag
    END
  END Notation;

PROCEDURE Entity (b: Builder; entity: DTD.Entity; writePos: BOOLEAN);
  VAR
    w: Writer.Writer;
  BEGIN
    w := b. w;
    w. StartTagLatin1 ("entity", FALSE);
    
    w. StartTagLatin1 ("type", TRUE);
    CASE entity. type OF
    | DTD.entityInternalGeneral: w. WriteLatin1 ("internal general")
    | DTD.entityInternalParameter: w. WriteLatin1 ("internal parameter")
    | DTD.entityExternalGeneral: w. WriteLatin1 ("external general")
    | DTD.entityExternalParameter: w. WriteLatin1 ("external parameter")
    | DTD.entityUnparsed: w. WriteLatin1 ("external general unparsed")
    | DTD.entityDocument: w. WriteLatin1 ("document")
    | DTD.entityExternalDTDSubset: w. WriteLatin1 ("external DTD subset")
    END;
    w. EndTag;
    
    String (w, "name", entity. name);
    WITH entity: DTD.ExternalEntity DO
      String (w, "system-identifier", entity. system);
      String (w, "public-identifier", entity. public);
      WriteURI (w, "base-uri", entity. baseURI);
      String (w, "notation", entity. ndata);
    | entity: DTD.InternalEntity DO
      w. StartTagLatin1 ("content", TRUE);
      w. WriteI (entity. entityValue^, 0, entity. LengthValue());
      w. EndTag
    END;
    
    IF writePos THEN
      WritePos (b)
    END;
    w. EndTag
  END Entity;

PROCEDURE NamespaceDeclaration (w: Writer.Writer; namespaceDecl: DTD.NamespaceDeclaration);
  BEGIN
    w. StartTagLatin1 ("namespace-declaration", FALSE);
    String (w, "prefix", namespaceDecl. prefix);
    IF (namespaceDecl. uri # NIL) THEN
      w. StartTagLatin1 ("namespace-uri", TRUE);
      w. WriteLatin1 (namespaceDecl. uri^);
      w. EndTag
    END;
    w. EndTag
  END NamespaceDeclaration;


PROCEDURE (b: Builder) SetLocator* (locator: Locator.Locator);
  BEGIN
    b. locator := locator
  END SetLocator;

PROCEDURE (b: Builder) StartDocument* (documentEntity: DTD.ExternalEntity);
  BEGIN
    b. w. StartTagLatin1 ("parser-protocol", FALSE);
    (*b. w. AttrURI ("xml:base", b. w. baseURI, TRUE);
        this breaks the simple minded diff tests, so I leave it out for now *)
    b. w. StartTagLatin1 ("start-document", FALSE);
    Entity (b, documentEntity, FALSE);
    WritePos (b);
    b. w. EndTag
  END StartDocument;

PROCEDURE (b: Builder) EndDocument*;
  BEGIN
    b. w. NewLine;
    b. w. StartTagLatin1 ("end-document", FALSE);
    WritePos (b);
    b. w. EndTag;
    b. w. EndTag;
    b. w. EndOfText
  END EndDocument;


PROCEDURE (b: Builder) StartDTD* (dtdBuilder: DTD.Builder);
  BEGIN
    b. w. NewLine;
    b. w. StartTagLatin1 ("start-dtd", FALSE);
    WritePos (b);
    b. w. EndTag
  END StartDTD;

PROCEDURE (b: Builder) EndDTD* (externalDTD: DTD.ExternalEntity;
                                allDeclarationsProcessed: BOOLEAN);
  BEGIN
    b. w. NewLine;
    b. w. StartTagLatin1 ("end-dtd", FALSE);
    IF (externalDTD # NIL) THEN
      Entity (b, externalDTD, FALSE)
    END;
    Boolean (b. w, "all-declarations-processed", allDeclarationsProcessed);
    WritePos (b);
    b. w. EndTag
  END EndDTD;



PROCEDURE (b: Builder) StartElement* (namespaceDecl: DTD.NamespaceDeclaration; 
                                      localName: DTD.String);
  BEGIN
    b. w. NewLine;
    b. w. StartTagLatin1 ("start-element", FALSE);
    IF (namespaceDecl # NIL) THEN
      NamespaceDeclaration (b. w, namespaceDecl)
    END;
    String (b. w, "local-name", localName);
    WritePos (b);
    b. w. EndTag
  END StartElement;

PROCEDURE (b: Builder) Attribute* (namespaceDecl: DTD.NamespaceDeclaration; 
                                   localName: DTD.String;
                                   attrDecl: DTD.AttrDecl;
                                   value: DTD.AttValue;
                                   specified: BOOLEAN);
  BEGIN
    b. w. NewLine;
    b. w. StartTagLatin1 ("attribute", FALSE);
    IF (namespaceDecl # NIL) THEN
      NamespaceDeclaration (b. w, namespaceDecl)
    END;
    String (b. w, "local-name", localName);
    IF (attrDecl # NIL) THEN
      b. w. StartTagLatin1 ("attr-type", TRUE);
      CASE attrDecl. type OF
      | DTD.attrID: b. w. WriteLatin1 ("ID")
      | DTD.attrIDREF: b. w. WriteLatin1 ("IDREF")
      | DTD.attrIDREFS: b. w. WriteLatin1 ("IDREFS")
      | DTD.attrENTITY: b. w. WriteLatin1 ("ENTITY")
      | DTD.attrENTITIES: b. w. WriteLatin1 ("ENTITIES")
      | DTD.attrNMTOKEN: b. w. WriteLatin1 ("NMTOKEN")
      | DTD.attrNMTOKENS: b. w. WriteLatin1 ("NMTOKENS")
      | DTD.attrNOTATION: b. w. WriteLatin1 ("NOTATION")
      | DTD.attrENUMERATED: b. w. WriteLatin1 ("ENUMERATED")
      | DTD.attrCDATA: b. w. WriteLatin1 ("CDATA")
      END;
      b. w. EndTag;
      b. w. StartTagLatin1 ("default-type", TRUE);
      CASE attrDecl. default OF
      | DTD.attrRequired: b. w. WriteLatin1 ("#REQUIRED")
      | DTD.attrImplied: b. w. WriteLatin1 ("#IMPLIED")
      | DTD.attrDefault: b. w. WriteLatin1 ("#DEFAULT")
      | DTD.attrFixed: b. w. WriteLatin1 ("#FIXED")
      END;
      b. w. EndTag
    END;
    IF value # NIL THEN String (b. w, "value", value. Flatten (attrDecl)) END;
    Boolean (b. w, "specified", specified);
    IF specified THEN
      WritePos (b)
    END;
    b. w. EndTag
  END Attribute;

PROCEDURE (b: Builder) NamespaceDeclaration* (namespaceDecl: DTD.NamespaceDeclaration);
  BEGIN
    b. w. NewLine;
    NamespaceDeclaration (b. w, namespaceDecl)
  END NamespaceDeclaration;

PROCEDURE (b: Builder) AttributesDone*;
  BEGIN
    b. w. NewLine;
    b. w. StartTagLatin1 ("attributes-done", FALSE);
    WritePos (b);
    b. w. EndTag
  END AttributesDone;

PROCEDURE (b: Builder) SkippedEntity* (name: DTD.String; referent: DTD.Entity);
  BEGIN
    b. w. NewLine;
    b. w. StartTagLatin1 ("skipped-entity", FALSE);
    String (b. w, "name", name);
    IF (referent # NIL) THEN
      Entity (b, referent, FALSE)
    END;
    WritePos (b);
    b. w. EndTag
  END SkippedEntity;

PROCEDURE (b: Builder) EndElement* (namespaceDecl: DTD.NamespaceDeclaration; 
                                    localName: DTD.String);
  BEGIN
    b. w. NewLine;
    b. w. StartTagLatin1 ("end-element", FALSE);
    IF (namespaceDecl # NIL) THEN
      NamespaceDeclaration (b. w, namespaceDecl)
    END;
    String (b. w, "local-name", localName);
    WritePos (b);
    b. w. EndTag
  END EndElement;

PROCEDURE (b: Builder) EntityDecl* (entity: DTD.Entity);
  BEGIN
    b. w. NewLine;
    Entity (b, entity, TRUE)
  END EntityDecl;

PROCEDURE (b: Builder) Notation* (notation: DTD.Notation);
  BEGIN
    b. w. NewLine;
    Notation (b, notation, TRUE)
  END Notation;

PROCEDURE (b: Builder) Characters* (VAR chars: DTD.StringVar;
                                    charsStart, charsEnd: DTD.CharPos;
                                    elementWhitespace: DTD.ElementWhitespaceType);
  BEGIN
    b. w. NewLine;
    b. w. StartTagLatin1 ("characters", FALSE);
    b. w. StartTagLatin1 ("chars", TRUE);
    b. w. WriteI (chars, charsStart, charsEnd);
    b. w. EndTag;
    b. w. StartTagLatin1 ("element-whitespace", TRUE);
    CASE elementWhitespace OF
    | DTD.elementWhitespaceYes: b. w. WriteLatin1 ("yes")
    | DTD.elementWhitespaceNo: b. w. WriteLatin1 ("no")
    | DTD.elementWhitespaceUnknown: b. w. WriteLatin1 ("unknown")
    END;
    b. w. EndTag;
    WritePos (b);
    b. w. EndTag
  END Characters;

PROCEDURE (b: Builder) StartCDATA*;
  BEGIN
    b. w. NewLine;
    b. w. StartTagLatin1 ("start-cdata", FALSE);
    WritePos (b);
    b. w. EndTag
  END StartCDATA;

PROCEDURE (b: Builder) EndCDATA*;
  BEGIN
    b. w. NewLine;
    b. w. StartTagLatin1 ("end-cdata", FALSE);
    WritePos (b);
    b. w. EndTag
  END EndCDATA;

PROCEDURE (b: Builder) StartEntity* (entity: DTD.Entity);
  VAR name: ARRAY 5 OF DTD.Char;
  BEGIN
    b. w. NewLine;
    b. w. StartTagLatin1 ("start-entity", FALSE);
    LongStrings.Long ("name", name);
    IF entity. name # NIL THEN b. w. AttrString (name, entity. name^) END;
    WritePos (b);
    b. w. EndTag
  END StartEntity;

PROCEDURE (b: Builder) EndEntity* (entity: DTD.Entity);
  VAR name: ARRAY 5 OF DTD.Char;
  BEGIN
    b. w. NewLine;
    b. w. StartTagLatin1 ("end-entity", FALSE);
    LongStrings.Long ("name", name);
    IF entity. name # NIL THEN b. w. AttrString (name, entity. name^) END;
    WritePos (b);
    b. w. EndTag
  END EndEntity;


PROCEDURE (b: Builder) ProcessingInstruction* (
                      target: DTD.String; VAR content: DTD.StringVar;
                      contentStart, contentEnd: DTD.CharPos; baseURI: URI.URI);
  BEGIN
    b. w. NewLine;
    b. w. StartTagLatin1 ("processing-instruction", FALSE);
    String (b. w, "target", target);
    b. w. StartTagLatin1 ("content", TRUE);
    b. w. WriteI (content, contentStart, contentEnd);
    b. w. EndTag;
    WriteURI (b. w, "base-uri", baseURI);
    WritePos (b);
    b. w. EndTag
  END ProcessingInstruction;

PROCEDURE (b: Builder) Comment* (VAR chars: DTD.StringVar;
                                 start, end: DTD.CharPos);
  BEGIN
    b. w. NewLine;
    b. w. StartTagLatin1 ("comment", FALSE);
    b. w. StartTagLatin1 ("content", TRUE);
    b. w. WriteI (chars, start, end);
    b. w. EndTag;
    WritePos (b);
    b. w. EndTag
  END Comment;


PROCEDURE New* (outputChannel: Channel.Channel;
                codecFactory: Codec.Factory): Builder;
  VAR
    b: Builder;
    cwd: URI.URI;
  BEGIN
    NEW (b);
    B.Init (b);
    b. w := Writer.New (outputChannel. NewWriter(), codecFactory, TRUE, 2);
    b. w. WriteTextDecl ("1.0", "");
    b. locator := NIL;
    cwd := File.GetCwd();
    IF (cwd # NIL) & (cwd IS URI.HierarchicalURI) THEN
      b. w. SetBaseURI (cwd(URI.HierarchicalURI))
    END;
    RETURN b
  END New;

END XMLBuilderParserProtocol.
