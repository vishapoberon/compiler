(* 	$Id: ServerBased.Mod,v 1.1.1.2 2000/07/10 20:31:53 mva Exp $	 *)
MODULE URIAuthorityServerBased;
(*  Implements class for registry-based authority components.
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
  IntStr, TextRider, CC := CharClass, URI,
  CharClass := URICharClass, String := URIString, Error := URIError;

CONST
  defaultPort = -1;

TYPE
  Port* = LONGINT;
  Authority* = POINTER TO AuthorityDesc;
  AuthorityDesc* = RECORD
  (**Server-based authority component of an URI.  *)
    (URI.AuthorityDesc)
    userinfo-: String.StringPtr;
    (**Userinfo from authority component.  @code{NIL} if no userinfo is
       given.  *)
    host-: String.StringPtr;
    (**Host part.  This is never @code{NIL}.  *)
    port-: Port;
    (**Port number.  If the port is part of the authority component, this
       field holds this number.  Otherwise, it is set to
       @ofield{defaultPort}.  *)
    defaultPort-: Port;
    (**Default port.  If the URI's authority component does not include a
       port number, this value is used instead.  *)
  END;


CONST
  illegalUserInfoChar = 1;
  malformedIPv4Address = 2;
  malformedHostName = 3;
  emptyHostName = 4;
  malformedPort = 5;
  portOutOfRange = 6;
  junkAfterAuthority = 7;
  
VAR
  serverContext: Error.Context;


PROCEDURE Init* (auth: Authority; userinfo, host: String.StringPtr; port, defaultPort: Port);
  BEGIN
    ASSERT (host # NIL);
    auth. userinfo := userinfo;
    auth. host := host;
    auth. port := port;
    auth. defaultPort := defaultPort
  END Init;

PROCEDURE New* (userinfo, host: String.StringPtr; port, defaultPort: Port): Authority;
(**Creates a new server-based authority component.  The arguments
   @oparam{userinfo}, @oparam{host}, @oparam{port}, and @oparam{defaultPort}
   are used to initialize the corresponding fields of a new instance of
   @otype{Authority}.

   @precond
   @oparam{host} must not be @code{NIL}.
   @end precond  *)
  VAR
    auth: Authority;
  BEGIN
    NEW (auth);
    Init (auth, userinfo, host, port, defaultPort);
    RETURN auth
  END New;

PROCEDURE (auth: Authority) Clone* (): URI.Authority;
  VAR
    copy: Authority;
  BEGIN
    NEW (copy);
    auth. Copy (copy);
    RETURN copy
  END Clone;

PROCEDURE (auth: Authority) Copy* (dest: URI.Authority);
  BEGIN
    (*auth. Copy^ (dest); procedure is abstract in super class *)
    WITH dest: Authority DO
      IF (auth. userinfo # NIL) THEN
        dest. userinfo := String.Copy (auth. userinfo^)
      ELSE
        dest. userinfo := NIL
      END;
      IF (auth. host # NIL) THEN
        dest. host := String.Copy (auth. host^)
      ELSE
        dest. host := NIL
      END;
      dest. port := auth. port;
      dest. defaultPort := auth. defaultPort
    END
  END Copy;

PROCEDURE ParseHost (str: URI.StringPtr; offset: URI.Offset): Error.Msg;
  VAR
    i, j, lastLabelStart: URI.Offset;
    
  PROCEDURE IsIPv4Address (str: URI.StringPtr): BOOLEAN;
    VAR
      i: URI.Offset;
    BEGIN
      i := 0;
      WHILE (str[i] # 0X) DO
        IF ~CharClass.IsDigit (str[i]) & (str[i] # ".") THEN
          RETURN FALSE
        END;
        INC (i)
      END;
      RETURN TRUE
    END IsIPv4Address;
  
  PROCEDURE SkipDigits (): BOOLEAN;
    VAR
      start, val: LONGINT;
    BEGIN
      IF CharClass.IsDigit (str[i]) &
         ((str[i] # "0") OR ~CharClass.IsDigit (str[i+1])) THEN
        start := i;
        val := 0;
        REPEAT
          IF (val < 1000) THEN
            val := val*10 + ORD(str[i])-ORD("0")
          END;
          INC (i)
        UNTIL ~CharClass.IsDigit (str[i]);
        IF (val > 255) THEN
          i := start                     (* fix error position, return FALSE *)
        ELSE
          RETURN TRUE
        END
      END;
      RETURN FALSE
    END SkipDigits;
  
  PROCEDURE SkipLabel(): BOOLEAN;
    BEGIN
      IF CharClass.IsAlpha (str[i]) THEN
        REPEAT
          INC (i)
        UNTIL ~CharClass.IsAlphaNum (str[i]) & (str[i] # "-");
        IF ~CharClass.IsAlphaNum (str[i-1]) THEN
          DEC (i)                        (* fix error pos and return FALSE *)
        ELSE
          RETURN TRUE
        END
      END;
      RETURN FALSE
    END SkipLabel;
  
  BEGIN
    i := 0;
    IF IsIPv4Address (str) THEN
      FOR j := 1 TO 4 DO
        IF ~SkipDigits() THEN
          RETURN Error.New (serverContext, malformedIPv4Address, i+offset)
        END;
        IF (j < 4) THEN
          IF (str[i] = ".") THEN
            INC (i)
          ELSE
            RETURN Error.New (serverContext, malformedIPv4Address, i+offset)
          END
        END
      END
    ELSE
      LOOP
        lastLabelStart := i;
        IF ~SkipLabel() THEN
          RETURN Error.New (serverContext, malformedIPv4Address, i+offset)
        END;
        IF (str[i] = ".") THEN
          INC (i);
          IF (str[i] = 0X) OR (str[i] = ":") THEN
            EXIT
          END
        ELSE
          EXIT
        END
      END;
      IF ~CharClass.IsAlpha (str[lastLabelStart]) THEN
        RETURN Error.New (serverContext, malformedHostName, i+offset)
      END
    END;
    IF str[i] # 0X THEN
      RETURN Error.New (serverContext, malformedHostName, i+offset)
    END;
    RETURN NIL
  END ParseHost;

PROCEDURE (auth: Authority) ParseAuthority* (str: URI.StringPtr; offset: URI.Offset): Error.Msg;
  VAR
    i, start: LONGINT;
    res: Error.Msg;
    userinfo, host: String.StringPtr;
    port: LONGINT;
  BEGIN
    i := 0;
    WHILE (str[i] # 0X) & (str[i] # "@") DO
      INC (i)
    END;
    
    userinfo := NIL;
    IF (str[i] # 0X) THEN
      (* the authority component includes a user info part *)
      i := 0;
      WHILE CharClass.SkipUnreserved (str^, i) OR
            CharClass.SkipEscaped (str^, i) OR
            CharClass.SkipMember (str^, i, ";:&=+$,") DO
      END;
      IF (str[i] = "@") THEN
        userinfo := String.Unescape (String.Extract (str^, 0, i));
        INC (i)
      ELSE
        RETURN Error.New (serverContext, illegalUserInfoChar, i+offset)
      END
    ELSE                                 (* no user info *)
      i := 0
    END;
    
    start := i;
    WHILE (str[i] # 0X) & (str[i] # ":") DO
      INC (i)
    END;
    IF (i = start) THEN
      RETURN Error.New (serverContext, emptyHostName, i+offset)
    ELSE
      host := String.Extract (str^, start, i);
      res := ParseHost (host, offset+start);
      IF (res # NIL) THEN
        RETURN res
      END
    END;
    
    port := defaultPort;
    IF (str[i] = ":") THEN
      INC (i);
      start := i;
      IF (str[i] # 0X) THEN
        port := 0;
        WHILE CharClass.IsDigit (str[i]) DO
          IF (port < 1000000) THEN
            port := port*10+ORD(str[i])-ORD("0")
          END;
          INC (i)
        END;
        IF (port > 65535) THEN
          RETURN Error.New (serverContext, portOutOfRange, start+offset)
        END
      END
    END;
    
    IF (str[i] # 0X) THEN
      RETURN Error.New (serverContext, junkAfterAuthority, i+offset)
    END;
    
    auth. userinfo := userinfo;
    auth. host := host;
    IF (port = defaultPort) THEN
      auth. port := auth. defaultPort
    ELSE
      auth. port := port
    END;
    RETURN NIL
  END ParseAuthority;

PROCEDURE (auth: Authority) WriteXML* (w: TextRider.Writer);
  VAR
    str: ARRAY 32 OF CHAR;
  BEGIN
    w. WriteChar (CC.eol); w. WriteString ("<authority-server-based>");
    IF (auth. userinfo # NIL) THEN
      w. WriteChar (CC.eol); w. WriteString ("<userinfo>");
      w. WriteString (auth. userinfo^);
      w. WriteString ("</userinfo>");
    END;
    w. WriteChar (CC.eol); w. WriteString ("<host>");
    w. WriteString (auth. host^);
    w. WriteString ("</host>");
    IF (auth. port >= 0) THEN
      w. WriteChar (CC.eol); w. WriteString ("<port>");
      IntStr.IntToStr (auth. port, str);
      w. WriteString (str);
      w. WriteString ("</port>");
    END;
    w. WriteChar (CC.eol); w. WriteString ("</authority-server-based>");
  END WriteXML;

PROCEDURE (auth: Authority) Append* (VAR str: ARRAY OF CHAR);
  VAR
    s: ARRAY 32 OF CHAR;
  BEGIN
    String.Append ("//", str);
    IF (auth. userinfo # NIL) THEN
      String.AppendEscaped (auth. userinfo^, CharClass.unreservedUserinfo, str);
      String.Append ("@", str)
    END;
    String.Append (auth. host^, str);
    IF (auth. port >= 0) & (auth. port # auth. defaultPort) THEN
      String.Append (":", str);
      IntStr.IntToStr (auth. port, s);
      String.Append (s, str)
    END
  END Append;

BEGIN
  serverContext := Error.NewContext ("URI:Authority:ServerBased");
  serverContext. SetString (illegalUserInfoChar,
    "Illegal character in user info part of authority component");
  serverContext. SetString (malformedIPv4Address,
    "Malformed IPv4 address in authority component");
  serverContext. SetString (malformedHostName,
    "Malformed host name in authority component");
  serverContext. SetString (emptyHostName,
    "Host name in authority component is empty");
  serverContext. SetString (malformedPort,
    "Malformed port number in authority component");
  serverContext. SetString (portOutOfRange,
    "Port number out of range in authority component");
  serverContext. SetString (junkAfterAuthority,
    "Junk after authority component");
END URIAuthorityServerBased.
