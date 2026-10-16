MODULE TLS13Random;
(* random bytes from /dev/urandom, through Linux0 (polpo's, or the one of the voc Internet
   module); replaces the ulmRandomGenerators filler, which was not cryptographically secure *)
IMPORT Linux0 := unixNet, SYSTEM;

(** buf[0..n) := n random bytes; FALSE if /dev/urandom cannot give them *)
PROCEDURE Fill*(VAR buf: ARRAY OF CHAR; n: LONGINT): BOOLEAN;
VAR fd, got, r: LONGINT; path: ARRAY 16 OF CHAR;
BEGIN
  IF (n < 0) OR (n > LEN(buf)) THEN RETURN FALSE END;
  IF n = 0 THEN RETURN TRUE END;
  path := "/dev/urandom";
  fd := Linux0.Openat0(Linux0.ATFDCWD, SYSTEM.ADR(path[0]), Linux0.ORDonly, 0);
  IF fd < 0 THEN RETURN FALSE END;
  got := 0; r := 1;
  WHILE (got < n) & (r > 0) DO
    r := Linux0.Read0(fd, SYSTEM.ADR(buf[got]), n - got);
    IF r > 0 THEN INC(got, r) END
  END;
  r := Linux0.Close0(fd);
  RETURN got = n
END Fill;

END TLS13Random.
