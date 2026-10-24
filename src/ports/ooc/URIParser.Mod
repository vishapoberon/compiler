(* 	$Id: Parser.Mod,v 1.1.1.2 2000/07/10 20:31:52 mva Exp $	 *)
MODULE URIParser;
(*  Implements the URI parser.
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
  URI, Error := URIError, CharClass := URICharClass, Str := URIString,
  Hierarchical := URISchemeHierarchical, Opaque := URISchemeOpaque,
  CurrentDoc := URISchemeCurrentDoc;


CONST                                    (* error codes *)
  illegalSchemeChar = 1;
  expectedHierarchicalPath = 2;
  expectedOpaquePart = 3;
  authorityNotSupported = 4;
  queryNotSupported = 5;
  junkAfterURI = 6;
  absoluteWithoutPath = 7;
  emptyOpaquePart = 8;
  invalidRelativeReference = 9;

VAR
  uriContext: Error.Context;
  defaultHierarchical: URI.HierarchicalURI;
  defaultOpaque: URI.OpaqueURI;


PROCEDURE NewURI* (str: URI.String; baseURI: URI.HierarchicalURI;
                   VAR res: Error.Msg): URI.URI;
(**Parses the string in @oparam{str} and creates a new URI object.  If the
   string is a relative URI, the URI is made absolute in relation to
   @oparam{baseURI}.  It is an error, if a relative URI string is given and
   @oparam{baseURI} is @code{NIL}.  On failure, result is @code{NIL} and
   @oparam{res} is changed to indicate the problem.  *)
   
(* use baseURI and resolve immediately, or delay this until later? ... *)
  VAR
    i, start, endOfScheme: Str.Offset;
    schemeId, substr: Str.StringPtr;
    uri, protoURI: URI.URI;
    hierURI: URI.HierarchicalURI;
  
  PROCEDURE Err (code: Error.Code);
    BEGIN
      res := Error.New (uriContext, code, i);
      Error.SetURIString (res, str)
    END Err;
  
  PROCEDURE Path (absolute: BOOLEAN);
    VAR
      start: Str.Offset;
      substr: Str.StringPtr;
    BEGIN  (* pre: ~absolute OR (str[i] = "/") *)
      IF absolute THEN
        INC (i)
      END;
      start := i;
      WHILE (str[i] # "?") & (str[i] # "#") & (str[i] # 0X) DO
        INC (i)
      END;
      substr := Str.Extract (str, start, i);
       res := hierURI. ParsePath (substr, absolute, start)
    END Path;
  
  BEGIN
    res := NIL; i := 0;
    IF Str.Length (str) = LEN (str) THEN
      res := Error.New (uriContext, junkAfterURI, i); RETURN NIL
    END;
    IF (str = "") THEN
      RETURN CurrentDoc.New()
    END;
    
    (* isolate scheme component of URI *)
    schemeId := NIL; protoURI := NIL;
    i := 0;
    WHILE (str[i] # ":") & (str[i] # "/") &
          (str[i] # "?") & (str[i] # "#") & (str[i] # 0X) DO
      INC (i)
    END;
    IF (str[i] = ":") & (i # 0) THEN     (* scheme is given *)
      endOfScheme := i;
      (* we got an absolute URI, because a non-empty scheme name is given;
         check if the characters before the ":" are valid *)
      i := 0;
      IF CharClass.SkipAlpha (str, i) THEN
        WHILE CharClass.SkipAlphaNum (str, i) OR
              CharClass.SkipMember (str, i, "+-.") DO
        END
      END;
      IF (i = endOfScheme) THEN          (* all characters valid *)
        schemeId := Str.Extract (str, 0, i);
        INC (i);
        protoURI := URI.GetScheme (schemeId)
      ELSE                               (* `i' refers to the illegal char *)
        Err (illegalSchemeChar); RETURN NIL
      END
    ELSE
      i := 0
    END;
    
    IF (schemeId = NIL) THEN
      IF (baseURI = NIL) THEN
        Err (invalidRelativeReference); RETURN NIL
      ELSE
        protoURI := baseURI
      END
    END;
    
    uri := NIL; hierURI := NIL; res := NIL;
    IF (schemeId = NIL) OR (str[i] = "/") OR
       (protoURI # NIL) & (protoURI IS URI.HierarchicalURI) THEN
      (* absolute or relative URI, with hierarchical path *)
      IF (protoURI = NIL) THEN
        protoURI := defaultHierarchical
      ELSIF ~(protoURI IS URI.HierarchicalURI) THEN
        Err (expectedHierarchicalPath); RETURN NIL
      END;

      uri := protoURI. Clone();
      uri. SetSchemeId (schemeId);
      hierURI := uri(URI.HierarchicalURI);
      IF (str[i] = "/") & (str[i+1] = "/") THEN
        hierURI. SetAuthority (hierURI. NewAuthority());
        IF (hierURI. authority = NIL) THEN
          Err (authorityNotSupported)
        ELSE
          (* path includes an authority component; extract authority
             substring and hand it over to the prototype URI's authority
             parser *)
          INC (i, 2);
          start := i;
          WHILE (str[i] # "/") & (str[i] # "?") &
                (str[i] # "#") & (str[i] # 0X) DO
            INC (i)
          END;
          substr := Str.Extract (str, start, i);
          res := hierURI. authority. ParseAuthority (substr, start);
          
          IF (res = NIL) & (str[i] = "/") THEN
            Path (TRUE)
          ELSE
            hierURI. ClearPath
          END
        END
      ELSE
        hierURI. SetAuthority (NIL);
        IF (str[i] = "/") THEN
          Path (TRUE)
        ELSIF (schemeId # NIL) THEN
          Err (absoluteWithoutPath)
        ELSE                             (* relative URI *)
          Path (FALSE)
        END
      END;
      
      (* check for query component *)
      IF (res = NIL) & (str[i] = "?") THEN
        hierURI. SetQuery (hierURI. NewQuery());
        IF (hierURI. query = NIL) THEN
          Err (queryNotSupported)
        ELSE
          INC (i);
          start := i;
          WHILE (str[i] # "#") & (str[i] # 0X) DO
            INC (i)
          END;
          substr := Str.Extract (str, start, i);
          res := hierURI. query. ParseQuery (substr, start)
        END
      ELSE
        hierURI. SetQuery (NIL)
      END;
      
      IF (schemeId = NIL) THEN
        hierURI. ResolveRelative (baseURI)
      END
    ELSE  (* (schemeId # NIL) & (str[i] # "/") *)
      (* absolute URI with opaque path component *)
      IF (str[i] = 0X) THEN
        Err (emptyOpaquePart); RETURN NIL
      END;

      IF (protoURI = NIL) THEN
        protoURI := defaultOpaque
      ELSIF ~(protoURI IS URI.OpaqueURI) THEN
        Err (expectedOpaquePart); RETURN NIL
      END;
      
      uri := protoURI. Clone();
      uri. SetSchemeId (schemeId);
      substr := Str.Extract (str, i, Str.Length (str));
      res := uri(URI.OpaqueURI). ParseOpaquePart (substr, i);
      i := Str.Length (str)
    END;
    
    IF (res = NIL) & (str[i] # 0X) THEN
      Err (junkAfterURI)
    END;
    
    IF (res = NIL) THEN
      RETURN uri
    ELSE
      Error.SetURIString (res, str);
      RETURN NIL
    END
  END NewURI;

PROCEDURE NewReference* (str: URI.String; baseURI: URI.HierarchicalURI;
                         fragmentPrototype: URI.Fragment;
                         VAR res: Error.Msg): URI.Reference;
(**Like @oproc{NewURI}, but parses a URI reference in @oparam{str}.  The
   instance @oparam{fragmentPrototype} is used to parse the fragment identifier
   of the URI.  The format of the fragment identifier is not related to the
   URI.  The application must know what to expect, and provide a matching
   @otype{URI.Fragment} prototype, to which the parser delegates analysis of
   the fragment identifier.  *)
  VAR
    i: URI.Offset;
    uri: URI.URI;
    fragment: URI.Fragment;
    substr: URI.StringPtr;
    ch: CHAR;
  BEGIN
    i := 0;
    IF Str.Length (str) = LEN (str) THEN
      res := Error.New (uriContext, junkAfterURI, i);
      RETURN NIL
    END;
    WHILE (str[i] # 0X) & (str[i] # "#") DO
      INC (i)
    END;
    
    ch := str[i];
    str[i] := 0X;
    uri := NewURI (str, baseURI, res);
    str[i] := ch;
    
    IF (res = NIL) THEN                  (* no error while parsing URI *)
      IF (ch = 0X) THEN                  (* no fragment identifier *)
        RETURN URI.NewReference (uri, NIL)
      ELSE
        fragment := fragmentPrototype. Clone();
        substr := Str.Extract (str, i+1, Str.Length (str));
        res := fragment. ParseFragment (substr, i+1);
        IF (res = NIL) THEN
          RETURN URI.NewReference (uri, fragment)
        ELSE
          Error.SetURIString (res, str);
          RETURN NIL
        END
      END
    ELSE
      RETURN NIL
    END
  END NewReference;


BEGIN
  defaultHierarchical := Hierarchical.New (NIL, NIL, NIL);
  defaultOpaque := Opaque.New (NIL, Str.Copy (""));
  
  uriContext := Error.NewContext ("URI:Parser");
  uriContext. SetString (illegalSchemeChar,
    "Illegal character in scheme component");
  uriContext. SetString (expectedHierarchicalPath,
    "Expected absolute or net path beginning with a slash `/'");
  uriContext. SetString (expectedOpaquePart,
    "Expected opaque URI component, not a slash `/'");
  uriContext. SetString (authorityNotSupported,
    "This URI scheme does not support an authority component");
  uriContext. SetString (queryNotSupported,
    "This URI scheme does not support a query component");
  uriContext. SetString (junkAfterURI,
    "Junk after URI");
  uriContext. SetString (absoluteWithoutPath,
    "The URI scheme name must be followed by a slash `/'");
  uriContext. SetString (emptyOpaquePart,
    "The opaque part of an URI must not be empty");
  uriContext. SetString (invalidRelativeReference,
    "Cannot resolve relative URI reference without known base URI");
END URIParser.
