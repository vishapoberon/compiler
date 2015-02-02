MODULE version;
   IMPORT Strings, architecture, prf;
CONST     
(* targets *)
    gnux86* = 0; gnux8664* = 1; gnuarmv6j* = 2; gnuarmv6jhardfp* = 3;  gnuarmv7ahardfp* = 4; gnupowerpc* = 5;

VAR arch-, version-, date-, versionLong-, prefix0-, prefix- : ARRAY 256 OF CHAR;
defaultTarget* : INTEGER;
BEGIN
arch := architecture.arch;
date := " [2015/02/02]";
version := "1.1";
versionLong := "";
COPY(version, versionLong);
Strings.Append (" ", versionLong);
Strings.Append(date, versionLong);
  prefix := "";
  (*prefix0 := "/opt";*)
  COPY(prf.prefix, prefix0);
  COPY (prefix0, prefix);
  Strings.Append ("/voc-", prefix);
  Strings.Append(version, prefix); (* /opt/voc-x.x *)
 (* will be used later in Kernel0.Mod to set OBERON default path *)

 IF arch = "x86_64" THEN
    defaultTarget := gnux8664
 ELSIF arch = "x86" THEN
    defaultTarget := gnux86
 ELSIF arch = "armv6j" THEN
    defaultTarget := gnuarmv6j
 ELSIF arch = "armv6j_hardfp" THEN
    defaultTarget := gnuarmv6jhardfp
 ELSIF arch = "armv7a_hardfp" THEN
    defaultTarget := gnuarmv7ahardfp
 ELSIF arch = "powerpc" THEN
    defaultTarget := gnupowerpc
 ELSE
    defaultTarget := gnux8664
 END

END version.
