(* License: GPL-3.0 *)
(* (c) 2024 Carlos Une <une@fastmail.fm> *)

MODULE IP;
IMPORT SYSTEM, Out, BIT;

TYPE
    IPv4* = LONGINT; (* 32-bit *)
    NETWORK* = RECORD
        ip*: IPv4;
        mask*: IPv4;
    END;

PROCEDURE New*(a, b, c, d: INTEGER): IPv4;
VAR r: IPv4;
BEGIN
    ASSERT((a >= 0) & (a <= 255));
    ASSERT((b >= 0) & (b <= 255));
    ASSERT((c >= 0) & (c <= 255));
    ASSERT((d >= 0) & (d <= 255));

    r := SYSTEM.LSH(LONG(a), 24);
    r := BIT.LOR(r, SYSTEM.LSH(LONG(b), 16));
    r := BIT.LOR(r, SYSTEM.LSH(LONG(c), 8));
    r := BIT.LOR(r, LONG(d));
    RETURN r;
END New;

PROCEDURE BNOT(ip: IPv4): IPv4;
BEGIN
    RETURN BIT.LXOR(-1, ip);
END BNOT;

(* b is the number of consecutive leading 1-bits in the network mask *)
PROCEDURE NewNetwork*(ip: IPv4; b: INTEGER; VAR net: NETWORK);
BEGIN
    ASSERT((b >= 0) & (b <= 32));
    IF b = 0 THEN net.mask := 0
    ELSE net.mask := SYSTEM.LSH(BNOT(0), LONG(32-b)) END;
    net.ip := BIT.LAND(ip, net.mask);
END NewNetwork;

PROCEDURE LargestAddress*(net: NETWORK): IPv4;
BEGIN
    RETURN SYSTEM.VAL(IPv4, SYSTEM.VAL(HUGEINT, LONG(net.ip)) + SYSTEM.VAL(HUGEINT, LONG(BNOT(net.mask))));
END LargestAddress;

(* Computes whether `ip' is contained within `net' *)
PROCEDURE IsWithin*(ip: IPv4; net: NETWORK): BOOLEAN;
BEGIN
    RETURN BIT.LLESSEQ(ip, LargestAddress(net)) & BIT.LLESSEQ(net.ip, ip);
END IsWithin;

PROCEDURE Decompose*(ip: IPv4; VAR a, b, c, d: INTEGER);
BEGIN
    a := SHORT(SYSTEM.LSH(ip, -24));
    b := SHORT(BIT.LAND(0FFH, SYSTEM.LSH(ip, -16)));
    c := SHORT(BIT.LAND(0FFH, SYSTEM.LSH(ip, -8)));
    d := SHORT(BIT.LAND(0FFH, ip));
END Decompose;

PROCEDURE PrintIP*(ip: IPv4);
VAR a, b, c, d: INTEGER;
BEGIN
    Decompose(ip, a, b, c, d);
    Out.Int(a, 1);
    Out.String(".");
    Out.Int(b, 1);
    Out.String(".");
    Out.Int(c, 1);
    Out.String(".");
    Out.Int(d, 1);
END PrintIP;

PROCEDURE PrintIPLn*(ip: IPv4);
BEGIN
    PrintIP(ip);
    Out.Ln;
END PrintIPLn;

PROCEDURE PrintBits*(ip: IPv4);
VAR i: SHORTINT;
BEGIN
    FOR i := 31 TO 0 BY -1
    DO
        IF (i # 31) & ((i + 1) MOD 8 = 0)  THEN
            Out.String(" ");
        END;

        IF BIT.BIT(ip, i) THEN
            Out.String("1");
        ELSE
            Out.String("0");
        END;
    END;
END PrintBits;

PROCEDURE PrintBitsLn*(ip: IPv4);
BEGIN
    PrintBits(ip);
    Out.Ln;
END PrintBitsLn;

END IP.
