MODULE XmppStrings;

(* Splitting and joining UTF-16 JIDs. Indices count code units. Component
   preparation and IDNA processing belong to the session's address policy. *)

IMPORT S := LongStrings, T := XmppTypes;

PROCEDURE PreparedDomain8*(domain: ARRAY OF CHAR): BOOLEAN;
(* Lowercase ASCII DNS-label syntax used by the base transport policy.
   Internationalized identities are normalized by the native TCP transport. *)
  VAR i, count, length: LONGINT; byte: CHAR;
BEGIN
  length := S.Length8(domain); IF (length = 0) OR (length > 253) THEN RETURN FALSE END;
  count := 0;
  FOR i := 0 TO length-1 DO
    byte := domain[i];
    IF byte = "." THEN
      IF (count = 0) OR (domain[i-1] = "-") THEN RETURN FALSE END;
      count := 0
    ELSE
      IF ~(((byte >= "a") & (byte <= "z")) OR ((byte >= "0") & (byte <= "9")) OR (byte = "-")) THEN
        RETURN FALSE
      END;
      IF (count = 0) & (byte = "-") THEN RETURN FALSE END;
      INC(count); IF count > 63 THEN RETURN FALSE END
    END
  END;
  RETURN (count > 0) & (domain[length-1] # "-")
END PreparedDomain8;

PROCEDURE Bounds(jid: ARRAY OF T.CodeUnit; VAR at, slash, length: LONGINT): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  at := -1; length := S.Length(jid); slash := length; i := 0;
  WHILE i < length DO
    IF jid[i] = ORD("/") THEN slash := i; i := length
    ELSE
      IF jid[i] = ORD("@") THEN
        IF at >= 0 THEN RETURN FALSE END; at := i
      END;
      INC(i)
    END
  END;
  RETURN (slash > at+1) & (at # 0)
END Bounds;

PROCEDURE Slice(source: ARRAY OF T.CodeUnit; start, end: LONGINT;
                VAR dest: ARRAY OF T.CodeUnit): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  IF LEN(dest) = 0 THEN RETURN FALSE END;
  dest[0] := 0;
  IF end-start >= LEN(dest) THEN RETURN FALSE END;
  FOR i := start TO end-1 DO dest[i-start] := source[i] END;
  dest[end-start] := 0; RETURN TRUE
END Slice;

PROCEDURE ServerFromJid*(jid: ARRAY OF T.CodeUnit; VAR server: ARRAY OF T.CodeUnit; VAR res: LONGINT);
  VAR at, slash, length: LONGINT;
BEGIN
  res := -1; IF LEN(server) > 0 THEN server[0] := 0 END;
  IF Bounds(jid, at, slash, length) & Slice(jid, at+1, slash, server) THEN res := 0 END
END ServerFromJid;

PROCEDURE UsernameFromJid*(jid: ARRAY OF T.CodeUnit; VAR username: ARRAY OF T.CodeUnit; VAR res: LONGINT);
  VAR at, slash, length: LONGINT;
BEGIN
  res := -1; IF LEN(username) > 0 THEN username[0] := 0 END;
  IF Bounds(jid, at, slash, length) & (at > 0) & Slice(jid, 0, at, username) THEN res := 0 END
END UsernameFromJid;

PROCEDURE ResourceFromJid*(jid: ARRAY OF T.CodeUnit; VAR resource: ARRAY OF T.CodeUnit);
  VAR at, slash, length: LONGINT; copied: BOOLEAN;
BEGIN
  IF LEN(resource) > 0 THEN resource[0] := 0 END;
  IF Bounds(jid, at, slash, length) & (slash < length) THEN
    copied := Slice(jid, slash+1, length, resource)
  END
END ResourceFromJid;

PROCEDURE GetProjectNameFromFullJid*(jid: ARRAY OF T.CodeUnit; VAR name: ARRAY OF T.CodeUnit);
BEGIN ResourceFromJid(jid, name) END GetProjectNameFromFullJid;

PROCEDURE GetShortJidFromFullJid*(jid: ARRAY OF T.CodeUnit; VAR short: ARRAY OF T.CodeUnit);
  VAR at, slash, length: LONGINT; copied: BOOLEAN;
BEGIN
  IF LEN(short) > 0 THEN short[0] := 0 END;
  IF Bounds(jid, at, slash, length) THEN copied := Slice(jid, 0, slash, short) END
END GetShortJidFromFullJid;

PROCEDURE JidCorrect*(jid: ARRAY OF T.CodeUnit): BOOLEAN;
  VAR at, slash, length, i: LONGINT;
BEGIN
  IF ~Bounds(jid, at, slash, length) OR ((slash < length) & (slash+1 = length)) THEN RETURN FALSE END;
  i := 0;
  WHILE i < length DO
    IF (jid[i] < 32) OR (jid[i] > 0FFFFH) OR
       ((jid[i] = 32) & (i < slash)) OR (jid[i] = 127) THEN RETURN FALSE END;
    IF (jid[i] >= 0D800H) & (jid[i] <= 0DBFFH) THEN
      INC(i);
      IF (i = length) OR (jid[i] < 0DC00H) OR (jid[i] > 0DFFFH) THEN RETURN FALSE END
    ELSIF (jid[i] >= 0DC00H) & (jid[i] <= 0DFFFH) THEN RETURN FALSE
    END;
    INC(i)
  END;
  RETURN TRUE
END JidCorrect;

PROCEDURE Jid*(user, server, resource: ARRAY OF T.CodeUnit; VAR jid: ARRAY OF T.CodeUnit): BOOLEAN;
  VAR length, n, i: LONGINT;
BEGIN
  IF LEN(jid) = 0 THEN RETURN FALSE END;
  FOR i := 0 TO S.Length(user)-1 DO
    IF (user[i] = ORD("@")) OR (user[i] = ORD("/")) THEN jid[0] := 0; RETURN FALSE END
  END;
  FOR i := 0 TO S.Length(server)-1 DO
    IF (server[i] = ORD("@")) OR (server[i] = ORD("/")) THEN jid[0] := 0; RETURN FALSE END
  END;
  jid[0] := 0; length := S.Length(server); n := S.Length(user);
  IF n > 0 THEN INC(length, n+1) END;
  n := S.Length(resource); IF n > 0 THEN INC(length, n+1) END;
  IF (length >= LEN(jid)) OR (S.Length(server) = 0) THEN RETURN FALSE END;
  IF S.Length(user) > 0 THEN S.Assign(user, jid); S.Append8("@", jid) END;
  S.Append(server, jid);
  IF S.Length(resource) > 0 THEN S.Append8("/", jid); S.Append(resource, jid) END;
  IF ~JidCorrect(jid) THEN jid[0] := 0; RETURN FALSE END;
  RETURN TRUE
END Jid;

END XmppStrings.
