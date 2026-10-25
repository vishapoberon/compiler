(*      $Id: Parser.Mod,v 1.31 2001/03/24 01:11:21 mva Exp $   *)
MODULE XMLParser;
(*  Implements the XML parser.
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
  Out, Ascii, Channel, Msg, LongStrings, URI, File := URISchemeFile,
  Codec := XMLUnicodeCodec, UTF8 := XMLUnicodeCodecUTF8, UTF16 := XMLUnicodeCodecUTF16,
  Locator := XMLLocator, EntityResolver := XMLEntityResolver,
  Limits := XMLLimits,
  Buffer := XMLUnicodeBuffer, Error := XMLError, DTD := XMLDTD, Builder := XMLBuilder;
  (* warning: the modules UTF8 and UTF16 are not used in this module, but
     they must be imported to guarantee that these codecs are available to
     the XML parser *)

TYPE
  PEInfo = RECORD
    oldChars: DTD.String;
    oldCPos,
    oldCurrLine,
    oldCurrLinePos,
    oldCurrLineTab: Buffer.CharPos;
    entity: DTD.Entity;
    in: Buffer.Input;
  END;

TYPE
  NameList = POINTER TO ARRAY OF DTD.String;
  PEInfoList = POINTER TO ARRAY OF PEInfo;
  ErrorListener = POINTER TO ErrorListenerDesc;
  Parser* = POINTER TO ParserDesc;
  ParserDesc = RECORD
  (**This class implements the actual XML parser.  It depends on
     @otype{DTD.Builder} to store and maintain the information gathered from a
     document's DTD, and on an instance of @otype{Builder.Builder} to pass on
     any data retrieved from the document content.

     The parser implementation is intended to be compliant to the specification
     ``Extensible Markup Language (XML) 1.0 (Second Edition)''
     @url{http://www.w3.org/TR/2000/REC-xml-20001006}, upto and including the
     erratas listed in @url{http://www.w3.org/XML/xml-V10-2e-errata} as of
     2001-03-07 (that is, upto and including E14).  *)
    
    errList-: Error.List;
    (**Holds all error messages related to the currently parsed XML document.
       After an error occured, @samp{errList.msgCount} is no longer zero.  *)
    limits-: Limits.Budget;
    aborted-: BOOLEAN;
    
    l: Locator.Locator;
    (* This object keeps track of file position (character index, line and
       column number).  It is passed to the builder to enable it to access
       this information for callback events.  *)
    errorListener: ErrorListener;
    (* This object is used by external code (typically, builders) to report
       errors during document processing.  *)
    errorPos: Locator.Position;
    er: EntityResolver.Resolver;
    in: Buffer.Input;
    initialBuilder, builder: Builder.Builder;
    (* When parsing starts, both @ofield{initialBuilder} and @ofield{builder}
       refer to the builder that was passed to @oproc{New}.  The first fatal
       error changes @ofield{builder} to an instance of the empty builder
       @otype{Builder.Builder}.  *)
    dtd: DTD.Builder;
    
    documentEntity: DTD.ExternalEntity;
    (* this is a reference to the document entity; the base URI that was passed
       to the constructor @oproc{New} is stored in this entity *)
    fileEntity: DTD.ExternalEntity;
    (* the field @ofield{fileEntity} is a reference to the entity (document,
       external DTD subset, or external entity) that is currently parsed; it
       is never @code{NIL} *)
       
    followExternalRef*: BOOLEAN;
    (**If @code{TRUE}, then the parser should try to follow references to the
       external DTD subset, external general entities and external parameter
       entities. It is an error if the external entity cannot be read. The
       default value is @code{TRUE}.  *)
    enforceQNames*: BOOLEAN;
    (**If @code{TRUE}, then the parser checks that element and attribute names
       also match the production @samp{QName}, and that entity names, PI
       targets, and notation names contain no colon.  This enables parts of the
       checks required from namespace aware parsers.  The default is
       @code{FALSE}.  *)
    validating*: BOOLEAN;
    (**If @code{TRUE}, then the parser checks that

       @itemize @bullet
       @item
       parameter entity references are expanded,

       @item
       parameter entity references do not violate the nesting requirements
       imposed by the various validity constraints,

       @item
       required attributes are present in an element's attribute list,
       @end itemize

       The default value of this field is @code{FALSE}.  Only use this setting
       in conjunction with a builder of type
       @otype{*XML:Builder:Validator.Builder}.  *)
    processDeclarations: BOOLEAN;
    (* if FALSE, then entity declarations and attribute declarations must not
       be processed; this field starts out TRUE, and is set to FALSE after
       a reference to a parameter entity that is not read, but only if 
       "standalone" is not "yes".  *)
    readCompleteDTD: BOOLEAN;
    (* if this field is TRUE at the end of the DTD, then all declarations have
       been read *)
    
    inDocumentElement: BOOLEAN;
    (* if TRUE, then the parser is within the document element *)
    inDTD: BOOLEAN;
    (* if TRUE, then the parser is within the document type declaration *)
    inExternalSubset: BOOLEAN;
    (* if TRUE, then the parser is within the external subset of the
       document type declaration *)
    inExternalEntity: BOOLEAN;
    (* if TRUE, then the parser is within an external parameter entity; note
       that the external subset is not considered to be an external parameter
       entity *)

    currEntityValue: DTD.AttValue;
    (* when parsing an entity value, this list is used to collect the text
       fragments from the value itself and any included parameter entity
       references *)
    
    nameList: NameList;
    lenNameList: LONGINT;
    (* these two fields hold a list of all attribute names that are part of
       a start tag or empty tag; using this list, the set of unsatisfied 
       default attributes is determined for the tag *)
    
    peStack: PEInfoList;
    lenPEStack: LONGINT;
    (* stack of currently being expanded entity declarations; maintained by
       PushEntity/PopEntity *)
       
    currLine, currLinePos, currLineTab: Buffer.CharPos;
    (* marker for a character position that stays accross NextBlock() calls *)
    lastError: Error.Msg;
  END;

CONST
  tabWidth = 8;
  caseEOB = -2;
  caseEOD = -1;

CONST
  initNameList = 8;
  incrNameList = 8;
  initPEStack = 4;
  incrPEStack = 4;
  
CONST
  stringSystemLiteral = 1;
  stringPubidLiteral = 2;
  stringVersion = 3;
  stringEncoding = 4;
  stringStandalone = 5;

VAR
  suplPubidChar: ARRAY 32 OF Buffer.Char;
  noName: DTD.String;


TYPE
  ErrorListenerDesc = RECORD
    (Locator.ErrorListenerDesc)
    p: Parser;
  END;


CONST  (* error codes *)
  (* lexical errors *)
  invalidChar = 1;
  junkAfterDocument = 2;
  invalidCloseCDATA = 3;
  invalidCommentDashDash = 4;
  commentNotClosed = 5;
  stringNotClosed = 6;
  piNotClosed = 7;
  cdataNotClosed = 8;
  expectedWhitespace = 9;
  expectedName = 10;
  expectedNmtoken = 11;
  expectedChar = 12;
  lAngleInAttValue = 13;
  expectedDigit10 = 14;
  expectedDigit16 = 15;
  expectedString = 16;
  invalidCharRef = 17;
  expectedEOS = 18;
  ignoreNotClosed = 19;
  invalidPubidChar = 20;
  invalidEncNameChar = 21;
  invalidVersionNumChar = 22;
  expectedNonEmptyString = 23;
  expectedYesNo = 24;
  xmlDeclNotAtBeginning = 25;
  reservedPITarget = 26;
  invalidCharacterEncodings = 27;        (* E79 says: this is a fatal error *)
  junkAfterExtSubset = 28;
  unknownCharacterEncoding = 29;
  invalidNCName = 30;
  invalidQName = 31;
  
  (* DTD errors *)
  expectedMarkupDecl = 105;
  expectedContentSpec = 106;
  expectedAttType = 107;
  expectedAttValue = 108;
  expectedEntityValue = 109;
  expectedCP = 110;
  expectedVersion = 111;
  expectedExternalID = 112;
  expectedConditional = 113;
  expectedPIEnd = 114;
  nonMarkupDeclPERef = 115;
  expectedEncodingDecl = 116;
  malformedURI = 117;
  invalidPredefEntityDecl = 118;
  
  (* document errors *)
  expectedElement = 208;
  expectedEndTag = 209;
  noSuchGeneralEntity = 210;
  noSuchParameterEntity = 211;
  multipleAttrName = 212;
  recursiveGeneralEntity = 213;
  requiredAttrMissing = 214;
  
  (* reference errors *)
  unbalancedPERef = 300;
  unbalancedGERef = 301;  (* unused...? *)
  invalidGEReplacement = 302;
  accessError = 303;
  referenceToUnparsed = 304;
  externalRefInAtttribute = 305;
  nestingViolation = 306;
  externalAccessDisabled = 307;
  recursiveParameterEntity = 308;
  
VAR
  parserContext: Error.Context;


(* ------------------------------------------------------------------------ *)

PROCEDURE IsCharUCS4 (ch: LONGINT): BOOLEAN;
  BEGIN
    RETURN (020H <= ch) & (ch <= 0D7FFH) OR
           (ch = 9H) OR (ch = 0AH) OR (ch = 0DH) OR
           (0E000H <= ch) & (ch <= 0FFFDH) OR
           (10000H <= ch) & (ch <= 10FFFFH)
  END IsCharUCS4;

PROCEDURE IsDigit (ch: Buffer.Char): BOOLEAN;
  BEGIN
    IF (ch < 100H) THEN
      RETURN (30H <= ch) & (ch <= 39H)
    ELSE
      RETURN (0660H <= ch) & (ch <= 0669H) OR (06F0H <= ch) & (ch <= 06F9H) OR
        (0966H <= ch) & (ch <= 096FH) OR (09E6H <= ch) & (ch <= 09EFH) OR
        (0A66H <= ch) & (ch <= 0A6FH) OR (0AE6H <= ch) & (ch <= 0AEFH) OR
        (0B66H <= ch) & (ch <= 0B6FH) OR (0BE7H <= ch) & (ch <= 0BEFH) OR
        (0C66H <= ch) & (ch <= 0C6FH) OR (0CE6H <= ch) & (ch <= 0CEFH) OR
        (0D66H <= ch) & (ch <= 0D6FH) OR (0E50H <= ch) & (ch <= 0E59H) OR
        (0ED0H <= ch) & (ch <= 0ED9H) OR (0F20H <= ch) & (ch <= 0F29H)
    END
  END IsDigit;

PROCEDURE IsBaseChar (ch: Buffer.Char): BOOLEAN;
  BEGIN
    IF (ch < 100H) THEN
      CASE ch OF
      | 0041H .. 005AH, 0061H .. 007AH, 00C0H .. 00D6H, 00D8H .. 00F6H,
        00F8H .. 00FFH:
        RETURN TRUE
      ELSE
        RETURN FALSE
      END
    ELSIF (ch < 400H) THEN
      RETURN (0100H <= ch) & (ch <= 0131H) OR (0134H <= ch) & (ch <= 013EH) OR
        (0141H <= ch) & (ch <= 0148H) OR (014AH <= ch) & (ch <= 017EH) OR
        (0180H <= ch) & (ch <= 01C3H) OR (01CDH <= ch) & (ch <= 01F0H) OR
        (01F4H <= ch) & (ch <= 01F5H) OR (01FAH <= ch) & (ch <= 0217H) OR
        (0250H <= ch) & (ch <= 02A8H) OR (02BBH <= ch) & (ch <= 02C1H) OR
        (ch = 0386H) OR (0388H <= ch) & (ch <= 038AH) OR (ch = 038CH) OR
        (038EH <= ch) & (ch <= 03A1H) OR (03A3H <= ch) & (ch <= 03CEH) OR
        (03D0H <= ch) & (ch <= 03D6H) OR (ch = 03DAH) OR (ch = 03DCH) OR
        (ch = 03DEH) OR (ch = 03E0H) OR (03E2H <= ch) & (ch <= 03F3H)
    ELSIF (ch < 800H) THEN
      RETURN (0401H <= ch) & (ch <= 040CH) OR (040EH <= ch) & (ch <= 044FH) OR
        (0451H <= ch) & (ch <= 045CH) OR (045EH <= ch) & (ch <= 0481H) OR
        (0490H <= ch) & (ch <= 04C4H) OR (04C7H <= ch) & (ch <= 04C8H) OR
        (04CBH <= ch) & (ch <= 04CCH) OR (04D0H <= ch) & (ch <= 04EBH) OR
        (04EEH <= ch) & (ch <= 04F5H) OR (04F8H <= ch) & (ch <= 04F9H) OR
        (0531H <= ch) & (ch <= 0556H) OR (ch = 0559H) OR
        (0561H <= ch) & (ch <= 0586H) OR (05D0H <= ch) & (ch <= 05EAH) OR
        (05F0H <= ch) & (ch <= 05F2H) OR (0621H <= ch) & (ch <= 063AH) OR
        (0641H <= ch) & (ch <= 064AH) OR (0671H <= ch) & (ch <= 06B7H) OR
        (06BAH <= ch) & (ch <= 06BEH) OR (06C0H <= ch) & (ch <= 06CEH) OR
        (06D0H <= ch) & (ch <= 06D3H) OR (ch = 06D5H) OR
        (06E5H <= ch) & (ch <= 06E6H)
    ELSIF (ch < 0C00H) THEN
      RETURN (0905H <= ch) & (ch <= 0939H) OR (ch = 093DH) OR
        (0958H <= ch) & (ch <= 0961H) OR (0985H <= ch) & (ch <= 098CH) OR
        (098FH <= ch) & (ch <= 0990H) OR (0993H <= ch) & (ch <= 09A8H) OR
        (09AAH <= ch) & (ch <= 09B0H) OR (ch = 09B2H) OR
        (09B6H <= ch) & (ch <= 09B9H) OR (09DCH <= ch) & (ch <= 09DDH) OR
        (09DFH <= ch) & (ch <= 09E1H) OR (09F0H <= ch) & (ch <= 09F1H) OR
        (0A05H <= ch) & (ch <= 0A0AH) OR (0A0FH <= ch) & (ch <= 0A10H) OR
        (0A13H <= ch) & (ch <= 0A28H) OR (0A2AH <= ch) & (ch <= 0A30H) OR
        (0A32H <= ch) & (ch <= 0A33H) OR (0A35H <= ch) & (ch <= 0A36H) OR
        (0A38H <= ch) & (ch <= 0A39H) OR (0A59H <= ch) & (ch <= 0A5CH) OR
        (ch = 0A5EH) OR (0A72H <= ch) & (ch <= 0A74H) OR
        (0A85H <= ch) & (ch <= 0A8BH) OR (ch = 0A8DH) OR
        (0A8FH <= ch) & (ch <= 0A91H) OR (0A93H <= ch) & (ch <= 0AA8H) OR
        (0AAAH <= ch) & (ch <= 0AB0H) OR (0AB2H <= ch) & (ch <= 0AB3H) OR
        (0AB5H <= ch) & (ch <= 0AB9H) OR (ch = 0ABDH) OR (ch = 0AE0H) OR
        (0B05H <= ch) & (ch <= 0B0CH) OR (0B0FH <= ch) & (ch <= 0B10H) OR
        (0B13H <= ch) & (ch <= 0B28H) OR (0B2AH <= ch) & (ch <= 0B30H) OR
        (0B32H <= ch) & (ch <= 0B33H) OR (0B36H <= ch) & (ch <= 0B39H) OR
        (ch = 0B3DH) OR (0B5CH <= ch) & (ch <= 0B5DH) OR
        (0B5FH <= ch) & (ch <= 0B61H) OR (0B85H <= ch) & (ch <= 0B8AH) OR
        (0B8EH <= ch) & (ch <= 0B90H) OR (0B92H <= ch) & (ch <= 0B95H) OR
        (0B99H <= ch) & (ch <= 0B9AH) OR (ch = 0B9CH) OR
        (0B9EH <= ch) & (ch <= 0B9FH) OR (0BA3H <= ch) & (ch <= 0BA4H) OR
        (0BA8H <= ch) & (ch <= 0BAAH) OR (0BAEH <= ch) & (ch <= 0BB5H) OR
        (0BB7H <= ch) & (ch <= 0BB9H)
    ELSIF (ch < 1000H) THEN
      RETURN (0C05H <= ch) & (ch <= 0C0CH) OR (0C0EH <= ch) & (ch <= 0C10H) OR
        (0C12H <= ch) & (ch <= 0C28H) OR (0C2AH <= ch) & (ch <= 0C33H) OR
        (0C35H <= ch) & (ch <= 0C39H) OR (0C60H <= ch) & (ch <= 0C61H) OR
        (0C85H <= ch) & (ch <= 0C8CH) OR (0C8EH <= ch) & (ch <= 0C90H) OR
        (0C92H <= ch) & (ch <= 0CA8H) OR (0CAAH <= ch) & (ch <= 0CB3H) OR
        (0CB5H <= ch) & (ch <= 0CB9H) OR (ch = 0CDEH) OR
        (0CE0H <= ch) & (ch <= 0CE1H) OR (0D05H <= ch) & (ch <= 0D0CH) OR
        (0D0EH <= ch) & (ch <= 0D10H) OR (0D12H <= ch) & (ch <= 0D28H) OR
        (0D2AH <= ch) & (ch <= 0D39H) OR (0D60H <= ch) & (ch <= 0D61H) OR
        (0E01H <= ch) & (ch <= 0E2EH) OR (ch = 0E30H) OR
        (0E32H <= ch) & (ch <= 0E33H) OR (0E40H <= ch) & (ch <= 0E45H) OR
        (0E81H <= ch) & (ch <= 0E82H) OR (ch = 0E84H) OR
        (0E87H <= ch) & (ch <= 0E88H) OR (ch = 0E8AH) OR (ch = 0E8DH) OR
        (0E94H <= ch) & (ch <= 0E97H) OR (0E99H <= ch) & (ch <= 0E9FH) OR
        (0EA1H <= ch) & (ch <= 0EA3H) OR (ch = 0EA5H) OR (ch = 0EA7H) OR
        (0EAAH <= ch) & (ch <= 0EABH) OR (0EADH <= ch) & (ch <= 0EAEH) OR
        (ch = 0EB0H) OR (0EB2H <= ch) & (ch <= 0EB3H) OR (ch = 0EBDH) OR
        (0EC0H <= ch) & (ch <= 0EC4H) OR (0F40H <= ch) & (ch <= 0F47H) OR
        (0F49H <= ch) & (ch <= 0F69H)
    ELSIF (ch < 1400H) THEN
      RETURN (10A0H <= ch) & (ch <= 10C5H) OR (10D0H <= ch) & (ch <= 10F6H) OR
        (ch = 1100H) OR (1102H <= ch) & (ch <= 1103H) OR
        (1105H <= ch) & (ch <= 1107H) OR (ch = 1109H) OR
        (110BH <= ch) & (ch <= 110CH) OR (110EH <= ch) & (ch <= 1112H) OR
        (ch = 113CH) OR (ch = 113EH) OR (ch = 1140H) OR (ch = 114CH) OR
        (ch = 114EH) OR (ch = 1150H) OR (1154H <= ch) & (ch <= 1155H) OR
        (ch = 1159H) OR (115FH <= ch) & (ch <= 1161H) OR
        (ch = 1163H) OR (ch = 1165H) OR (ch = 1167H) OR (ch = 1169H) OR
        (116DH <= ch) & (ch <= 116EH) OR (1172H <= ch) & (ch <= 1173H) OR
        (ch = 1175H) OR (ch = 119EH) OR (ch = 11A8H) OR (ch = 11ABH) OR
        (11AEH <= ch) & (ch <= 11AFH) OR (11B7H <= ch) & (ch <= 11B8H) OR
        (ch = 11BAH) OR (11BCH <= ch) & (ch <= 11C2H) OR
        (ch = 11EBH) OR (ch = 11F0H) OR (ch = 11F9H)
    ELSE
      RETURN (1E00H <= ch) & (ch <= 1E9BH) OR (1EA0H <= ch) & (ch <= 1EF9H) OR
        (1F00H <= ch) & (ch <= 1F15H) OR (1F18H <= ch) & (ch <= 1F1DH) OR
        (1F20H <= ch) & (ch <= 1F45H) OR (1F48H <= ch) & (ch <= 1F4DH) OR
        (1F50H <= ch) & (ch <= 1F57H) OR (ch = 1F59H) OR (ch = 1F5BH) OR
        (ch = 1F5DH) OR (1F5FH <= ch) & (ch <= 1F7DH) OR
        (1F80H <= ch) & (ch <= 1FB4H) OR (1FB6H <= ch) & (ch <= 1FBCH) OR
        (ch = 1FBEH) OR (1FC2H <= ch) & (ch <= 1FC4H) OR
        (1FC6H <= ch) & (ch <= 1FCCH) OR (1FD0H <= ch) & (ch <= 1FD3H) OR
        (1FD6H <= ch) & (ch <= 1FDBH) OR (1FE0H <= ch) & (ch <= 1FECH) OR
        (1FF2H <= ch) & (ch <= 1FF4H) OR (1FF6H <= ch) & (ch <= 1FFCH) OR
        (ch = 2126H) OR (212AH <= ch) & (ch <= 212BH) OR (ch = 212EH) OR
        (2180H <= ch) & (ch <= 2182H) OR (3041H <= ch) & (ch <= 3094H) OR
        (30A1H <= ch) & (ch <= 30FAH) OR (3105H <= ch) & (ch <= 312CH) OR
        (0AC00H <= ch) & (ch <= 0D7A3H)
    END
  END IsBaseChar;

PROCEDURE IsIdeographic (ch: Buffer.Char): BOOLEAN;
  BEGIN
    RETURN (4E00H <= ch) & (ch <= 9FA5H) OR
           (ch = 3007H) OR
           (3021H <= ch ) & (ch <= 3029H)
  END IsIdeographic;

PROCEDURE IsCombiningChar (ch: Buffer.Char): BOOLEAN;
  BEGIN
    IF (ch < 0300H) THEN
      RETURN FALSE
    ELSIF (ch < 0A00H) THEN
      RETURN (0300H <= ch) & (ch <= 0345H) OR (0360H <= ch) & (ch <= 0361H) OR
        (0483H <= ch) & (ch <= 0486H) OR (0591H <= ch) & (ch <= 05A1H) OR
        (05A3H <= ch) & (ch <= 05B9H) OR (05BBH <= ch) & (ch <= 05BDH) OR
        (ch = 05BFH) OR (05C1H <= ch) & (ch <= 05C2H) OR (ch = 05C4H) OR
        (064BH <= ch) & (ch <= 0652H) OR (ch = 0670H) OR
        (06D6H <= ch) & (ch <= 06DCH) OR (06DDH <= ch) & (ch <= 06DFH) OR
        (06E0H <= ch) & (ch <= 06E4H) OR (06E7H <= ch) & (ch <= 06E8H) OR
        (06EAH <= ch) & (ch <= 06EDH) OR (0901H <= ch) & (ch <= 0903H) OR
        (ch = 093CH) OR (093EH <= ch) & (ch <= 094CH) OR (ch = 094DH) OR
        (0951H <= ch) & (ch <= 0954H) OR (0962H <= ch) & (ch <= 0963H) OR
        (0981H <= ch) & (ch <= 0983H) OR (ch = 09BCH) OR (ch = 09BEH) OR
        (ch = 09BFH) OR (09C0H <= ch) & (ch <= 09C4H) OR
        (09C7H <= ch) & (ch <= 09C8H) OR (09CBH <= ch) & (ch <= 09CDH) OR
        (ch = 09D7H) OR (09E2H <= ch) & (ch <= 09E3H)
    ELSIF (ch < 0D00H) THEN
      RETURN (ch = 0A02H) OR (ch = 0A3CH) OR (ch = 0A3EH) OR (ch = 0A3FH) OR
        (0A40H <= ch) & (ch <= 0A42H) OR (0A47H <= ch) & (ch <= 0A48H) OR
        (0A4BH <= ch) & (ch <= 0A4DH) OR (0A70H <= ch) & (ch <= 0A71H) OR
        (0A81H <= ch) & (ch <= 0A83H) OR (ch = 0ABCH) OR
        (0ABEH <= ch) & (ch <= 0AC5H) OR (0AC7H <= ch) & (ch <= 0AC9H) OR
        (0ACBH <= ch) & (ch <= 0ACDH) OR (0B01H <= ch) & (ch <= 0B03H) OR
        (ch = 0B3CH) OR (0B3EH <= ch) & (ch <= 0B43H) OR
        (0B47H <= ch) & (ch <= 0B48H) OR (0B4BH <= ch) & (ch <= 0B4DH) OR
        (0B56H <= ch) & (ch <= 0B57H) OR (0B82H <= ch) & (ch <= 0B83H) OR
        (0BBEH <= ch) & (ch <= 0BC2H) OR (0BC6H <= ch) & (ch <= 0BC8H) OR
        (0BCAH <= ch) & (ch <= 0BCDH) OR (ch = 0BD7H) OR
        (0C01H <= ch) & (ch <= 0C03H) OR (0C3EH <= ch) & (ch <= 0C44H) OR
        (0C46H <= ch) & (ch <= 0C48H) OR (0C4AH <= ch) & (ch <= 0C4DH) OR
        (0C55H <= ch) & (ch <= 0C56H) OR (0C82H <= ch) & (ch <= 0C83H) OR
        (0CBEH <= ch) & (ch <= 0CC4H) OR (0CC6H <= ch) & (ch <= 0CC8H) OR
        (0CCAH <= ch) & (ch <= 0CCDH) OR (0CD5H <= ch) & (ch <= 0CD6H)
    ELSIF (ch < 1000H) THEN
      RETURN (0D02H <= ch) & (ch <= 0D03H) OR (0D3EH <= ch) & (ch <= 0D43H) OR
        (0D46H <= ch) & (ch <= 0D48H) OR (0D4AH <= ch) & (ch <= 0D4DH) OR
        (ch = 0D57H) OR (ch = 0E31H) OR (0E34H <= ch) & (ch <= 0E3AH) OR
        (0E47H <= ch) & (ch <= 0E4EH) OR (ch = 0EB1H) OR
        (0EB4H <= ch) & (ch <= 0EB9H) OR (0EBBH <= ch) & (ch <= 0EBCH) OR
        (0EC8H <= ch) & (ch <= 0ECDH) OR (0F18H <= ch) & (ch <= 0F19H) OR
        (ch = 0F35H) OR (ch = 0F37H) OR (ch = 0F39H) OR
        (ch = 0F3EH) OR (ch = 0F3FH) OR (0F71H <= ch) & (ch <= 0F84H) OR
        (0F86H <= ch) & (ch <= 0F8BH) OR (0F90H <= ch) & (ch <= 0F95H) OR
        (ch = 0F97H) OR (0F99H <= ch) & (ch <= 0FADH) OR
        (0FB1H <= ch) & (ch <= 0FB7H) OR (ch = 0FB9H)
    ELSIF (ch < 2000H) THEN
      RETURN FALSE
    ELSE
      RETURN (20D0H <= ch) & (ch <= 20DCH) OR (ch = 20E1H) OR
        (302AH <= ch) & (ch <= 302FH) OR (ch = 3099H) OR (ch = 309AH)
    END
  END IsCombiningChar;

PROCEDURE IsExtender (ch: Buffer.Char): BOOLEAN;
  BEGIN
    IF (ch = 00B7H) THEN
      RETURN TRUE
    ELSIF (ch >= 02D0H) THEN
      RETURN (ch = 02D0H) OR (ch = 02D1H) OR (ch = 0387H) OR (ch = 0640H) OR
        (ch = 0E46H) OR (ch = 0EC6H) OR (ch = 3005H) OR
        (3031H <= ch) & (ch <= 3035H) OR (309DH <= ch) & (ch <= 309EH) OR
        (30FCH <= ch) & (ch <= 30FEH)
    ELSE
      RETURN FALSE
    END
  END IsExtender;

PROCEDURE IsLetter (ch: Buffer.Char): BOOLEAN;
  BEGIN
    RETURN IsBaseChar (ch) OR IsIdeographic (ch)
  END IsLetter;

PROCEDURE IsNameChar* (ch: Buffer.Char): BOOLEAN;
  BEGIN
    RETURN IsLetter (ch) OR IsDigit (ch) OR
           (ch = 46) OR (ch = 45) OR (ch = 95) OR (ch = 58) OR
           IsCombiningChar (ch) OR IsExtender (ch)
  END IsNameChar;

PROCEDURE IsNameChar0* (ch: Buffer.Char): BOOLEAN;
  BEGIN
    RETURN IsLetter (ch) OR (ch = 95) OR (ch = 58)
  END IsNameChar0;

PROCEDURE UpperASCII (ch: Buffer.Char): Buffer.Char;
  BEGIN
    IF (ORD ("a") <= ch) & (ch <= ORD ("z")) THEN
      RETURN ch-32
    ELSE
      RETURN ch
    END
  END UpperASCII;

PROCEDURE DispatchChar (ch: Buffer.Char): LONGINT;
(* Keeps end markers next to ASCII labels within VOC's CASE range limit. *)
  BEGIN
    IF ch = Buffer.markerEOB THEN RETURN caseEOB
    ELSIF ch = Buffer.markerEOD THEN RETURN caseEOD
    ELSE RETURN ch
    END
  END DispatchChar;

PROCEDURE IsPubidChar (ch: Buffer.Char): BOOLEAN;
  VAR
    i: LONGINT;
  BEGIN
    IF (65 <= UpperASCII (ch)) & (UpperASCII (ch) <= 90) OR
       (48 <= ch) & (ch <= 57) OR
       (ch = 32) OR (ch = ORD (Ascii.cr)) OR (ch = ORD (Ascii.lf)) THEN
      RETURN TRUE
    ELSE
      i := 0;
      WHILE (suplPubidChar[i] # 0) & (suplPubidChar[i] # ch) DO
        INC (i)
      END;
      RETURN (suplPubidChar[i] # 0)
    END
  END IsPubidChar;

PROCEDURE IsVersionNumChar (ch: Buffer.Char): BOOLEAN;
  BEGIN
    RETURN (65 <= UpperASCII (ch)) & (UpperASCII (ch) <= 90) OR
           (48 <= ch) & (ch <= 57) OR
           (ch = 95) OR (ch = 46) OR (ch = 58) OR (ch = 45)
  END IsVersionNumChar;

PROCEDURE IsEncNameChar (ch: Buffer.Char; first: BOOLEAN): BOOLEAN;
  BEGIN
    IF (65 <= UpperASCII (ch)) & (UpperASCII (ch) <= 90) THEN
      RETURN TRUE
    ELSIF ~first THEN
      RETURN (48 <= ch) & (ch <= 57) OR
             (ch = 46) OR (ch = 95) OR (ch = 45)
    ELSE
      RETURN FALSE
    END
  END IsEncNameChar;


(* ------------------------------------------------------------------------ *)

PROCEDURE (el: ErrorListener) Error* (context: Error.Context; code: Error.Code;
                                      fatalError: BOOLEAN;
                                      pos: Locator.Position): Error.Msg;
  VAR
    err: Error.Msg;
    p: Parser;
  BEGIN
    p := el. p;
    IF (p. limits # NIL) & ~p. limits. Charge (Limits.work, 1) THEN
      p. builder := Builder.New(); RETURN p. limits. error
    END;
    err := Error.New (context, code);
    err. SetIntAttrib ("char", pos. charIndex+Error.errMsgCharPosBase);
    err. SetIntAttrib ("line", pos. line+Error.errMsgLineBase);
    err. SetIntAttrib ("column", pos. column+Error.errMsgColumnBase);
    err. SetAttribute (URI.NewURIAttribute ("baseURI", p. fileEntity. baseURI));
    IF (pos. inInternalEntity # NIL) THEN
      err. SetLStringAttrib ("entity_name", 
                            Msg.GetLStringPtr (pos. inInternalEntity. name^))
    END;
    p. errList. Append (err);
    IF fatalError & (p. builder = p. initialBuilder) THEN
      p. builder := Builder.New()
    END;
    RETURN err
  END Error;


PROCEDURE (p: Parser) ParseDocument*;
(**Parses the document, issuing callbacks to @otype{Builder.Builder} as
   it goes along.  After completion, any errors are reported in
   @ofield{p.errList}.  *)
  VAR
    dtd: DTD.Builder;
    cpos: Buffer.CharPos;
    cstart: Buffer.CharPos;
    cdelta: Buffer.CharPos;
    chars: Buffer.CharArray;
  
  CONST
    followedByAny = 0;
    followedByNonName = 1;
  
  (*
  Character Information            Value
  ------------------------------   -----------------------------
  current file position            in. offsetFromPos0+cpos
  current line                     p. l. currLine
  current column                   cpos-p. l. currLinePos+p. l. currLineTab
  file position of current line    p. l. currLinePos
  column delta because of tabs     p. l. currLineTab
  marked file position             cstart
  
  All numbering (file position, line, column) starts at zero.
  
  
  Handling of control characters is slightly tricky.  There are three end of
  line variants (LF, CR, CR+LF) to handle, and the end of a line requires
  adjustment of @ofield{p.currLine}, @ofield{p.currLinePos}, and
  @ofield{p.currLineTab}.  A tab character means adjustment of
  @ovar{p.currLineTab}.  All other control characters are invalid and must
  be reported as such.  The special character
  @oconst{Buffer.markedEOB} means that the end of the current buffer has been
  reached and new characters must be retrieved from file.  The other special,
  @oconst{Buffer.markedEOD}, means that the end of the document has been 
  reached.
  
  
  The prodedures that produce content (character data, attribute value, or
  entity value) produce normalized values of the character data in the
  input buffer itself.  With @ovar{cpos} denoting the current reading
  position, the character interval
  @samp{[@ovar{cstart}, @ovar{cpos}-@ovar{cdelta}[} holds the normalized
  value.  The value of @ovar{cdelta} is increased each time the normalized
  value of a character sequence is shorter than the sequence itself.  Examples
  for this are CR+LF end of line marker, or character references.
  *)
  
  PROCEDURE DecLength (VAR pos: Locator.Position; len: DTD.CharPos);
    BEGIN
      DEC (pos. charIndex, len);
      DEC (pos. column, len)
    END DecLength;
  
  PROCEDURE StorePosition (VAR pos: Locator.Position);
    VAR
      i: LONGINT;
    BEGIN
      IF (p. in # NIL) & (chars = p. in. chars) THEN
        pos. charIndex := cpos+p. in. offsetFromPos0;
        pos. line := p. currLine;
        pos. column := cpos-p. currLinePos+p. currLineTab
      ELSE
        (* go down the stack of pushed entities, until the external entity
           is found that represents the most recently opened file *)
        IF (p. in = NIL) THEN
          i := 0
        ELSE
          i := p. lenPEStack-1;
          WHILE (p. peStack[i]. oldChars # p. in. chars) DO
            DEC (i)
          END
        END;
        pos. charIndex := p. peStack[i]. oldCPos+p. peStack[i]. in. offsetFromPos0;
        pos. line := p. currLine;
        pos. column := p. peStack[i]. oldCPos - 
                       p. currLinePos+p. currLineTab;
        IF (p. peStack[i]. entity. name # NIL) THEN
          DecLength (pos, LongStrings.Length (p. peStack[i]. entity. name^)+2)
        END
      END
    END StorePosition;
  
  PROCEDURE ResetLocator;
    BEGIN
      p. currLine := 0;
      p. currLinePos := 0;
      p. currLineTab := 0;
      cpos := 0;
      cdelta := 0;
      cstart := 0
    END ResetLocator;
  
  PROCEDURE SetFileEntity (new: DTD.ExternalEntity);
    BEGIN
      p. fileEntity := new;
      p. l. entity := new;
    END SetFileEntity;
  
  
  PROCEDURE ^Stop;

  PROCEDURE ErrPosNF (code: Error.Code; VAR pos: Locator.Position);
    VAR
      i: LONGINT;
    BEGIN
      IF p. aborted THEN RETURN END;
      IF (p. limits # NIL) & ~p. limits. Charge (Limits.work, 1) THEN
        Stop; RETURN
      END;
      p. lastError := Error.New (parserContext, code);
      p. lastError. SetIntAttrib ("char", pos. charIndex+Error.errMsgCharPosBase);
      p. lastError. SetIntAttrib ("line", pos. line+Error.errMsgLineBase);
      p. lastError. SetIntAttrib ("column", pos. column+Error.errMsgColumnBase);
      p. lastError. SetAttribute (URI.NewURIAttribute ("baseURI", p. fileEntity. baseURI));
      IF (chars # p. in. chars) THEN
        i := p. lenPEStack-1;
        p. lastError. SetLStringAttrib ("entity_name", 
                              Msg.GetLStringPtr (p. peStack[i]. entity. name^))
      END;
      p. errList. Append (p. lastError)
    END ErrPosNF;
  
  PROCEDURE ErrPos (code: Error.Code; VAR pos: Locator.Position);
    BEGIN
      ErrPosNF (code, pos);
      IF (p. builder = p. initialBuilder) THEN
        p. builder := Builder.New()
      END
    END ErrPos;
  
  PROCEDURE WriteBuffer (msg: ARRAY OF CHAR);
    VAR
      i, end: LONGINT;
    BEGIN
      end := cpos+80;
      i := cpos;
      Out.Ln; Out.String ("### buffer contents "); 
      Out.String (msg); Out.String (" ###"); Out.Ln;
      WHILE (chars[i] < Buffer.markerEOB) & (i <= end) DO
        IF (chars[i] > 0FFH) THEN
          Out.Char("?")
        ELSE
          Out.Char(CHR (chars[i]))
        END;
        INC (i)
      END;
      Out.Ln;
    END WriteBuffer;
  
  PROCEDURE ErrNF (code: Error.Code);
    BEGIN  (* non-fatal error *)
      (*WriteBuffer ("ERROR");*)
      StorePosition (p. errorPos);
      ErrPosNF (code, p. errorPos)
    END ErrNF;
  
  PROCEDURE Err (code: Error.Code);
    BEGIN
      ErrNF (code);
      IF (p. builder = p. initialBuilder) THEN
        p. builder := Builder.New()
      END
    END Err;

  PROCEDURE Stop;
  (* Propagate a resource failure through normal grammar returns. Entity pops
     restore this end marker in the parent input, so parsing cannot resume. *)
    VAR msg: Msg.Msg;
    BEGIN
      IF ~p. aborted THEN
        p. aborted := TRUE;
        p. lastError := p. limits. error;
        p. builder := Builder.New();
        msg := p. errList. msgList;
        WHILE (msg # NIL) & (msg # p. limits. error) DO msg := msg. nextMsg END;
        IF msg = NIL THEN p. errList. Append (p. limits. error) END
      END;
      IF (0 <= cpos) & (cpos < LEN (chars^)) THEN chars[cpos] := Buffer.markerEOD END
    END Stop;

  PROCEDURE Charge (kind: SHORTINT; n: LONGINT): BOOLEAN;
    BEGIN
      IF p. aborted THEN RETURN FALSE END;
      IF (p. limits = NIL) OR p. limits. Charge (kind, n) THEN RETURN TRUE END;
      Stop; RETURN FALSE
    END Charge;

  PROCEDURE Enter (): BOOLEAN;
    BEGIN
      IF p. aborted THEN RETURN FALSE END;
      IF (p. limits = NIL) OR p. limits. Enter() THEN RETURN TRUE END;
      Stop; RETURN FALSE
    END Enter;

  PROCEDURE Leave;
    BEGIN IF p. limits # NIL THEN p. limits. Leave END END Leave;

  PROCEDURE AppendCharacters (value: DTD.AttValue; source: DTD.String;
                             start, end: DTD.CharPos; copy: BOOLEAN);
    BEGIN
      IF ~Charge (Limits.work, 1) THEN RETURN END;
      value. Append (dtd. NewCharacters (source, start, end, copy))
    END AppendCharacters;

  PROCEDURE CheckValue (value: DTD.AttValue): BOOLEAN;
    VAR length: LONGINT;

    PROCEDURE Visit (value: DTD.AttValue): BOOLEAN;
      VAR fragment: DTD.Fragment; n, maximum: LONGINT; ok: BOOLEAN;
      BEGIN
        IF ~Enter() THEN RETURN FALSE END;
        ok := TRUE; fragment := value. fragmentList;
        WHILE (fragment # NIL) & ok DO
          ok := Charge (Limits.work, 1);
          IF ok THEN
            WITH fragment: DTD.Characters DO
              n := fragment. sourceEnd-fragment. sourceStart
            | fragment: DTD.EntityRef DO
              IF (fragment. entity # NIL) & (fragment. entity. attValue # NIL) THEN
                ok := Visit (fragment. entity. attValue); n := 0
              ELSE n := LongStrings.Length (fragment. name^)+2
              END
            END;
            maximum := p. limits. maxAttributeUnits;
            IF maximum < 0 THEN maximum := MAX (LONGINT)-2 END;
            IF (n > MAX (LONGINT)-2-length) OR (length > maximum) OR (n > maximum-length) THEN
              p. limits. Fail (Limits.attributeUnits); Stop; ok := FALSE
            ELSIF ok THEN
              INC (length, n); ok := Charge (Limits.expandedUnits, n)
            END
          END;
          fragment := fragment. next
        END;
        Leave; RETURN ok
      END Visit;

    BEGIN
      IF p. limits = NIL THEN RETURN TRUE END;
      length := 0; RETURN Visit (value)
    END CheckValue;
  
  (* ---------------------------------------------------------------------- *)
  
  PROCEDURE Clone (string: DTD.String): DTD.String;
    VAR
      clone: DTD.String;
      i: LONGINT;
    BEGIN
      NEW (clone, LEN (string^));
      FOR i := 0 TO LEN (string^)-1 DO
        clone[i] := string[i]
      END;
      RETURN clone
    END Clone;
  
  PROCEDURE GetString (start, end: DTD.CharPos): DTD.String;
    VAR
      string: DTD.String;
      i: DTD.CharPos;
    BEGIN
      IF ~Charge (Limits.work, 1) THEN RETURN noName END;
      NEW (string, end-start+1);
      i := 0;
      WHILE (start # end) DO
        string[i] := chars[start];
        INC (start); INC (i)
      END;
      string[i] := 0;
      RETURN string
    END GetString;
  
  PROCEDURE GetBuffer (entity: DTD.ExternalEntity): Buffer.Input;
    VAR
      res: Msg.Msg;
      ch: Channel.Channel;
      in: Buffer.Input;
      str: ARRAY 2*1024 OF CHAR;
    BEGIN
      IF p. aborted THEN RETURN NIL
      ELSIF ~p. followExternalRef THEN
        Err (externalAccessDisabled);
        RETURN NIL
      ELSIF (entity. baseURI = NIL) THEN
        RETURN NIL
      ELSE
        ch := entity. baseURI. GetChannel (URI.channelOld, res);
        IF (ch = NIL) THEN
          Err (accessError);
          entity. baseURI. GetString (str);
          p. lastError. SetStringAttrib ("uri", Msg.GetStringPtr (str));
          p. lastError. SetMsgAttrib ("channel_error", res);
          RETURN NIL
        ELSE
          in := Buffer.NewInput (Limits.Wrap (ch. NewReader(), p. limits), NIL, p. errList);
          entity. SetCodecFactory (in. codecFactory);
          RETURN in
        END
      END
    END GetBuffer;
  
  PROCEDURE CheckInvalidChars (input: Buffer.Input; entity: DTD.ExternalEntity);
    VAR
      str: ARRAY 2*1024 OF CHAR;
    BEGIN
      IF (input # NIL) & (input. codec. invalidChars # 0) THEN
        Err (invalidCharacterEncodings);
        IF entity. baseURI # NIL THEN
          entity. baseURI. GetString (str)
        ELSE
          str := "<input>"
        END;
        p. lastError. SetStringAttrib ("uri", Msg.GetStringPtr (str));
        p. lastError. SetIntAttrib ("encodings", input. codec. invalidChars)
      END
    END CheckInvalidChars;
  
  PROCEDURE Internalize (entity: DTD.ExternalEntity): DTD.String;
    VAR
      in: Buffer.Input;
      len, i, delta: Buffer.CharPos;
      str: DTD.String;
    BEGIN
      in := GetBuffer (entity);
      IF (in # NIL) THEN
        WHILE in. NextBlock() DO END;
        IF (p. limits # NIL) & (p. limits. error # NIL) THEN Stop END;
        IF ~Charge (Limits.expandedUnits, in. endOfBuffer) THEN
          in. Close; NEW (str, 2); str[0] := Buffer.markerEOD; RETURN str
        END;

        (* do eol replacement magic *)
        len := in. endOfBuffer;
        i := 0; delta := 0;
        WHILE (i # len) DO
          CASE in. chars[i] OF
          | ORD (Ascii.cr):
            in. chars[i-delta] := ORD (Ascii.lf);
            IF (in. chars[i+1] = ORD (Ascii.lf)) THEN
              INC (i); INC (delta)
            END
          ELSE
            in. chars[i-delta] := in. chars[i]
          END;
          INC (i)
        END;
        DEC (len, delta);

        NEW (str, len+2);
        FOR i := 0 TO len-1 DO
          str[i] := in. chars[i]
        END;
        CheckInvalidChars (in, entity);
        in. Close
      ELSE
        NEW (str, 2);
        len := 0
      END;
      CASE entity. type OF
      | DTD.entityExternalGeneral:
        str[len] := Buffer.markerEOD
      | DTD.entityExternalParameter:
        str[len] := Buffer.markerEOB
      END;
      RETURN str
    END Internalize;
  
  PROCEDURE PushEntity (entity: DTD.Entity; syncEntity: BOOLEAN): BOOLEAN;
  (* `syncEntity=TRUE' means that the resolved entity is matched against
     a grammar production (extParsedPE, externalSubset) and is not
     inserted at an arbitrary place in the external subset or an entity
     value *)
    VAR
      newList: PEInfoList;
      i: LONGINT;
    BEGIN
      IF ~Charge (Limits.entityExpansions, 1) THEN RETURN FALSE END;
      IF ~Enter() THEN RETURN FALSE END;
      IF (entity # NIL) THEN
        entity. expanding := TRUE
      END;
      
      IF (p. lenPEStack = LEN (p. peStack^)) THEN
        NEW (newList, LEN (p. peStack^)+incrPEStack);
        FOR i := 0 TO LEN (p. peStack^)-1 DO
          newList[i] := p. peStack[i]
        END;
        p. peStack := newList
      END;
      p. peStack[p. lenPEStack]. entity := entity;
      p. peStack[p. lenPEStack]. oldChars := chars;
      p. peStack[p. lenPEStack]. oldCPos := cpos;
      p. peStack[p. lenPEStack]. oldCurrLine := p. currLine;
      p. peStack[p. lenPEStack]. oldCurrLinePos := p. currLinePos;
      p. peStack[p. lenPEStack]. oldCurrLineTab := p. currLineTab;
      p. peStack[p. lenPEStack]. in := p. in;
      INC (p. lenPEStack);
      
      IF syncEntity & (entity IS DTD.ExternalEntity) THEN
        (* external entity read from file *)
        p. in := GetBuffer (entity(DTD.ExternalEntity));
        SetFileEntity (entity(DTD.ExternalEntity));
        ResetLocator;
        IF (p. in = NIL) THEN            (* read error: simulate empty file *)
          NEW (chars, 2);
          chars[0] := Buffer.markerEOD
        ELSE
          chars := p. in. chars
        END
      ELSE
        (* internal entity or internalized external entity that is inserted
           somewhere "in between"; continue parsing in a _copy_ of the entity
           value, because the value may be modified during parsing *)
        IF (entity IS DTD.ExternalEntity) & (entity. entityValue = NIL) THEN
          entity. SetEntityValue (Internalize (entity(DTD.ExternalEntity)))
        END;
        IF Charge (Limits.expandedUnits, LEN (entity. entityValue^)-2) THEN
          chars := Clone (entity. entityValue)
        ELSE
          NEW (chars, 2); chars[0] := Buffer.markerEOD
        END;
        
        CASE entity. type OF
        | DTD.entityInternalGeneral, DTD.entityExternalGeneral:
          chars[LEN (chars^)-2] := Buffer.markerEOD
        | DTD.entityInternalParameter, DTD.entityExternalParameter:
          chars[LEN (chars^)-2] := Buffer.markerEOB;
          
          (* add a space to the end of the interal entity (or internalized
             external entity), unless we are within
             an entity value declaration; this ensures the replacement ends in
             a whitespace character, and at the same tim `LookingAt' will not
             fall out of an expanded entity reference *)
          IF (p. currEntityValue = NIL) THEN
            chars[LEN (chars^)-2] := 32;
            IF syncEntity THEN
              chars[LEN (chars^)-1] := Buffer.markerEOD
            ELSE
              chars[LEN (chars^)-1] := Buffer.markerEOB
            END
          END
        END;
        
        IF (entity. type = DTD.entityInternalGeneral) OR
           (entity. type = DTD.entityInternalParameter) THEN
          p. l. inInternalEntity := entity(DTD.InternalEntity)
        END
      END;
      cpos := 0; cdelta := 0; cstart := 0;
      IF (p. limits # NIL) & (p. limits. error # NIL) THEN Stop END;
      RETURN TRUE
    END PushEntity;
  
  PROCEDURE PopEntity;
    VAR
      i: LONGINT;
    BEGIN
      IF (p. currEntityValue # NIL) THEN
        (* we are parsing the entity value of an entity declaration: append
           text fragment to the value's fragment list *)
        AppendCharacters (p. currEntityValue, chars, cstart, cpos-cdelta, TRUE)
      END;
      
      DEC (p. lenPEStack);
      IF (p. in # NIL) & (p. in # p. peStack[p. lenPEStack]. in) THEN
        CheckInvalidChars (p. in, p. fileEntity);
        p. in. Close                     (* close external entity buffer *)
      END;
      chars := p. peStack[p. lenPEStack]. oldChars;
      cpos := p. peStack[p. lenPEStack]. oldCPos;
      p. currLine := p. peStack[p. lenPEStack]. oldCurrLine;
      p. currLinePos := p. peStack[p. lenPEStack]. oldCurrLinePos;
      p. currLineTab := p. peStack[p. lenPEStack]. oldCurrLineTab;
      i := p. lenPEStack-1;
      WHILE (i >= 0) & ~(p. peStack[i]. entity IS DTD.ExternalEntity) DO
        DEC (i)
      END;
      IF (i >= 0) THEN
        SetFileEntity (p. peStack[i]. entity(DTD.ExternalEntity))
      ELSE
        SetFileEntity (p. documentEntity)
      END;
      
      IF (i # p. lenPEStack-1) THEN
        (* parsing continues in replacement text of internal entity *)
        p. l. inInternalEntity := p. peStack[p. lenPEStack-1]. entity(DTD.InternalEntity)
      ELSE  (* parsing continues on file level *)
        p. l. inInternalEntity := NIL
      END;
      
      p. in := p. peStack[p. lenPEStack]. in;
      cstart := cpos; cdelta := 0;
      
      IF (p. peStack[p. lenPEStack]. entity # NIL) THEN
        p. peStack[p. lenPEStack]. entity. expanding := FALSE
      END;
      Leave;
      IF p. aborted THEN Stop END
    END PopEntity;
  
  PROCEDURE NextBlock;
    VAR
      oldOffset: Buffer.CharPos;
      res: BOOLEAN;
    BEGIN
      IF p. aborted THEN Stop; RETURN END;
      ASSERT (chars[cpos] = Buffer.markerEOB);
      IF (p. lenPEStack # 0) & (p. in. chars # chars) THEN
        (* fix up end of entity by removing the space that was added there
           by PushEntity *)
        IF (p. currEntityValue = NIL) THEN
          ASSERT (chars[LEN (chars^)-2] = 32);
          chars[LEN (chars^)-2] := Buffer.markerEOB;
        END;
        
        (* we reached the end of an internal parameter entity expansion;
           remove the top-level stack element, restore the old context, and
           continue parsing *)
        PopEntity
      ELSE
        oldOffset := p. in. offsetFromPos0;
        res := p. in. NextBlock();
        chars := p. in. chars;
        DEC (cpos, p. in. offsetFromPos0-oldOffset);
        DEC (cstart, p. in. offsetFromPos0-oldOffset);
        DEC (p. currLinePos, p. in. offsetFromPos0-oldOffset);
        IF (p. limits # NIL) & (p. limits. error # NIL) THEN Stop END
      END
    END NextBlock;
  
  PROCEDURE DiscardPreviousInput;
    BEGIN
      IF (p. in. chars = chars) THEN
        p. in. discardable := cpos;
        cstart := cpos
      END
    END DiscardPreviousInput;
  
  PROCEDURE EndOfLine;
  (* Must be called @emph{after} skipping over an end of line marker (LF, CR,
     or CR+LF).  *)
    BEGIN
      IF (chars = p. in. chars) THEN
        INC (p. currLine);
        p. currLinePos := cpos;
        p. currLineTab := 0
      END
    END EndOfLine;
  
  PROCEDURE Tab;
  (* Must be called @emph{before} skipping over a tab charatcer (Ascii.ht).  *)
    VAR
      currColumn: Buffer.CharPos;
    BEGIN
      IF (chars = p. in. chars) THEN
        currColumn := cpos-p. currLinePos+p. currLineTab;
        INC (p. currLineTab, tabWidth-currColumn MOD tabWidth-1)
      END
    END Tab;
  
  PROCEDURE LookingAtS(): BOOLEAN;
  (* pre: chars[cpos] is valid *)
    BEGIN
      IF (chars[cpos] <= 32) THEN
        RETURN TRUE
      ELSIF (p. inExternalSubset OR p. inExternalEntity) &
            (chars[cpos] = 37) THEN
       IF (chars[cpos+1] = Buffer.markerEOB) THEN
         IF (chars = p. in. chars) THEN
           (* we aren't within an internal entity value *)
           INC (cpos);
           NextBlock;
           DEC (cpos);
           RETURN IsNameChar (chars[cpos+1])
         ELSE
           RETURN FALSE
         END
       ELSE
         RETURN IsNameChar (chars[cpos+1])
       END
      ELSE
        RETURN FALSE
      END
    END LookingAtS;
  
  PROCEDURE LookingAtSnoPE(): BOOLEAN;
  (* pre: chars[cpos] is valid *)
    BEGIN
      RETURN (chars[cpos] <= 32)
    END LookingAtSnoPE;
  
  (* ---------------------------------------------------------------------- *)
  
  (* NOTE: All procedures that consume characters from the input stream
     must ensure that @samp{chars[cpos] # Buffer.markerEOB} after completion.
     That is, the current lookahead character @samp{chars[cpos]} must be
     valid if such a procedure is done.  Conversely, all procedure can 
     depend on @samp{chars[cpos]} when activated.  *)
  
  PROCEDURE LookingAt (str: ARRAY OF CHAR; followedBy: SHORTINT): BOOLEAN;
  (* pre: `str' does not contain any whitespace characters
     post: ~result & (chars[cpos] # Buffer.markerEOB) OR
           result & (chars[cpos..cpos+Length(str)] # Buffer.markerEOB)
           the pointer `chars' has not changed *)
    VAR
      i: Buffer.CharPos;
    BEGIN
      IF p. aborted THEN RETURN FALSE END;
      i := 0;
      LOOP
        IF (chars[cpos] = Buffer.markerEOB) THEN
          IF (chars = p. in. chars) THEN
            NextBlock;
            IF p. aborted THEN DEC (cpos, i); Stop; RETURN FALSE END
          ELSE
            (* we are in an internal entity reference; EOB marks the end of
               the reference *)
            DEC (cpos, i);
            RETURN (str[i] = 0X)
          END
        ELSIF (str[i] = 0X) THEN
          DEC (cpos, i);
          CASE followedBy OF
          | followedByNonName:
            RETURN ~IsNameChar (chars[cpos+i])
          | followedByAny:
            RETURN TRUE
          END
        ELSIF (ORD (str[i]) = chars[cpos]) THEN
          INC (i); INC (cpos)
        ELSE
          DEC (cpos, i);
          RETURN FALSE
        END
      END
    END LookingAt;
  
  PROCEDURE NextChar;
    BEGIN
      IF ~p. aborted & (chars[cpos] # Buffer.markerEOD) THEN
        INC (cpos);
        IF (chars[cpos] = Buffer.markerEOB) THEN
          NextBlock
        END
      END
    END NextChar;
  
  PROCEDURE Nmtoken (checkForQName, noColon: BOOLEAN): DTD.String;
  (* pre: chars[cpos] # Buffer.markerEOB *)
    VAR
      string: DTD.String;
      colon: DTD.CharPos;
    BEGIN
      IF p. aborted THEN RETURN noName END;
      IF IsNameChar (chars[cpos]) THEN
        cstart := cpos;
        IF (chars[cpos] = 58) THEN
          (* colon at beginning of name *)
          colon := cpos;
          IF checkForQName THEN
            IF noColon THEN              (* no colon allowed in NCName *)
              Err (invalidNCName)
            ELSE
              Err (invalidQName)
            END
          END
        ELSE
          colon := -1
        END;
        INC (cpos);
        LOOP
          IF p. aborted THEN Stop; RETURN noName END;
          IF (chars[cpos] = Buffer.markerEOB) THEN
            IF (chars # p. in. chars) THEN (* in internal entity value *)
              string := GetString (cstart, cpos);
              NextBlock;
              EXIT
            ELSE
              NextBlock
            END
          ELSIF (chars[cpos] = 58) & checkForQName THEN
            IF noColon THEN              (* no colon allowed in NCName *)
              Err (invalidNCName)
            ELSIF (colon >= 0) THEN      (* multiple colons *)
              Err (invalidQName)
            END;
            colon := cpos;
            INC (cpos)
          ELSIF IsNameChar (chars[cpos]) THEN
            INC (cpos)
          ELSE
            string := GetString (cstart, cpos);
            EXIT
          END
        END;
        IF checkForQName & (string[LEN (string^)-2] = 58) THEN
          (* colon is last character in name *)
          Err (invalidQName)
        END;
        RETURN string
      ELSE
        Err (expectedNmtoken);
        NextChar;
        RETURN noName
      END
    END Nmtoken;
  
  PROCEDURE Name (noColon: BOOLEAN): DTD.String;
  (* pre: chars[cpos] # Buffer.markerEOB *)
    BEGIN
      IF IsNameChar0 (chars[cpos]) THEN
        RETURN Nmtoken (p. enforceQNames, noColon)
      ELSE
        Err (expectedName);
        NextChar;
        RETURN noName
      END
    END Name;
  
  PROCEDURE CheckChar (ch: DTD.Char);
  (* Compare the current character with @oparam{ch}, and report an error if
     they don't match.  *)
    VAR
      str: ARRAY 2 OF CHAR;
    BEGIN
      IF p. aborted THEN RETURN END;
      IF (chars[cpos] # ch) THEN
        Err (expectedChar);
        str := "X";
        str[0] := CHR (ch);
        p. lastError. SetStringAttrib ("symbol", Msg.GetStringPtr (str))
      END;
      IF (chars[cpos] # Buffer.markerEOD) THEN
        INC (cpos);
        IF (chars[cpos] = Buffer.markerEOB) THEN
          NextBlock
        END
      END
    END CheckChar;
  
  PROCEDURE ^ XMLDecl (entity: DTD.ExternalEntity);
  PROCEDURE ^ extSubsetDecl;
  
  PROCEDURE SkippedEntity (name: DTD.String);
  (* if name=NIL, then the external subset of the DTD is skipped *)
    BEGIN
      p. readCompleteDTD := FALSE;
      IF (p. documentEntity. standalone # DTD.standaloneYes) THEN
        p. processDeclarations := FALSE
      END
    END SkippedEntity;
  
  PROCEDURE PEReference (declSep: BOOLEAN);
    VAR
      name: DTD.String;
      decl: DTD.Declaration;
      entity: DTD.Entity;
      oldCStart: DTD.CharPos;
      oldFlag, inInternalSubset: BOOLEAN;
    BEGIN  (* pre: (chars[cpos] = "%") *)
      IF ~declSep & 
         (~p. inExternalSubset & ~p. inExternalEntity) THEN
        Err (nonMarkupDeclPERef)
      END;
      CheckChar (37);
      oldCStart := cstart+p. in. offsetFromPos0;
      name := Name (TRUE);
      cstart := oldCStart-p. in. offsetFromPos0;
      CheckChar (59);
      decl := dtd. peNamespace. Get (name);
      IF ~Charge (Limits.work, 0) THEN RETURN END;
      IF (decl = NIL) THEN  (* FIXME... the WFC/VC rules are quite hairy *)
        IF p. validating OR
           (p. processDeclarations & p. followExternalRef) THEN
          Err (noSuchParameterEntity);
          p. lastError. SetLStringAttrib ("name", Msg.GetLStringPtr (name^))
        ELSE
          SkippedEntity (name)
        END
      ELSE
        entity := decl(DTD.Entity);
        IF entity. expanding THEN
          Err (recursiveParameterEntity);
          p. lastError. SetLStringAttrib ("name", Msg.GetLStringPtr (name^));
          RETURN
        END;
        IF declSep THEN
          (* this parameter reference is part of the rule DeclSep: if possible,
             parse the replacement text as a sequence of declarations *)
          IF p. followExternalRef OR
             (entity. type = DTD.entityInternalParameter) THEN
            inInternalSubset := ~(p. inExternalSubset OR p. inExternalEntity);
            IF ~PushEntity (entity, inInternalSubset) THEN RETURN END;
            
            (* an external entity should being with a TextDecl *)
            oldFlag := p. inExternalEntity;
            IF (entity. type = DTD.entityExternalParameter) THEN
              p. inExternalEntity := TRUE;
              IF LookingAt ("<?xml", followedByNonName) THEN
                XMLDecl (entity(DTD.ExternalEntity))
              END
            END;
            
            extSubsetDecl;
            IF (chars[cpos] # Buffer.markerEOD) THEN
              Err (junkAfterExtSubset)
            END;
            
            IF (entity. type = DTD.entityExternalParameter) THEN
              p. inExternalEntity := oldFlag
            END;
            
            IF inInternalSubset THEN
              PopEntity
            END
          ELSE
            SkippedEntity (name)
          END
        ELSE
          (* not in DeclSep: must be within entity value definition *)
          IF (entity IS DTD.ExternalEntity) THEN
            (* PushEntity reserves expansion and nesting before opening input. *)
            entity. SetEntityValue (NIL)
          END;
          IF ~PushEntity (entity, FALSE) THEN RETURN END
        END
      END
    END PEReference;
  
  PROCEDURE OptS (noPE: BOOLEAN);
  (* Matches the syntax rule "S?".  This procedure is used only @emph{outside}
     the document element, and never as part of an entity or attribute value.
     This means that the characters skipped by this rule are never reported
     to the application.
     
     To prevent expansion of parameter entity references, `noPE' can be
     set to TRUE.  *)
    BEGIN
      LOOP
        IF p. aborted THEN Stop; EXIT END;
        CASE DispatchChar (chars[cpos]) OF
        | caseEOB:
          NextBlock
        | 32:
          INC (cpos)
        | ORD (Ascii.lf):
          INC (cpos); EndOfLine
        | ORD (Ascii.cr):
          INC (cpos);
          IF (chars[cpos] = Buffer.markerEOB) THEN
            NextBlock
          END;
          IF (chars[cpos] = ORD (Ascii.lf)) THEN
            INC (cpos)
          END;
          EndOfLine
        | ORD (Ascii.ht):
          Tab; INC (cpos)
        | 37:
          IF ~noPE THEN
            PEReference (FALSE)
          ELSE
            EXIT
          END
        ELSE
          IF (chars[cpos] < 32) THEN
            Err (invalidChar);
            INC (cpos)
          ELSE
            EXIT
          END
        END
      END
    END OptS;
  
  PROCEDURE S;
    BEGIN
      IF LookingAtS() THEN
        OptS (FALSE)
      ELSE
        Err (expectedWhitespace)
      END
    END S;

  PROCEDURE SnoPE;
    BEGIN
      IF LookingAtSnoPE() THEN
        OptS (TRUE)
      ELSE
        Err (expectedWhitespace)
      END
    END SnoPE;

  PROCEDURE ControlChar (eolReplacement: DTD.Char);
  (* @precond
     @itemize
     @item
     @samp{(chars[cpos] < " ") OR (chars[cpos] = Buffer.markerEOB)}
     
     @item
     The variables @ovar{cstart} and @ovar{coffset} have been initialized.
     
     @item
     @oparam{eolReplacement} is either space (ASCII 20X), denoting attribute
     value normalization, or newline (ASCII 0AX), denoting normal end of
     line processing.
     @end itemize
     @end precond  *)
    VAR
      cend: DTD.CharPos;
    BEGIN
      ASSERT ((chars[cpos] < 32) OR (chars[cpos] = Buffer.markerEOB));
      cend := cpos-cdelta;
      CASE DispatchChar (chars[cpos]) OF
      | caseEOB:
        NextBlock
      | 32:
        chars[cend] := 32; INC (cpos)
      | ORD (Ascii.lf):
        IF (chars = p. in. chars) THEN
          chars[cend] := eolReplacement; INC (cpos); EndOfLine
        ELSE
          (* no EOL handling in replacement text of internal entities;
             see E86 for more information *)
          chars[cend] := chars[cpos]; INC (cpos)
        END
      | ORD (Ascii.cr):
        IF (chars = p. in. chars) THEN
          chars[cend] := eolReplacement;
          INC (cpos);
          IF (chars[cpos] = Buffer.markerEOB) THEN
            NextBlock
          END;
          IF (chars[cpos] = ORD (Ascii.lf)) THEN
            INC (cpos); INC (cdelta)
          END;
          EndOfLine
        ELSE
          (* no EOL handling in replacement text of internal entities;
             see E86 for more information *)
          chars[cend] := chars[cpos]; INC (cpos)
        END
      | ORD (Ascii.ht):
        IF (eolReplacement = 32) THEN
          chars[cend] := 32
        ELSE
          chars[cend] := ORD (Ascii.ht)
        END;
        Tab; INC (cpos)
      ELSE
        chars[cend] := Buffer.markerError;
        Err (invalidChar);
        IF ~p. aborted THEN INC (cpos) END
      END
    END ControlChar;
  
  
  PROCEDURE String (type: SHORTINT): DTD.String;
    VAR
      pos: Locator.Position;
      endChar: DTD.Char;
      string: DTD.String;
    
    PROCEDURE NormalizeWhitespace;
    (* For a PubidLiteral, normalize whitespace by collapsing sequences of
       whitespace into a single space character, and by remobing leading and
       trailing whitespace.  *)
      VAR
        i, delta: LONGINT;
      BEGIN
        (* strip leading whitespace *)
        WHILE (cstart # cpos-cdelta) & (chars[cstart] <= 32) DO
          INC (cstart)
        END;
        i := cstart; delta := 0;
        WHILE (i # cpos-cdelta) DO
          IF (chars[i] <= 32) THEN
            (* fold sequence of whitespace into single space *)
            chars[i-delta] := 32;
            WHILE (i+1 # cpos-cdelta) & (chars[i+1] <= 32) DO
              INC (i); INC (delta)
            END
          ELSE
            chars[i-delta] := chars[i]
          END;
          INC (i)
        END;
        (* strip space character from end of string (can only be one) *)
        INC (cdelta, delta);
        IF (cpos-cdelta # cstart) & (chars[cpos-cdelta-1] = 32) THEN
          INC (cdelta)
        END
      END NormalizeWhitespace;
    
    BEGIN
      IF (chars[cpos] = 39) OR (chars[cpos] = 34) THEN
        StorePosition (pos);
        endChar := chars[cpos];
        INC (cpos);
        cstart := cpos; cdelta := 0;
        LOOP
          IF p. aborted THEN Stop; RETURN noName END;
          CASE DispatchChar (chars[cpos]) OF
          | 00H..1FH, caseEOB:
            IF (type = stringPubidLiteral) & (chars[cpos] = ORD (Ascii.ht)) THEN
              Err (invalidPubidChar)
            END;
            ControlChar (ORD (Ascii.lf))
          | caseEOD:
            ErrPos (stringNotClosed, pos);
            RETURN GetString (cstart, cpos-cdelta)
          ELSE
            IF (chars[cpos] = endChar) THEN
              IF (type = stringPubidLiteral) THEN
                NormalizeWhitespace
              END;
              string := GetString (cstart, cpos-cdelta);
              CheckChar (endChar);
              
              CASE type OF
              | stringStandalone:
                IF (~LongStrings.Equal8 (string^, "yes")) & (~LongStrings.Equal8 (string^, "no")) THEN
                  ErrPos (expectedYesNo, pos)
                END
              | stringEncoding, stringVersion:
                IF (string[0] = 0) THEN
                  ErrPos (expectedNonEmptyString, pos)
                END
              ELSE (* ignore *)
              END;
              RETURN string
              
            ELSE
              CASE type OF
              | stringPubidLiteral:
                IF ~IsPubidChar (chars[cpos]) THEN
                  Err (invalidPubidChar)
                END
              | stringEncoding:
                IF ~IsEncNameChar (chars[cpos], cpos = cstart) THEN
                  Err (invalidEncNameChar)
                END
              | stringVersion:
                IF ~IsVersionNumChar (chars[cpos]) THEN
                  Err (invalidVersionNumChar)
                END
              ELSE (* ignore *)
              END;
              chars[cpos-cdelta] := chars[cpos]; INC (cpos)
            END
          END
        END
      ELSE
        Err (expectedString);
        RETURN GetString (cpos, cpos)
      END
    END String;

  PROCEDURE Eq;
  (* post: chars[cpos] # Buffer.markerEOB *)
    BEGIN
      OptS (TRUE); CheckChar (61); OptS (TRUE)
    END Eq;
  
  PROCEDURE XMLDecl (entity: DTD.ExternalEntity);
  (* pre: cpos=0 and looking at "<?xml"+NonName *)
    VAR
      string: DTD.String;
      encoding: POINTER TO ARRAY OF CHAR;
      codecFactory: Codec.Factory;
      i: LONGINT;
    BEGIN
      ASSERT (cpos = 0);
      ASSERT (entity # NIL);
      INC (cpos, 5);                   (* skip over "<?xml" *)
      IF (chars[cpos] # 63) THEN S END;
      IF LookingAt ("version", followedByNonName) THEN
        INC (cpos, 7);                 (* skip over "version" *)
        Eq;
        entity. SetVersion (String (stringVersion));
        IF (chars[cpos] # 63) THEN S END
      ELSIF (entity. type = DTD.entityDocument) THEN
        Err (expectedVersion)
      END;
      IF LookingAt ("encoding", followedByNonName) THEN
        INC (cpos, 8);                 (* skip over "encoding" *)
        Eq;
        string := String (stringEncoding);
        
        IF p. in. autoDetectedCodec & (entity. encoding = NIL) THEN
          (* if the character encoding was determined, through auto
             detection, then install a new codec and parse XMLDecl again *)
          NEW (encoding, LongStrings.Length (string^)+1);
          FOR i := 0 TO LEN (encoding^)-1 DO
            IF (string[i] > ORD (MAX (CHAR))) THEN
              encoding[i] := "?"
            ELSE
              encoding[i] := CHR (string[i])
            END
          END;
          codecFactory := Codec.GetFactory (encoding^);
          IF (codecFactory = NIL) THEN
            Err (unknownCharacterEncoding)
          ELSE
            p. in. SetCodec (codecFactory, FALSE);
            ResetLocator;
            XMLDecl (entity);
            RETURN
          END
        END;
        
        entity. SetEncoding (string);
        IF (chars[cpos] # 63) THEN S END
      ELSIF (entity. type # DTD.entityDocument) THEN
        Err (expectedEncodingDecl)
      END;
      IF (entity. type = DTD.entityDocument) &
         LookingAt ("standalone", followedByNonName) THEN
        INC (cpos, 10);              (* skip over "standalone" *)
        Eq;
        string := String (stringStandalone);
        IF LongStrings.Equal8 (string^, "yes") THEN
          entity. SetStandalone (DTD.standaloneYes)
        ELSE
          entity. SetStandalone (DTD.standaloneNo)
        END
      END;
      OptS (TRUE);
      IF LookingAt ("?>", followedByAny) THEN
        INC (cpos, 2)
      ELSE
        Err (expectedPIEnd)
      END
    END XMLDecl;


  PROCEDURE CurrentEntity (): DTD.Entity;
    BEGIN
      IF (p. lenPEStack = 0) THEN
        ASSERT (p. documentEntity # NIL);
        RETURN p. documentEntity
      ELSE
        ASSERT (p. peStack[p. lenPEStack-1]. entity # NIL);
        RETURN p. peStack[p. lenPEStack-1]. entity
      END
    END CurrentEntity;
  
  PROCEDURE CheckCurrentEntity (reference: DTD.Entity);
    BEGIN
      IF p. validating & (reference # CurrentEntity()) THEN
        ErrNF (nestingViolation)
      END
    END CheckCurrentEntity;
  
  
  PROCEDURE PI;
  (* pre: looking at "<?" *)
    VAR
      currentEntity: DTD.Entity;
      target: DTD.String;
    
    PROCEDURE IsReserved (name: ARRAY OF DTD.Char): BOOLEAN;
      BEGIN
        RETURN (UpperASCII (name[0]) = 88) &
               (UpperASCII (name[1]) = 77) &
               (UpperASCII (name[2]) = 76)
      END IsReserved;
    
    BEGIN
      StorePosition (p. l^);
      currentEntity := CurrentEntity();
      INC (cpos, 2);                     (* skip over "<?" *)
      target := Name (TRUE);
      IF LongStrings.Equal8 (target^, "xml") THEN
        ErrPos (xmlDeclNotAtBeginning, p. l^)
      ELSIF IsReserved (target^) THEN
        ErrPos (reservedPITarget, p. l^)
      END;
      
      IF LookingAt ("?>", followedByAny) THEN
        p. builder. ProcessingInstruction (target, chars^, 0, 0, (* callback *)
                                           p. fileEntity. baseURI);
        INC (cpos, 2)
      ELSE
        S;
        cstart := cpos; cdelta := 0;
        LOOP
          IF p. aborted THEN Stop; EXIT END;
          CASE DispatchChar (chars[cpos]) OF
          | 00H..1FH, caseEOB:
            ControlChar (ORD (Ascii.lf))
          | caseEOD:
            ErrPos (piNotClosed, p. l^);
            EXIT
          | 63:
            IF LookingAt ("?>", followedByAny) THEN
              CheckCurrentEntity (currentEntity);
              p. builder. ProcessingInstruction (target, chars^, (* callback *)
                                                 cstart, cpos-cdelta,
                                                 p. fileEntity. baseURI);
              INC (cpos, 2);
              EXIT
            ELSE
              chars[cpos-cdelta] := chars[cpos]; INC (cpos)
            END
          ELSE
            chars[cpos-cdelta] := chars[cpos]; INC (cpos)
          END
        END
      END
    END PI;

  PROCEDURE Comment;
  (* pre: looking at "<!--" *)
    VAR
      currentEntity: DTD.Entity;
    BEGIN
      StorePosition (p. l^);
      currentEntity := CurrentEntity();
      INC (cpos, 4);                     (* skip over "<!--" *)
      cstart := cpos; cdelta := 0;
      LOOP
        IF p. aborted THEN Stop; EXIT END;
        CASE DispatchChar (chars[cpos]) OF
        | 00H..1FH, caseEOB:
          ControlChar (ORD (Ascii.lf))
        | caseEOD:
          ErrPos (commentNotClosed, p. l^);
          EXIT
        | 45:
          IF LookingAt ("-->", followedByAny) THEN
            CheckCurrentEntity (currentEntity);
            p. builder. Comment (chars^, cstart, cpos-cdelta); (* callback *)
            INC (cpos, 3);
            EXIT
          ELSIF LookingAt ("--", followedByAny) THEN
            Err (invalidCommentDashDash)
          END;
          chars[cpos-cdelta] := chars[cpos]; INC (cpos);
        ELSE
          chars[cpos-cdelta] := chars[cpos]; INC (cpos)
        END
      END;
      DiscardPreviousInput
    END Comment;

  PROCEDURE CDSect;
  (* pre: looking at "<![CDATA[" *)
    BEGIN
      StorePosition (p. l^);
      p. builder. StartCDATA;            (* callback *)
      INC (cpos, 9);                     (* skip over "<![CDATA[" *)
      cstart := cpos; cdelta := 0;
      LOOP
        IF p. aborted THEN Stop; EXIT END;
        CASE DispatchChar (chars[cpos]) OF
        | 00H..1FH, caseEOB:
          ControlChar (ORD (Ascii.lf))
        | caseEOD:
          ErrPos (cdataNotClosed, p. l^);
          EXIT
        | 93:
          IF LookingAt ("]]>", followedByAny) THEN
            DecLength (p. l^, -9);
            p. builder. Characters (chars^, cstart, cpos-cdelta, (* callback *)
                                    DTD.elementWhitespaceNo);
            INC (cpos, 3);
            StorePosition (p. l^);
            p. builder. EndCDATA;        (* callback *)
            EXIT
          ELSE
            chars[cpos-cdelta] := chars[cpos]; INC (cpos)
          END
        ELSE
          chars[cpos-cdelta] := chars[cpos]; INC (cpos)
        END
      END
    END CDSect;
  
  PROCEDURE CharRef;
  (* Parses the character references and writes the result to 
     `chars[cpos-cdelta]'.  If `cstart=cpos-cdelta' when this procedure
     is invoked, then `chars[cstart,cpos-cdelta[' is the replacement
     text for the character reference.  
     pre: looking at "&#"
     post: `cstart' is preserved *)
    CONST
      overflow = 20000H;
      errorReplacement = 20H;
    VAR
      cval: LONGINT;
      pos: Locator.Position;
    
    PROCEDURE ToUnicode (cval: LONGINT): DTD.CharPos;
      BEGIN
        IF (cval <= 0FFFFH) THEN
          chars[cpos-cdelta] := cval;
          RETURN 1
        ELSE
          DEC (cval, 10000H);
          chars[cpos-cdelta] := 0D800H + cval DIV 1024;
          chars[cpos-cdelta+1] := 0DC00H + cval MOD 1024;
          RETURN 2
        END
      END ToUnicode;
    
    BEGIN
      StorePosition (pos);
      cval := 0;
      IF LookingAt ("&#x", followedByAny) THEN
        INC (cpos, 3); INC (cdelta, 3);
        LOOP
          IF p. aborted THEN Stop; RETURN END;
          CASE DispatchChar (chars[cpos]) OF
          | caseEOB:
            NextBlock
          | 59, caseEOD:
            EXIT
          | 48..57:
            IF (cval <= overflow) THEN
              cval := cval*16 + chars[cpos] - 48
            END;
            INC (cpos); INC (cdelta)
          | 97..102, 65..70:
            IF (cval <= overflow) THEN
              cval := cval*16 + (UpperASCII (chars[cpos]) + 10) - 65
            END;
            INC (cpos); INC (cdelta)
          ELSE
            Err (expectedDigit16); cval := errorReplacement; EXIT
          END
        END
      ELSE
        INC (cpos, 2); INC (cdelta, 2);
        LOOP
          IF p. aborted THEN Stop; RETURN END;
          CASE DispatchChar (chars[cpos]) OF
          | caseEOB:
            NextBlock
          | 59, caseEOD:
            EXIT
          | 48..57:
            IF (cval <= overflow) THEN
              cval := cval*10 + chars[cpos] - 48
            END;
            INC (cpos); INC (cdelta)
          ELSE
            Err (expectedDigit10); cval := errorReplacement; EXIT
          END
        END
      END;
      IF (chars[cpos] = 59) THEN INC (cdelta) END;
      CheckChar (59);
      IF ~IsCharUCS4 (cval) THEN
        ErrPos (invalidCharRef, pos); cval := errorReplacement
      END;
      
      DEC (cdelta, ToUnicode (cval))
    END CharRef;

  PROCEDURE EntityRef (enforceDecl, permitExternal: BOOLEAN): DTD.EntityRef;
  (* pre: (chars[cpos] = "&") & (chars[cpos] # "#")
     post: `cstart' is preserved *)
    VAR
      name: DTD.String;
      decl: DTD.Declaration;
      entity: DTD.Entity;
      localCStart: DTD.CharPos;
      pos: Locator.Position;
    BEGIN
      StorePosition (pos);
      CheckChar (38);
      localCStart := p. in. offsetFromPos0+cstart;
      name := Name (TRUE);
      cstart := localCStart-p. in. offsetFromPos0;
      CheckChar (59);
      
      decl := dtd. geNamespace. Get (name);
      IF (decl = NIL) THEN
        entity := NIL;
        IF enforceDecl & p. processDeclarations & (name # noName) THEN
          ErrPos (noSuchGeneralEntity, pos);
          p. lastError. SetLStringAttrib ("name", Msg.GetLStringPtr (name^))
        END
      ELSE
        entity := decl(DTD.Entity);
        IF (entity. type = DTD.entityUnparsed) THEN
          ErrPos (referenceToUnparsed, pos);
          p. lastError. SetLStringAttrib ("name", Msg.GetLStringPtr (name^));
          name := noName
        ELSIF ~permitExternal & (entity. type = DTD.entityExternalGeneral) THEN
          ErrPos (externalRefInAtttribute, pos);
          p. lastError. SetLStringAttrib ("name", Msg.GetLStringPtr (name^));
          name := noName
        END
      END;
      RETURN dtd. NewEntityRef (name, entity)
    END EntityRef;

  PROCEDURE AttValue (isAttDecl: BOOLEAN): DTD.AttValue;
  (* Parses an attribute value string and returns a data structure containing
     character sequences and general entity references.  The attribute is
     partially normalized by replacing newlines with spaces.  No non-CDATA
     normalization is done, and no general entity references are resolved.  *)
    VAR
      attValue: DTD.AttValue;
      endChar: DTD.Char;
      pos: Locator.Position;
    
    PROCEDURE Flush;
      BEGIN
        IF (cpos-cdelta # cstart) THEN
          AppendCharacters (attValue, chars, cstart, cpos-cdelta, isAttDecl)
        END
      END Flush;
    
    BEGIN
      attValue := dtd. NewAttValue();
      IF (chars[cpos] = 39) OR (chars[cpos] = 34) THEN
        StorePosition (pos);
        endChar := chars[cpos];
        INC (cpos);
        cstart := cpos; cdelta:= 0;
        LOOP
          IF p. aborted THEN Stop; EXIT END;
          CASE DispatchChar (chars[cpos]) OF
          | 00H..1FH, caseEOB:
            ControlChar (32)
          | caseEOD:
            ErrPos (stringNotClosed, pos);
            Flush;
            EXIT
          | 60:
            Err (lAngleInAttValue);
            chars[cpos-cdelta] := 32; INC (cpos)
          | 38:
            IF LookingAt ("&#", followedByAny) THEN
              (* looking at character reference: replace on the spot *)
              CharRef()
            ELSE
              Flush;
              attValue. Append (EntityRef (TRUE, FALSE));
              cstart := cpos; cdelta := 0
            END;
          ELSE
            IF (chars[cpos] = endChar) THEN
              (* if the attribute type is not CDATA, then strip the trailing
                 space; the normalization for such attributes ensures that
                 there is at most one space at the end of the value *)
              Flush;
              CheckChar (endChar);
              EXIT
            ELSE
              chars[cpos-cdelta] := chars[cpos]; INC (cpos)
            END
          END
        END
      ELSE
        Err (expectedAttValue); NextChar
      END;
      RETURN attValue
    END AttValue;

  PROCEDURE Expand (attValue: DTD.AttValue);
    VAR
      fragment: DTD.Fragment;
      decl: DTD.Declaration;
      entity: DTD.Entity;

    PROCEDURE ^ExpandAttValue (entity: DTD.Entity): DTD.AttValue;
    
    PROCEDURE IsRecursive (entity: DTD.Entity): BOOLEAN;
      VAR
        fragment: DTD.Fragment;
      BEGIN
        IF ~Enter() THEN RETURN FALSE END;
        IF ~Charge (Limits.work, 1) THEN Leave; RETURN FALSE END;
        IF entity. expanding THEN
          Leave; RETURN TRUE
        ELSE
          entity. expanding := TRUE;
          IF (entity. attValue = NIL) THEN
            entity. attValue := ExpandAttValue (entity)
          END;
          fragment := entity. attValue. fragmentList;
          WHILE (fragment # NIL) & ~p. aborted DO
            IF ~Charge (Limits.work, 1) THEN
              entity. expanding := FALSE; Leave; RETURN FALSE
            END;
            WITH fragment: DTD.EntityRef DO
              IF (fragment. entity # NIL) &
                 IsRecursive (fragment. entity) THEN
                 entity. expanding := FALSE;
                 Leave; RETURN TRUE
              END
            ELSE                           (* ignore *)
            END;
            fragment := fragment. next
          END;
          entity. expanding := FALSE;
          Leave; RETURN FALSE
        END
      END IsRecursive;

    PROCEDURE ExpandAttValue (entity: DTD.Entity): DTD.AttValue;
      VAR
        attValue: DTD.AttValue;

      PROCEDURE Flush;
        BEGIN
          IF (cpos # cstart) THEN
            AppendCharacters (attValue, chars, cstart, cpos, FALSE)
          END
        END Flush;

      BEGIN
        IF (entity IS DTD.ExternalEntity) THEN
          entity. SetEntityValue (NIL)
        END;

        attValue := dtd. NewAttValue();
        IF ~PushEntity (entity, FALSE) THEN RETURN attValue END;
        cstart := cpos;
        LOOP
          IF p. aborted THEN Stop; EXIT END;
          CASE DispatchChar (chars[cpos]) OF
          | caseEOD:
            Flush;
            EXIT
          | 00H .. 1FH:
            (* the entity value has been cleaned of end of line artifacts or
                invalid characters; any remaining whitespace must be replaced
                with " " *)
            chars[cpos] := 32;
            INC (cpos)
          | 60:
            Err (lAngleInAttValue);
            INC (cpos)
          | 38:
            Flush;
            IF LookingAt ("&#", followedByAny) THEN
              (* looking at character reference: replace on the spot *)
              cstart := cpos; cdelta := 0;
              CharRef();
              AppendCharacters (attValue, chars, cstart, cpos-cdelta, FALSE)
            ELSE
              attValue. Append (EntityRef (TRUE, FALSE))
            END;
            cstart := cpos
          ELSE
            INC (cpos)
          END
        END;
        PopEntity;
        RETURN attValue
      END ExpandAttValue;

    BEGIN
      IF ~Enter() THEN RETURN END;
      fragment := attValue. fragmentList;
      WHILE (fragment # NIL) & ~p. aborted DO
        WITH fragment: DTD.EntityRef DO
          decl := dtd. geNamespace. Get (fragment. name);
          IF (decl = NIL) THEN
            Err (noSuchGeneralEntity);
            p. lastError. SetLStringAttrib ("name", Msg.GetLStringPtr (fragment. name^))
          ELSE
            entity := decl(DTD.Entity);
            fragment. entity := entity;
            IF (entity. attValue = NIL) THEN
              entity. attValue := ExpandAttValue (entity);
              Expand (entity. attValue)
            END;

            IF IsRecursive (entity) THEN
              Err (recursiveGeneralEntity);
              p. lastError. SetLStringAttrib ("name", Msg.GetLStringPtr (entity. name^));
              fragment. entity. attValue. Clear
            END
          END
        ELSE                           (* leave characters as is *)
        END;
        fragment := fragment. next
      END;
      Leave;
      IF ~CheckValue (attValue) THEN attValue. Clear END
    END Expand;

  PROCEDURE ^element;
  
  PROCEDURE content;
  (* post: chars[cpos] # Buffer.markerEOB *)

    PROCEDURE CharData;
    (* This procedure matches character data and character references.  The
       latter are included for efficiency reasons.  A text sequence with
       with embedded character references will cause only a single up 
       call.  *)
      VAR
        elementWhitespace: DTD.ElementWhitespaceType;
      BEGIN
        StorePosition (p. l^);
        cstart := cpos; cdelta := 0;
        elementWhitespace := DTD.elementWhitespaceUnknown;

        LOOP  (* loop invariant: cdelta = 0 *)
          IF p. aborted THEN Stop; EXIT END;
          (* this is a very specialized version of the loop down below; it
             covers the case where `cdelta' stays zero, which means that
             no characters must be copied *)
          CASE DispatchChar (chars[cpos]) OF
          | 00H..1FH, caseEOB:
            IF (chars # p. in. chars) THEN
              INC (cpos)
            ELSE
              ControlChar (ORD (Ascii.lf));
              IF (cdelta # 0) THEN
                EXIT
              END
            END
          | 32:
            INC (cpos)
          | 60, 38, caseEOD:
            EXIT
          | 93:
            IF LookingAt ("]]>", followedByAny) THEN
              EXIT
            ELSE
              elementWhitespace := DTD.elementWhitespaceNo;
              INC (cpos)
            END
          ELSE
            elementWhitespace := DTD.elementWhitespaceNo;
            INC (cpos)
          END
        END;

        LOOP
          CASE DispatchChar (chars[cpos]) OF
          | 00H..1FH, caseEOB:
            IF (chars # p. in. chars) THEN
              (* when expanding an entity reference, no translation of
                 end of line characters is done; the reason for this is that
                 they have already been normalized when parsing the entity
                 value, and any remaining CR/LF characters have been
                 explicitly introduced through character references *)
              chars[cpos-cdelta] := chars[cpos]; INC (cpos)
            ELSE
              ControlChar (ORD (Ascii.lf))
            END
          | 32:
            chars[cpos-cdelta] := chars[cpos]; INC (cpos)
          | 60, caseEOD:
            EXIT
          | 38:
            IF LookingAt ("&#", followedByAny) THEN (* character reference *)
              elementWhitespace := DTD.elementWhitespaceNo;
              CharRef()
            ELSE
              EXIT
            END
          | 93:
            IF LookingAt ("]]>", followedByAny) THEN
              Err (invalidCloseCDATA)
            END;
            elementWhitespace := DTD.elementWhitespaceNo;
            chars[cpos-cdelta] := chars[cpos]; INC (cpos)
          ELSE
            elementWhitespace := DTD.elementWhitespaceNo;
            chars[cpos-cdelta] := chars[cpos]; INC (cpos)
          END
        END;

        IF (cpos-cdelta # cstart) THEN
          p. builder. Characters (chars^, cstart, cpos-cdelta, (* callback *)
                                  elementWhitespace)
        END
      END CharData;

    PROCEDURE FollowEntityRef (entityRef: DTD.EntityRef);
      VAR
        decl: DTD.Declaration;
        entity: DTD.Entity;
        pos: Locator.Position;
      BEGIN
        decl := dtd. geNamespace. Get (entityRef. name);
        IF ~Charge (Limits.work, 0) THEN RETURN END;
        entity := NIL;
        IF (decl # NIL) THEN
          entity := decl(DTD.Entity)
        END;
        StorePosition (p. l^);
        IF (chars = p. in. chars) THEN
          DecLength (p. l^, LongStrings.Length (entityRef. name^)+2)
        END;

        IF (entity = NIL) THEN
          ErrPos (noSuchGeneralEntity, p. l^);
          p. lastError. SetLStringAttrib ("name",
                                       Msg.GetLStringPtr (entityRef. name^))
        ELSIF entity. expanding THEN
          Err (recursiveGeneralEntity);
          p. lastError. SetLStringAttrib ("name",
                                       Msg.GetLStringPtr (entityRef. name^))
        ELSIF (entity. type = DTD.entityExternalGeneral) &
              ~p. followExternalRef THEN
          p. builder. SkippedEntity (entityRef. name, entity) (* callback *)
        ELSE
          p. builder. StartEntity (entity); (* callback *)
          IF ~PushEntity (entity, TRUE) THEN RETURN END;
          StorePosition (pos);
          (* recursivly enter replacement; FIXME: endless loop? *)
          IF (entity. type = DTD.entityExternalGeneral) &
             LookingAt ("<?xml", followedByNonName) THEN
            XMLDecl (decl(DTD.ExternalEntity))
          END;
          content;
          IF (chars[cpos] # Buffer.markerEOD) THEN
            ErrPos (invalidGEReplacement, pos);
            p. lastError. SetLStringAttrib ("name",
                                        Msg.GetLStringPtr (entityRef. name^))
          END;
          PopEntity;
          StorePosition (p. l^);
          p. builder. EndEntity (entity); (* callback *)
        END
      END FollowEntityRef;

    BEGIN
      IF p. aborted THEN RETURN END;
      LOOP
        IF ~Charge (Limits.work, 0) THEN EXIT END;
        CASE DispatchChar (chars[cpos]) OF
        | caseEOD:
          EXIT
        | 60:
          IF LookingAt ("<!--", followedByAny) THEN
            Comment
          ELSIF LookingAt ("<![CDATA[", followedByAny) THEN
            CDSect
          ELSIF LookingAt ("<?", followedByAny) THEN
            PI
          ELSIF (chars[cpos+1] # 47) THEN
            element
          ELSE
            EXIT
          END;
        | 38:
          IF LookingAt ("&#", followedByAny) THEN (* character reference *)
            CharData
          ELSE
            FollowEntityRef (EntityRef (FALSE, TRUE))
          END
        ELSE
          CharData
        END
      END
    END content;

  PROCEDURE element;
    VAR
      emptyElementTag: BOOLEAN;
      startName, endName: DTD.String;
      attrName: DTD.String;
      attrValue: DTD.AttValue;
      decl, decl0: DTD.Declaration;
      attrDecl: DTD.AttrDecl;
      pos: Locator.Position;
      
    PROCEDURE NoteName (name: DTD.String);
      VAR
        newList: NameList;
        i: LONGINT;
      BEGIN
        IF (p. lenNameList = LEN (p. nameList^)) THEN
          NEW (newList, LEN (p. nameList^)+incrNameList);
          FOR i := 0 TO LEN (p. nameList^)-1 DO
            newList[i] := p. nameList[i]
          END;
          p. nameList := newList
        END;
        p. nameList[p. lenNameList] := name;
        INC (p. lenNameList)
      END NoteName;
    
    PROCEDURE AttributeNameUsed (name: DTD.String): BOOLEAN;
      VAR
        i: LONGINT;
      BEGIN
        FOR i := 0 TO p. lenNameList-1 DO
          IF ~Charge (Limits.work, 1) THEN RETURN FALSE END;
          IF LongStrings.Equal (name^, p. nameList[i]^) THEN
            RETURN TRUE
          END
        END;
        RETURN FALSE
      END AttributeNameUsed;
    
    PROCEDURE AddDefaultAttributes (elemDecl: DTD.ElementDecl);
      VAR
        decl: DTD.Declaration;
        attrDecl: DTD.AttrDecl;
      
      PROCEDURE AttributeDefined (name: DTD.String): BOOLEAN;
        VAR
          i: LONGINT;
        BEGIN
          i := 0;
          WHILE (i # p. lenNameList) DO
            IF ~Charge (Limits.work, 1) THEN RETURN FALSE END;
            IF LongStrings.Equal (p. nameList[i]^, name^) THEN
              RETURN TRUE
            END;
            INC (i)
          END;
          RETURN FALSE
        END AttributeDefined;
      
      BEGIN
        IF elemDecl # NIL THEN
          decl := elemDecl. attrNamespace. declList
        ELSE
          decl := dtd. attributeList
        END;
        WHILE (decl # NIL) DO
          IF ~Charge (Limits.work, 1) THEN RETURN END;
          attrDecl := decl(DTD.AttrDecl);
          IF ((elemDecl # NIL) OR LongStrings.Equal (attrDecl. elementName^, startName^)) &
             ~AttributeDefined (attrDecl. name) THEN
            IF (attrDecl. default >= DTD.attrDefault) THEN
              Expand (attrDecl. defaultValue);
              p. builder. Attribute (NIL, decl. name, attrDecl,
                                     attrDecl. defaultValue, FALSE);
              NoteName (decl. name)
            ELSIF p. validating &
                  (attrDecl. default = DTD.attrRequired) THEN
              ErrPosNF (requiredAttrMissing, p. l^);
              p. lastError. SetLStringAttrib ("name", Msg.GetLStringPtr (attrDecl. name^))
            END
          END;
          decl := decl. next
        END
      END AddDefaultAttributes;
    
    PROCEDURE ErrEndTag;
      BEGIN
        IF (startName # noName) THEN
          ErrPos (expectedEndTag, pos);
          p. lastError. SetLStringAttrib ("name", Msg.GetLStringPtr (startName^))
        END
      END ErrEndTag;
    
    BEGIN
      IF ~Enter() THEN RETURN END;
      IF (chars[cpos] = 60) THEN
        CheckChar (60);
        p. lenNameList := 0;
        emptyElementTag := FALSE;
        StorePosition (p. l^);
        startName := Name (FALSE);
        decl := dtd. elementNamespace. Get (startName);
        IF ~Charge (Limits.work, 0) THEN Leave; RETURN END;
        p. builder. StartElement (NIL, startName); (* callback *)
        LOOP
          IF ~Charge (Limits.work, 0) THEN EXIT END;
          IF (chars[cpos] = Buffer.markerEOD) THEN
            EXIT
          ELSIF (chars[cpos] # 62) & (chars[cpos] # 47) THEN
            S
          END;
          IF (chars[cpos] = 47) THEN
            CheckChar (47);
            emptyElementTag := TRUE;
            EXIT
          ELSIF (chars[cpos] = 62) THEN
            EXIT
          END;
          
          StorePosition (p. l^);
          attrName := Name (FALSE);
          IF AttributeNameUsed (attrName) THEN
            ErrPos (multipleAttrName, p. l^);
            p. lastError. SetLStringAttrib ("name", Msg.GetLStringPtr (attrName^))
          END;
          NoteName (attrName);
          Eq;
          attrDecl := NIL;
          IF (decl # NIL) THEN
            decl0 := decl(DTD.ElementDecl). attrNamespace. Get (attrName);
            IF (decl0 # NIL) THEN
              attrDecl := decl0(DTD.AttrDecl)
            END
          ELSE
            decl0 := dtd. attributeList;
            WHILE (decl0 # NIL) & (attrDecl = NIL) DO
              IF ~Charge (Limits.work, 1) THEN
                decl0 := NIL
              ELSIF LongStrings.Equal (decl0(DTD.AttrDecl). elementName^, startName^) &
                    LongStrings.Equal (decl0. name^, attrName^) THEN
                attrDecl := decl0(DTD.AttrDecl)
              END;
              IF decl0 # NIL THEN decl0 := decl0. next END
            END
          END;
          attrValue := AttValue (TRUE);
          Expand (attrValue);
          p. builder. Attribute (NIL, attrName, attrDecl, attrValue, TRUE) (* callback *)
        END;
        
        StorePosition (p. l^);
        IF (decl # NIL) THEN
          AddDefaultAttributes (decl(DTD.ElementDecl))
        ELSE
          AddDefaultAttributes (NIL)
        END;
        CheckChar (62);
        p. builder. AttributesDone();    (* callback *)
        
        DiscardPreviousInput;
        IF emptyElementTag THEN
          StorePosition (p. l^);
          p. builder. EndElement (NIL, startName) (* callback *)
        ELSE
          content;
          StorePosition (pos);
          IF (chars[cpos] # 60) THEN ErrEndTag END;
          CheckChar (60);
          IF (chars[cpos] # 47) THEN ErrEndTag END;
          CheckChar (47);
          StorePosition (p. l^);
          endName := Name (FALSE);
          IF ~LongStrings.Equal (endName^, startName^) THEN ErrEndTag END;
          p. builder. EndElement (NIL, startName); (* callback *)
          OptS (TRUE);
          CheckChar (62)
        END
      ELSE
        Err (expectedElement)
      END;
      Leave
    END element;
  
  PROCEDURE MiscRep;
  (* post: chars[cpos] # Buffer.markerEOB *)
    BEGIN
      LOOP
        IF p. aborted THEN Stop; EXIT END;
        CASE DispatchChar (chars[cpos]) OF
        | caseEOB:
          NextBlock
        | 60:
          IF LookingAt ("<!--", followedByAny) THEN
            Comment
          ELSIF LookingAt ("<?", followedByAny) THEN
            PI
          ELSE
            EXIT
          END
        | 00H..32:
          S
        ELSE
          EXIT
        END
      END
    END MiscRep;
  
  PROCEDURE ExternalID (optionJustPubid: BOOLEAN;
                        VAR public, system: DTD.String; VAR baseURI: URI.URI);
  (* pre: ExternalID is optionally followed by S *)
    VAR
      res: Msg.Msg;
    BEGIN
      public := NIL;
      system := NIL;
      baseURI := NIL;
      IF LookingAt ("SYSTEM", followedByNonName) THEN
        INC (cpos, 6);               (* skip over "SYSTEM" *)
        S;
        system := String (stringSystemLiteral);
        p. er. GetURI (NIL, system, p. fileEntity. baseURI, baseURI, res);
        IF (res # NIL) THEN
          Err (malformedURI);
          p. lastError. SetMsgAttrib ("uri_error", res)
        END
      ELSIF LookingAt ("PUBLIC", followedByNonName) THEN
        INC (cpos, 6);               (* skip over "PUBLIC" *)
        S;
        public := String (stringPubidLiteral);
        IF ~optionJustPubid OR LookingAtS() THEN
          S;
          IF ~optionJustPubid OR
             (chars[cpos] = 39) OR (chars[cpos] = 34) THEN
            system := String (stringPubidLiteral)
          END
        END;
        p. er. GetURI (public, system, p.fileEntity.baseURI, baseURI, res);
        IF (res # NIL) THEN
          Err (malformedURI);
          p. lastError. SetMsgAttrib ("uri_error", res)
        END
      ELSE
        Err (expectedExternalID)
      END
    END ExternalID;

  PROCEDURE markupdecl;
    PROCEDURE elementdecl (currentEntity: DTD.Entity);
    (* pre: looking at "<!ELEMENT"+NonName *)
      VAR
        elementName: DTD.String;
        cp: DTD.CP;
        elementDecl: DTD.ElementDecl;
        decl: DTD.Declaration;
        particles: LONGINT;

      PROCEDURE Particle (): BOOLEAN;
        BEGIN
          IF p. aborted THEN RETURN FALSE END;
          IF (p. limits # NIL) & (p. limits. maxModelParticles >= 0) &
             (particles >= p. limits. maxModelParticles) THEN
            p. limits. Fail (Limits.modelParticles); Stop; RETURN FALSE
          END;
          INC (particles); RETURN Charge (Limits.work, 1)
        END Particle;

      PROCEDURE contentspec(): DTD.CP;
        VAR
          currentEntity: DTD.Entity;
          
        PROCEDURE Mixed (currentEntity: DTD.Entity): DTD.CP;
        (* pre: looking at "#PCDATA"+nonNameChar *)
          VAR
            hasAlternative: BOOLEAN;
            first, last: DTD.CP;
          BEGIN
            IF ~Particle() THEN RETURN dtd. NewNameCP (DTD.cpOnce, noName) END;
            first := dtd. NewNameCP (DTD.cpOnce, GetString (cpos, cpos+7));
            INC (cpos, 7);             (* skip over "#PCDATA" *)
            last := first;
            OptS (FALSE);
            hasAlternative := FALSE;
            WHILE (chars[cpos] = 124) DO
              IF ~Particle() THEN RETURN dtd. NewChoiceCP (DTD.cpOnce, first) END;
              hasAlternative := TRUE;
              CheckChar (124);
              OptS (FALSE);
              last. SetNext (dtd. NewNameCP (DTD.cpOnce, Name (FALSE)));
              last := last. next;
              OptS (FALSE)
            END;
            CheckCurrentEntity (currentEntity);
            CheckChar (41);
            IF hasAlternative OR (chars[cpos] = 42) THEN
              CheckChar (42);
              RETURN dtd. NewChoiceCP (DTD.cpRepeat0, first)
            ELSE
              RETURN dtd. NewChoiceCP (DTD.cpOnce, first)
            END
          END Mixed;

        PROCEDURE children (currentEntity: DTD.Entity): DTD.CP;
        (* pre: character before chars[cpos] was "("+S? *)
          VAR
            cp: DTD.CP;

          PROCEDURE Quantifier(): DTD.CPModeType;
          (* pre: chars[cpos] # markerEOB *)
            BEGIN
              CASE chars[cpos] OF
              | 42: CheckChar (42); RETURN DTD.cpRepeat0
              | 43: CheckChar (43); RETURN DTD.cpRepeat1
              | 63: CheckChar (63); RETURN DTD.cpOptional
              ELSE
                RETURN DTD.cpOnce
              END
            END Quantifier;

          PROCEDURE choiceseq (currentEntity: DTD.Entity): DTD.CP;
          (* pre: character before chars[cpos] was "("+S? *)
            VAR
              class: DTD.Char;
              first, last: DTD.CP;

            PROCEDURE cp(): DTD.CP;
            (* pre: chars[cpos] # markerEOB *)
              VAR
                cp: DTD.CP;
                currentEntity: DTD.Entity;
              BEGIN
                IF (chars[cpos] = 40) THEN
                  currentEntity := CurrentEntity();
                  CheckChar (40);
                  OptS (FALSE);
                  cp := choiceseq (currentEntity)
                ELSIF IsNameChar0 (chars[cpos]) THEN
                  IF ~Particle() THEN RETURN dtd. NewNameCP (DTD.cpOnce, noName) END;
                  cp := dtd. NewNameCP (DTD.cpOnce, Name (FALSE))
                ELSE
                  Err (expectedCP);
                  cp := dtd. NewNameCP (DTD.cpOnce, noName)
                END;
                cp. SetMode (Quantifier());
                RETURN cp
              END cp;

            BEGIN
              IF ~Particle() THEN RETURN dtd. NewNameCP (DTD.cpOnce, noName) END;
              IF ~Enter() THEN RETURN dtd. NewNameCP (DTD.cpOnce, noName) END;
              class := 0;
              first := cp();
              OptS (FALSE);
              last := first;
              LOOP
                CASE DispatchChar (chars[cpos]) OF
                | caseEOB:
                  NextBlock
                | 44, 124:
                  IF (class = 0) THEN
                    class := chars[cpos]
                  END;
                  CheckChar (class);
                  OptS (FALSE);
                  last. SetNext (cp());
                  last := last. next;
                  OptS (FALSE)
                ELSE                   (* end of document, or other char *)
                  EXIT
                END
              END;
              CheckChar (41);
              CheckCurrentEntity (currentEntity);
              
              IF (class = 44) THEN
                Leave;
                RETURN dtd. NewSeqCP (DTD.cpOnce, first)
              ELSE
                Leave;
                RETURN dtd. NewChoiceCP (DTD.cpOnce, first)
              END
            END choiceseq;

          BEGIN
            cp := choiceseq (currentEntity);
            cp. SetMode (Quantifier());
            RETURN cp
          END children;

        BEGIN
          IF LookingAt ("EMPTY", followedByNonName) THEN
            RETURN dtd. NewNameCP (DTD.cpOnce, Name (FALSE))
          ELSIF LookingAt ("ANY", followedByNonName) THEN
            RETURN dtd. NewNameCP (DTD.cpOnce, Name (FALSE))
          ELSIF (chars[cpos] = 40) THEN
            currentEntity := CurrentEntity();
            CheckChar (40);
            OptS (FALSE);
            IF LookingAt ("#PCDATA", followedByNonName) THEN
              RETURN Mixed (currentEntity)
            ELSE
              RETURN children (currentEntity)
            END
          ELSE
            Err (expectedContentSpec);
            RETURN dtd. NewNameCP (DTD.cpOnce, noName)
          END
        END contentspec;

      BEGIN
        particles := 0;
        INC (cpos, 9);                 (* skip over "<!ELEMENT" *)
        S;
        elementName := Name (FALSE);
        S;
        cp := contentspec();
        OptS (FALSE);

        elementDecl := dtd. NewElementDecl (elementName, cp, ~currentEntity. IsDocumentEntity());
        IF ~dtd. elementNamespace. Add (elementDecl) THEN
          IF ~Charge (Limits.work, 0) THEN RETURN END;
          decl := dtd. elementNamespace. Get (elementName);
          decl(DTD.ElementDecl). SetMultipleDecl
        END;

        CheckCurrentEntity (currentEntity);
        CheckChar (62)
      END elementdecl;

    PROCEDURE AttListDecl (currentEntity: DTD.Entity);
    (* pre: looking at "<!ATTLIST"+NonName *)
      VAR
        elementName, attrName: DTD.String;
        attrType: DTD.AttributeType;
        attrEnumeration: DTD.Enumeration;
        default: DTD.DefaultType;
        defaultValue: DTD.AttValue;
        attrDecl: DTD.AttrDecl;

      PROCEDURE AttType (VAR attrType: DTD.AttributeType;
                         VAR enum: DTD.Enumeration);
      (* post: chars[cpos] # Buffer.markerEOB *)

        PROCEDURE Enumeration (attrType: DTD.AttributeType): DTD.Enumeration;
          BEGIN
            enum := dtd. NewEnumeration();
            CheckChar (40);
            LOOP
              IF p. aborted THEN Stop; EXIT END;
              OptS (FALSE);
              CASE attrType OF
              | DTD.attrNOTATION:
                enum. Append (Name (TRUE))
              | DTD.attrENUMERATED:
                enum. Append (Nmtoken (FALSE, FALSE))
              END;
              OptS (FALSE);
              IF (chars[cpos] = 124) THEN
                CheckChar (124)
              ELSE
                EXIT
              END
            END;
            CheckChar (41);
            RETURN enum
          END Enumeration;

        BEGIN
          enum := NIL;
          IF LookingAt ("CDATA", followedByNonName) THEN
            INC (cpos, 5);
            attrType := DTD.attrCDATA
          ELSIF LookingAt ("ID", followedByNonName) THEN
            INC (cpos, 2);
            attrType := DTD.attrID
          ELSIF LookingAt ("IDREF", followedByNonName) THEN
            INC (cpos, 5);
            attrType := DTD.attrIDREF
          ELSIF LookingAt ("IDREFS", followedByNonName) THEN
            INC (cpos, 6);
            attrType := DTD.attrIDREFS
          ELSIF LookingAt ("ENTITY", followedByNonName) THEN
            INC (cpos, 6);
            attrType := DTD.attrENTITY
          ELSIF LookingAt ("ENTITIES", followedByNonName) THEN
            INC (cpos, 8);
            attrType := DTD.attrENTITIES
          ELSIF LookingAt ("NMTOKEN", followedByNonName) THEN
            INC (cpos, 7);
            attrType := DTD.attrNMTOKEN
          ELSIF LookingAt ("NMTOKENS", followedByNonName) THEN
            INC (cpos, 8);
            attrType := DTD.attrNMTOKENS
          ELSIF LookingAt ("NOTATION", followedByNonName) OR
                (chars[cpos] = 40) THEN
            IF (chars[cpos] = 40) THEN
              attrType := DTD.attrENUMERATED
            ELSE
              attrType := DTD.attrNOTATION;
              INC (cpos, 8);           (* skip over "NOTATION" *)
              S
            END;
            enum := Enumeration (attrType)
          ELSE
            Err (expectedAttType);
            NextChar;
            attrType := DTD.attrCDATA
          END
        END AttType;

      PROCEDURE DefaultDecl (attrType: DTD.AttributeType;
                             VAR default: DTD.DefaultType;
                             VAR defaultValue: DTD.AttValue);
        BEGIN
          defaultValue := NIL;
          IF LookingAt ("#REQUIRED", followedByNonName) THEN
            INC (cpos, 9);
            default := DTD.attrRequired
          ELSIF LookingAt ("#IMPLIED", followedByNonName) THEN
            INC (cpos, 8);
            default := DTD.attrImplied
          ELSE
            IF LookingAt ("#FIXED", followedByNonName) THEN
              INC (cpos, 6);           (* skip over "#FIXED" *)
              S;
              default := DTD.attrFixed
            ELSE
              default := DTD.attrDefault
            END;
            defaultValue := AttValue (TRUE)
          END
        END DefaultDecl;

      BEGIN
        INC (cpos, 9);                 (* skip over "<!ATTLIST" *)
        S;
        elementName := Name (FALSE);
        LOOP
          IF p. aborted THEN Stop; EXIT END;
          IF (chars[cpos] # 62) THEN
            S
          END;
          IF (chars[cpos] = 62) OR (chars[cpos] = Buffer.markerEOD) THEN
            EXIT
          END;

          attrName := Name (FALSE);
          S;
          AttType (attrType, attrEnumeration);
          S;
          DefaultDecl (attrType, default, defaultValue);
          IF p. processDeclarations THEN
            attrDecl := dtd. NewAttrDecl (elementName, attrName,
              attrType, attrEnumeration, default, defaultValue,
              ~currentEntity. IsDocumentEntity());
            dtd. AddAttribute (attrDecl)
          END
        END;
        CheckCurrentEntity (currentEntity);
        CheckChar (62)
      END AttListDecl;

    PROCEDURE EntityDecl (currentEntity: DTD.Entity);
    (* pre: looking at "<!ENTITY"+NonName *)
      VAR
        name: DTD.String;
        isPEntity: BOOLEAN;
        entityValue, public, system, ndata: DTD.String;
        baseURI: URI.URI;
        entity: DTD.Entity;
        entityType: DTD.EntityType;
        dummy: BOOLEAN;

      PROCEDURE EntityValue (isPEntity: BOOLEAN): DTD.String;
      (* pre: chars[cpos] # Buffer.markerEOB *)
        VAR
          endChar: DTD.Char;
          pos: Locator.Position;
          storedPos: DTD.CharPos;
          string: DTD.String;
          fragment: DTD.Fragment;
          startLevel: LONGINT;

        PROCEDURE Copy (start, end: DTD.CharPos);
          BEGIN
            WHILE (start # end) DO
              chars[start-cdelta] := chars[start];
              INC (start)
            END
          END Copy;

        BEGIN
          string := noName;
          IF (chars[cpos] = 39) OR (chars[cpos] = 34) THEN
            (* if the entity value contains parameter entity references, all
               the pieces are collected first into `p. currEntityValue', and are only
               at the very end rewritten into one large string *)
            p. currEntityValue := dtd. NewAttValue();
            
            StorePosition (pos);
            startLevel := p. lenPEStack;
            endChar := chars[cpos];
            INC (cpos);
            cstart := cpos; cdelta := 0;
            LOOP
              IF p. aborted THEN Stop; EXIT END;
              CASE DispatchChar (chars[cpos]) OF
              | 00H..1FH, caseEOB:
                ControlChar (ORD (Ascii.lf))
              | caseEOD:
                ErrPos (stringNotClosed, pos);
                AppendCharacters (p. currEntityValue, chars, cstart, cpos-cdelta, TRUE);
                EXIT
              | 37:
                IF (cstart # cpos-cdelta) THEN
                  (* append character sequence before the PE reference to
                     the fragment list *)
                  AppendCharacters (p. currEntityValue, chars, cstart, cpos-cdelta, TRUE)
                END;
                PEReference (FALSE);
                (* note: PopEntity will attach the characters from within the
                   reference to `currEntityValue'; it will also reset
                   `cstart' and `cdelta' *)
              | 38:
                IF LookingAt ("&#", followedByAny) THEN
                  (* looking at character reference: replace on the spot *)
                  CharRef()
                ELSE
                  storedPos := cpos+p. in. offsetFromPos0;
                  fragment := EntityRef (FALSE, TRUE);
                  Copy (storedPos-p. in. offsetFromPos0, cpos)
                END
              ELSE
                IF (chars[cpos] = endChar) & (p. lenPEStack = startLevel) THEN
                  (* only recognize the string end delimiter if we are not
                     expanding any entity references *)
                  AppendCharacters (p. currEntityValue, chars, cstart, cpos-cdelta, TRUE);
                  CheckChar (endChar);
                  EXIT
                ELSE
                  chars[cpos-cdelta] := chars[cpos]; INC (cpos)
                END
              END
            END;
            IF CheckValue (p. currEntityValue) THEN
              string := p. currEntityValue. Flatten (NIL)
            END;
            p. currEntityValue := NIL
          ELSE
            Err (expectedEntityValue); NextChar
          END;
          RETURN string
        END EntityValue;

      BEGIN
        INC (cpos, 8);                 (* skip over entity *)
        SnoPE;
        isPEntity := (chars[cpos] = 37);
        IF isPEntity THEN
          CheckChar (37);
          S
        END;
        StorePosition (p. l^);
        name := Name (TRUE);
        S;
        IF (chars[cpos] = 39) OR (chars[cpos] = 34) THEN
          public := NIL; system := NIL; ndata := NIL;
          entityValue := EntityValue (isPEntity);

          IF isPEntity THEN
            entityType := DTD.entityInternalParameter
          ELSE
            entityType := DTD.entityInternalGeneral
          END;
          IF ~isPEntity & ~dtd. IsValidEntityDecl (name, entityValue) THEN
            ErrPos (invalidPredefEntityDecl, p. l^)
          END;
          entity := dtd. NewInternalEntity (name, entityType, entityValue,
                                            ~currentEntity. IsDocumentEntity())
        ELSE
          entityValue := NIL;
          IF isPEntity THEN
            entityType := DTD.entityExternalParameter
          ELSE
            entityType := DTD.entityExternalGeneral
          END;
          ExternalID (FALSE, public, system, baseURI);

          ndata := NIL;
          IF ~isPEntity & LookingAtS() THEN
            S;
            IF LookingAt ("NDATA", followedByNonName) THEN
              entityType := DTD.entityUnparsed;
              INC (cpos, 5);           (* skipt over "NDATA" *)
              S;
              ndata := Name (FALSE)
            END
          END;
          entity := dtd. NewExternalEntity (name, entityType, public, system, 
                            ndata, baseURI, ~currentEntity. IsDocumentEntity())
        END;
        OptS (FALSE);
        CheckCurrentEntity (currentEntity);
        CheckChar (62);

        IF p. processDeclarations THEN
          IF isPEntity THEN
            dummy := dtd. peNamespace. Add (entity)
          ELSIF dtd. geNamespace. Add (entity) THEN
            p. builder. EntityDecl (entity) (* callback *)
          END
        END
      END EntityDecl;

    PROCEDURE NotationDecl (currentEntity: DTD.Entity);
    (* pre: looking at "<!NOTATION"+NonName *)
      VAR
        name, public, system: DTD.String;
        baseURI: URI.URI;
      BEGIN
        INC (cpos, 10);                (* skipt over "<!NOTATION" *)
        S;
        StorePosition (p. l^);
        name := Name (TRUE);
        S;
        ExternalID (TRUE, public, system, baseURI);
        (* what should be done if the external id of the notation cannot be
           resolved to an absolute URI?  Infoset suggestes this is an error
           ... *)
        OptS (FALSE);
        p. builder. Notation (dtd. NewNotation (name, public, system, baseURI)); (* callback *)
        CheckCurrentEntity (currentEntity);
        CheckChar (62)
      END NotationDecl;

    BEGIN
      IF LookingAt ("<!ELEMENT", followedByNonName) THEN
        elementdecl (CurrentEntity())
      ELSIF LookingAt ("<!ATTLIST", followedByNonName) THEN
        AttListDecl (CurrentEntity())
      ELSIF LookingAt ("<!ENTITY", followedByNonName) THEN
        EntityDecl (CurrentEntity())
      ELSIF LookingAt ("<!NOTATION", followedByNonName) THEN
        NotationDecl (CurrentEntity())
      ELSIF LookingAt ("<?", followedByAny) THEN
        PI
      ELSIF LookingAt ("<!--", followedByAny) THEN
        Comment
      ELSE
        Err (expectedMarkupDecl); NextChar
      END;
      DiscardPreviousInput
    END markupdecl;

  PROCEDURE extSubsetDecl;
    VAR
      pos: Locator.Position;
      currentEntity: DTD.Entity;
      
    PROCEDURE ignoreSectContents;
      VAR
        level: LONGINT;
      BEGIN
        level := 1;
        cstart := cpos; cdelta := 0;
        LOOP
          IF p. aborted THEN Stop; EXIT END;
          CASE DispatchChar (chars[cpos]) OF
          | 00H..1FH, caseEOB:
            ControlChar (ORD (Ascii.lf))
          | caseEOD:
            ErrPos (ignoreNotClosed, pos);
            EXIT
          | 93:
            IF LookingAt ("]]>", followedByAny) THEN
              IF (level = 1) THEN
                CheckCurrentEntity (currentEntity)
              END;
              INC (cpos, 3);             (* skip over "]]>" *)
              DEC (level);
              IF (level = 0) THEN
                EXIT
              END
            ELSE
              chars[cpos-cdelta] := chars[cpos]; INC (cpos)
            END
          | 60:
            IF LookingAt ("<![", followedByAny) THEN
              INC (cpos, 3);             (* skip over "]]>" *)
              INC (level)
            ELSE
              chars[cpos-cdelta] := chars[cpos]; INC (cpos)
            END
          ELSE
            chars[cpos-cdelta] := chars[cpos]; INC (cpos)
          END
        END
      END ignoreSectContents;
    
    BEGIN
      IF ~Enter() THEN RETURN END;
      LOOP
        IF p. aborted THEN EXIT END;
        IF (chars[cpos] = 60) THEN
          currentEntity := CurrentEntity();
          StorePosition (pos);
          IF LookingAt ("<![", followedByAny) THEN
            INC (cpos, 3);           (* skip over "<![" *)
            OptS (FALSE);
            IF LookingAt ("INCLUDE", followedByNonName) THEN
              INC (cpos, 7);         (* skip over "INCLUDE" *)
              OptS (FALSE);
              CheckCurrentEntity (currentEntity);
              CheckChar (91);
              extSubsetDecl;
              CheckCurrentEntity (currentEntity);
              IF LookingAt ("]]>", followedByAny) THEN
                INC (cpos, 3)        (* skip over "]]>" *)
              ELSE
                Err (expectedEOS)
              END
            ELSIF LookingAt ("IGNORE", followedByNonName) THEN
              INC (cpos, 6);         (* skip over "IGNORE" *)
              OptS (FALSE);
              CheckCurrentEntity (currentEntity);
              CheckChar (91);
              ignoreSectContents
            ELSE
              Err (expectedConditional)
            END
          ELSE
            markupdecl
          END
        ELSIF (chars[cpos] = 37) THEN
          PEReference (TRUE)
        ELSIF LookingAtSnoPE() THEN
          SnoPE
        ELSE
          EXIT
        END
      END;
      Leave
    END extSubsetDecl;

  PROCEDURE prolog;
    PROCEDURE doctypedecl;
      VAR
        rootName, public, system: DTD.String;
        baseURI: URI.URI;
        externalSubset: DTD.ExternalEntity;
        decl: DTD.Declaration;
        attr: DTD.AttrDecl;
      
      PROCEDURE CheckGeneralEntities;
        VAR
          decl: DTD.Declaration;
          oldBuilder: Builder.Builder;
          oldErrCount, len: LONGINT;
          oldValidating: BOOLEAN;
          pos: Locator.Position;
        BEGIN
          (* internal general entities must match the `content' production;
             create a sandbox and parse every internal general entity inside
             this sandbox *)
          oldBuilder := p. builder;
          oldErrCount := p. errList. msgCount;
          oldValidating := p. validating;
          StorePosition (pos);
          
          p. builder := Builder.New();
          decl := p. dtd. geNamespace. declList;
          LOOP
            IF (decl = NIL) OR p. aborted THEN EXIT END;
            IF (decl(DTD.Entity). type = DTD.entityInternalGeneral) THEN
              len := LongStrings.Length (decl. name^)+2;
              INC (cpos, len);
              IF ~PushEntity (decl(DTD.Entity), TRUE) THEN
                DEC (cpos, len); Stop; EXIT
              END;
              
              content;
              IF (chars[cpos] # Buffer.markerEOD) THEN
                ErrPos (invalidGEReplacement, pos);
                p. lastError. SetLStringAttrib ("name",
                                               Msg.GetLStringPtr (decl. name^))
              END;
              
              PopEntity; DEC (cpos, len);
              IF p. aborted THEN Stop; EXIT END;
            END;
            decl := decl. next
          END;
          
          (* replace the sandbox with the usual environment *)
          p. validating := oldValidating;
          IF (p. errList. msgCount = oldErrCount) THEN (* no errors found *)
            p. builder := oldBuilder
          ELSE                           (* some WFC was detected *)
            p. builder := Builder.New()
          END
        END CheckGeneralEntities;
      
      BEGIN  (* pre: looking at "<!DOCTYPE"+NonName *)
        p. inDTD := TRUE;
        
        StorePosition (p. l^);
        p. builder. StartDTD (p. dtd);   (* callback *)
        IF ~Charge (Limits.work, 0) THEN RETURN END;
        
        INC (cpos, 9);                   (* skip over "<!DOCTYPE" *)
        S;
        rootName := Name (FALSE);
        p. dtd. SetRootName (rootName);
        OptS (FALSE);
        IF LookingAt ("SYSTEM", followedByAny) OR
           LookingAt ("PUBLIC", followedByAny) THEN
          (* this implies that there was some whitespace between the name
             and the current character *)
          ExternalID (FALSE, public, system, baseURI); 
          OptS (FALSE)
        ELSE
          system := NIL; public := NIL; baseURI := NIL
        END;
        IF (chars[cpos] = 91) THEN
          CheckChar (91);
          LOOP
            IF p. aborted THEN Stop; EXIT END;
            IF (chars[cpos] = 60) THEN
              markupdecl
            ELSIF (chars[cpos] = 37) THEN
              PEReference (TRUE)
            ELSIF LookingAtSnoPE() THEN
              SnoPE
            ELSE
              EXIT
            END
          END;
          IF (p. lenPEStack # 0) THEN
            Err (unbalancedPERef)
          END;
          CheckChar (93);
          OptS (FALSE)
        END;
        CheckChar (62);
        
        IF (public # NIL) OR (system # NIL) THEN
          IF p. followExternalRef THEN
            externalSubset := dtd. NewExternalDTD (public, system, baseURI);
            IF ~PushEntity (externalSubset, TRUE) THEN RETURN END;
            p. inExternalSubset := TRUE;
            IF LookingAt ("<?xml", followedByNonName) THEN
              XMLDecl (externalSubset)
            END;
            extSubsetDecl;
            p. inExternalSubset := FALSE;
            IF (chars[cpos] # Buffer.markerEOD) THEN
              Err (junkAfterExtSubset)
            END;
            PopEntity
          ELSE
            SkippedEntity (NIL)
          END
        ELSE
          externalSubset := NIL;
        END;
        
        (* for every attribute declaration, expand its default value *)
        decl := dtd. attributeList;
        WHILE (decl # NIL) DO
          attr := decl(DTD.AttrDecl);
          IF (attr. default >= DTD.attrDefault) THEN
            Expand (attr. defaultValue)
          END;
          decl := decl. next
        END;
        
        dtd. AttachAttributes;
        CheckGeneralEntities;
        StorePosition (p. l^);
        p. builder. EndDTD (externalSubset, p. readCompleteDTD); (* callback *)
        p. inDTD := FALSE
      END doctypedecl;
    
    BEGIN
      IF LookingAt ("<?xml", followedByNonName) THEN
        XMLDecl (p. documentEntity)
      END;
      MiscRep;
      IF LookingAt ("<!DOCTYPE", followedByNonName) THEN
        doctypedecl;
        MiscRep
      END
    END prolog;
  
  BEGIN
    SetFileEntity (p. documentEntity);
    ResetLocator;
    chars := p. in. chars;
    dtd := p. dtd;
    
    StorePosition (p. l^);
    p. builder. SetLocator (p. l);
    p. builder. SetErrorListener (p. errorListener);
    p. builder. StartDocument (p. documentEntity); (* callback *)
    IF (p. limits # NIL) & (p. limits. error # NIL) THEN Stop END;
    
    prolog;
    IF (p. limits # NIL) & (p. limits. error # NIL) THEN Stop END;
    p. inDocumentElement := TRUE;
    element;
    IF p. aborted THEN
      WHILE (p. lenPEStack # 0) DO PopEntity END
    END;
    IF (p. lenPEStack # 0) THEN
      Err (unbalancedGERef)
    END;
    p. inDocumentElement := FALSE;
    MiscRep;
    IF (chars[cpos] # Buffer.markerEOD) THEN
      Err (junkAfterDocument)
    END;
    CheckInvalidChars (p. in, p. fileEntity);
    IF (p. limits # NIL) & (p. limits. error # NIL) THEN Stop END;
    
    StorePosition (p. l^);
    p. initialBuilder. EndDocument;      (* callback *)
    IF (p. limits # NIL) & (p. limits. error # NIL) THEN Stop END
  END ParseDocument;


PROCEDURE Init (p: Parser; new: BOOLEAN;
                reader: Channel.Reader;
                baseURI: URI.URI;
                codecFactory: Codec.Factory;
                entityResolver: EntityResolver.Resolver;
                builder: Builder.Builder; limits: Limits.Budget);
  BEGIN
    p. limits := limits; p. aborted := FALSE;
    p. errList := Error.NewList();
    IF new THEN
      NEW (p. l);
      NEW (p. errorListener);
      NEW (p. nameList, initNameList);
      NEW (p. peStack, initPEStack);
      p. in := Buffer.NewInput (Limits.Wrap (reader, limits), codecFactory, p. errList);
    ELSE
      HALT (127);
      (*p. in. Reset (reader, codecFactory, p. errList)*)
    END;
    
    p. l. inInternalEntity := NIL;
    p. errorListener. p := p;
    
    p. dtd := DTD.New();
    p. dtd. SetLimits (limits);
    p. documentEntity := p. dtd. NewDocumentEntity (baseURI);
    p. documentEntity. SetCodecFactory (p. in. codecFactory);
    p. builder := builder;
    p. initialBuilder := builder;
    builder. SetLimits (limits);
    IF (entityResolver = NIL) THEN
      entityResolver := EntityResolver.New()
    END;
    p. er := entityResolver;
    
    
    p. followExternalRef := TRUE;
    p. enforceQNames := FALSE;
    p. validating := FALSE;
    p. processDeclarations := TRUE;
    p. readCompleteDTD := TRUE;
    
    p. inDocumentElement := FALSE;
    p. inDTD := FALSE;
    p. inExternalSubset := FALSE;
    p. inExternalEntity := FALSE;
    
    p. currEntityValue := NIL;
    p. lenNameList := 0;
    p. lenPEStack := 0
  END Init;

(*PROCEDURE (p: Parser) Reset* (reader: Channel.Reader;
                              baseURI: URI.URI;
                              codecFactory: Codec.Factory;
                              entityResolver: EntityResolver.Resolver;
                              builder: Builder.Builder);
(**Resets the buffer @oparam{b} to its initial state.  This has the same effect
   as calling @oproc{NewReader} with the same parameters, except that some of
   the resources allocated by @oparam{b} are reused.
   
   Note: This method does not change the state of the reader @oparam{reader}.
   For example, if the reader should continue reading a file from its
   beginning, then it must be positioned @emph{before} this method is called.*)
  BEGIN
    Init (p, FALSE, reader, baseURI, codecFactory, entityResolver, builder)
  END Reset;*)

PROCEDURE NewChannel* (ch: Channel.Channel;
                       baseURI: URI.URI; 
                       codecFactory: Codec.Factory;
                       entityResolver: EntityResolver.Resolver;
                       builder: Builder.Builder): Parser;
(**Creates a new parser for the input channel @oparam{ch}.  @oparam{baseURI} is
   the absolute URI of the document entity, as computed by the method of
   RFC 2396, if that is known.  If this value is @code{NIL}, or refers to an
   opaque URI, then relative URIs in the document cannot be resolved.
   
   @oparam{codecFactory} designates the decoder that should be used to read
   the byte stream from @oparam{ch}.  If this is @code{NIL}, then autodetection
   is done on the input encoding.  If everything fails, the decoder defaults
   to @ovar{UTF8.factory}.
   
   The entity resolver @oparam{entityResolver} is used to map public and
   system identifiers of the document to absolute URIs.  If it is @code{NIL},
   entities are exclusively resolved through their system identifier.
   
   The interface to the application is the builder instance @oparam{builder}.
   During parsing, the parser will call the methods of this object.  *)
  VAR
    p: Parser;
  BEGIN
    NEW (p);
    Init (p, TRUE, ch. NewReader(), 
                   baseURI, codecFactory, entityResolver, builder, NIL);
    RETURN p
  END NewChannel;

PROCEDURE NewReader* (reader: Channel.Reader;
                      baseURI: URI.URI; 
                      codecFactory: Codec.Factory;
                      entityResolver: EntityResolver.Resolver;
                      builder: Builder.Builder): Parser;
(**Like @oproc{NewChannel}, but takes the data from the reader @oparam{reader}.
   *)
  VAR
    p: Parser;
  BEGIN
    NEW (p);
    Init (p, TRUE, reader, baseURI, codecFactory, entityResolver, builder, NIL);
    RETURN p
  END NewReader;

PROCEDURE NewReaderLimited* (reader: Channel.Reader; baseURI: URI.URI;
                            codecFactory: Codec.Factory;
                            entityResolver: EntityResolver.Resolver;
                            builder: Builder.Builder; limits: Limits.Budget): Parser;
(**Creates a parser with a shared budget applied before input prefetch.
   The same budget is used for every external entity opened during parsing. *)
  VAR p: Parser;
  BEGIN
    NEW (p); Init (p, TRUE, reader, baseURI, codecFactory, entityResolver, builder, limits);
    RETURN p
  END NewReaderLimited;

PROCEDURE NewChannelLimited* (channel: Channel.Channel; baseURI: URI.URI;
                             codecFactory: Codec.Factory;
                             entityResolver: EntityResolver.Resolver;
                             builder: Builder.Builder; limits: Limits.Budget): Parser;
(**Like @oproc{NewReaderLimited}, using a new reader on the channel. *)
  BEGIN
    RETURN NewReaderLimited (channel. NewReader(), baseURI, codecFactory,
                             entityResolver, builder, limits)
  END NewChannelLimited;

PROCEDURE NewURILimited* (uri, baseURI: URI.URI; codecFactory: Codec.Factory;
                          entityResolver: EntityResolver.Resolver;
                          builder: Builder.Builder; limits: Limits.Budget;
                          VAR res: Msg.Msg): Parser;
(**Opens the primary URI and applies the budget before reading its contents. *)
  VAR ch: Channel.Channel;
  BEGIN
    ch := uri. GetChannel (URI.channelOld, res);
    IF ch = NIL THEN RETURN NIL END;
    RETURN NewReaderLimited (ch. NewReader(), uri, codecFactory, entityResolver, builder, limits)
  END NewURILimited;

PROCEDURE NewFileLimited* (filePath: ARRAY OF CHAR; baseURI: URI.URI;
                          codecFactory: Codec.Factory;
                          entityResolver: EntityResolver.Resolver;
                          builder: Builder.Builder; limits: Limits.Budget;
                          VAR res: Msg.Msg): Parser;
(**Like @oproc{NewURILimited}, using a file path. *)
  BEGIN
    RETURN NewURILimited (File.ToURI (filePath), baseURI, codecFactory,
                          entityResolver, builder, limits, res)
  END NewFileLimited;

PROCEDURE NewURI* (uri, baseURI: URI.URI; 
                   codecFactory: Codec.Factory;
                   entityResolver: EntityResolver.Resolver;
                   builder: Builder.Builder; VAR res: Msg.Msg): Parser;
(**Like @oproc{NewChannel}, but opens the channel on the URI @oparam{uri}.  If
   the channel cannot be opened, result is @code{NIL} and @oparam{res} holds
   the error message.  *)
  VAR
    ch: Channel.Channel;
  BEGIN
    ch := uri. GetChannel (URI.channelOld, res);
    IF (ch = NIL) THEN
      RETURN NIL
    ELSE
      RETURN NewChannel (ch, uri, codecFactory, entityResolver, builder)
    END
  END NewURI;

PROCEDURE NewFile* (filePath: ARRAY OF CHAR; baseURI: URI.URI; 
                    codecFactory: Codec.Factory;
                    entityResolver: EntityResolver.Resolver;
                    builder: Builder.Builder; VAR res: Msg.Msg): Parser;
(**Like @oproc{NewURI}, using the file @oparam{filePath}.  *)
  BEGIN
    RETURN NewURI (File.ToURI (filePath), baseURI, codecFactory,
                   entityResolver, builder, res)
  END NewFile;

PROCEDURE NewExternalID* (public, system: ARRAY OF DTD.Char;
                          systemBaseURI: URI.URI; 
                          codecFactory: Codec.Factory;
                          entityResolver: EntityResolver.Resolver;
                          builder: Builder.Builder; VAR res: Msg.Msg): Parser;
(**Like @oproc{NewURI}, using the given public or system identifier.  The
   external identifiers are mapped to an absolute URI using
   @oparam{entityResolver}.  *)
  VAR
    uri: URI.URI;
    
  PROCEDURE ToString (VAR s: ARRAY OF DTD.Char): DTD.String;
    VAR
      str: DTD.String;
    BEGIN
      IF (s[0] = 0) THEN
        RETURN NIL
      ELSE
        NEW (str, LongStrings.Length (s)+1);
        LongStrings.Assign (s, str^);
        RETURN str
      END
    END ToString;
  
  BEGIN
    entityResolver. GetURI (ToString (public), ToString (system),
                            systemBaseURI, uri, res);
    IF (uri = NIL) THEN
      RETURN NIL
    ELSE
      RETURN NewURI (uri, NIL, codecFactory, entityResolver, builder, res)
    END
  END NewExternalID;


PROCEDURE SetErrorMessages;
  VAR
    i: INTEGER;
    t: ARRAY 128 OF CHAR;
  BEGIN
    FOR i := 0 TO 999 DO
      CASE i OF
      | invalidChar:
        t := "Invalid character in document"
      | junkAfterDocument:
        t := "Junk after document element"
      | invalidCloseCDATA:
        t := "String `]]>' not allowed in character data"
      | invalidCommentDashDash:
        t := "String `--' not allowed in comment"
      | commentNotClosed:
        t := "Comment not closed"
      | stringNotClosed:
        t := "String not closed"
      | piNotClosed:
        t := "Processing instruction not closed"
      | cdataNotClosed:
        t := "CDATA section not closed"
      | expectedWhitespace:
        t := "Expected whitespace"
      | expectedName:
        t := "Expected name token"
      | expectedNmtoken:
        t := "Expected Nmtoken"
      | expectedChar:
        t := "Expected character `${symbol}'"
      | lAngleInAttValue:
        t := "Character `<' not allowed in attribute value"
      | expectedDigit10:
        t := "Expected digit [0-9]"
      | expectedDigit16:
        t := "Expected digit [0-9a-fA-F]"
      | expectedString:
        t := "Expected string"
      | invalidCharRef:
        t := "Character reference designates illegal character"
      | expectedEOS:
        t := "Exepcted `]]>'"
      | ignoreNotClosed:
        t := "Ignored section not closed"
      | invalidPubidChar:
        t := "Invalid character in public ID string"
      | invalidEncNameChar:
        t := "Invalid character in encoding name"
      | invalidVersionNumChar:
        t := "Invalid character in version number"
      | expectedNonEmptyString:
        t := "Expected non-empty string"
      | expectedYesNo:
        t := "Expected 'yes' or 'no'"
      | xmlDeclNotAtBeginning:
        t := "XML declaration must be at beginning of file"
      | reservedPITarget:
        t := "This target name is reserved"
      | invalidCharacterEncodings:
        t := "Document `${uri}' had ${encodings} character encoding errors"
      | junkAfterExtSubset:
        t := "Junk after external DTD subset"
      | unknownCharacterEncoding:
        t := "Unknown character encoding"
      | invalidNCName:
        t := "This name must not contain a colon character `:'"
      | invalidQName:
        t := "Invalid use of colon in a qualified name"
        
      | expectedMarkupDecl:
        t := "Expected markup declaration"
      | expectedContentSpec:
        t := "Expected content specification: `EMPTY', `ANY', or `('"
      | expectedAttType:
        t := "Expected attribute type (type name, `NOTATION', or enumeration)"
      | expectedAttValue:
        t := "Expected attribute value"
      | expectedEntityValue:
        t := "Expected entity value"
      | expectedCP:
        t := "Expected content particle (name or `(')"
      | expectedVersion:
        t := "Expected token `version'"
      | expectedExternalID:
        t := "Expected `PUBLIC' or `SYSTEM'"
      | expectedConditional:
        t := "Expected `INCLUDE' or `IGNORE'"
      | expectedPIEnd:
        t := "Expected `?>'"
      | nonMarkupDeclPERef:
        t := "Parameter entity references are restricted to markup declarations in the internal subset of the DTD"
      | expectedEncodingDecl:
        t := "Expected token `encoding'"
      | malformedURI:
        t := "Malformed URI: ${uri_error}"
      | invalidPredefEntityDecl:
        t := "Invalid redefinition of a predefined internal entity"
        
      | expectedElement:
        t := "Expected element"
      | expectedEndTag:
        t := "Expected end tag </${name}>"
      | noSuchGeneralEntity:
        t := "General entity `${name}' not defined"
      | noSuchParameterEntity:
        t := "Parameter entity `${name}' not defined"
      | multipleAttrName:
        t := "Attribute `${name}' is already defined"
      | recursiveGeneralEntity:
        t := "General entity `${name}' is defined recursively"
      | requiredAttrMissing:
        t := "Required attribute `${name}' is not set"
      
      | unbalancedPERef:
        t := "End tag `${name}' comes from a different entity than its start tag"
      | unbalancedGERef:
        t := "Unbalanced general entity reference"
      | invalidGEReplacement:
        t := "Replacement text of general entity `${name}' is not valid content"
      | accessError:
        t := "Could not access URL `${uri}': ${channel_error}"
      | referenceToUnparsed:
        t := "Reference to unparsed entity `${name}' not allowed"
      | externalRefInAtttribute:
        t := "Attribute value contains reference to external entity `${name}'"
      | nestingViolation:
        t := "Nesting violation: Opening and closing parenthesis not in same entity"
      | externalAccessDisabled:
        t := "External entity access is disabled"
      | recursiveParameterEntity:
        t := "Parameter entity `${name}' is defined recursively"
      ELSE
        t := ""
      END;
      IF (t # "") THEN
        parserContext. SetString (i, t)
      END
    END
  END SetErrorMessages;

BEGIN
  LongStrings.Long ("-'()+,./:=?;!*#@$_%", suplPubidChar);
  NEW (noName, 8);
  LongStrings.Long ("#no_name", noName^);

  parserContext := Error.NewContext ("XML:Parser");
  SetErrorMessages
END XMLParser.
