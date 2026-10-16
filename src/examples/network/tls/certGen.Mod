MODULE certGen;  (* certGen cn [mail] [dns]: prints a new self-signed certificate and its key (PEM) *)
IMPORT TLSCertGen, Args, Out;
VAR cn, mail, dns: ARRAY 256 OF CHAR; c, k: ARRAY 4096 OF CHAR;
BEGIN
  Args.Get(1, cn); Args.Get(2, mail); Args.Get(3, dns);
  IF TLSCertGen.SelfSigned(cn, mail, dns, 100, c, k) THEN Out.String(c); Out.String(k)
  ELSE Out.String(TLSCertGen.lastError); Out.Ln
  END
END certGen.
