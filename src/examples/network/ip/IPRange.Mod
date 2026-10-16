(* License: GPL-3.0 *)
(* (c) 2025 Carlos Une <une@fastmail.fm> *)

MODULE IPRange;
IMPORT Out, Modules, IP;

VAR
    n: INTEGER;
    val: ARRAY 64 OF CHAR;
    net: IP.NETWORK;

PROCEDURE IsDigit(c: CHAR): BOOLEAN;
BEGIN
    RETURN (c >= '0') & (c <= '9');
END IsDigit;

PROCEDURE GetNumber(s: ARRAY OF CHAR; VAR i: INTEGER): INTEGER;
VAR r: INTEGER;
BEGIN
    r := 0;
    ASSERT((i < LEN(s)) & IsDigit(s[i]));
    LOOP
        IF (i < LEN(s)) & IsDigit(s[i]) THEN
            r := r * 10;
            r := r + (ORD(s[i]) - ORD('0'));
            ASSERT(r <= 255);
            INC(i);
        ELSE
            EXIT;
        END;
    END;
    RETURN r;
END GetNumber;

PROCEDURE GetChar(s: ARRAY OF CHAR; VAR i: INTEGER): CHAR;
VAR c: CHAR;
BEGIN
    ASSERT(i < LEN(s));
    c := s[i];
    INC(i);
    RETURN c;
END GetChar;

PROCEDURE ToSubnet(s: ARRAY OF CHAR; VAR net: IP.NETWORK);
VAR i, a, b, c, d, e: INTEGER;
BEGIN
    (* A full IPv4 address and prefix occupy at most 18 characters. Reject
       oversized/truncated Modules.GetArg results before parsing a prefix. *)
    i := 0;
    WHILE (i < LEN(s)) & (s[i] # 0X) DO INC(i) END;
    ASSERT((i > 0) & (i <= 18));
    i := 0;
    a := GetNumber(s, i);
    ASSERT(a <= 255);
    ASSERT(GetChar(s, i) = '.');
    b := GetNumber(s, i);
    ASSERT(b <= 255);
    ASSERT(GetChar(s, i) = '.');
    c := GetNumber(s, i);
    ASSERT(c <= 255);
    ASSERT(GetChar(s, i) = '.');
    d := GetNumber(s, i);
    ASSERT(d <= 255);
    ASSERT(GetChar(s, i) = '/');
    e := GetNumber(s, i);
    ASSERT(e <= 32);
    ASSERT((i < LEN(s)) & (s[i] = 0X));
    IP.NewNetwork(IP.New(a, b, c, d), e, net);
END ToSubnet;

PROCEDURE NetInfo(net: IP.NETWORK);
BEGIN
    Out.String("Network:");
    IP.PrintIPLn(net.ip);
    Out.String("Mask:   ");
    IP.PrintIPLn(net.mask);
    Out.String("First:  ");
    IP.PrintIPLn(net.ip);
    Out.String("Last:   ");
    IP.PrintIPLn(IP.LargestAddress(net));
END NetInfo;

BEGIN
    FOR n := 1 TO Modules.ArgCount - 1
    DO
        Modules.GetArg(n, val);
        ToSubnet(val, net);
        NetInfo(net);
    END;
END IPRange.
