MODULE TLSNameConstraints;
(* The nameConstraints of a CA certificate (RFC 5280, 4.2.1.10) against the names of a leaf
   certificate below it: its subjectAltName dNSName and iPAddress entries and its subject
   (directoryName). A name of a form with permitted subtrees must lie in one of them; no name
   may lie in an excluded subtree. dNSName: the domain and its subdomains, case insensitive
   (".example.com": only subdomains); a wildcard name is refused if an excluded subtree lies
   within it. iPAddress: address and mask. directoryName: the subtree is a prefix of the
   subject, compared RDN by RDN (as encoded). A form we do not check (rfc822Name, URI, ...)
   with constraints, when the leaf has names of that form, refuses the leaf. *)
IMPORT TLSBytes, TLSASN1, TLSX509, TLSX509Names;

CONST
  DNS = 82H; IP = 87H; Dir = 0A4H;  (* GeneralName tags: [2], [7], [4] constructed *)
  Permitted = 0A0H; Excluded = 0A1H;

PROCEDURE Lower(ch: CHAR): CHAR;
BEGIN
  IF (ch >= "A") & (ch <= "Z") THEN ch := CHR(ORD(ch) + 32) END;
  RETURN ch
END Lower;

(* name[from..name.len) ends with c[cfrom..c.len) (case insensitive) *)
PROCEDURE EndsWith(VAR name: TLSBytes.Buffer; from: LONGINT; VAR c: TLSBytes.Buffer; cfrom: LONGINT): BOOLEAN;
VAR i, j: LONGINT;
BEGIN
  IF name.len - from < c.len - cfrom THEN RETURN FALSE END;
  i := name.len - 1; j := c.len - 1;
  WHILE j >= cfrom DO
    IF Lower(name.data[i]) # Lower(c.data[j]) THEN RETURN FALSE END;
    DEC(i); DEC(j)
  END;
  RETURN TRUE
END EndsWith;

(* the DNS name name[from..) lies in the subtree c *)
PROCEDURE DNSWithin(VAR name: TLSBytes.Buffer; from: LONGINT; VAR c: TLSBytes.Buffer): BOOLEAN;
VAR n: LONGINT;
BEGIN
  IF c.len = 0 THEN RETURN TRUE END;
  n := name.len - from;
  IF c.data[0] = "." THEN RETURN (n > c.len) & EndsWith(name, from, c, 0) END;  (* subdomains only *)
  IF n = c.len THEN RETURN EndsWith(name, from, c, 0) END;
  RETURN (n > c.len) & (name.data[name.len - c.len - 1] = ".") & EndsWith(name, from, c, 0)
END DNSWithin;

(* a AND b, for bytes *)
PROCEDURE And8(a, b: LONGINT): LONGINT;
VAR r, bit, i: LONGINT;
BEGIN
  r := 0; bit := 1; i := 0;
  WHILE i < 8 DO
    IF ODD(a) & ODD(b) THEN INC(r, bit) END;
    a := a DIV 2; b := b DIV 2; bit := bit * 2; INC(i)
  END;
  RETURN r
END And8;

(* the address ip (4 or 16 bytes) lies in c: address and mask (8 or 32 bytes) *)
PROCEDURE IPWithin(VAR ip, c: TLSBytes.Buffer): BOOLEAN;
VAR i, n, a, m, b: LONGINT;
BEGIN
  n := ip.len;
  IF c.len # 2 * n THEN RETURN FALSE END;
  i := 0;
  WHILE i < n DO
    a := ORD(ip.data[i]); b := ORD(c.data[i]); m := ORD(c.data[n + i]);
    IF And8(a, m) # And8(b, m) THEN RETURN FALSE END;
    INC(i)
  END;
  RETURN TRUE
END IPWithin;

(* the Name subject (DER) starts with the RDNs of the Name c (DER) *)
PROCEDURE DirWithin(VAR subject, c: TLSBytes.Buffer): BOOLEAN;
VAR sp, sl, cp, cl, i: LONGINT; st, ct: TLSASN1.TLV;
BEGIN
  sp := 0; cp := 0;
  IF ~TLSASN1.EnterSequence(subject, sp, subject.len, sp, sl) OR ~TLSASN1.EnterSequence(c, cp, c.len, cp, cl) THEN RETURN FALSE END;
  WHILE cp < cl DO
    IF (sp >= sl) OR ~TLSASN1.ReadTLV(c, cp, cl, ct) OR ~TLSASN1.ReadTLV(subject, sp, sl, st) THEN RETURN FALSE END;
    IF ct.next - ct.hdr # st.next - st.hdr THEN RETURN FALSE END;
    i := 0;
    WHILE i < ct.next - ct.hdr DO
      IF c.data[ct.hdr + i] # subject.data[st.hdr + i] THEN RETURN FALSE END;
      INC(i)
    END
  END;
  RETURN TRUE
END DirWithin;

(* name (of the form tag) lies in the subtree base (a GeneralName TLV in nc), or overlaps it
   (wildcards, for excluded subtrees) *)
PROCEDURE Within(tag: LONGINT; VAR name: TLSBytes.Buffer; VAR nc: TLSBytes.Buffer; VAR base: TLSASN1.TLV; excluded: BOOLEAN): BOOLEAN;
VAR c, d: TLSBytes.Buffer; wild: BOOLEAN;
BEGIN
  IF ~TLSASN1.CopyValue(nc, base, c) THEN RETURN FALSE END;
  IF tag = DNS THEN
    wild := (name.len > 2) & (name.data[0] = "*") & (name.data[1] = ".");
    IF DNSWithin(name, 0, c) THEN RETURN TRUE END;
    IF excluded & wild THEN  (* c within the domain of *.D *)
      TLSBytes.Slice(name, 2, name.len - 2, d);
      RETURN DNSWithin(c, 0, d)
    END;
    RETURN FALSE
  ELSIF tag = IP THEN RETURN IPWithin(name, c)
  ELSE (* Dir: c is the explicit [4]: its content is a Name *)
    RETURN DirWithin(name, c)
  END
END Within;

(* the subtrees of kind (Permitted, Excluded) in nc: has: one of the form tag exists; in: name
   lies in (overlaps, for Excluded) one of them; FALSE if malformed *)
PROCEDURE Scan(VAR nc: TLSBytes.Buffer; kind, tag: LONGINT; VAR name: TLSBytes.Buffer; check: BOOLEAN; VAR has, in: BOOLEAN): BOOLEAN;
VAR pos, lim, tp, tl, sp, sl: LONGINT; t, sub, base: TLSASN1.TLV;
BEGIN
  has := FALSE; in := FALSE; pos := 0;
  IF ~TLSASN1.EnterSequence(nc, pos, nc.len, pos, lim) THEN RETURN FALSE END;
  WHILE pos < lim DO
    IF ~TLSASN1.ReadTLV(nc, pos, lim, t) OR (t.tag # Permitted) & (t.tag # Excluded) THEN RETURN FALSE END;
    IF t.tag = kind THEN
      tp := t.val; tl := t.next;
      IF tp >= tl THEN RETURN FALSE END;  (* GeneralSubtrees: at least one *)
      WHILE tp < tl DO
        IF ~TLSASN1.ReadTLV(nc, tp, tl, sub) OR (sub.tag # TLSASN1.Sequence) THEN RETURN FALSE END;
        sp := sub.val; sl := sub.next;
        IF ~TLSASN1.ReadTLV(nc, sp, sl, base) OR (sp # sl) THEN RETURN FALSE END;  (* minimum 0, no maximum *)
        IF base.tag = tag THEN
          has := TRUE;
          IF check & ~in & Within(tag, name, nc, base, kind = Excluded) THEN in := TRUE END
        END
      END
    END
  END;
  RETURN TRUE
END Scan;

(* the name of the form tag passes nc *)
PROCEDURE NameOK(VAR nc: TLSBytes.Buffer; tag: LONGINT; VAR name: TLSBytes.Buffer): BOOLEAN;
VAR has, in: BOOLEAN;
BEGIN
  IF ~Scan(nc, Permitted, tag, name, TRUE, has, in) OR has & ~in THEN RETURN FALSE END;
  RETURN Scan(nc, Excluded, tag, name, TRUE, has, in) & ~in
END NameOK;

(* there are no constraints on the form tag in nc *)
PROCEDURE Unconstrained(VAR nc: TLSBytes.Buffer; tag: LONGINT): BOOLEAN;
VAR has1, has2, in: BOOLEAN; none: TLSBytes.Buffer;
BEGIN
  TLSBytes.Init(none);
  RETURN Scan(nc, Permitted, tag, none, FALSE, has1, in) & Scan(nc, Excluded, tag, none, FALSE, has2, in) & ~has1 & ~has2
END Unconstrained;

(** the names of leaf pass the nameConstraints value nc of a CA above it; FALSE also if nc is
  malformed *)
PROCEDURE Permit*(VAR nc: TLSBytes.Buffer; VAR leaf: TLSX509.CertInfo): BOOLEAN;
VAR san, name: TLSBytes.Buffer; pos, lim, sl: LONGINT; t: TLSASN1.TLV; has, in: BOOLEAN;
BEGIN
  IF ~Scan(nc, Permitted, -1, name, FALSE, has, in) OR ~Scan(nc, Excluded, -1, name, FALSE, has, in) THEN RETURN FALSE END;
  (* the subject: a directoryName, unless it is empty *)
  pos := 0;
  IF ~TLSASN1.EnterSequence(leaf.subject, pos, leaf.subject.len, pos, sl) THEN RETURN FALSE END;
  IF (pos < sl) & ~NameOK(nc, Dir, leaf.subject) THEN RETURN FALSE END;
  IF TLSX509Names.SubjectAltNameValue(leaf, san) THEN
    pos := 0;
    IF ~TLSASN1.EnterSequence(san, pos, san.len, pos, lim) THEN RETURN FALSE END;
    WHILE pos < lim DO
      IF ~TLSASN1.ReadTLV(san, pos, lim, t) THEN RETURN FALSE END;
      IF (t.tag = DNS) OR (t.tag = IP) OR (t.tag = Dir) THEN
        IF ~TLSASN1.CopyValue(san, t, name) THEN RETURN FALSE END;  (* [4]: a Name *)
        IF (t.tag = IP) & (name.len # 4) & (name.len # 16) THEN RETURN FALSE END;
        IF ~NameOK(nc, t.tag, name) THEN RETURN FALSE END
      ELSIF ~Unconstrained(nc, t.tag) THEN
        RETURN FALSE  (* a form we do not check, constrained *)
      END
    END
  END;
  RETURN TRUE
END Permit;

END TLSNameConstraints.
