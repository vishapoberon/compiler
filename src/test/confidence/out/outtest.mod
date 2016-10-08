MODULE outtest;

IMPORT Out;

VAR
  r:  REAL;
  lr: LONGREAL;

PROCEDURE ws(s: ARRAY OF CHAR); BEGIN Out.String(s) END ws;
PROCEDURE wi(i: HUGEINT); BEGIN Out.Int(i,1) END wi;
PROCEDURE wl; BEGIN Out.Ln END wl;


BEGIN
  ws("Out module tests."); wl;
  ws("SIZE(INTEGER) = "); wi(SIZE(INTEGER)); wl; wl;

  ws("Testing LONGREAL."); wl; wl;
  ws("                                1         2         3");            wl;
  ws("                       123456789012345678901234567890");            wl;
  ws(" 1.0D0:                "); Out.LongReal( 1.0D0,                1);  wl;
  ws(" 1.1D0:                "); Out.LongReal( 1.1D0,                1);  wl;
  ws(" 2.1D0:                "); Out.LongReal( 2.1D0,                1);  wl;
  ws("-1.1D0:                "); Out.LongReal(-1.1D0,                1);  wl;
  ws(" 1.1D3:                "); Out.LongReal( 1.1D3,                1);  wl;
  ws(" 1.1D-3:               "); Out.LongReal( 1.1D-3,               1);  wl;
  ws(" 1.2345678987654321D3: "); Out.LongReal( 1.2345678987654321D3, 1);  wl;
  ws(" 0.0:                  "); Out.LongReal(0.0,                   1);  wl;
  ws(" 0.000123D0:           "); Out.LongReal(0.000123D0,            1);  wl;
  lr := 0.0; lr :=  1/lr;
  ws(" 1/0.0:                "); Out.LongReal(lr,                    1);  wl;
  lr := 0.0; lr := -1/lr;
  ws("-1/0.0:                "); Out.LongReal(lr,                    1);  wl;
  wl;
  ws("                                1         2         3");            wl;
  ws("                       123456789012345678901234567890");            wl;
  ws(" 1.0D0:                "); Out.LongReal( 1.0D0,                12); wl;
  ws(" 1.1D0:                "); Out.LongReal( 1.1D0,                12); wl;
  ws(" 2.1D0:                "); Out.LongReal( 2.1D0,                12); wl;
  ws("-1.1D0:                "); Out.LongReal(-1.1D0,                12); wl;
  ws(" 1.1D3:                "); Out.LongReal( 1.1D3,                12); wl;
  ws(" 1.1D-3:               "); Out.LongReal( 1.1D-3,               12); wl;
  ws(" 1.2345678987654321D3: "); Out.LongReal( 1.2345678987654321D3, 12); wl;
  ws(" 0.0:                  "); Out.LongReal(0.0,                   12); wl;
  ws(" 0.000123D0:           "); Out.LongReal(0.000123D0,            12); wl;
  lr := 0.0; lr :=  1/lr;
  ws(" 1/0.0:                "); Out.LongReal(lr,                    12); wl;
  lr := 0.0; lr := -1/lr;
  ws("-1/0.0:                "); Out.LongReal(lr,                    12); wl;
  wl;
  ws("                                1         2         3");            wl;
  ws("                       123456789012345678901234567890");            wl;
  ws(" 1.0D0:                "); Out.LongReal( 1.0D0,                30); wl;
  ws(" 1.1D0:                "); Out.LongReal( 1.1D0,                30); wl;
  ws(" 2.1D0:                "); Out.LongReal( 2.1D0,                30); wl;
  ws("-1.1D0:                "); Out.LongReal(-1.1D0,                30); wl;
  ws(" 1.1D3:                "); Out.LongReal( 1.1D3,                30); wl;
  ws(" 1.1D-3:               "); Out.LongReal( 1.1D-3,               30); wl;
  ws(" 1.2345678987654321D3: "); Out.LongReal( 1.2345678987654321D3, 30); wl;
  ws(" 0.0:                  "); Out.LongReal(0.0,                   30); wl;
  ws(" 0.000123D0:           "); Out.LongReal(0.000123D0,            30); wl;
  lr := 0.0; lr :=  1/lr;
  ws(" 1/0.0:                "); Out.LongReal(lr,                    30); wl;
  lr := 0.0; lr := -1/lr;
  ws("-1/0.0:                "); Out.LongReal(lr,                    30); wl;
  wl; wl; wl;


  ws("Testing REAL."); wl; wl;
  ws("                                1         2         3");            wl;
  ws("                       123456789012345678901234567890");            wl;
  ws(" 1.0E0:                "); Out.Real( 1.0E0,                    1);  wl;
  ws(" 1.1E0:                "); Out.Real( 1.1E0,                    1);  wl;
  ws(" 2.1E0:                "); Out.Real( 2.1E0,                    1);  wl;
  ws("-1.1E0:                "); Out.Real(-1.1E0,                    1);  wl;
  ws(" 1.1E3:                "); Out.Real( 1.1E3,                    1);  wl;
  ws(" 1.1E-3:               "); Out.Real( 1.1E-3,                   1);  wl;
  ws(" 1.2345678987654321E3: "); Out.Real( 1.2345678987654321E3,     1);  wl;
  ws(" 0.0:                  "); Out.Real(0.0,                       1);  wl;
  ws(" 0.000123E0:           "); Out.Real(0.000123E0,                1);  wl;
  r := 0.0; r :=  1/r;
  ws(" 1/0.0:                "); Out.Real(r,                         1);  wl;
  r := 0.0; r := -1/r;
  ws("-1/0.0:                "); Out.Real(r,                         1);  wl;
  wl;
  ws("                                1         2         3");        wl;
  ws("                       123456789012345678901234567890");        wl;
  ws(" 1.0E0:                "); Out.Real( 1.0E0,                    12); wl;
  ws(" 1.1E0:                "); Out.Real( 1.1E0,                    12); wl;
  ws(" 2.1E0:                "); Out.Real( 2.1E0,                    12); wl;
  ws("-1.1E0:                "); Out.Real(-1.1E0,                    12); wl;
  ws(" 1.1E3:                "); Out.Real( 1.1E3,                    12); wl;
  ws(" 1.1E-3:               "); Out.Real( 1.1E-3,                   12); wl;
  ws(" 1.2345678987654321E3: "); Out.Real( 1.2345678987654321E3,     12); wl;
  ws(" 0.0:                  "); Out.Real(0.0,                       12); wl;
  ws(" 0.000123E0:           "); Out.Real(0.000123E0,                12); wl;
  r := 0.0; r :=  1/r;
  ws(" 1/0.0:                "); Out.Real(r,                         12); wl;
  r := 0.0; r := -1/r;
  ws("-1/0.0:                "); Out.Real(r,                         12); wl;
  wl;
  ws("                                1         2         3");            wl;
  ws("                       123456789012345678901234567890");            wl;
  ws(" 1.0E0:                "); Out.Real( 1.0E0,                    30); wl;
  ws(" 1.1E0:                "); Out.Real( 1.1E0,                    30); wl;
  ws(" 2.1E0:                "); Out.Real( 2.1E0,                    30); wl;
  ws("-1.1E0:                "); Out.Real(-1.1E0,                    30); wl;
  ws(" 1.1E3:                "); Out.Real( 1.1E3,                    30); wl;
  ws(" 1.1E-3:               "); Out.Real( 1.1E-3,                   30); wl;
  ws(" 1.2345678987654321E3: "); Out.Real( 1.2345678987654321E3,     30); wl;
  ws(" 0.0:                  "); Out.Real(0.0,                       30); wl;
  ws(" 0.000123E0:           "); Out.Real(0.000123E0,                30); wl;
  r := 0.0; r :=  1/r;
  ws(" 1/0.0:                "); Out.Real(r,                         30); wl;
  r := 0.0; r := -1/r;
  ws("-1/0.0:                "); Out.Real(r,                         30); wl;
  wl;

END outtest.
