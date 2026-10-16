MODULE TestNetworkClient;
IMPORT Args, https, http, strTypes, Out;
VAR url, mode, number: ARRAY 1024 OF CHAR; h: http.Client;
  body: strTypes.pstring; n, i: LONGINT;
BEGIN
  Args.Get(1, url); Args.Get(2, mode); Args.Get(3, number);
  n := 0; i := 0;
  WHILE (number[i] >= "0") & (number[i] <= "9") DO
    n := n * 10 + ORD(number[i]) - ORD("0"); INC(i)
  END;
  h := https.Create(url); ASSERT(h # NIL);
  IF mode = "auth" THEN http.appendUserPasswdHdr(h, "user", "password") END;
  body := h.Get(h);
  IF mode = "refused" THEN ASSERT(h.rspnFirstLine = NIL)
  ELSE
    ASSERT(h.rspnCode = 200);
    ASSERT(h.rspnComplete = (mode # "incomplete"));
    ASSERT(h.rspnContentLength = n);
    ASSERT(body # NIL);
    i := 0;
    WHILE i < n DO ASSERT(ORD(body[i]) = (i * 7 + i DIV 251) MOD 256); INC(i) END
  END;
  Out.String("network client passed"); Out.Ln
END TestNetworkClient.
