MODULE testClient;
IMPORT Platform, Internet, Out;

VAR
  sock: Internet.Socket;
  str: ARRAY 256 OF CHAR; (* Ensure a large enough buffer *)
  i: INTEGER;
  b: BOOLEAN;
BEGIN
  IF Internet.Connect("127.0.0.1", "2023", sock) THEN
    Out.String("Client connected to server."); Out.Ln;
    IF Internet.Write(sock, "hello dave") THEN
      Out.String("written hello dave, reading answer"); Out.Ln;
      IF Internet.Read(sock, str) THEN
        Out.String("Client received from server: "); Out.String(str); Out.Ln;
      ELSE
        Out.String("Client failed to read from server."); Out.Ln;
      END;
    ELSE
      Out.String("Client failed to write to server."); Out.Ln;
    END;
    IF Internet.Write(sock, "bye") THEN
      Out.String("Sent 'bye' to server."); Out.Ln;
    END;
    Out.String("trying to disconnect"); Out.Ln;
    Internet.Disconnect(sock);
    Out.String("Client disconnected."); Out.Ln;
  ELSE
    Out.String("Client failed to connect to server."); Out.Ln;
  END;
END testClient.
