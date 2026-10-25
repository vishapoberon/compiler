MODULE XMLBasicElement;

IMPORT
  SYSTEM, LongStrings, DTD := XMLDTD, Locator := XMLLocator, Writer := XMLWriter;


TYPE
  String* = DTD.String;
  StringVar* = DTD.StringVar;
  CharPos* = DTD.CharPos;
  AttValue* = DTD.AttValue;
  
TYPE
  StringBuffer* = POINTER TO StringBufferDesc;
  StringBufferDesc = RECORD
    length-: LONGINT;
    array-: String;
  END;

TYPE
  Element* = POINTER TO ElementDesc;
  ElementDesc* = RECORD
    next-: Element;
  END;

TYPE
  PCData* = POINTER TO PCDataDesc;
  PCDataDesc = RECORD
    (ElementDesc)
    chars-: StringBuffer;
  END;

TYPE
  List* = POINTER TO ListDesc;
  ListDesc = RECORD
    head-, tail-: Element;
  END;


TYPE
  FactoryFunction* = PROCEDURE (): Element;
  ElementFactory = POINTER TO ElementFactoryDesc;
  ElementFactoryDesc = RECORD
    next: ElementFactory;
    name: String;
    gen: FactoryFunction;
  END;

TYPE
  RootFactory* = POINTER TO RootFactoryDesc;
  RootFactoryDesc = RECORD
    list: ElementFactory;
  END;


CONST
  stringBufferSlack = 8;
  stringBufferMinSize = 32-stringBufferSlack;


PROCEDURE InitRootFactory (rf: RootFactory);
  BEGIN
    rf. list := NIL
  END InitRootFactory;

PROCEDURE NewRootFactory* (): RootFactory;
  VAR
    rf: RootFactory;
  BEGIN
    NEW (rf);
    InitRootFactory (rf);
    RETURN rf
  END NewRootFactory;

PROCEDURE (rf: RootFactory) AddFactory* (name: StringVar;
                                         gen: FactoryFunction);
  VAR
    ef: ElementFactory;
  BEGIN
    NEW (ef);
    NEW (ef. name, LongStrings.Length (name)+1);
    LongStrings.Assign (name, ef. name^);
    ef. gen := gen;
    ef. next := rf. list;
    rf. list := ef
  END AddFactory;

PROCEDURE (rf: RootFactory) NewElement* (name: String): Element;
(**Called with the name of the root element of an XML document.  Result is a
   new instance of the element if the name is valid, or @code{NIL} otherwise.  *)
  VAR
    ptr: ElementFactory;
  BEGIN
    ptr := rf. list;
    WHILE (ptr # NIL) & ~LongStrings.Equal (ptr. name^, name^) DO
      ptr := ptr. next
    END;
    IF (ptr = NIL) THEN
      RETURN NIL
    ELSE
      RETURN ptr. gen()
    END
  END NewElement;

(* ------------------------------------------------------------------------ *)

PROCEDURE InitElement* (elem: Element);
  BEGIN
    elem. next := NIL;
  END InitElement;

PROCEDURE (elem: Element) SetLocator* (l: Locator.Locator);
(**Using the locator @oparam{l}, the context of the element and its attributes
   can be determined.  This can be used to get the base URI relative to which
   an URI attribute value should be expanded.  This method is called after an
   element has been created, and before any attribute or content data is passed
   on to it.  *)
  BEGIN
  END SetLocator;

PROCEDURE (elem: Element) IsChildName* (localName: String): BOOLEAN;
(**Determines if @oparam{localName} is a valid name for a child element of
   @oparam{elem}.  If result is @code{FALSE}, the parser will generate an
   appropriate error message.  By default, all child names are rejected.  *)
  BEGIN
    RETURN FALSE
  END IsChildName;

PROCEDURE (elem: Element) NewChild* (localName: String): Element;
(**Creates a new instance of the child element if the child can appear at the
   current place in the element.  Otherwise, it returns @code{NIL}.  The
   default implementation always returns @code{NIL}.  *)
  BEGIN
    RETURN NIL
  END NewChild;

PROCEDURE (elem: Element) MissingChild* (): String;
(**Called at the end of an XML element to determine if any required child
   elements are missing.  Result is the name of one of the missing childs, or
   @code{NIL} if all required child elements are present.  By default,
   @code{NIL} is returned.  *)
  BEGIN
    RETURN NIL
  END MissingChild;

PROCEDURE (elem: Element) AddChild* (child: Element);
(**Adds the parsed child element @oparam{child} to @oparam{elem}.  The object
   @oparam{child} was previously created with @oproc{Element.NewChild}.  *)
  BEGIN
    HALT (127)
  END AddChild;


PROCEDURE (elem: Element) IsAttributeName* (localName: String): BOOLEAN;
(**Determines if @oparam{localName} is a valid name for an attribute of
   @oparam{elem}.  If result is @code{FALSE}, the parser will generate an
   appropriate error message.  By default, all attribute names are rejected.  *)
  BEGIN
    RETURN FALSE
  END IsAttributeName;

PROCEDURE (elem: Element) AddAttribute* (localName: String;
                                         value: AttValue): BOOLEAN;
(**Adds the attribute @oparam{localName} to the element @oparam{elem}.  If the
   attribute value @oparam{value} is valid, result is @code{TRUE}.  Otherwise,
   this functions returns @code{FALSE} and the parser will generate an
   appropriate error message.  The default implementation always returns
   @code{FALSE}.  *)
  BEGIN
    RETURN FALSE
  END AddAttribute;

PROCEDURE (elem: Element) MissingAttribute* (): String;
(**Called at the end of the attribute list of a start tag to determine if any
   required attributes are missing.  Result is the name of one of the missing
   attributes, or @code{NIL} if all required attributes are present.  The
   default behavious is to return @code{NIL}.  *)
  BEGIN
    RETURN NIL
  END MissingAttribute;


PROCEDURE (elem: Element) HasMixedContent*(): BOOLEAN;
(**Returns @code{TRUE}, if element @oparam{elem} containes mixed content.  In
   this case, the element may contain character data other than whitespace.
   For element that has only element content, @oproc{Element.AddCharacters} is
   not called, and an error is signalled if the element content includes
   non-whitespace characters.  By default, element-only content is assumed.  *)
  BEGIN
    RETURN FALSE
  END HasMixedContent;

PROCEDURE (elem: Element) AddCharacters* (VAR chars: StringVar;
                                          charsStart, charsEnd: CharPos);
(**Adds character data to the content of element @oparam{elem}.  The new
   characters are in the character interval
   @samp{@oparam{chars}[@oparam{charsStart}..@oparam{charsEnd}-1]}.  *)
  BEGIN
    HALT (127)
  END AddCharacters;

PROCEDURE (elem: Element) CheckElement* (): String;
(**Called at the very end of an XML element (after
   @oproc{Element.MissingChild}) to perform consistency checks on the whole
   element.  For example, this method makes sure that the combination of
   attributes and content does not violate any rules of the application.

   Result is an error message if some part of the element is invalid, and
   @code{NIL} on success.  By default, @code{NIL} is returned.

   Any code that should be evaluted if an element is completed, should be
   placed in this method.  *)
  BEGIN
    RETURN NIL
  END CheckElement;

PROCEDURE (elem: Element) Write* (writer: Writer.Writer);
(**Serializes the object @oparam{elem} into an XML element.  The data is
   generated with the writer @oparam{writer}.  *)
  BEGIN HALT (127)
  END Write;

(* ------------------------------------------------------------------------ *)

PROCEDURE NewList*(): List;
  VAR
    list: List;
  BEGIN
    NEW (list);
    list. head := NIL;
    list. tail := NIL;
    RETURN list
  END NewList;

PROCEDURE (list: List) Append* (elem: Element);
  BEGIN
    elem. next := NIL;
    IF (list. head = NIL) THEN
      list. head := elem;
      list. tail := elem
    ELSE
      list. tail. next := elem
    END;
    list. tail := elem
  END Append;

PROCEDURE (list: List) IsEmpty* (): BOOLEAN;
  BEGIN
    RETURN (list. head = NIL)
  END IsEmpty;

PROCEDURE (list: List) Write* (w: Writer.Writer);
  VAR
    elem: Element;
  BEGIN
    elem := list. head;
    WHILE (elem # NIL) DO
      elem. Write (w);
      elem := elem. next
    END
  END Write;

(* ------------------------------------------------------------------------ *)

PROCEDURE NewString* (value: StringVar): String;
  VAR
    str: String;
  BEGIN
    NEW (str, LongStrings.Length (value)+1);
    LongStrings.Assign (value, str^);
    RETURN str
  END NewString;

PROCEDURE NewStringBuffer* (value: StringVar): StringBuffer;
  VAR
    sb: StringBuffer;
    len: LONGINT;
  BEGIN
    NEW (sb);
    sb. length := LongStrings.Length (value);
    len := stringBufferMinSize;
    WHILE (len <= sb. length) DO
      ASSERT (len <= (MAX (LONGINT)-stringBufferSlack) DIV 2);
      len := len*2+stringBufferSlack
    END;
    NEW (sb. array, len);
    LongStrings.Assign (value, sb. array^);
    RETURN sb
  END NewStringBuffer;

PROCEDURE (sb: StringBuffer) AddCharacters* (VAR chars: StringVar;
                                             charsStart, charsEnd: CharPos);
   VAR
    i, len: LONGINT;
    new: String;
  BEGIN
    ASSERT ((0 <= charsStart) & (charsStart <= charsEnd) & (charsEnd <= LEN (chars)));
    ASSERT (charsEnd-charsStart < MAX (LONGINT)-sb. length);
    (* make sure that the new text can be stored *)
    IF (charsEnd-charsStart+sb. length >= LEN (sb. array^)) THEN
      len := LEN (sb. array^);
      REPEAT
        ASSERT (len <= (MAX (LONGINT)-stringBufferSlack) DIV 2);
        len := len*2+stringBufferSlack
      UNTIL (charsEnd-charsStart+sb. length < len);
      NEW (new, len);
      FOR i := 0 TO sb. length DO
        new[i] := sb. array[i]
      END;
      sb. array := new
    END;
    
    (* copy text over *)
    IF charsStart < charsEnd THEN
      SYSTEM.MOVE (SYSTEM.ADR (chars[charsStart]), SYSTEM.ADR (sb. array[sb. length]),
                   (charsEnd-charsStart)*SIZE (DTD.Char))
    END;
    INC (sb. length, charsEnd-charsStart);
    sb. array[sb. length] := 0
  END AddCharacters;

(* ------------------------------------------------------------------------ *)

PROCEDURE InitPCData* (pcdata: PCData);
  VAR empty: ARRAY 1 OF DTD.Char;
  BEGIN
    InitElement (pcdata);
    empty[0] := 0; pcdata. chars := NewStringBuffer(empty)
  END InitPCData;

PROCEDURE NewPCData*(): PCData;
  VAR
    pcdata: PCData;
  BEGIN
    NEW (pcdata);
    InitPCData (pcdata);
    RETURN pcdata
  END NewPCData;

PROCEDURE (pcdata: PCData) AddCharacters* (VAR chars: StringVar;
                                           charsStart, charsEnd: CharPos);
  BEGIN
    pcdata. chars. AddCharacters (chars, charsStart, charsEnd)
  END AddCharacters;

PROCEDURE (pcdata: PCData) Write* (writer: Writer.Writer);
  BEGIN
    writer. WriteI (pcdata. chars. array^, 0, pcdata. chars. length)
  END Write;

PROCEDURE (pcdata: PCData) Normalize* (stripLeadingWS, stripTrailingWS: BOOLEAN);
  VAR
    i, d, l: LONGINT;
    s: String;
  BEGIN
    i := 0; l := pcdata. chars. length; s := pcdata. chars. array;
    IF stripLeadingWS THEN
      WHILE (i < l) & (s[i] <= 32) DO
        INC (i)
      END
    END;
    d := i;
    WHILE (i < l) DO
      IF (s[i] <= 32) THEN
        s[i-d] := 32;
        INC (i);
        WHILE (i < l) & (s[i] <= 32) DO
          INC (i); INC (d)
        END
      ELSE
        s[i-d] := s[i]; INC (i)
      END
    END;
    IF stripTrailingWS & (i # d) & (s[i-d-1] = 32) THEN
      INC (d)
    END;
    s[i-d] := 0;
    pcdata. chars. length := i-d
  END Normalize;

END XMLBasicElement.
