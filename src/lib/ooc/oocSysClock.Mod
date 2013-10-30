MODULE oocSysClock; 
IMPORT Unix;
  
CONST
  maxSecondParts* = 999; (* Most systems have just millisecond accuracy *) 
  
  zoneMin* = -780;       (* time zone minimum minutes *)
  zoneMax* =  720;       (* time zone maximum minutes *)

  localTime* = MIN(INTEGER);  (* time zone is inactive & time is local *)
  unknownZone* = localTime+1; (* time zone is unknown *)
 
  (* daylight savings mode values *)
  unknown* = -1;   (* current daylight savings status is unknown *)
  inactive* = 0;   (* daylight savings adjustments are not in effect *)
  active* = 1;     (* daylight savings adjustments are being used *)
    
TYPE
  (* The DateTime type is a system-independent time format whose fields
     are defined as follows:
     
          year      > 0
          month     = 1 .. 12
          day       = 1 .. 31
          hour      = 0 .. 23
          minute    = 0 .. 59
          second    = 0 .. 59
          fractions = 0 .. maxSecondParts
          zone      = -780 .. 720
  *)     
  DateTime* =
    RECORD
      year*:           INTEGER;
      month*:          SHORTINT;
      day*:            SHORTINT;
      hour*:           SHORTINT;
      minute*:         SHORTINT;
      second*:         SHORTINT;
      summerTimeFlag*: SHORTINT; (* daylight savings mode (see above) *)      
      fractions*:      INTEGER;  (* parts of a second in milliseconds *)
      zone*:           INTEGER;  (* Time zone differential factor which 
                                    is the number of minutes to add to 
                                    local time to obtain UTC or is set
                                    to localTime when time zones are
                                    inactive. *)
    END;


PROCEDURE CanGetClock*(): BOOLEAN;
(* Returns TRUE if a system clock can be read; FALSE otherwise.  *)
VAR timeval: Unix.Timeval; timezone: Unix.Timezone;
l : LONGINT;
BEGIN
   l := Unix.Gettimeofday(timeval, timezone);
   IF l = 0 THEN RETURN TRUE ELSE RETURN FALSE END 
END CanGetClock;
(*
PROCEDURE CanSetClock*(): BOOLEAN;
(* Returns TRUE if a system clock can be set; FALSE otherwise.  *)
*)
(*
PROCEDURE IsValidDateTime* (d: DateTime): BOOLEAN;
(* Returns TRUE if the value of `d' represents a valid date and time; 
   FALSE otherwise.  *)
*)


  (*
PROCEDURE SetClock* (userData: DateTime);
(* If possible, sets the system clock to the values of `userData'.  *)
*)
(*
PROCEDURE MakeLocalTime * (VAR c: DateTime);
(* Fill in the daylight savings mode and time zone for calendar date `c'.
   The fields `zone' and `summerTimeFlag' given in `c' are ignored, assuming
   that the rest of the record describes a local time.
   Note 1: On most Unix systems the time zone information is only available for
    dates falling within approx. 1 Jan 1902 to 31 Dec 2037.  Outside this range
    the field `zone' will be set to the unspecified `localTime' value (see 
    above), and `summerTimeFlag' will be set to `unknown'.
   Note 2: The time zone information might not be fully accurate for past (and
    future) years that apply different DST rules than the current year.
    Usually the current set of rules is used for _all_ years between 1902 and 
    2037.
   Note 3: With DST there is one hour in the year that happens twice: the
    hour after which the clock is turned back for a full hour.  It is undefined
    which time zone will be selected for dates refering to this hour, i.e.
    whether DST or normal time zone will be chosen.  *)
*)

PROCEDURE GetTimeOfDay* (VAR sec, usec: LONGINT): LONGINT;
(* PRIVAT.  Don't use this.  Take Time.GetTime instead.  
   Equivalent to the C function `gettimeofday'.  The return value is `0' on 
   success and `-1' on failure; in the latter case `sec' and `usec' are set to
   zero.  *)
   VAR timeval: Unix.Timeval; timezone: Unix.Timezone;
   l : LONGINT;
BEGIN
   l := Unix.Gettimeofday (timeval, timezone);
   IF l = 0 THEN
      sec := timeval.sec;
      usec := timeval.usec;
   ELSE
      sec := 0;
     usec := 0;
   END;
   RETURN l;
END GetTimeOfDay;

END oocSysClock.
