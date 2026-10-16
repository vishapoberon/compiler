MODULE fetch;  (* fetch url [file]: GET url (http or https), prints the status line and the body
  size; saves a complete body in file, else in the last part of the path (index.html for /) *)

IMPORT https, http, Args, Out, Platform;

VAR url, name: ARRAY 1024 OF CHAR; h: http.Client; i, j, k: LONGINT;

BEGIN
  IF Args.argc < 2 THEN Out.String("usage: fetch url [file]"); Out.Ln; Platform.Exit(1) END;
  Args.Get(1, url); Args.Get(2, name);
  IF ~https.Get(url, h) THEN Out.String("fetch: "); Out.String(url); Out.String(" failed"); Out.Ln; Platform.Exit(1) END;
  https.Report(h);
  IF ~h.rspnComplete THEN Out.String(": not saved"); Out.Ln; Platform.Exit(1) END;
  IF name = "" THEN  (* the last part of the path *)
    i := 0; j := 0;
    WHILE url[i] # 0X DO IF url[i] = "/" THEN j := i + 1 END; INC(i) END;
    k := j; i := 0; WHILE (url[j] # 0X) & (url[j] # "?") DO name[i] := url[j]; INC(i); INC(j) END;
    name[i] := 0X;
    IF (name = "") OR (k < 2) OR (url[k - 2] = "/") THEN COPY("index.html", name) END  (* no path *)
  END;
  IF https.Save(h, name) THEN Out.String(", saved in "); Out.String(name); Out.Ln
  ELSE Out.String(", cannot write "); Out.String(name); Out.Ln; Platform.Exit(1)
  END
END fetch.
