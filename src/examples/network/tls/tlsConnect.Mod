MODULE tlsConnect;  (* tlsConnect host port: connect with TLS 1.3, report *)
IMPORT TLS13Live, Args, Out;
VAR host, port: ARRAY 256 OF CHAR; s: TLS13Live.State;
BEGIN
  Args.Get(1, host); Args.Get(2, port);
  IF TLS13Live.Connect(host, port, s) THEN Out.String("connected"); TLS13Live.Disconnect(s)
  ELSE Out.String("refused: "); Out.String(TLS13Live.lastError)
  END;
  Out.Ln
END tlsConnect.
