MODULE XmppWire;

(* A synchronous byte transport and channel writer. Implementations authenticate
   a specific service domain and own their socket, deadlines and TLS state. *)

IMPORT Channel, Msg, S := LongStrings, Items := XmppItems, J := XmppStrings;

TYPE
  Transport* = POINTER TO TransportDesc;
  TransportDesc* = RECORD (Channel.WriterDesc) END;
  Context = POINTER TO ContextDesc;
  ContextDesc = RECORD (Msg.ContextDesc) END;

VAR context: Context;

PROCEDURE (c: Context) GetTemplate(message: Msg.Msg; VAR text: Msg.LString);
BEGIN S.Long("XMPP transport operation failed", text) END GetTemplate;

PROCEDURE Error*(): Msg.Msg;
BEGIN RETURN Msg.New(context, 1) END Error;

PROCEDURE (t: Transport) Read*(VAR bytes: ARRAY OF CHAR; VAR count: LONGINT): BOOLEAN;
(* TRUE with count > 0 for data, TRUE with zero for clean EOF; FALSE on error. *)
BEGIN count := 0; t.res := Error(); RETURN FALSE END Read;

PROCEDURE (t: Transport) AuthenticatedFor*(domain: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN FALSE END AuthenticatedFor;

PROCEDURE (t: Transport) DomainName*(domain: ARRAY OF CHAR; VAR canonical: Items.Bytes): BOOLEAN;
(* Return a canonical UTF-8 service identity. The base profile accepts prepared
   ASCII names; native transports can supply validated internationalized names. *)
  VAR i: LONGINT;
BEGIN
  canonical := NIL; IF (S.Length8(domain) = 0) OR (S.Length8(domain) > 253) THEN RETURN FALSE END;
  canonical := Items.Copy8(domain);
  FOR i := 0 TO LEN(canonical^)-2 DO
    IF (canonical[i] >= "A") & (canonical[i] <= "Z") THEN canonical[i] := CHR(ORD(canonical[i])+32) END
  END;
  IF ~J.PreparedDomain8(canonical^) THEN canonical := NIL; RETURN FALSE END;
  RETURN TRUE
END DomainName;

PROCEDURE (t: Transport) StartTLS*(domain: ARRAY OF CHAR): BOOLEAN;
BEGIN t.res := Error(); RETURN FALSE END StartTLS;

PROCEDURE (t: Transport) Close*;
BEGIN END Close;

BEGIN
  NEW(context); Msg.InitContext(context, "XmppWire")
END XmppWire.
