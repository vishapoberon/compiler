MODULE TLS13Random;
(* random bytes from /dev/urandom, through unixNet (of the Internet library in voc, over Linux0
   in polpo); replaces the ulmRandomGenerators filler, which was not cryptographically secure *)
IMPORT unixNet, SYSTEM;

(** buf[0..n) := n random bytes; FALSE if /dev/urandom cannot give them *)
PROCEDURE Fill*(VAR buf: ARRAY OF CHAR; n: LONGINT): BOOLEAN;
VAR fd, got, r: LONGINT; path: ARRAY 16 OF CHAR;
BEGIN
  IF (n < 0) OR (n > LEN(buf)) THEN RETURN FALSE END;
  IF n = 0 THEN RETURN TRUE END;
  path := "/dev/urandom";
  fd := unixNet.Openat0(unixNet.ATFDCWD, SYSTEM.ADR(path[0]), unixNet.ORDonly, 0);
  IF fd < 0 THEN RETURN FALSE END;
  got := 0; r := 1;
  WHILE (got < n) & (r > 0) DO
    r := unixNet.Read0(fd, SYSTEM.ADR(buf[got]), n - got);
    IF r > 0 THEN INC(got, r) END
  END;
  r := unixNet.Close0(fd);
  RETURN got = n
END Fill;

END TLS13Random.
