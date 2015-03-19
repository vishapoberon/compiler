MODULE s;

IMPORT sockets, types, Out := Console, Unix, S := SYSTEM;

TYPE Int32 = types.Int32;
     Int16 = types.Int16;
     String = types.String;

PROCEDURE DoSmth(sock : Int32);
VAR str, aff : String;
    n, s : LONGINT;
BEGIN
   s := SIZE(String);
   aff := "Affirmative, Dave";
   n := Unix.Read(sock, S.ADR(str), s);

   IF n < 0 THEN
      Out.String("error reading from socket"); Out.Ln;
   END;
   Out.String("received message is "); Out.String(str); Out.Ln;
   s := 17;
   n := Unix.Write(sock, S.ADR(aff), s);
   IF n < 2 THEN
      Out.String("error writing to socket"); Out.Ln
   END;
      
END DoSmth;

PROCEDURE ZeroByteArr(VAR a : ARRAY OF S.BYTE);
VAR i : LONGINT;
BEGIN
   FOR i := 0 TO LEN(a)-1 DO
      a[i] := 0
   END;
END ZeroByteArr;

PROCEDURE serve;
VAR sockfd, newsockfd, portno, clilen, pid: sockets.Int32;
    ServAddr, CliAddr: sockets.SockAddrIn;
    Null : Int32;
    Port, maxQueue, res : Int32;
    afinet, port, port0: Int16;
BEGIN
   Port := 2055;
   maxQueue := 5;
   Null := 0;
   sockfd := sockets.Socket(S.VAL(Int32, sockets.AfInet), S.VAL(Int32, sockets.SockStream), Null);
   IF sockfd < 0 THEN
      Out.String("error opening socket")
   ELSE
      Out.String("socket created.")
   END;
   Out.Ln;
   
   types.IntegerToInt16(sockets.AfInet, afinet);
   types.IntegerToInt16(Port, port);
   types.htons(port, port0); (* only necessary on little endian computers *)
   ServAddr.SinFamily := afinet;
   ServAddr.SinPort := port0;
   ZeroByteArr(ServAddr.SinZero);
   (*Out.String("listening on port ");Out.Int(S.VAL(INTEGER, ServAddr.SinPort), 0); Out.Ln;*)
   ServAddr.SinAddr.SAddr := 0(*sockets.InAddrAny*);
   
   res := sockets.Bind(sockfd, S.VAL(sockets.SockAddr, ServAddr), (SIZE(sockets.SockAddr)));
   IF res < 0 THEN
      Out.String("error on binding")
   ELSE
      Out.String("binding completed.")
   END;
   Out.Ln;
    
   res := sockets.Listen(sockfd, maxQueue);
   
   IF res # 0 THEN
      Out.String("listen() failed");
   ELSE
      Out.String("listen okay");
   END;
   Out.Ln;
   clilen := SIZE(sockets.SockAddrIn);
   LOOP
      newsockfd := sockets.Accept(sockfd, S.VAL(sockets.SockAddr, ServAddr), clilen);
      IF newsockfd < 0 THEN
         Out.String("error on accept")
      ELSE
         Out.String("accept okay")
      END;
      Out.Ln;

      pid := Unix.Fork();
      IF pid < 0 THEN
         Out.String("error on fork")
      ELSIF pid = 0 THEN
         Out.String("forked okay"); Out.Ln;
         res := Unix.Close(sockfd);
	 DoSmth(newsockfd);
	 EXIT
      ELSE
         res := Unix.Close(newsockfd);
      END;
   END;


END serve;


BEGIN

serve;

END s.
