MODULE testServer;
IMPORT server, Internet, unixNet, Out, Platform, SYSTEM;

VAR s: server.server;

(* seconds since 1970 *)
PROCEDURE Now(): LONGREAL;
VAR tv: ARRAY 2 OF LONGINT; r: LONGINT;
BEGIN
  r := unixNet.GetTimeOfDay(SYSTEM.ADR(tv), 0);
  RETURN tv[0] + tv[1] / 1000000.0
END Now;

PROCEDURE DoSmth(VAR s: server.server);
VAR
  str, aff: ARRAY 256 OF CHAR;
  n: LONGINT;
  startTime, endTime: LONGREAL;
  dfTime: LONGREAL;
  keep: BOOLEAN;
  i: INTEGER; (* Declare 'i' *)
BEGIN
  keep := TRUE;
  startTime := Now();
  aff := "Affirmative, Dave";
  REPEAT
    Out.String("Server waiting for client message..."); Out.Ln;

    (* Clear the buffer before reading *)
    FOR i := 0 TO LEN(str) - 1 DO
      str[i] := 0X;
    END;

    IF ~Internet.ReadBuf(s^.newsockfd, str, n) THEN
      Out.String("ReadBuf() failed or no data available."); Out.Ln;
      endTime := Now();
    ELSE
      startTime := Now();
      Out.String("Server got message from client"); Out.Ln;

      IF n > 0 THEN
        str[n] := 0X; (* Ensure the received message is zero-terminated *)
        Out.String("Server received message: '"); Out.String(str); Out.Char("'"); Out.Ln;

        IF str = "bye" THEN
          keep := FALSE;
        ELSE
          IF ~Internet.Write(s^.newsockfd, aff) THEN
            Out.String("Server error writing to socket"); Out.Ln;
          END;
        END;
      ELSE
        Out.String("No meaningful data received."); Out.Ln;

        (* Check if this indicates the client has closed the connection *)
        keep := FALSE;  (* Terminate the loop if no data is read *)
      END;
    END;

    endTime := Now();
    dfTime := endTime - startTime;
    IF dfTime > s.timeoutval THEN keep := FALSE END;
    Platform.Delay(500);
  UNTIL ~keep;

  Out.String("Server: Connection closed, exiting."); Out.Ln;
  Internet.Disconnect(s^.newsockfd);
  Out.String("Server: Disconnected."); Out.Ln; Out.Ln;
  HALT(0);

END DoSmth;

BEGIN
s := server.Create();
server.setPort(s, 2023);
server.setListenOn(s, "127.0.0.1");
server.setMaxQueue(s, 5);
server.setTimeOut(s, 10.0);
server.setHandler(s, DoSmth);

server.start(s);
server.serve(s, TRUE);

END testServer.
