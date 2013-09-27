MODULE version;
   IMPORT Strings := oocOakStrings, architecture;
CONST     
(* targets *)
    gnux86* = 0; gnux8664* = 1; gnuarmv6j* = 2; gnuarmv6jhardfp* = 3;  gnuarmv7ahardfp* = 4;

VAR arch-, version-, date-, versionLong-, prefix0-, prefix- : ARRAY 23 OF CHAR;
defaultTarget* : INTEGER;
BEGIN
arch := architecture.arch;
date := " [2013/09/23]";
version := "1.0";
versionLong := "";
COPY(version, versionLong);
Strings.Append (" ", versionLong);
Strings.Append(date, versionLong);
  prefix := "";
  prefix0 := "/opt";
  COPY (prefix0, prefix);
  Strings.Append ("/voc-", prefix);
  Strings.Append(version, prefix); (* /opt/voc-1.0 *)
 (* will be used later in Kernel.Mod to set OBERON default path *)

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
 ELSE
    defaultTarget := gnux8664
 END

END version.
