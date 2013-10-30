<* O2EXTENSIONS + *>
<* IOVERFLOW - *>
MODULE Random;

  IMPORT
    Sys:=SYSTEM,Win:=Windows,MathL;

  CONST
    (* Period parameter *)
    MT19937N*=624;

    (* Period parameters *)
    MT19937M=397;
    MT19937MATRIX_A  =Sys.VAL(SET,9908b0dfH);  -- constant vector a
    MT19937UPPER_MASK=Sys.VAL(SET,80000000H);  -- most significant w-r bits
    MT19937LOWER_MASK=Sys.VAL(SET,7fffffffH);  -- least significant r bits

    (* Tempering parameters *)
    TEMPERING_MASK_B=Sys.VAL(SET,9d2c5680H);
    TEMPERING_MASK_C=Sys.VAL(SET,0efc60000H);

    Seed0=4357;
  TYPE
    tMT19937StateArray=ARRAY MT19937N OF SET; -- the array for the state vector

  VAR
    Seed-:LONGINT;

    mt : tMT19937StateArray;
    mti: LONGINT; -- mti=MT19937N+1 means mt[] is not initialized

    GaussRandomBuf:LONGREAL;
    GaussRandomBufFilled:BOOLEAN;

  (* Initializing the array with a seed *)
  PROCEDURE SetSeed*(seed:LONGINT);(* sgenrand_MT19937 *)
    CONST
      HighBits=Sys.VAL(SET,0ffff0000H);
    VAR
      i:LONGINT;
    BEGIN
      Seed:=seed;
      FOR i:=0 TO MT19937N-1 DO
        mt[i]:=Sys.VAL(SET,seed) * HighBits;
        seed:=69069*seed+1;
        mt[i]:=mt[i] + (Sys.SHIFT(Sys.VAL(SET,seed) * HighBits,-16));
        seed:=69069*seed+1;
      END;
      mti := MT19937N;
    END SetSeed;

  (* Initialization by array of seeds *)
  PROCEDURE SetSeeds*(seed_array-:tMT19937StateArray); (* lsgenrand_MT19937 *)
    VAR
      i:LONGINT;
    BEGIN
      FOR i:=0 TO MT19937N-1 DO
        mt[i]:=seed_array[i];
      END;
      mti:=MT19937N;
    END SetSeeds;

  (* random longint (full range) *)
  PROCEDURE Int*():LONGINT; (* genrand_MT19937 *)
    TYPE
      ar=ARRAY 2 OF SET;
    VAR
      mag01:ARRAY 2 OF SET;
      y:SET;
      kk:LONGINT;
    BEGIN
      mag01[0]:={};
      mag01[1]:=MT19937MATRIX_A;

      IF mti>=MT19937N THEN (* generate MT19937N longints at one time *)
        IF mti=(MT19937N+1) THEN  -- if sgenrand_MT19937() has not been called,
          SetSeed(Seed0);   -- default initial seed is used
        END;
        FOR kk:=0 TO MT19937N-MT19937M-1 DO
           y:=(mt[kk] * MT19937UPPER_MASK) + (mt[kk+1] * MT19937LOWER_MASK);
           mt[kk]:=mt[kk+MT19937M]/Sys.SHIFT(y,-1)/mag01[Sys.VAL(LONGINT,y * {0})];
        END;
        FOR kk:=MT19937N-MT19937M TO MT19937N-2 DO
          y:=(mt[kk] * MT19937UPPER_MASK) + (mt[kk+1] * MT19937LOWER_MASK);
          mt[kk]:=mt[kk+(MT19937M-MT19937N)]/Sys.SHIFT(y,-1)/mag01[Sys.VAL(LONG
INT,y * {0})];
        END;
        y:=(mt[MT19937N-1] * MT19937UPPER_MASK) + (mt[0] * MT19937LOWER_MASK);
        mt[MT19937N-1]:=mt[MT19937M-1]/Sys.SHIFT(y,-1)/mag01[Sys.VAL(LONGINT,y
* {0})];
        mti:=0;
      END;
      y:=mt[mti]; INC(mti);
      y:=y/Sys.SHIFT(y,-11);
      y:=y/(Sys.SHIFT(y,7) * TEMPERING_MASK_B);
      y:=y/(Sys.SHIFT(y,15) * TEMPERING_MASK_C);
      y:=y/Sys.SHIFT(y,-18);
      RETURN Sys.VAL(LONGINT,y);
    END Int;

  (*randomization*)
  PROCEDURE Randomize*(); (* Randomize_MT19937 *)
    VAR
      ST:Win.SYSTEMTIME;
    BEGIN
      Win.GetSystemTime(ST);
      SetSeed(((Sys.VAL(LONGINT,ST.wHour)*60+ST.wMinute)*60+ST.wSecond)*1000+S
T.wMilliseconds);
    END Randomize;

  (*integer RANDOM with positive range*)
  -- bug fixed 21.6.2000.
  PROCEDURE IntRange*(Range:LONGINT):LONGINT; (* RandInt_MT19937 *)
    TYPE
    VAR
      X:Sys.CARD64;
    BEGIN
      X:=Range;
      X:=X * Sys.VAL(Sys.CARD64,Int());
      Sys.MOVE(Sys.ADR(X)+4,Sys.ADR(Range),4);
      RETURN Range;
    END IntRange;

  (*float RANDOM on 0..1 interval*)
  PROCEDURE Real*():LONGREAL; (* RandFloat_MT19937 *)
    BEGIN
      RETURN Sys.VAL(Sys.CARD32,Int())/(1.0*MAX(Sys.CARD32)+1)
    END Real;

  PROCEDURE Gauss*(mean,std:LONGREAL):LONGREAL;
    VAR
      r1,r2,s,result:LONGREAL;
    BEGIN
      IF GaussRandomBufFilled THEN
        result:=GaussRandomBuf*std+mean
      ELSE
        REPEAT
          r1:=2*Real()-1;
          r2:=2*Real()-1;
          s:=r1*r1+r2*r2;
        UNTIL s<1;
        s:=MathL.sqrt((-2*MathL.ln(s))/s);
        result:=r1*s*std+mean;
        GaussRandomBuf:=r2*s;
      END;
      GaussRandomBufFilled:=NOT GaussRandomBufFilled;
      RETURN result
    END Gauss;

BEGIN
  Seed:=Seed0;
  mti:=MT19937N+1;
  GaussRandomBufFilled:=FALSE;
END Random.

(*----------------------------------------------------------------------
   Mersenne Twister: A 623-Dimensionally Equidistributed Uniform
   Pseudo-Random Number Generator.

   What is Mersenne Twister?
   Mersenne Twister(MT) is a pseudorandom number generator developped by
   Makoto Matsumoto and Takuji Nishimura (alphabetical order) during
   1996-1997. MT has the following merits:
   It is designed with consideration on the flaws of various existing
   generators.
   Far longer period and far higher order of equidistribution than any
   other implemented generators. (It is proved that the period is 2^19937-1,
   and 623-dimensional equidistribution property is assured.)
   Fast generation. (Although it depends on the system, it is reported that
   MT is sometimes faster than the standard ANSI-C library in a system
   with pipeline and cache memory.)
   Efficient use of the memory. (The implemented C-code mt19937.c
   consumes only 624 words of working area.)

   home page
     http://www.math.keio.ac.jp/~matumoto/emt.html
   original c source
     http://www.math.keio.ac.jp/~nisimura/random/int/mt19937int.c

   Coded by Takuji Nishimura, considering the suggestions by
   Topher Cooper and Marc Rieffel in July-Aug. 1997.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later
   version.
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
   See the GNU Library General Public License for more details.
   You should have received a copy of the GNU Library General
   Public License along with this library; if not, write to the
   Free Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
   02111-1307  USA

   Copyright (C) 1997, 1999 Makoto Matsumoto and Takuji Nishimura.
   When you use this, send an email to: matumoto@math.keio.ac.jp
   with an appropriate reference to your work.

   REFERENCE
   M. Matsumoto and T. Nishimura,
   "Mersenne Twister: A 623-Dimensionally Equidistributed Uniform
   Pseudo-Random Number Generator",
   ACM Transactions on Modeling and Computer Simulation,
   Vol. 8, No. 1, January 1998, pp 3--30.


  Translated to OP and Delphi interface added by Roman Krejci (6.12.1999)

  http://www.rksolution.cz/delphi/tips.htm

  Revised 21.6.2000: Bug in the function RandInt_MT19937 fixed
----------------------------------------------------------------------*)
