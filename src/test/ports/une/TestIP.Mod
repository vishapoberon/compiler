(* License: GPL-3.0 *)
(* (c) 2024 Carlos Une <une@fastmail.fm> *)

MODULE TestIP;
IMPORT Out, IP, ethRandomNumbers := RandomNumbers;

PROCEDURE NetInfo();
VAR net: IP.NETWORK;
BEGIN
    IP.NewNetwork(IP.New(10, 7, 80, 130), 26, net);
    Out.String("Network:");
    IP.PrintIPLn(net.ip);
    Out.String("Mask:   ");
    IP.PrintIPLn(net.mask);
    Out.String("First:  ");
    IP.PrintIPLn(net.ip);
    Out.String("Last:   ");
    IP.PrintIPLn(IP.LargestAddress(net));
    Out.Ln;
END NetInfo;

PROCEDURE TestWithin();
VAR netip, testip: IP.IPv4;
    cidr: INTEGER;
    net: IP.NETWORK;
BEGIN
    netip := IP.New(10, 7, 12, 64);
    cidr := 26;
    testip := IP.New(10, 7, 12, 120);
    IP.NewNetwork(netip, cidr, net);

    Out.String("Address ");
    IP.PrintIP(testip);
    Out.String(" is contained within subnet ");
    IP.PrintIP(net.ip);
    Out.String("/");
    Out.Int(cidr, 1);
    Out.String(": ");

    IF IP.IsWithin(testip, net) THEN
        Out.String("YES");
    ELSE
        Out.String("NO");
    END;

    Out.Ln;
END TestWithin;

PROCEDURE TestDecompose();
VAR ip: IP.IPv4;
    a, b, c, d, w, x, y, z: INTEGER;
BEGIN
    a := 1;
    b := 2;
    c := 3;
    d := 4;

    ip := IP.New(a, b, c, d);
    Out.String("IP:");
    IP.PrintIP(ip);
    Out.String(" = ");
    IP.PrintBitsLn(ip);

    (* Decompose IP into separate components *)
    IP.Decompose(ip, w, x, y, z);
    ASSERT(a = w);
    ASSERT(b = x);
    ASSERT(c = y);
    ASSERT(d = z);
    ASSERT(IP.New(w, x, y, z) = ip);
    Out.String("TestDecompose: OK");
    Out.Ln;
END TestDecompose;

PROCEDURE TestSubnet();
VAR i: INTEGER;
    net: IP.NETWORK;
BEGIN
    FOR i := 32 TO 1 BY -8
    DO
        IP.NewNetwork(IP.New(10, 0, 0, 0), i, net);
        Out.String("CIDR:/");
        Out.Int(i, 1);
        Out.String(" Mask = ");
        IP.PrintIP(net.mask);
        Out.String(" Range = ");
        IP.PrintIP(net.ip);
        Out.String("/");
        IP.PrintIPLn(IP.LargestAddress(net));
    END;
END TestSubnet;

PROCEDURE TestRandom();
VAR i: INTEGER;
    ip: IP.IPv4;
    a, b, c, d, w, x, y, z: INTEGER;

    PROCEDURE Generate(VAR a, b, c, d: INTEGER): IP.IPv4;
    BEGIN
        a := SHORT(ENTIER(ethRandomNumbers.Uniform() * 256.0));
        b := SHORT(ENTIER(ethRandomNumbers.Uniform() * 256.0));
        c := SHORT(ENTIER(ethRandomNumbers.Uniform() * 256.0));
        d := SHORT(ENTIER(ethRandomNumbers.Uniform() * 256.0));
        RETURN IP.New(a, b, c, d);
    END Generate;

BEGIN
    ethRandomNumbers.InitSeed(1234);

    FOR i := 0 TO MAX(INTEGER) - 1
    DO
        ip := Generate(a, b, c, d);
        IP.Decompose(ip, w, x, y, z);
        ASSERT(a = w);
        ASSERT(b = x);
        ASSERT(c = y);
        ASSERT(d = z);
        ASSERT(ip = IP.New(w, x, y, z));
    END;

    Out.String("TestRandom: OK");
    Out.Ln;
END TestRandom;

BEGIN
    NetInfo;
    TestDecompose;
    TestWithin;
    TestSubnet;
    TestRandom;

    Out.String("Fim.");
    Out.Ln;
END TestIP.
